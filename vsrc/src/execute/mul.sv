`ifdef VERILATOR
`include "include/common.sv"
`endif

module mul import common::*;(
    input logic clk,
    input u64 ia, ib,
    input logic en,
    input logic newOp,
    output logic busy,
    input u4 mulOp,
    output u64 mulOut
);
//ops:
// 0000: mul
// 0100: div
// 0101: divu
// 0110: rem
// 0111: remu
// 1000: mulw
// 1100: divw
// 1101: divuw
// 1110: remw
// 1111: remuw
u64 sign_extended_a;
u64 sign_extended_b;
u64 unsigned_a;
u64 unsigned_b;

assign sign_extended_a = {{32{ia[31]}}, ia[31:0]};
assign sign_extended_b = {{32{ib[31]}}, ib[31:0]};
assign unsigned_a = {32'b0, ib[31:0]};
assign unsigned_b = {32'b0, ib[31:0]};

u64 result;
u7 shift; //16*4, done in 16 cycles, each cycle run 4 adds
u4 cur_chunk;

u64 res0,res1,res2,res3;

assign res0=cur_chunk[0] ? 0 : ia;
assign res1=cur_chunk[1] ? 0 : ia;
assign res2=cur_chunk[2] ? 0 : ia;
assign res3=cur_chunk[3] ? 0 : ia;

logic mulBusy;
logic divBusy;

assign busy=mulBusy||divBusy;

u3 divia,divib;

u64 diva,divb;

u64 div_quotient;
u64 div_remainder;

logic div_out_mux;

always_comb begin
    case (divia) 
        3'b000: diva = ia;
        3'b001: diva = sign_extended_a;
        3'b010: diva = unsigned_a;
        default: diva = 0;
    endcase
    case (divib) 
        3'b000: divb = ib;
        3'b001: divb = sign_extended_b;
        3'b010: divb = unsigned_b;
        default: divb = 0;
    endcase
end


always_ff @(posedge clk) begin
    if(en && newOp) begin
        if (mulOp==4'b0000||mulOp==4'b1000) begin
            mulBusy <= 1;
            shift <= 0;
            result <= 0;
            cur_chunk <= ib[3:0];
        end
        else begin 
            //div, rem
            
        end
    end
    if(en && mulBusy) begin
        result <= result + (res0<<shift) + (res1<<(shift+1)) + (res2<<(shift+2)) + (res3<<(shift+3));
        shift <= shift + 4;
        //cur_chunk <= 4'b1111 & (ib >> shift[3:0]) ;
        if(mulOp==4'b0000 && shift==64) begin
            mulOut <= result;
            mulBusy <= 0;
        end
        if(mulOp==4'b1000 && shift==32) begin
            mulOut <= {{32{result[31]}}, result[31:0]};
            mulBusy <= 0;
        end
    end
    
end

endmodule