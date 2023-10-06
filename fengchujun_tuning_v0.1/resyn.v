module sine_resyn(
        input clk ,
        input reset,
        input [23:0] fcw,
        
        output [11:0] sin_out
    );
    reg [11:0] rom_memory [1023:0];

    initial begin
        $readmemh("D:/document/project/vivado/FPGA_autotune/sin.mem", rom_memory);
    end

    reg [23:0] accu;
    reg [2:0] fdiv_cnt;
    wire accu_en;
    wire [9:0] lut_index;
	  
//process for frequency divider
    always @(posedge clk) begin
      if(reset == 1'b0)
         fdiv_cnt <= 0; //synchronous reset
      else if(accu_en == 1'b1)
         fdiv_cnt <= 0; 
      else    
         fdiv_cnt <= fdiv_cnt +1;    
    end

//logic for accu enable signal, resets also the frequency divider counter
    assign accu_en = (fdiv_cnt == 3'd5) ? 1'b1 : 1'b0;

//process for phase accumulator
    always @(posedge clk) begin
      if(reset == 1'b0)         
            accu <= 0; //synchronous reset
      else if(accu_en == 1'b1)
            accu <= accu + fcw;
    end

//10 msb's of the phase accumulator are used to index the sinewave lookup-table
    assign lut_index = accu[23:14];

//16-bit sine value from lookup table
    assign sin_out = rom_memory[lut_index];
endmodule
