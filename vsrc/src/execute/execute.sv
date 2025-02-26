`ifdef VERILATOR
`include "include/common.sv"
`include "src/execute/alu.sv"
`include "src/execute/mul.sv"
`endif

module execute import common::*;(
    input logic clk,rst,
    input REG_ID_EX moduleIn,
    output REG_EX_MEM moduleOut,
    output FORWARD_SOURCE forwardSource,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall
);

u64 ib;

assign ib=moduleIn.srcB?moduleIn.imm:moduleIn.rs2;

u64 aluOut;
u64 mulOut;
u64 pcBranch;

assign pcBranch=moduleIn.pcPlus4+(moduleIn.imm<<2);

alu alu(
    .clk(clk),
    .ia(moduleIn.rs1),
    .ib(ib),
    .aluOp(moduleIn.aluOp),
    .aluOut(aluOut)
);

mul mul(
    .clk(clk),
    .ia(moduleIn.rs1),
    .ib(ib),
    .mulOp(moduleIn.mulOp),
    .mulOut(mulOut)
);

initial begin
    moduleOut.valid = 0;
end

u64 datUse;
assign datUse = moduleIn.rvm ? mulOut : aluOut;

u64 aluOutProc;

assign aluOutProc = moduleIn.rv64 ? {{32{datUse[31]}}, datUse[31:0]}: datUse;

assign forwardSource.valid = moduleIn.valid & moduleIn.wd != 0;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = aluOutProc;

assign ok_to_proceed = 1; // always proceed, todo if multiply cannot complete in one cycle

always_ff @(posedge clk  or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else if(ok_to_proceed_overall) begin
        moduleOut.valid <= moduleIn.valid;
        moduleOut.rs2 <= moduleIn.rs2;
        moduleOut.aluOut <= aluOutProc;
        moduleOut.isWriteBack <= moduleIn.isWriteBack;
        moduleOut.wd <= moduleIn.wd;
        moduleOut.isBranch <= moduleIn.isBranch;
        moduleOut.pcBranch <= pcBranch;

        moduleOut.isMemRead <= moduleIn.isMemRead;
        moduleOut.isMemWrite <= moduleIn.isMemWrite;
        moduleOut.memMode <= moduleIn.memMode;

        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end


endmodule