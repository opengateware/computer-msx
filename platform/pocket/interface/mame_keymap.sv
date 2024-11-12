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

module mame_keymap
    (
        // Clock and Reset
        input  wire        clk,
        input  wire        reset,
        // PS/2 Interface
        input  wire [10:0] ps2_key,
        // Gamepad Interface
        output  reg  [3:0] start,   //! Start 1,2,3,4
        output  reg  [3:0] coin,    //! Coin  1,2,3,4
        output  reg        pause,   //! Pause
        output  reg  [7:0] player1, //! Player 1
        output  reg  [7:0] player2, //! Player 2
        output  reg  [7:0] player3, //! Player 3
        output  reg  [7:0] player4  //! Player 4
    );

    wire pressed = ps2_key[9];

    always_ff @(posedge clk) begin
        reg old_state;
        if (reset) begin
            start   <= 4'h0;
            coin    <= 4'h0;
            pause   <= 1'h0;
            player1 <= 8'h0;
            player2 <= 8'h0;
            player3 <= 8'h0;
            player4 <= 8'h0;
        end
        else begin
            old_state <= ps2_key[10];
            if(old_state ^ ps2_key[10]) begin
                case(ps2_key[8:0])
                    9'h016: start[0]   <= pressed; // 1
                    9'h01E: start[1]   <= pressed; // 2
                    9'h026: start[2]   <= pressed; // 3
                    9'h025: start[3]   <= pressed; // 4

                    9'h02E: coin[0]    <= pressed; // 5
                    9'h036: coin[1]    <= pressed; // 6
                    9'h03D: coin[2]    <= pressed; // 7
                    9'h03E: coin[2]    <= pressed; // 8

                    9'h04D: pause      <= pressed; // P

                    9'h175: player1[0] <= pressed; // Up
                    9'h172: player1[1] <= pressed; // Down
                    9'h16B: player1[2] <= pressed; // Left
                    9'h174: player1[3] <= pressed; // Right
                    9'h014: player1[4] <= pressed; // Left Ctrl
                    9'h011: player1[5] <= pressed; // Left Alt
                    9'h029: player1[6] <= pressed; // Space
                    9'h012: player1[7] <= pressed; // Left Shift

                    9'h02D: player2[0] <= pressed; // R
                    9'h02B: player2[1] <= pressed; // F
                    9'h023: player2[2] <= pressed; // D
                    9'h034: player2[3] <= pressed; // G
                    9'h01C: player2[4] <= pressed; // A
                    9'h01B: player2[5] <= pressed; // S
                    9'h015: player2[6] <= pressed; // Q
                    9'h01D: player2[7] <= pressed; // W

                    9'h043: player3[0] <= pressed; // I
                    9'h042: player3[1] <= pressed; // K
                    9'h03B: player3[2] <= pressed; // J
                    9'h04B: player3[3] <= pressed; // L
                    9'h114: player3[4] <= pressed; // Right Ctrl
                    9'h059: player3[5] <= pressed; // Right Shift
                    9'h05A: player3[6] <= pressed; // Enter

                    9'h075: player4[0] <= pressed; // Keypad 8 and Up Arrow
                    9'h072: player4[1] <= pressed; // Keypad 2 and Down Arrow
                    9'h06B: player4[2] <= pressed; // Keypad 4 and Left Arrow
                    9'h074: player4[3] <= pressed; // Keypad 6 and Right Arrow
                    9'h070: player4[4] <= pressed; // Keypad 0 and Insert
                    9'h071: player4[5] <= pressed; // Keypad . and Delete
                    9'h15A: player4[6] <= pressed; // Keypad ENTER
                endcase
            end
        end
    end

endmodule
