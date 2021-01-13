// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * OpenTitan Big Number Accelerator (OTBN)
 */
module otbn
  import prim_alert_pkg::*;
  import otbn_pkg::*;
  import otbn_reg_pkg::*;
#(
  parameter regfile_e             RegFile      = RegFileFF,
  parameter logic [NumAlerts-1:0] AlertAsyncOn = {NumAlerts{1'b1}}
) (
  input clk_i,
  input rst_ni,

  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,

  // Inter-module signals
  output logic idle_o,

  // Interrupts
  output logic intr_done_o,

  // Alerts
  input  prim_alert_pkg::alert_rx_t [NumAlerts-1:0] alert_rx_i,
  output prim_alert_pkg::alert_tx_t [NumAlerts-1:0] alert_tx_o

  // CSRNG interface
  // TODO: Needs to be connected to RNG distribution network (#2638)
);

  import prim_util_pkg::vbits;

  // The OTBN_*_SIZE parameters are auto-generated by regtool and come from the
  // bus window sizes; they are given in bytes and must be powers of two.
  localparam int ImemSizeByte = int'(otbn_reg_pkg::OTBN_IMEM_SIZE);
  localparam int DmemSizeByte = int'(otbn_reg_pkg::OTBN_DMEM_SIZE);

  localparam int ImemAddrWidth = vbits(ImemSizeByte);
  localparam int DmemAddrWidth = vbits(DmemSizeByte);

  `ASSERT_INIT(ImemSizePowerOfTwo, 2**ImemAddrWidth == ImemSizeByte)
  `ASSERT_INIT(DmemSizePowerOfTwo, 2**DmemAddrWidth == DmemSizeByte)

  logic start;
  logic busy_d, busy_q;
  logic done;

  err_bits_t err_bits;

  logic [ImemAddrWidth-1:0] start_addr;

  otbn_reg2hw_t reg2hw;
  otbn_hw2reg_t hw2reg;

  // Bus device windows, as specified in otbn.hjson
  typedef enum int {
    TlWinImem = 0,
    TlWinDmem = 1
  } tl_win_e;

  tlul_pkg::tl_h2d_t tl_win_h2d [2];
  tlul_pkg::tl_d2h_t tl_win_d2h [2];


  // Inter-module signals ======================================================

  // TODO: Better define what "idle" means -- only the core, or also the
  // register interface?
  assign idle_o = ~busy_q & ~start;


  // Interrupts ================================================================

  prim_intr_hw #(
    .Width(1)
  ) u_intr_hw_done (
    .clk_i,
    .rst_ni,
    .event_intr_i           (done),
    .reg2hw_intr_enable_q_i (reg2hw.intr_enable.q),
    .reg2hw_intr_test_q_i   (reg2hw.intr_test.q),
    .reg2hw_intr_test_qe_i  (reg2hw.intr_test.qe),
    .reg2hw_intr_state_q_i  (reg2hw.intr_state.q),
    .hw2reg_intr_state_de_o (hw2reg.intr_state.de),
    .hw2reg_intr_state_d_o  (hw2reg.intr_state.d),
    .intr_o                 (intr_done_o)
  );

  // Instruction Memory (IMEM) =================================================

  localparam int ImemSizeWords = ImemSizeByte / 4;
  localparam int ImemIndexWidth = vbits(ImemSizeWords);

  // Access select to IMEM: core (1), or bus (0)
  logic imem_access_core;

  logic imem_req;
  logic imem_write;
  logic [ImemIndexWidth-1:0] imem_index;
  logic [31:0] imem_wdata;
  logic [31:0] imem_wmask;
  logic [31:0] imem_rdata;
  logic imem_rvalid;
  logic [1:0] imem_rerror_vec;
  logic imem_rerror;

  logic imem_req_core;
  logic imem_write_core;
  logic [ImemIndexWidth-1:0] imem_index_core;
  logic [31:0] imem_wdata_core;
  logic [31:0] imem_rdata_core;
  logic imem_rvalid_core;
  logic imem_rerror_core;

  logic imem_req_bus;
  logic imem_write_bus;
  logic [ImemIndexWidth-1:0] imem_index_bus;
  logic [31:0] imem_wdata_bus;
  logic [31:0] imem_wmask_bus;
  logic [31:0] imem_rdata_bus;
  logic imem_rvalid_bus;
  logic [1:0] imem_rerror_bus;

  logic [ImemAddrWidth-1:0] imem_addr_core;
  assign imem_index_core = imem_addr_core[ImemAddrWidth-1:2];

  logic [1:0] unused_imem_addr_core_wordbits;
  assign unused_imem_addr_core_wordbits = imem_addr_core[1:0];

  prim_ram_1p_adv #(
    .Width           (32),
    .Depth           (ImemSizeWords),
    .DataBitsPerMask (32), // Write masks are not supported.
    .CfgW            (8)
  ) u_imem (
    .clk_i,
    .rst_ni,
    .req_i    (imem_req),
    .write_i  (imem_write),
    .addr_i   (imem_index),
    .wdata_i  (imem_wdata),
    .wmask_i  (imem_wmask),
    .rdata_o  (imem_rdata),
    .rvalid_o (imem_rvalid),
    .rerror_o (imem_rerror_vec),
    .cfg_i    ('0)
  );

  // imem_rerror_vec is 2 bits wide and is used to report ECC errors. Bit 1 is set if there's an
  // uncorrectable error and bit 0 is set if there's a correctable error. However, we're treating
  // all errors as fatal, so OR the two signals together.
  assign imem_rerror = |imem_rerror_vec;

  // IMEM access from main TL-UL bus
  logic imem_gnt_bus;
  assign imem_gnt_bus = imem_req_bus & ~imem_access_core;

  tlul_adapter_sram #(
    .SramAw      (ImemIndexWidth),
    .SramDw      (32),
    .Outstanding (1),
    .ByteAccess  (0),
    .ErrOnRead   (0)
  ) u_tlul_adapter_sram_imem (
    .clk_i,
    .rst_ni,
    .tl_i   (tl_win_h2d[TlWinImem]),
    .tl_o   (tl_win_d2h[TlWinImem]),

    .req_o    (imem_req_bus   ),
    .gnt_i    (imem_gnt_bus   ),
    .we_o     (imem_write_bus ),
    .addr_o   (imem_index_bus ),
    .wdata_o  (imem_wdata_bus ),
    .wmask_o  (imem_wmask_bus ),
    .rdata_i  (imem_rdata_bus ),
    .rvalid_i (imem_rvalid_bus),
    .rerror_i (imem_rerror_bus)
  );

  // Mux core and bus access into IMEM
  assign imem_access_core = busy_q | start;

  assign imem_req   = imem_access_core ? imem_req_core   : imem_req_bus;
  assign imem_write = imem_access_core ? imem_write_core : imem_write_bus;
  assign imem_index = imem_access_core ? imem_index_core : imem_index_bus;
  assign imem_wdata = imem_access_core ? imem_wdata_core : imem_wdata_bus;

  // The instruction memory only supports 32b word writes, so we hardcode its
  // wmask here.
  //
  // Since this could cause confusion if the bus tried to do a partial write
  // (which wasn't caught in the TLUL adapter for some reason), we assert that
  // the wmask signal from the bus is indeed '1 when it requests a write. We
  // don't have the corresponding check for writes from the core because the
  // core cannot perform writes (and has no imem_wmask_o port).
  assign imem_wmask = 32'hFFFFFFFF;
  `ASSERT(ImemWmaskBusIsFullWord_A,
      imem_req_bus && imem_write_bus |-> imem_wmask_bus == 32'hFFFFFFFF)

  // Explicitly tie off bus interface during core operation to avoid leaking
  // the currently executed instruction from IMEM through the bus
  // unintentionally.
  assign imem_rdata_bus  = !imem_access_core ? imem_rdata : 32'b0;
  assign imem_rdata_core = imem_rdata;

  assign imem_rvalid_bus  = !imem_access_core ? imem_rvalid : 1'b0;
  assign imem_rvalid_core = imem_access_core ? imem_rvalid : 1'b0;

  // imem_rerror_bus is passed to a TLUL adapter to report read errors back to the TL interface.
  // We've squashed together the 2 bits from ECC into a single (uncorrectable) error, but the TLUL
  // adapter expects the original ECC format. Send imem_rerror as bit 1, signalling an uncorrectable
  // error.
  //
  // The mux ensures that imem_rerror doesn't appear on the bus (possibly leaking information) when
  // the core is operating. Since rerror depends on rvalid, we could avoid this mux. However that
  // seems a bit fragile, so we err on the side of caution.
  assign imem_rerror_bus  = !imem_access_core ? {imem_rerror, 1'b0} : 2'b00;
  assign imem_rerror_core = imem_rerror;


  // Data Memory (DMEM) ========================================================

  localparam int DmemSizeWords = DmemSizeByte / (WLEN / 8);
  localparam int DmemIndexWidth = vbits(DmemSizeWords);

  // Access select to DMEM: core (1), or bus (0)
  logic dmem_access_core;

  logic dmem_req;
  logic dmem_write;
  logic [DmemIndexWidth-1:0] dmem_index;
  logic [WLEN-1:0] dmem_wdata;
  logic [WLEN-1:0] dmem_wmask;
  logic [WLEN-1:0] dmem_rdata;
  logic dmem_rvalid;
  logic [1:0] dmem_rerror_vec;
  logic dmem_rerror;

  logic dmem_req_core;
  logic dmem_write_core;
  logic [DmemIndexWidth-1:0] dmem_index_core;
  logic [WLEN-1:0] dmem_wdata_core;
  logic [WLEN-1:0] dmem_wmask_core;
  logic [WLEN-1:0] dmem_rdata_core;
  logic dmem_rvalid_core;
  logic dmem_rerror_core;

  logic dmem_req_bus;
  logic dmem_write_bus;
  logic [DmemIndexWidth-1:0] dmem_index_bus;
  logic [WLEN-1:0] dmem_wdata_bus;
  logic [WLEN-1:0] dmem_wmask_bus;
  logic [WLEN-1:0] dmem_rdata_bus;
  logic dmem_rvalid_bus;
  logic [1:0] dmem_rerror_bus;

  logic [DmemAddrWidth-1:0] dmem_addr_core;
  assign dmem_index_core = dmem_addr_core[DmemAddrWidth-1:DmemAddrWidth-DmemIndexWidth];

  logic unused_dmem_addr_core_wordbits;
  assign unused_dmem_addr_core_wordbits = ^dmem_addr_core[DmemAddrWidth-DmemIndexWidth-1:0];

  prim_ram_1p_adv #(
    .Width           (WLEN),
    .Depth           (DmemSizeWords),
    .DataBitsPerMask (32), // 32b write masks for 32b word writes from bus
    .CfgW            (8)
  ) u_dmem (
    .clk_i,
    .rst_ni,
    .req_i    (dmem_req),
    .write_i  (dmem_write),
    .addr_i   (dmem_index),
    .wdata_i  (dmem_wdata),
    .wmask_i  (dmem_wmask),
    .rdata_o  (dmem_rdata),
    .rvalid_o (dmem_rvalid),
    .rerror_o (dmem_rerror_vec),
    .cfg_i    ('0)
  );

  // Combine uncorrectable / correctable errors. See note above definition of imem_rerror for
  // details.
  assign dmem_rerror = |dmem_rerror_vec;

  // DMEM access from main TL-UL bus
  logic dmem_gnt_bus;
  assign dmem_gnt_bus = dmem_req_bus & ~dmem_access_core;

  tlul_adapter_sram #(
    .SramAw      (DmemIndexWidth),
    .SramDw      (WLEN),
    .Outstanding (1),
    .ByteAccess  (0),
    .ErrOnRead   (0)
  ) u_tlul_adapter_sram_dmem (
    .clk_i,
    .rst_ni,

    .tl_i     (tl_win_h2d[TlWinDmem]),
    .tl_o     (tl_win_d2h[TlWinDmem]),

    .req_o    (dmem_req_bus   ),
    .gnt_i    (dmem_gnt_bus   ),
    .we_o     (dmem_write_bus ),
    .addr_o   (dmem_index_bus ),
    .wdata_o  (dmem_wdata_bus ),
    .wmask_o  (dmem_wmask_bus ),
    .rdata_i  (dmem_rdata_bus ),
    .rvalid_i (dmem_rvalid_bus),
    .rerror_i (dmem_rerror_bus)
  );

  // Mux core and bus access into dmem
  assign dmem_access_core = busy_q;

  assign dmem_req   = dmem_access_core ? dmem_req_core   : dmem_req_bus;
  assign dmem_write = dmem_access_core ? dmem_write_core : dmem_write_bus;
  assign dmem_wmask = dmem_access_core ? dmem_wmask_core : dmem_wmask_bus;
  assign dmem_index = dmem_access_core ? dmem_index_core : dmem_index_bus;
  assign dmem_wdata = dmem_access_core ? dmem_wdata_core : dmem_wdata_bus;

  // Explicitly tie off bus interface during core operation to avoid leaking
  // DMEM data through the bus unintentionally.
  assign dmem_rdata_bus  = !dmem_access_core ? dmem_rdata : '0;
  assign dmem_rdata_core = dmem_rdata;

  assign dmem_rvalid_bus  = !dmem_access_core ? dmem_rvalid : 1'b0;
  assign dmem_rvalid_core = dmem_access_core  ? dmem_rvalid : 1'b0;

  // Expand the error signal to 2 bits and mask when the core has access. See note above
  // imem_rerror_bus for details.
  assign dmem_rerror_bus  = !dmem_access_core ? {dmem_rerror, 1'b0} : 2'b00;
  assign dmem_rerror_core = dmem_rerror;


  // Registers =================================================================

  otbn_reg_top u_reg (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .tl_win_o (tl_win_h2d),
    .tl_win_i (tl_win_d2h),

    .reg2hw,
    .hw2reg,

    .devmode_i (1'b1)
  );

  // CMD register
  assign start = reg2hw.cmd.start.qe & reg2hw.cmd.start.q;

  // STATUS register
  assign hw2reg.status.busy.d = busy_q;
  assign hw2reg.status.dummy.d = 1'b0;

  // ERR_BITS register
  // The error bits for an OTBN operation get stored on the cycle that done is
  // asserted. Software is expected to read them out before starting the next operation.
  assign hw2reg.err_bits.bad_data_addr.de = done;
  assign hw2reg.err_bits.bad_data_addr.d = err_bits.bad_data_addr;

  assign hw2reg.err_bits.bad_insn_addr.de = done;
  assign hw2reg.err_bits.bad_insn_addr.d = err_bits.bad_insn_addr;

  assign hw2reg.err_bits.call_stack.de = done;
  assign hw2reg.err_bits.call_stack.d = err_bits.call_stack;

  assign hw2reg.err_bits.illegal_insn.de = done;
  assign hw2reg.err_bits.illegal_insn.d = err_bits.illegal_insn;

  assign hw2reg.err_bits.loop.de = done;
  assign hw2reg.err_bits.loop.d = err_bits.loop;

  assign hw2reg.err_bits.fatal_imem.de = done;
  assign hw2reg.err_bits.fatal_imem.d = err_bits.fatal_imem;

  assign hw2reg.err_bits.fatal_dmem.de = done;
  assign hw2reg.err_bits.fatal_dmem.d = err_bits.fatal_dmem;

  assign hw2reg.err_bits.fatal_reg.de = done;
  assign hw2reg.err_bits.fatal_reg.d = err_bits.fatal_reg;

  // START_ADDR register
  assign start_addr = reg2hw.start_addr.q[ImemAddrWidth-1:0];

  // FATAL_ALERT_CAUSE register. The .de and .d values are equal for each bit, so that it can only
  // be set, not cleared.
  assign hw2reg.fatal_alert_cause.imem_error.de = imem_rerror;
  assign hw2reg.fatal_alert_cause.imem_error.d  = imem_rerror;
  assign hw2reg.fatal_alert_cause.dmem_error.de = dmem_rerror;
  assign hw2reg.fatal_alert_cause.dmem_error.d  = dmem_rerror;
  // TODO: Register file errors
  assign hw2reg.fatal_alert_cause.reg_error.de = 0;
  assign hw2reg.fatal_alert_cause.reg_error.d  = 0;

  // Alerts ====================================================================

  logic [NumAlerts-1:0] alert_test;
  assign alert_test[AlertFatal] = reg2hw.alert_test.fatal.q &
                                  reg2hw.alert_test.fatal.qe;
  assign alert_test[AlertRecov] = reg2hw.alert_test.recov.q &
                                  reg2hw.alert_test.recov.qe;

  logic [NumAlerts-1:0] alerts;
  assign alerts[AlertFatal] = imem_rerror | dmem_rerror;
  assign alerts[AlertRecov] = 1'b0; // TODO: Implement

  for (genvar i = 0; i < NumAlerts; i++) begin: gen_alert_tx
    prim_alert_sender #(
      .AsyncOn(AlertAsyncOn[i]),
      .IsFatal(i == AlertFatal)
    ) u_prim_alert_sender (
      .clk_i,
      .rst_ni,
      .alert_test_i  ( alert_test[i] ),
      .alert_req_i   ( alerts[i]     ),
      .alert_ack_o   (               ),
      .alert_state_o (               ),
      .alert_rx_i    ( alert_rx_i[i] ),
      .alert_tx_o    ( alert_tx_o[i] )
    );
  end


  // OTBN Core =================================================================

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      busy_q <= 1'b0;
    end else begin
      busy_q <= busy_d;
    end
  end
  assign busy_d = (busy_q | start) & ~done;

  `ifdef OTBN_BUILD_MODEL
    // Build both model and RTL implementation into the design, and switch at runtime through a
    // plusarg.

    // Set the plusarg +OTBN_USE_MODEL=1 to use the model (ISS) instead of the RTL implementation.
    bit otbn_use_model;
    initial begin
      $value$plusargs("OTBN_USE_MODEL=%d", otbn_use_model);
    end

    // Mux between model and RTL implementation at runtime.
    logic      done_model, done_rtl;
    logic      start_model, start_rtl;
    err_bits_t err_bits_model, err_bits_rtl;

    assign done = otbn_use_model ? done_model : done_rtl;
    assign err_bits = otbn_use_model ? err_bits_model : err_bits_rtl;
    assign start_model = start & otbn_use_model;
    assign start_rtl = start & ~otbn_use_model;

    // Model (Instruction Set Simulation)
    localparam string ImemScope = "..u_imem.u_mem.gen_generic.u_impl_generic";
    localparam string DmemScope = "..u_dmem.u_mem.gen_generic.u_impl_generic";

    otbn_core_model #(
      .DmemSizeByte(DmemSizeByte),
      .ImemSizeByte(ImemSizeByte),
      .DmemScope(DmemScope),
      .ImemScope(ImemScope),
      .DesignScope("")
    ) u_otbn_core_model (
      .clk_i,
      .rst_ni,

      .enable_i (otbn_use_model),

      .start_i (start_model),
      .done_o (done_model),

      .err_bits_o (err_bits_model),

      .start_addr_i (start_addr),

      .err_o ()
    );

    // RTL implementation
    otbn_core #(
      .RegFile(RegFile),
      .DmemSizeByte(DmemSizeByte),
      .ImemSizeByte(ImemSizeByte)
    ) u_otbn_core (
      .clk_i,
      .rst_ni,

      .start_i (start_rtl),
      .done_o  (done_rtl),

      .err_bits_o (err_bits_rtl),

      .start_addr_i  (start_addr),

      .imem_req_o    (imem_req_core),
      .imem_addr_o   (imem_addr_core),
      .imem_wdata_o  (imem_wdata_core),
      .imem_rdata_i  (imem_rdata_core),
      .imem_rvalid_i (imem_rvalid_core),
      .imem_rerror_i (imem_rerror_core),

      .dmem_req_o    (dmem_req_core),
      .dmem_write_o  (dmem_write_core),
      .dmem_addr_o   (dmem_addr_core),
      .dmem_wdata_o  (dmem_wdata_core),
      .dmem_wmask_o  (dmem_wmask_core),
      .dmem_rdata_i  (dmem_rdata_core),
      .dmem_rvalid_i (dmem_rvalid_core),
      .dmem_rerror_i (dmem_rerror_core)
    );
  `else
    otbn_core #(
      .RegFile(RegFile),
      .DmemSizeByte(DmemSizeByte),
      .ImemSizeByte(ImemSizeByte)
    ) u_otbn_core (
      .clk_i,
      .rst_ni,

      .start_i (start),
      .done_o  (done),

      .err_bits_o (err_bits),

      .start_addr_i  (start_addr),

      .imem_req_o    (imem_req_core),
      .imem_addr_o   (imem_addr_core),
      .imem_wdata_o  (imem_wdata_core),
      .imem_rdata_i  (imem_rdata_core),
      .imem_rvalid_i (imem_rvalid_core),
      .imem_rerror_i (imem_rerror_core),

      .dmem_req_o    (dmem_req_core),
      .dmem_write_o  (dmem_write_core),
      .dmem_addr_o   (dmem_addr_core),
      .dmem_wdata_o  (dmem_wdata_core),
      .dmem_wmask_o  (dmem_wmask_core),
      .dmem_rdata_i  (dmem_rdata_core),
      .dmem_rvalid_i (dmem_rvalid_core),
      .dmem_rerror_i (dmem_rerror_core)
    );
  `endif

  // The core can never signal a write to IMEM
  assign imem_write_core = 1'b0;

  // LFSR ======================================================================

  // TODO: Potentially insert local LFSR, or use output from RNG distribution
  // network directly, depending on availability. Revisit once CSRNG interface
  // is known (#2638).


  // Asserts ===================================================================

  // All outputs should be known value after reset
  `ASSERT_KNOWN(TlODValidKnown_A, tl_o.d_valid)
  `ASSERT_KNOWN(TlOAReadyKnown_A, tl_o.a_ready)
  `ASSERT_KNOWN(IntrDoneOKnown_A, intr_done_o)
  `ASSERT_KNOWN(AlertTxOKnown_A, alert_tx_o)
  `ASSERT_KNOWN(IdleOKnown_A, idle_o)

endmodule
