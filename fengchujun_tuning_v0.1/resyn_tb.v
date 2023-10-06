`timescale 1ns / 1ps

module resyn_tb(
    );
    
reg clk;
reg [23:0]fcw;
reg reset;
wire [11:0]sin_out;

sine_resyn sine_resyn(
.clk(clk),
.reset(reset),
.fcw(fcw),
.sin_out(sin_out)
);

initial begin
    clk=0;
    reset=1;
    fcw=500;
    #10
    reset=0;
end

always begin
    #5
    clk=~clk;
end
    
endmodule
