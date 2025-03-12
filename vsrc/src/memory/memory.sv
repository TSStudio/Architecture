`ifdef VERILATOR
`include "include/common.sv"
`include "src/memory/memory_helper.sv"
`include "src/memory/memory_solver.sv"
`endif

module memory import common::*;(
    input logic clk,rst,
    input REG_EX_MEM moduleIn,
    output REG_MEM_WB moduleOut,
    output FORWARD_SOURCE forwardSource,

    output dbus_req_t dreq,
    input  dbus_resp_t dresp,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall
);

logic cur_mem_op_done;
u64 cur_mem_data;
logic cur_mem_op_started;

assign ok_to_proceed = ~(moduleIn.valid) | ~(moduleIn.isMemRead|moduleIn.isMemWrite) | cur_mem_op_done;

initial begin
    moduleOut.valid = 0;
    cur_mem_op_done = 0;
end

assign forwardSource.valid = moduleIn.valid & moduleIn.wd != 0;
assign forwardSource.isWb = moduleIn.isWriteBack;
assign forwardSource.wd = moduleIn.wd;
assign forwardSource.wdData = moduleIn.isMemRead ? dataOut:moduleIn.aluOut;

msize_t msize;
strobe_t strobe;
addr_t addr;
word_t data;
                
memoryHelper memoryHelper_inst(
    .addressReq(moduleIn.aluOut),
    .dataIn(moduleIn.rs2),
    .memMode(moduleIn.memMode),
    .addr(addr),
    .msize(msize),
    .strobe(strobe),
    .data(data)
);

memorySolver memorySolver_inst(
    .addressReq(moduleIn.aluOut),
    .dataIn(cur_mem_data),
    .memMode(moduleIn.memMode),
    .data(dataOut)
);

u64 dataOut;

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else if(ok_to_proceed_overall) begin
        moduleOut.valid <= moduleIn.valid;
        moduleOut.aluOut <= moduleIn.aluOut;
        moduleOut.pcPlus4 <= moduleIn.pcPlus4;
        moduleOut.isWriteBack <= moduleIn.isWriteBack;
        moduleOut.isMemRead <= moduleIn.isMemRead;
        moduleOut.wd <= moduleIn.wd;
        moduleOut.isBranch <= moduleIn.isBranch;
        moduleOut.isJump <= moduleIn.isJump;
        moduleOut.branchAdopted <= moduleIn.flagResult;
        moduleOut.memOut <= dataOut;
        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;

        cur_mem_op_done <= 0;
        cur_mem_op_started <= 0;
    end
    if(dresp.addr_ok & dresp.data_ok & cur_mem_op_started) begin
        cur_mem_data <= dresp.data;
        cur_mem_op_done <= 1;
        dreq.valid <= 0;
    end
    if(moduleIn.valid & (moduleIn.isMemRead|moduleIn.isMemWrite) & ~cur_mem_op_started) begin
        cur_mem_op_started <= 1;
        dreq.addr <= addr;
        dreq.valid <= 1;
        dreq.size <= msize;
        if(moduleIn.isMemRead) begin
            dreq.strobe <= 0;
        end else begin
            dreq.strobe <= strobe;
            dreq.data <= data;
        end
    end
end

endmodule