`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/csr_mapper.sv"
`endif

module csr import common::*; import csr_pkg::*;(
    input logic clk,rst,
    input u12 read_target,
    input logic wdEn,wdEn2,wdEn3,
    input u12 write_target,write_target2,write_target3,
    input u64 write_data,write_data2,write_data3,
    //input u64 write_mask,
    output u64 read_data,
    output u64 csrs[31:0]
);

u5 mapped_csr_addr_read;
u5 mapped_csr_addr_write;
u5 mapped_csr_addr_write2;
u5 mapped_csr_addr_write3;
u64 csr_write_mask;
u64 csr_write_mask2;
u64 csr_write_mask3;

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
csr_mapper csr_mapper_inst3(
    .target(write_target2),
    .mapped_target(mapped_csr_addr_write2),
    .mask(csr_write_mask2)
);
csr_mapper csr_mapper_inst4(
    .target(write_target3),
    .mapped_target(mapped_csr_addr_write3),
    .mask(csr_write_mask3)
);

logic wdEn2X,wdEn3X;

assign wdEn2X = wdEn2 & (mapped_csr_addr_write!=mapped_csr_addr_write2);
assign wdEn3X = wdEn3 & (mapped_csr_addr_write!=mapped_csr_addr_write3) & (mapped_csr_addr_write2!=mapped_csr_addr_write3);

//u64 regs[31:0];

always_ff @(negedge clk or posedge rst) begin
    if(rst) begin
        for(int i=0;i<32;i=i+1) begin
            csrs[i] <= 0;
        end
    end else begin
        if(wdEn) begin
            if(write_target==CSR_MSTATUS||write_target==CSR_SSTATUS) begin
                u64 temp_data = write_data & csr_write_mask;
                csrs[mapped_csr_addr_write][62:0] <= temp_data[62:0];
                csrs[mapped_csr_addr_write][63] <= temp_data[16:15]==3 | 
                                                temp_data[14:13]==3 |
                                                temp_data[10:9]==3;
                                                
            end else if(write_target!=12'b000000000000)
                csrs[mapped_csr_addr_write] <= write_data & csr_write_mask;
        end
        if(wdEn2X) begin
            if(write_target2==CSR_MSTATUS||write_target2==CSR_SSTATUS) begin
                u64 temp_data = write_data2 & csr_write_mask2;
                csrs[mapped_csr_addr_write2][62:0] <= temp_data[62:0];
                csrs[mapped_csr_addr_write2][63] <= temp_data[16:15]==3 | 
                                                temp_data[14:13]==3 |
                                                temp_data[10:9]==3;
                                                
            end else if(write_target2!=12'b000000000000)
                csrs[mapped_csr_addr_write2] <= write_data2 & csr_write_mask2;
        end
        if(wdEn3X) begin
            if(write_target3==CSR_MSTATUS||write_target3==CSR_SSTATUS) begin
                u64 temp_data = write_data3 & csr_write_mask3;
                csrs[mapped_csr_addr_write3][62:0] <= temp_data[62:0];
                csrs[mapped_csr_addr_write3][63] <= temp_data[16:15]==3 | 
                                                temp_data[14:13]==3 |
                                                temp_data[10:9]==3;
                                                
            end else if(write_target3!=12'b000000000000)
                csrs[mapped_csr_addr_write3] <= write_data3 & csr_write_mask3;
        end
        if((~wdEn && ~wdEn2 && ~wdEn3) | (write_target!=CSR_MCYCLE && write_target2!=CSR_MCYCLE && write_target3!=CSR_MCYCLE))
            csrs[9] <= csrs[9] + 1;
    end
end

assign read_data=csrs[mapped_csr_addr_read];

endmodule