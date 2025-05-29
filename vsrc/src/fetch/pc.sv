`ifdef VERILATOR
`include "include/common.sv"
`include "src/fetch/int.sv"
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
    input u64 JumpAddr,
    input logic csrJump,

    input logic trint,
    input logic swint,
    input logic exint,

    input u2 priviledgeMode,
    input u64 mstatus,
    input u64 mip,
    input u64 mie,

    input u64 pcbranch,
    input logic adopt_branch
);

logic intEn;
exception_t exception_int;

interruptJudge iJ(
    .priviledgeMode(priviledgeMode),
    .trint(trint),
    .swint(swint),
    .exint(exint),
    .mstatus(mstatus), 
    .mip(mip),
    .mie(mie),

    .intEn(intEn),
    .exception(exception_int)
);

u64 curPC;
u64 nextPC;

u32 instr_n;

logic instr_ok;

logic mis_align;

initial begin
    
end

assign ok_to_proceed = instr_ok;

logic stall;

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        curPC <= PCINIT;
        nextPC <= PCINIT+4;
        ibus_req.addr <= PCINIT;
        ibus_req.valid <= 1;
        moduleOut.valid <= 0;
        instr_ok <= 0;
    end else begin 
        if(ok_to_proceed_overall) begin
            if(JumpEn) begin
                moduleOut.valid <= 0;
                moduleOut.exception_valid <= 0;
                curPC <= JumpAddr;
                nextPC <= JumpAddr + 4;
                if(JumpAddr[1:0] != 2'b00) begin
                    mis_align <= 1;
                    instr_ok <= 1;
                end else begin
                    ibus_req.addr <= JumpAddr;
                    ibus_req.valid <= 1;
                    mis_align <= 0;
                    instr_ok <= 0;
                end
                stall <= csrJump;
            end else if(adopt_branch) begin
                moduleOut.valid <= 0;
                moduleOut.exception_valid <= 0;
                curPC <= pcbranch;
                nextPC <= pcbranch + 4;
                if(pcbranch[1:0] != 2'b00) begin
                    mis_align <= 1;
                    instr_ok <= 1;
                end else begin
                    ibus_req.addr <= pcbranch;
                    ibus_req.valid <= 1;
                    mis_align <= 0;
                    instr_ok <= 0;
                end
            end else if(~lwHold & ~stall & ~intEn & ~mis_align & ~adopt_branch) begin 
                moduleOut.valid <= 1;
                moduleOut.pc <= curPC;
                moduleOut.pcPlus4 <= curPC+4;
                moduleOut.instrAddr <= curPC;
                moduleOut.instr <= instr_n;
                moduleOut.exception_valid <= 0;
                curPC <= nextPC;
                if (nextPC[1:0] != 2'b00) begin
                    mis_align <= 1;
                    ibus_req.valid <= 0;
                end else begin
                    mis_align <= 0;
                    ibus_req.addr <= nextPC;
                    ibus_req.valid <= 1;
                end
                instr_ok <= 0;
                nextPC <= nextPC + 4;
            end else begin
                moduleOut.valid <= 0;
                if(intEn) begin
                    moduleOut.exception_valid <= 1;
                    moduleOut.exception <= exception_int;
                    moduleOut.pc <= curPC;
                    moduleOut.instrAddr <= curPC;
                end else if (mis_align) begin
                    moduleOut.instr <= 0;
                    moduleOut.exception_valid <= 1;
                    moduleOut.exception <= INSTRUCTION_ADDRESS_MISALIGNED; 
                    moduleOut.pc <= curPC;
                    moduleOut.instrAddr <= curPC;
                end else begin
                    moduleOut.exception_valid <= 0;
                end
                ibus_req.valid <= 0;
                instr_ok <= 1;
                stall <= 0;
            end
        end else if (ibus_resp.addr_ok & ibus_resp.data_ok) begin
            instr_ok <= 1;
            instr_n <= ibus_resp.data;
            ibus_req.valid <= 0;
        end
    end
end

endmodule