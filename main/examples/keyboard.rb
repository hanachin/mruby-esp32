i2c = ESP32::I2C.new(ESP32::I2C::NUM_1, ESP32::I2C::MODE_MASTER, 0, 0, 0)
conf = ::ESP32::I2C::Config.new(
  mode:          ::ESP32::I2C::MODE_MASTER,
  sda_io_num:    ::ESP32::GPIO::NUM_18,
  sda_pullup_en: ::ESP32::GPIO::PULLUP_DISABLE,
  scl_io_num:    ::ESP32::GPIO::NUM_19,
  scl_pullup_en: ::ESP32::GPIO::PULLUP_DISABLE,
  clk_speed:     ::MCP23017::SUPPORTED_FREQ.first,
  addr_10bit_en: ::ESP32::I2C::ADDR_BIT_7,
  slave_addr:    0x00
)
i2c.param_config(conf)
i2c.driver_install

def i2c.write(addr, reg, data)
  cmd do |c|
    c.master_start
    b = ((addr << 1) | ::ESP32::I2C::MASTER_WRITE).chr
    c.master_write_byte(b, true)
    c.master_write_byte(reg.chr, true)
    c.master_write(data, true)
    c.master_stop
  end
end

def i2c.read(addr, reg, n)
  s = nil
  cmd do |c|
    c.master_start
    b = ((addr << 1) | ::ESP32::I2C::MASTER_WRITE).chr
    c.master_write_byte(b, true)
    c.master_write_byte(reg.chr, true)
    c.master_start
    b = ((addr << 1) | ::ESP32::I2C::MASTER_READ).chr
    c.master_write_byte(b, true)
    ret, s = c.master_read(n, ESP32::I2C::MASTER_ACK)
    c.master_stop
  end
  s
end

low = MCP23017::INPUT_LOW
mcp23017 = MCP23017.new(i2c, a0: low, a1: low, a2: low)
p mcp23017.write_gppua(0b11111111)
p mcp23017.write_gppub(0b11111111)

loop do
  data = mcp23017.read_pins
  puts "%08b%08b" % [data[0].ord, data[1].ord]
end

# # __END__
# # mcp23017[MCP23017::GPA0]
