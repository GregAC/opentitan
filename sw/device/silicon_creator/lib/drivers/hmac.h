// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_HMAC_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_HMAC_H_

#include <stddef.h>
#include <stdint.h>

#include "sw/device/lib/base/mmio.h"
#include "sw/device/silicon_creator/lib/error.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialization parameters for HMAC.
 */
typedef struct hmac {
  /**
   * The base address for the HMAC hardware registers.
   */
  mmio_region_t base_addr;
} hmac_t;

/**
 * A typed representation of the HMAC digest.
 */
typedef struct hmac_digest {
  uint32_t digest[8];
} hmac_digest_t;

/**
 * Initializes the HMAC in SHA256 mode.
 *
 * This function resets the HMAC module to clear the digest register.
 * It then configures the HMAC block in SHA256 mode with little endian
 * data input and digest output.
 *
 * @param hmac A HMAC handle.
 * @return The result of the operation.
 */
rom_error_t hmac_sha256_init(const hmac_t *hmac);

/**
 * Sends `len` bytes from `data` to the SHA2-256 function.
 *
 * This function does not check for the size of the available HMAC
 * FIFO. Since the this function is meant to run in blocking mode,
 * polling for FIFO status is equivalent to stalling on FIFO write.
 *
 * @param hmac A HMAC handle
 * @param data Buffer to copy data from.
 * @param len size of the `data` buffer.
 * @return The result of the operation.
 */
rom_error_t hmac_sha256_update(const hmac_t *hmac, const void *data,
                               size_t len);

/**
 * Finalizes SHA256 operation and writes `digest` buffer.
 *
 * @param hmac A HMAC handle.
 * @param[out] digest Buffer to copy digest to.
 * @return The result of the operation.
 */
rom_error_t hmac_sha256_final(const hmac_t *hmac, hmac_digest_t *digest);

#ifdef __cplusplus
}
#endif

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_HMAC_H_
