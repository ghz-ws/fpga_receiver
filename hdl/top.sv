module top(
    input ext_rst,mclk,
    inout [7:0]adbus,acbus,
    input [15:0]adc,
    input adc_clkp,adc_clkn,
    output adc_drv_clk,aux,
    output [8:1]pmod,
    output [2:0]led
    );
    
    logic locked,clk,rst;
    assign rst=!locked;
    assign led=3'b111;
    
    assign aux=pmod[4];
    
    //adc input double latch
    logic [15:0]dl;
    logic signed [15:0]s_adc;
    logic [1:0]clk_state;
    always_ff@(posedge clk)begin
        if(rst)begin
            dl<=0;
            clk_state<=0;
        end else begin
            dl<=adc;
            clk_state<={clk_state,adc_clkp};
            if(clk_state==2)begin
                s_adc<=$signed(dl);
            end
        end
    end
    
    assign pmod={4'b0,($unsigned(s_adc+(1<<15)))>>12};
    
    clk_wiz_0 mmcm(
        .clk_out1(clk),     //main clk
        .clk_out2(adc_drv_clk), //adc drive clk
        .locked(locked),
        .clk_in1(mclk)
        );
        
    uart_echo uart(
        .clk(clk),
        .rst(rst),
        .rx(adbus[0]),
        .tx(adbus[1]),
        .err()
        );
endmodule
