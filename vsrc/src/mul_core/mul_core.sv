`ifdef VERILATOR
`include "include/common.sv"
`endif

module mul_core import common::*;(
    input logic clk,rst,
    input logic op_begin,
    input mbus_req_t req,
    output logic busy,
    output u64 mulOut,
    output logic ready,
    output logic divZero
);

u64 ib_temp;
u64 mul_temp;
u64 rem_temp;
u64 div_temp;

u6 state;

assign busy = state!=0;

assign mulOut = req.op==MUL ? mul_temp : req.op==DIV ? div_temp : rem_temp;

always_ff@(posedge clk) begin
    if(rst) begin
        mul_temp <= 0;
        state <= 0;
        ready <= 0;
        divZero <= 0;
    end else begin
        if(op_begin) begin
            case(req.op)
                MUL: begin
                    mul_temp <= (req.ia[0]*req.ib) + ((req.ia[1]*req.ib)<<1) + ((req.ia[2]*req.ib)<<2) + ((req.ia[3]*req.ib)<<3);
                    state <= 4;
                end
                DIV, REM: begin
                    if (req.dw) begin
                        if(req.ib==0) begin
                            div_temp <= ~0;
                            rem_temp <= req.ia_orig;
                            state <= 0;
                            ready <= 1;
                            divZero <= 1;
                        end else begin
                            ib_temp <= req.ib;
                            if ({63'b0,req.ia[63]}>=req.ib) begin
                                div_temp <= 1<<63;
                                rem_temp <= req.ia - (req.ib<<63);
                                state <= 63;
                            end else begin
                                div_temp <= 0;
                                rem_temp <= req.ia;
                                state <= 63;
                            end
                        end
                    end else begin
                        if(req.ib[31:0]==0) begin
                            div_temp <= ~0;
                            rem_temp <= {32'b0,req.ia_orig[31:0]};
                            state <= 0;
                            ready <= 1;
                            divZero <= 1;
                        end else begin
                            ib_temp <= {32'b0,req.ib[31:0]};
                            if ({31'b0,req.ia[31]}>=req.ib[31:0]) begin
                                div_temp <= 1<<31;
                                rem_temp <= {32'b0,req.ia[31:0]} - (req.ib<<31);
                                state <= 31;
                            end else begin
                                div_temp <= 0;
                                rem_temp <= {32'b0,req.ia[31:0]};
                                state <= 31;
                            end
                        end
                    end
                end
                default: begin
                    mul_temp <= 0;
                end
            endcase
        end else begin
            if(state!=0)begin
                case(req.op)
                    MUL: begin
                        mul_temp <= mul_temp + ((req.ia[state]*req.ib) << state) + ((req.ia[state+1]*req.ib) << (state+1)) + ((req.ia[state+2]*req.ib) << (state+2)) + ((req.ia[state+3]*req.ib) << (state+3));
                        if(req.dw) begin
                            if (state == 60) begin
                                state <= 0;
                                ready <= 1;
                            end else begin
                                state <= state + 4;
                            end
                        end else begin
                            if (state == 28) begin
                                state <= 0;
                                ready <= 1;
                            end else begin
                                state <= state + 4;
                            end
                        end
                    end
                    DIV, REM: begin
                        if(rem_temp>>(state-1) >= ib_temp) begin
                            div_temp <= div_temp + (1<<(state-1));
                            rem_temp <= rem_temp - (ib_temp<<(state-1));
                        end
                        if(state==1) begin
                            ready <= 1;
                        end
                        state <= state - 1;
                    end
                    default: begin
                        mul_temp <= 0;
                    end
                endcase
            end
        end
    end
end


endmodule