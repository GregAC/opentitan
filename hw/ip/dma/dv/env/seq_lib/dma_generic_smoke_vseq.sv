// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/*
  DMA Smoke - Generic DMA Operation
    - Generic operation through Mailbox initiated via FW
    - FW parses CMD object in Mailbox
    - FW sanitizes the said Object
    - FW allocates DMA enabled Memory Space for the data movement
    - FW configures Source Address and ASID
    - FW configures Destination Address and ASID
    - FW completes other configuration such as:
        i)    Operation Size
        ii)   Opcode
    - FW triggers the DMA operation
    - FW either
        i)    Poll for completion
        ii)   Waits for Completion Interrupt
    - Reset memory contents at the end of iteration
*/

class dma_generic_smoke_vseq extends dma_base_vseq;
  rand int num_txns;

  `uvm_object_utils(dma_generic_smoke_vseq)
  `uvm_object_new

  constraint transactions_c {num_txns == valid_combinations.size();}

  typedef struct {
    dma_address_space_id_t src_id;
    dma_address_space_id_t dst_id;
  } valid_space_id_t;

  valid_space_id_t valid_combinations[$] = '{
      '{OtInternalAddr, SocControlAddr},
      '{OtInternalAddr, SocControlAddr},
      // TODO remove once SYS support is enabled'{OtInternalAddr, SocSystemAddr},
      '{OtInternalAddr, OtExtFlashAddr},
      '{SocControlAddr, OtInternalAddr},
      '{SocControlAddr, OtInternalAddr},
      // TODO remove once SYS support is enabled '{SocSystemAddr, OtInternalAddr},
      '{OtExtFlashAddr, OtInternalAddr},
      '{OtInternalAddr,OtInternalAddr}
  };

  // Function : Rerandomization of address ranges
  function void randomize_item(ref dma_seq_item dma_config, input int iteration = 0);
    int num_valid_combinations = valid_combinations.size();
    int index = $urandom_range(0, num_valid_combinations);
    valid_space_id_t valid_combination = valid_combinations.pop_front();
    if (iteration > 0) begin
      // Disable DMA memory region base and limit randomization
      dma_config.lock_memory_range();
    end
    `DV_CHECK_RANDOMIZE_WITH_FATAL(
      dma_config,
      valid_dma_config == 1; // Allow only random configurations
      m_src_asid == valid_combination.src_id;
      m_dst_asid == valid_combination.dst_id;
      m_opcode == DmaOperCopy;)
    `uvm_info(`gfn, $sformatf("DMA: Randomized a new transaction\n %s",
                              dma_config.sprint()), UVM_HIGH)
  endfunction

  virtual task body();
    `uvm_info(`gfn, "DMA: Starting Generic smoke Sequence", UVM_LOW)
    valid_combinations.shuffle();
    super.body();

    `uvm_info(`gfn, $sformatf("DMA: Running %d DMA Sequences", num_txns), UVM_LOW)

    for (int i = 0; i < num_txns; i++) begin
      `uvm_info(`gfn, $sformatf("DMA: Started Sequence #%0d", i), UVM_LOW)
      randomize_item(dma_config, i);
      run_common_config(dma_config);
      set_control_register(dma_config.opcode, // OPCODE
                           dma_config.handshake, // Handshake Enable
                           dma_config.auto_inc_buffer, // Auto-increment Buffer Address
                           dma_config.auto_inc_fifo, // Auto-increment FIFO Address
                           dma_config.direction, // Direction
                           1'b1); // Go
      poll_status();
      clear();
      delay(10);
      // TODO: reset design to unlock DMA enabled momory range registers
      // Clear memory contents
      `uvm_info(`gfn, $sformatf("Clearing memory contents"), UVM_MEDIUM)
      cfg.mem_host.init();
      cfg.mem_ctn.init();
      cfg.mem_sys.init();
      `uvm_info(`gfn, $sformatf("DMA: Completed Sequence #%d", i), UVM_LOW)
    end

    `uvm_info(`gfn, "DMA: Completed Smoke Sequence", UVM_LOW)
  endtask : body
endclass
