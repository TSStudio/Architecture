`ifdef VERILATOR
`include "include/common.sv"
`endif

module programCounter import common::*;(
    input logic clk,rst,

    input logic lwHold,
    output REG_IF_ID moduleOut,

    input ibus_resp_t ibus_resp,
    output ibus_req_t ibus_req,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall,

    input logic JumpEn,
    input u64 JumpAddr
);

u64 curPC;
u64 nextPC;

u32 instr_n;

logic instr_ok;

initial begin
    
end

assign ok_to_proceed = instr_ok;

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        curPC <= PCINIT;
        nextPC <= PCINIT+4;
        ibus_req.addr <= curPC;
        ibus_req.valid <= 1;
        moduleOut.valid <= 0;
        instr_ok <= 0;
    end else begin 
        if(ok_to_proceed_overall) begin
            if(JumpEn) begin
                moduleOut.valid <= 0;

                curPC <= JumpAddr;
                nextPC <= JumpAddr + 4;
                ibus_req.addr <= JumpAddr;
                ibus_req.valid <= 1;
                instr_ok <= 0;
            end else if(~lwHold) begin 
                moduleOut.valid <= 1;
                moduleOut.pc <= curPC;
                moduleOut.pcPlus4 <= curPC+4;
                moduleOut.instr <= instr_n;
                moduleOut.instrAddr <= curPC;

                curPC <= nextPC;
                ibus_req.addr <= nextPC;
                ibus_req.valid <= 1;
                instr_ok <= 0;
                nextPC <= nextPC + 4;
            end else begin
                moduleOut.valid <= 0;
                ibus_req.valid <= 0;
                instr_ok <= 1;
            end
        end
        if (ibus_resp.addr_ok & ibus_resp.data_ok) begin
            instr_ok <= 1;
            instr_n <= ibus_resp.data;
            ibus_req.valid <= 0;
        end
    end
end

endmodule