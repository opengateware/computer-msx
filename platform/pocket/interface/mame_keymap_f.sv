//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// PS/2 Keyboard to MAME Key Mapping
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
//
// key bitmap:
//
// | Gamepad   | Start       | Coinage    |
// | --------- | ----------- | ---------- |
// | [0] up    | [0] start 1 | [0] coin 1 |
// | [1] down  | [1] start 2 | [1] coin 2 |
// | [2] left  | [2] start 3 | [2] coin 3 |
// | [3] right | [3] start 4 | [3] coin 4 |
// | [4] btn_1 |             |            |
// | [5] btn_2 |             |            |
// | [6] btn_3 |             |            |
// | [7] btn_4 |             |            |
//
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module mame_keymap_f
    (
        // Clock and Reset
        input  wire        clk,
        input  wire        reset,
        // PS/2 Interface
        input  wire [10:0] ps2_key,
        // Gamepad Interface
        // Start 1,2,3,4
        output  reg        kb1_start,  kb2_start,  kb3_start, kb4_start,
        // Coin  1,2,3,4
        output  reg        kb1_coin,   kb2_coin,   kb3_coin,  kb4_coin,
        // Service Control
        output  reg        kb_pause,   kb_tilt,    kb_test,   kb_reset,
        output  reg        kb_service,
        // Player 1
        output  reg        kb1_up,     kb1_down,   kb1_left,  kb1_right,  //! Directional Pad
        output  reg        kb1_btn1,   kb1_btn2,   kb1_btn3,  kb1_btn4,   //! Y/B/A/X
        output  reg        kb1_btn5,   kb1_btn6,                          //! L/R / Coin P1 / P1 Start
        // Player 2
        output  reg        kb2_up,     kb2_down,   kb2_left,  kb2_right,  //! Directional Pad
        output  reg        kb2_btn1,   kb2_btn2,   kb2_btn3,  kb2_btn4,   //! Y/B/A/X
        output  reg        kb2_btn5,   kb2_btn6,                          //! L/R / Coin P2 / P2 Start
        // Player 3
        output  reg        kb3_up,     kb3_down,   kb3_left,  kb3_right,  //! Directional Pad
        output  reg        kb3_btn1,   kb3_btn2,   kb3_btn3,  kb3_btn4,   //! Y/B/A/X
        output  reg        kb3_btn5,   kb3_btn6,                          //! L/R / Coin P3 / P3 Start
        // Player 4
        output  reg        kb4_up,     kb4_down,   kb4_left,  kb4_right,  //! Directional Pad
        output  reg        kb4_btn1,   kb4_btn2,   kb4_btn3,  kb4_btn4,   //! Y/B/A/X
        output  reg        kb4_btn5,   kb4_btn6                           //! L/R / Coin P4 / P4 Start
    );

    wire pressed = ps2_key[9];

    always_ff @(posedge clk) begin
        reg old_state;
        if (reset) begin
            // start   <= 4'h0;
            // coin    <= 4'h0;
            // pause   <= 1'h0;
            // player1 <= 8'h0;
            // player2 <= 8'h0;
            // player3 <= 8'h0;
            // player4 <= 8'h0;
        end
        else begin
            old_state <= ps2_key[10];
            if(old_state ^ ps2_key[10]) begin
                case(ps2_key[8:0])
                    // Service Control
                    9'h04D: kb_pause   <= pressed; // P
                    9'h02C: kb_tilt    <= pressed; // T
                    9'h006: kb_test    <= pressed; // F2
                    9'h004: kb_reset   <= pressed; // F3
                    9'h046: kb_service <= pressed; // 9
                    // Start
                    9'h016: kb1_start  <= pressed; // 1
                    9'h01E: kb2_start  <= pressed; // 2
                    9'h026: kb3_start  <= pressed; // 3
                    9'h025: kb4_start  <= pressed; // 4
                    // Coinage
                    9'h02E: kb1_coin   <= pressed; // 5
                    9'h036: kb2_coin   <= pressed; // 6
                    9'h03D: kb3_coin   <= pressed; // 7
                    9'h03E: kb4_coin   <= pressed; // 8
                    // Player 1
                    9'h175: kb1_up     <= pressed; // Up
                    9'h172: kb1_down   <= pressed; // Down
                    9'h16B: kb1_left   <= pressed; // Left
                    9'h174: kb1_right  <= pressed; // Right
                    9'h014: kb1_btn1   <= pressed; // Left Ctrl
                    9'h011: kb1_btn2   <= pressed; // Left Alt
                    9'h029: kb1_btn3   <= pressed; // Space
                    9'h012: kb1_btn4   <= pressed; // Left Shift
                    9'h01A: kb1_btn5   <= pressed; // Z
                    9'h022: kb1_btn6   <= pressed; // X
                    // Player 2
                    9'h02D: kb2_up     <= pressed; // R
                    9'h02B: kb2_down   <= pressed; // F
                    9'h023: kb2_left   <= pressed; // D
                    9'h034: kb2_right  <= pressed; // G
                    9'h01C: kb2_btn1   <= pressed; // A
                    9'h01B: kb2_btn2   <= pressed; // S
                    9'h015: kb2_btn3   <= pressed; // Q
                    9'h01D: kb2_btn4   <= pressed; // W
                    // Player 3
                    9'h043: kb3_up     <= pressed; // I
                    9'h042: kb3_down   <= pressed; // K
                    9'h03B: kb3_left   <= pressed; // J
                    9'h04B: kb3_right  <= pressed; // L
                    9'h114: kb3_btn1   <= pressed; // Right Ctrl
                    9'h059: kb3_btn2   <= pressed; // Right Shift
                    9'h05A: kb3_btn3   <= pressed; // Enter
                    // Player 4
                    9'h075: kb4_up     <= pressed; // Keypad 8 and Up Arrow
                    9'h072: kb4_down   <= pressed; // Keypad 2 and Down Arrow
                    9'h06B: kb4_left   <= pressed; // Keypad 4 and Left Arrow
                    9'h074: kb4_right  <= pressed; // Keypad 6 and Right Arrow
                    9'h070: kb4_btn1   <= pressed; // Keypad 0 and Insert
                    9'h071: kb4_btn2   <= pressed; // Keypad . and Delete
                    9'h15A: kb4_btn3   <= pressed; // Keypad ENTER
                endcase
            end
        end
    end

endmodule
