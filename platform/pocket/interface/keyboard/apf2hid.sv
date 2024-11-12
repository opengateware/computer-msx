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

module apf2hid
    (
        // Clock and Reset
        input  logic        clk,        //! Clock
        input  logic        reset,      //! Reset
        // APF Keyboard Port
        input  logic [31:0] cont3_key,  //! Modifiers/Input Type
        input  logic [31:0] cont3_joy,  //! Scan code 1-4
        input  logic [15:0] cont3_trig, //! Scan code 5-6
        // USB Keyboard Output
        output logic [63:0] usb_kb_hid, //! 64-bit HID Report
        output logic  [7:0] usb_kb_mod, //! Modifiers
        output logic  [7:0] usb_kb_sc1, //! Scan Code 1
        output logic  [7:0] usb_kb_sc2, //! Scan Code 2
        output logic  [7:0] usb_kb_sc3, //! Scan Code 3
        output logic  [7:0] usb_kb_sc4, //! Scan Code 4
        output logic  [7:0] usb_kb_sc5, //! Scan Code 5
        output logic  [7:0] usb_kb_sc6  //! Scan Code 6
    );

    // USB Keyboard Check
    reg  [3:0] key_type, key_type_s1, key_type_s2;
    wire       is_keyboard = (key_type == 4'h4) ? 1'b1 : 1'b0; // APF Keyboard Check

    always_ff @(posedge clk) begin : syncType
        {key_type, key_type_s2, key_type_s1} <= {key_type_s2, key_type_s1, cont3_key[31:28]};
    end

    // USB HID Scancodes/Key Modifiers
    wire  [7:0] usb_kb_res    = 8'h00;                                                             // HID Report Reserved
    wire [63:0] apf_scancodes = {cont3_key[15:8], usb_kb_res, cont3_joy[31:0], cont3_trig[15:0]};  // APF HID Scancodes/Key Modifiers
    reg  [63:0] kb_scancodes, kb_scancodes_s1, kb_scancodes_s2;

    always_ff @(posedge clk) begin : syncKey
        kb_scancodes    <= kb_scancodes_s2;
        kb_scancodes_s2 <= kb_scancodes_s1;
        kb_scancodes_s1 <= apf_scancodes;
    end

    // USB Keyboard Output
    assign usb_kb_hid = is_keyboard ? kb_scancodes        : 64'h00; // HID Report
    assign usb_kb_mod = is_keyboard ? kb_scancodes[63:56] : 8'h00;  // Modifier keys
    assign usb_kb_sc1 = is_keyboard ? kb_scancodes[47:40] : 8'h00;  // Keycode 1
    assign usb_kb_sc2 = is_keyboard ? kb_scancodes[39:32] : 8'h00;  // Keycode 2
    assign usb_kb_sc3 = is_keyboard ? kb_scancodes[31:24] : 8'h00;  // Keycode 3
    assign usb_kb_sc4 = is_keyboard ? kb_scancodes[23:16] : 8'h00;  // Keycode 4
    assign usb_kb_sc5 = is_keyboard ? kb_scancodes[15:08] : 8'h00;  // Keycode 5
    assign usb_kb_sc6 = is_keyboard ? kb_scancodes[07:00] : 8'h00;  // Keycode 6

endmodule
