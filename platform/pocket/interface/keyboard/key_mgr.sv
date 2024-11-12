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

module key_mgr
    (
        input  wire        clk,         //! System Clock
        input  wire        reset,       //! Reset
        input  wire  [3:0] key_idx,     //! Key Index
        input  wire  [8:0] scancode,    //! Key Scan Code
        output logic       key_strobe,  //! Key Data Valid
        output logic       key_pressed, //! 1: Make (Pressed) | 0: Break (Released)
        output logic [8:0] key_code     //! Key Scan Code
    );

    //! ------------------------------------------------------------------------
    //! Scancode Storage
    //! ------------------------------------------------------------------------
    reg  [8:0] scancode_last[0:15];
    reg  [8:0] scancode_saved[0:15];
    reg [15:0] save_scancode;

    reg        key_strobe_array[0:15];
    reg        key_pressed_array[0:15];
    reg  [8:0] key_code_array[0:15];
    reg        key_strobe_array_reg[0:15];
    reg        key_pressed_array_reg[0:15];
    reg  [8:0] key_code_array_reg[0:15];
    reg [15:0] save_scancode_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 16; i++) begin
                scancode_last[i]  <= 9'h0;
                scancode_saved[i] <= 9'h0;
            end
        end
        else begin
            for (int i = 0; i < 16; i++) begin
                if (key_idx == i[3:0]) begin
                    scancode_last[i]  <= scancode;
                    scancode_saved[i] <= (save_scancode[i]) ? scancode : scancode_saved[i];
                end
            end
        end
    end

    //! ------------------------------------------------------------------------
    //! Key State
    //! ------------------------------------------------------------------------
    typedef enum {IDLE, SAVE, PRESS, HOLD_RELEASE} KeyState;
    KeyState current_state[0:15], next_state[0:15];

    //! ------------------------------------------------------------------------
    //! Key Conditions
    //! ------------------------------------------------------------------------
    wire key_make    = (scancode != scancode_last[key_idx]) && (scancode != 9'h0) || ( |scancode & ~|scancode_last[key_idx]);
    wire key_break   = (scancode != scancode_last[key_idx]) && (scancode == 9'h0) || (~|scancode &  |scancode_last[key_idx]);
    wire key_changed = (scancode != scancode_last[key_idx]);

    //! ------------------------------------------------------------------------
    //! State Machine Controller
    //! ------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 16; i++) begin
                current_state[i]         <= IDLE;
                save_scancode_reg[i]     <= 0;
                key_code_array_reg[i]    <= 0;
                key_pressed_array_reg[i] <= 0;
                key_strobe_array_reg[i]  <= 0;
            end
        end
        else begin
            for (int i = 0; i < 16; i++) begin
                if (key_idx == i[3:0]) begin
                    current_state[i]         <= next_state[i];
                    save_scancode_reg[i]     <= save_scancode[i];
                    key_code_array_reg[i]    <= key_code_array[i];
                    key_pressed_array_reg[i] <= key_pressed_array[i];
                    key_strobe_array_reg[i]  <= key_strobe_array[i];
                end
            end
        end
    end

    //! ------------------------------------------------------------------------
    //! State Machine Logic
    //! ------------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < 16; i++) begin
            if (key_idx == i[3:0]) begin
                next_state[i]        = current_state[i];
                save_scancode[i]     = 1'b0;
                key_code_array[i]    = 9'h0;
                key_pressed_array[i] = 1'b0;
                key_strobe_array[i]  = 1'b0;

                case (current_state[i])
                    IDLE: begin
                        next_state[i] = (key_make) ? SAVE : IDLE;
                    end
                    SAVE: begin
                        save_scancode[i] = 1'b1;
                        next_state[i]    = PRESS;
                    end
                    PRESS: begin
                        key_code_array[i]    = scancode_saved[i];
                        key_pressed_array[i] = 1'b1;
                        key_strobe_array[i]  = 1'b1;
                        next_state[i]        = HOLD_RELEASE;
                    end
                    HOLD_RELEASE: begin
                        key_code_array[i]    =   scancode_saved[i];
                        key_pressed_array[i] = ~(key_break || key_changed);
                        key_strobe_array[i]  =  (key_break || key_changed);
                        next_state[i]        =  (key_break)   ? IDLE :
                                                (key_changed) ? SAVE : HOLD_RELEASE;
                    end
                    default: begin
                        next_state[i]  = IDLE;
                    end
                endcase
            end
            else begin
                next_state[i]        = current_state[i];
                save_scancode[i]     = save_scancode_reg[i];
                key_code_array[i]    = key_code_array_reg[i];
                key_pressed_array[i] = key_pressed_array_reg[i];
                key_strobe_array[i]  = key_strobe_array_reg[i];
            end
        end
    end

    assign key_code    = key_code_array[key_idx];
    assign key_pressed = key_pressed_array[key_idx];
    assign key_strobe  = key_strobe_array[key_idx];

endmodule
