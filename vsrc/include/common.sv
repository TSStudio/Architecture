`ifndef COMMON_SV
`define COMMON_SV
`ifdef VERILATOR
`include "include/config.sv"
`endif

import config_pkg::*;
package common;
	// parameters
	import config_pkg::*;
	parameter XLEN = 64;
	parameter MXLEN = XLEN;
	parameter LINK_REG_ID = 1;
	parameter logic[63:0] PCINIT = 64'h00000000_80000000;

	// typedefs
	typedef logic[127:0] u128;
	typedef logic[63:0] u64;
	typedef logic[43:0] u44;
	typedef logic[31:0] u32;
	typedef logic[19:0] u20;
	typedef logic[15:0] u16;
	typedef logic[14:0] u15;
	typedef logic[13:0] u14;
	typedef logic[12:0] u13;
	typedef logic[11:0] u12;
	typedef logic[10:0] u11;
	typedef logic[9:0]  u10;
	typedef logic[8:0]  u9;
	typedef logic[7:0]  u8;
	typedef logic[6:0]  u7;
	typedef logic[5:0]  u6;
	typedef logic[4:0]  u5;
	typedef logic[3:0]  u4;
	typedef logic[2:0]  u3;
	typedef logic[1:0]  u2;
	typedef logic 	    u1;

	typedef u5 creg_addr_t;
	// typedef u64 word_t;
	typedef u8 strobe_t;
	typedef u12 csr_addr_t;

/**
 * this file contains basic definitions and typedefs for general designs.
 */

// Vivado does not support string parameters.
`ifdef VERILATOR
`define STRING string
`else
`define STRING /* f**k vivado */
`endif

/**
 * Vivado does not support that members of a packed union
 * have different sizes. Therefore, we have to use struct
 * instead of union in Vivado.
 */
`ifdef VERILATOR
`define PACKED_UNION union packed
`else
`define PACKED_UNION struct packed
`endif

// simple compile-time assertion
`define ASSERTS(expr, message) \
    if (!(expr)) $error(message);
`define ASSERT(expr) `ASSERTS(expr, "Assertion failed.");
 
// to ignore some signals
`define UNUSED_OK(list) \
    logic _unused_ok = &{1'b0, {list}, 1'b0};

// basic data types
`define BITS(x) logic[(x)-1:0]

typedef int unsigned uint;

typedef logic     i1;
typedef `BITS(2)  i2;
typedef `BITS(3)  i3;
typedef `BITS(4)  i4;
typedef `BITS(5)  i5;
typedef `BITS(6)  i6;
typedef `BITS(7)  i7;
typedef `BITS(8)  i8;
typedef `BITS(9)  i9;
typedef `BITS(16) i16;
typedef `BITS(19) i19;
typedef `BITS(26) i26;
typedef `BITS(32) i32;
typedef `BITS(33) i33;
typedef `BITS(34) i34;
typedef `BITS(35) i35;
typedef `BITS(36) i36;
typedef `BITS(37) i37;
typedef `BITS(38) i38;
typedef `BITS(39) i39;
typedef `BITS(40) i40;
typedef `BITS(41) i41;
typedef `BITS(42) i42;
typedef `BITS(64) i64;
typedef `BITS(65) i65;
typedef `BITS(66) i66;
typedef `BITS(67) i67;
typedef `BITS(68) i68;

// for arithmetic overflow detection
typedef i65 arith_t;

// all addresses and words are 64-bit
typedef i64 addr_t;
typedef i64 word_t;

// number of bytes transferred in one memory r/w
typedef enum i3 {
    MSIZE1 = 3'b000,
    MSIZE2 = 3'b001,
    MSIZE4 = 3'b010,
    MSIZE8 = 3'b011
} msize_t;

// length of a burst transaction
// NOTE: WRAP mode in AXI3 only supports power-of-2 length.
typedef enum i8 {
    MLEN1  = 8'h00,
    MLEN2  = 8'h01,
    MLEN4  = 8'h03,
    MLEN8  = 8'h07,
    MLEN16 = 8'h0f,
    MLEN32 = 8'h1f,
    MLEN64 = 8'h3f,
    MLEN128 = 8'h7f,
    MLEN256 = 8'hff
} mlen_t;

parameter mlen_t AXI_BURST_LEN =AXI_BURST_NUM == 16 ? MLEN16 :
 							    AXI_BURST_NUM == 32 ? MLEN32 :
							    AXI_BURST_NUM == 64 ? MLEN64 :
							    AXI_BURST_NUM == 128 ? MLEN128 :
							    AXI_BURST_NUM == 256 ? MLEN256 : MLEN1;

/**
 * SOME NOTES ON BUSES
 *
 * bus naming convention:
 *  * CPU -> cache: xxx_req_t
 *  * cache -> CPU: xxx_resp_t
 *
 * in other words, caches are masters and CPU is the worker,
 * and CPU must wait for caches to complete memory transactions.
 * handshake signals are synchronized at positive edge of the clock.
 *
 * we guarantee that IBus is a subset of DBus, so that data cache can
 * be used as a instruction cache.
 * powerful students are free to design their own bus interfaces to
 * enable superscalar pipelines and other advanced techniques.
 *
 * a request on cache bus can bypass a cache instance if the address
 * is in uncached memory regions.
 */

/**
 * NOTE on strobe:
 *
 * strobe is used to mask out unused bytes in data, and
 * data are always assumed be placed at addresses aligned to
 * 8 bytes, no matter the lowest 3 bits of addr says.
 * for example, if you want to write one byte "0xcd" at 0x1f2,
 * the addr is "0x000001f2", but the data should be "0x00cd0000"
 * and the strobe should be "0b0100", rather than "0x000000cd"
 * and "0b0001".
 */

/**
 * data cache bus
 */
typedef struct packed {
    logic    valid;     // in request?
    addr_t   addr;      // target address
    msize_t  size;      // number of bytes
    strobe_t strobe;    // which bytes are enabled? set to zeros for read request
    word_t   data;      // the data to write
} dbus_req_t;

typedef struct packed {
    logic  addr_ok;     // is the address accepted by cache?
    logic  data_ok;     // is the field "data" valid?
    word_t data;        // the data read from cache
} dbus_resp_t;

/**
 * instruction cache bus
 * addr must be aligned to 4 bytes.
 *
 * basically, ibus_resp_t is the same as dbus_resp_t.
 */
typedef struct packed {
    logic  valid;       // in request?
    addr_t addr;        // target address
} ibus_req_t;

typedef struct packed {
    logic  addr_ok;     // is the address accepted by cache?
    logic  data_ok;     // is the field "data" valid?
    u32 data;           // the data read from cache
} ibus_resp_t;

`define IREQ_TO_DREQ(ireq) \
    {ireq, MSIZE4, 8'b0, 64'b0}

