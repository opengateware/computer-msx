//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket Gamepad Controller
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
// Shift joystick interface through 3-stages of registers and output the
// synchronized signal
//
// The value of cont_key is transferred to pkey_s1.
// The value of pkey_s1 (from the previous clock cycle) is transferred to pkey_s2.
// The value of pkey_s2 (from two clock cycles ago) is transferred to pkey_s,
// which is in the target clock domain.
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module joypad
    #(
         parameter DEADZONE = 8'h10                                 //! Set Controller Deadzone
     ) (
         input  wire        clk_sys,                                //! Clock to Sync To (eg: clk_sys)
         // Pocket PAD Interface
         input  wire [31:0] cont_key, cont_joy,                     //! Gamepad/Analog Joystick
         // DPAD
         output wire        key_up,  key_down, key_left, key_right, //! D-PAD
         output wire        key_a,   key_b,    key_x,    key_y,     //! Face Buttons
         output wire        key_l1,  key_l2,   key_l3,              //! Left  Shoulder/Trigger/Analog Buttons
         output wire        key_r1,  key_r2,   key_r3,              //! Right Shoulder/Trigger/Analog Buttons
         output wire        key_se,  key_st,                        //! Select and Start Buttons
         // Analog Stick
         output wire        joy_up , joy_down, joy_left, joy_right, //! Analog 2 DPAD
         output wire  [7:0] joy_lx,  joy_ly,   joy_rx,   joy_ry,    //! Left/Right Analog Stick
         // Type
         output wire  [3:0] pad_type                                //! Controller Type
     );

    //! ------------------------------------------------------------------------
    //! Gamepad
    //! ------------------------------------------------------------------------
    reg [31:0] pkey_s;           //! Synced Joystick Register
    reg [31:0] pkey_s1, pkey_s2; //! Registers for Synchronization

    always_ff @(posedge clk_sys) begin : syncKey
        {pkey_s, pkey_s2, pkey_s1} <= {pkey_s2, pkey_s1, cont_key};
    end

    // D-PAD
    assign key_up    = pkey_s[0];
    assign key_down  = pkey_s[1];
    assign key_left  = pkey_s[2];
    assign key_right = pkey_s[3];
    // Face Buttons
    assign key_y     = pkey_s[7];
    assign key_x     = pkey_s[6];
    assign key_b     = pkey_s[5];
    assign key_a     = pkey_s[4];
    // Shoulder/Trigger Buttons
    assign key_l1    = pkey_s[8];
    assign key_r1    = pkey_s[9];
    assign key_l2    = pkey_s[10];
    assign key_r2    = pkey_s[11];
    assign key_l3    = pkey_s[12];
    assign key_r3    = pkey_s[13];
    // Select and Start Buttons
    assign key_se    = pkey_s[14];
    assign key_st    = pkey_s[15];
    // Controller Type
    assign pad_type  = pkey_s[31:28];

    //! ------------------------------------------------------------------------
    //! Analog Stick
    //! ------------------------------------------------------------------------
    reg [31:0] pjoy_s;           //! Synced Analog Register
    reg [31:0] pjoy_s1, pjoy_s2; //! 2-stage register for synchronization

    // Shift joystick interface through two stages of registers and output the synchronized signal
    always_ff @(posedge clk_sys) begin : syncJoy
        {pjoy_s, pjoy_s2, pjoy_s1} <= {pjoy_s2, pjoy_s1, cont_joy};
    end

    // Analog Stick | 0x00 > 0x80 < 0xFF
    assign joy_lx = pjoy_s[7:0];
    assign joy_ly = pjoy_s[15:8];
    assign joy_rx = pjoy_s[23:16];
    assign joy_ry = pjoy_s[31:24];

    // Analog to DPAD
    analog2dpad #(.DEADZONE(DEADZONE)) analog2dpad
    (
        .clk_sys   ( clk_sys   ),
        .pad_type  ( pad_type  ),
        .joy_lx    ( joy_lx    ),
        .joy_ly    ( joy_ly    ),
        .joy_rx    ( joy_rx    ),
        .joy_ry    ( joy_ry    ),
        .joy_left  ( joy_left  ),
        .joy_right ( joy_right ),
        .joy_up    ( joy_up    ),
        .joy_down  ( joy_down  )
    );

endmodule
