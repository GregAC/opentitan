// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_LIB_DIF_DIF_PADCTRL_H_
#define OPENTITAN_SW_DEVICE_LIB_DIF_DIF_PADCTRL_H_

#include <stdbool.h>

// Generated.
#include "padctrl_regs.h"

#include "sw/device/lib/base/mmio.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Pad attributes.
 *
 * Some attributes have defined meanings, others are implementation defined
 * (`kDifPadCtrlAttrAdditionalFirst` and onwards). Not all pads will support all
 * attributes.
 */
typedef enum dif_padctrl_attr {
  kDifPadctrlAttrIOInvert = 0,
  kDifPadctrlAttrOpenDrain,
  kDifPadctrlAttrPullDown,
  kDifPadctrlAttrPullUp,
  kDifPadctrlAttrKeeper,
  kDifPadctrlAttrWeakDrive,
  kDifPadctrlAttrAdditionalFirst,
  kDifPadctrlAttrLast = PADCTRL_PARAM_ATTRDW - 1,
} dif_padctrl_attr_t;

/**
 * Generic padctrl DIF return codes
 */
typedef enum dif_padctrl_result {
  kDifPadctrlOk = 0,    /**< Operation succeeded. */
  kDifPadctrlError = 1, /**< Operation failed due to an unspecified error. It
                           cannot be recovered or retried. */
  kDifPadctrlBadArg = 2 /**< Operation failed due to a bad argument and can be
                           retried. No register reads or writes have been
                           performed */
} dif_padctrl_result_t;

/**
 * Pad kinds.
 *
 * A pad can be an MIO or DIO pad
 */
typedef enum dif_padctrl_pad_kind {
  kDifPadctrlPadMio = 0, /**< MIO (Multiplexed Input/Output) pad. Connected via
                            pinmux. */
  kDifPadctrlPadDio,     /**< DIO (Dedicated Input/Output) pad. Connected
                            directly to peripheral inputs and outputs, bypassing
                            pinmux. */
} dif_padctrl_pad_kind_t;

/**
 * Pad index.
 *
 * Combined with `dif_padctrl_pad_kind_t` to refer to a specific pad.
 */
typedef uint32_t dif_padctrl_pad_index_t;

/**
 * Padctrl instance state.
 *
 * Padctrl persistent data that is required by the Padctrl API.
 */
typedef struct dif_padctrl {
  mmio_region_t base_addr; /**< Padctrl base address. */
} dif_padctrl_t;

/**
 * Padctrl init routine error codes.
 */
typedef enum dif_padctrl_init_result {
  kDifPadctrlInitOk = kDifPadctrlOk,
  kDifPadctrlInitError = kDifPadctrlError,
  kDifPadctrlInitBadArg = kDifPadctrlBadArg,
  kDifPadctrlInitRegistersLocked, /**< Peripheral is locked and cannot be
                                     reset or initialised. This is not
                                     recoverable. */
} dif_padctrl_init_result_t;

/**
 * Initialises an instance of Padctrl.
 *
 * Information that must be retained, and is required to program Padctrl, shall
 * be stored in @p padctrl.
 *
 * @param base_addr Base address of an isntance of the Padctrl IP block
 * @param padctrl Padctrl state data
 * @return dif_padctrl_init_error_t.
 */
dif_padctrl_init_result_t dif_padctrl_init(mmio_region_t base_addr,
                                          dif_padctrl_t *padctrl);

/**
 * Locks the padctrl registers.
 *
 * After the registers have been locked, they can only be unlocked by the
 * system reset.
 *
 * @param padctrl Padctrl state data.
 * @return dif_padctrl_registers_lock_error_t.
 */
dif_padctrl_result_t dif_padctrl_registers_lock(
    dif_padctrl_t *padctrl);

/**
 * Padctrl attribute enable routines error codes.
 */
typedef enum dif_padctrl_enable_attr_result {
  kDifPadctrlEnableOk = kDifPadctrlOk,
  kDifPadctrlEnableError = kDifPadctrlError,
  kDifPadctrlEnableBadArg = kDifPadctrlBadArg,
  kDifPadctrlEnableAttrNotSupported, /**< Attribute is not supported. A write
                                        has been performed to the attribute
                                        registers but it had no effect as the
                                        attribute isn't supported. Enable can
                                        be retried with a different
                                        attribute. */
  kDifPadctrlEnableAttrConflict,     /**< Could not enable attribute because it
                                        conflicts with another already enabled
                                        attribute. No write to the attribute
                                        registers has been attemped. Enable can
                                        be retried with a different attribute. */
} dif_padctrl_enable_attr_result_t;

/**
 * Enables or disables an attribute for a pad.
 *
 * Not all pads implement all attributes and some combinations of attributes
 * cannot be enabled together. `dif_padctrl_enable_attr` will check for
 * this and return an appropriate error. Note that for additional attributes as
 * the meaning is implementation defined `dif_padctrl_enable_attr` cannot
 * check for invalid combinations that involve them.
 *
 * @param padctrl Padctrl state data.
 * @param pad_kind Which kind of pad to enable to an attribute for.
 * @param pad_index Which pad to enable an attribute for.
 * @param attr Attribute to enable.
 * @param enable Enables if true, disabled otherwise.
 * @return dif_padctrl_enable_error_t
 */
dif_padctrl_enable_attr_result_t dif_padctrl_enable_attr(
    const dif_padctrl_t *padctrl, dif_padctrl_pad_kind_t kind,
    dif_padctrl_pad_index_t index, dif_padctrl_attr_t attr, bool enable);

#endif  // OPENTITAN_SW_DEVICE_LIB_DIF_PADCTRL_H_

#ifdef __cplusplus
}  // extern "C"
#endif  // OPENTITAN_SW_DEVICE_LIB_DIF_DIF_PADCTRL_H_