`define DRESP_TO_IRESP(dresp, ireq) \
    {dresp.addr_ok, dresp.data_ok, ireq.addr[2] ? dresp.data[63:32] : dresp.data[31:0]}

/**
 * cache bus: simplified burst AXI transaction interface
 */
typedef enum i2 {
    AXI_BURST_FIXED = '0,
    AXI_BURST_INCR,
    AXI_BURST_WRAP,
    AXI_BURST_RESERVED
} axi_burst_type_t;

typedef enum u3 {
    CSRRW = 3'b001,
    CSRRS = 3'b010,
    CSRRC = 3'b011,
    CSRRWI = 3'b101,
    CSRRSI = 3'b110,
    CSRRCI = 3'b111,
    ETRAP = 3'b000,

    UNKNOWN2 = 3'b100
} csr_op_t;

typedef enum u3 {
    ECALL = 3'b000,
    EBREAK = 3'b001,
    MRET = 3'b010,
    UNKNOWN = 3'b111
} trap_t;

typedef struct packed {
    logic    valid;     // in request?
    logic    is_write;  // is it a write transaction?
    msize_t  size;      // number of bytes in one burst
    addr_t   addr;      // start address
    strobe_t strobe;    // which bytes are enabled?
    word_t   data;      // the data to write
    mlen_t   len;       // number of bursts
    axi_burst_type_t burst;
} cbus_req_t;

typedef struct packed {
    logic  ready;       // is data arrived in this cycle?
    logic  last;        // is it the last word?
    word_t data;        // the data from AXI bus
} cbus_resp_t;

typedef enum u4 {
    MACHINE_EXTERNAL_INTERRUPT = 4'b0000,
    SUPERVISOR_EXTERNAL_INTERRUPT = 4'b0001,
    MACHINE_SOFTWARE_INTERRUPT = 4'b0010,
    SUPERVISOR_SOFTWARE_INTERRUPT = 4'b0011,
    MACHINE_TIMER_INTERRUPT = 4'b0100,
    SUPERVISOR_TIMER_INTERRUPT = 4'b0101,
    ILLEGAL_INSTRUCTION = 4'b0110,
    INSTRUCTION_ADDRESS_MISALIGNED = 4'b1000,
    ENVIRONMENT_CALL_FROM_U_MODE = 4'b1010,
    LOAD_ADDRESS_MISALIGNED = 4'b1100,
    STORE_AMO_ADDRESS_MISALIGNED = 4'b1110,
    NO_EXCEPTION = 4'b1111
} exception_t;

typedef enum u6 {
    LR_W = 6'b000010,
    SC_W = 6'b000011,
    AMO_SWAP_W = 6'b000001,
    AMO_ADD_W = 6'b000000,
    AMO_XOR_W = 6'b000100,
    AMO_AND_W = 6'b001100,
    AMO_OR_W = 6'b001000,
    AMO_MIN_W = 6'b010000,
    AMO_MAX_W = 6'b010100,
    AMO_MINU_W = 6'b011000,
    AMO_MAXU_W = 6'b011100,
    LR_D = 6'b100010,
    SC_D = 6'b100011,
    AMO_SWAP_D = 6'b100001,
    AMO_ADD_D = 6'b100000,
    AMO_XOR_D = 6'b100100,
    AMO_AND_D = 6'b101100,
    AMO_OR_D = 6'b101000,
    AMO_MIN_D = 6'b110000,
    AMO_MAX_D = 6'b110100,
    AMO_MINU_D = 6'b111000,
    AMO_MAXU_D = 6'b111100

} amo_t;

typedef struct packed {
    logic  valid;
    u64 pcPlus4;
    u64 pc;
    u32 instr;

    u64 instrAddr;

    logic exception_valid;
    exception_t exception;
} REG_IF_ID;

typedef struct packed {
    logic valid;
    u64 pcPlus4;
    u64 pc;
    u64 rs1;
    u2 srcA; // 00: 0, 01: rs1, 10: pc
    u2 srcB; // 00: rs2, 01: imm, 10: imm<<12 , 11: csr
    u64 rs2;
    u64 imm;
    logic isWriteBack;
    u5 wd;
    u3 aluOp;
    u4 mulOp;
    logic isBranch;
    logic isJump;
    logic rv64;
    logic rvm;

    logic cns; // compare and set
    logic cmpSrcB; // compare source B 0 for rs2, 1 for imm
    u2 useflag; 
    logic flagInv;

    u32 instr;
    u64 instrAddr;

    logic isMemWrite;
    logic isMemRead;
    u4 memMode;

    logic isCSRWrite;
    u64 CSR_value;
    u12 CSR_addr;
    csr_op_t csr_op;
    trap_t trap;

    logic exception_valid;
    exception_t exception;

    u64 addr_if_jump; // address to jump to if jump is taken
    u64 addr_if_not_jump; // address to jump to if jump is not taken
    logic adopt_branch; // if true, branch is adopted, otherwise, it is not adopted

    logic is_amo;
    amo_t amo_type;
} REG_ID_EX;

typedef struct packed {
    logic valid;
    u64 rs1;
    u64 rs2;
    u64 aluOut;
    u64 pcPlus4;
    logic isWriteBack;
    u5 wd;
    logic isBranch;
    logic isJump;

    logic flagResult;

    u32 instr;
    u64 instrAddr;

    logic isMemWrite;
    logic isMemRead;
    u4 memMode;

    logic isCSRWrite;
    u64 CSR_write_value;
    u12 CSR_addr;
    csr_op_t csr_op;
    trap_t trap;

    logic exception_valid;
    exception_t exception;

    u64 addr_if_jump; // address to jump to if jump is taken
    u64 addr_if_not_jump; // address to jump to if jump is not taken
    logic adopt_branch; // if true, branch is adopted, otherwise, it is not adopted

    logic is_amo;
    amo_t amo_type;
} REG_EX_MEM;

typedef struct packed {
    logic  valid;
    u64 aluOut;
    u64 pcPlus4;
    u5  wd;
    logic isWriteBack;
    
    u64 memOut;

    logic isJump;

    u32 instr;
    u64 instrAddr;

    logic isMemRead;

    logic isMem;
    u64 memAddr;

    logic isCSRWrite;
    u64 CSR_write_value;
    u12 CSR_addr;
    logic isCSRWrite2;
    u64 CSR_write_value2;
    u12 CSR_addr2;
    logic isCSRWrite3;
    u64 CSR_write_value3;
    u12 CSR_addr3;

    logic skip;
} REG_MEM_WB;

typedef struct packed {
    logic valid;
    u32 instr;
    u64 instrAddr;
    logic isWb;
    u5  wd;
    u64 wdData;
    logic skip;

    logic isMem;
    u64 memAddr;
} WB_COMMIT;

typedef struct packed {
    logic valid;
    logic isWb;
    u5  wd;
    u64 wdData;
} FORWARD_SOURCE;

typedef enum u2 {
    MUL = 2'b00,
    DIV = 2'b01,
    REM = 2'b10
} mul_op_t;

typedef struct packed {
    logic dw; // 0: 32, 1: 64
    mul_op_t op; // operation
    u64 ia; // operand A
    u64 ia_orig; // original operand A
    u64 ib; // operand B
} mbus_req_t;

endpackage
`endif
