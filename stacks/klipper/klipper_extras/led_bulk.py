import zlib, base64

class LedBulk:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode   = self.printer.lookup_object('gcode')

        self.printer.register_event_handler('klippy:shutdown', 
                                            self._handle_shutdown)        

        self.gcode.register_command('SET_LED_BULK',
                                    self.cmd_SET_LED_BULK,
                                    desc=self.cmd_SET_LED_BULK_help)

        self.shutdown = False        

    cmd_SET_LED_BULK_help = 'Set LED string to VALUES. LED is "type:name", i.e. "neopixel:whatever". VALUES is a base64-encoded zlib compressed bytearray, 4 bytes per index.'

    def _handle_shutdown(self):
        self.shutdown = True

    def cmd_SET_LED_BULK(self, gcmd):
        led_name = gcmd.get('LED').replace(':', ' ')

        try:
            led = self.printer.lookup_object(led_name)
        except:
            gcmd.respond_info("Error: LED not found: %s" % led_name)
            return

        try:
            decoded_data = base64.b64decode(gcmd.get('VALUES'))
        except Exception as e:
            gcmd.respond_info("Error decoding data: %s" % e)
            return

        try:
            values = zlib.decompress(decoded_data)
        except Exception as e:
            gcmd.respond_info("Error decompressing data: %s" % e)
        
        length = len(values)
        count = min(led.led_helper.led_count, int(length / 4))

        for i in range(count):
            next_state = values[i*4:i*4+4]
            led.led_helper.led_state[i] = tuple([
                next_state[0] / 255.0,
                next_state[1] / 255.0,
                next_state[2] / 255.0,
                next_state[3] / 255.0,
            ])

        if not self.shutdown:
            led.led_helper.update_func(led.led_helper.led_state, None)
        
def load_config(config):
    return LedBulk(config)
