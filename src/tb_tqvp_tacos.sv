/*
 * Copyright (c) 2025 Nicklaus Thompson
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps

// 
module tqvp_tacos_testbench();
	// Module ports
	logic clk, rst_n;			// i
	
	logic [7:0] ui_in;			// i
	logic [7:0] uo_out;			// o
	
	logic [5:0] address;		// i
	logic [31:0] data_in;		// i
	
	logic [1:0] data_write_n;	// i
	logic [1:0] data_read_n;	// i
	
	logic [31:0] data_out;		// o
    logic data_ready;			// o
	logic user_interrupt;		// o
	
	// Device(s) Under Test
	tqvp_tacos dut (.*);
	
	// Clock
	parameter CLOCK_PERIOD=20;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end
	
	// Simulation parameters
	string current_test;
	
	// Test some transactions
	initial begin
		// Reset
		current_test = "RESET";
		rst_n = 0; address = 0; data_in = 0; data_write_n = 0; data_read_n = 0;	repeat(01) @(posedge clk);
		
		// Read addresses
		rst_n = 1; 		repeat(01) @(posedge clk);
		address = 1;	repeat(01) @(posedge clk);
		address = 2;	repeat(01) @(posedge clk);
		address = 3;	repeat(01) @(posedge clk);
		address = 4;	repeat(05) @(posedge clk);
		
		// Try writing to all addresses. Address 0 should accept 2 bytes, Addresses 1 and 2 4 bytes, 
		// and addresses 3+ 0 bytes. Address 0 bytes 3-2 and Address 3 are only writable internally.
		data_in = 32'hDEADBEEF; data_write_n = 2'b10;
		address = 0; repeat(01) @(posedge clk);
		address = 1; repeat(01) @(posedge clk);
		address = 2; repeat(01) @(posedge clk);
		address = 3; repeat(01) @(posedge clk);
		address = 4; repeat(01) @(posedge clk);
		
		data_in = 32'hBEEFDEAD; data_write_n = 2'b01;
		address = 0; repeat(01) @(posedge clk);
		address = 1; repeat(01) @(posedge clk);
		address = 2; repeat(01) @(posedge clk);
		address = 3; repeat(01) @(posedge clk);
		address = 4; repeat(01) @(posedge clk);
		
		// Write some data
		data_in = 32'h00000001; data_write_n = 2'b10;
		address = 0; repeat(01) @(posedge clk);
		data_in = 32'h00000004; data_write_n = 2'b10;
		address = 1; repeat(01) @(posedge clk);
		data_in = 32'h00000005; data_write_n = 2'b10;
		address = 2; repeat(01) @(posedge clk);
		data_in = 32'h00000000; data_write_n = 2'b00;
		address = 3; repeat(01) @(posedge clk);
		
		// End the simulation
		$stop;
		
	end // initial
	
endmodule // tqvp_tacos
