// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
#include <set>
#include <vector>

#include "gtest/gtest.h"
#include "sw/device/lib/base/mmio.h"
#include "sw/device/lib/testing/mock_mmio.h"

#include "padctrl_regs.h"  // Generated.
#include "sw/device/lib/dif/dif_padctrl.h"

namespace dif_padctrl_test {
namespace {

class DifPadctrlTest : public testing::Test, public mock_mmio::MmioTest {
 protected:
  /**
   *
   * Attribute field informtion for a pad (MIO or DIO)
   */
  struct AttrField {
    ptrdiff_t reg_offset; /**< register offset for register holding field. */
    uintptr_t bit_mask;   /**< bit mask of field. */
    uintptr_t bit_offset; /**< offset of field within register. */
    uint32_t pad_num;     /**< which pad it corresponds to. */
  };

  // Setup attribute field info for all DIO and MIO pads
  std::vector<AttrField> dio_attr_fields_ = {
      {PADCTRL_DIO_PADS_REG_OFFSET, PADCTRL_DIO_PADS_ATTR0_MASK,
       PADCTRL_DIO_PADS_ATTR0_OFFSET, 0},
      {PADCTRL_DIO_PADS_REG_OFFSET, PADCTRL_DIO_PADS_ATTR1_MASK,
       PADCTRL_DIO_PADS_ATTR1_OFFSET, 1},
      {PADCTRL_DIO_PADS_REG_OFFSET, PADCTRL_DIO_PADS_ATTR2_MASK,
       PADCTRL_DIO_PADS_ATTR2_OFFSET, 2},
      {PADCTRL_DIO_PADS_REG_OFFSET, PADCTRL_DIO_PADS_ATTR3_MASK,
       PADCTRL_DIO_PADS_ATTR3_OFFSET, 3},
  };

  std::vector<AttrField> mio_attr_fields_ = {
      {PADCTRL_MIO_PADS0_REG_OFFSET, PADCTRL_MIO_PADS0_ATTR0_MASK,
       PADCTRL_MIO_PADS0_ATTR0_OFFSET, 0},
      {PADCTRL_MIO_PADS0_REG_OFFSET, PADCTRL_MIO_PADS0_ATTR1_MASK,
       PADCTRL_MIO_PADS0_ATTR1_OFFSET, 1},
      {PADCTRL_MIO_PADS0_REG_OFFSET, PADCTRL_MIO_PADS0_ATTR2_MASK,
       PADCTRL_MIO_PADS0_ATTR2_OFFSET, 2},
      {PADCTRL_MIO_PADS0_REG_OFFSET, PADCTRL_MIO_PADS0_ATTR3_MASK,
       PADCTRL_MIO_PADS0_ATTR3_OFFSET, 3},
      {PADCTRL_MIO_PADS1_REG_OFFSET, PADCTRL_MIO_PADS1_ATTR4_MASK,
       PADCTRL_MIO_PADS1_ATTR4_OFFSET, 4},
      {PADCTRL_MIO_PADS1_REG_OFFSET, PADCTRL_MIO_PADS1_ATTR5_MASK,
       PADCTRL_MIO_PADS1_ATTR5_OFFSET, 5},
      {PADCTRL_MIO_PADS1_REG_OFFSET, PADCTRL_MIO_PADS1_ATTR6_MASK,
       PADCTRL_MIO_PADS1_ATTR6_OFFSET, 6},
      {PADCTRL_MIO_PADS1_REG_OFFSET, PADCTRL_MIO_PADS1_ATTR7_MASK,
       PADCTRL_MIO_PADS1_ATTR7_OFFSET, 7},
      {PADCTRL_MIO_PADS2_REG_OFFSET, PADCTRL_MIO_PADS2_ATTR8_MASK,
       PADCTRL_MIO_PADS2_ATTR8_OFFSET, 8},
      {PADCTRL_MIO_PADS2_REG_OFFSET, PADCTRL_MIO_PADS2_ATTR9_MASK,
       PADCTRL_MIO_PADS2_ATTR9_OFFSET, 9},
      {PADCTRL_MIO_PADS2_REG_OFFSET, PADCTRL_MIO_PADS2_ATTR10_MASK,
       PADCTRL_MIO_PADS2_ATTR10_OFFSET, 10},
      {PADCTRL_MIO_PADS2_REG_OFFSET, PADCTRL_MIO_PADS2_ATTR11_MASK,
       PADCTRL_MIO_PADS2_ATTR11_OFFSET, 11},
      {PADCTRL_MIO_PADS3_REG_OFFSET, PADCTRL_MIO_PADS3_ATTR12_MASK,
       PADCTRL_MIO_PADS3_ATTR12_OFFSET, 12},
      {PADCTRL_MIO_PADS3_REG_OFFSET, PADCTRL_MIO_PADS3_ATTR13_MASK,
       PADCTRL_MIO_PADS3_ATTR13_OFFSET, 13},
      {PADCTRL_MIO_PADS3_REG_OFFSET, PADCTRL_MIO_PADS3_ATTR14_MASK,
       PADCTRL_MIO_PADS3_ATTR14_OFFSET, 14},
      {PADCTRL_MIO_PADS3_REG_OFFSET, PADCTRL_MIO_PADS3_ATTR15_MASK,
       PADCTRL_MIO_PADS3_ATTR15_OFFSET, 15}};

