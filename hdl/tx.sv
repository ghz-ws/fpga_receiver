module tx(
    input clk,
    input rst,
    input [7:0]tx_data,
    input act,
    output logic tx_line,
    output logic busy
    );
    
    parameter parity=0; //0=none, 1=odd, 2=even
    parameter div_ratio=434;  //50M/115.2k=434
    
    //Gen. tx clk
    logic [$clog2(div_ratio):0]div;
    logic tx_clk;
    always_ff@(posedge clk)begin
        if(rst)begin
            div<=0;
            tx_clk<=0;
        end else begin
            if(div==div_ratio)begin
                tx_clk<=1;
                div<=0;
            end else begin
                tx_clk<=0;
                div<=div+1;
            end       
        end
    end
    
    //data send
    logic [2:0]bitcnt,parity_cnt;
    logic [7:0]tx_buf;
    enum logic [2:0] {START, SEND, PARITY, STOP, FINISH}state;
    always_ff@(posedge clk)begin
        if(rst)begin
            tx_line<=1;
            busy<=0;
            bitcnt<=0;
            parity_cnt<=0;
            state<=START;
        end else begin
            if(act&&!busy)begin
                busy<=1;
                tx_buf<=tx_data;    //latch tx_data
            end else begin
                if(busy&&tx_clk)begin
                    case(state)
                        START:begin
                            tx_line=0;      //send start bit 0
                            bitcnt<=0;      //clear bit cnt
                            parity_cnt<=0;  //clear parity cnt
                            state<=SEND;
                        end
                        SEND:begin
                            tx_line<=tx_buf[bitcnt];   //data send. LSB first
                            bitcnt<=bitcnt+1;
                            if(tx_buf[bitcnt])begin
                                parity_cnt<=parity_cnt+1;   //parity cnt up
                            end
                            if(bitcnt==7)begin      //finish preparation
                                if(parity==0)begin
                                    state<=STOP;
                                end else begin
                                    state<=PARITY;
                                end
                            end
                        end
                        PARITY:begin
                            state<=STOP;
                            if(parity_cnt==1||parity_cnt==3||parity_cnt==5||parity_cnt==7)begin //number of 1 is odd
                                if(parity==1)begin  //odd parity
                                    tx_line<=0;
                                end else begin      //even parity
                                    tx_line<=1;
                                end
                            end else begin  //number of 1 is even
                                if(parity==1)begin  //odd parity
                                    tx_line<=1;
                                end else begin      //even parity
                                    tx_line<=0;
                                end
                            end
                        end
                        STOP:begin
                            tx_line=1;
                            state<=FINISH;
                        end
                        FINISH:begin
                            busy<=0;
                            state<=START;
                        end
                        default:begin
                            busy<=0;
                            tx_line=1;
                            state<=START;
                        end
                    endcase
                end
            end
        end
    end
endmodule
