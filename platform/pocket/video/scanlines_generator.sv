//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Generic Video Scanlines
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2017, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2015, Till Harbaum <till@harbaum.org>
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

module scanlines_generator
    #(
         parameter ORIENTATION = 0      //! Scanline Orientation [0]: Horizontal | [01] Vertical
     ) (
         // Clock
         input  logic        clk_vid,   //! Pixel Clock
         // Scanline Control
         input  logic  [1:0] scanlines, //! Scanlines - [00]: None | [01]: 25% | [10]: 50% | [11]: 75%
         // Video Input
         input  logic [23:0] core_rgb,  //! Core: RGB Video
         input  logic        core_hs,   //! Core: Vsync
         input  logic        core_vs,   //! Core: Hsync
         input  logic        core_de,   //! Core: Data Enable
         // Video Output
         output logic [23:0] scnl_rgb,  //! Ouput: RGB Video
         output logic        scnl_hs,   //! Ouput: Vsync
         output logic        scnl_vs,   //! Ouput: Hsync
         output logic        scnl_de    //! Ouput: Data Enable
     );

    wire  [7:0] r, g, b;                //! RGB Signals
    assign {r, g, b} = core_rgb;        //! Concatenation the RGB Signals

    reg   [1:0] scanline_r;             //! Scanline Register
    reg  [23:0] rgb_r;                  //! RGB Data

    //! ------------------------------------------------------------------------
    //! Generate vertical or horizontal scanline based on ORIENTATION parameter
    //! ------------------------------------------------------------------------
    generate
        if (ORIENTATION) begin
            always_ff @(posedge clk_vid) begin
                reg rOLD_VS;
                rOLD_VS   <= core_vs;
                // XOR scanline value with scanlines
                scanline_r <= scanline_r ^ scanlines;
                // Detect end of frame (Vsync falling edge) and reset scanline counter to 0
                if(rOLD_VS && ~core_vs) begin scanline_r <= 0; end
            end
        end
        else begin
            always_ff @(posedge clk_vid) begin
                reg rOLD_HS, rOLD_VS;
                rOLD_HS <= core_hs;
                rOLD_VS <= core_vs;
                // Detect end of line (Hsync falling edge) and XOR scanline value with scanlines
                if(rOLD_HS && ~core_hs) begin scanline_r <= scanline_r ^ scanlines; end
                // Detect end of frame (Vsync falling edge) and reset scanline counter to 0
                if(rOLD_VS && ~core_vs) begin scanline_r <= 0; end
            end
        end
    endgenerate

    //! ------------------------------------------------------------------------
    //! Generate scanline effect on RGB data
    //! ------------------------------------------------------------------------
    // 00: 00%             - Set the output RGB data to be the same as the input RGB data.
    // 01: 25% [1/2 + 1/4] - Concatenate the second and third bit of each color channel and add them to the first bit shifted left by one position, with an additional 0 in the least significant position.
    // 10: 50% [1/2]       - Keep only the first bit of each color channel.
    // 11: 75% [1/4]       - Keep only the second and third bits of each color channel, with an additional 0 in the most significant position.
    always_comb begin
        case(scanline_r)
            2'b00: begin rgb_r = {r, g, b}; end
            2'b01: begin rgb_r = {{1'b0, r[7:1]} + {2'b0, r[7:2]}, {1'b0, g[7:1]} + {2'b0, g[7:2]}, {1'b0, b[7:1]} + {2'b0, b[7:2]}}; end
            2'b10: begin rgb_r = {{1'b0, r[7:1]},  {1'b0, g[7:1]}, {1'b0, b[7:1]}};                                                   end
            2'b11: begin rgb_r = {{2'b0, r[7:2]},  {2'b0, g[7:2]}, {2'b0, b[7:2]}};                                                   end
        endcase
    end

    //! ------------------------------------------------------------------------
    //! Video Output
    //! ------------------------------------------------------------------------
    always_ff @(posedge clk_vid) begin
        // Declare registers to hold the previous and current values of the input signals
        reg [23:0] rgb1, rgb2; // 24-bit RGB color values for current and previous cycles
        reg        hs1,  hs2;  // Horizontal Sync (HS) signal for current and previous cycles
        reg        vs1,  vs2;  // Vertical Sync (VS) signal for current and previous cycles
        reg        de1,  de2;  // Display Enable (DE) signal for current and previous cycles

        // Assign output signals to the values of the previous cycle
        scnl_rgb <= rgb2; // Output RGB color value from two cycles ago
        scnl_vs  <= vs2;  // Output VS signal from two cycles ago
        scnl_hs  <= hs2;  // Output HS signal from two cycles ago
        scnl_de  <= de2;  // Output DE signal from two cycles ago

        // Update the values of the registers with the current cycle's input signals
        rgb2 <= rgb1; rgb1 <= rgb_r;   // Shift the RGB values by one cycle and assign the current value
        vs2  <= vs1;  vs1  <= core_vs; // Shift the VS signal  by one cycle and assign the current value
        hs2  <= hs1;  hs1  <= core_hs; // Shift the HS signal  by one cycle and assign the current value
        de2  <= de1;  de1  <= core_de; // Shift the DE signal  by one cycle and assign the current value
    end

endmodule
