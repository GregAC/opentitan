// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <assert.h>

#include "sw/device/lib/testing/test_framework/check.h"
#include "sw/device/lib/testing/test_framework/ottf_main.h"
#include "sw/ip/i2c/dif/dif_i2c.h"
#include "sw/ip/i2c/test/utils/i2c_testutils.h"
#include "sw/ip/rv_core_ibex/test/utils/rv_core_ibex_testutils.h"
#include "sw/lib/sw/device/arch/device.h"
#include "sw/lib/sw/device/base/macros.h"
#include "sw/lib/sw/device/base/memory.h"
#include "sw/lib/sw/device/base/mmio.h"
#include "sw/lib/sw/device/runtime/hart.h"
#include "sw/lib/sw/device/runtime/irq.h"
#include "sw/lib/sw/device/runtime/log.h"
#include "sw/lib/sw/device/runtime/print.h"

#include "hw/top_darjeeling/sw/autogen/top_darjeeling.h"
#include "i2c_regs.h"  // Generated.

OTTF_DEFINE_TEST_CONFIG();

enum {
  kDeviceAddr = 0x40,

  // Registers
  kTemperatureReg = 0x00,
  kHumidityReg = 0x01,
  kConfigurationReg = 0x02,
  kManufacturerIdReg = 0xFE,
  kDeviceIdReg = 0xFF,

  // Registers values
  kManufacturerId = 0x5449,
  kDeviceId = 0x1050,

  // Other
  kDefaultTimeoutMicros = 100000,
};

static dif_rv_core_ibex_t rv_core_ibex;
static dif_pinmux_t pinmux;
static dif_i2c_t i2c;

static status_t read_manufacture_id(void) {
  uint8_t reg = kManufacturerIdReg;
  uint8_t data[2] = {0};
  TRY(i2c_testutils_write(&i2c, kDeviceAddr, 1, &reg, true));
  TRY(i2c_testutils_read(&i2c, kDeviceAddr, 2, data, kDefaultTimeoutMicros));
  uint8_t manufacturer_id[2] = {kManufacturerId >> 8, kManufacturerId & 0xFF};
  TRY_CHECK_ARRAYS_EQ(data, manufacturer_id, sizeof(data));
  return OK_STATUS();
}

static status_t read_product_id(void) {
  uint8_t reg = kDeviceIdReg;
  uint8_t data[2] = {0};
  TRY(i2c_testutils_write(&i2c, kDeviceAddr, 1, &reg, true));
  TRY(i2c_testutils_read(&i2c, kDeviceAddr, 2, data, kDefaultTimeoutMicros));
  uint8_t device_id[2] = {kDeviceId >> 8, kDeviceId & 0xFF};
  TRY_CHECK_ARRAYS_EQ(data, device_id, sizeof(data));
  return OK_STATUS();
}

static status_t read_temperature(void) {
  uint8_t reg = kTemperatureReg;
  uint8_t data[2] = {0};
  TRY(i2c_testutils_write(&i2c, kDeviceAddr, 1, &reg, true));
  TRY(i2c_testutils_read(&i2c, kDeviceAddr, 2, data, kDefaultTimeoutMicros));

  // HDC1080 temperature formula: T = -40 + 165 * (raw / 2^16)
  // Using fixed-point math for calculations.
  int32_t temperature_raw = (data[0] << 8) | data[1];
  int32_t temperature_fixed = (-40 * (1 << 16)) + (165 * temperature_raw);
  temperature_fixed /= (1 << 16);

  // Check if the temperature is within a plausible range for our CI setup.
  CHECK(temperature_fixed >= 15 && temperature_fixed <= 40,
        "Temperature out of range: %d", temperature_fixed);

  return OK_STATUS();
}

static status_t read_humidity(void) {
  uint8_t reg = kHumidityReg;
  uint8_t data[2] = {0};
  TRY(i2c_testutils_write(&i2c, kDeviceAddr, 1, &reg, true));
  TRY(i2c_testutils_read(&i2c, kDeviceAddr, 2, data, kDefaultTimeoutMicros));

  uint16_t humidity_raw = (uint16_t)(data[0] << 8) | data[1];
  int32_t humidity_fixed = (100 * humidity_raw) / (1 << 16);

  // Check if the humidity is within a plausible range for our CI setup.
  CHECK(humidity_fixed >= 5 && humidity_fixed <= 95,
        "Humidity out of range: %d", humidity_fixed);

  return OK_STATUS();
}

static status_t test_init(void) {
  mmio_region_t base_addr =
      mmio_region_from_addr(TOP_DARJEELING_RV_CORE_IBEX_CFG_BASE_ADDR);

  TRY(dif_rv_core_ibex_init(base_addr, &rv_core_ibex));

  base_addr = mmio_region_from_addr(TOP_DARJEELING_I2C2_BASE_ADDR);
  TRY(dif_i2c_init(base_addr, &i2c));

  base_addr = mmio_region_from_addr(TOP_DARJEELING_PINMUX_AON_BASE_ADDR);
  TRY(dif_pinmux_init(base_addr, &pinmux));

  TRY(dif_i2c_host_set_enabled(&i2c, kDifToggleEnabled));

  return OK_STATUS();
}

bool test_main(void) {
  status_t test_result;
  CHECK_STATUS_OK(test_init());

  // TODO: test kDifI2cSpeedFastPlus
  // (Bug lowrisc/opentitan#18764)
  dif_i2c_speed_t speeds[] = {kDifI2cSpeedStandard, kDifI2cSpeedFast};

  test_result = OK_STATUS();
  for (size_t i = 0; i < ARRAYSIZE(speeds); ++i) {
    CHECK_STATUS_OK(i2c_testutils_set_speed(&i2c, speeds[i]));
    EXECUTE_TEST(test_result, read_manufacture_id);
    EXECUTE_TEST(test_result, read_product_id);
    EXECUTE_TEST(test_result, read_temperature);
    EXECUTE_TEST(test_result, read_humidity);
  }

  return status_ok(test_result);
}