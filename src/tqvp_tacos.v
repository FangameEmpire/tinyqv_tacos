/*
 * Copyright (c) 2025 Nicklaus Thompson
 * SPDX-License-Identifier: Apache-2.0
 */

//`default_nettype none

// Change the name of this module to something that reflects its functionality and includes your name for uniqueness
// For example tqvp_yourname_spi for an SPI peripheral.
// Then edit tt_wrapper.v line 41 and change tqvp_example to your chosen module name.
module tqvp_tacos (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [5:0]   address,      // Address within this peripheral's address space
    input [31:0]  data_in,      // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input [1:0]   data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input [1:0]   data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    
    output [31:0] data_out,     // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output        data_ready,

    output        user_interrupt  // Dedicated interrupt request for this peripheral
);

    // Internal and external control is done through a register
	reg [31:0] alu_status;
	wire [3:0] alu_opcode;
	assign alu_opcode = alu_status[3:0];
	always @(posedge clk) begin
		if (!rst_n) begin
			alu_status[31:16] <= 0;
		end else begin
			alu_status[19:16] <= alu_opcode;
		end
	end
	
	// Data size, primarily based on register cost
	localparam WIDTH = 32;
	localparam FBITS = 16;
	
	// Implement a 32-bit read/write register at addresses 0-3
    reg [31:0] alu_a, alu_b, alu_c;
    always @(posedge clk) begin
        if (!rst_n) begin
            alu_status[15:8] <= 0;
			alu_a <= 0;
			alu_b <= 0;
        end else begin
            if (address == 6'h0) begin
                if (data_write_n != 2'b11)              alu_status[7:0]   <= data_in[7:0];
                if (data_write_n[1] != data_write_n[0]) alu_status[15:8]  <= data_in[15:8];
				// alu_status[31:16] will be read-only
            end else if (address == 6'h1) begin
				if (data_write_n != 2'b11)              alu_a[7:0]   <= data_in[7:0];
                if (data_write_n[1] != data_write_n[0]) alu_a[15:8]  <= data_in[15:8];
                if (data_write_n == 2'b10)              alu_a[31:16] <= data_in[31:16];
			end else if (address == 6'h2) begin
				if (data_write_n != 2'b11)              alu_b[7:0]   <= data_in[7:0];
                if (data_write_n[1] != data_write_n[0]) alu_b[15:8]  <= data_in[15:8];
                if (data_write_n == 2'b10)              alu_b[31:16] <= data_in[31:16];
			end
        end
    end // always @(posedge clk)
	
	// Square and square root data
	wire [WIDTH-1:0] sqrt_in, sqrt_out, sqrt_rem, mul_b_in, mul_out;
	assign sqrt_in = alu_opcode[2] ? alu_c : alu_a;
	assign mul_b_in = (alu_opcode[2:1] == 2'b11) ? alu_b : alu_a;
	
	// Output depends on data
	wire update_c;
	always @(posedge clk) begin
        if (!rst_n) begin
            alu_c <= 0;
        end else if (update_c) begin
			if (alu_opcode == 4'h0) begin
				alu_c <= sqrt_out; // sqrt(A)
			end else if (alu_opcode == 4'h1) begin
				alu_c <= sqrt_rem; // sqrt(A)
			end else if (alu_opcode == 4'h2) begin
				alu_c <= mul_out; // A^2
			end else if (alu_opcode == 4'h3) begin
				alu_c <= alu_c + mul_out;
			end else if (alu_opcode == 4'h4) begin
				alu_c <= sqrt_out; // sqrt(C)
			end else if (alu_opcode == 4'h5) begin
				alu_c <= sqrt_rem; // sqrt(C)
			end else if (alu_opcode == 4'h6) begin
				alu_c <= sqrt_out; // sqrt(A^2 + B^2)
			end else if (alu_opcode == 4'h7) begin
				alu_c <= sqrt_rem; // sqrt(A^2 + B^2)
			end else begin
				alu_c <= alu_status;
			end
		end else begin
            alu_c <= alu_c;
        end
    end
	
	// Square and square root operations
	wire start_sqrt, start_mul, busy_sqrt, busy_mul, done_mul, valid_sqrt, valid_mul, ovf_mul;
	sqrt #(.WIDTH(WIDTH), .FBITS(FBITS)) square_calculator (clk, start_sqrt, busy_sqrt, valid_sqrt, sqrt_in, sqrt_out, sqrt_rem);
	mul #(.WIDTH(WIDTH), .FBITS(FBITS)) product_calculator (clk, ~rst_n, start_mul, busy_mul, done_mul, valid_mul, ovf_mul, alu_a, mul_b_in, mul_out);

    // The bottom 8 bits of the stored data are added to ui_in and output to uo_out.
    assign uo_out = 0;

    // Address 0 reads the example data register.  
    // Address 4 reads ui_in
    // All other addresses read 0.
    assign data_out = (address == 6'h0) ? alu_status :
                      (address == 6'h1) ? alu_a :
                      (address == 6'h2) ? alu_b :
                      (address == 6'h3) ? alu_c :
                      32'h0;

    // All reads complete in 1 clock
    assign data_ready = 1;
    
    // User interrupt is generated on rising edge of ui_in[6], and cleared by writing a 1 to the low bit of address 8.
    reg example_interrupt;
    reg last_ui_in_6;

    always @(posedge clk) begin
        if (!rst_n) begin
            example_interrupt <= 0;
        end

        if (ui_in[6] && !last_ui_in_6) begin
            example_interrupt <= 1;
        end else if (address == 6'h8 && data_write_n != 2'b11 && data_in[0]) begin
            example_interrupt <= 0;
        end

        last_ui_in_6 <= ui_in[6];
    end

    assign user_interrupt = example_interrupt;

    // List all unused inputs to prevent warnings
    // data_read_n is unused as none of our behaviour depends on whether
    // registers are being read.
    wire _unused = &{data_read_n, 1'b0};

endmodule // tqvp_tacos
