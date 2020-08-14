module load&store(inst, clk, );
	input logic [31:0] inst;
	input logic clk;
	
	logic [63:0] load_addr;  // address to load from the main memory
	logic load;  // a flag that identifies whether LDR operation is taken or not
	logic store_wide;  // a flag that identifies whether 64 or 32 bit is used in STR operation
	logic [63:0] load_data;  // data loaded from the main memory
	logic [63:0] store_addr;  // address to store data onto the main memory

	memory mem(.rd_addr(load_addr), .rd_data(load_data), wr_addr, wr_data, wr_en, .wide(store_wide), .clk(clock));

	always_comb begin
		if (inst[28:24] == 4'bx1x0) begin //load and store
			if (inst[31:28] == 4'b0X01 && ~inst[24] && ~inst[26]) begin  // LDR (literal)
				if (inst[30]) begin  // LDR 64bits
						store_wide = 0;
						load_addr = pc + inst[23:5];
				end
				else begin
				end
			end
			else if (inst[29:28] == 2'b11 && ~inst[24] && ~inst[21]) begin
				if (inst[11:10] == 2'b01) begin  // immediate LDR/STR (post-index)
				end
				else if (inst[11:10] == 11) begin  // immediate LDR/STR (pre-index)
				end
			end
		end
		else begin
			load_addr = 64'bx;
			store_wide = 0;
		end
	end

endmodule
