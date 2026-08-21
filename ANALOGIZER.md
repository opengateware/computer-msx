# Analogizer

Analogizer is a cartridge-slot adapter for the Analogue Pocket that adds analog
video output and SNAC controller support. This core supports it through
RndMnkIII's [Analogizer](https://github.com/RndMnkIII/Analogizer) project, whose
wiki is the authority on the adapter itself.

## What we can and cannot answer

The capability lists below are RndMnkIII's, verified against his hardware. We
have not re-tested them, because no maintainer of this core owns the adapter, a
CRT, or the SNAC harnesses. Send analog video and SNAC problems to the
[Analogizer project](https://github.com/RndMnkIII/Analogizer), not to this repo.

Three things are ours, and they're the ones worth reporting here:

- **Rally-X is single player.** all Analogizer second player functionality was supressed (commented)
- **Blank the Pocket Screen** The core reads the setting out of
  `analogizer.bin` and then enable/disable blanking Pocket screen output based on this setting.
- **Cart power is on for everyone.** The adapter draws power from the cartridge
  slot, so `cartridge_adapter` in `core.json` enables it for every user whether
  they own an adapter or not. The menu option does not gate it. Do not leave a
  cartridge in the slot while running this core.

## Configuration lives in a file, not the menu

Everything except the on/off switch comes from `analogizer.bin`, not from the
Pocket's menu system. Generate it with
[Pupdate 5.6.0 or newer](https://github.com/mattpannella/pupdate/releases) or
[AnalogizerConfigurator 0.7 or newer](https://github.com/RndMnkIII/AnalogizerConfigurator/releases),
then copy it to `/Assets/analogizer/common` on the SD card, creating that folder
if it does not exist. Those utilities are where you choose the SNAC controller
type, the SNAC controller assignments that map physical pads onto the Pocket's
PAD format, the video output mode, and Blank the Pocket Screen.

Turn it on with **ANALOGIZER ENABLE OPTIONS: ON ** in Analogizer Configurator/Pupdate menu. With it off, the core
disables every Analogizer code path.

## Video output

The core can output RGBS, RGsB, YPbPr, Y/C NTSC, Y/C PAL, and an SVGA
scandoubler with 50% scanlines. The SOG switch position applies to R2 and R3
adapters only.

- **RGBS.** Supported. SOG switch off.
- **RGsB.** Supported. SOG switch on.
- **YPbPr.** Supported, tested on a Sony PVM-9044D. SOG switch on.
- **Y/C NTSC.** Supported. SOG switch off.
- **Y/C PAL.** Supported. SOG switch off.
- **Scandoubler.** Supported. SOG switch off.

Analogizer generates the encoded Y/C signal from RGB and drives it out of the
VGA port's R and G pins, redirecting CSync to the VGA HSync pin. Turning that
into S-Video or composite is the job of an external Y/C adapter on the VGA port,
which takes its 5V from VGA pin 9. Only Mike Simone's active designs have
official support:

- [MiSTerAddons Active Y/C Adapter](https://misteraddons.com/collections/parts/products/yc-active-encoder-board/)
- [MikeS11 Active VGA to Composite / S-Video](https://ultimatemister.com/product/mikes11-active-composite-svideo/)
- [Active VGA to Composite/S-Video adapter](https://antoniovillena.com/product/mikes1-vga-composite-adapter/)

Passive adapters may work to varying degrees depending on the screen. Anything
not tested against Analogizer gets no official support. Thanks to
[Mike Simone](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder) for the Y/C
encoder project this builds on.

## SNAC controllers

SNAC lets you mix inputs from a real gamepad and PS/2 keyboard and mouse with the Pocket's built-in controls,
or with a USB or wireless controller on the Dock. Supported pads, with the A/B
switch position each one needs:

- **DB15 Neo Geo.** Switch A.
- **NES.** Switch A.
- **SNES.** Switch A.
- **PC Engine.** Switch A.
- **PC Engine multitap.** Switch A. Native 2-button and 6-button pads, up to 5
  players, over the Analogizer-specific PC Engine cable harness.
- **PS/2 Keyboard & Mouse + NES One Player** Switch A.
- **PS/2 Keyboard & Mouse + SNES One Player** Switch A.
- **PS/2 Keyboard & Mouse + DB15 Two Players** Switch A.
- **PS/2 Keyboard & Mouse + No SNAC game controller** Switch A.
- **PSX DualShock / DualShock 2, digital d-pad.** Switch B.
- **PSX DualShock / DualShock 2, analog d-pad.** Switch B.

"PS/2 Keyboard & Mouse + ..." options will require a specific Analogizer PS/2 SNAC adapter that will be available soon.

Every adapter version (v1, v2, v3) has a side slide switch labelled `A B` that
has to match the controller you plugged in. PSX DualShock and DualShock 2 pads
need the B side; everything else needs the A side.

Handle that switch carefully. Use something thin and flat, like a precision
screwdriver with a 2.0 mm blade. Rest the tip on the lever and press gently until
it slides over.

```
     ---
   B|O  |A  A/B switch on position B
     ---
     ---
   B|  O|A  A/B switch on position A
     ---
```
