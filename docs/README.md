[![MSX](msx-logo.png)](#)

---

[![Active Development](https://img.shields.io/badge/Maintenance%20Level-Actively%20Developed-brightgreen.svg)](#status-of-features)
[![Build](https://github.com/opengateware/computer-msx/actions/workflows/build-pocket.yml/badge.svg)](https://github.com/opengateware/computer-msx/actions/workflows/build-pocket.yml)
[![release](https://img.shields.io/github/release/opengateware/computer-msx.svg)](https://github.com/opengateware/computer-msx/releases)
[![license](https://img.shields.io/github/license/opengateware/computer-msx.svg?label=License&color=yellow)](#legal-notices)
[![issues](https://img.shields.io/github/issues/opengateware/computer-msx.svg?label=Issues&color=red)](https://github.com/opengateware/computer-msx/issues)
[![stars](https://img.shields.io/github/stars/opengateware/computer-msx.svg?label=Project%20Stars)](https://github.com/opengateware/computer-msx/stargazers)
[![discord](https://img.shields.io/discord/676418475635507210.svg?logo=discord&logoColor=white&label=Discord&color=5865F2)](https://chat.raetro.org)
[![Twitter Follow](https://img.shields.io/twitter/follow/marcusjordan?style=social)](https://twitter.com/marcusjordan)

## MSX Compatible Gateware IP Core

This Implementation of a compatible [MSX] home computer hardware in HDL is the work of [Molekula].

## Overview

The MSX, launched by ASCII Corporation and Microsoft in 1983, aimed to standardize the home computer market, akin to the VHS format for video. Despite its ambitious goals, the MSX found regional success, particularly in Asia, South America, Europe, and the former Soviet Union, but remained largely unknown in the United States. Its architecture, featuring a Zilog Z80A CPU and TMS9918 video processor, made it a versatile platform for both education and gaming.

The acronym "MSX" has sparked much debate over its meaning. Initially, many interpreted it as "Microsoft Extended," a nod to its built-in Microsoft eXtended BASIC. However, Kazuhiko Nishi, a key figure behind the MSX, offered various interpretations over the years, including "Machines with Software Exchangeability" and references to major electronics companies Matsushita (Panasonic) and Sony. Nishi's vision was for a name that signified the system's next-generation capabilities and its association with leading tech giants.

Despite not achieving its goal of global standardization, the MSX left a lasting legacy in the realms of computing and gaming. Before the dominance of Nintendo's gaming consoles, the MSX was a preferred platform for pioneering game developers. The system's versatile architecture and software library made it a beloved platform among enthusiasts, maintaining a dedicated community and influencing generations of users and creators.

## Technical specifications

- **Main CPU:** Zilog Z80 @ 3.579545 MHz
- **Sound Chip:** AY-3-8912 @ 1.789772 MHz
- **Video Resolution:** 256×192 pixels @ 5.369317 MHz
- **Aspect Ratio:** 4:3
- **Video Processor:** TMS9918 or TMS9928 Video Display Processor (VDP)
- **Memory:** 64kB of RAM, expandable through the use of cartridge slots and external peripherals
- **Storage:** Supports floppy disk, cassette tape and cartridge-based storage

## Features

- Reference Model: Philips VG8020/00
- Video Support: NTSC/PAL
- Input: Joystick, Joy2Key and Keyboard
- Sound: Yamaha YM2149 (SSG)
- Memory: 64kB RAM in Slot 3
- Expansion: 2 Cartridge Slots (`.ROM`)
- Supported Mappers:
  - Auto/Mirrored
  - GameMaster2
  - Konami
  - Konami SCC
  - ASCII8
  - ASCII16
  - Linear64k
  - R-TYPE
- BIOS: Supports different BIOS and Hangul BASIC via FWBIOS, by default will use [C-BIOS]

### Status of Features (Not Yet Implemented)

- [ ] Floppy Disk Support (`.DSK`)
- [ ] Cassette Support (`.CAS`)
- [ ] On-Screen Keyboard

## Compatible Platforms

- Analogue Pocket

## Usage

MSX1 ROMs and BIOS should be placed in `/Assets/msx/common`.

C-BIOS is not a real BIOS rom and has certain restrictions, such as no support for anything other then cartridges (ROMs). So there is no support for disk, cassette or games that required BASIC.

## Memory limitations

- Slot 1 ROM image max size 4MB
- Slot 2 ROM image max size 4MB
- Slot 3 64Kb RAM

## Credits and acknowledgment

- [Molekula]
- [Daniel Wallner](https://opencores.org/projects/t80)
- [Jose Tejada](https://github.com/jotego)
- Arnim Laeuger
- Kazuhiro Tsujikawa
- Alexey Melnikov
- Viacheslav Slavinsky
- Patrick van Arkel

## Powered by Open-Source Software

This project borrowed and use code from several other projects. A great thanks to their efforts!

| Modules   | Copyright/Developer     |
| :-------- | :---------------------- |
| [MSX RTL] | 2022 (c) Molekula       |
| [T80]     | 2001 (c) Daniel Wallner |
| VDP18     | 2006 (c) Arnim Laeuger  |
| [JT49]    | 2018 (c) Jose Tejada    |
| [JT8255]  | 2021 (c) Jose Tejada    |
| [C-BIOS]  | 2001 (c) C-BIOS Team    |

## License

This work is licensed under multiple licenses.

- All original source code is licensed under [GNU General Public License v3.0 or later] unless implicit indicated.
- All documentation is licensed under [Creative Commons Attribution Share Alike 4.0 International] Public License.
- Some configuration and data files are licensed under [Creative Commons Zero v1.0 Universal].

Open Gateware and any contributors reserve all others rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel or otherwise.

Individual files may contain the following SPDX license tags as a shorthand for the above copyright and warranty notices:

```text
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-License-Identifier: CC0-1.0
```

This eases machine processing of licensing information based on the SPDX License Identifiers that are available at <https://spdx.org/licenses/>.

## Legal Notices

The Open Gateware authors and contributors or any of its maintainers are in no way associated with or endorsed by  ASCII Corporation, Microsoft or any other company not implicit indicated.
All other brands or product names are the property of their respective holders.

[Molekula]: https://github.com/tdlabac
[MSX]: https://en.wikipedia.org/wiki/MSX

[MSX RTL]: https://github.com/tdlabac/MSX1_MiSTer
[T80]: https://opencores.org/projects/t80
[JT49]: https://github.com/jotego/jt49
[JT8255]: https://github.com/jotego/jt8255/
[C-BIOS]: https://cbios.sourceforge.net/

[GNU General Public License v3.0 or later]: https://spdx.org/licenses/GPL-3.0-or-later.html
[Creative Commons Attribution Share Alike 4.0 International]: https://spdx.org/licenses/CC-BY-SA-4.0.html
[Creative Commons Zero v1.0 Universal]: https://spdx.org/licenses/CC0-1.0.html
