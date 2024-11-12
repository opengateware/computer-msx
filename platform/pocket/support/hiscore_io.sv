//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket HiScore NVRAM/SRAM I/O Controller for APF bridge
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

module hiscore_io
    #(
         // HiScore
         parameter HS_AW        = 16,       //! Max size of game RAM address for highscores
         parameter HS_SW        = 8,        //! Max size of capture RAM For highscore data (default 8 = 256 bytes max)
         parameter HS_CFG_AW    = 2,        //! Max size of RAM address for highscore.dat entries (default 4 = 16 entries max)
         parameter HS_CFG_LW    = 2,        //! Max size of length for each highscore.dat entries (default 1 = 256 bytes max)
         parameter HS_CONFIG    = 2,        //! Dataslot index for config transfer
         parameter HS_DATA      = 3,        //! Dataslot index for save data transfer
         // MPU <-> FPGA I/O
         parameter HS_MASK      = 4'h6,     //! Upper 4 bits of address
         parameter HS_WR_DELAY  = 4,        //! Number of clock cycles to delay each write output
         parameter HS_WR_HOLD   = 1,        //! Number of clock cycles to hold the nvram_wr signal high
         parameter HS_RD_DELAY  = 4,        //! Number of memory clock cycles it takes for a read to complete
         // NVRAM HiScore
         parameter HS_USE_NVRAM = 0,        //! Use NVRAM HiScore Module
         parameter HS_PAUSE_PAD = 4         //! Cycles to wait with paused CPU before and after NVRAM access
     ) (
         input  logic             clk_74a,
         input  logic             clk_memory,
         input  logic             pll_core_locked,
         input  logic             reset_sw,
         input  logic             pause_core,
         // Pocket Bridge Data Slots
         input  logic             dataslot_requestwrite,
         input  logic      [15:0] dataslot_requestwrite_id,
         input  logic             dataslot_requestread,
         input  logic      [15:0] dataslot_requestread_id,
         input  logic             dataslot_allcomplete,
         // Pocket Bridge
         input  logic             bridge_endian_little,
         input  logic      [31:0] bridge_addr,
         input  logic             bridge_wr,
         input  logic      [31:0] bridge_wr_data,
         input  logic             bridge_rd,
         output logic      [31:0] bridge_rd_data = 0,
         // Pocket Bridge Data Tables
         output logic       [9:0] datatable_addr,
         output logic             datatable_wren,
         output logic      [31:0] datatable_data,
         // HiScore NVRAM Size
         input  logic      [15:0] nvram_size,  //! Number bytes required for Save
         // HiScore Interface
         output logic             hs_write_en,
         output logic [HS_AW-1:0] hs_address,
         input  logic       [7:0] hs_data_out,
         output logic       [7:0] hs_data_in,
         output logic             hs_access_read,
         output logic             hs_access_write,
         output logic             hs_configured,
         output logic             hs_pause
     );

    //! ------------------------------------------------------------------------
    //! Internal Wires and Registers
    //! ------------------------------------------------------------------------
    logic [HS_AW-1:0] nvram_rd_addr;
    logic [HS_AW-1:0] nvram_wr_addr;

    logic             nvram_download = 0;
    logic      [15:0] nvram_index;
    logic             nvram_wr;
    logic [HS_AW-1:0] nvram_addr;
    logic       [7:0] nvram_dout;

    logic             nvram_upload = 0;
    logic             nvram_upload_req;
    logic      [15:0] nvram_upload_index;
    logic       [7:0] nvram_din;
    logic             nvram_rd;

    //! ------------------------------------------------------------------------
    //! Sync and Assignments
    //! ------------------------------------------------------------------------
    assign nvram_addr  = nvram_wr ? nvram_wr_addr : nvram_rd_addr;
    synch_3 #(.WIDTH(16)) sync_nvram_index(dataslot_requestwrite_id, nvram_index, clk_memory);

    //! ------------------------------------------------------------------------
    //! Download/Upload Signal Handler
    //! ------------------------------------------------------------------------
    always_ff @(posedge clk_74a) begin
        if (dataslot_requestwrite && (dataslot_requestwrite_id == HS_DATA) || (dataslot_requestwrite_id == HS_CONFIG)) begin
            nvram_download <= 1;
        end
        else if(dataslot_requestread && (dataslot_requestread_id == HS_DATA)) begin
            nvram_upload   <= 1;
        end
        else if(dataslot_allcomplete) begin
            nvram_download <= 0;
            nvram_upload   <= 0;
        end
    end

    //! ------------------------------------------------------------------------
    //! Configure Save Data Size
    //! ------------------------------------------------------------------------
    always_ff @(posedge clk_74a or negedge pll_core_locked) begin
        if (~pll_core_locked) begin
            datatable_addr <= 0;
            datatable_wren <= 0;
            datatable_data <= 0;
        end
        else begin
            datatable_addr <= HS_DATA * 2 + 1; // Data slot index, not id
            datatable_wren <= 1;               // Write nvram size
            datatable_data <= nvram_size;      // nvram size is the number bytes
        end
    end

    //! ------------------------------------------------------------------------
    //! MPU -> FPGA Download
    //! ------------------------------------------------------------------------
    data_loader #(
        .ADDRESS_MASK_UPPER_4      ( HS_MASK              ),
        .WRITE_MEM_CLOCK_DELAY     ( HS_WR_DELAY          ),
        .WRITE_MEM_EN_CYCLE_LENGTH ( HS_WR_HOLD           ),
        .ADDRESS_SIZE              ( HS_AW                )
    ) hiscore_in (
        .clk_74a                   ( clk_74a              ),
        .clk_memory                ( clk_memory           ),

        .bridge_wr                 ( bridge_wr            ),
        .bridge_endian_little      ( bridge_endian_little ),
        .bridge_addr               ( bridge_addr          ),
        .bridge_wr_data            ( bridge_wr_data       ),

        .write_en                  ( nvram_wr             ),
        .write_addr                ( nvram_wr_addr        ),
        .write_data                ( nvram_dout           )
    );

    //! ------------------------------------------------------------------------
    //! FPGA -> MPU Upload
    //! ------------------------------------------------------------------------
    data_unloader #(
        .ADDRESS_MASK_UPPER_4 ( HS_MASK              ),
        .READ_MEM_CLOCK_DELAY ( HS_RD_DELAY          ),
        .ADDRESS_SIZE         ( HS_AW                )
    ) hiscore_out (
        .clk_74a              ( clk_74a              ),
        .clk_memory           ( clk_memory           ),

        .bridge_rd            ( bridge_rd            ),
        .bridge_endian_little ( bridge_endian_little ),
        .bridge_addr          ( bridge_addr          ),
        .bridge_rd_data       ( bridge_rd_data       ),

        .read_en              ( nvram_rd             ),
        .read_addr            ( nvram_rd_addr        ),
        .read_data            ( nvram_din            )
    );

    generate
        if(HS_USE_NVRAM) begin
            //! ------------------------------------------------------------------------
            //! NVRAM HiScore
            //! ------------------------------------------------------------------------
            nvram #(
                .DUMPWIDTH        ( HS_SW            ),
                .CONFIGINDEX      ( HS_CONFIG        ),
                .DUMPINDEX        ( HS_DATA          ),
                .PAUSEPAD         ( HS_PAUSE_PAD     )
            ) nvram_hiscore_io (
                .clk              ( clk_memory       ),
                .paused           ( pause_core       ),
                .reset            ( reset_sw         ),
                .autosave         ( 1                ),
                .OSD_STATUS       ( pause_core       ),
                // I/O Interface
                .ioctl_upload     ( nvram_upload     ),
                .ioctl_upload_req ( nvram_upload_req ),
                .ioctl_download   ( nvram_download   ),
                .ioctl_wr         ( nvram_wr         ),
                .ioctl_addr       ( nvram_addr       ),
                .ioctl_index      ( nvram_index      ),
                .ioctl_din        ( nvram_din        ),
                .ioctl_dout       ( nvram_dout       ),
                // Core Interface
                .nvram_address    ( hs_address       ),
                .nvram_data_out   ( hs_data_out      ),
                .pause_cpu        ( hs_pause         )
            );
        end
        else begin
            //! ------------------------------------------------------------------------
            //! HiScore
            //! ------------------------------------------------------------------------
            hiscore #(
                .HS_ADDRESSWIDTH  ( HS_AW            ),
                .HS_SCOREWIDTH    ( HS_SW            ),
                .HS_CONFIGINDEX   ( HS_CONFIG        ),
                .HS_DUMPINDEX     ( HS_DATA          ),
                .CFG_ADDRESSWIDTH ( HS_CFG_AW        ),
                .CFG_LENGTHWIDTH  ( HS_CFG_LW        )
            ) hiscore_io (
                .clk              ( clk_memory       ), // [i]
                .reset            ( reset_sw         ), // [i]
                .autosave         ( 1                ), // [i]
                .paused           ( pause_core       ), // [i]
                .menu_status      ( pause_core       ), // [i]
                // I/O Interface
                .ioctl_upload     ( nvram_upload     ), // [i]
                .ioctl_upload_req ( nvram_upload_req ), // [o]
                .ioctl_download   ( nvram_download   ), // [i]
                .ioctl_wr         ( nvram_wr         ), // [i]
                .ioctl_addr       ( nvram_addr       ), // [i]
                .ioctl_index      ( nvram_index      ), // [i]
                // Core Interface
                .ram_address      ( hs_address       ), // [o] Address in game RAM to read/write score data
                .data_from_ram    ( hs_data_out      ), // [i] Incoming data from game RAM
                .data_to_ram      ( hs_data_in       ), // [o] Data to send to game RAM
                .ram_write        ( hs_write_en      ), // [o] Write to game RAM (active high)

                .data_from_mpu    ( nvram_dout       ), // [i] Incoming data from MPU
                .data_to_mpu      ( nvram_din        ), // [o] Data to send to MPU
                .ram_intent_read  ( hs_access_read   ), // [o] RAM read required (active high)
                .ram_intent_write ( hs_access_write  ), // [o] RAM write required (active high)
                .pause_cpu        ( hs_pause         ), // [o] Pause core CPU to prepare for/relax after RAM access
                .configured       ( hs_configured    )  // [o] Hiscore module has valid configuration (active high)
            );
        end
    endgenerate

endmodule