  // Vector of all attributes, initialise with the basic attributes.
  std::vector<dif_padctrl_attr_t> attributes_ = {
      kDifPadctrlAttrIOInvert, kDifPadctrlAttrOpenDrain,
      kDifPadctrlAttrPullDown, kDifPadctrlAttrPullUp,
      kDifPadctrlAttrKeeper,   kDifPadctrlAttrWeakDrive};

  void SetUp() override {
    // Add additional attributes to attributes_ vector during setup.
    for (dif_padctrl_attr_t attr = kDifPadctrlAttrAdditionalFirst;
         attr <= kDifPadctrlAttrLast; attr = (dif_padctrl_attr_t)(attr + 1)) {
      attributes_.push_back(attr);
    }
  }

  void DeviceInit() {
    EXPECT_READ32(PADCTRL_REGEN_REG_OFFSET, 1);

    // Extract unique register offsets from dio_attr_fields_.
    // set is required to keep ordering.
    std::set<ptrdiff_t> dio_pad_reg_offsets;
    for (auto dio_attr_field : dio_attr_fields_) {
      dio_pad_reg_offsets.insert(dio_attr_field.reg_offset);
    }

    // Iterate through in ascending order, expecting a write of 0 to each.
    for (auto dio_reg_offset : dio_pad_reg_offsets) {
      EXPECT_WRITE32(dio_reg_offset, 0);
    }

    // Extract unique register offsets from mio_attr_fields_
    std::set<ptrdiff_t> mio_pad_reg_offsets;
    for (auto mio_attr_field : mio_attr_fields_) {
      mio_pad_reg_offsets.insert(mio_attr_field.reg_offset);
    }

    // Iterate through in ascending order, expecting a write of 0 to each.
    for (auto mio_reg_offset : mio_pad_reg_offsets) {
      EXPECT_WRITE32(mio_reg_offset, 0);
    }

    mmio_region_t base_addr = dev().region();
    EXPECT_EQ(dif_padctrl_init(base_addr, &dif_padctrl_),
              kDifPadctrlInitOk);
  }

