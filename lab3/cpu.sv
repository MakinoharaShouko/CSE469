module cpu(clk, reset, cond3, pc4, rm_val2, rn_val2, wr_val, N, Z, C, V);
	input logic clk, reset;
	output logic [3:0] cond3;
	output logic [63:0] pc4;
	output logic signed [63:0] rm_val2, rn_val2;
	output logic signed [63:0] wr_val;
	output logic N, Z, C, V;
	logic [3:0] cond, cond1, cond2;
	logic [4:0] rm_addr, rn_addr, rd_addr, wr_addr;
	logic [31:0] inst, inst1, inst2, inst3, inst4;
	logic [63:0] new_pc, uns_res, uns_res1, pc, pc1, pc2, pc3;
	logic [64:0] uns_comp_result, uns_comp_result1;
	logic signed [64:0] comp_result, comp_result1;
	logic signed [63:0] res, res1, rd_val, rn_val, rn_val1, rm_val, rm_val1, load_res;
	logic [7:0] inst_p1, inst_p2, inst_p3, inst_p4;
	logic cond_res, cond_res1, cond_res2, cond_res3, wr_en, wide, pc_wr;
	logic [63:0] load_addr;  // address to load from the main memory
	logic store;  // a flag that identifies whether STR operation is taken or not
	logic store_wide;  // a flag that identifies whether 64 or 32 bit is used in STR operation
	logic [63:0] store_addr;  // address to store data onto the main memory
	logic [63:0] store_data;  // data to write into the main memory
	
	logic stop_pc;  // stop the pipeline temporarily when branches
	
	assign stop_pc = (inst[28:26] === 3'b101) | (inst1[28:26] === 3'b101) | (inst2[28:26] === 3'b101) | (inst3[28:26] === 3'b101);
	
	pc_inc pi(.pc, .inst(inst3), .rn_val(rn_val2), .reset, .stop(stop_pc), .cond(cond_res2), .new_pc);
	
	// STAGE 1
	// read instruction bytes from the code memory
	// assemble them together to get the instruction
	code_memory cm1(.clk, .stop(stop_pc), .pc(pc), .inst(inst_p1));
	code_memory cm2(.clk, .stop(stop_pc), .pc(pc + 1), .inst(inst_p2));
	code_memory cm3(.clk, .stop(stop_pc), .pc(pc + 2), .inst(inst_p3));
	code_memory cm4(.clk, .stop(stop_pc), .pc(pc + 3), .inst(inst_p4));
	
	// STAGE 2
	// read registers
	// write new pc value to r15
	// write to target register
	assign inst = {inst_p1, inst_p2, inst_p3, inst_p4};
	
	conditional_check cc(.clk, .stop(inst[28:26] === 3'b101), .inst, .N, .Z, .C, .V, .cond_res, .cond);
	
	register_addr ra(.reset, .inst, .rm_addr, .rn_addr, .rd_addr);
	
	regfile rf(.clock(clk), .reset, .stop(stop_pc), .addr1(rn_addr), .val1(rn_val), .addr2(rm_addr), .val2(rm_val),
				  .addr3(rd_addr), .val3(rd_val), .new_pc(pc), .wr_en, .wide, .wr_addr, .wr_val);
	
	// STAGE 3
	// execute the code
	execution ex(.clk, .pc(pc2), .reset, .rm_val(rm_val), .rn_val(rn_val), .uns_rm_val(rm_val), .uns_rn_val(rn_val),
					 .rd_val, .inst(inst1), .res, .uns_res, .uns_comp_result, .comp_result, .cond(cond_res1), .load_addr,
					 .store, .store_wide, .store_addr, .store_data);
	
	// STAGE 4
	// accessing the main memory
	memory mem(.rd_addr(load_addr), .rd_data(load_res), .wr_addr(store_addr), .wr_data(store_data),
				  .wr_en(store & ~(inst3[28:26] === 3'b101)), .wide(store_wide), .reset, .clk);
				  
	// STAGE 5
	update up(.clk, .reset, .cond(cond_res3), .stop(inst4[28:26] === 3'b101), .inst(inst3), .rn_val(rn_val2),
				 .res(res1), .uns_res(uns_res1), .uns_comp_result(uns_comp_result1), .comp_result(comp_result1),
				 .load_res, .N, .Z, .C, .V, .wr_en, .wide, .wr_addr, .wr_val, .pc(pc4));
				 
	// move data between registers
	always_ff@(posedge clk) begin
		if (reset)
			pc <= 0;
		
		cond_res1 <= cond_res;
		cond_res2 <= cond_res1;
		cond_res3 <= cond_res2;
		
		cond1 <= cond;
		cond2 <= cond1;
		cond3 <= cond2;
		
		inst1 <= inst;	
		inst2 <= inst1;
		inst3 <= inst2;
		inst4 <= inst3;
		
		rn_val1 <= rn_val;
		rn_val2 <= rn_val1;
		
		rm_val1 <= rm_val;
		rm_val2 <= rm_val1;
		
		pc <= new_pc;
		if (stop_pc == 1)
			pc1 <= pc1;
		else
			pc1 <= pc;
			
		pc2 <= pc1;
		pc3 <= pc2;
		pc4 <= pc3;
		
		res1 <= res;
		//res2 <= res1;
		uns_res1 <= uns_res;
		uns_comp_result1 <= uns_comp_result;
		comp_result1 <= comp_result;
	end
endmodule

`timescale 1 ps / 1 ps
module code_execution_testbench();
	logic [3:0] cond3;
	logic signed [63:0] rm_val2, rn_val2;
	logic signed [63:0] wr_val;
	logic [63:0] pc4;
	logic clk, reset, N, Z, C, V;
	
	cpu c(.*);
	
	parameter CLOCK1_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK1_PERIOD/2) clk <= ~clk;
	end

	initial begin
		$monitor("rm: %d, rn: %d, pc: %d, cond: %b, res: %d, NZCV: %b",
					rm_val2, rn_val2, pc4, cond3, wr_val, {N, Z, C, V});
		reset <= 1; @(posedge clk);  // expects nothing, address undefined
		reset <= 0; @(posedge clk);  // see test_command.txt for the commands used
						@(posedge clk);  
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
		$stop;
	end
endmodule
