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

logic mem_ok;
logic mem_op_done;

assign mem_ok = dresp.addr_ok & dresp.data_ok;


assign ok_to_proceed = ~(moduleIn.valid) | ~(moduleIn.isMemRead|moduleIn.isMemWrite) | mem_op_done;

initial begin
    moduleOut.valid = 0;
    mem_op_done = 0;
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
    .addressReq(addrReq),
    .dataIn(dresp.data),
    .memMode(memMode),
    .data(dataOut)
);

u4 memMode;
u64 addrReq;
u64 dataOut;

always_ff @(negedge clk) begin
    if(moduleIn.valid & (moduleIn.isMemRead|moduleIn.isMemWrite) ) begin
        mem_op_done <= 0;
        dreq.addr <= addr;
        dreq.valid <= 1;
        dreq.size <= msize;
        memMode <= moduleIn.memMode;
        addrReq <= moduleIn.aluOut;
        if(moduleIn.isMemRead) begin
            dreq.strobe <= 0;
        end else begin
            dreq.strobe <= strobe;
            dreq.data <= data;
        end
    end
    if(mem_ok) begin
        mem_op_done <= 1;
    end
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else if(ok_to_proceed_overall) begin
        moduleOut.valid <= moduleIn.valid;
        moduleOut.aluOut <= moduleIn.aluOut;
        moduleOut.isWriteBack <= moduleIn.isWriteBack;
        moduleOut.wd <= moduleIn.wd;
        moduleOut.isBranch <= moduleIn.isBranch;
        moduleOut.pcBranch <= moduleIn.pcBranch;
        moduleOut.memOut <= dataOut;
        moduleOut.instrAddr <= moduleIn.instrAddr;
        moduleOut.instr <= moduleIn.instr;
    end
end

endmodule