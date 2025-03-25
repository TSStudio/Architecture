`ifdef VERILATOR
`include "include/common.sv"
`endif

module csr import common::*;(
    input logic clk,rst,
    input u12 read_target,
    input logic wdEn,
    input u12 write_target,
    input u64 write_data,
    //input u64 write_mask,
    output u64 read_data,
    output u64 csrs[4095:0]
);

//u64 regs[31:0];

always_ff @(negedge clk or posedge rst) begin
    if(rst) begin
        for(int i=0;i<4096;i=i+1) begin
            csrs[i] <= 0;
        end
    end else begin
        if(wdEn) begin
            //if(write_target!=12'b000000000000) csrs[write_target] <= (csrs[write_target] & ~write_mask) | (write_data & write_mask);
            if(write_target!=12'b000000000000) csrs[write_target] <= write_data;
        end
    end
end

assign read_data=csrs[read_target];

endmodule