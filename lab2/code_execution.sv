module code_execution(clk, reset, cond, pc, rm_val, rn_val, res, N, Z, C, V);
	input logic clk, reset;
	output logic [3:0] cond;
	output logic [63:0] pc;
	output logic signed [63:0] rm_val, rn_val;
	output logic signed [63:0] res;
	output logic N, Z, C, V;
	logic [4:0] rm_addr, rn_addr, rd_addr, wr_addr;
	logic [31:0] inst;
	logic [63:0] new_pc;
	logic signed [63:0] rd_val;
	logic [7:0] inst1, inst2, inst3, inst4;
	logic cond_res, wr_en, wide;
	
	// read instruction bytes from the code memory
	// assemble them together to get the instruction
	code_memory cm1(.pc(pc), .inst(inst1));
	code_memory cm2(.pc(pc + 1), .inst(inst2));
	code_memory cm3(.pc(pc + 2), .inst(inst3));
	code_memory cm4(.pc(pc + 3), .inst(inst4));
	assign inst = {inst1, inst2, inst3, inst4};
	
	operation op(.clock(clk), .reset, .pc, .rm_val, .rn_val, .uns_rm_val(rm_val), .uns_rn_val(rn_val),
					 .rd_val, .inst, .wr_en, .res, .wr_addr, .wide, .cond(cond_res), .N, .Z, .C, .V);
	
	// read registers
	// write new pc value to r15
	// write to target register
	regfile rf(.clock(clk), .reset, .addr1(rn_addr), .val1(rn_val), .addr2(rm_addr), .val2(rm_val),
				  .addr3(rd_addr), .val3(rd_val), .pc, .new_pc, .wr_en, .wide, .wr_addr, .wr_val(res));
	
	// read rm rn addresses
	// update flags
	// update pc
	always_comb begin
		// branches, exception and system instruction
		// conditional branch (immediate)
		// check if the condition is met for branching
		if (inst[28:26] == 3'b101 && inst[31:29] == 3'b010 && ~inst[24] & ~inst[4]) begin
			cond = inst[3:0];
			case(cond[3:1])
				3'b000: cond_res = Z;
				3'b001: cond_res = C;
				3'b010: cond_res = N;
				3'b011: cond_res = V;
				3'b100: cond_res = C & ~Z;
				3'b101: cond_res = N == V;
				3'b110: cond_res = (N == V) & ~Z;
				3'b111: cond_res = 1;
				default: cond_res = 1'bx;
			endcase
			if (cond[3:1] != 3'b111 && cond[0])
				cond_res = ~cond_res;
		end
		else if (inst[28] && inst[24:21] == 4'b0010 && inst[29] && ~inst[10] && ~inst[4]) begin // CMP
			cond = inst[15:12];
			case(cond[3:1])
				3'b000: cond_res = inst[2];
				3'b001: cond_res = inst[1];
				3'b010: cond_res = inst[3];
				3'b011: cond_res = inst[0];
				3'b100: cond_res = inst[1] & ~inst[2];
				3'b101: cond_res = inst[3] == inst[0];
				3'b110: cond_res = (inst[3] == inst[0]) & ~inst[2];
				3'b111: cond_res = 1;
				default: cond_res = 1'bx;
			endcase
			if (cond[3:1] != 3'b111 && cond[0])
				cond_res = ~cond_res;
		end
		else begin
			cond = 4'bxxxx;
			cond_res = 1'bx;
		end
		
		if (reset)
			new_pc = 0;
		else if (inst[28:26] == 3'b101) begin  // branches, exception and system instruction
				casex(inst[31:29]) 
					3'b010: if (~inst[24] & ~inst[4] & cond_res) // conditional branch(immediate)
							     new_pc = pc + 4 * inst[24:5];
							  else
								  new_pc = pc + 4;
					3'bx00: new_pc = pc + 4 * inst[25:0];  // unconditional branch
					3'bx01: if (~inst[25])  // compare and branch (immediate)
							     new_pc = pc + 4 * inst[23:5];
							  else  // test and branch (immeiate)
							     new_pc = pc + 4 * inst[18:5];
					3'b110: if (inst[25] && inst[24:21] == 4'd0 && inst[20:16] == 4'b1111 &&
									inst[15:10] == 5'd0 && inst[4:0] == 4'd0) //unconditional branch(register) BR
								  new_pc = rn_val;
							  else
								  new_pc = pc + 4;
					default: new_pc = 0;  // undefined behavior
				endcase
		end
		else  // not branching
			new_pc = pc + 4;
			
		if (reset) begin
			rm_addr = 5'bxxxxx;
			rn_addr = 5'bxxxxx;
		end
		
		// unconditional branch (register)
		else if (inst[28:26] == 3'b101 && inst[31:29] == 3'b110 && inst[25]) begin
			rn_addr = inst[9:5];
			rm_addr =5'bxxxxx;
			rd_addr =5'bxxxxx;
		end

		// immediate data process
		else if (inst[28:26] == 3'b100) begin
			rd_addr =5'bxxxxx;
			if (inst[25:23] == 3'b010) begin  // immediate add/subtract
				rn_addr = inst[9:5];
				rm_addr = 5'bxxxxx;
			end
			else if (inst[25:23] == 3'b011) begin  // immediate add/subtract with tags
				rn_addr = inst[9:5];
				rm_addr = 5'bxxxxx;
			end
			else if (inst[25:23] == 3'b100) begin  // immediate logic
				rn_addr = inst[9:5];
				rm_addr = 5'bxxxxx;
			end
			// if (inst[25:23] == 3'b101) begin  // immediate move wide
				// EMPTY
			// end
			else if (inst[25:23] == 3'b110) begin  // bitfield
				rn_addr = inst[9:5];
				rm_addr = 5'bxxxxx;
			end
			else if (inst[25:23] == 3'b111) begin  // extract
				rm_addr = inst[20:16];
				rn_addr = inst[9:5];
			end
			else begin
				rn_addr = 5'bxxxxx;
				rm_addr = 5'bxxxxx;
			end
		end
			
		// load and store
		// there are many unimplemented branches since they are not in lab 1
		else if (inst[28:25] == 4'bx1x0 && inst[31:28] == 4'bxx11) begin
			if (inst[24:23] == 2'b0x && inst[11:10] == 2'b10) begin  // load/store register (register offset)
				rm_addr = inst[20:16];
			end
			else
				rm_addr = 5'bxxxxx;
			rn_addr = inst[9:5];
			rd_addr = inst[4:0];
		end
			
		// register data process
		else if (inst[27:25] == 3'b101) begin
			rd_addr =5'bxxxxx;
			if (inst[28]) begin
				if (inst[24:21] == 4'b0110) begin
					if (!inst[30])  // data processing (2 source)
						rm_addr = inst[20:16];
					else
						rm_addr = 5'bxxxxx;
				end
				else if (inst[24:21] == 0) begin
					if (inst[15:10] == 0)
						rm_addr = inst[20:16];
					else
						rm_addr = 5'bxxxxx;
				end
				else if (inst[24:21] == 4'b0010) begin
					if (!inst[11])  // conditional compare register
						rm_addr = inst[20:16];
					else
						rm_addr = 5'bxxxxx;
				end
				else if (inst[24:21] == 4'b0100)  // conditional select
					rm_addr = inst[20:16];
				else if (inst[24])  // data-proccess (3 source)
					rm_addr = inst[20:16];
				else
					rm_addr = 5'bxxxxx;
			end
			else begin  // !inst[28]
				// all operations in this branch involves rm & rn
				rm_addr = inst[20:16];
			end
			rn_addr = inst[9:5];  // all instructions involves rn
		end
	
		else begin
			rd_addr =5'bxxxxx;
			rn_addr = 5'bxxxxx;
			rm_addr = 5'bxxxxx;
		end
	end
endmodule

`timescale 1 ps / 1 ps
module code_execution_testbench();
	logic [3:0] cond;
	logic signed [63:0] rm_val, rn_val;
	logic signed [63:0] res;
	logic [63:0] pc;
	logic clk, reset, N, Z, C, V;
	
	code_execution ce(.*);
	
	parameter CLOCK1_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK1_PERIOD/2) clk <= ~clk;
	end

	initial begin
		$monitor("rm: %d, rn: %d, pc: %d, cond: %b, res: %d, NZCV: %b",
					rm_val, rn_val, pc, cond, res, {N, Z, C, V});
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
		$stop;
	end
endmodule
