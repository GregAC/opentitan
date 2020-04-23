// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdbool.h>
#include <stddef.h>

#include "sw/device/lib/dif/dif_padctrl.h"

// Generated.
#include "padctrl_regs.h"

#include "sw/device/lib/base/mmio.h"
#include "sw/device/lib/base/bitfield.h"

static const int kPadctrlRegisterWidthInBytes = (PADCTRL_PARAM_REG_WIDTH / 8);

// This is the value written to a whole attribute register, it is not a per-pad
// value so desired default attribute setting must be replicated per attribute
// field in the attribute register.
static const uint32_t kPadctrlAttrDefault = 0;
static const uint32_t kPadctrlAttrFieldMask = PADCTRL_MIO_PADS0_ATTR0_MASK;

/**
 * Checks if an attribute field contains conflicting attributes
 */
static bool conflicting_attributes(uint32_t attrs) {
  // Cannot be both pull up and pull down
  if ((attrs & (1 << kDifPadctrlAttrPullDown)) &&
      (attrs & (1 << kDifPadctrlAttrPullUp))) {
    return true;
  }

  // Cannot combine pull down with open drain
  if ((attrs & (1 << kDifPadctrlAttrPullDown)) &&
      (attrs & (1 << kDifPadctrlAttrOpenDrain))) {
    return true;
  }

  return false;
}

dif_padctrl_init_result_t dif_padctrl_init(mmio_region_t base_addr,
                                          dif_padctrl_t *padctrl) {
  if (padctrl == NULL) {
    return kDifPadctrlInitBadArg;
  }

  bool padctrl_unlocked = mmio_region_get_bit32(
      base_addr, PADCTRL_REGEN_REG_OFFSET, PADCTRL_REGEN_WEN);

  if (!padctrl_unlocked) {
    return kDifPadctrlInitRegistersLocked;
  }

  padctrl->base_addr = base_addr;

  // Reset all DIO pad attributes to the default value
  for (int i = 0; i < PADCTRL_DIO_PADS_MULTIREG_COUNT; ++i) {
    // TODO: Fix reggen so DIO_PADS defines don't switch between having and not
    // having a 0 depending on whether multiple regs are needed.
    ptrdiff_t dio_pads_register_offset =
        PADCTRL_DIO_PADS_REG_OFFSET + (i * kPadctrlRegisterWidthInBytes);
    mmio_region_write32(padctrl->base_addr, dio_pads_register_offset,
                        kPadctrlAttrDefault);
  }

  // Reset all MIO pad attributes to the default value
  for (int i = 0; i < PADCTRL_MIO_PADS_MULTIREG_COUNT; ++i) {
    // TODO: Fix reggen so MIO_PADS defines don't switch between having and not
    // having a 0 depending on whether multiple regs are needed.
    ptrdiff_t mio_pads_register_offset =
        PADCTRL_MIO_PADS0_REG_OFFSET + (i * kPadctrlRegisterWidthInBytes);
    mmio_region_write32(padctrl->base_addr, mio_pads_register_offset,
                        kPadctrlAttrDefault);
  }

  return kDifPadctrlInitOk;
}

dif_padctrl_result_t dif_padctrl_registers_lock(
    dif_padctrl_t *padctrl) {
  if (padctrl == NULL) {
    return kDifPadctrlBadArg;
  }

  mmio_region_write32(padctrl->base_addr, PADCTRL_REGEN_REG_OFFSET, 0);

  return kDifPadctrlOk;
}

/**
 * Determine field and register containing attributes for a given pad.
 *
 * @return false if pad index is out of range.
 */
static bool calc_pad_attr_field_and_reg(dif_padctrl_pad_index_t index,
    int num_pads, ptrdiff_t base_register_offset, int attr_fields_per_reg,
    bitfield_field32_t* field_out, ptrdiff_t* register_offset_out) {
  if (index >= num_pads) {
    return false;
  }

  uint32_t register_index;

  register_index = index / attr_fields_per_reg;

  field_out->index =
      (index % PADCTRL_MIO_PADS_ATTR_FIELDS_PER_REG) * PADCTRL_PARAM_ATTRDW;

  field_out->mask = kPadctrlAttrFieldMask;

  *register_offset_out = base_register_offset +
      (kPadctrlRegisterWidthInBytes * register_index);

  return true;
}

dif_padctrl_enable_attr_result_t dif_padctrl_enable_attr(
    const dif_padctrl_t *padctrl, dif_padctrl_pad_kind_t kind,
    dif_padctrl_pad_index_t index, dif_padctrl_attr_t attr, bool enable) {
  if (padctrl == NULL) {
    return kDifPadctrlEnableBadArg;
  }

  if (attr > kDifPadctrlAttrLast) {
    return kDifPadctrlEnableBadArg;
  }

  bitfield_field32_t attr_field;
  ptrdiff_t pad_register_offset;

  if (kind == kDifPadctrlPadMio) {
    if (!calc_pad_attr_field_and_reg(index, PADCTRL_PARAM_NMIOPADS,
          PADCTRL_MIO_PADS0_REG_OFFSET, PADCTRL_MIO_PADS_ATTR_FIELDS_PER_REG,
          &attr_field, &pad_register_offset)) {
        return kDifPadctrlEnableBadArg;
    }
  } else {
    if (!calc_pad_attr_field_and_reg(index, PADCTRL_PARAM_NDIOPADS,
          PADCTRL_DIO_PADS_REG_OFFSET, PADCTRL_DIO_PADS_ATTR_FIELDS_PER_REG,
          &attr_field, &pad_register_offset)) {
        return kDifPadctrlEnableBadArg;
    }
  }

  // Determine which bit within the register controls the attribute being
  // modified.
  uint32_t attr_bit_index = attr_field.index + attr;

  if (enable) {
    // Get the attribute field from the appropriate register
    uint32_t attr_reg_value =
        mmio_region_read32(padctrl->base_addr, pad_register_offset);

    attr_field.value = bitfield_get_field32(attr_reg_value, attr_field);

    // Update the attribute field with the attribute to enable
    attr_field.value |= (1 << attr);

    // Check if the new setting causes a conflict
    if (conflicting_attributes(attr_field.value)) {
      return kDifPadctrlEnableAttrConflict;
    }

    // Write the new attribute setting back to the appropriate register
    attr_reg_value = bitfield_set_field32(attr_reg_value, attr_field);

    mmio_region_write32(padctrl->base_addr, pad_register_offset,
                        attr_reg_value);

    // See if attribute enable was successful
    bool test_attr = mmio_region_get_bit32(padctrl->base_addr,
                                           pad_register_offset, attr_bit_index);

    // Attribute fields are WARL so if attribute isn't supported read value
    // won't have it set.
    if (test_attr) {
      return kDifPadctrlEnableOk;
    } else {
      return kDifPadctrlEnableAttrNotSupported;
    }
  } else {
    // Disable can never fail (once this point has been reached).
    mmio_region_nonatomic_clear_bit32(padctrl->base_addr, pad_register_offset,
                                      attr_bit_index);

    return kDifPadctrlEnableOk;
  }
}
