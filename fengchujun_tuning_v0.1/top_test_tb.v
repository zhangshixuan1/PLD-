`timescale 1ns / 1ps



module top_test_tb(

    );
reg clk;
reg reset;
wire pwm;

top_test top_test(
    .clk(clk),
    .reset(reset),
    .pwm(pwm)
);
initial begin
    clk=0;
    reset=0;
    #100
    reset=1;
end

always begin
    #5
    clk=~clk;
end
endmodule
