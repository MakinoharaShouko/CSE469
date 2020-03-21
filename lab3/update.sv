module update(clk, reset, cond, stop, inst, rn_val, res, uns_res, uns_comp_result, comp_result, load_res,
				  N, Z, C, V, wr_en, wide, wr_addr, wr_val, pc);
	input logic clk, reset, cond, stop;
	input logic [31:0] inst;
	input logic [63:0] pc;
	input logic signed [63:0] res, load_res, rn_val;
	input logic [63:0] uns_res;
	input logic [64:0] uns_comp_result;
	input logic signed [64:0] comp_result;
	output logic N, Z, C, V, wr_en, wide;
	output logic [4:0] wr_addr;
	//output logic [63:0] new_pc;
	output logic signed [63:0] wr_val;
	
	/*always_comb begin
		// update PC
		if (reset)
			new_pc = 0;
		else if (inst[28:26] == 3'b101) begin  // branches, exception and system instruction
				casex(inst[31:29]) 
					3'b010: if (~inst[24] & ~inst[4] & cond) // conditional branch(immediate)
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
		pc_wr = | new_pc;
	end*/
	
	always_ff@(posedge clk) begin
		if (!stop) begin
		
			// update flag
			if (reset) begin
				Z <= 0;
				N <= 0;
				V <= 0;
				C <= 0;
			end
			else begin
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
		end
	end
	always_comb begin
		wr_en = 1'bx;
		wr_val = 64'bx;
		wr_addr = 5'bxxxxx;
		wide = 1'bx;
		// write to register
		if (!stop) begin
			casex(inst[28:25])			
				4'b100x: begin //Data processing (immediate)
					wr_en = 1;
					wr_val = res;
					wr_addr = inst[4:0];
					if (inst[25:23] == 3'b010) begin // add|subtract (immediate)
						if (~inst[31]) //arm32
							wide = 0;
						else //arm64
							wide = 1;
					end
						
					else if (inst[25:23] == 3'b100) begin //logical operation (immediate)
						if (inst[31])  //arm64
							wide = 1;
						else if (~inst[31] && ~inst[22])  //arm32
							wide = 0;
					end		
				
					else if (inst[25:23] == 3'b101) begin  // MOV
						if (inst[31])  //arm64
							wide = 1;
						else if (~inst[31] && ~inst[22])  //arm32
							wide = 0;
					end
				end
				
				4'bx1x0: begin //load and store
					if (inst[31:28] == 4'b0x01 && ~inst[24] && ~inst[26]) begin  // LDR (literal)
						wr_addr = inst[4:0];
						wr_en = 1;
						wide = 1;
						wr_val = load_res;
					end
					else if (inst[29:28] == 2'b11) begin
						if (~inst[24] && ~inst[21]) begin
							if (inst[11:10] == 01) begin  // immediate LDR/STR (post-index)
								if (inst[23:22] == 2'b01) begin  // LDR
									wr_addr = inst[4:0];
									wr_en = 1;
									wr_val = load_res;
									if (inst[31:30] == 2'b11)  // 64bits
										wide = 1;
									else if (inst[31:30] == 2'b10)  // LDR 32bits
										wide = 0;
								end
								else if (inst[23:22] == 2'b00) begin  // STR
									wr_addr = inst[4:0];
									wr_en = 1;
									wr_val = res;
									if (inst[31:30] == 2'b11)  // STR 64bits
										wide = 1;
									else if (inst[31:30] == 2'b10)  // STR 32bits
										wide = 0;
								end
							end
							else if (inst[11:10] == 01) begin  // immediate LDR/STR (pre-index)
								if (inst[23:22] == 2'b11) begin  // LDR
									wr_addr = inst[4:0];
									wr_en = 1;
									wr_val = load_res;
									if (inst[31:30] == 2'b11)  // 64bits
										wide = 1;
									else if (inst[31:30] == 2'b10)  // LDR 32bits
										wide = 0;
								end
								else if (inst[23:22] == 2'b00) begin  // STR
									if (inst[31:30] == 2'b11)  // STR 64bits
										wide = 1;
									else if (inst[31:30] == 2'b10)  // STR 32bits
										wide = 0;
								end
							end
						end
						else if (inst[24]) begin  // unsgined immediate
							if (inst[23:22] == 2'b01) begin  // LDR
								wr_addr = inst[4:0];
								wr_en = 1;
								wr_val = load_res;
								if (inst[31:30] == 2'b11)  // 64bits
									wide = 1;
								else if (inst[31:30] == 2'b10)  // LDR 32bits
									wide = 0;
							end
						end
					end
				end
				
				4'b101x: begin // branch
					if (inst[30:29] == 2'b00) begin
						if (inst[31]) begin //BL
							wr_val = res;
							wr_addr = 30;
							wr_en = 1; 
							wide = 1;
						end
					end
				end
				
				/*4'bx1x0: begin //load and store
					if (inst[29:28] == 2'b11 && ~inst[24] && ~inst[21]) begin
						if (inst[11:10] == 01) begin  // immediate LDR/STR (post-index)
							wr_en = 1;
							wide = 1;
							wr_addr = inst[9:5];
						end
					end
				end*/
				
				4'bx101: begin //data processing (register)
						if (~inst[28]) begin
							wr_val = res;
							if (~inst[24]) begin  // logical (shifted register)
								wr_en = 1;
								wr_addr = inst[4:0];
								if (inst[30:29] == 2'b00) begin // BIC
									if (inst[31]) // arm64
										wide = 1;
									else if (~inst[15]) //arm32
										wide = 0;
								end
								else if (inst[30:29] == 2'b00 || inst[30:29] == 2'b11) begin // AND
									if (inst[31])  // arm64
										wide = 1;
									else if (~inst[15])  //arm32
										wide = 0;
								end
								else if (inst[30:29] == 2'b01) begin //ORR 
									if (inst[31])  // arm64
										wide = 1;
									else if (~inst[15])  //arm32
										wide = 0;
								end
								else if (inst[30:29] == 2'b10) begin //EOR
									if (inst[31])  // arm64
										wide = 1;
									else if (~inst[15])  //arm32
										wide = 0;
								end
							end
							else if (inst[24]) begin
								if (~inst[21]) begin  // add/subtract (shifted register)
									wr_addr = inst[4:0];
									wr_en = 1;
									if (inst[21] == 0) begin
										if (inst[31])  // arm64
											wide = 1;
										else if (~inst[15]) //arm32
											wide = 0;
									end
								end
								else if (inst[21]) begin  // add/subtract (extended register)
									if (inst[23:22] == 2'b00 && inst[12:10] <= 4) begin
										wr_addr = inst[4:0];
										wr_en = 1;
										if (inst[31])  // 64
											wide = 1;
										else  // 32
											wide = 0;
										end
									end
								end
							end
						end
			endcase
		end
	end
endmodule
