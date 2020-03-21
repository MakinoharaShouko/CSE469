// get the registers to access from the instruction
module register_addr(reset, inst, rm_addr, rn_addr, rd_addr);
	input logic [31:0] inst;
	input logic reset;
	output logic [4:0] rm_addr, rn_addr, rd_addr;
	// read rm rn addresses
	// update flags
	// update pc
	always_comb begin
		if (reset) begin
			rm_addr = 5'bxxxxx;
			rn_addr = 5'bxxxxx;
			rd_addr = 5'bxxxxx;
		end
		
		// unconditional branch (register)
		else if (inst[28:26] == 3'b101 && inst[31:29] == 3'b110 && inst[25]) begin
			rn_addr = inst[9:5];
			rm_addr =5'bxxxxx;
			rd_addr =5'bxxxxx;
		end

		// immediate data process
		else if (inst[28:26] == 3'b100) begin
			rd_addr = inst[4:0];
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
		else if (inst[28] && ~inst[25] && inst[29:28] == 4'b11) begin
			if (~inst[24] && inst[21] && inst[11:10] == 2'b10)  // load/store register (register offset)
				rm_addr = inst[20:16];
			else
				rm_addr = 5'bxxxxx;
				
			rn_addr = inst[9:5];
			rd_addr = inst[4:0];
		end
			
		// register data process
		else if (inst[27:25] == 3'b101) begin
			rd_addr = inst[4:0];
			if (inst[28]) begin
				if (inst[24:21] == 4'b0110) begin
					if (~inst[30])  // data processing (2 source)
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
					if (~inst[11])  // conditional compare register
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
			else begin  // ~inst[28]
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
