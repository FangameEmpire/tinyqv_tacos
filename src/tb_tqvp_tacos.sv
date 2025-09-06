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
		
		
		
		// End the simulation
		$stop;
		
	end // initial
	
endmodule // tqvp_tacos
