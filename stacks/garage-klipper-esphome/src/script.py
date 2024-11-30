from aioesphomeserver import LightEntity, EntityListener, Device, LightStateResponse
from aioesphomeapi import LightColorCapability
from moonraker_api import MoonrakerClient, MoonrakerListener
from moonraker_api.const import WEBSOCKET_STATE_STOPPED

from urllib.parse import urlparse
from neopixel_effects.effects import StaticEffect, BlendEffect, TwinkleEffect, RainbowEffect

import base64, zlib
import dataclasses
import asyncio

@dataclasses.dataclass
class LightString:
    name: str
    count: int
    reverse: bool

    def gcode(self, pixels):
        if self.reverse:
            pixels = reversed(pixels)

        data = bytearray()
        for p in range(len(pixels)):
            pixel = pixels[p]
            data.extend([
                int(pixel[0] * 255),
                int(pixel[1] * 255),
                int(pixel[2] * 255),
                int(pixel[3] * 255),
            ])

        values = base64.b64encode(zlib.compress(bytes(data), 9)).decode()

        return ["SET_LED_BULK LED=%s VALUES='%s'" % (self.name, values)]

class LightStrip(EntityListener):
    def __init__(self, *args, connector=None, strings=[], effects={}, **kwargs):
        super().__init__(*args, **kwargs)
        self.connector = connector
        self.strings = strings
        self.num_pixels = sum([s.count for s in strings])
        self.effects = effects

        self.current_effect_name = None
        self.current_effect = StaticEffect(count=self.num_pixels)
        self.white_brightness = 0.0
        self.color_brightness = 0.0

    async def handle(self, key, message):
        if type(message) != LightStateResponse:
            return

        await self.device.log(1, "light", f"message.effect: '{message.effect}'")

        if message.effect != "" and message.effect != self.current_effect_name:
            if message.effect in self.effects:
                self.current_effect_name = message.effect
                self.current_effect = self.effects[message.effect](self.num_pixels, message)
                self.current_effect.next_frame()

        if self.current_effect:
            self.current_effect.update(message)

        self.color_brightness = message.color_brightness
        self.white_brightness = message.brightness

        if message.state == False:
            self.color_brightness = 0.0
            self.white_brightness = 0.0

    async def render(self):
        pixels = []

        for i in range(self.num_pixels):
            color = self.current_effect.pixels[i]

            pixel = [
                color[0] * self.color_brightness,
                color[1] * self.color_brightness,
                color[2] * self.color_brightness,
                color[3] * self.white_brightness,
            ]

            pixels.append(pixel)

        # partition strings
        # write to each string
        cur = 0
        gcodes = []
        for string in self.strings:
            last = cur + string.count - 1
            gcodes.extend(string.gcode(pixels[cur:last]))
            cur = last + 1

        resp = await self.connector.client.call_method(
            "printer.gcode.script",
            script="\n".join(gcodes),
        )

    async def run(self):
        while True:
            self.current_effect.next_frame()
            await self.render()
            await asyncio.sleep(1/24.0)


class APIConnector(MoonrakerListener):
    def __init__(self, url):
        self.running = False
        self.url = url

        url_parts = urlparse(url)

        self.client = MoonrakerClient(
            loop=asyncio.get_event_loop(),
            listener=self,
            host=url_parts.hostname,
            port=url_parts.port,
            api_key=url_parts.username,
        )

    async def start(self) -> None:
        self.running = True
        await self.client.connect()

    async def stop(self) -> None:
        self.running = False
        await self.client.disconnect()

    async def state_changed(self, state: str) -> None:
        if self.client.state == WEBSOCKET_STATE_STOPPED:
            await self.client.connect()

class Server:
    async def run(self):
        connector = APIConnector("http://localhost:7125")
        await connector.start()

        device = Device(
            name = "Garage Stuff",
            mac_address = "7E:85:BA:7E:38:E8",
            model = "Garage Stuff",
        )

        device.add_entity(LightEntity(
            name="Front Lights",
            color_modes=[LightColorCapability.ON_OFF | LightColorCapability.BRIGHTNESS | LightColorCapability.RGB | LightColorCapability.WHITE],
            effects=["Static", "Twinkle", "Rainbow"],
        ))

        def make_twinkle_effect(count, state):
            return BlendEffect(
                TwinkleEffect(count=count, include_white_channel=True),
                StaticEffect(count=count, color=[state.red, state.green, state.blue, state.white], include_white_channel=True),
                mode='lighten',
                include_white_channel=True,
            )

        def make_static_effect(count, state):
            return StaticEffect(
                count=count,
                color=[
                    state.red,
                    state.green,
                    state.blue,
                    state.white,
                ],
                include_white_channel=True
            )

        def make_rainbow_effect(count, state):
            return RainbowEffect(
                count=count,
                brightness=1.0,
                change_per_frame=0.005,
                length_multiplier=1.0,
                include_white_channel=True
            )

        device.add_entity(LightStrip(
            name = "_front_lights_strip",
            connector = connector,
            entity_id = "front_lights",
            strings = [
                LightString(name="neopixel:east_string", count=60, reverse=True),
                LightString(name="neopixel:west_string", count=60, reverse=False),                
            ],
            effects={
                "Static": make_static_effect,
                "Twinkle": make_twinkle_effect,
                "Rainbow": make_rainbow_effect,
            },
        ))

        await device.run()


if __name__ == "__main__":
    server = Server()
    asyncio.run(server.run())
