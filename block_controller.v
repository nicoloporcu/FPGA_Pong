`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input left, input right, input p2left, input p2right,
	input two_player,
	input ack,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [15:0] score,
	output reg [15:0] p2score,
	output reg[15:0] highscore
   );
	wire block_fill;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg [9:0] xpos, ypos;
	reg [9:0] PL, PR, PC, PY;
	
	reg [9:0] P2L, P2R, P2Y;
	
	reg [1:0] game_state;
	reg [11:0] background;
	
	parameter RED   = 12'b1111_0000_0000;
	parameter BLUE  = 12'b0000_0000_1111;
	parameter GREEN  = 12'b0000_1111_0000;	
	parameter TURQOUISE = 12'b0000_1111_1111;
	parameter YELLOW = 12'b1111_1111_0000;
	
	
	// State machine states
    localparam  
      INI   = 2'b00,
      START = 2'b01,
      DONE  = 2'b10,
      TWO = 2'b11,
      UNKN  = 2'bxx;
    
	localparam ball_width = 10; //horizontal
	localparam ball_height = 10;//vertical
	localparam paddle_length = 50;
	localparam paddle_2_length = 50; 
	

	
	
	//INT to control the velocity
	
	integer dx = 0, dy = 1;
	integer debounce =0;
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (paddle) 
			rgb = RED;
		else if (paddle2 & (game_state == TWO))
		    rgb = GREEN;
		     
		else if(line_1 || line_2 || line_3 || line_4 || line_5 || line_6 || line_7 || line_8 || line_9)
				rgb = BLUE;
		else	
			rgb=background;
	end
		//the +-5 for the positions give the dimension of the block (i.e. it will be 10x10 pixels)
	//assign block_fill=vCount>=(ypos-5) && vCount<=(ypos+5) && hCount>=(xpos-5) && hCount<=(xpos+5);
	assign paddle =  vCount>=(PY) && vCount<=(PY + 10) && hCount>=(PL) && hCount<=(PR);
	assign paddle2 = vCount<=(P2Y) && vCount>=(P2Y - 10) && hCount>=(P2L) && hCount<=(P2R);
	
	assign line_1 = hCount == xpos && vCount == ypos+4;
	assign line_2 = hCount>=(xpos-2) && hCount<=(xpos+2)&& vCount==(ypos+3);
	assign line_3 = hCount>=(xpos-3) && hCount<=(xpos+3)&& vCount==(ypos+2);
	assign line_4 = hCount>=(xpos-4) && hCount<=(xpos+4)&& vCount==(ypos+1);
	assign line_5 = hCount>=(xpos-4) && hCount<=(xpos+4)&& vCount==(ypos);
	assign line_6 = hCount>=(xpos-4) && hCount<=(xpos+4)&& vCount==(ypos-1);
	assign line_7 = hCount>=(xpos-3) && hCount<=(xpos+3)&& vCount==(ypos-2);
	assign line_8 = hCount>=(xpos-2) && hCount<=(xpos+2)&& vCount==(ypos-3);
	assign line_9 = hCount == xpos && vCount == (ypos-4);
	
	
	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			game_state <= INI;
			background <= 12'b1111_1111_1111;
			score <= 0;
			highscore <=0;
			xpos<=450;
			ypos<=150;
			dx <= 0;
			dy <= 1;
		end
		else if (clk) begin
		
			if (game_state == INI)
			begin
			
			if(two_player)
			     game_state <= TWO;
			else
			     game_state <= START;
			     
			     
			 score <= 0; 
			 p2score <=0;
			
			//rough values for center of screen
			
			//CENTER FOR THE BALL
			 xpos<=450;
			 ypos<=150;
			
			 PL <= 450 - paddle_length/2;
			 PR <= 450 + paddle_length/2;
			 PY <= 450;
			 
			 P2L <= 450 - paddle_length/2;
			 P2R <= 450 + paddle_length/2;
			 P2Y <= 100;
			 
			 debounce <= 0;
			//paddle ini. position 
			
			end
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/
			else if (game_state == START)
				begin
				
				xpos <= xpos + dx;
				ypos <= ypos + dy;
				
				if(debounce !=0)
				begin
				debounce = debounce -1;
				end
				
				if (ypos <= (35 + ball_height/2)+1)//Top starting +1
				    begin
				    if (debounce ==0)
				       begin
					   dy = dy*-1;
					   end
				    debounce = 10;
				    end
				
	         
				if (xpos <= (144 + ball_width/2)+1)//Top starting +1
				    begin
				    if (debounce ==0)
				       begin
					   dx = dx*-1;
					   end
				    debounce = 10;
				    end
				
				if (xpos >= (783 - ball_width/2)+1)//Top starting +1
				    begin
				    if (debounce ==0)
				       begin
					   dx = dx*-1;
					   end
					debounce = 10;
					end
					
					
				if( (ypos >= (PY- ball_height/2)) && ( xpos < PL || xpos > PR))
				    begin
					game_state <= DONE;
					end
				
				if( (ypos >= (PY- ball_height/2)) && ( xpos >= PL &&  xpos <= PR))
					begin
					
					if(debounce ==0)
					begin
					   score <= score +1;
					   background <= TURQOUISE;
					   if (background == TURQOUISE)
					       background <= YELLOW;
					end
					
					debounce = 10;
					
					if( PR - xpos > 40 && PR -xpos <= 50)
					begin
					   dy = -1;
					   dx = -2;
					end

					if( PR - xpos > 30 && PR -xpos <= 40)
					begin
					   dy = -1;
					   dx = -1;
					end
					
					if( PR - xpos >= 20 && PR -xpos <= 30)
					begin
					   dx = 0;
					   dy = -2;
					end
					
					if( PR - xpos >= 10 && PR -xpos < 20)
					begin
					   dx = 1;
					   dy = -1;
					end
					
					if( PR - xpos >= 0 && PR -xpos < 10)
					begin
					   dx = 2;
					   dy = -1;
					end
					
					end
					
				//if(xpos < PL || xpos > PR) //not within the range
					//game_state <= DONE; 
				
				if(right) begin
					 //change the amount you increment to make the speed faster 
					if(PR <= 793) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					begin
						PR<=PR+2;
						PL<=PL+2;
					end
				end
				else if(left) begin
					if(PL >= 144) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
						begin
						PR<=PR-2;
						PL<=PL-2;
						end
				end
				/*else if(up) begin
					ypos<=ypos-2;
					if(ypos==34)
						ypos<=514;
				end
				else if(down) begin
					ypos<=ypos+2;
					if(ypos==514)
						ypos<=34;
				end
				*/
				end
				
				
				
				
				
				
				///TWO PLAYER
				
				else if(game_state == TWO)
				begin
				
				xpos <= xpos + dx;
				ypos <= ypos + dy;
				
				if(debounce !=0)
				begin
				debounce = debounce -1;
				end
				
	         
				if (xpos <= (144 + ball_width/2)+1)//Top starting +1
				    begin
				    if (debounce ==0)
				       begin
					   dx = dx*-1;
					   end
				    debounce = 10;
				    end
				
				if (xpos >= (783 - ball_width/2)+1)//Top starting +1
				    begin
				    if (debounce ==0)
				       begin
					   dx = dx*-1;
					   end
					debounce = 10;
					end
					
					
				if( (ypos >= (PY- ball_height/2)) && ( xpos < PL || xpos > PR))
				    begin
					game_state <= DONE;
					end
				
				else if( (ypos >= (PY- ball_height/2)) && ( xpos >= PL &&  xpos <= PR))
					begin
					
					if(debounce ==0)
					begin
					   background <= 12'b0000_1111_1111;
					   score <= score +1;
					end
					
					debounce = 10;
					
					if( PR - xpos > 40 && PR -xpos <= 50)
					begin
					   dy = -1;
					   dx = -2;
					end

					if( PR - xpos > 30 && PR -xpos <= 40)
					begin
					   dy = -1;
					   dx = -1;
					end
					
					if( PR - xpos >= 20 && PR -xpos <= 30)
					begin
					   dx = 0;
					   dy = -2;
					end
					
					if( PR - xpos >= 10 && PR -xpos < 20)
					begin
					   dx = 1;
					   dy = -1;
					end
					
					if( PR - xpos >= 0 && PR -xpos < 10)
					begin
					   dx = 2;
					   dy = -1;
					end
					
					end
				
				if( (ypos <= (P2Y + ball_height/2)) && ( xpos < P2L || xpos > P2R))
				    begin
					game_state <= DONE;
					end
				
				if( (ypos <= (P2Y + ball_height/2)) && ( xpos >= P2L &&  xpos <= P2R))
				    begin
				    
					
					if(debounce ==0)
					begin
					   background <= 12'b1111_1111_0000;
					   score <= score +1;
					end
					
					debounce = 10;
					
					if( P2R - xpos > 40 && P2R -xpos <= 50)
					begin
					   dy = 1;
					   dx = -2;
					end

					if( P2R - xpos > 30 && P2R -xpos <= 40)
					begin
					   dy = 1;
					   dx = -1;
					end
					
					if( P2R - xpos >= 20 && P2R -xpos <= 30)
					begin
					   dx = 0;
					   dy = 2;
					end
					
					if( P2R - xpos >= 10 && P2R -xpos < 20)
					begin
					   dx = 1;
					   dy = 1;
					end
					
					if( P2R - xpos >= 0 && P2R -xpos < 10)
					begin
					   dx = 2;
					   dy = 1;
					end
					
					end

				if(right) begin
					 //change the amount you increment to make the speed faster 
					if(PR <= 793) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					begin
						PR<=PR+2;
						PL<=PL+2;
					end
				end
				else if(left) begin
					if(PL >= 144) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
						begin
						PR<=PR-2;
						PL<=PL-2;
						end
				end
				
				if(p2right) begin
				    if(P2R <= 793) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					begin
						P2R<=P2R+2;
						P2L<=P2L+2;
					end
				    
				end
				
				else if(p2left) begin
				    if(P2L >= 144) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					begin
						P2R<=P2R-2;
						P2L<=P2L-2;
					end
				end
				
				end
				
				
				
				//DONE STATE
				
				else if(game_state == DONE)
				begin
				    if (score > highscore)
				        highscore <= score;
				    if(ack)
				        game_state <= INI;
				end
				
		end
	end



	
	
endmodule
