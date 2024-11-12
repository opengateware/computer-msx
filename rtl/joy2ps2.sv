//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2024, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Joystick to PS/2 Keyboard
//
// Copyright (c) 2024, Marcus Andrade <marcus@opengateware.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module joy2ps2
    (
        input   wire        clk,
        input   wire        reset,     // Reset signal
        input   wire        enable,    // Reset signal
        input   wire [23:0] key_map,   // Key Mapping
        input   wire  [5:0] joy_key,   // [5] Start, [4] Select, [3] R1, [2] L1,  [1] X, [0] Y
        output logic [10:0] ps2_key    // [10] Strobe, [9] Pressed/Released, [8:0] Scancode
    );

    // Define states for the state machine
    typedef enum logic [2:0] {
                KEY_IDLE,
                KEY_SAVE,
                KEY_PRESSED,
                KEY_HELD,
                KEY_RELEASED_TO_IDLE,
                KEY_RELEASED_TO_NEW
            } KeyState;

    KeyState state, next_state;

    // PS/2 Keyboard Internal Logic
    reg       key_strobe;
    reg       key_pressed;
    reg [8:0] key_code;

    // PS/2 Translation
    reg [8:0] ps2_scancode, ps2_scancode_last;
    reg [8:0] key_code_saved;
    reg       save_key;

    parameter SC_END      = 9'h169, // SELECT
              SC_PG_UP    = 9'h17D, // STOP
              SC_L_ALT    = 9'h011, // GRAPH
              SC_L_CRTL   = 9'h014, // CRTL
              SC_UP       = 9'h175, // Arrow Up
              SC_DOWN     = 9'h172, // Arrow Down
              SC_LEFT     = 9'h16B, // Arrow Left
              SC_RIGHT    = 9'h174, // Arrow Right
              SC_F1       = 9'h005, SC_1        = 9'h016,
              SC_F2       = 9'h006, SC_2        = 9'h01E,
              SC_F3       = 9'h004, SC_3        = 9'h026,
              SC_F4       = 9'h00C, SC_4        = 9'h025,
              SC_F5       = 9'h003, SC_5        = 9'h02E,
              SC_M        = 9'h03A, SC_N        = 9'h031,
              SC_SPACE    = 9'h029, SC_SHIFT    = 9'h012,
              SC_ESC      = 9'h076, SC_RETURN   = 9'h05A,
              SC_NONE     = 9'h000;

    reg [8:0] MAP_Y,  MAP_X;
    reg [8:0] MAP_L,  MAP_R;
    reg [8:0] MAP_ST, MAP_SE;

    always_ff @(negedge clk) begin : assignMapping
        case(key_map[3:0])
            4'h1   : begin MAP_Y  = SC_SPACE;  end
            4'h2   : begin MAP_Y  = SC_SHIFT;  end
            4'h3   : begin MAP_Y  = SC_M;      end
            4'h4   : begin MAP_Y  = SC_N;      end
            4'h5   : begin MAP_Y  = SC_1;      end
            4'h6   : begin MAP_Y  = SC_2;      end
            4'h7   : begin MAP_Y  = SC_3;      end
            4'h8   : begin MAP_Y  = SC_4;      end
            4'h9   : begin MAP_Y  = SC_ESC;    end
            4'hA   : begin MAP_Y  = SC_RETURN; end
            default: begin MAP_Y  = SC_NONE;   end
        endcase
        case(key_map[7:4])
            4'h1   : begin MAP_X  = SC_SPACE;  end
            4'h2   : begin MAP_X  = SC_SHIFT;  end
            4'h3   : begin MAP_X  = SC_M;      end
            4'h4   : begin MAP_X  = SC_N;      end
            4'h5   : begin MAP_X  = SC_1;      end
            4'h6   : begin MAP_X  = SC_2;      end
            4'h7   : begin MAP_X  = SC_3;      end
            4'h8   : begin MAP_X  = SC_4;      end
            4'h9   : begin MAP_X  = SC_ESC;    end
            4'hA   : begin MAP_X  = SC_RETURN; end
            default: begin MAP_X  = SC_NONE;   end
        endcase
        case(key_map[11:8])
            4'h1   : begin MAP_L  = SC_END;    end
            4'h2   : begin MAP_L  = SC_PG_UP;  end
            4'h3   : begin MAP_L  = SC_L_ALT;  end
            4'h4   : begin MAP_L  = SC_L_CRTL; end
            4'h5   : begin MAP_L  = SC_F1;     end
            default: begin MAP_L  = SC_NONE;   end
        endcase
        case(key_map[15:12])
            4'h1   : begin MAP_R  = SC_END;    end
            4'h2   : begin MAP_R  = SC_PG_UP;  end
            4'h3   : begin MAP_R  = SC_L_ALT;  end
            4'h4   : begin MAP_R  = SC_L_CRTL; end
            4'h5   : begin MAP_R  = SC_F5;     end
            default: begin MAP_R  = SC_NONE;   end
        endcase
        case(key_map[19:16])
            4'h1   : begin MAP_SE = SC_SPACE;  end
            4'h2   : begin MAP_SE = SC_F1;     end
            4'h3   : begin MAP_SE = SC_F2;     end
            4'h4   : begin MAP_SE = SC_F3;     end
            4'h5   : begin MAP_SE = SC_F4;     end
            4'h6   : begin MAP_SE = SC_F5;     end
            default: begin MAP_SE = SC_NONE;   end
        endcase
        case(key_map[23:20])
            4'h1   : begin MAP_ST = SC_SPACE;  end
            4'h2   : begin MAP_ST = SC_F1;     end
            4'h3   : begin MAP_ST = SC_F2;     end
            4'h4   : begin MAP_ST = SC_F3;     end
            4'h5   : begin MAP_ST = SC_F4;     end
            4'h6   : begin MAP_ST = SC_F5;     end
            default: begin MAP_ST = SC_NONE;   end
        endcase
    end

    always_ff @(posedge clk) begin : joy2scancode
        if (reset) begin
            ps2_scancode <= 9'h0;
        end
        else begin
            if(joy_key != 6'h0) begin
                case(joy_key)
                    6'h01  : begin ps2_scancode <= MAP_Y;  end // [0] Y
                    6'h02  : begin ps2_scancode <= MAP_X;  end // [1] X
                    6'h04  : begin ps2_scancode <= MAP_L;  end // [2] L
                    6'h08  : begin ps2_scancode <= MAP_R;  end // [3] R
                    6'h10  : begin ps2_scancode <= MAP_SE; end // [4] Select
                    6'h20  : begin ps2_scancode <= MAP_ST; end // [5] Start
                    default: begin /* DO NOTHING */        end
                endcase
            end
            else begin
                ps2_scancode <= 9'h0;
            end
        end
    end

    // Save Scancode
    always_ff @(posedge clk) begin : saveScancode
        key_code_saved <= (save_key) ? ps2_scancode : key_code_saved;
    end

    // State Machine Controller
    always_ff @(posedge clk) begin : scancodeFSM
        if (reset) begin
            state <= KEY_IDLE;
        end
        else begin
            ps2_scancode_last <= ps2_scancode;
            state             <= next_state;
        end
    end

    // PS/2 Translation
    always_comb begin : scancodeTranslation
        next_state  = state;
        key_code    = 9'h000;
        key_pressed = 1'b0;
        key_strobe  = 1'b0;
        save_key    = 1'b0;

        case (state)
            KEY_IDLE: begin
                key_code = 9'h000;
                // Detect zero to non-zero transition
                if(~|ps2_scancode_last & |ps2_scancode) begin
                    next_state = KEY_SAVE;
                end
            end
            KEY_SAVE: begin
                save_key   = 1'b1;
                next_state = KEY_PRESSED;
            end
            KEY_PRESSED: begin
                key_code    = key_code_saved;
                key_pressed = 1'b1;
                key_strobe  = 1'b1;
                next_state  = KEY_HELD;
            end
            KEY_HELD: begin
                key_code    = key_code_saved;
                key_pressed = 1'b1;
                key_strobe  = 1'b0;
                // Detect non-zero to zero transition
                if(|ps2_scancode_last & ~|ps2_scancode) begin
                    next_state = KEY_RELEASED_TO_IDLE;
                end
                else if (ps2_scancode_last != ps2_scancode) begin
                    next_state = KEY_RELEASED_TO_NEW;
                end
            end
            KEY_RELEASED_TO_IDLE: begin
                key_code    = key_code_saved;
                key_pressed = 1'b0;
                key_strobe  = 1'b1;
                next_state  = KEY_IDLE;
            end
            KEY_RELEASED_TO_NEW: begin
                key_code    = key_code_saved;
                key_strobe  = 1'b1;
                key_pressed = 1'b0;
                next_state  = KEY_SAVE;
            end
            default: begin
                next_state  = KEY_IDLE;
            end
        endcase
    end

    // PS/2 Keyboard Output
    assign ps2_key = enable ? {key_strobe, key_pressed, key_code} : 11'h0;

endmodule
