/* Copyright lowRISC contributors. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

.section .text.start
.globl start
start:
  /* Read mode, then tail-call either rsa_encrypt or rsa_decrypt */
  la    x2, mode
  lw    x2, 0(x2)

  li    x3, 1
  beq   x2, x3, rsa_encrypt

  li    x3, 2
  beq   x2, x3, rsa_decrypt

  /* Mode is neither 1 (= encrypt) nor 2 (= decrypt). Fail. */
  unimp

.text
/**
 * RSA encryption
 */
rsa_encrypt:
  jal      x1, modload
  jal      x1, modexp_65537

  /* pointer to out buffer */
  lw        x21, 28(x0)

  /* copy all limbs of result to wide reg file */
  li       x8, 0
  loopi     8, 2
    bn.lid   x8, 0(x21++)
    addi     x8, x8, 1

  ecall

/**
 * RSA decryption
 */
rsa_decrypt:
  jal      x1, modload
  jal      x1, modexp
  ecall


.data
/*
The structure of the 256b below are mandated by the calling convention of the
RSA library.
*/

/* Mode (1 = encrypt; 2 = decrypt) */
.globl mode
mode:
  .word 0x00000001

/* N: Key/modulus size in 256b limbs (i.e. for RSA-1024: N = 4) */
.globl n_limbs
n_limbs:
  .word 0x00000008

/* pointer to m0' (dptr_m0d) */
dptr_m0d:
  .word m0d

/* pointer to RR (dptr_rr) */
dptr_rr:
  .word RR

/* load pointer to modulus (dptr_m) */
dptr_m:
  .word modulus

/* pointer to base bignum buffer (dptr_in) */
dptr_in:
  .word in

/* pointer to exponent buffer (dptr_exp, unused for encrypt) */
dptr_exp:
  .word exp

/* pointer to out buffer (dptr_out) */
dptr_out:
  .word out


/* Freely available DMEM space. */

m0d:
  /* filled by modload */
  .zero 512

RR:
  /* filled by modload */
  .zero 512

/* Modulus (n) */
.globl modulus
modulus:
.word 0x94c790f9
.word 0x12d396cf
.word 0x50a6166f
.word 0x29e9cb5d
.word 0x0444c853
.word 0x1a2d69da
.word 0x70a8b8c1
.word 0xd896b597
.word 0x3a2cef07
.word 0xf9169066
.word 0x82f91e27
.word 0x1731322b
.word 0x862a3b9d
.word 0x512bb80f
.word 0x9979d8ab
.word 0x8694fe1e
.word 0x20ae1268
.word 0xb3c30703
.word 0x91362384
.word 0xffc826e9
.word 0x358cb9c7
.word 0xb5d0ecfb
.word 0xd4b260de
.word 0x94603c64
.word 0x6cc96f22
.word 0x6e13615b
.word 0x484f2645
.word 0x16e01ec2
.word 0x69311a58
.word 0xa0109322
.word 0x92c3263d
.word 0xd340c3a3
.word 0x31a31d33
.word 0xc561e1c7
.word 0xc166b5f4
.word 0xf64fc631
.word 0x731a2da5
.word 0x887567f4
.word 0xa1c4c8f4
.word 0xc747ab3b
.word 0x478c5b18
.word 0xadba8228
.word 0x0480397f
.word 0x080777f5
.word 0x8cff39e5
.word 0x4172fc7f
.word 0x4d5a991a
.word 0xf271e9f7
.word 0x11c96c74
.word 0x3f13b8b1
.word 0x12088e9f
.word 0xd0405aa7
.word 0x4826aae3
.word 0x39a76eb2
.word 0x438e0608
.word 0xfa8dce74
.word 0x7bf91049
.word 0x2fa44ad2
.word 0x0f9d2493
.word 0xd52cd9da
.word 0x61c9c021
.word 0xaf1fc6c3
.word 0xa51a47f4
.word 0xbdc5a92d

/* private exponent (d) */
.globl exp
exp:
.word 0x631682fd
.word 0xde2ac074
.word 0x3d776983
.word 0xbb075c1a
.word 0xcbd43497
.word 0xc028c328
.word 0x05af286a
.word 0x768424fd
.word 0x3ffac5d6
.word 0x085602c6
.word 0x9cbe752f
.word 0x8b370e92
.word 0xe34e675a
.word 0x1316b390
.word 0xa4a2754c
.word 0x460310eb
.word 0xb5a909c2
.word 0xaf531e7a
.word 0x94e7615c
.word 0x7d061d6b
.word 0xe7b4c655
.word 0x598156a6
.word 0x30dcee47
.word 0xfd49c67d
.word 0xc2a105b8
.word 0x68f1b155
.word 0x9a97c547
.word 0x3e03f331
.word 0x70e8f3c7
.word 0x79bd80ae
.word 0x3115e6fd
.word 0xaacbc612
.word 0x5a6d84d1
.word 0x174f31ed
.word 0x89951b6b
.word 0xa79f3f91
.word 0xbe4aec2c
.word 0xc02815c2
.word 0xd8ecf0b8
.word 0x98d72580
.word 0xb407de84
.word 0x7978c067
.word 0x87212a5c
.word 0x1d847647
.word 0x6b811e26
.word 0x05e25e02
.word 0xf5cb171c
.word 0xa40015c1
.word 0x5cf21bd6
.word 0x35b65521
.word 0x9c3d8e24
.word 0xb30cf35c
.word 0x5e9eff64
.word 0xe971e87f
.word 0x54ddf604
.word 0x0a7f4f00
.word 0xa5886463
.word 0x0ec87636
.word 0x5739d62c
.word 0x19cb9c6c
.word 0xcb73632c
.word 0xe12e896b
.word 0x6174c4f7
.word 0x9e639a67

/* input data */
.globl in
in:
  .byte 0x4f
  .byte 0x54
  .byte 0x42
  .byte 0x4e
  .byte 0x20
  .byte 0x69
  .byte 0x73
  .byte 0x20
  .byte 0x67
  .byte 0x72
  .byte 0x65
  .byte 0x61
  .byte 0x74
  .byte 0x21
  .zero 498

/* output data */
.globl out
out:
  .zero 512
