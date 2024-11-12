//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
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
// Generic Video Interface for the Analogue Pocket Display
//
// Note: APF scaler requires HSync and VSync to last for a single clock, and
// video_rgb to be 0 when video_de is low
//
// RGB palettes
//
// | RGB Format | Bit Depth | Number of Colors |
// | ---------- | --------- | ---------------- |
// | RGB111     | 3 bits    | 8                |
// | RGB222     | 6 bits    | 64               |
// | RGB233     | 8 bits    | 256              |
// | RGB332     | 8 bits    | 256              |
// | RGB333     | 9 bits    | 512              |
// | RGB444     | 12 bits   | 4,096            |
// | RGB555     | 15 bits   | 32,768           |
// | RGB565     | 16 bits   | 65,536           |
// | RGB666     | 18 bits   | 262,144          |
// | RGB888     | 24 bits   | 16,777,216       |
//
//------------------------------------------------------------------------------

`default_nettype none

module video_mixer
    #(
         parameter             RW = 8,                   //! Bits Per Pixel Red
         parameter             GW = 8,                   //! Bits Per Pixel Green
         parameter             BW = 8                    //! Bits Per Pixel Blue
     ) (
         // Clocks
         input  logic          clk_74a,                  //! APF: Main Clock
         input  logic          clk_sys,                  //! Core: System Clock
         input  logic          clk_vid,                  //! Core: Pixel Clock
         input  logic          clk_vid_90deg,            //! Core: Pixel Clock 90º Phase Shift
         // Input Controls
         input  logic    [2:0] video_preset,             //! Video preset configurations (up to 8)
         input  logic    [3:0] scnl_sw,                  //! Scanlines Switches
         input  logic    [3:0] smask_sw,                 //! Shadow Mask Switches
         // Input Video from Core
         input  logic [RW-1:0] core_r,                   //! Core: Video Red
         input  logic [GW-1:0] core_g,                   //! Core: Video Green
         input  logic [BW-1:0] core_b,                   //! Core: Video Blue
         input  logic          core_vs,                  //! Core: Vsync
         input  logic          core_hs,                  //! Core: Hsync
         input  logic          core_de,                  //! Core: Data Enable
         // Output to Display Connection
         output logic   [23:0] video_rgb,                //! Display: RGB Color: Red[23:16] Green[15:8] Blue[7:0]
         output logic          video_vs,                 //! Display: Video Vertical Sync
         output logic          video_hs,                 //! Display: Video Horizontal Sync
         output logic          video_de,                 //! Display: Data Enable
         output logic          video_rgb_clock,          //! Display: Pixel Clock
         output logic          video_rgb_clock_90,       //! Display: Pixel Clock 90º Phase Shift
         // Pocket Bridge Slots
         input  logic          dataslot_requestwrite,
         input  logic   [15:0] dataslot_requestwrite_id,
         input  logic          dataslot_allcomplete,
         // Pocket Bridge
         input  logic          bridge_endian_little,
         input  logic   [31:0] bridge_addr,
         input  logic          bridge_wr,
         input  logic   [31:0] bridge_wr_data
     );

    //! ------------------------------------------------------------------------
    //! Combine Colors to Create a Full RGB888 Color Space
    //! ------------------------------------------------------------------------
    reg [7:0] R, G, B;

    always_comb begin
        R = RW == 8 ? core_r : {core_r, {8-RW{1'b0}}};
        G = GW == 8 ? core_g : {core_g, {8-GW{1'b0}}};
        B = BW == 8 ? core_b : {core_b, {8-BW{1'b0}}};
    end

    //! ------------------------------------------------------------------------
    //! Scanlines
    //! ------------------------------------------------------------------------
    wire [23:0] s_video_rgb;
    wire        s_video_hs, s_video_vs, s_video_de;

    scanlines video_scanlines
              (
                  .clk_vid   ( clk_vid     ),
                  .scnl_sw   ( scnl_sw     ),
                  .core_rgb  ( {R, G, B}   ),
                  .core_vs   ( core_vs     ),
                  .core_hs   ( core_hs     ),
                  .core_de   ( core_de     ),
                  .scnl_rgb  ( s_video_rgb ),
                  .scnl_hs   ( s_video_hs  ),
                  .scnl_vs   ( s_video_vs  ),
                  .scnl_de   ( s_video_de  )
              );

    //! ------------------------------------------------------------------------
    //! Shadow Mask
    //! ------------------------------------------------------------------------
    wire [23:0] sm_video_rgb;
    wire        sm_video_hs, sm_video_vs, sm_video_de;

    shadowmask video_shadowmask
               (
                   .clk_vid     ( clk_vid        ),
                   .clk_sys     ( clk_sys        ),

                   .mask_wr     ( filter_wr      ),
                   .mask_data   ( filter_dout    ),

                   .mask_enable ( smask_sw[0]    ),
                   .mask_rotate ( smask_sw[1]    ),
                   .mask_2x     ( smask_sw[2]    ),
                   .brd_in      ( 0              ),

                   .din         ( s_video_rgb    ),
                   .hs_in       ( s_video_hs     ),
                   .vs_in       ( s_video_vs     ),
                   .de_in       ( s_video_de     ),

                   .dout        ( sm_video_rgb   ),
                   .hs_out      ( sm_video_hs    ),
                   .vs_out      ( sm_video_vs    ),
                   .de_out      ( sm_video_de    )
               );

    //! ------------------------------------------------------------------------
    //! Video Output
    //! ------------------------------------------------------------------------
    reg [23:0] video_rgb_r;
    reg        video_hs_r, video_vs_r, video_de_r;

    always_ff @(posedge clk_vid) begin
        video_de  <= 0;
        video_rgb <= {8'b0, video_preset, 13'b0};
        if (video_de_r) begin
            video_de  <= 1;
            video_rgb <= video_rgb_r;
        end
        // Set HSync and VSync to be high for a single cycle on the rising edge
        // of the HSync and VSync coming out of the core
        video_hs    <= ~video_hs_r && sm_video_hs;
        video_vs    <= ~video_vs_r && sm_video_vs;
        video_hs_r  <= sm_video_hs;
        video_vs_r  <= sm_video_vs;
        video_de_r  <= sm_video_de;
        video_rgb_r <= sm_video_rgb;
    end

    //! ------------------------------------------------------------------------
    //! Clock Output
    //! ------------------------------------------------------------------------
    always_comb begin
        video_rgb_clock    = clk_vid;
        video_rgb_clock_90 = clk_vid_90deg;
    end

    //! ------------------------------------------------------------------------
    //! MPU -> FPGA Download
    //! ------------------------------------------------------------------------
    wire        filter_download;
    wire [15:0] filter_index;
    wire        filter_wr;
    wire [23:0] filter_addr;
    wire [15:0] filter_dout;

    // data_io #(.MASK(4'h1),.AW(24),.DW(16),.DELAY(4),.HOLD(1)) video_config_io
    //         (
    //             // Clocks and Reset
    //             .clk_74a                  ( clk_74a                  ),
    //             .clk_memory               ( clk_sys                  ),
    //             // Pocket Bridge Slots
    //             .dataslot_requestwrite    ( dataslot_requestwrite    ), // [i]
    //             .dataslot_requestwrite_id ( dataslot_requestwrite_id ), // [i]
    //             .dataslot_allcomplete     ( dataslot_allcomplete     ), // [i]
    //             // MPU -> FPGA (MPU Write to FPGA)
    //             // Pocket Bridge
    //             .bridge_endian_little     ( bridge_endian_little     ), // [i]
    //             .bridge_addr              ( bridge_addr              ), // [i]
    //             .bridge_wr                ( bridge_wr                ), // [i]
    //             .bridge_wr_data           ( bridge_wr_data           ), // [i]
    //             // Controller Interface
    //             .ioctl_download           ( filter_download          ), // [o]
    //             .ioctl_index              ( filter_index             ), // [o]
    //             .ioctl_wr                 ( filter_wr                ), // [o]
    //             .ioctl_addr               ( filter_addr              ), // [o]
    //             .ioctl_dout               ( filter_dout              )  // [o]
    //         );

endmodule
