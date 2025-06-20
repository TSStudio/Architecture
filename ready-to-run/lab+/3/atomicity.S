
temp.elf:     file format elf64-littleriscv


Disassembly of section .data:

0000000000000000 <_binary_atomicity_bin_start>:
   0:	0010029b          	addiw	x5,x0,1
   4:	01f29293          	slli	x5,x5,0x1f
   8:	10028293          	addi	x5,x5,256
   c:	12345337          	lui	x6,0x12345
  10:	6783031b          	addiw	x6,x6,1656 # 12345678 <_binary_atomicity_bin_end+0x12345594>
  14:	0062a023          	sw	x6,0(x5)
  18:	000383b7          	lui	x7,0x38
  1c:	ab73839b          	addiw	x7,x7,-1353 # 37ab7 <_binary_atomicity_bin_end+0x379d3>
  20:	00e39393          	slli	x7,x7,0xe
  24:	eef38393          	addi	x7,x7,-273
  28:	0872ae2f          	amoswap.w	x28,x7,(x5)
  2c:	12345eb7          	lui	x29,0x12345
  30:	678e8e9b          	addiw	x29,x29,1656 # 12345678 <_binary_atomicity_bin_end+0x12345594>
  34:	0bde1663          	bne	x28,x29,e0 <_binary_atomicity_bin_start+0xe0>
  38:	0002ef03          	lwu	x30,0(x5)
  3c:	00038fb7          	lui	x31,0x38
  40:	ab7f8f9b          	addiw	x31,x31,-1353 # 37ab7 <_binary_atomicity_bin_end+0x379d3>
  44:	00ef9f93          	slli	x31,x31,0xe
  48:	eeff8f93          	addi	x31,x31,-273
  4c:	09ff1a63          	bne	x30,x31,e0 <_binary_atomicity_bin_start+0xe0>
  50:	0010029b          	addiw	x5,x0,1
  54:	01f29293          	slli	x5,x5,0x1f
  58:	10028293          	addi	x5,x5,256
  5c:	12345337          	lui	x6,0x12345
  60:	6783031b          	addiw	x6,x6,1656 # 12345678 <_binary_atomicity_bin_end+0x12345594>
  64:	0062a023          	sw	x6,0(x5)
  68:	00100393          	li	x7,1
  6c:	0072ae2f          	amoadd.w	x28,x7,(x5)
  70:	12345eb7          	lui	x29,0x12345
  74:	678e8e9b          	addiw	x29,x29,1656 # 12345678 <_binary_atomicity_bin_end+0x12345594>
  78:	07de1463          	bne	x28,x29,e0 <_binary_atomicity_bin_start+0xe0>
  7c:	0002ef03          	lwu	x30,0(x5)
  80:	12345fb7          	lui	x31,0x12345
  84:	679f8f9b          	addiw	x31,x31,1657 # 12345679 <_binary_atomicity_bin_end+0x12345595>
  88:	05ff1c63          	bne	x30,x31,e0 <_binary_atomicity_bin_start+0xe0>
  8c:	0010029b          	addiw	x5,x0,1
  90:	01f29293          	slli	x5,x5,0x1f
  94:	10028293          	addi	x5,x5,256
  98:	12345337          	lui	x6,0x12345
  9c:	6783031b          	addiw	x6,x6,1656 # 12345678 <_binary_atomicity_bin_end+0x12345594>
  a0:	0062a023          	sw	x6,0(x5)
  a4:	1002a3af          	lr.w	x7,(x5)
  a8:	00038e37          	lui	x28,0x38
  ac:	ab7e0e1b          	addiw	x28,x28,-1353 # 37ab7 <_binary_atomicity_bin_end+0x379d3>
  b0:	00ee1e13          	slli	x28,x28,0xe
  b4:	eefe0e13          	addi	x28,x28,-273
  b8:	19c2aeaf          	sc.w	x29,x28,(x5)
  bc:	00000f13          	li	x30,0
  c0:	03ee9063          	bne	x29,x30,e0 <_binary_atomicity_bin_start+0xe0>
  c4:	0002ef83          	lwu	x31,0(x5)
  c8:	00038e37          	lui	x28,0x38
  cc:	ab7e0e1b          	addiw	x28,x28,-1353 # 37ab7 <_binary_atomicity_bin_end+0x379d3>
  d0:	00ee1e13          	slli	x28,x28,0xe
  d4:	eefe0e13          	addi	x28,x28,-273
  d8:	01cf9463          	bne	x31,x28,e0 <_binary_atomicity_bin_start+0xe0>
  dc:	0005006b          	.insn	4, 0x0005006b
  e0:	0000006f          	j	e0 <_binary_atomicity_bin_start+0xe0>
