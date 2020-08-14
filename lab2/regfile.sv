// This file implements a set of registers the processor reads from
module regfile (clock, reset, addr1, val1, addr2, val2, addr3, val3, pc, new_pc, wr_en, wide, wr_addr, wr_val);
	input logic clock, reset, wr_en, wide; 
	input logic [4:0] addr1, addr2, addr3, wr_addr;
	input logic signed [63:0] wr_val;
	input logic [63:0] new_pc;
	output logic signed [63:0] val1, val2, val3;
	output logic [63:0] pc;
	logic signed [31:0] reg_file [63:0];
	
	always_comb begin
		val1 = reg_file[addr1];
		val2 = reg_file[addr2];
		val3 = reg_file[addr3];
		pc = reg_file[15];
	end
	
	always_ff@(posedge clock) begin
		if (reset) begin
			reg_file[0] <= 12;
			reg_file[1] <= 810;
			reg_file[2] <= 0;
			reg_file[3] <= 0;
			reg_file[4] <= 0;
			reg_file[5] <= 46;
			reg_file[6] <= 8;
			reg_file[7] <= 0;
			reg_file[8] <= 114;
			reg_file[9] <= 0;
			reg_file[10] <= 46;
			reg_file[11] <= 0;
			reg_file[12] <= 0;
			reg_file[13] <= 15;
			reg_file[14] <= 0;
			reg_file[15] <= 0;
			reg_file[16] <= 0;
			reg_file[17] <= 0;
			reg_file[18] <= 3;
			reg_file[19] <= 23;
			reg_file[20] <= 0;
			reg_file[21] <= 0;
			reg_file[22] <= 0;
			reg_file[23] <= 0;
			reg_file[24] <= 7;
			reg_file[25] <= 0;
			reg_file[26] <= 0;
			reg_file[27] <= -1919;
			reg_file[28] <= 5;
			reg_file[29] <= 0;
			reg_file[30] <= 77;
			reg_file[31] <= 514;
		end
		else begin
			reg_file[15] <= new_pc;
			if (wr_en) begin
				if (wide)
					reg_file[wr_addr] <= wr_val;
				else
					reg_file[wr_addr][31:0] <= wr_val[31:0];
			end
		end
	end
endmodule
