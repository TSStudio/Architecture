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

    output u64 CSR_value,
    output u12 CSR_addr,
    output logic CSR_wbEn,

    output u64 CSR_value2,
    output u12 CSR_addr2,
    output logic CSR_wbEn2,

    output u64 CSR_value3,
    output u12 CSR_addr3,
    output logic CSR_wbEn3,

    output logic priviledgeModeWrite,
    output u2 newPriviledgeMode,

    output logic ok_to_proceed,
    input logic ok_to_proceed_overall
);

assign ok_to_proceed = ok;

logic ok;

always_ff @(posedge clk or posedge rst) begin

    if(rst) begin
        ok <= 1;
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
        wbEn <= 0;
        ok <= 0;
    end else begin
        if(ok==0) begin
            ok <= 1;
        end
        if(moduleIn.isWriteBack & moduleIn.valid) begin
            // write back
            wbEn <= 1;
            wd <= moduleIn.wd;
            wbData <= moduleIn.isMemRead?moduleIn.memOut:
                        moduleIn.isJump?moduleIn.pcPlus4:
                         moduleIn.aluOut;
        end else begin
            wbEn <= 0;
        end
        if((moduleIn.isCSRWrite|moduleIn.isCSRWrite2) & moduleIn.valid) begin
            CSR_wbEn <= moduleIn.isCSRWrite;
            CSR_addr <= moduleIn.CSR_addr;
            CSR_value <= moduleIn.CSR_write_value;
            CSR_wbEn2 <= moduleIn.isCSRWrite2;
            CSR_addr2 <= moduleIn.CSR_addr2;
            CSR_value2 <= moduleIn.CSR_write_value2;
        end else begin
            CSR_wbEn <= 0;
            CSR_wbEn2 <= 0;
        end
        if(moduleIn.priviledgeModeWrite & moduleIn.valid) begin
            priviledgeModeWrite <= 1;
            newPriviledgeMode <= moduleIn.newPriviledgeMode;
        end else begin
            priviledgeModeWrite <= 0;
        end
        moduleOut.valid <= 0;
    end
end

endmodule