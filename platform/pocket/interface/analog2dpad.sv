//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket Analogue Joystick to DPAD Controller
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
//    Uy    |        0x00
// Lx ++ Rx | 0x00 > 0x80 < 0xFF
//    Dy    |        0xFF
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module analog2dpad
    #(
         parameter   [7:0] CENTER   = 8'h80,    //! Analog Center Value
         parameter   [7:0] DEADZONE = 8'h10     //! Set Controller Deadzone
     ) (
        input  logic       clk_sys,             //! System Clock
        input  logic [3:0] pad_type,            //! System Clock
        input  logic [7:0] joy_lx,   joy_ly,    //! Left Analog X/Y
        input  logic [7:0] joy_rx,   joy_ry,    //! Right Analog X/Y
        output logic       joy_up,   joy_down,  //! D-PAD Signals
        output logic       joy_left, joy_right  //! D-PAD Signals
    );

    //! ------------------------------------------------------------------------
    //! Analog Stick
    //! ------------------------------------------------------------------------
    logic ljoy_u, ljoy_d, ljoy_l, ljoy_r;
    logic rjoy_u, rjoy_d, rjoy_l, rjoy_r;

    always_ff @(posedge clk_sys) begin
        //! Left Analog Stick
        ljoy_l <= (joy_lx < (CENTER - DEADZONE));
        ljoy_r <= (joy_lx > (CENTER + DEADZONE));
        ljoy_u <= (joy_ly < (CENTER - DEADZONE));
        ljoy_d <= (joy_ly > (CENTER + DEADZONE));
        //! Right Analog Stick
        rjoy_l <= (joy_rx < (CENTER - DEADZONE));
        rjoy_r <= (joy_rx > (CENTER + DEADZONE));
        rjoy_u <= (joy_ry < (CENTER - DEADZONE));
        rjoy_d <= (joy_ry > (CENTER + DEADZONE));
    end

    //! ------------------------------------------------------------------------
    //! Combine Left or Right Analog Stick into DPAD
    //! ------------------------------------------------------------------------
    assign joy_left  = (pad_type == 4'h3) ? (ljoy_l | rjoy_l) : 1'b0;
    assign joy_right = (pad_type == 4'h3) ? (ljoy_r | rjoy_r) : 1'b0;
    assign joy_up    = (pad_type == 4'h3) ? (ljoy_u | rjoy_u) : 1'b0;
    assign joy_down  = (pad_type == 4'h3) ? (ljoy_d | rjoy_d) : 1'b0;

endmodule
