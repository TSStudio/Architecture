`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/csr_mapper.sv"
`endif

module csr import common::*; import csr_pkg::*;(
    input logic clk,rst,
    input u12 read_target,
    input logic wdEn,
    input u12 write_target,
    input u64 write_data,
    //input u64 write_mask,
    output u64 read_data,
    output u64 csrs[31:0]
);

u5 mapped_csr_addr_read;
u5 mapped_csr_addr_write;
u64 csr_write_mask;

csr_mapper csr_mapper_inst(
    .target(read_target),
    .mapped_target(mapped_csr_addr_read),
    .mask()
);
csr_mapper csr_mapper_inst2(
    .target(write_target),
    .mapped_target(mapped_csr_addr_write),
    .mask(csr_write_mask)
);


//u64 regs[31:0];

always_ff @(negedge clk or posedge rst) begin
    if(rst) begin
        for(int i=0;i<32;i=i+1) begin
            csrs[i] <= 0;
        end
    end else begin
        if(wdEn) begin
            //if(write_target!=12'b000000000000) csrs[write_target] <= (csrs[write_target] & ~write_mask) | (write_data & write_mask);
            if(write_target==CSR_MSTATUS||write_target==CSR_SSTATUS) begin
                u64 temp_data = write_data & csr_write_mask;
                csrs[mapped_csr_addr_write][62:0] <= temp_data[62:0];
                csrs[mapped_csr_addr_write][63] <= temp_data[16:15]==3 | 
                                                   temp_data[14:13]==3 |
                                                   temp_data[10:9]==3;
                                                
            end else if(write_target!=12'b000000000000)
                csrs[mapped_csr_addr_write] <= write_data & csr_write_mask;
            if(write_target!=CSR_MCYCLE)
                csrs[9] <= csrs[9] + 1;
        end else csrs[9] <= csrs[9] + 1;
    end
end

assign read_data=csrs[mapped_csr_addr_read];

endmodule