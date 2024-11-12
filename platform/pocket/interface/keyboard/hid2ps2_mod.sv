//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket USB HID Keyboard/Mouse and PS/2 Scan Code Translation
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module hid2ps2_mod
    (
        input  logic        clk,
        input  logic  [7:0] usb,
        output logic [71:0] ps2
    );

    always_ff @(posedge clk) begin : modScancode
        ps2[71:63] <= (usb[0]) ? 9'h014 : 9'h00; // Left Control
        ps2[62:54] <= (usb[1]) ? 9'h012 : 9'h00; // Left Shift
        ps2[53:45] <= (usb[2]) ? 9'h011 : 9'h00; // Left Alt
        ps2[44:36] <= (usb[3]) ? 9'h11F : 9'h00; // Left GUI
        ps2[35:27] <= (usb[4]) ? 9'h114 : 9'h00; // Right Control
        ps2[26:18] <= (usb[5]) ? 9'h059 : 9'h00; // Right Shift
        ps2[17:09] <= (usb[6]) ? 9'h111 : 9'h00; // Right Alt
        ps2[08:00] <= (usb[7]) ? 9'h127 : 9'h00; // Right GUI
    end

endmodule