  /**
   * Expects the read required to read an attribute field.
   *
   * @param attr_field Which attribute field we expect to read
   * @param existing_attrs What existing attributes will be in the read
   * @return The bits seen by the read
   */
  uint32_t ExpectAttrFieldRead(
      const AttrField &attr_field,
      std::initializer_list<dif_padctrl_attr_t> existing_attrs) {
    uint32_t attr_field_bits = 0;

    for (auto attr : existing_attrs) {
      EXPECT_LE(attr, kDifPadctrlAttrLast);

      attr_field_bits |= 1 << attr;
    }

    EXPECT_EQ(attr_field_bits & ~attr_field.bit_mask, 0);

    uint32_t other_field_bits = dev().GarbageMemory<uint32_t>() &
                                ~(attr_field.bit_mask << attr_field.bit_offset);

    uint32_t existing_reg_bits =
        other_field_bits | (attr_field_bits << attr_field.bit_offset);

    EXPECT_READ32(attr_field.reg_offset, existing_reg_bits);

    return existing_reg_bits;
  }

  /**
   * Attribute field update kinds
   *
   * Specifies whether an attribute should be enabled or disabled and if
   * enabled whether it should be supported or not.
   */
  enum AttrFieldUpdateKind {
    kAttrFieldUpdateEnableSupported,
    kAttrFieldUpdateEnableNotSupported,
    kAttrFieldUpdateDisable
  };

  /**
   * Expects a read and write sequence required to update attributes
   *
   * @param attr_field Which attribute field we expect to update
   * @param existing_attrs What existing attributes will be seen in the
   * initial read
   * @param update_addr What attribute to update
   * @param update_kind What kind of update to do
   */
  void ExpectAttrFieldUpdate(
      const AttrField &attr_field,
      std::initializer_list<dif_padctrl_attr_t> existing_attrs,
      dif_padctrl_attr_t update_attr, AttrFieldUpdateKind update_kind) {
    // Check the attribute we want to update is valid
    EXPECT_LE(update_attr, kDifPadctrlAttrLast);

    // Expect a read that will give us the existing attributes, retaining the
    // bits the that will be returned from that read.
    uint32_t existing_reg_bits =
        ExpectAttrFieldRead(attr_field, existing_attrs);

    // Update the bits from the read to include the attribute update.
    uint32_t update_attr_bit = (1 << update_attr);
    EXPECT_EQ(update_attr_bit & ~attr_field.bit_mask, 0);

    uint32_t new_reg_bits;
    bool enable = (update_kind != kAttrFieldUpdateDisable);

    if (enable) {
      new_reg_bits =
          existing_reg_bits | (update_attr_bit << attr_field.bit_offset);
    } else {
      new_reg_bits =
          existing_reg_bits & ~(update_attr_bit << attr_field.bit_offset);
    }

    // Expect a write to perform the attribute update.
    EXPECT_WRITE32(attr_field.reg_offset, new_reg_bits);

    if (enable) {
      // If this update enables an attribute expect a read to check if it is
      // supported, what the read returns depends upon whether |update_kind|
      // says the attribute is supported.
      if (update_kind == kAttrFieldUpdateEnableSupported) {
        EXPECT_READ32(attr_field.reg_offset, new_reg_bits);
      } else {
        EXPECT_READ32(attr_field.reg_offset, existing_reg_bits);
      }
    }
  }

  /**
   * Tests various attribute enables/disables for success
   *
   * @param attr_field The attribute field to test
   * @param pad_kind What kind of pad |attr_field| is for
   */
  void TestEnableAttrSuccess(const AttrField &attr_field,
                             dif_padctrl_pad_kind_t pad_kind) {
    DeviceInit();

    // Test enabling a supported attribute when others are already enabled.
    ExpectAttrFieldUpdate(
        attr_field, {kDifPadctrlAttrIOInvert, kDifPadctrlAttrWeakDrive},
        kDifPadctrlAttrPullDown, kAttrFieldUpdateEnableSupported);

    EXPECT_EQ(
        dif_padctrl_enable_attr(&dif_padctrl_, pad_kind, attr_field.pad_num,
                                kDifPadctrlAttrPullDown, true),
        kDifPadctrlEnableOk);

    // Test disabling a supported attribute when others are already enabled.
    ExpectAttrFieldUpdate(attr_field,
                          {kDifPadctrlAttrIOInvert, kDifPadctrlAttrPullUp},
                          kDifPadctrlAttrPullUp, kAttrFieldUpdateDisable);

    EXPECT_EQ(
        dif_padctrl_enable_attr(&dif_padctrl_, pad_kind, attr_field.pad_num,
                                kDifPadctrlAttrPullUp, false),
        kDifPadctrlEnableOk);

    // For every attribute test enabling and disabling it when no other
    // attributes are enabled and it is a supported attribute.
    for (auto attr : attributes_) {
      ExpectAttrFieldUpdate(attr_field, {}, attr,
                            kAttrFieldUpdateEnableSupported);

      EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, pad_kind,
                                        attr_field.pad_num, attr, true),
                kDifPadctrlEnableOk);

