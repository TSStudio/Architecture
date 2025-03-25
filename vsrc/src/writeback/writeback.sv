`ifdef VERILATOR
`include "include/common.sv"
`endif

module writeback import common::*;(
    input logic clk,rst,
    input REG_MEM_WB moduleIn,
    output logic wbEn,
    output u5 wd,
    output u64 wbData,
    output WB_COMMIT moduleOut,

    output logic JumpEn,
    output u64 JumpAddr,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall
);

assign ok_to_proceed = ok;

assign JumpEn = (moduleIn.isJump|(moduleIn.isBranch&moduleIn.branchAdopted)) & moduleIn.valid;

assign JumpAddr = {moduleIn.aluOut[63:1],1'b0};

logic ok;

always_ff @(posedge clk or posedge rst) begin
    if(ok==0) begin
        ok <= 1;
    end

    if(rst) begin
        // do nothing
    end else if(ok_to_proceed_overall) begin
        moduleOut.valid <= moduleIn.valid;
        if(moduleIn.valid) begin
            if(moduleIn.isWriteBack) begin
                // write back
                moduleOut.isWb <= 1;
                moduleOut.wd <= moduleIn.wd;
                moduleOut.wdData <= moduleIn.isMemRead?moduleIn.memOut:moduleIn.aluOut;
                moduleOut.instrAddr <= moduleIn.instrAddr;
                moduleOut.instr <= moduleIn.instr;
                moduleOut.isMem <= moduleIn.isMem;
                moduleOut.memAddr <= moduleIn.memAddr;
            end else if (moduleIn.isJump) begin
                moduleOut.isWb <= 1;
                moduleOut.wd <= moduleIn.wd;
                moduleOut.wdData <= moduleIn.pcPlus4;
                moduleOut.instrAddr <= moduleIn.instrAddr;
                moduleOut.instr <= moduleIn.instr;
                moduleOut.isMem <= moduleIn.isMem;
                moduleOut.memAddr <= moduleIn.memAddr;
            end else begin
                wbEn <= 0;
                moduleOut.isWb <= 0;
                moduleOut.instrAddr <= moduleIn.instrAddr;
                moduleOut.instr <= moduleIn.instr;
                moduleOut.isMem <= moduleIn.isMem;
                moduleOut.memAddr <= moduleIn.memAddr;
            end
        end
        ok <= 0;
    end else begin
        if(moduleIn.isWriteBack & moduleIn.valid) begin
            // write back
            wbEn <= 1;
            wd <= moduleIn.wd;
            wbData <= moduleIn.isMemRead?moduleIn.memOut:
                        moduleIn.isJump?moduleIn.pcPlus4:
                         moduleIn.aluOut;
        end
        else begin
            wbEn <= 0;
        end
        moduleOut.valid <= 0;
    end
end

endmodule