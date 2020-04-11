// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Top module auto-generated by `reggen`

`include "prim_assert.sv"

module entropy_src_reg_top (
  input clk_i,
  input rst_ni,

  // Below Regster interface can be changed
  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,
  // To HW
  output entropy_src_reg_pkg::entropy_src_reg2hw_t reg2hw, // Write
  input  entropy_src_reg_pkg::entropy_src_hw2reg_t hw2reg, // Read

  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);

  import entropy_src_reg_pkg::* ;

  localparam int AW = 6;
  localparam int DW = 32;
  localparam int DBW = DW/8;                    // Byte Width

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [AW-1:0]  reg_addr;
  logic [DW-1:0]  reg_wdata;
  logic [DBW-1:0] reg_be;
  logic [DW-1:0]  reg_rdata;
  logic           reg_error;

  logic          addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  tlul_pkg::tl_h2d_t tl_reg_h2d;
  tlul_pkg::tl_d2h_t tl_reg_d2h;

  assign tl_reg_h2d = tl_i;
  assign tl_o       = tl_reg_d2h;

  tlul_adapter_reg #(
    .RegAw(AW),
    .RegDw(DW)
  ) u_reg_if (
    .clk_i,
    .rst_ni,

    .tl_i (tl_reg_h2d),
    .tl_o (tl_reg_d2h),

    .we_o    (reg_we),
    .re_o    (reg_re),
    .addr_o  (reg_addr),
    .wdata_o (reg_wdata),
    .be_o    (reg_be),
    .rdata_i (reg_rdata),
    .error_i (reg_error)
  );

  assign reg_rdata = reg_rdata_next ;
  assign reg_error = (devmode_i & addrmiss) | wr_err ;

  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic intr_state_es_entropy_valid_qs;
  logic intr_state_es_entropy_valid_wd;
  logic intr_state_es_entropy_valid_we;
  logic intr_state_es_rct_failed_qs;
  logic intr_state_es_rct_failed_wd;
  logic intr_state_es_rct_failed_we;
  logic intr_state_es_apt_failed_qs;
  logic intr_state_es_apt_failed_wd;
  logic intr_state_es_apt_failed_we;
  logic intr_state_es_fifo_err_qs;
  logic intr_state_es_fifo_err_wd;
  logic intr_state_es_fifo_err_we;
  logic intr_enable_es_entropy_valid_qs;
  logic intr_enable_es_entropy_valid_wd;
  logic intr_enable_es_entropy_valid_we;
  logic intr_enable_es_rct_failed_qs;
  logic intr_enable_es_rct_failed_wd;
  logic intr_enable_es_rct_failed_we;
  logic intr_enable_es_apt_failed_qs;
  logic intr_enable_es_apt_failed_wd;
  logic intr_enable_es_apt_failed_we;
  logic intr_enable_es_fifo_err_qs;
  logic intr_enable_es_fifo_err_wd;
  logic intr_enable_es_fifo_err_we;
  logic intr_test_es_entropy_valid_wd;
  logic intr_test_es_entropy_valid_we;
  logic intr_test_es_rct_failed_wd;
  logic intr_test_es_rct_failed_we;
  logic intr_test_es_apt_failed_wd;
  logic intr_test_es_apt_failed_we;
  logic intr_test_es_fifo_err_wd;
  logic intr_test_es_fifo_err_we;
  logic es_regen_qs;
  logic es_regen_wd;
  logic es_regen_we;
  logic [7:0] es_rev_abi_revision_qs;
  logic [7:0] es_rev_hw_revision_qs;
  logic [7:0] es_rev_chip_type_qs;
  logic [1:0] es_conf_enable_qs;
  logic [1:0] es_conf_enable_wd;
  logic es_conf_enable_we;
  logic es_conf_rng_src_en_qs;
  logic es_conf_rng_src_en_wd;
  logic es_conf_rng_src_en_we;
  logic es_conf_rct_en_qs;
  logic es_conf_rct_en_wd;
  logic es_conf_rct_en_we;
  logic es_conf_apt_en_qs;
  logic es_conf_apt_en_wd;
  logic es_conf_apt_en_we;
  logic es_conf_rng_bit_en_qs;
  logic es_conf_rng_bit_en_wd;
  logic es_conf_rng_bit_en_we;
  logic [1:0] es_conf_rng_bit_sel_qs;
  logic [1:0] es_conf_rng_bit_sel_wd;
  logic es_conf_rng_bit_sel_we;
  logic [15:0] es_rct_health_qs;
  logic [15:0] es_rct_health_wd;
  logic es_rct_health_we;
  logic [15:0] es_apt_health_apt_max_qs;
  logic [15:0] es_apt_health_apt_max_wd;
  logic es_apt_health_apt_max_we;
  logic [15:0] es_apt_health_apt_win_qs;
  logic [15:0] es_apt_health_apt_win_wd;
  logic es_apt_health_apt_win_we;
  logic [31:0] es_entropy_qs;
  logic es_entropy_re;
  logic [2:0] es_fifo_status_dig_src_depth_qs;
  logic es_fifo_status_dig_src_depth_re;
  logic [2:0] es_fifo_status_hwif_depth_qs;
  logic es_fifo_status_hwif_depth_re;
  logic [4:0] es_fifo_status_es_depth_qs;
  logic es_fifo_status_es_depth_re;
  logic es_fifo_status_diag_qs;
  logic es_fifo_status_diag_re;
  logic [2:0] es_fdepthst_qs;
  logic es_fdepthst_re;
  logic [2:0] es_thresh_qs;
  logic [2:0] es_thresh_wd;
  logic es_thresh_we;
  logic [15:0] es_rate_qs;
  logic [15:0] es_rate_wd;
  logic es_rate_we;
  logic [3:0] es_seed_qs;
  logic [3:0] es_seed_wd;
  logic es_seed_we;

  // Register instances
  // R[intr_state]: V(False)

  //   F[es_entropy_valid]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h0)
  ) u_intr_state_es_entropy_valid (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_state_es_entropy_valid_we),
    .wd     (intr_state_es_entropy_valid_wd),

    // from internal hardware
    .de     (hw2reg.intr_state.es_entropy_valid.de),
    .d      (hw2reg.intr_state.es_entropy_valid.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_state.es_entropy_valid.q ),

    // to register interface (read)
    .qs     (intr_state_es_entropy_valid_qs)
  );


  //   F[es_rct_failed]: 1:1
  prim_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h0)
  ) u_intr_state_es_rct_failed (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_state_es_rct_failed_we),
    .wd     (intr_state_es_rct_failed_wd),

    // from internal hardware
    .de     (hw2reg.intr_state.es_rct_failed.de),
    .d      (hw2reg.intr_state.es_rct_failed.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_state.es_rct_failed.q ),

    // to register interface (read)
    .qs     (intr_state_es_rct_failed_qs)
  );


  //   F[es_apt_failed]: 2:2
  prim_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h0)
  ) u_intr_state_es_apt_failed (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_state_es_apt_failed_we),
    .wd     (intr_state_es_apt_failed_wd),

    // from internal hardware
    .de     (hw2reg.intr_state.es_apt_failed.de),
    .d      (hw2reg.intr_state.es_apt_failed.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_state.es_apt_failed.q ),

    // to register interface (read)
    .qs     (intr_state_es_apt_failed_qs)
  );


  //   F[es_fifo_err]: 3:3
  prim_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h0)
  ) u_intr_state_es_fifo_err (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_state_es_fifo_err_we),
    .wd     (intr_state_es_fifo_err_wd),

    // from internal hardware
    .de     (hw2reg.intr_state.es_fifo_err.de),
    .d      (hw2reg.intr_state.es_fifo_err.d ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_state.es_fifo_err.q ),

    // to register interface (read)
    .qs     (intr_state_es_fifo_err_qs)
  );


  // R[intr_enable]: V(False)

  //   F[es_entropy_valid]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_intr_enable_es_entropy_valid (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_enable_es_entropy_valid_we),
    .wd     (intr_enable_es_entropy_valid_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_enable.es_entropy_valid.q ),

    // to register interface (read)
    .qs     (intr_enable_es_entropy_valid_qs)
  );


  //   F[es_rct_failed]: 1:1
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_intr_enable_es_rct_failed (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_enable_es_rct_failed_we),
    .wd     (intr_enable_es_rct_failed_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_enable.es_rct_failed.q ),

    // to register interface (read)
    .qs     (intr_enable_es_rct_failed_qs)
  );


  //   F[es_apt_failed]: 2:2
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_intr_enable_es_apt_failed (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_enable_es_apt_failed_we),
    .wd     (intr_enable_es_apt_failed_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_enable.es_apt_failed.q ),

    // to register interface (read)
    .qs     (intr_enable_es_apt_failed_qs)
  );


  //   F[es_fifo_err]: 3:3
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_intr_enable_es_fifo_err (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (intr_enable_es_fifo_err_we),
    .wd     (intr_enable_es_fifo_err_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.intr_enable.es_fifo_err.q ),

    // to register interface (read)
    .qs     (intr_enable_es_fifo_err_qs)
  );


  // R[intr_test]: V(True)

  //   F[es_entropy_valid]: 0:0
  prim_subreg_ext #(
    .DW    (1)
  ) u_intr_test_es_entropy_valid (
    .re     (1'b0),
    .we     (intr_test_es_entropy_valid_we),
    .wd     (intr_test_es_entropy_valid_wd),
    .d      ('0),
    .qre    (),
    .qe     (reg2hw.intr_test.es_entropy_valid.qe),
    .q      (reg2hw.intr_test.es_entropy_valid.q ),
    .qs     ()
  );


  //   F[es_rct_failed]: 1:1
  prim_subreg_ext #(
    .DW    (1)
  ) u_intr_test_es_rct_failed (
    .re     (1'b0),
    .we     (intr_test_es_rct_failed_we),
    .wd     (intr_test_es_rct_failed_wd),
    .d      ('0),
    .qre    (),
    .qe     (reg2hw.intr_test.es_rct_failed.qe),
    .q      (reg2hw.intr_test.es_rct_failed.q ),
    .qs     ()
  );


  //   F[es_apt_failed]: 2:2
  prim_subreg_ext #(
    .DW    (1)
  ) u_intr_test_es_apt_failed (
    .re     (1'b0),
    .we     (intr_test_es_apt_failed_we),
    .wd     (intr_test_es_apt_failed_wd),
    .d      ('0),
    .qre    (),
    .qe     (reg2hw.intr_test.es_apt_failed.qe),
    .q      (reg2hw.intr_test.es_apt_failed.q ),
    .qs     ()
  );


  //   F[es_fifo_err]: 3:3
  prim_subreg_ext #(
    .DW    (1)
  ) u_intr_test_es_fifo_err (
    .re     (1'b0),
    .we     (intr_test_es_fifo_err_we),
    .wd     (intr_test_es_fifo_err_wd),
    .d      ('0),
    .qre    (),
    .qe     (reg2hw.intr_test.es_fifo_err.qe),
    .q      (reg2hw.intr_test.es_fifo_err.q ),
    .qs     ()
  );


  // R[es_regen]: V(False)

  prim_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h1)
  ) u_es_regen (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (es_regen_we),
    .wd     (es_regen_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_regen.q ),

    // to register interface (read)
    .qs     (es_regen_qs)
  );


  // R[es_rev]: V(False)

  //   F[abi_revision]: 7:0
  // constant-only read
  assign es_rev_abi_revision_qs = 8'h1;


  //   F[hw_revision]: 15:8
  // constant-only read
  assign es_rev_hw_revision_qs = 8'h1;


  //   F[chip_type]: 23:16
  // constant-only read
  assign es_rev_chip_type_qs = 8'h1;


  // R[es_conf]: V(False)

  //   F[enable]: 1:0
  prim_subreg #(
    .DW      (2),
    .SWACCESS("RW"),
    .RESVAL  (2'h0)
  ) u_es_conf_enable (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_conf_enable_we & es_regen_qs),
    .wd     (es_conf_enable_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_conf.enable.q ),

    // to register interface (read)
    .qs     (es_conf_enable_qs)
  );


  //   F[rng_src_en]: 4:4
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_es_conf_rng_src_en (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_conf_rng_src_en_we & es_regen_qs),
    .wd     (es_conf_rng_src_en_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_conf.rng_src_en.q ),

    // to register interface (read)
    .qs     (es_conf_rng_src_en_qs)
  );


  //   F[rct_en]: 5:5
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_es_conf_rct_en (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_conf_rct_en_we & es_regen_qs),
    .wd     (es_conf_rct_en_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_conf.rct_en.q ),

    // to register interface (read)
    .qs     (es_conf_rct_en_qs)
  );


  //   F[apt_en]: 6:6
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_es_conf_apt_en (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_conf_apt_en_we & es_regen_qs),
    .wd     (es_conf_apt_en_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_conf.apt_en.q ),

    // to register interface (read)
    .qs     (es_conf_apt_en_qs)
  );


  //   F[rng_bit_en]: 8:8
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_es_conf_rng_bit_en (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_conf_rng_bit_en_we & es_regen_qs),
    .wd     (es_conf_rng_bit_en_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_conf.rng_bit_en.q ),

    // to register interface (read)
    .qs     (es_conf_rng_bit_en_qs)
  );


  //   F[rng_bit_sel]: 10:9
  prim_subreg #(
    .DW      (2),
    .SWACCESS("RW"),
    .RESVAL  (2'h0)
  ) u_es_conf_rng_bit_sel (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_conf_rng_bit_sel_we & es_regen_qs),
    .wd     (es_conf_rng_bit_sel_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_conf.rng_bit_sel.q ),

    // to register interface (read)
    .qs     (es_conf_rng_bit_sel_qs)
  );


  // R[es_rct_health]: V(False)

  prim_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (16'hb)
  ) u_es_rct_health (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_rct_health_we & es_regen_qs),
    .wd     (es_rct_health_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_rct_health.q ),

    // to register interface (read)
    .qs     (es_rct_health_qs)
  );


  // R[es_apt_health]: V(False)

  //   F[apt_max]: 15:0
  prim_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (16'h298)
  ) u_es_apt_health_apt_max (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_apt_health_apt_max_we & es_regen_qs),
    .wd     (es_apt_health_apt_max_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_apt_health.apt_max.q ),

    // to register interface (read)
    .qs     (es_apt_health_apt_max_qs)
  );


  //   F[apt_win]: 31:16
  prim_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (16'h400)
  ) u_es_apt_health_apt_win (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_apt_health_apt_win_we & es_regen_qs),
    .wd     (es_apt_health_apt_win_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_apt_health.apt_win.q ),

    // to register interface (read)
    .qs     (es_apt_health_apt_win_qs)
  );


  // R[es_entropy]: V(True)

  prim_subreg_ext #(
    .DW    (32)
  ) u_es_entropy (
    .re     (es_entropy_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.es_entropy.d),
    .qre    (reg2hw.es_entropy.re),
    .qe     (),
    .q      (reg2hw.es_entropy.q ),
    .qs     (es_entropy_qs)
  );


  // R[es_fifo_status]: V(True)

  //   F[dig_src_depth]: 2:0
  prim_subreg_ext #(
    .DW    (3)
  ) u_es_fifo_status_dig_src_depth (
    .re     (es_fifo_status_dig_src_depth_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.es_fifo_status.dig_src_depth.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (es_fifo_status_dig_src_depth_qs)
  );


  //   F[hwif_depth]: 6:4
  prim_subreg_ext #(
    .DW    (3)
  ) u_es_fifo_status_hwif_depth (
    .re     (es_fifo_status_hwif_depth_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.es_fifo_status.hwif_depth.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (es_fifo_status_hwif_depth_qs)
  );


  //   F[es_depth]: 16:12
  prim_subreg_ext #(
    .DW    (5)
  ) u_es_fifo_status_es_depth (
    .re     (es_fifo_status_es_depth_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.es_fifo_status.es_depth.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (es_fifo_status_es_depth_qs)
  );


  //   F[diag]: 31:31
  prim_subreg_ext #(
    .DW    (1)
  ) u_es_fifo_status_diag (
    .re     (es_fifo_status_diag_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.es_fifo_status.diag.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (es_fifo_status_diag_qs)
  );


  // R[es_fdepthst]: V(True)

  prim_subreg_ext #(
    .DW    (3)
  ) u_es_fdepthst (
    .re     (es_fdepthst_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.es_fdepthst.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (es_fdepthst_qs)
  );


  // R[es_thresh]: V(False)

  prim_subreg #(
    .DW      (3),
    .SWACCESS("RW"),
    .RESVAL  (3'h0)
  ) u_es_thresh (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (es_thresh_we),
    .wd     (es_thresh_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_thresh.q ),

    // to register interface (read)
    .qs     (es_thresh_qs)
  );


  // R[es_rate]: V(False)

  prim_subreg #(
    .DW      (16),
    .SWACCESS("RW"),
    .RESVAL  (16'h4)
  ) u_es_rate (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (es_rate_we),
    .wd     (es_rate_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_rate.q ),

    // to register interface (read)
    .qs     (es_rate_qs)
  );


  // R[es_seed]: V(False)

  prim_subreg #(
    .DW      (4),
    .SWACCESS("RW"),
    .RESVAL  (4'hb)
  ) u_es_seed (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface (qualified with register enable)
    .we     (es_seed_we & es_regen_qs),
    .wd     (es_seed_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.es_seed.q ),

    // to register interface (read)
    .qs     (es_seed_qs)
  );




  logic [13:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[ 0] = (reg_addr == ENTROPY_SRC_INTR_STATE_OFFSET);
    addr_hit[ 1] = (reg_addr == ENTROPY_SRC_INTR_ENABLE_OFFSET);
    addr_hit[ 2] = (reg_addr == ENTROPY_SRC_INTR_TEST_OFFSET);
    addr_hit[ 3] = (reg_addr == ENTROPY_SRC_ES_REGEN_OFFSET);
    addr_hit[ 4] = (reg_addr == ENTROPY_SRC_ES_REV_OFFSET);
    addr_hit[ 5] = (reg_addr == ENTROPY_SRC_ES_CONF_OFFSET);
    addr_hit[ 6] = (reg_addr == ENTROPY_SRC_ES_RCT_HEALTH_OFFSET);
    addr_hit[ 7] = (reg_addr == ENTROPY_SRC_ES_APT_HEALTH_OFFSET);
    addr_hit[ 8] = (reg_addr == ENTROPY_SRC_ES_ENTROPY_OFFSET);
    addr_hit[ 9] = (reg_addr == ENTROPY_SRC_ES_FIFO_STATUS_OFFSET);
    addr_hit[10] = (reg_addr == ENTROPY_SRC_ES_FDEPTHST_OFFSET);
    addr_hit[11] = (reg_addr == ENTROPY_SRC_ES_THRESH_OFFSET);
    addr_hit[12] = (reg_addr == ENTROPY_SRC_ES_RATE_OFFSET);
    addr_hit[13] = (reg_addr == ENTROPY_SRC_ES_SEED_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = 1'b0;
    if (addr_hit[ 0] && reg_we && (ENTROPY_SRC_PERMIT[ 0] != (ENTROPY_SRC_PERMIT[ 0] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 1] && reg_we && (ENTROPY_SRC_PERMIT[ 1] != (ENTROPY_SRC_PERMIT[ 1] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 2] && reg_we && (ENTROPY_SRC_PERMIT[ 2] != (ENTROPY_SRC_PERMIT[ 2] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 3] && reg_we && (ENTROPY_SRC_PERMIT[ 3] != (ENTROPY_SRC_PERMIT[ 3] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 4] && reg_we && (ENTROPY_SRC_PERMIT[ 4] != (ENTROPY_SRC_PERMIT[ 4] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 5] && reg_we && (ENTROPY_SRC_PERMIT[ 5] != (ENTROPY_SRC_PERMIT[ 5] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 6] && reg_we && (ENTROPY_SRC_PERMIT[ 6] != (ENTROPY_SRC_PERMIT[ 6] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 7] && reg_we && (ENTROPY_SRC_PERMIT[ 7] != (ENTROPY_SRC_PERMIT[ 7] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 8] && reg_we && (ENTROPY_SRC_PERMIT[ 8] != (ENTROPY_SRC_PERMIT[ 8] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[ 9] && reg_we && (ENTROPY_SRC_PERMIT[ 9] != (ENTROPY_SRC_PERMIT[ 9] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[10] && reg_we && (ENTROPY_SRC_PERMIT[10] != (ENTROPY_SRC_PERMIT[10] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[11] && reg_we && (ENTROPY_SRC_PERMIT[11] != (ENTROPY_SRC_PERMIT[11] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[12] && reg_we && (ENTROPY_SRC_PERMIT[12] != (ENTROPY_SRC_PERMIT[12] & reg_be))) wr_err = 1'b1 ;
    if (addr_hit[13] && reg_we && (ENTROPY_SRC_PERMIT[13] != (ENTROPY_SRC_PERMIT[13] & reg_be))) wr_err = 1'b1 ;
  end

  assign intr_state_es_entropy_valid_we = addr_hit[0] & reg_we & ~wr_err;
  assign intr_state_es_entropy_valid_wd = reg_wdata[0];

  assign intr_state_es_rct_failed_we = addr_hit[0] & reg_we & ~wr_err;
  assign intr_state_es_rct_failed_wd = reg_wdata[1];

  assign intr_state_es_apt_failed_we = addr_hit[0] & reg_we & ~wr_err;
  assign intr_state_es_apt_failed_wd = reg_wdata[2];

  assign intr_state_es_fifo_err_we = addr_hit[0] & reg_we & ~wr_err;
  assign intr_state_es_fifo_err_wd = reg_wdata[3];

  assign intr_enable_es_entropy_valid_we = addr_hit[1] & reg_we & ~wr_err;
  assign intr_enable_es_entropy_valid_wd = reg_wdata[0];

  assign intr_enable_es_rct_failed_we = addr_hit[1] & reg_we & ~wr_err;
  assign intr_enable_es_rct_failed_wd = reg_wdata[1];

  assign intr_enable_es_apt_failed_we = addr_hit[1] & reg_we & ~wr_err;
  assign intr_enable_es_apt_failed_wd = reg_wdata[2];

  assign intr_enable_es_fifo_err_we = addr_hit[1] & reg_we & ~wr_err;
  assign intr_enable_es_fifo_err_wd = reg_wdata[3];

  assign intr_test_es_entropy_valid_we = addr_hit[2] & reg_we & ~wr_err;
  assign intr_test_es_entropy_valid_wd = reg_wdata[0];

  assign intr_test_es_rct_failed_we = addr_hit[2] & reg_we & ~wr_err;
  assign intr_test_es_rct_failed_wd = reg_wdata[1];

  assign intr_test_es_apt_failed_we = addr_hit[2] & reg_we & ~wr_err;
  assign intr_test_es_apt_failed_wd = reg_wdata[2];

  assign intr_test_es_fifo_err_we = addr_hit[2] & reg_we & ~wr_err;
  assign intr_test_es_fifo_err_wd = reg_wdata[3];

  assign es_regen_we = addr_hit[3] & reg_we & ~wr_err;
  assign es_regen_wd = reg_wdata[0];




  assign es_conf_enable_we = addr_hit[5] & reg_we & ~wr_err;
  assign es_conf_enable_wd = reg_wdata[1:0];

  assign es_conf_rng_src_en_we = addr_hit[5] & reg_we & ~wr_err;
  assign es_conf_rng_src_en_wd = reg_wdata[4];

  assign es_conf_rct_en_we = addr_hit[5] & reg_we & ~wr_err;
  assign es_conf_rct_en_wd = reg_wdata[5];

  assign es_conf_apt_en_we = addr_hit[5] & reg_we & ~wr_err;
  assign es_conf_apt_en_wd = reg_wdata[6];

  assign es_conf_rng_bit_en_we = addr_hit[5] & reg_we & ~wr_err;
  assign es_conf_rng_bit_en_wd = reg_wdata[8];

  assign es_conf_rng_bit_sel_we = addr_hit[5] & reg_we & ~wr_err;
  assign es_conf_rng_bit_sel_wd = reg_wdata[10:9];

  assign es_rct_health_we = addr_hit[6] & reg_we & ~wr_err;
  assign es_rct_health_wd = reg_wdata[15:0];

  assign es_apt_health_apt_max_we = addr_hit[7] & reg_we & ~wr_err;
  assign es_apt_health_apt_max_wd = reg_wdata[15:0];

  assign es_apt_health_apt_win_we = addr_hit[7] & reg_we & ~wr_err;
  assign es_apt_health_apt_win_wd = reg_wdata[31:16];

  assign es_entropy_re = addr_hit[8] && reg_re;

  assign es_fifo_status_dig_src_depth_re = addr_hit[9] && reg_re;

  assign es_fifo_status_hwif_depth_re = addr_hit[9] && reg_re;

  assign es_fifo_status_es_depth_re = addr_hit[9] && reg_re;

  assign es_fifo_status_diag_re = addr_hit[9] && reg_re;

  assign es_fdepthst_re = addr_hit[10] && reg_re;

  assign es_thresh_we = addr_hit[11] & reg_we & ~wr_err;
  assign es_thresh_wd = reg_wdata[2:0];

  assign es_rate_we = addr_hit[12] & reg_we & ~wr_err;
  assign es_rate_wd = reg_wdata[15:0];

  assign es_seed_we = addr_hit[13] & reg_we & ~wr_err;
  assign es_seed_wd = reg_wdata[3:0];

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[0] = intr_state_es_entropy_valid_qs;
        reg_rdata_next[1] = intr_state_es_rct_failed_qs;
        reg_rdata_next[2] = intr_state_es_apt_failed_qs;
        reg_rdata_next[3] = intr_state_es_fifo_err_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[0] = intr_enable_es_entropy_valid_qs;
        reg_rdata_next[1] = intr_enable_es_rct_failed_qs;
        reg_rdata_next[2] = intr_enable_es_apt_failed_qs;
        reg_rdata_next[3] = intr_enable_es_fifo_err_qs;
      end

      addr_hit[2]: begin
        reg_rdata_next[0] = '0;
        reg_rdata_next[1] = '0;
        reg_rdata_next[2] = '0;
        reg_rdata_next[3] = '0;
      end

      addr_hit[3]: begin
        reg_rdata_next[0] = es_regen_qs;
      end

      addr_hit[4]: begin
        reg_rdata_next[7:0] = es_rev_abi_revision_qs;
        reg_rdata_next[15:8] = es_rev_hw_revision_qs;
        reg_rdata_next[23:16] = es_rev_chip_type_qs;
      end

      addr_hit[5]: begin
        reg_rdata_next[1:0] = es_conf_enable_qs;
        reg_rdata_next[4] = es_conf_rng_src_en_qs;
        reg_rdata_next[5] = es_conf_rct_en_qs;
        reg_rdata_next[6] = es_conf_apt_en_qs;
        reg_rdata_next[8] = es_conf_rng_bit_en_qs;
        reg_rdata_next[10:9] = es_conf_rng_bit_sel_qs;
      end

      addr_hit[6]: begin
        reg_rdata_next[15:0] = es_rct_health_qs;
      end

      addr_hit[7]: begin
        reg_rdata_next[15:0] = es_apt_health_apt_max_qs;
        reg_rdata_next[31:16] = es_apt_health_apt_win_qs;
      end

      addr_hit[8]: begin
        reg_rdata_next[31:0] = es_entropy_qs;
      end

      addr_hit[9]: begin
        reg_rdata_next[2:0] = es_fifo_status_dig_src_depth_qs;
        reg_rdata_next[6:4] = es_fifo_status_hwif_depth_qs;
        reg_rdata_next[16:12] = es_fifo_status_es_depth_qs;
        reg_rdata_next[31] = es_fifo_status_diag_qs;
      end

      addr_hit[10]: begin
        reg_rdata_next[2:0] = es_fdepthst_qs;
      end

      addr_hit[11]: begin
        reg_rdata_next[2:0] = es_thresh_qs;
      end

      addr_hit[12]: begin
        reg_rdata_next[15:0] = es_rate_qs;
      end

      addr_hit[13]: begin
        reg_rdata_next[3:0] = es_seed_qs;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Assertions for Register Interface
  `ASSERT_PULSE(wePulse, reg_we)
  `ASSERT_PULSE(rePulse, reg_re)

  `ASSERT(reAfterRv, $rose(reg_re || reg_we) |=> tl_o.d_valid)

  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

  // this is formulated as an assumption such that the FPV testbenches do disprove this
  // property by mistake
  `ASSUME(reqParity, tl_reg_h2d.a_valid |-> tl_reg_h2d.a_user.parity_en == 1'b0)

endmodule