      ExpectAttrFieldUpdate(attr_field, {attr}, attr, kAttrFieldUpdateDisable);

      EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, pad_kind,
                                        attr_field.pad_num, attr, false),
                kDifPadctrlEnableOk);
    }
  }

  /**
   * Tests a failure to enable an attribute due to a conflict
   *
   * @param attr_field The attribute field to test
   * @param pad_kind What kind of pad |attr_field| is for
   */
  void TestEnableAttrFailureConflict(const AttrField &attr_field,
                                     dif_padctrl_pad_kind_t pad_kind) {
    DeviceInit();

    // Expect a read of |attr_field| with a couple of attribute set.
    ExpectAttrFieldRead(attr_field,
                        {kDifPadctrlAttrIOInvert, kDifPadctrlAttrPullUp});

    // Attempt to set an attribute that conflicts with the currently set one
    // expecting the appropriate error.
    EXPECT_EQ(
        dif_padctrl_enable_attr(&dif_padctrl_, pad_kind, attr_field.pad_num,
                                kDifPadctrlAttrPullDown, true),
        kDifPadctrlEnableAttrConflict);
  }

  /**
   * Test a failure to enable an attribute that isn't supported
   *
   * @param attr_field The attribute field to test
   * @param pad_kind What kind of pad |attr_field| is for
   */
  void TestEnableAttrFailureNotSupported(const AttrField &attr_field,
                                         dif_padctrl_pad_kind_t pad_kind) {
    DeviceInit();

    // Test enabling an unsupported attribute when others are already enabled.
    ExpectAttrFieldUpdate(
        attr_field, {kDifPadctrlAttrKeeper, kDifPadctrlAttrWeakDrive},
        kDifPadctrlAttrPullUp, kAttrFieldUpdateEnableNotSupported);

    EXPECT_EQ(
        dif_padctrl_enable_attr(&dif_padctrl_, pad_kind, attr_field.pad_num,
                                kDifPadctrlAttrPullUp, true),
        kDifPadctrlEnableAttrNotSupported);

    // For every attribute test enabling it when no other attributes are
    // enabled and it is not a supported attribute.
    for (auto attr : attributes_) {
      ExpectAttrFieldUpdate(attr_field, {}, attr,
                            kAttrFieldUpdateEnableNotSupported);

      EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, pad_kind,
                                        attr_field.pad_num, attr, true),
                kDifPadctrlEnableAttrNotSupported);
    }
  }

  dif_padctrl_t dif_padctrl_;
};

TEST_F(DifPadctrlTest, InitSuccess) { DeviceInit(); }

TEST_F(DifPadctrlTest, InitFailureLocked) {
  EXPECT_READ32(PADCTRL_REGEN_REG_OFFSET, 0);

  mmio_region_t base_addr = dev().region();
  EXPECT_EQ(dif_padctrl_init(base_addr, &dif_padctrl_),
            kDifPadctrlInitRegistersLocked);
}

TEST_F(DifPadctrlTest, InitFailureInvalidPadctrl) {
  mmio_region_t base_addr = dev().region();

  EXPECT_EQ(dif_padctrl_init(base_addr, nullptr),
            kDifPadctrlInitBadArg);
}

