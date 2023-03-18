`timescale 1ns / 1ps
module tb_top();
    bit ext_rst,mclk;
    wire [7:0]adbus,acbus;
    logic [15:0]adc;
    logic adc_clkp,adc_clkn;
    logic adc_drv_clk,aux;
    logic [8:1]pmod;
    logic [2:0]led;
    logic signed [9:0]out;
    
    always #42ns mclk<=!mclk;
    
    assign adc_clkp=adc_drv_clk;
    assign adc_clkn=!adc_drv_clk;
    assign adc=out<<<6;
    
    initial begin
        @(posedge dut.locked);
        #100us
        $finish;
    end
    
    top dut(.*);
    nco_sim nco(.*);
endmodule
