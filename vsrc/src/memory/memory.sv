`ifdef VERILATOR
`include "include/common.sv"
`include "src/memory/memory_helper.sv"
`include "src/memory/memory_solver.sv"
`endif

module memory import common::*;(
    input logic clk,rst,
    output logic bubbleHold,
    input REG_EX_MEM moduleIn,
    output REG_MEM_WB moduleOut,
    output FORWARD_SOURCE forwardSource,

    
    output dbus_req_t dreq,
    input  dbus_resp_t dresp
);

logic busy;
logic mem_ok;

assign bubbleHold = busy;
assign mem_ok = dresp.addr_ok & dresp.data_ok;

initial begin
    moduleOut.valid = 0;
    busy = 0;
end

assign forwardSource.valid = moduleIn.valid;
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
    if(moduleIn.valid & (moduleIn.isMemRead|moduleIn.isMemWrite) & ~busy) begin
        busy <= 1;
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
        busy <= 0;
    end


end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        moduleOut.valid <= 0;
    end else begin
        moduleOut.valid <= moduleIn.valid & ~bubbleHold;
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