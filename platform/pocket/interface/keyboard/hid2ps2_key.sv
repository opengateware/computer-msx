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

module hid2ps2_key
    (
        input  logic       clk, //! System Clock
        input  logic [7:0] usb, //! USB HID ID
        output logic [8:0] ps2  //! PS/2 Scancode
    );

    // Set the ram style to control implementation.
    (* ramstyle = "no_rw_check" *)
    logic [8:0] rom[0:255];

    always_ff @(posedge clk) begin : ps2Scancode
        ps2 <= rom[usb];
    end

    // Initialize the lookup table with default values
    initial begin : generateTable
        for (int i = 0; i < 256; i = i + 1) begin : setDefaultValues
            rom[i] = 9'h000; // Default value (no translation)
        end

        // Define translations for specific USB HID codes
        rom[8'h00] = 9'h000; // Reserved (no event indicated)
        rom[8'h01] = 9'h000; // Keyboard Error Roll Over - used for all slots if too many keys are pressed ("Phantom key")
        rom[8'h02] = 9'h000; // POST Fail
        rom[8'h03] = 9'h000; // Error Undefined
        rom[8'h04] = 9'h01C; // a and A
        rom[8'h05] = 9'h032; // b and B
        rom[8'h06] = 9'h021; // c and C
        rom[8'h07] = 9'h023; // d and D
        rom[8'h08] = 9'h024; // e and E
        rom[8'h09] = 9'h02B; // f and F
        rom[8'h0A] = 9'h034; // g and G
        rom[8'h0B] = 9'h033; // h and H
        rom[8'h0C] = 9'h043; // i and I
        rom[8'h0D] = 9'h03B; // j and J
        rom[8'h0E] = 9'h042; // k and K
        rom[8'h0F] = 9'h04B; // l and L
        rom[8'h10] = 9'h03A; // m and M
        rom[8'h11] = 9'h031; // n and N
        rom[8'h12] = 9'h044; // o and O
        rom[8'h13] = 9'h04D; // p and P
        rom[8'h14] = 9'h015; // q and Q
        rom[8'h15] = 9'h02D; // r and R
        rom[8'h16] = 9'h01B; // s and S
        rom[8'h17] = 9'h02C; // t and T
        rom[8'h18] = 9'h03C; // u and U
        rom[8'h19] = 9'h02A; // v and V
        rom[8'h1A] = 9'h01D; // w and W
        rom[8'h1B] = 9'h022; // x and X
        rom[8'h1C] = 9'h035; // y and Y
        rom[8'h1D] = 9'h01A; // z and Z
        rom[8'h1E] = 9'h016; // 1 and !
        rom[8'h1F] = 9'h01E; // 2 and @
        rom[8'h20] = 9'h026; // 3 and #
        rom[8'h21] = 9'h025; // 4 and $
        rom[8'h22] = 9'h02E; // 5 and %
        rom[8'h23] = 9'h036; // 6 and ^
        rom[8'h24] = 9'h03D; // 7 and &
        rom[8'h25] = 9'h03E; // 8 and *
        rom[8'h26] = 9'h046; // 9 and (
        rom[8'h27] = 9'h045; // 0 and )
        rom[8'h28] = 9'h05A; // Return (ENTER)
        rom[8'h29] = 9'h076; // ESCAPE
        rom[8'h2A] = 9'h066; // DELETE (Backspace)
        rom[8'h2B] = 9'h00D; // Tab
        rom[8'h2C] = 9'h029; // Spacebar
        rom[8'h2D] = 9'h04E; // - and (underscore)
        rom[8'h2E] = 9'h055; // = and +
        rom[8'h2F] = 9'h054; // [ and {
        rom[8'h30] = 9'h05B; // ] and }
        rom[8'h31] = 9'h05D; // \ and |
        rom[8'h32] = 9'h05D; // Non-US # and ~
        rom[8'h33] = 9'h04C; // ; and :
        rom[8'h34] = 9'h052; // ' and "
        rom[8'h35] = 9'h00E; // Grave Accent and Tilde
        rom[8'h36] = 9'h041; // Keyboard, and <
        rom[8'h37] = 9'h049; // . and >
        rom[8'h38] = 9'h04A; // / and ?
        rom[8'h39] = 9'h058; // Caps Lock
        rom[8'h3A] = 9'h005; // F1
        rom[8'h3B] = 9'h006; // F2
        rom[8'h3C] = 9'h004; // F3
        rom[8'h3D] = 9'h00C; // F4
        rom[8'h3E] = 9'h003; // F5
        rom[8'h3F] = 9'h00B; // F6
        rom[8'h40] = 9'h083; // F7
        rom[8'h41] = 9'h00A; // F8
        rom[8'h42] = 9'h001; // F9
        rom[8'h43] = 9'h009; // F10
        rom[8'h44] = 9'h078; // F11
        rom[8'h45] = 9'h007; // F12
        rom[8'h46] = 9'h17C; // Print Screen
        rom[8'h47] = 9'h07E; // Scroll Lock
        rom[8'h48] = 9'h000; // Pause
        rom[8'h49] = 9'h170; // Insert
        rom[8'h4A] = 9'h16C; // Home
        rom[8'h4B] = 9'h17D; // Page Up
        rom[8'h4C] = 9'h171; // Delete Forward
        rom[8'h4D] = 9'h169; // End
        rom[8'h4E] = 9'h17A; // Page Down
        rom[8'h4F] = 9'h174; // Right Arrow
        rom[8'h50] = 9'h16B; // Left Arrow
        rom[8'h51] = 9'h172; // Down Arrow
        rom[8'h52] = 9'h175; // Up Arrow
        rom[8'h53] = 9'h077; // Keypad Num Lock and Clear
        rom[8'h54] = 9'h14A; // Keypad /
        rom[8'h55] = 9'h07C; // Keypad *
        rom[8'h56] = 9'h07B; // Keypad -
        rom[8'h57] = 9'h079; // Keypad +
        rom[8'h58] = 9'h15A; // Keypad ENTER
        rom[8'h59] = 9'h069; // Keypad 1 and End
        rom[8'h5A] = 9'h072; // Keypad 2 and Down Arrow
        rom[8'h5B] = 9'h07A; // Keypad 3 and PageDn
        rom[8'h5C] = 9'h06B; // Keypad 4 and Left Arrow
        rom[8'h5D] = 9'h073; // Keypad 5
        rom[8'h5E] = 9'h074; // Keypad 6 and Right Arrow
        rom[8'h5F] = 9'h06C; // Keypad 7 and Home
        rom[8'h60] = 9'h075; // Keypad 8 and Up Arrow
        rom[8'h61] = 9'h07D; // Keypad 9 and PageUp
        rom[8'h62] = 9'h070; // Keypad 0 and Insert
        rom[8'h63] = 9'h071; // Keypad . and Delete
        // Extra Keys
        rom[8'h64] = 9'h061; // Non-US \ and | - 102nd
        rom[8'h65] = 9'h12F; // Application
        rom[8'h66] = 9'h137; // Power
        rom[8'h67] = 9'h00F; // Keypad =
        rom[8'h68] = 9'h008; // F13
        rom[8'h69] = 9'h010; // F14
        rom[8'h6A] = 9'h018; // F15
        rom[8'h6B] = 9'h020; // F16
        rom[8'h6C] = 9'h028; // F17
        rom[8'h6D] = 9'h030; // F18
        rom[8'h6E] = 9'h038; // F19
        rom[8'h6F] = 9'h040; // F20
        rom[8'h70] = 9'h048; // F21
        rom[8'h71] = 9'h050; // F22
        rom[8'h72] = 9'h057; // F23
        rom[8'h73] = 9'h05F; // F24
        rom[8'h74] = 9'h000; // Execute
        rom[8'h75] = 9'h000; // Help
        rom[8'h76] = 9'h000; // Menu
        rom[8'h77] = 9'h000; // Select
        rom[8'h78] = 9'h000; // Stop
        rom[8'h79] = 9'h000; // Again
        rom[8'h7A] = 9'h000; // Undo
        rom[8'h7B] = 9'h000; // Cut
        rom[8'h7C] = 9'h000; // Copy
        rom[8'h7D] = 9'h000; // Paste
        rom[8'h7E] = 9'h000; // Find
        rom[8'h7F] = 9'h000; // Mute
        rom[8'h80] = 9'h000; // Volume Up
        rom[8'h81] = 9'h000; // Volume Down
        rom[8'h82] = 9'h000; // Locking Caps Lock
        rom[8'h83] = 9'h000; // Locking Num Lock
        rom[8'h84] = 9'h000; // Locking Scroll Lock
        rom[8'h85] = 9'h06D; // Keypad Comma
        rom[8'h86] = 9'h000; // Keypad Equal Sign
        rom[8'h87] = 9'h051; // International1 - Ro
        rom[8'h88] = 9'h013; // International2 - Katakana/Hiragana
        rom[8'h89] = 9'h06A; // International3 - Yen
        rom[8'h8A] = 9'h064; // International4 - Henkan
        rom[8'h8B] = 9'h067; // International5 - Muhenkan
        rom[8'h8C] = 9'h027; // International6 - Keypad JP Comma
        rom[8'h8D] = 9'h000; // International7
        rom[8'h8E] = 9'h000; // International8
        rom[8'h8F] = 9'h000; // International9
        rom[8'h90] = 9'h0F2; // LANG1 - Hangeul
        rom[8'h91] = 9'h0F1; // LANG2 - Hanja
        rom[8'h92] = 9'h063; // LANG3 - Katakana
        rom[8'h93] = 9'h062; // LANG4 - Hiragana
        rom[8'h94] = 9'h05F; // LANG5 - Zenkaku/Hankaku
        rom[8'h95] = 9'h000; // LANG6
        rom[8'h96] = 9'h000; // LANG7
        rom[8'h97] = 9'h000; // LANG8
        rom[8'h98] = 9'h000; // LANG9
        rom[8'h99] = 9'h000; // Alternate Erase
        rom[8'h9A] = 9'h000; // SysReq/Attention
        rom[8'h9B] = 9'h000; // Cancel
        rom[8'h9C] = 9'h000; // Clear
        rom[8'h9D] = 9'h000; // Prior
        rom[8'h9E] = 9'h000; // Return
        rom[8'h9F] = 9'h000; // Separator
        rom[8'hA0] = 9'h000; // Out
        rom[8'hA1] = 9'h000; // Oper
        rom[8'hA2] = 9'h000; // Clear/Again
        rom[8'hA3] = 9'h000; // CrSel/Props
        rom[8'hA4] = 9'h000; // ExSel
        rom[8'hE0] = 9'h014; // Left Control
        rom[8'hE1] = 9'h012; // Left Shift
        rom[8'hE2] = 9'h011; // Left Alt
        rom[8'hE3] = 9'h11F; // Left GUI
        rom[8'hE4] = 9'h114; // Right Control
        rom[8'hE5] = 9'h059; // Right Shift
        rom[8'hE6] = 9'h111; // Right Alt
        rom[8'hE7] = 9'h127; // Right GUI
    end

endmodule
