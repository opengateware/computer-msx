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

module usb_keyboard
    (
        // Clock and Reset
        input  logic        clk,            //! Clock
        input  logic        clk_sync,       //! Clock
        input  logic        reset,          //! Reset
        // APF Keyboard Port
        input  logic [31:0] cont3_key,      //! Modifiers/Input Type
        input  logic [31:0] cont3_joy,      //! Scan code 1-4
        input  logic [15:0] cont3_trig,     //! Scan code 5-6
        // USB Keyboard Output
        output logic [63:0] usb_kb_hid,     //! 64-bit HID Report
        output logic  [7:0] usb_kb_mod,     //! Modifiers
        output logic  [7:0] usb_kb_sc1,     //! Scan Code 1
        output logic  [7:0] usb_kb_sc2,     //! Scan Code 2
        output logic  [7:0] usb_kb_sc3,     //! Scan Code 3
        output logic  [7:0] usb_kb_sc4,     //! Scan Code 4
        output logic  [7:0] usb_kb_sc5,     //! Scan Code 5
        output logic  [7:0] usb_kb_sc6,     //! Scan Code 6
        // PS/2 Keyboard Output
        output logic [10:0] ps2_key = 11'h0 //! PS/2 Keyboard
    );

    //! ------------------------------------------------------------------------
    //! APF to USB HID
    //! ------------------------------------------------------------------------
    apf2hid u_apf2hid
            (
                .clk        ( clk        ),
                .reset      ( reset      ),
                .cont3_key  ( cont3_key  ),
                .cont3_joy  ( cont3_joy  ),
                .cont3_trig ( cont3_trig ),
                .usb_kb_hid ( usb_kb_hid ),
                .usb_kb_mod ( usb_kb_mod ),
                .usb_kb_sc1 ( usb_kb_sc1 ),
                .usb_kb_sc2 ( usb_kb_sc2 ),
                .usb_kb_sc3 ( usb_kb_sc3 ),
                .usb_kb_sc4 ( usb_kb_sc4 ),
                .usb_kb_sc5 ( usb_kb_sc5 ),
                .usb_kb_sc6 ( usb_kb_sc6 )
            );

    //! ------------------------------------------------------------------------
    //! Translate USB HID ID to PS/2 Scancode
    //! ------------------------------------------------------------------------
    logic [53:0] ps2_keys;
    logic [71:0] ps2_mods;

    hid2ps2_mod u_key_mod (.clk(~clk), .usb(usb_kb_mod), .ps2(ps2_mods));
    hid2ps2_key u_key_sc1 (.clk(~clk), .usb(usb_kb_sc1), .ps2(ps2_keys[53:45]));
    hid2ps2_key u_key_sc2 (.clk(~clk), .usb(usb_kb_sc2), .ps2(ps2_keys[44:36]));
    hid2ps2_key u_key_sc3 (.clk(~clk), .usb(usb_kb_sc3), .ps2(ps2_keys[35:27]));
    hid2ps2_key u_key_sc4 (.clk(~clk), .usb(usb_kb_sc4), .ps2(ps2_keys[26:18]));
    hid2ps2_key u_key_sc5 (.clk(~clk), .usb(usb_kb_sc5), .ps2(ps2_keys[17:09]));
    hid2ps2_key u_key_sc6 (.clk(~clk), .usb(usb_kb_sc6), .ps2(ps2_keys[08:00]));

    //! ------------------------------------------------------------------------
    //! PS/2 Keyboard FIFO
    //! ------------------------------------------------------------------------
    logic [125:0] fifo_dout;
    logic         fifo_empty;
    logic         fifo_rd;

    kb_fifo u_fifo
            (
                .clk   ( clk                  ),
                .reset ( reset                ),
                .din   ( {ps2_mods, ps2_keys} ),
                .rd_en ( fifo_rd              ),
                .empty ( fifo_empty           ),
                .dout  ( fifo_dout            )
            );

    //! ------------------------------------------------------------------------
    //! PS/2 FIFO Scancode Arbiter
    //! ------------------------------------------------------------------------
    logic [8:0] scancode;
    logic [3:0] key_idx;

    key_arbiter u_key_arbiter
                (
                    .clk        ( clk         ),
                    .reset      ( reset       ),
                    .fifo_ready ( ~fifo_empty ),
                    .fifo_din   ( fifo_dout   ),
                    .fifo_rd    ( fifo_rd     ),
                    .key_idx    ( key_idx     ),
                    .scancode   ( scancode    )
                );

    //! ------------------------------------------------------------------------
    //! PS/2 Key Controller
    //! ------------------------------------------------------------------------
    logic       strobe;
    logic       pressed;
    logic [8:0] key_code;

    key_mgr u_key_ctl
            (
                .clk         ( clk      ),
                .reset       ( reset    ),
                .key_idx     ( key_idx  ),
                .scancode    ( scancode ),
                .key_strobe  ( strobe   ),
                .key_pressed ( pressed  ),
                .key_code    ( key_code )
            );

    assign ps2_key = {strobe, pressed, key_code};

endmodule
