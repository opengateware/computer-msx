//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Video Scanlines Generator
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
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
// | Horizontal Lines                 |
// | Soft     | 25% | 4'b0001 | 4'd1  |
// | Medium   | 50% | 4'b0010 | 4'd2  |
// | Hard     | 75% | 4'b0011 | 4'd3  |
//
// | Vertical Lines                   |
// | Soft     | 25% | 4'b0100 | 4'd4  |
// | Medium   | 50% | 4'b1000 | 4'd8  |
// | Hard     | 75% | 4'b1100 | 4'd12 |
//
// | Horizontal and Vertical Lines    |
// | Soft     | 25% | 4'b0101 | 4'd5  |
// | Medium   | 50% | 4'b1010 | 4'd10 |
// | Hard     | 75% | 4'b1111 | 4'd15 |
//
//------------------------------------------------------------------------------

`default_nettype none

module scanlines
    (
        // Clock
        input             clk_vid,    //! Pixel Clock
        // Scanline Control
        input       [3:0] scnl_sw,    //! Scanlines
        // Video Input
        input      [23:0] core_rgb,   //! Core: RGB Video
        input             core_hs,    //! Core: Hsync
        input             core_vs,    //! Core: Vsync
        input             core_de,    //! Core: Data Enable
        // Video Output
        output reg [23:0] scnl_rgb,   //! Ouput: RGB Video
        output reg        scnl_hs,    //! Ouput: Hsync
        output reg        scnl_vs,    //! Ouput: Vsync
        output reg        scnl_de     //! Ouput: Data Enable
    );

    //! ------------------------------------------------------------------------
    //! Horizontal Scanlines
    //! ------------------------------------------------------------------------
    wire [23:0] h_video_rgb;
    wire        h_video_hs, h_video_vs, h_video_de;

    scanlines_generator #(.ORIENTATION(0)) scanlines_horizontal
                        (
                            .clk_vid   ( clk_vid      ),
                            .scanlines ( scnl_sw[1:0] ),
                            .core_rgb  ( core_rgb     ),
                            .core_hs   ( core_hs      ),
                            .core_vs   ( core_vs      ),
                            .core_de   ( core_de      ),
                            .scnl_rgb  ( h_video_rgb  ),
                            .scnl_hs   ( h_video_hs   ),
                            .scnl_vs   ( h_video_vs   ),
                            .scnl_de   ( h_video_de   )
                        );

    //! ------------------------------------------------------------------------
    //! Vertical Scanlines
    //! ------------------------------------------------------------------------
    wire [23:0] v_video_rgb;
    wire        v_video_hs, v_video_vs, v_video_de;

    scanlines_generator #(.ORIENTATION(1)) scanlines_vertical
                        (
                            .clk_vid   ( clk_vid      ),
                            .scanlines ( scnl_sw[3:2] ),
                            .core_rgb  ( h_video_rgb  ),
                            .core_hs   ( h_video_hs   ),
                            .core_vs   ( h_video_vs   ),
                            .core_de   ( h_video_de   ),
                            .scnl_rgb  ( v_video_rgb  ),
                            .scnl_hs   ( v_video_hs   ),
                            .scnl_vs   ( v_video_vs   ),
                            .scnl_de   ( v_video_de   )
                        );

    //! ------------------------------------------------------------------------
    //! Video Output
    //! ------------------------------------------------------------------------
    always_ff @(posedge clk_vid) begin
        scnl_rgb <= v_video_rgb;
        scnl_hs  <= v_video_hs;
        scnl_vs  <= v_video_vs;
        scnl_de  <= v_video_de;
    end

endmodule
