module pc_inc (pc, inst, rn_val, reset, stop, cond, new_pc);
	input logic [63:0] pc, rn_val;
	input logic [31:0] inst;
	input logic reset, stop, cond;
	output logic [63:0] new_pc;
	
	always_comb begin
		// update PC
		if (reset)
			new_pc = 0;
		else if (inst[28:26] == 3'b101) begin  // branches, exception and system instruction
				casex(inst[31:29]) 
					3'b010: if (~inst[24] & ~inst[4] & cond) // conditional branch(immediate)
							     new_pc = pc + 4 * inst[24:5] - 4;
							  else
								  new_pc = pc;
					3'bx00: new_pc = pc + 4 * inst[25:0] - 4;  // unconditional branch
					3'bx01: if (~inst[25])  // compare and branch (immediate)
							     new_pc = pc + 4 * inst[23:5] - 4;
							  else  // test and branch (immeiate)
							     new_pc = pc + 4 * inst[18:5] - 4;
					3'b110: if (inst[25] && inst[24:21] == 4'd0 && inst[20:16] == 4'b1111 &&
									inst[15:10] == 5'd0 && inst[4:0] == 4'd0) //unconditional branch(register) BR
								  new_pc = rn_val;
							  else
								  new_pc = pc;
					default: new_pc = 0;  // undefined behavior
				endcase
		end
		else if (stop)
			new_pc = pc;
		else  // not branching
			new_pc = pc + 4;
	end
endmodule
