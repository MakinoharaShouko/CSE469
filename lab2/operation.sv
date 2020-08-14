module operation(clock, reset, pc, rm_val, rn_val, uns_rm_val, uns_rn_val, rd_val, inst, wr_en, res, wr_addr, wide, cond, N, Z, C, V);
	input logic clock, reset, cond;
	input logic [63:0] pc, uns_rm_val, uns_rn_val;
	input logic signed [63:0] rm_val, rn_val, rd_val;
	input logic [31:0] inst;
	output logic signed [63:0] res;  // operation result
	output logic wr_en, N, Z, C, V, wide;
	output logic [4:0] wr_addr;  // the register address that should be written
	
	logic [63:0] load_addr;  // address to load from the main memory
	logic store;  // a flag that identifies whether STR operation is taken or not
	logic store_wide;  // a flag that identifies whether 64 or 32 bit is used in STR operation
	logic [63:0] load_data;  // data loaded from the main memory
	logic [63:0] store_addr;  // address to store data onto the main memory
	logic [63:0] store_data;  // data to write into the main memory
	
	logic [63:0] uns_res;
	logic [64:0] uns_comp_result; 
	logic signed [64:0] comp_result;
	
	// accessing the main memory
	memory mem(.rd_addr(load_addr), .rd_data(load_data), .wr_addr(store_addr), .wr_data(store_data),
				  .wr_en(store), .wide(store_wide), .reset, .clk(clock));
	
	always_comb begin
		comp_result = 65'bx;
		uns_comp_result = 65'bx;
		load_addr = 64'bx;
		store_wide = 1'bx;
		store_addr = 64'bx;
		store_data = 64'bx;
		store = 1'bx;
		wr_addr = 5'bx;
		wr_en = 1'bx;
		wide = 1'bx;
		res = 64'bx;
		uns_res = 64'bx;
		
		casex(inst[28:25])			
			4'b100x: begin //Data processing (immediate)
				wr_en = 1;
				wr_addr = inst[4:0];
				if (inst[25:23] == 3'b010) begin // add|subtract (immediate)
					if (~inst[31]) begin //arm32
						wide = 0;
						if (inst[30]) begin  // SUB
							if (inst[22]) begin
								res[31:0] = rn_val[31:0] - {8'b0, inst[21:10], 12'b0};
								uns_res[31:0] = uns_rn_val[31:0] - {8'b0, inst[21:10], 12'b0};
								comp_result[32:0] = {rn_val[31], rn_val[31:0]} - {9'b0, inst[21:10], 12'b0};
								uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} - {9'b0, inst[21:10], 12'b0};
							end
							else begin
								res[31:0] = rn_val[31:0] - {20'b0, inst[21:10]};
								uns_res[31:0] = uns_rn_val[31:0] - {21'b0, inst[21:10]};
								comp_result[32:0] = {rn_val[31], rn_val[31:0]} - {21'b0, inst[21:10]};
								uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} - {21'b0, inst[21:10]};
							end
						end			
						else begin  //ADD
							if (inst[22]) begin
								res[31:0] = rn_val[31:0] + {8'b0, inst[21:10], 12'b0};
								uns_res[31:0] = uns_rn_val[31:0] + {8'b0, inst[21:10], 12'b0};
								comp_result[32:0] = {rn_val[31], rn_val[31:0]} + {9'b0, inst[21:10], 12'b0};
								uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + {9'b0, inst[21:10], 12'b0};
							end
							else begin
								res[31:0] = rn_val[31:0] + {20'b0, inst[21:10]};
								uns_res[31:0] = uns_rn_val[31:0] + {20'b0, inst[21:10]};
								comp_result[32:0] = {rn_val[31], rn_val[31:0]} + {21'b0, inst[21:10]};
								uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + {21'b0, inst[21:10]};
							end
						end
					end
					else begin //arm64
						wide = 1;
						if (inst[30]) begin  // SUB
							if (inst[22]) begin
								res = rn_val - {40'b0, inst[21:10], 12'b0};
								uns_res = uns_rn_val - {40'b0, inst[21:10], 12'b0};
								comp_result = {rn_val[63], rn_val} - {41'b0, inst[21:10], 12'b0};
								uns_comp_result = {1'b0, uns_rn_val} - {41'b0, inst[21:10], 12'b0};
							end
							else begin
								res = rn_val - {52'b0, inst[21:10]};
								uns_res = uns_rn_val - {52'b0, inst[21:10]};
								comp_result = {rn_val[63], rn_val} - {53'b0, inst[21:10]};
								uns_comp_result = {1'b0, uns_rn_val} - {53'b0, inst[21:10]};
							end
						end			
						else begin  //ADD
							if (inst[22]) begin
								res = rn_val + {40'b0, inst[21:10], 12'b0};
								uns_res = uns_rn_val + {40'b0, inst[21:10], 12'b0};
								comp_result = {rn_val[63], rn_val} + {41'b0, inst[21:10], 12'b0};
								uns_comp_result = {1'b0, uns_rn_val} + {41'b0, inst[21:10], 12'b0};
							end
							else begin
								res = rn_val + {52'b0, inst[21:10]};
								uns_res = uns_rn_val + {52'b0, inst[21:10]};
								comp_result = {rn_val[63], rn_val} + {53'b0, inst[21:10]};
								uns_comp_result = {1'b0, uns_rn_val} + {53'b0, inst[21:10]};
							end
						end
					end
				end
					
				else if (inst[25:23] == 3'b100) begin //logical operation (immediate)
					if (inst[31]) begin //arm64
						wide = 1;
						if (inst[30:29] == 2'b00 || inst[30:29] == 2'b11)  //AND 
							res = rn_val & {inst[22], inst[15:10], inst[21:16]};
						else if (inst[30:29] == 2'b01)  // ORR
							res = rn_val | {inst[22], inst[15:10], inst[21:16]};
						else if (inst[30:29] == 2'b10)  //EOR
							res = rn_val ^ {inst[22], inst[15:10], inst[21:16]};
					end
					else if (~inst[31] && ~inst[22]) begin //arm32
						wide = 0;
						if (inst[30:29] == 2'b00 || inst[30:29] == 2'b11)  //AND 
							res[31:0] = rn_val[31:0] & {inst[15:10], inst[21:16]};
						else if (inst[30:29] == 2'b01)  // ORR
							res[31:0] = rn_val[31:0] | {inst[15:10], inst[21:16]};
						else if (inst[30:29] == 2'b10)  //EOR
							res[31:0] = rn_val[31:0] ^ {inst[15:10], inst[21:16]};
					end
				end		
			
				else if (inst[25:23] == 3'b101) begin  // MOV
					if (inst[31]) begin //arm64
						wide = 1;
						if (inst[30:29] == 2'b00)  //MOVN
							res = ~({48'b0, {inst[20:5]}} << (inst[22:21] * 16));
						else if (inst[30:29] == 2'b10)  //MOVZ
							res = {48'b0, {inst[20:5]}} << (inst[22:21] * 16);
						else if (inst[30:29] == 2'b11) begin  //MOVK
							res = rd_val;
							res[15 + (inst[22:21] * 16) -: 16] <= comp_result[15 + (inst[22:21] * 16) -: 16] & {48'b0, {inst[20:5]}};
						end
					end
					else if (~inst[31] && ~inst[22]) begin //arm32
						wide = 0;
						if (inst[30:29] == 2'b00)  //MOVN
							res[31:0] = ~({16'b0, {inst[20:5]}} << (inst[22:21] * 16));
						else if (inst[30:29] == 2'b10)  //MOVZ
							res[31:0] = {16'b0, {inst[20:5]}} << (inst[22:21] * 16);
						else if (inst[30:29] == 2'b11) begin  //MOVK
							res = rd_val;
							res[15 + (inst[22:21] * 16) -: 16] = comp_result[15 + (inst[22:21] * 16) -: 16] & {48'b0, {inst[20:5]}};
						end
					end
				end
			end
			
			4'bx1x0: begin //load and store
				if (inst[31:28] == 4'b0X01 && ~inst[24] && ~inst[26]) begin  // LDR (literal)
					load_addr = pc + inst[23:5];
					wr_addr = inst[4:0];
					wr_en = 1;
					wide = 1;
					res = load_data;
				end
				else if (inst[29:28] == 2'b11 && ~inst[24] && ~inst[21]) begin
					if (inst[11:10] == 11) begin  // immediate LDR/STR (pre-index)
						if (inst[23:22] == 2'b01) begin  // LDR
							wr_addr = inst[4:0];
							load_addr = rn_val + inst[20:12];
							if (inst[31:30] == 2'b11) begin  // 64bits
								wr_en = 1;
								wide = 1;
								res = load_data;
							end
							else if (inst[31:30] == 2'b10) begin  // LDR 32bits
								wr_en = 1;
								wide = 0;
								res = load_data;
							end
						end
						else if (inst[23:22] == 2'b00) begin  // STR
							store_addr = rn_val + inst[20:12];
							store_data = rd_val;
							store = 1;
							if (inst[31:30] == 2'b11) begin  // STR 64bits
								store_wide = 1;
							end
							else if (inst[31:30] == 2'b10) begin// STR 32bits
								store_wide = 0;
							end
						end
					end
				end
			end
			
			4'b101x: begin // branch
				if (inst[30:29] == 2'b00) begin
					if (inst[31]) begin //BL
						wr_addr = 30;
						res = pc + 4;
					end
				end
			end
			
			4'bx101: begin //data processing (register)
					if (~inst[28]) begin
						if (~inst[24]) begin  // logical (shifted register)
							wr_en = 1;
							wr_addr = inst[4:0];
							if (inst[30:29] == 2'b00) begin // BIC
								if (inst[31]) begin // arm64
									wide = 1;
									if (inst[23:22] == 2'b00)  //LSL
										res = rn_val & (~(rm_val << inst[15:10]));
									else if (inst[23:22] == 2'b01)  //LSR
										res = rn_val & (~(rm_val >> inst[15:10]));
									else if (inst[23:22] == 2'b10)  //ASR
										res = rn_val & (~(rm_val >>> inst[15:10]));
								end
								else if (~inst[15]) begin //arm32
									wide = 0;
									if (inst[23:22] == 2'b00)  //LSL
										res[31:0] = rn_val[31:0] & (~(rm_val[31:0] << inst[15:10]));
									else if (inst[23:22] == 2'b01)  //LSR
										res[31:0] = rn_val[31:0] & (~(rm_val[31:0] >> inst[15:10]));
									else if (inst[23:22] == 2'b10)  //ASR
										res[31:0] = rn_val[31:0] & (~(rm_val[31:0] >>> inst[15:10]));
								end
							end
							else if (inst[30:29] == 2'b00 || inst[30:29] == 2'b11) begin // AND
								if (inst[31]) begin // arm64
									wide = 1;
									if (inst[23:22] == 2'b00)  //LSL
										res = rn_val & (rm_val << inst[15:10]);
									else if (inst[23:22] == 2'b01)  //LSR
										res = rn_val & (rm_val >> inst[15:10]);
									else if (inst[23:22] == 2'b10)  //ASR
										res = rn_val & rm_val >>> (inst[15:10]);
								end
								else if (~inst[15]) begin //arm32
									wide = 0;
									if (inst[23:22] == 2'b00)  //LSL
										res[31:0] = rn_val[31:0] & (rm_val[31:0] << inst[15:10]);
									else if (inst[23:22] == 2'b01)  //LSR
										res[31:0] = rn_val[31:0] & (rm_val[31:0] >> inst[15:10]);
									else if (inst[23:22] == 2'b10)  //ASR
										res[31:0] = rn_val[31:0] & (rm_val[31:0] >>> inst[15:10]);
								end
							end
							else if (inst[30:29] == 2'b01) begin //ORR 
								if (inst[31]) begin // arm64
									wide = 1;
									if (inst[23:22] == 2'b00)  //LSL
										res = rn_val | (rm_val << inst[15:10]);
									else if (inst[23:22] == 2'b01)  //LSR
										res = rn_val | (rm_val >> inst[15:10]);
									else if (inst[23:22] == 2'b10)  //ASR
										res = rn_val | (rm_val >>> inst[15:10]);
								end
								else if (~inst[15]) begin //arm32
									wide = 0;
									if (inst[23:22] == 2'b00)  //LSL
										res[31:0] = rn_val[31:0] | (rm_val[31:0] << inst[15:10]);
									else if (inst[23:22] == 2'b01)  //LSR
										res[31:0] = rn_val[31:0] | (rm_val[31:0] >> inst[15:10]);
									else if (inst[23:22] == 2'b10)  //ASR
										res[31:0] = rn_val[31:0] | (rm_val[31:0] >>> inst[15:10]);
								end
							end
							else if (inst[30:29] == 2'b10) begin //EOR
								if (inst[31]) begin // arm64
									wide = 1;
									if (inst[23:22] == 2'b00)  //LSL
										res = rn_val ^ (rm_val << inst[15:10]);
									else if (inst[23:22] == 2'b01)  //LSR
										res = rn_val ^ (rm_val >> inst[15:10]);
									else if (inst[23:22] == 2'b10)  //ASR
										res = rn_val ^ (rm_val >>> inst[15:10]);
								end
								else if (~inst[15]) begin //arm32
									wide = 0;
									if (inst[23:22] == 2'b00)  //LSL
										res[31:0] = rn_val[31:0] ^ (rm_val[31:0] << inst[15:10]);
									else if (inst[23:22] == 2'b01)  //LSR
										res[31:0] = rn_val[31:0] ^ (rm_val[31:0] >> inst[15:10]);
									else if (inst[23:22] == 2'b10)  //ASR
										res[31:0] = rn_val[31:0] ^ (rm_val[31:0] >>> inst[15:10]);
								end
							end
						end
						else if (inst[24]) begin
							if (~inst[21]) begin  // add/subtract (shifted register)
								wr_addr = inst[4:0];
								wr_en = 1;
								if (inst[21] == 0) begin
									if (inst[30]) begin //SUB
										if (inst[31]) begin // arm64
											wide = 1;
											if (inst[23:22] == 2'b00) begin  //LSL
												res = rn_val - (rm_val << inst[15:10]);
												uns_res = uns_rn_val - (uns_rm_val << inst[15:10]);
												comp_result = {rn_val[63], rn_val} - ({rm_val[63], rm_val} << inst[15:10]);
												uns_comp_result = {1'b0, uns_rn_val} - ({1'b0, uns_rm_val} << inst[15:10]);
											end
											else if (inst[23:22] == 2'b01) begin //LSR
												res = rn_val - (rm_val >> inst[15:10]);
												uns_res = uns_rn_val - (uns_rm_val >> inst[15:10]);
												comp_result = {rn_val[63], rn_val} - ({rm_val[63], rm_val} >> inst[15:10]);
												uns_comp_result = {1'b0, uns_rn_val} - ({1'b0, uns_rm_val} >> inst[15:10]);
											end
											else if (inst[23:22] == 2'b10) begin  //ASR
												res = rn_val - (rm_val >>> inst[15:10]);
												uns_res = uns_rn_val - (uns_rm_val >>> inst[15:10]);
												comp_result = {rn_val[63], rn_val} - ({rm_val[63], rm_val} >>> inst[15:10]);
												uns_comp_result = {1'b0, uns_rn_val} - ({1'b0, uns_rm_val} >>> inst[15:10]);
											end
										end
										else if (~inst[15]) begin//arm32
											wide = 0;
											if (inst[23:22] == 2'b00) begin  //LSL
												res[32:0] = rn_val[31:0] - (rm_val[31:0] << inst[15:10]);
												uns_res[32:0] = uns_rn_val[31:0] - (uns_rm_val[31:0] << inst[15:10]);
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} - ({rm_val[31], rm_val[31:0]} << inst[15:10]);
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} - ({1'b0, uns_rm_val[31:0]} << inst[15:10]);
											end
											else if (inst[23:22] == 2'b01) begin  //LSR
												res[32:0] = rn_val[31:0] - (rm_val[31:0] >> inst[15:10]);
												uns_res[32:0] = uns_rn_val[31:0] - (uns_rm_val[31:0] >> inst[15:10]);
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} - ({rm_val[31], rm_val[31:0]} >> inst[15:10]);
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} - ({1'b0, uns_rm_val[31:0]} >> inst[15:10]);
											end
											else if (inst[23:22] == 2'b10) begin  //ASR
												res[32:0] = rn_val[31:0] - (rm_val[31:0] >>> inst[15:10]);
												uns_res[32:0] = uns_rn_val[31:0] - (uns_rm_val[31:0] >>> inst[15:10]);
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} - ({rm_val[31], rm_val[31:0]} >>> inst[15:10]);
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} - ({1'b0, uns_rm_val[31:0]} >>> inst[15:10]);
											end
										end
									end
									else begin //ADD
										if (inst[31]) begin // arm64
											wide = 1;
											if (inst[23:22] == 2'b00) begin  //LSL
												res = rn_val + (rm_val << inst[15:10]);
												uns_res = uns_rn_val + (uns_rm_val << inst[15:10]);
												comp_result = {rn_val[63], rn_val} + ({rm_val[63], rm_val} << inst[15:10]);
												uns_comp_result = {1'b0, uns_rn_val} + ({1'b0, uns_rm_val} << inst[15:10]);
											end
											else if (inst[23:22] == 2'b01) begin //LSR
												res = rn_val + (rm_val >> inst[15:10]);
												uns_res = uns_rn_val + (uns_rm_val >> inst[15:10]);
												comp_result = {rn_val[63], rn_val} + ({rm_val[63], rm_val} >> inst[15:10]);
												uns_comp_result = {1'b0, uns_rn_val} + ({1'b0, uns_rm_val} >> inst[15:10]);
											end
											else if (inst[23:22] == 2'b10) begin  //ASR
												res = rn_val + (rm_val >>> inst[15:10]);
												uns_res = uns_rn_val + (uns_rm_val >>> inst[15:10]);
												comp_result = {rn_val[63], rn_val} + ({rm_val[63], rm_val} >>> inst[15:10]);
												uns_comp_result = {1'b0, uns_rn_val} + ({1'b0, uns_rm_val} >>> inst[15:10]);
											end
										end
										else if (~inst[15]) begin//arm32
											wide = 0;
											if (inst[23:22] == 2'b00) begin  //LSL
												res[32:0] = rn_val[31:0] + (rm_val[31:0] << inst[15:10]);
												uns_res[32:0] = uns_rn_val[31:0] + (uns_rm_val[31:0] << inst[15:10]);
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} + ({rm_val[31], rm_val[31:0]} << inst[15:10]);
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + ({1'b0, uns_rm_val[31:0]} << inst[15:10]);
											end
											else if (inst[23:22] == 2'b01) begin  //LSR
												res[32:0] = rn_val[31:0] + (rm_val[31:0] >> inst[15:10]);
												uns_res[32:0] = uns_rn_val[31:0] + (uns_rm_val[31:0] >> inst[15:10]);
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} + ({rm_val[31], rm_val[31:0]} >> inst[15:10]);
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + ({1'b0, uns_rm_val[31:0]} >> inst[15:10]);
											end
											else if (inst[23:22] == 2'b10) begin  //ASR
												res[32:0] = rn_val[31:0] + (rm_val[31:0] >>> inst[15:10]);
												uns_res[32:0] = uns_rn_val[31:0] + (uns_rm_val[31:0] >>> inst[15:10]);
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} + ({rm_val[31], rm_val[31:0]} >>> inst[15:10]);
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + ({1'b0, uns_rm_val[31:0]} >>> inst[15:10]);
											end
										end
									end
								end
							end
							else if (inst[21]) begin  // add/subtract (extended register)
								if (inst[23:22] == 2'b00 && inst[12:10] <= 4) begin
									wr_addr = inst[4:0];
									wr_en = 1;
									if (inst[30]) begin  // sub
										case(inst[15:13])
											3'b000: res = uns_rn_val - ({56'b0, uns_rm_val[7:0]} << inst[12:10]);
											3'b001: res = uns_rn_val - ({48'b0, uns_rm_val[15:0]} << inst[12:10]);
											3'b010: res = uns_rn_val - ({32'b0, uns_rm_val[31:0]} << inst[12:10]);
											3'b011: res = uns_rn_val - (uns_rm_val << inst[12:10]);
											3'b100: res = rn_val - ({56'b0, rm_val[7:0]} << inst[12:10]);
											3'b101: res = rn_val - ({48'b0, rm_val[15:0]} << inst[12:10]);
											3'b110: res = rn_val - ({32'b0, rm_val[31:0]} << inst[12:10]);
											3'b111: res = rn_val - (rm_val << inst[12:10]);
										endcase
										if (inst[31])  // 64
											wide = 1;
										else  // 32
											wide = 0;
									end
									else begin  // add
										case(inst[15:13])
											3'b000: res = uns_rn_val + ({56'b0, uns_rm_val[7:0]} << inst[12:10]);
											3'b001: res = uns_rn_val + ({48'b0, uns_rm_val[15:0]} << inst[12:10]);
											3'b010: res = uns_rn_val + ({32'b0, uns_rm_val[31:0]} << inst[12:10]);
											3'b011: res = uns_rn_val + (uns_rm_val << inst[12:10]);
											3'b100: res = rn_val + ({56'b0, rm_val[7:0]} << inst[12:10]);
											3'b101: res = rn_val + ({48'b0, rm_val[15:0]} << inst[12:10]);
											3'b110: res = rn_val + ({32'b0, rm_val[31:0]} << inst[12:10]);
											3'b111: res = rn_val + (rm_val << inst[12:10]);
										endcase
										if (inst[31])  // 64
											wide = 1;
										else  // 32
											wide = 0;
									end
								end
							end
						end
					end
					else begin
						if (inst[28] && inst[24:21] == 4'b0010) begin
							if (inst[11]) begin
								if (inst[29] && ~inst[10] && ~inst[4]) begin  // CMP (immediate)
									if (cond) begin  // check conditional code
										if (inst[30]) begin  // CCMP
											if (inst[31]) begin  // 64
												res = rn_val + (~{59'b0, inst[20:16]}) + 1;
												uns_res = uns_rn_val + (~{59'b0, inst[20:16]}) + 1;
												comp_result = {rn_val[63], rn_val} + (~{60'b0, inst[20:16]}) + 1;
												uns_comp_result = {1'b0, uns_rn_val} + (~{60'b0, inst[20:16]}) + 1;
											end
											else begin  // 32
												res[31:0] = rn_val[31:0] + (~{27'b0, inst[20:16]}) + 1;
												uns_res[31:0] = uns_rn_val[31:0] + (~{27'b0, inst[20:16]}) + 1;
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} + (~{28'b0, inst[20:16]}) + 1;
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + (~{28'b0, inst[20:16]}) + 1;
											end
										end
										else begin  // CCMN
											if (inst[31]) begin  // 64
												res = rn_val + {59'b0, inst[20:16]};
												uns_res = uns_rn_val + {59'b0, inst[20:16]};
												comp_result = {rn_val[63], rn_val} + {60'b0, inst[20:16]};
												uns_comp_result = {1'b0, uns_rn_val} + {60'b0, inst[20:16]};
											end
											else begin  // 32
												res[32:0] = rn_val[31:0] + {27'b0, inst[20:16]};
												uns_res[32:0] = uns_rn_val[31:0] + {27'b0, inst[20:16]};
												comp_result[32:0] = {rn_val[31], rn_val[31:0]} + {28'b0, inst[20:16]};
												uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + {28'b0, inst[20:16]};
											end
										end
									end
								end
								else begin
									if (inst[29] && ~inst[10] && ~inst[4]) begin  // CMP (register)
										if (cond) begin
											if (inst[30]) begin  // CCMP
												if (inst[31]) begin  // 64
													res = rn_val + ~rm_val + 1;
													uns_res = uns_rn_val + ~uns_rm_val + 1;
													comp_result = {rn_val[63], rn_val} + ~{rm_val[63], rm_val} + 1;
													uns_comp_result = {1'b0, uns_rn_val} + ~{1'b0, uns_rm_val} + 1;
												end
												else begin  // 32
													res[32:0] = rn_val[31:0] + ~rm_val[31:0] + 1;
													uns_res[32:0] = uns_rn_val[31:0] + ~uns_rm_val[31:0] + 1;
													comp_result[32:0] = {rn_val[31], rn_val[31:0]} + ~{rm_val[31], rm_val[31:0]} + 1;
													uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + ~{1'b0, uns_rm_val[31:0]} + 1;
												end
											end
											else begin  // CCMN
												if (inst[31]) begin  // 64
													res = rn_val + rm_val + 1;
													uns_res = uns_rn_val + uns_rm_val + 1;
													comp_result = {rn_val[63], rn_val} + {rm_val[63], rm_val} + 1;
													uns_comp_result = {1'b0, uns_rn_val} + {1'b0, uns_rm_val} + 1;
												end
												else begin  // 32
													res[32:0] = rn_val[31:0] + rm_val[31:0] + 1;
													uns_res[32:0] = uns_rn_val[31:0] + uns_rm_val[31:0] + 1;
													comp_result[32:0] = {rn_val[31], rn_val[31:0]} + {rm_val[31], rm_val[31:0]} + 1;
													uns_comp_result[32:0] = {1'b0, uns_rn_val[31:0]} + {1'b0, uns_rm_val[31:0]} + 1;
												end
											end
										end
									end
								end
							end
						end
					end
				end
		endcase
	end

	always_ff @(posedge clock) begin
		// flags
		casex(inst[28:25])
			4'b100x: begin //Data processing (immediate)
					if (inst[25:23] == 3'b010 && inst[29]) begin // add|subtract (immediate)
						if (~inst[31]) begin //arm32
							if (uns_comp_result[32])
								C <= 1;  // unsigned carry
							else
								C <= 0;
								
							if (comp_result[32:0] != {res[31], res[31:0]})
								V <= 1;  // signed overflow
							else
								V <= 0;

							if (res[31:0] == 0) begin  // result is 0
								Z <= 1;
								N <= 0;
							end
							else begin  // non-zero
								if (res[31:0] < 0)  // negative
									N <= 1;
								else  // positive
									N <= 0;
								Z <= 0;
							end
						end
						else begin //arm64
							if (uns_comp_result[64])
								C <= 1;  // unsigned carry
							else
								C <= 0;
								
							if (comp_result != {res[63], res})
								V <= 1;  // signed overflow
							else
								V <= 0;
							
							if (res == 0) begin  // result is 0
								Z <= 1;
								N <= 0;
							end
							else begin  // non-zero
								if (res < 0)  // negative
									N <= 1;
								else  // positive
									N <= 0;
								Z <= 0;
							end
						end
					end	
						
					else if (inst[25:23] == 3'b100 && inst[30:29] == 2'b11) begin //logical operation (immediate)
						C <= 0;
						V <= 0;
						if (inst[31]) begin //arm64
							if (res[31:0] == 0) begin  // result is 0
								Z <= 1;
								N <= 0;
							end
							else begin  // non-zero
								if (res[31:0] < 0)  // negative
									N <= 1;
								else  // positive
									N <= 0;
								Z <= 0;
							end
						end
						else if (~inst[31] && ~inst[22]) begin //arm32
							if (res == 0) begin  // result is 0
								Z <= 1;
								N <= 0;
							end
							else begin  // non-zero
								if (res < 0)  // negative
									N <= 1;
								else  // positive
									N <= 0;
								Z <= 0;
							end
						end
					end							
					/*	
					else if (inst[25:23] == 3'b101) begin  // MOV
						C <= 0;
						V <= 0;
						N <= 0;
						Z <= 0;
					end*/
				end
			/*
			4'bx1x0: begin //load and store
							C <= 0;
							V <= 0;
							N <= 0;
							Z <= 0;
						end
						
			4'b101x: begin // branch
							C <= 0;
							V <= 0;
							N <= 0;
							Z <= 0;
						end
			*/			
			4'bx101: begin //data processing (register)
							if (~inst[28]) begin
								if (~inst[24] && inst[30:29] == 2'b11) begin  // logical (shifted register)
									C <= 0;
									V <= 0;
									if (inst[31]) begin //arm64
										if (res == 0) begin  // result is 0
											Z <= 1;
											N <= 0;
										end
										else begin  // non-zero
											if (res < 0)  // negative
												N <= 1;
											else  // positive
												N <= 0;
											Z <= 0;
										end
									end
									else if (~inst[15]) begin  // arm32
										if (res[31:0] == 0) begin  // result is 0
											Z <= 1;
											N <= 0;
										end
										else begin  // non-zero
											if (res[31:0] < 0)  // negative
												N <= 1;
											else  // positive
												N <= 0;
											Z <= 0;
										end
									end
									else begin
									end
								end
								else if (inst[24]) begin
									if (inst[29]) begin  // add/subtract
										if (~inst[31] && ~inst[15]) begin //arm32
											if (uns_comp_result[32])
												C <= 1;  // unsigned carry
											else
												C <= 0;
												
											if (comp_result[32:0] != {res[31], res[31:0]})
												V <= 1;  // signed overflow
											else
												V <= 0;
					
											if (res[31:0] == 0) begin  // result is 0
												Z <= 1;
												N <= 0;
											end
											else begin  // non-zero
												if (res[31:0] < 0)  // negative
													N <= 1;
												else  // positive
													N <= 0;
												Z <= 0;
											end
										end
										else begin //arm64
											if (uns_comp_result[64])
												C <= 1;  // unsigned carry
											else
												C <= 0;
												
											if (comp_result != {res[63], res})
												V <= 1;  // signed overflow
											else
												V <= 0;
											
											if (res == 0) begin  // result is 0
												Z <= 1;
												N <= 0;
											end
											else begin  // non-zero
												if (res < 0)  // negative
													N <= 1;
												else  // positive
													N <= 0;
												Z <= 0;
											end
										end
									end	
								end
							end
							else begin
								// CMP
								if (inst[28] && inst[24:21] == 4'b0010 && inst[29] && ~inst[10] && ~inst[4]) begin
									if (cond) begin
										if (~inst[31]) begin //arm32
											if (uns_comp_result[32])
												C <= 1;  // unsigned carry
											else
												C <= 0;
												
											if (comp_result[32:0] != {res[31], res[31:0]})
												V <= 1;  // signed overflow
											else
												V <= 0;
					
											if (res[31:0] == 0) begin  // result is 0
												Z <= 1;
												N <= 0;
											end
											else begin  // non-zero
												if (res[31:0] < 0)  // negative
													N <= 1;
												else  // positive
													N <= 0;
												Z <= 0;
											end
										end
										else begin //arm64
											if (uns_comp_result[64])
												C <= 1;  // unsigned carry
											else
												C <= 0;
												
											if (comp_result != {res[63], res})
												V <= 1;  // signed overflow
											else
												V <= 0;
											
											if (res == 0) begin  // result is 0
												Z <= 1;
												N <= 0;
											end
											else begin  // non-zero
												if (res < 0)  // negative
													N <= 1;
												else  // positive
													N <= 0;
												Z <= 0;
											end
										end
									end
								end
							end
						end
			
		endcase
	end						
endmodule
