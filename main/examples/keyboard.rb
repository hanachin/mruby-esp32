# ESP32::NVS.open("namespace", ESP32::NVS::READWRITE) do |nvs|
#   puts nvs.get_i8("8")
#   puts nvs.get_i16("16")
#   puts nvs.get_i32("32")
#   # nvs.set_i64("64", 64) # depends on MRB_INT_BIT
#   puts nvs.get_str("str")
#   puts nvs.get_blob("blob")
# end

# ESP32::NVS.open("namespace", ESP32::NVS::READWRITE) do |nvs|
#   nvs.set_i8("8", 8)
#   nvs.set_i16("16", 16)
#   nvs.set_i32("32", 32)
#   # nvs.set_i64("64", 64) # depends on MRB_INT_BIT
#   nvs.set_str("str", "STR")
#   nvs.set_blob("blob", "BLOB")
# end

GATTC_TAG = "GATTC_DEMO"
PROFILE_A_APP_ID = 0

remote_device_name = "TODO"
connect = false

ESP32::BT::Controller.mem_release(ESP32::ESP_BT_MODE_CLASSIC_BT)
ESP32::BT::Controller.init
ESP32::BT::Controller.enable
ESP32::Bluedroid.init
ESP32::Bluedroid.enable

def log_e(tag, message)
  raise "#{tag}: #{message}"
end

def log_i(tag, message)
  "#{tag}: #{message}"
end

def esp_log_buffer_hex(tag, buf)
  print "#{tag}: "
  # TODO
  p buf
end

ESP32::BLE::GAP.register_callback do |param|
  case param
  when ESP32::BLE::GAP::ScanParamCmpl
    duration = 30
    ESP32::BLE::GAP.start_scanning(duration)
  when ESP32::BLE::GAP::ScanStartCmpl
    unless param.success?
      log_e GATTC_TAG, ("scan start failed, error status = %x" % param.status)
      break
    end
    log_i GATTC_TAG, "scan start success"
  when ESP32::BLE::GAP::ScanRst
    if param.search_evt == ESP_GAP_SEARCH_INQ_RES_EVT
      esp_log_buffer_hex(param.bda)
      log_i GATTC_TAG, ("searched Adv Data Len %d, Scan Response Len %d" % [param.adv_data_len, param.scan_rsp_len])
      adv_name = param.adv_name
      log_i GATTC_TAG, ("searched Device Name Len %d" % adv_name.length)
      log_i GATTC_TAG, adv_name
      log_i GATTC_TAG, "\n"

      if adv_name == remote_device_name
        log_i GATTC_TAG, ("searched device %s\n" % remote_device_name)
        unless connect
          connect = true
          log_i GATTC_TAG, "connect to the remote device."
          ESP32::BLE::GAP.stop_scanning
        end
      end
    end
  else
    # TODO
    p param
  end
end

ESP32::BLE::GATTC.register_callback do |gattc_if, param|
  puts gattc_if
end

ESP32::BLE::GATTC.app_register(PROFILE_A_APP_ID)

ESP32::BLE::GATT.set_local_mtu(500)

raise "owari"

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
