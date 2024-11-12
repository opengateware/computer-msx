//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// NVRAM-style hiscore autosave support for arcade cores.
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2021, Jim Gregory
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//------------------------------------------------------------------------------
//
// Version history:
// 0001 - 2021-10-01 - First marked release
// 0002 - 2021-10-09 - Add change mask support
// 0003 - 2023-06-21 - Changes for the Analogue Pocket
//
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module nvram
    #(
         parameter DUMPWIDTH       = 8,                 // Address size of NVRAM for highscore data (default 8 = 256 bytes max)
         parameter CONFIGINDEX     = 2,                 // ioctl_index for config transfer
         parameter DUMPINDEX       = 3,                 // ioctl_index for dump transfer
         parameter PAUSEPAD        = 4,                 // Cycles to wait with paused CPU before and after NVRAM access
         parameter TARGET_PLATFORM = 1                  // Platform: [1] Analogue Pocket | [2] MiMiC
     ) (
         input  wire                 clk,
         input  wire                 paused,            // Signal from core confirming CPU is paused
         input  wire                 reset,
         input  wire                 autosave,          // Auto-save enabled (active high)

         input  wire                 ioctl_upload,
         output  reg                 ioctl_upload_req,
         input  wire                 ioctl_download,
         input  wire                 ioctl_wr,
         input  wire          [24:0] ioctl_addr,
         input  wire           [7:0] ioctl_index,
         output wire           [7:0] ioctl_din,
         input  wire           [7:0] ioctl_dout,
         input  wire                 OSD_STATUS,

         output wire [DUMPWIDTH-1:0] nvram_address,
         input  wire           [7:0] nvram_data_out,

         output  reg                 pause_cpu          // Pause core CPU to prepare for/relax after NVRAM access
     );

    // Hiscore data tracking
    reg  downloaded_config = 1'b0; // Has hiscore config been loaded?
    reg  downloaded_dump   = 1'b0; // Has hiscore data been loaded?
    reg  extracting_dump   = 1'b0; // Is hiscore data currently extracted and checked for change?
    wire downloading_config;       // Is hiscore config currently being loaded?
    wire downloading_dump;         // Is hiscore data currently being loaded?
    wire uploading_dump;           // Is hiscore data currently being saved?

    assign downloading_config = ioctl_download && (ioctl_index == CONFIGINDEX);
    assign downloading_dump   = ioctl_download && (ioctl_index == DUMPINDEX);
    assign uploading_dump     = ioctl_upload   && (ioctl_index == DUMPINDEX);

    // State machine constants
    localparam SM_STATEWIDTH      = 3; // Width of state machine net
    localparam SM_IDLE            = 0;
    localparam SM_TIMER           = 1;
    localparam SM_EXTRACTINIT     = 2;
    localparam SM_EXTRACTREADY    = 3;
    localparam SM_EXTRACTNEXT     = 4;
    localparam SM_EXTRACTSAVE     = 5;
    localparam SM_EXTRACTCOMPLETE = 6;

    // State machine control
    reg  [(SM_STATEWIDTH-1):0] state = SM_IDLE;      // Current state machine index
    reg  [(SM_STATEWIDTH-1):0] next_state = SM_IDLE; // Next state machine index to move to after wait timer expires
    reg                 [31:0] wait_timer;           // Wait timer for inital/read/write delays

    // Last cycle signals
    reg       last_reset = 1'b0;       // Last cycle reset
    reg       last_OSD_STATUS;         // Last cycle OSD status
    reg [7:0] last_ioctl_index;        // Last cycle HPS IO index
    reg       last_ioctl_download = 0; // Last cycle HPS IO download

    // Buffer RAM control signals
    reg  [DUMPWIDTH-1:0] buffer_addr;
    reg  [DUMPWIDTH-1:0] buffer_length;
    wire           [7:0] buffer_data_in;
    reg                  buffer_write = 1'b0;

    assign nvram_address = buffer_addr;

    // Change detection signals
    reg  [DUMPWIDTH-1:0] compare_length = 1'b0;
    reg                  compare_nonzero = 1'b1; // High after extract and compare if any byte returned is non-zero
    reg                  compare_changed = 1'b1; // High after extract and compare if any byte is different to current hiscore data
    wire           [7:0] check_mask_out /* synthesis keep */;
    wire                 check_mask = check_mask_out[buffer_addr[2:0]] /* synthesis keep */;

    // RAM used to store high score check mask
    spram_hs #(.aWidth(DUMPWIDTH-3),.dWidth(8))
             mask_ram (
                 .clk(clk),
                 .addr(downloading_config ? ioctl_addr[DUMPWIDTH-4:0] : buffer_addr[DUMPWIDTH-1:3]),
                 .we(downloading_config && ioctl_wr),
                 .d(ioctl_dout),
                 .q(check_mask_out)
             );

    // RAM used to store high score data buffer
    spram_hs #(.aWidth(DUMPWIDTH),.dWidth(8))
             nvram_buffer (
                 .clk(clk),
                 .addr((downloading_dump || uploading_dump) ? ioctl_addr[DUMPWIDTH-1:0] : buffer_addr),
                 .we(downloading_dump ? ioctl_wr : buffer_write),
                 .d(downloading_dump ? ioctl_dout : nvram_data_out),
                 .q(ioctl_din)
             );

    always @(posedge clk) begin

        // Track completion of configuration and dump download
        if(TARGET_PLATFORM == 1) begin
            if (~ioctl_download && last_ioctl_download) begin
                downloaded_config <= 1'b1;
                downloaded_dump   <= 1'b1;
            end
        end
        else begin
            if ((last_ioctl_download != ioctl_download) && (ioctl_download == 1'b0)) begin
                if (last_ioctl_index == CONFIGINDEX) downloaded_config <= 1'b1;
                if (last_ioctl_index == DUMPINDEX)   downloaded_dump   <= 1'b1;
            end
        end

        // Track last cycle values
        last_ioctl_download <= ioctl_download;
        last_ioctl_index    <= ioctl_index;
        last_OSD_STATUS     <= OSD_STATUS;
        last_reset          <= reset;

        // Check for end of core reset to initialise hiscore system state
        if (last_reset == 1'b1 && reset == 1'b0) begin
            next_state      <= SM_IDLE;
            state           <= SM_IDLE;
            extracting_dump <= 1'b0;
            buffer_length   <= (2**DUMPWIDTH) - 1'b1;
        end
        else begin

            // Trigger hiscore extraction when OSD is opened
            if(last_OSD_STATUS==1'b0 && OSD_STATUS==1'b1 && extracting_dump==1'b0 && uploading_dump==1'b0) begin
                extracting_dump <= 1'b1;
                state           <= SM_EXTRACTINIT;
            end

            // Extract hiscore data from game RAM and save in hiscore data buffer
            if (extracting_dump == 1'b1) begin
                case (state)
                    SM_EXTRACTINIT: // Initialise state machine for extraction
                    begin
                        // Setup addresses and comparison flags
                        buffer_addr     <= 1'b0;
                        buffer_write    <= 1'b0;
                        compare_nonzero <= 1'b0;
                        compare_changed <= 1'b0;
                        compare_length  <= 1'b0;
                        // Pause cpu and wait for next state
                        pause_cpu        <= 1'b1;
                        state            <= SM_TIMER;
                        next_state       <= SM_EXTRACTREADY;
                        wait_timer       <= PAUSEPAD;
                        ioctl_upload_req <= 1'b0;
                    end
                    SM_EXTRACTREADY: begin
                        // Schedule write for next cycle when addresses are ready
                        buffer_write   <= 1'b1;
                        compare_length <= compare_length + 1'b1;
                        state          <= SM_EXTRACTNEXT;
                    end
                    SM_EXTRACTNEXT: begin
                        if ((nvram_data_out != ioctl_din) && (downloaded_config == 1'b0 || check_mask == 1'b1)) begin
                            compare_changed <= 1'b1; // Hiscore data changed since last dump
                        end

                        if (nvram_data_out != 8'b0) begin
                            compare_nonzero <= 1'b1; // Hiscore data is not blank
                        end

                        // Always stop writing to hiscore dump ram and increment local address
                        buffer_write <= 1'b0;
                        buffer_addr  <= buffer_addr + 1'b1;

                        if (compare_length == buffer_length) begin
                            // Finish extract if last address is reached
                            state      <= SM_TIMER;
                            next_state <= SM_EXTRACTSAVE;
                            wait_timer <= PAUSEPAD;
                        end
                        else begin
                            // Otherwise move to next byte
                            state      <= SM_TIMER;
                            next_state <= SM_EXTRACTREADY;
                            wait_timer <= 1'b0;
                        end

                    end
                    SM_EXTRACTSAVE: begin
                        // If high scores have changed and are not blank, then trigger autosave if enabled
                        if (compare_changed == 1'b1 && compare_nonzero == 1'b1 && autosave == 1'b1) begin
                            ioctl_upload_req <= 1'b1;
                        end

                        // Release pause and schedule end of extraction process
                        pause_cpu  <= 1'b0;
                        state      <= SM_TIMER;
                        next_state <= SM_EXTRACTCOMPLETE;
                        wait_timer <= 4'd4;
                    end
                    SM_EXTRACTCOMPLETE: begin
                        // End extract, clear any upload request and move state machine to idle
                        extracting_dump  <= 1'b0;
                        ioctl_upload_req <= 1'b0;
                        state            <= SM_IDLE;
                    end
                endcase
            end

            if(state == SM_TIMER) // timer wait state
            begin
                // Do not progress timer if CPU is paused by source other than this module
                if (paused == 1'b0 || pause_cpu == 1'b1) begin
                    if (wait_timer > 1'b0)
                        wait_timer <= wait_timer - 1'b1;
                    else
                        state <= next_state;
                end
            end
        end
    end

endmodule
