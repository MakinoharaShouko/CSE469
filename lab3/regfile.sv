// This file implements a set of registers the processor reads from
module regfile (clock, reset, stop, addr1, val1, addr2, val2, addr3, val3, new_pc, wr_en, wide, wr_addr, wr_val);
	input logic clock, reset, stop, wr_en, wide; 
	input logic [4:0] addr1, addr2, addr3, wr_addr;
	input logic signed [63:0] wr_val;
	input logic [63:0] new_pc;
	output logic signed [63:0] val1, val2, val3;
	logic signed [63:0] reg_file [0:31];
	
	always_ff@(posedge clock) begin
		val1 <= reg_file[addr1];
		val2 <= reg_file[addr2];
		val3 <= reg_file[addr3];
		if (reset) begin
			reg_file[0] <= 114;
			reg_file[1] <= 514;
		end
		else begin
			if (~stop)
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
