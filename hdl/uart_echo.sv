module uart_echo(
    input clk,rst,rx,
    output tx,
    output err
    );
    
    logic [7:0]tx_data,rx_data;
    logic act,valid,busy_t,busy_r;
    
    assign tx_data=rx_data;
    
    //valid edge detect
    logic [1:0]valid_edge;
    always_ff@(posedge clk)begin
        if(rst)begin
            valid_edge<=0;
            act<=0;
        end else begin
            valid_edge<={valid_edge[0],valid};
            if(valid_edge==2'b01)begin
                act<=1;
            end else begin
                act<=0;
            end
        end
    end
    
    tx tx_unit(.*,.busy(busy_t),.tx_line(tx));
    rx rx_unit(.*,.busy(busy_r),.rx_line(rx));
endmodule