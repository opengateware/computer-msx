//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket USB HID Keyboard/Mouse and PS/2 Scan Code Translation
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2023, Jacob Boline <mail@jboline.me>
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

module key_ctl
    (
        input  logic       clk,          //! System Clock
        input  logic       reset,        //! Reset
        input  logic [3:0] key_idx,      //! Key Index
        input  logic [8:0] scancode,     //! Key Scan Code
        output logic       key_strobe,   //! Key Data Valid
        output logic       key_pressed,  //! 1: Make (Pressed) | 0: Break (Released)
        output logic [8:0] key_code      //! Key Scan Code
    );

    //! ------------------------------------------------------------------------
    //! Scancode Storage
    //! ------------------------------------------------------------------------
    reg [8:0] scancode_last, scancode_saved;
    reg       save_scancode;

    always_ff @(posedge clk) begin : scancodeStorage
        scancode_last  <= scancode;
        scancode_saved <= (save_scancode) ? scancode : scancode_saved;
    end

    //! ------------------------------------------------------------------------
    //! Key State
    //! ------------------------------------------------------------------------
    typedef enum {IDLE, SAVE, PRESS, HOLD_RELEASE} KeyState;
    KeyState current_state, next_state;

    //! ------------------------------------------------------------------------
    //! Key Conditions
    //! ------------------------------------------------------------------------
    wire key_make    = (scancode != scancode_last) && (scancode != 9'h0) || ( |scancode & ~|scancode_last);
    wire key_break   = (scancode != scancode_last) && (scancode == 9'h0) || (~|scancode &  |scancode_last);
    wire key_changed = (scancode != scancode_last);

    //! ------------------------------------------------------------------------
    //! State Machine Controller
    //! ------------------------------------------------------------------------
    always_ff @(posedge clk) begin : scancodeFSMControl
        current_state  <= (reset) ? IDLE : next_state;
    end

    always_comb begin : scancodeFSM
        next_state    = current_state;
        save_scancode = 1'b0;
        key_code      = 9'h0;
        key_pressed   = 1'b0;
        key_strobe    = 1'b0;

        case (current_state)
            IDLE: begin
                next_state = (key_make) ? SAVE : IDLE;
            end
            SAVE: begin
                save_scancode = 1'b1;
                next_state    = PRESS;
            end
            PRESS: begin
                key_code    = scancode_saved;
                key_pressed = 1'b1;
                key_strobe  = 1'b1;
                next_state  = HOLD_RELEASE;
            end
            HOLD_RELEASE: begin
                key_code    =   scancode_saved;
                key_pressed = ~(key_break || key_changed);
                key_strobe  =  (key_break || key_changed);
                next_state  =  (key_break)   ? IDLE :
                               (key_changed) ? SAVE : HOLD_RELEASE;
            end
            default: begin
                next_state  = IDLE;
            end
        endcase
    end

endmodule
