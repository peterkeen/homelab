import time
import random
import colorsys
import asyncio

from machine import WS2812B
from neopixel.effects import StaticEffect, BlendEffect, TwinkleEffect

from aioesphomeserver import (
    Device,
    LightEntity,
    LightStateResponse,
    EntityListener,
)
from aioesphomeapi import LightColorCapability

class LightStrip(EntityListener):
    def __init__(self, *args, strings=[], effects={}, **kwargs):
        super().__init__(*args, **kwargs)
        self.strings = strings
        self.num_pixels = sum([s[1] for s in strings])
        self.effects = effects

        self.current_effect_name = None
        self.current_effect = StaticEffect(count=self.num_pixels)
        self.white_brightness = 0.0
        self.color_brightness = 0.0

    async def handle(self, key, message):
        if type(message) != LightStateResponse:
            return

        await self.device.log(1, f"message.effect: '{message.effect}'")

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

    def render(self):
        pixels = []

        for i in range(self.num_pixels):
            color = self.current_effect.pixels[i]

            pixel = [
                int(color[0] * 255.0 * self.color_brightness),
                int(color[1] * 255.0 * self.color_brightness),
                int(color[2] * 255.0 * self.color_brightness),
                int(color[3] * 255.0 * self.white_brightness),
            ]

            pixels.append(pixel)

        # partition strings
        # write to each string
        cur = 0
        for string, length in self.strings:
            last = cur + length - 1
            string.write(pixels[cur:last])
            cur = last + 1

    async def run(self):
        while True:
            self.current_effect.next_frame()
            self.render()
            await asyncio.sleep(1/24.0)


device = Device(
    name = "Garage Stuff",
    mac_address = "7E:85:BA:7E:38:07",
    model = "Garage Stuff"
)

device.add_entity(LightEntity(
    name="Front Lights",
    color_modes=[LightColorCapability.ON_OFF | LightColorCapability.BRIGHTNESS | LightColorCapability.RGB | LightColorCapability.WHITE],
    effects=["Static", "Twinkle"],
))

def make_twinkle_effect(count, state):
    return BlendEffect(
        TwinkleEffect(count=count, include_white_channel=True),
        StaticEffect(count=count, color=[state.red, state.green, state.blue, state.white], include_white_channel=True),
        mode='lighten',
        include_white_channel=True,
    )

device.add_entity(LightStrip(
    name = "_front_lights_strip",
    entity_id = "front_lights",
    strings = [(WS2812B(23, slot = 0, rgbw = True, color_order="GRBW"), 1)],
    effects={
        "Static": lambda count, state: StaticEffect(count=count, color=[state.red, state.green, state.blue, state.white], include_white_channel=True),
        "Twinkle": make_twinkle_effect,
    },
))

asyncio.run(device.run())
