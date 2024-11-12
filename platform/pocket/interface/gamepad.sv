//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket PAD Controller
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
// Shifts the joystick input signal through two stages of registers,
// synchronizing it to the system clock signal, and outputs the synchronized
// joystick outputs
//
// key bitmap:
//   [0] dpad_up    | [ 8] trig_l1
//   [1] dpad_down  | [ 9] trig_r1
//   [2] dpad_left  | [10] trig_l2
//   [3] dpad_right | [11] trig_r2
//   [4] face_a     | [12] trig_l3
//   [5] face_b     | [13] trig_r3
//   [6] face_x     | [14] face_select
//   [7] face_y     | [15] face_start
//   [28:16] <unused>
//   [31:29] type
//
// joy values - unsigned - 0x00 > 0x80 < 0xFF
//     [7:0] lstick_x
//    [15:8] lstick_y
//   [23:16] rstick_x
//   [31:24] rstick_y
//
// trigger values - unsigned - 0x00-0xFF
//    [7:0] ltrig
//   [15:8] rtrig
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module gamepad
    #(
         parameter JOY_PADS = 1,                                    //! Total Number of Gamepads
         parameter JOY_ALT  = 0,                                    //! 2 Players Alternate
         parameter DEADZONE = 8'h10                                 //! Set Controller Deadzone
     ) (
         input  logic        clk_sys,                               //! Clock to Sync To (eg: clk_sys)
         //! Pocket PAD Interface
         input  logic [31:0] cont1_key, cont1_joy,                  //! Gamepad/Analog Joystick
         input  logic [31:0] cont2_key, cont2_joy,                  //! Gamepad/Analog Joystick
         input  logic [31:0] cont3_key, cont3_joy,                  //! Gamepad/Analog Joystick
         input  logic [31:0] cont4_key, cont4_joy,                  //! Gamepad/Analog Joystick
         //! Player 1
         output logic        p1_up,    p1_down,  p1_left, p1_right, //! D-PAD
         output logic        p1_a,     p1_b,     p1_x,    p1_y,     //! Face Buttons
         output logic        p1_l1,    p1_l2,    p1_l3,   p1_se,    //! Left  Shoulder/Trigger/Analog Buttons/Select
         output logic        p1_r1,    p1_r2,    p1_r3,   p1_st,    //! Right Shoulder/Trigger/Analog Buttons/Start
         output logic        j1_up,    j1_down,  j1_left, j1_right, //! Analog 2 DPAD
         output logic  [7:0] j1_lx,    j1_ly,    j1_rx,   j1_ry,    //! Left/Right Analog Stick
         //! Player 2
         output logic        p2_up,    p2_down,  p2_left, p2_right, //! D-PAD
         output logic        p2_a,     p2_b,     p2_x,    p2_y,     //! Face Buttons
         output logic        p2_l1,    p2_l2,    p2_l3,   p2_se,    //! Left  Shoulder/Trigger/Analog Buttons/Select
         output logic        p2_r1,    p2_r2,    p2_r3,   p2_st,    //! Right Shoulder/Trigger/Analog Buttons/Start
         output logic        j2_up,    j2_down,  j2_left, j2_right, //! Analog 2 DPAD
         output logic  [7:0] j2_lx,    j2_ly,    j2_rx,   j2_ry,    //! Left/Right Analog Stick
         //! Player 3
         output logic        p3_up,    p3_down,  p3_left, p3_right, //! D-PAD
         output logic        p3_a,     p3_b,     p3_x,    p3_y,     //! Face Buttons
         output logic        p3_l1,    p3_l2,    p3_l3,   p3_se,    //! Left  Shoulder/Trigger/Analog Buttons/Select
         output logic        p3_r1,    p3_r2,    p3_r3,   p3_st,    //! Right Shoulder/Trigger/Analog Buttons/Start
         output logic        j3_up,    j3_down,  j3_left, j3_right, //! Analog 2 DPAD
         output logic  [7:0] j3_lx,    j3_ly,    j3_rx,   j3_ry,    //! Left/Right Analog Stick
         //! Player 4
         output logic        p4_up,    p4_down,  p4_left, p4_right, //! D-PAD
         output logic        p4_a,     p4_b,     p4_x,    p4_y,     //! Face Buttons
         output logic        p4_l1,    p4_l2,    p4_l3,   p4_se,    //! Left  Shoulder/Trigger/Analog Buttons/Select
         output logic        p4_r1,    p4_r2,    p4_r3,   p4_st,    //! Right Shoulder/Trigger/Analog Buttons/Start
         output logic        j4_up,    j4_down,  j4_left, j4_right, //! Analog 2 DPAD
         output logic  [7:0] j4_lx,    j4_ly,    j4_rx,   j4_ry,    //! Left/Right Analog Stick
         //! Single Player or Alternate 2 Players for Arcade
         output logic        m_up,     m_down,   m_left,  m_right,  //! Joystick
         output logic        m_btn1,   m_btn2,   m_btn3,  m_btn4,   //! Y/B/A/X
         output logic        m_btn5,   m_btn6,   m_btn7,  m_btn8,   //! L1/R1/L2/R2
         output logic        m_coin,   m_coin1,  m_coin2,           //! Coinage
         output logic        m_start1, m_start2,                    //! P1/P2 Start
         //! Type
         output logic  [3:0] p1_type, p2_type, p3_type, p4_type     //! Controller Type
     );

    //! ------------------------------------------------------------------------
    //! Player 1
    //! ------------------------------------------------------------------------
    joypad #(.DEADZONE(DEADZONE)) joypad_p1
    (
        .clk_sys  ( clk_sys   ),
        // Pocket PAD Interface
        .cont_key ( cont1_key ),
        .cont_joy ( cont1_joy ),
        // DPAD
        .key_up   ( p1_up     ),.key_down ( p1_down ),.key_left ( p1_left ),.key_right ( p1_right ),
        .key_a    ( p1_a      ),.key_b    ( p1_b    ),.key_x    ( p1_x    ),.key_y     ( p1_y     ),
        .key_l1   ( p1_l1     ),.key_l2   ( p1_l2   ),.key_l3   ( p1_l3   ),
        .key_r1   ( p1_r1     ),.key_r2   ( p1_r2   ),.key_r3   ( p1_r3   ),
        .key_se   ( p1_se     ),.key_st   ( p1_st   ),
        // Analog Stick
        .joy_up   ( j1_up     ),.joy_down ( j1_down ),.joy_left ( j1_left ),.joy_right ( j1_right ),
        .joy_lx   ( j1_lx     ),.joy_ly   ( j1_ly   ),.joy_rx   ( j1_rx   ),.joy_ry    ( j1_ry    ),
        // Type
        .pad_type ( p1_type   )
    );

    //! ------------------------------------------------------------------------
    //! Player 2
    //! ------------------------------------------------------------------------
    generate
        if(JOY_PADS >= 2) begin
            joypad #(.DEADZONE(DEADZONE)) joypad_p2
            (
                .clk_sys  ( clk_sys   ),
                // Pocket PAD Interface
                .cont_key ( cont2_key ),
                .cont_joy ( cont2_joy ),
                // DPAD
                .key_up   ( p2_up     ),.key_down ( p2_down ),.key_left ( p2_left ),.key_right ( p2_right ),
                .key_a    ( p2_a      ),.key_b    ( p2_b    ),.key_x    ( p2_x    ),.key_y     ( p2_y     ),
                .key_l1   ( p2_l1     ),.key_l2   ( p2_l2   ),.key_l3   ( p2_l3   ),
                .key_r1   ( p2_r1     ),.key_r2   ( p2_r2   ),.key_r3   ( p2_r3   ),
                .key_se   ( p2_se     ),.key_st   ( p2_st   ),
                // Analog Stick
                .joy_up   ( j2_up     ),.joy_down ( j2_down ),.joy_left ( j2_left ),.joy_right ( j2_right ),
                .joy_lx   ( j2_lx     ),.joy_ly   ( j2_ly   ),.joy_rx   ( j2_rx   ),.joy_ry    ( j2_ry    ),
                // Type
                .pad_type ( p2_type   )
            );
        end
        else begin
            assign { p2_up, p2_down, p2_left, p2_right } =  4'h0;
            assign { p2_y , p2_x   , p2_b   , p2_a     } =  4'h0;
            assign { p2_l1, p2_r1  , p2_l2  , p2_r2    } =  4'h0;
            assign { p2_l3, p2_r3  , p2_se  , p2_st    } =  4'h0;
            assign { j2_up, j2_down, j2_left, j2_right } =  4'h0;
            assign { j2_lx, j2_ly  , j2_rx  , j2_ry    } = 32'h0;
            assign { p2_type                           } =  4'h0;
        end
    endgenerate

    //! ------------------------------------------------------------------------
    //! Player 3
    //! ------------------------------------------------------------------------
    generate
        if(JOY_PADS >= 3) begin
            joypad #(.DEADZONE(DEADZONE)) joypad_p3
            (
                .clk_sys  ( clk_sys   ),
                // Pocket PAD Interface
                .cont_key ( cont3_key ),
                .cont_joy ( cont3_joy ),
                // DPAD
                .key_up   ( p3_up     ),.key_down ( p3_down ),.key_left ( p3_left ),.key_right ( p3_right ),
                .key_a    ( p3_a      ),.key_b    ( p3_b    ),.key_x    ( p3_x    ),.key_y     ( p3_y     ),
                .key_l1   ( p3_l1     ),.key_l2   ( p3_l2   ),.key_l3   ( p3_l3   ),
                .key_r1   ( p3_r1     ),.key_r2   ( p3_r2   ),.key_r3   ( p3_r3   ),
                .key_se   ( p3_se     ),.key_st   ( p3_st   ),
                // Analog Stick
                .joy_up   ( j3_up     ),.joy_down ( j3_down ),.joy_left ( j3_left ),.joy_right ( j3_right ),
                .joy_lx   ( j3_lx     ),.joy_ly   ( j3_ly   ),.joy_rx   ( j3_rx   ),.joy_ry    ( j3_ry    ),
                // Type
                .pad_type ( p3_type   )
            );
        end
        else begin
            assign { p3_up, p3_down, p3_left, p3_right } =  4'h0;
            assign { p3_y , p3_x   , p3_b   , p3_a     } =  4'h0;
            assign { p3_l1, p3_r1  , p3_l2  , p3_r2    } =  4'h0;
            assign { p3_l3, p3_r3  , p3_se  , p3_st    } =  4'h0;
            assign { j3_up, j3_down, j3_left, j3_right } =  4'h0;
            assign { j3_lx, j3_ly  , j3_rx  , j3_ry    } = 32'h0;
            assign { p3_type                           } =  4'h0;
        end
    endgenerate

    //! ------------------------------------------------------------------------
    //! Player 4
    //! ------------------------------------------------------------------------
    generate
        if(JOY_PADS == 4) begin
            joypad #(.DEADZONE(DEADZONE)) joypad_p4
            (
                .clk_sys  ( clk_sys   ),
                // Pocket PAD Interface
                .cont_key ( cont4_key ),
                .cont_joy ( cont4_joy ),
                // DPAD
                .key_up   ( p4_up     ),.key_down ( p4_down ),.key_left ( p4_left ),.key_right ( p4_right ),
                .key_a    ( p4_a      ),.key_b    ( p4_b    ),.key_x    ( p4_x    ),.key_y     ( p4_y     ),
                .key_l1   ( p4_l1     ),.key_l2   ( p4_l2   ),.key_l3   ( p4_l3   ),
                .key_r1   ( p4_r1     ),.key_r2   ( p4_r2   ),.key_r3   ( p4_r3   ),
                .key_se   ( p4_se     ),.key_st   ( p4_st   ),
                // Analog Stick
                .joy_up   ( j4_up     ),.joy_down ( j4_down ),.joy_left ( j4_left ),.joy_right ( j4_right ),
                .joy_lx   ( j4_lx     ),.joy_ly   ( j4_ly   ),.joy_rx   ( j4_rx   ),.joy_ry    ( j4_ry    ),
                // Type
                .pad_type ( p4_type   )
            );
        end
        else begin
            assign { p4_up, p4_down, p4_left, p4_right } =  4'h0;
            assign { p4_y , p4_x   , p4_b   , p4_a     } =  4'h0;
            assign { p4_l1, p4_r1  , p4_l2  , p4_r2    } =  4'h0;
            assign { p4_l3, p4_r3  , p4_se  , p4_st    } =  4'h0;
            assign { j4_up, j4_down, j4_left, j4_right } =  4'h0;
            assign { j4_lx, j4_ly  , j4_rx  , j4_ry    } = 32'h0;
            assign { p4_type                           } =  4'h0;
        end
    endgenerate

    generate
        // Alternate 2 Players for Arcade
        if(JOY_PADS == 2 && JOY_ALT == 1) begin
            assign m_start1 = p1_st;
            assign m_start2 = p2_st;
            assign m_coin1  = p1_se;
            assign m_coin2  = p2_se;
            assign m_coin   = p1_se    | p2_se;
            assign m_up     = p1_up    | p2_up    | j1_up    | j2_up;
            assign m_down   = p1_down  | p2_down  | j1_down  | j2_down;
            assign m_left   = p1_left  | p2_left  | j1_left  | j2_left;
            assign m_right  = p1_right | p2_right | j1_right | j2_right;
            assign m_btn1   = p1_y     | p2_y;
            assign m_btn2   = p1_b     | p2_b;
            assign m_btn3   = p1_a     | p2_a;
            assign m_btn4   = p1_x     | p2_x;
            assign m_btn5   = p1_l1    | p2_l1;
            assign m_btn6   = p1_r1    | p2_r1;
            assign m_btn7   = p1_l2    | p2_l2;
            assign m_btn8   = p1_r2    | p2_r2;
        end
        // Single Players for Arcade
        else if(JOY_PADS == 1 && JOY_ALT == 0) begin
            assign m_start1 = p1_st;
            assign m_coin1  = p1_se;
            assign m_coin   = p1_se;
            assign m_up     = p1_up    | j1_up;
            assign m_down   = p1_down  | j1_down;
            assign m_left   = p1_left  | j1_left;
            assign m_right  = p1_right | j1_right;
            assign m_btn1   = p1_y;
            assign m_btn2   = p1_b;
            assign m_btn3   = p1_a;
            assign m_btn4   = p1_x;
            assign m_btn5   = p1_l1;
            assign m_btn6   = p1_r1;
            assign m_btn7   = p1_l2;
            assign m_btn8   = p1_r2;
            assign { m_start2, m_coin2 } = 2'h0;
        end
        else begin
            assign { m_coin                             } = 1'h0;
            assign { m_up,     m_down,  m_left, m_right } = 4'h0;
            assign { m_btn1,   m_btn2,  m_btn3, m_btn4  } = 4'h0;
            assign { m_btn5,   m_btn6,  m_btn7, m_btn8  } = 4'h0;
            assign { m_coin1,  m_coin2                  } = 2'h0;
            assign { m_start1, m_start2                 } = 2'h0;
        end
    endgenerate

endmodule
