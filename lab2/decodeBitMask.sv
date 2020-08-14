module decodeBitMask(N, imms, immr, mask, immediate);
	input logic N, immediate;
	input logic [5:0] imms, immr;
	output logic mask;
	
	logic [5:0] level, S, R, diff;
	int length;
	
	always_comb begin
		length = $clog(~imms);
	
		if (length > 0) begin
			case(length):
				6: level = 6'b111111;
				5: level = 6'b011111;
				4: level = 6'b001111;
				3: level = 6'b000111;
				2: level = 6'b000011;
				1: level = 6'b000001;
				default: level = 6'bx;
			endcase
			if (immediate && (level & imms) == level) begin  // undefined
			end
			else begin
				S = imms & level
				R = immr & level
			end
		end
		else begin  // undefined
			level = 6'bx;
		end
		
		mask = 32'bX;
	end	
endmodule
