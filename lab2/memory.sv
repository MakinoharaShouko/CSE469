module memory(rd_addr, rd_data, wr_addr, wr_data, wr_en, wide, reset, clk);
	input logic [63:0] rd_addr, wr_addr;
	input logic signed [63:0] wr_data;
	input logic wr_en, wide, clk, reset;
	output logic signed [63:0] rd_data;
	
	logic signed [63:0] memory [0:999];
	
	always_comb begin
		rd_data = memory[rd_addr];
	end
	
	always_ff@(posedge clk) begin
		if (reset) begin
			for (int i = 0; i < 1000; i ++)
				memory[i] <= 0;
		end
		else if (wr_en) begin  // store value on the memory
			if (wide)  // store 64 bit
				memory[wr_addr] <= wr_data;
			else  // store 32 bit
				memory[wr_addr][31:0] <= wr_data[31:0];
		end
	end
endmodule
