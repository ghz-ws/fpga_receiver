module rx(
    input clk,
    input rst,
    input rx_line,
    output logic [7:0]rx_data,
    output logic busy,
    output logic valid,
    output logic err
    );
    
    parameter parity=0; //0=none, 1=odd, 2=even
    parameter div_ratio=434;  //50M/115.2k=434
    
    // double latch to suppress glitch
    logic [1:0]rx_latch;
    always_ff@(posedge clk)begin
        if(rst)begin
            rx_latch<=2'b11;
        end else begin
            rx_latch<={rx_latch[0],rx_line};    
        end
    end
    
    //Gen. rx clk. 180 deg. phase delayed
    logic [$clog2(div_ratio):0]div;
    logic rx_clk;
    always_ff@(posedge clk) begin
        if(!busy)begin
            div<=0;
            rx_clk<=0;
        end else begin
            if(div==div_ratio/2)begin
                rx_clk<=1;
                div<=div+1;
            end else if(div==div_ratio)begin
                rx_clk<=0;
                div<=0;
            end else begin
                rx_clk<=0;
                div<=div+1;
            end       
        end
    end
    
    //data receive
    logic [2:0]bitcnt,parity_cnt;
    logic [7:0]rx_buf;
    enum logic [1:0] {START, RECEIVE, PARITY, STOP}state;
    always_ff@(posedge clk)begin
        if(rst)begin
            busy<=0;
            valid<=0;
            err<=0;
            rx_data<=0;
            state<=START;
        end else begin
            if(!busy&&rx_latch[1]==0)begin
                busy<=1;
                valid<=0;
                err<=0;
            end else begin
                if(busy&&rx_clk)begin
                    case(state)
                        START:begin
                            bitcnt<=0;      //clear bit cnt
                            parity_cnt<=0;  //clear parity cnt
                            state<=RECEIVE;
                        end
                        RECEIVE:begin
                            rx_buf[bitcnt]<=rx_latch[1];   //data receive. LSB first
                            bitcnt<=bitcnt+1;
                            if(rx_latch[1])begin
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
                                if(parity==1&&rx_latch[1]==1)begin  //odd parity err
                                    err<=1;
                                end else if(parity==2&&rx_latch[1]==0)begin  //even parity err
                                    err<=1;
                                end
                            end else begin  //number of 1 is even
                                if(parity==1&&rx_latch[1]==0)begin  //odd parity err
                                    err<=1;
                                end else if(parity==2&&rx_latch[1]==1)begin  //even parity err
                                    err<=1;
                                end
                            end
                        end
                        STOP:begin
                            state<=START;
                            busy<=0;
                            if(rx_latch[1]&&!err)begin
                                valid<=1;
                                rx_data<=rx_buf;
                            end else begin
                                err<=1;
                            end
                        end
                        default:begin
                            busy<=0;
                            state<=START;
                        end
                    endcase
               end
            end
        end
    end
endmodule
