module code_memory(pc, inst);
	input logic signed [63:0] pc;
	output logic [7:0] inst;
	
	logic [7:0] inst_set [63:0];
	
	initial begin
		inst_set[0] = 8'b10101011;
		inst_set[1] = 8'b00001000;
		inst_set[2] = 8'b00000011;
		inst_set[3] = 8'b11100000;
		inst_set[4] = 8'b00010100;
		inst_set[5] = 8'b00000000;
		inst_set[6] = 8'b00000000;
		inst_set[7] = 8'b00000010;
		inst_set[8] = 8'b00000000;
		inst_set[9] = 8'b00000000;
		inst_set[10] = 8'b00000000;
		inst_set[11] = 8'b00000000;
		inst_set[12] = 8'b11111010;
		inst_set[13] = 8'b01000000;
		inst_set[14] = 8'b00001011;
		inst_set[15] = 8'b01101111;
		inst_set[16] = 8'b11001011;
		inst_set[17] = 8'b00000001;
		inst_set[18] = 8'b00000000;
		inst_set[19] = 8'b10101010;
		inst_set[20] = 8'b01111010;
		inst_set[21] = 8'b01001010;
		inst_set[22] = 8'b01000011;
		inst_set[23] = 8'b00000111;
		inst_set[24] = 8'b11001010;
		inst_set[25] = 8'b00010011;
		inst_set[26] = 8'b00000011;
		inst_set[27] = 8'b11001101;
		inst_set[28] = 84;
		inst_set[29] = 0;
		inst_set[30] = 0;
		inst_set[31] = 79;
		inst_set[32] = 0;
		inst_set[33] = 0;
		inst_set[34] = 0;
		inst_set[35] = 0;
		inst_set[36] = 8'b10010001;
		inst_set[37] = 0;
		inst_set[38] = 8'b00100001;
		inst_set[39] = 8'b10101111;
	end
	
	always_comb
		inst = inst_set[pc];
endmodule
