`timescale 1ns / 1ps
module top_test(
    input clk,
    input reset,
    output pwm
    );

wire[23:0]fcw=rom_tune[the_tune];
wire[11:0]sin_out1;
wire[11:0]sin_out2;
wire[11:0]sin_out3;
wire[11:0]sin_out4;
wire[7:0]sin_in=(sin_out1[11:4]>>1)+(sin_out2[11:4]>>2)+(sin_out3[11:4]>>3)+(sin_out4[11:4]>>3);
reg [4:0]the_tune=0;
reg [24:0]count=0;
wire clk_1=(count[24]==1);
reg [23:0] rom_tune [31:0];

    initial begin
        $readmemh("D:/document/project/vivado/FPGA_autotune/tune.mem", rom_tune);
    end

always @(posedge clk)begin
    count<=count+1;
end

always@(posedge clk_1)begin
    the_tune<=the_tune+1;
end

    sine_resyn sin1(
        .clk(clk) ,
        .reset(reset),
        .fcw(fcw),
        .sin_out(sin_out1)
    );
    sine_resyn sin2(
        .clk(clk) ,
        .reset(reset),
        .fcw(fcw<<1),
        .sin_out(sin_out2)
    );
    sine_resyn sin3(
        .clk(clk) ,
        .reset(reset),
        .fcw(fcw*3),
        .sin_out(sin_out3)
    );
    sine_resyn sin4(
        .clk(clk) ,
        .reset(reset),
        .fcw(fcw<<2),
        .sin_out(sin_out4)
    );
    
    pwm pwm1(
        .clk_in(clk),
        .rst_in(reset),
        .level_in(sin_in),
        .pwm_out(pwm)
    );

    
endmodule




module pwm (input clk_in, input rst_in, input [7:0] level_in, output pwm_out);
    reg [7:0] count;
    assign pwm_out = count<level_in;
    always @(posedge clk_in)begin
        if (~rst_in)begin
            count <= 8'b0;
        end else begin
            count <= count+8'b1;
        end
    end
endmodule