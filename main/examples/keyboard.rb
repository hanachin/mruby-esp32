i2c = ESP32::I2C.new(ESP32::I2C::NUM_0, ESP32::I2C::MODE_MASTER, 0, 0, 0)
conf = ::ESP32::I2C::Config.new(
  mode:          ::ESP32::I2C::MODE_MASTER,
  sda_io_num:    ::ESP32::GPIO::NUM_21,
  sda_pullup_en: ::ESP32::GPIO::PULLUP_ENABLE,
  scl_io_num:    ::ESP32::GPIO::NUM_22,
  scl_pullup_en: ::ESP32::GPIO::PULLUP_ENABLE,
  clk_speed:     ::MCP23017::SUPPORTED_FREQ[1]
)
i2c.param_config(conf)
i2c.driver_install

i2c2 = ESP32::I2C.new(ESP32::I2C::NUM_1, ESP32::I2C::MODE_MASTER, 0, 0, 0)
conf2 = ::ESP32::I2C::Config.new(
  mode:          ::ESP32::I2C::MODE_MASTER,
  sda_io_num:    ::ESP32::GPIO::NUM_2,
  sda_pullup_en: ::ESP32::GPIO::PULLUP_ENABLE,
  scl_io_num:    ::ESP32::GPIO::NUM_16,
  scl_pullup_en: ::ESP32::GPIO::PULLUP_ENABLE,
  clk_speed:     ::MCP23017::SUPPORTED_FREQ[1]
)
i2c2.param_config(conf2)
i2c2.driver_install

low = MCP23017::INPUT_LOW
high = MCP23017::INPUT_HIGH

l1 = MCP23017.new(i2c, a0: low, a1: low, a2: low)
l2 = MCP23017.new(i2c, a0: high, a1: low, a2: low)
r1 = MCP23017.new(i2c2, a0: low, a1: high, a2: low)
r2 = MCP23017.new(i2c2, a0: high, a1: high, a2: low)

[l1, l2, r1, r2].each do |mcp23017|
  puts "gppua"
  mcp23017.write_gppua(0b11111111)
  puts "gppub"
  mcp23017.write_gppub(0b11111111)
  puts "ipola"
  mcp23017.write_ipola(0b11111111)
  puts "ipolb"
  mcp23017.write_ipolb(0b11111111)
end

while true
  {L1: l1, L2: l2, R1: r1, R2: r2}.each do |key, mcp23017|
    begin
      data = mcp23017.read_pins
      puts "%s:%08b%08b" % [key, data[0].ord, data[1].ord]
    rescue ESP32::Error
      retry
    end
  end
  ESP32::System.delay(1000)
end
