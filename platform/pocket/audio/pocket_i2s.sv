//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket I2S Audio Interface
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

module pocket_i2s
    (
        input  wire        audio_sclk, //! Serial clock
        // Core Audio
        input  wire [15:0] audio_l,    //! Left channel
        input  wire [15:0] audio_r,    //! Right channel
        // Pocket I2S Interface
        output  reg        audio_dac,  //! Serialized data
        output  reg        audio_lrck  //! Left/Right clock
    );

    //! ------------------------------------------------------------------------
    //! Synchronize audio samples
    //! ------------------------------------------------------------------------
    reg [31:0] audio_sd_s; //! Synced Audio Sample
    synch_3 #(.WIDTH(32)) sync_sample({audio_l, audio_r}, audio_sd_s, audio_sclk);

    //! ------------------------------------------------------------------------
    //! Generate signals for digital-to-analog conversion.
    //! ------------------------------------------------------------------------
    reg [31:0] audio_sample_sh; // Register for shifting audio samples
    reg  [4:0] audio_lrck_cnt;  // Register for counting LRCK (left/right clock) cycles

    always_ff @(negedge audio_sclk) begin
        audio_dac <= audio_sample_sh[31];  // Set DAC output to the MSB (most significant bit) of audio_sample_sh
        audio_lrck_cnt <= audio_lrck_cnt + 1'b1;
        if (audio_lrck_cnt == 31) begin
            audio_lrck <= ~audio_lrck;  // Toggle audio_lrck (switch channels)
            if (~audio_lrck) begin
                audio_sample_sh <= audio_sd_s;  // Reload sample shifter with new audio sample
            end
        end
        else if (audio_lrck_cnt < 16) begin
            audio_sample_sh <= {audio_sample_sh[30:0], 1'b0}; // Only shift for 16 clocks per channel
        end
    end

endmodule
