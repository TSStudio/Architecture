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

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall
);

assign ok_to_proceed = 1; // always proceed

always_ff @(posedge clk or posedge rst) begin
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
            end
            else begin
                wbEn <= 0;
                moduleOut.isWb <= 0;
                moduleOut.instrAddr <= moduleIn.instrAddr;
                moduleOut.instr <= moduleIn.instr;
            end
        end
    end else begin
        if(moduleIn.isWriteBack) begin
            // write back
            wbEn <= 1;
            wd <= moduleIn.wd;
            wbData <= moduleIn.isMemRead?moduleIn.memOut:moduleIn.aluOut;
        end
        else begin
            wbEn <= 0;
        end
        moduleOut.valid <= 0;
    end
end

endmodule