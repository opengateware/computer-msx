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
// Analogue Pocket Dock USB Notes:
//
// Mouse:
// Because mouse input data is report/event based (using deltas instead of
// absolute coordinates), a 16-bit counter is used to identify each unique
// report, and incremented each time a new report is sent.
// A comparator can be used against the current and previous counter value
// to detect new events.
// 
// In the mouse data are X position delta, Y position delta,
// up to 8 buttons, and the report counter.
// Buttons, starting at bit 0 with left, right, middle, etc.
//
// | Register bit range | Function                 |
// | :----------------- | :----------------------- |
// | cont4_joy[31:16]   | Buttons                  |
// | cont4_joy[15:0]    | Relative X movement (LE) |
// | cont4_key[15:0]    | Report counter (LE)      |
// | cont4_trig[15:0]   | Relative Y movement (LE) |
//
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module usb_mouse
    (
        // Clock and Reset
        input  logic               clk,               // System Clock
        input  logic               reset,             // Reset
        // APF Mouse
        input  logic        [31:0] cont4_key,         // Keypad
        input  logic        [31:0] cont4_joy,         // Joystick
        input  logic        [15:0] cont4_trig,        // Trigger
        // USB Mouse
        output logic               mouse_left_btn,    // Mouse Left Button
        output logic               mouse_middle_btn,  // Mouse Right Button
        output logic               mouse_right_btn,   // Mouse Middle Button
        output logic signed [15:0] mouse_dx,          // Mouse X
        output logic signed [15:0] mouse_dy,          // Mouse Y
        // PS/2 Interface
        output logic        [24:0] ps2_mouse = 25'h0  // [24] - toggles with every event
    );

    // Mouse Internal Logic
    wire        [15:0] mouse_report_counter = {cont4_key[7:0], cont4_key[15:8]};
    wire         [7:0] mouse_buttons;
    wire signed [15:0] mouse_pointer_x;
    wire signed [15:0] mouse_pointer_y;

    // USB Mouse Check
    wire         [3:0] key_type;
    wire               is_mouse = (key_type == 4'h5) ? 1'b1 : 1'b0; // APF Input Type

    synch_3 #(.WIDTH(4))  sync_mt( cont4_key[31:28],                   key_type,        clk);
    synch_3 #(.WIDTH(8))  sync_mb( cont4_joy[23:16],                   mouse_buttons,   clk);
    synch_3 #(.WIDTH(16)) sync_mx({cont4_joy[7:0],   cont4_joy[15:8]}, mouse_pointer_x, clk);
    synch_3 #(.WIDTH(16)) sync_my({cont4_trig[7:0], cont4_trig[15:8]}, mouse_pointer_y, clk);

    assign mouse_left_btn   = mouse_buttons[0];
    assign mouse_right_btn  = mouse_buttons[1];
    assign mouse_middle_btn = mouse_buttons[2];
    assign mouse_dx         = mouse_pointer_x;
    assign mouse_dy         = mouse_pointer_y;

endmodule