TEST_F(DifPadctrlTest, LockSuccess) {
  DeviceInit();

  EXPECT_WRITE32(PADCTRL_REGEN_REG_OFFSET, 0);

  EXPECT_EQ(dif_padctrl_registers_lock(&dif_padctrl_),
            kDifPadctrlOk);
}

TEST_F(DifPadctrlTest, LockFailureInvalidPadctrl) {
  EXPECT_EQ(dif_padctrl_registers_lock(nullptr),
            kDifPadctrlBadArg);
}

TEST_F(DifPadctrlTest, EnableAttrSuccess) {
  for (auto attr_field : mio_attr_fields_) {
    TestEnableAttrSuccess(attr_field, kDifPadctrlPadMio);
  }

  for (auto attr_field : dio_attr_fields_) {
    TestEnableAttrSuccess(attr_field, kDifPadctrlPadDio);
  }
}

TEST_F(DifPadctrlTest, EnableMioAttrFailureConflict) {
  for (auto attr_field : mio_attr_fields_) {
    TestEnableAttrFailureConflict(attr_field, kDifPadctrlPadMio);
  }

  for (auto attr_field : dio_attr_fields_) {
    TestEnableAttrFailureConflict(attr_field, kDifPadctrlPadDio);
  }
}

TEST_F(DifPadctrlTest, EnableMioAttrFailureNotSupported) {
  for (auto attr_field : mio_attr_fields_) {
    TestEnableAttrFailureNotSupported(attr_field, kDifPadctrlPadMio);
  }

  for (auto attr_field : dio_attr_fields_) {
    TestEnableAttrFailureNotSupported(attr_field, kDifPadctrlPadDio);
  }
}

TEST_F(DifPadctrlTest, EnableAttrFailureInvalidPad) {
  DeviceInit();

  EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, kDifPadctrlPadMio,
                                    PADCTRL_PARAM_NMIOPADS,
                                    kDifPadctrlAttrPullUp, true),
            kDifPadctrlEnableBadArg);

  EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, kDifPadctrlPadDio,
                                    PADCTRL_PARAM_NDIOPADS,
                                    kDifPadctrlAttrPullUp, true),
            kDifPadctrlEnableBadArg);

  EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, kDifPadctrlPadMio, -1,
                                    kDifPadctrlAttrPullUp, true),
            kDifPadctrlEnableBadArg);

  EXPECT_EQ(dif_padctrl_enable_attr(&dif_padctrl_, kDifPadctrlPadDio, -1,
                                    kDifPadctrlAttrPullUp, true),
            kDifPadctrlEnableBadArg);
}

TEST_F(DifPadctrlTest, EnableMioAttrFailureInvalidAttr) {
  DeviceInit();

  for (auto pad_kind : {kDifPadctrlPadMio, kDifPadctrlPadDio}) {
    dif_padctrl_attr_t bad_attr_1 =
        (dif_padctrl_attr_t)(kDifPadctrlAttrLast + 1);

    EXPECT_EQ(
        dif_padctrl_enable_attr(&dif_padctrl_, pad_kind, 0, bad_attr_1, true),
        kDifPadctrlEnableBadArg);

    dif_padctrl_attr_t bad_attr_2 =
        (dif_padctrl_attr_t)(kDifPadctrlAttrIOInvert - 1);

    EXPECT_EQ(
        dif_padctrl_enable_attr(&dif_padctrl_, pad_kind, 0, bad_attr_2, true),
        kDifPadctrlEnableBadArg);
  }
}

TEST_F(DifPadctrlTest, EnableMioAttrFailureInvalidPadctrl) {
  DeviceInit();

  EXPECT_EQ(dif_padctrl_enable_attr(nullptr, kDifPadctrlPadMio, 0,
                                    kDifPadctrlAttrIOInvert, true),
            kDifPadctrlEnableBadArg);
}

}  // namespace
}  // namespace dif_padctrl_test
