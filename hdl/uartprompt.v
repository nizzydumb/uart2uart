

module uartprompt(
	input clock, // 27 MHz
	input reset,
	input rx,
	output reg tx
);

	localparam CLOCK_FREQUENCY = 32'd48_000_000;
	localparam BAUDRATE = 32'd115_200;
	localparam integer DIVIDER = CLOCK_FREQUENCY/BAUDRATE;

	
	reg[31:0] clockCounter = 32'd0;
	reg sendData = 1'b0;
	
	always @(posedge clock) begin
		if(!reset) begin
			if(clockCounter != CLOCK_FREQUENCY-1) begin
				sendData <= 1'b0;
				clockCounter <= clockCounter + 1'b1;
			end else begin
				sendData <= 1'b1;
				clockCounter <= 32'd0;
			end
			
		end else begin
			sendData <= 1'b0;
			clockCounter <= 32'd0;
		end
	end


	localparam IDLE = 2'b00;
	localparam SEND = 2'b01;	

	
	localparam SIZE_OF_MESSAGE = 8'd65;
	reg[7:0] dataIndexCounter = 8'd0;
	reg[7:0] dataToSend[SIZE_OF_MESSAGE-1:0];
	
	integer i;
	

	
	initial begin
		dataToSend[0] = 8'd64; // size of frame 
		for(i = 1; i < 65; i = i + 1) begin
			dataToSend[i] <= i;
		end
	end
	

	reg[7:0] dataSendCounter = 8'h0;
	reg[31:0] baudrateCounter = 32'd0;	
	reg[1:0] state = IDLE;
	
	always @(posedge clock) begin
		if(!reset) begin
			case(state) 
				IDLE : begin
					tx <= 1'b1;
					dataSendCounter <= 8'h0;
					baudrateCounter <= 32'd0;
					if(sendData || dataIndexCounter != 8'd0) begin
						state <= SEND;
					end
				end
				SEND : begin				
					if(baudrateCounter != DIVIDER-1) begin
						baudrateCounter <= baudrateCounter + 1'b1;
					end else begin
						dataSendCounter <= dataSendCounter + 1'b1;;
						baudrateCounter <= 32'd0;
					end
					
								
					case(dataSendCounter)
						0 : tx <= 1'b0;
						1 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						2 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						3 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						4 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						5 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						6 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						7 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						8 : tx <= dataToSend[dataIndexCounter][dataSendCounter-1];
						9 : tx <= 1'b1;
						10 : begin 
							if(dataIndexCounter != SIZE_OF_MESSAGE-1)
								dataIndexCounter <= dataIndexCounter + 1'b1;
							else 
								dataIndexCounter <= 8'd0;
							state <= IDLE;
						end
					endcase
				end
			endcase
		end else begin
			tx <= 1'b1;
			dataSendCounter <= 8'h0;
			baudrateCounter <= 32'd0;
			state <= IDLE;
			dataIndexCounter <= 8'd0;
		end
	
	end
		
	
endmodule
