`ifdef VERILATOR
`include "include/common.sv"
`endif

module regfile import common::*;(
    input logic clk,rst,
    input u5 rs1,rs2,wd,
    input u64 wdData,
    input logic wdEn,
    output u64 rs1Data,rs2Data,
    output u64 regs[31:0]
);

//u64 regs[31:0];

always_ff @(negedge clk or posedge rst) begin
    if(rst) begin
        regs[0] <= 0;
        for(int i=1;i<32;i=i+1) begin
            regs[i] <= 0;
        end
    end else begin
        if(wdEn) begin
            regs[wd] <= wdData;
        end
    end
end

assign rs1Data=regs[rs1];
assign rs2Data=regs[rs2];

endmodule