//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket Save I/O Controller for APF bridge
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

module save_io
    #(
         // MPU <-> FPGA (NVRAM/SAVE I/O)
         parameter MASK       = 4'h6, //! Upper 4 bits of address
         parameter AW         = 27,   //! Address Width
         parameter DW         = 8,    //! Data Width (8 or 16 bits)
         parameter WR_DELAY   = 4,    //! Number of clock cycles to delay each write output
         parameter WR_HOLD    = 1,    //! Number of clock cycles to hold the ioctl_wr signal high
         parameter RD_DELAY   = 4,    //! Number of memory clock cycles it takes for a read to complete
         parameter SAVE_IDX   = 3     //! Dataslot index for save data transfer
     ) (
         input  logic          clk_74a,
         input  logic          clk_memory,
         // Pocket Bridge Slots
         input  logic          dataslot_requestwrite,
         input  logic   [15:0] dataslot_requestwrite_id,
         input  logic          dataslot_requestread,
         input  logic   [15:0] dataslot_requestread_id,
         input  logic          dataslot_allcomplete,
         // Pocket Bridge
         input  logic          bridge_endian_little,
         input  logic   [31:0] bridge_addr,
         input  logic          bridge_wr,
         input  logic   [31:0] bridge_wr_data,
         input  logic          bridge_rd,
         output logic   [31:0] bridge_rd_data = 0,
         // MPU <-> FPGA
         output logic          nvram_download = 0,
         output logic   [15:0] nvram_index,
         output logic          nvram_wr,
         output logic [AW-1:0] nvram_addr,
         output logic [DW-1:0] nvram_dout,
         output logic          nvram_upload  = 0,
         input  logic          nvram_upload_req,
         input  logic   [15:0] nvram_upload_index,
         input  logic [DW-1:0] nvram_din,
         output logic          nvram_rd
     );

    localparam WORD_SIZE = DW == 16 ? 2 : 1;

    logic [AW-1:0] nvram_rd_addr;
    logic [AW-1:0] nvram_wr_addr;

    assign nvram_addr  = nvram_wr ? nvram_wr_addr : nvram_rd_addr;
    synch_3 #(.WIDTH(16)) sync_nvram_index(dataslot_requestwrite_id, nvram_index, clk_memory);

    always_ff @(posedge clk_74a) begin
        if (dataslot_requestwrite && (dataslot_requestwrite_id == SAVE_IDX)) begin
            nvram_download <= 1;
        end
        else if(dataslot_requestread && (dataslot_requestread_id == SAVE_IDX)) begin
            nvram_upload   <= 1;
        end
        else if(dataslot_allcomplete) begin
            nvram_download <= 0;
            nvram_upload   <= 0;
        end
    end

    //! ------------------------------------------------------------------------
    //! MPU -> FPGA Download
    //! ------------------------------------------------------------------------
    data_loader #(
        .ADDRESS_MASK_UPPER_4      ( MASK                 ),
        .WRITE_MEM_CLOCK_DELAY     ( WR_DELAY             ),
        .WRITE_MEM_EN_CYCLE_LENGTH ( WR_HOLD              ),
        .ADDRESS_SIZE              ( AW                   ),
        .OUTPUT_WORD_SIZE          ( WORD_SIZE            )
    ) save_data_in (
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
        .ADDRESS_MASK_UPPER_4 ( MASK                 ),
        .READ_MEM_CLOCK_DELAY ( RD_DELAY             ),
        .ADDRESS_SIZE         ( AW                   ),
        .INPUT_WORD_SIZE      ( WORD_SIZE            )
    ) save_data_out (
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

endmodule
