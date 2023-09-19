// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_LIB_DIF_AUTOGEN_DIF_MBX_AUTOGEN_H_
#define OPENTITAN_SW_DEVICE_LIB_DIF_AUTOGEN_DIF_MBX_AUTOGEN_H_

// THIS FILE HAS BEEN GENERATED, DO NOT EDIT MANUALLY. COMMAND:
// util/make_new_dif.py --mode=regen --only=autogen

/**
 * @file
 * @brief <a href="/book/hw/ip/mbx/">MBX</a> Device Interface Functions
 */

#include <stdbool.h>
#include <stdint.h>

#include "sw/device/lib/base/macros.h"
#include "sw/device/lib/base/mmio.h"
#include "sw/device/lib/dif/dif_base.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

/**
 * A handle to mbx.
 *
 * This type should be treated as opaque by users.
 */
typedef struct dif_mbx {
  /**
   * The base address for the mbx hardware registers.
   */
  mmio_region_t base_addr;
} dif_mbx_t;

/**
 * Creates a new handle for a(n) mbx peripheral.
 *
 * This function does not actuate the hardware.
 *
 * @param base_addr The MMIO base address of the mbx peripheral.
 * @param[out] mbx Out param for the initialized handle.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_init(mmio_region_t base_addr, dif_mbx_t *mbx);

/**
 * A mbx alert type.
 */
typedef enum dif_mbx_alert {
  /**
   * This fatal alert is triggered when a fatal TL-UL bus integrity fault is
   * detected.
   */
  kDifMbxAlertFatalFault = 0,
  /**
   * This recoverable alert is triggered when memory with invalid ECC (e.g.,
   * uninitialized memory) or at an invalid address is accessed.
   */
  kDifMbxAlertRecovFault = 1,
} dif_mbx_alert_t;

/**
 * Forces a particular alert, causing it to be escalated as if the hardware
 * had raised it.
 *
 * @param mbx A mbx handle.
 * @param alert The alert to force.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_alert_force(const dif_mbx_t *mbx, dif_mbx_alert_t alert);

/**
 * A mbx interrupt request type.
 */
typedef enum dif_mbx_irq {
  /**
   * A new object was received in the inbound mailbox.
   */
  kDifMbxIrqMbxReady = 0,
  /**
   * An abort request was received from the requester.
   */
  kDifMbxIrqMbxAbort = 1,
  /**
   * The mailbox instance generated an error.
   */
  kDifMbxIrqMbxError = 2,
} dif_mbx_irq_t;

/**
 * A snapshot of the state of the interrupts for this IP.
 *
 * This is an opaque type, to be used with the `dif_mbx_irq_get_state()`
 * and `dif_mbx_irq_acknowledge_state()` functions.
 */
typedef uint32_t dif_mbx_irq_state_snapshot_t;

/**
 * Returns the type of a given interrupt (i.e., event or status) for this IP.
 *
 * @param mbx A mbx handle.
 * @param irq An interrupt request.
 * @param[out] type Out-param for the interrupt type.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_get_type(const dif_mbx_t *mbx, dif_mbx_irq_t irq,
                                  dif_irq_type_t *type);

/**
 * Returns the state of all interrupts (i.e., pending or not) for this IP.
 *
 * @param mbx A mbx handle.
 * @param[out] snapshot Out-param for interrupt state snapshot.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_get_state(const dif_mbx_t *mbx,
                                   dif_mbx_irq_state_snapshot_t *snapshot);

/**
 * Returns whether a particular interrupt is currently pending.
 *
 * @param mbx A mbx handle.
 * @param irq An interrupt request.
 * @param[out] is_pending Out-param for whether the interrupt is pending.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_is_pending(const dif_mbx_t *mbx, dif_mbx_irq_t irq,
                                    bool *is_pending);

/**
 * Acknowledges all interrupts that were pending at the time of the state
 * snapshot.
 *
 * @param mbx A mbx handle.
 * @param snapshot Interrupt state snapshot.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_acknowledge_state(
    const dif_mbx_t *mbx, dif_mbx_irq_state_snapshot_t snapshot);

/**
 * Acknowledges all interrupts, indicating to the hardware that all
 * interrupts have been successfully serviced.
 *
 * @param mbx A mbx handle.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_acknowledge_all(const dif_mbx_t *mbx);

/**
 * Acknowledges a particular interrupt, indicating to the hardware that it has
 * been successfully serviced.
 *
 * @param mbx A mbx handle.
 * @param irq An interrupt request.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_acknowledge(const dif_mbx_t *mbx, dif_mbx_irq_t irq);

/**
 * Forces a particular interrupt, causing it to be serviced as if hardware had
 * asserted it.
 *
 * @param mbx A mbx handle.
 * @param irq An interrupt request.
 * @param val Value to be set.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_force(const dif_mbx_t *mbx, dif_mbx_irq_t irq,
                               const bool val);

/**
 * A snapshot of the enablement state of the interrupts for this IP.
 *
 * This is an opaque type, to be used with the
 * `dif_mbx_irq_disable_all()` and `dif_mbx_irq_restore_all()`
 * functions.
 */
typedef uint32_t dif_mbx_irq_enable_snapshot_t;

/**
 * Checks whether a particular interrupt is currently enabled or disabled.
 *
 * @param mbx A mbx handle.
 * @param irq An interrupt request.
 * @param[out] state Out-param toggle state of the interrupt.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_get_enabled(const dif_mbx_t *mbx, dif_mbx_irq_t irq,
                                     dif_toggle_t *state);

/**
 * Sets whether a particular interrupt is currently enabled or disabled.
 *
 * @param mbx A mbx handle.
 * @param irq An interrupt request.
 * @param state The new toggle state for the interrupt.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_set_enabled(const dif_mbx_t *mbx, dif_mbx_irq_t irq,
                                     dif_toggle_t state);

/**
 * Disables all interrupts, optionally snapshotting all enable states for later
 * restoration.
 *
 * @param mbx A mbx handle.
 * @param[out] snapshot Out-param for the snapshot; may be `NULL`.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_disable_all(const dif_mbx_t *mbx,
                                     dif_mbx_irq_enable_snapshot_t *snapshot);

/**
 * Restores interrupts from the given (enable) snapshot.
 *
 * @param mbx A mbx handle.
 * @param snapshot A snapshot to restore from.
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
dif_result_t dif_mbx_irq_restore_all(
    const dif_mbx_t *mbx, const dif_mbx_irq_enable_snapshot_t *snapshot);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // OPENTITAN_SW_DEVICE_LIB_DIF_AUTOGEN_DIF_MBX_AUTOGEN_H_
