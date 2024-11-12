//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2024, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// MSX Compatible Gateware IP Core
//
// Copyright (c) 2022, Molekula <@tdlabac>
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

module vy0010
    (
        input         clk,
        input         clk_en,
        input         reset,
        input  [15:0] addr,
        input   [7:0] d_from_cpu,
        output  [7:0] d_to_cpu,
        input         stlsl_n,
        input         wr_n,
        input         rd_n,
        input         CS1_n,
        input         img_mounted,
        input  [31:0] img_size,
        input         img_wp,
        output [31:0] sd_lba,
        output        sd_rd,
        output        sd_wr,
        input         sd_ack,
        input   [8:0] sd_buff_addr,
        input   [7:0] sd_buff_dout,
        output  [7:0] sd_buff_din,
        input         sd_buff_wr,
        input         sd_din_strobe
    );

    reg side_select, m_on, in_use = 1'b0;
    reg [1:0] ds = 2'b0;
    reg type1, type0 = 1'b1;

    wire ic4   = ~&{addr[13:3], ~stlsl_n};
    wire r7ffc = ~ic4 && addr[2] && addr[1:0] == 2'b00;
    wire r7ffd = ~ic4 && addr[2] && addr[1:0] == 2'b01;
    wire r7fff = ~ic4 && addr[2] && addr[1:0] == 2'b11;
    wire romce = addr[15:14] == 2'b01 && ic4 && ~stlsl_n && ~CS1_n;
    wire csfdc = ~ic4 && ~addr[2];

    assign d_to_cpu = romce            ? d_from_rom                             :
                      r7ffc   && ~rd_n ? {7'b1111111, ~side_select}             :
                      r7ffd   && ~rd_n ? {m_on, in_use, 4'b1110, ~ds[1], ds[0]} :
                      r7fff   && ~rd_n ? {~drq, ~intrq, type1, type0, 4'b1111}  :
                      csfdc   && ~rd_n ? d_from_wd                              : 8'hFF;

    wire wr7ffc = r7ffc & ~wr_n;
    always @(posedge reset, posedge wr7ffc) begin
        if (reset) begin
            side_select <= 1'b0;
        end
        else begin
            if (~stlsl_n) begin
                side_select <= d_from_cpu[0];
            end
        end
    end

    wire wr7ffd = r7ffd & ~wr_n;
    always @(posedge reset, posedge wr7ffd) begin
        if (reset) begin
            m_on   <= 1'b0;
            in_use <= 1'b0;
            ds     <= 2'b00;
        end
        else begin
            if (~stlsl_n) begin
                ds[0]  <=  d_from_cpu[0];
                ds[1]  <= ~d_from_cpu[1];
                in_use <=  d_from_cpu[6];
                m_on   <=  d_from_cpu[7];
            end
        end
    end

    wire [7:0] d_from_wd;
    wire       drq, intrq;
    reg        img_load;

    always @(posedge clk) begin
        if(img_mounted) begin
            img_load <= |img_size;
        end
    end

    wire fdd_ready = img_load & ~ds[0] & ds[1];

    wd1793 #(.RWMODE(1), .EDSK(0)) fdc
    (
        .clk_sys      ( clk            ),
        .ce           ( clk_en         ),
        .reset        ( reset          ),
        .io_en        ( csfdc          ),
        .rd           ( ~rd_n          ),
        .wr           ( ~wr_n          ),
        .addr         ( addr[1:0]      ),
        .din          ( d_from_cpu     ),
        .dout         ( d_from_wd      ),
        .drq          ( drq            ),
        .intrq        ( intrq          ),
        .ready        ( fdd_ready      ),
        .layout       ( 1'b0           ),
        .size_code    ( 3'h2           ),
        .side         ( side_select    ),
        .img_mounted  ( img_mounted    ),
        .wp           ( img_wp         ),
        .img_size     ( img_size[19:0] ),
        .sd_lba       ( sd_lba         ),
        .sd_rd        ( sd_rd          ),
        .sd_wr        ( sd_wr          ),
        .sd_ack       ( sd_ack         ),
        .sd_buff_addr ( sd_buff_addr   ),
        .sd_buff_dout ( sd_buff_dout   ),
        .sd_buff_din  ( sd_buff_din    ),
        .sd_buff_wr   ( sd_buff_wr     ),
        .input_active ( 1'b0           ),
        .input_addr   ( 20'h0          ),
        .input_data   ( 8'h0           ),
        .input_wr     ( 1'b0           ),
        .buff_din     ( 8'h0           )
    );

    wire [7:0] d_from_rom;

    spram #(.addr_width(14), .mem_init_file("rom/vy0010.mif"), .mem_name("VY0010ROM")) vy0010_rom
    (
        .clock   ( clk        ),
        .address ( addr[13:0] ),
        .wren    ( 0          ),
        .q       ( d_from_rom )
    );

endmodule
