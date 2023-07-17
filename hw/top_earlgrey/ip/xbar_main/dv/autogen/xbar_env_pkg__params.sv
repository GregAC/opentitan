// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// xbar_env_pkg__params generated by `tlgen.py` tool


// List of Xbar device memory map
tl_device_t xbar_devices[$] = '{
    '{"rv_dm__regs", '{
        '{32'h41200000, 32'h41200003}
    }},
    '{"rv_dm__mem", '{
        '{32'h00010000, 32'h00010fff}
    }},
    '{"rom_ctrl__rom", '{
        '{32'h00008000, 32'h0000ffff}
    }},
    '{"rom_ctrl__regs", '{
        '{32'h411e0000, 32'h411e007f}
    }},
    '{"peri", '{
        '{32'h40000000, 32'h401fffff},
        '{32'h40400000, 32'h407fffff}
    }},
    '{"spi_host0", '{
        '{32'h40300000, 32'h4030003f}
    }},
    '{"spi_host1", '{
        '{32'h40310000, 32'h4031003f}
    }},
    '{"usbdev", '{
        '{32'h40320000, 32'h40320fff}
    }},
    '{"flash_ctrl__core", '{
        '{32'h41000000, 32'h410001ff}
    }},
    '{"flash_ctrl__prim", '{
        '{32'h41008000, 32'h4100807f}
    }},
    '{"flash_ctrl__mem", '{
        '{32'h20000000, 32'h200fffff}
    }},
    '{"hmac", '{
        '{32'h41110000, 32'h41110fff}
    }},
    '{"kmac", '{
        '{32'h41120000, 32'h41120fff}
    }},
    '{"aes", '{
        '{32'h41100000, 32'h411000ff}
    }},
    '{"entropy_src", '{
        '{32'h41160000, 32'h411600ff}
    }},
    '{"csrng", '{
        '{32'h41150000, 32'h4115007f}
    }},
    '{"edn0", '{
        '{32'h41170000, 32'h4117007f}
    }},
    '{"edn1", '{
        '{32'h41180000, 32'h4118007f}
    }},
    '{"rv_plic", '{
        '{32'h48000000, 32'h4fffffff}
    }},
    '{"otbn", '{
        '{32'h41130000, 32'h4113ffff}
    }},
    '{"keymgr", '{
        '{32'h41140000, 32'h411400ff}
    }},
    '{"rv_core_ibex__cfg", '{
        '{32'h411f0000, 32'h411f07ff}
    }},
    '{"sram_ctrl_main__regs", '{
        '{32'h411c0000, 32'h411c001f}
    }},
    '{"sram_ctrl_main__ram", '{
        '{32'h10000000, 32'h1001ffff}
}}};

  // List of Xbar hosts
tl_host_t xbar_hosts[$] = '{
    '{"rv_core_ibex__corei", 0, '{
        "rom_ctrl__rom",
        "rv_dm__mem",
        "sram_ctrl_main__ram",
        "flash_ctrl__mem"}}
    ,
    '{"rv_core_ibex__cored", 1, '{
        "rom_ctrl__rom",
        "rom_ctrl__regs",
        "rv_dm__mem",
        "rv_dm__regs",
        "sram_ctrl_main__ram",
        "peri",
        "spi_host0",
        "spi_host1",
        "usbdev",
        "flash_ctrl__core",
        "flash_ctrl__prim",
        "flash_ctrl__mem",
        "aes",
        "entropy_src",
        "csrng",
        "edn0",
        "edn1",
        "hmac",
        "rv_plic",
        "otbn",
        "keymgr",
        "kmac",
        "sram_ctrl_main__regs",
        "rv_core_ibex__cfg"}}
    ,
    '{"rv_dm__sba", 2, '{
        "rom_ctrl__rom",
        "rom_ctrl__regs",
        "rv_dm__mem",
        "rv_dm__regs",
        "sram_ctrl_main__ram",
        "peri",
        "spi_host0",
        "spi_host1",
        "usbdev",
        "flash_ctrl__core",
        "flash_ctrl__prim",
        "flash_ctrl__mem",
        "aes",
        "entropy_src",
        "csrng",
        "edn0",
        "edn1",
        "hmac",
        "rv_plic",
        "otbn",
        "keymgr",
        "kmac",
        "sram_ctrl_main__regs",
        "rv_core_ibex__cfg"}}
};
