// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module otbn_top_sim (
  input IO_CLK,
  input IO_RST_N
);
  import otbn_pkg::*;

  // Size of the instruction memory, in bytes
  parameter int ImemSizeByte = otbn_reg_pkg::OTBN_IMEM_SIZE;
  // Size of the data memory, in bytes
  parameter int DmemSizeByte = otbn_reg_pkg::OTBN_DMEM_SIZE;
  // Start address of first instruction in IMem
  parameter int ImemStartAddr = 32'h0;
  // Include the model. If included checks are run to compare model and RTL behaviour
  parameter bit UseModel = 1'b1;

  localparam int ImemAddrWidth = prim_util_pkg::vbits(ImemSizeByte);
  localparam int DmemAddrWidth = prim_util_pkg::vbits(DmemSizeByte);

  logic otbn_done;
  logic otbn_start;
  logic otbn_start_done;

  // Instruction memory (IMEM) signals
  logic                     imem_req;
  logic [ImemAddrWidth-1:0] imem_addr;
  logic [31:0]              imem_rdata;
  logic                     imem_rvalid;
  logic [1:0]               imem_rerror;

  // Data memory (DMEM) signals
  logic                     dmem_req;
  logic                     dmem_write;
  logic [DmemAddrWidth-1:0] dmem_addr;
  logic [WLEN-1:0]          dmem_wdata;
  logic [WLEN-1:0]          dmem_wmask;
  logic [WLEN-1:0]          dmem_rdata;
  logic                     dmem_rvalid;
  logic [1:0]               dmem_rerror;


  otbn_core #(
    .ImemSizeByte ( ImemSizeByte ),
    .DmemSizeByte ( DmemSizeByte )
  ) u_otbn_core (
    .clk_i         ( IO_CLK        ),
    .rst_ni        ( IO_RST_N      ),

    .start_i       ( otbn_start    ),
    .done_o        ( otbn_done     ),

    .start_addr_i  ( ImemStartAddr ),

    .imem_req_o    ( imem_req      ),
    .imem_addr_o   ( imem_addr     ),
    .imem_wdata_o  (               ),
    .imem_rdata_i  ( imem_rdata    ),
    .imem_rvalid_i ( imem_rvalid   ),
    .imem_rerror_i ( imem_rerror   ),

    .dmem_req_o    ( dmem_req      ),
    .dmem_write_o  ( dmem_write    ),
    .dmem_addr_o   ( dmem_addr     ),
    .dmem_wdata_o  ( dmem_wdata    ),
    .dmem_wmask_o  ( dmem_wmask    ),
    .dmem_rdata_i  ( dmem_rdata    ),
    .dmem_rvalid_i ( dmem_rvalid   ),
    .dmem_rerror_i ( dmem_rerror   )
  );

  // Pulse otbn_start for 1 cycle immediately out of reset
  always @(posedge IO_CLK or negedge IO_RST_N) begin
    if(!IO_RST_N) begin
      otbn_start      <= 1'b0;
      otbn_start_done <= 1'b0;
    end else begin
      if (!otbn_start_done) begin
        otbn_start      <= 1'b1;
        otbn_start_done <= 1'b1;
      end else if (otbn_start) begin
        otbn_start <= 1'b0;
      end
    end
  end

  localparam int DmemSizeWords = DmemSizeByte / (WLEN / 8);
  localparam int DmemIndexWidth = prim_util_pkg::vbits(DmemSizeWords);

  logic [DmemIndexWidth-1:0] dmem_index;
  logic [DmemAddrWidth-DmemIndexWidth-1:0] unused_dmem_addr;

  assign dmem_index = dmem_addr[DmemAddrWidth-1:DmemAddrWidth-DmemIndexWidth];
  assign unused_dmem_addr = dmem_addr[DmemAddrWidth-DmemIndexWidth-1:0];

  prim_ram_1p_adv #(
    .Width           ( WLEN          ),
    .Depth           ( DmemSizeWords ),
    .DataBitsPerMask ( 32            ),
    .CfgW            ( 8             )
  ) u_dmem (
    .clk_i    ( IO_CLK      ),
    .rst_ni   ( IO_RST_N    ),
    .req_i    ( dmem_req    ),
    .write_i  ( dmem_write  ),
    .addr_i   ( dmem_index  ),
    .wdata_i  ( dmem_wdata  ),
    .wmask_i  ( dmem_wmask  ),
    .rdata_o  ( dmem_rdata  ),
    .rvalid_o ( dmem_rvalid ),
    .rerror_o ( dmem_rerror ),
    .cfg_i    ( '0          )
  );

  localparam int ImemSizeWords = ImemSizeByte / 4;
  localparam int ImemIndexWidth = prim_util_pkg::vbits(ImemSizeWords);

  logic [ImemIndexWidth-1:0] imem_index;
  logic [1:0] unused_imem_addr;

  assign imem_index = imem_addr[ImemAddrWidth-1:2];
  assign unused_imem_addr = imem_addr[1:0];

  prim_ram_1p_adv #(
    .Width           ( 32            ),
    .Depth           ( ImemSizeWords ),
    .DataBitsPerMask ( 32            ),
    .CfgW            ( 8             )
  ) u_imem (
    .clk_i    ( IO_CLK      ),
    .rst_ni   ( IO_RST_N    ),
    .req_i    ( imem_req    ),
    .write_i  ( 1'b0        ),
    .addr_i   ( imem_index  ),
    .wdata_i  ( '0          ),
    .wmask_i  ( '0          ),
    .rdata_o  ( imem_rdata  ),
    .rvalid_o ( imem_rvalid ),
    .rerror_o ( imem_rerror ),
    .cfg_i    ( '0          )
  );


  // When OTBN is done let a few more cycles run then finish simulation
  logic [1:0] finish_counter;

  always @(posedge IO_CLK or negedge IO_RST_N) begin
    if (!IO_RST_N) begin
      finish_counter <= 2'd0;
    end else begin
      if (otbn_done) begin
        finish_counter <= 2'd1;
      end

      if (finish_counter != 0) begin
        finish_counter <= finish_counter + 2'd1;
      end

      if (finish_counter == 2'd3) begin
        $finish;
      end
    end
  end

  if (UseModel) begin : g_model
    // The model
    //
    // This runs in parallel with the real core above. Eventually, we'll have strong consistency
    // checks between the two. For now, we just check that they have the same "done" signals.

    localparam string ImemScope = "...u_imem.u_mem.gen_generic.u_impl_generic";
    localparam string DmemScope = "...u_dmem.u_mem.gen_generic.u_impl_generic";
    localparam string DesignScope = "...u_otbn_core";

    logic otbn_model_done;
    bit   otbn_model_err;

    otbn_core_model #(
      .DmemSizeByte    ( DmemSizeByte ),
      .ImemSizeByte    ( ImemSizeByte ),
      .DmemScope       ( DmemScope ),
      .ImemScope       ( ImemScope ),
      .DesignScope     ( DesignScope )
    ) u_otbn_core_model (
      .clk_i        ( IO_CLK ),
      .rst_ni       ( IO_RST_N ),

      .start_i      ( otbn_start ),
      .done_o       ( otbn_model_done ),

      .start_addr_i ( ImemStartAddr ),

      .err_o        ( otbn_model_err )
    );

    bit done_mismatch_latched;
    bit model_err_latched;

    always_ff @(posedge IO_CLK or negedge IO_RST_N) begin
      if (!IO_RST_N) begin
        done_mismatch_latched <= 1'b0;
        model_err_latched     <= 1'b0;
      end else begin
        if (otbn_done != otbn_model_done) begin
          $display("ERROR: At time %0t, otbn_done != otbn_model_done (%0d != %0d).",
                   $time, otbn_done, otbn_model_done);
          done_mismatch_latched <= 1'b1;
        end
        model_err_latched <= model_err_latched | otbn_model_err;
      end
    end

    export "DPI-C" function otbn_err_get;

    function automatic bit otbn_err_get();
      return model_err_latched | done_mismatch_latched;
    endfunction
  end else begin : g_no_model
    export "DPI-C" function otbn_err_get;

    function automatic bit otbn_err_get();
      return 0;
    endfunction
  end


  export "DPI-C" function otbn_base_reg_get;

  function automatic int unsigned otbn_base_reg_get(int index);
    return u_otbn_core.gen_rf_base_ff.u_otbn_rf_base.rf_reg[index];
  endfunction

  export "DPI-C" function otbn_bignum_reg_get;

  function automatic int unsigned otbn_bignum_reg_get(int index, int word);
    return u_otbn_core.gen_rf_bignum_ff.u_otbn_rf_bignum.rf[index][word*32+:32];
  endfunction


endmodule
