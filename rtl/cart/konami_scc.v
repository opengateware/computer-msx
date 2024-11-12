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

module cart_konami_scc
    (
        input         clk,
        input         clk_en,
        input         reset,
        input  [24:0] rom_size,
        input  [15:0] addr,
        input   [7:0] d_from_cpu,
        output  [7:0] d_to_cpu,
        output        ack,
        input         wr,
        input         rd,
        input         cs,
        output [24:0] mem_addr,
        output [14:0] scc_sound
    );

    reg  [7:0] bank0, bank1, bank2, bank3;
    wire [7:0] mask = rom_size[20:13] - 1'd1;

    always @(posedge reset, posedge clk) begin
        if (reset) begin
            bank0 <= 8'h00;
            bank1 <= 8'h01;
            bank2 <= 8'h02;
            bank3 <= 8'h03;
        end
        else begin
            if (cs && wr) begin
                case (addr[15:11])
                    5'b01010: bank0 <= d_from_cpu; // 5000-57ffh
                    5'b01110: bank1 <= d_from_cpu; // 7000-77ffh
                    5'b10010: bank2 <= d_from_cpu; // 9000-97ffh
                    5'b10110: bank3 <= d_from_cpu; // b000-b7ffh
                endcase
            end
        end
    end

    wire [7:0] bank_base = addr[15:13] == 3'b010 ? bank0 :
                           addr[15:13] == 3'b011 ? bank1 :
                           addr[15:13] == 3'b100 ? bank2 : bank3;

    assign mem_addr = {3'h0, (bank_base & mask), addr[12:0]};

    wire       scc_req = cs && addr[15:11] == 5'b10011 && bank2[5:0] == 6'b111111 && (rd || wr);
    wire [7:0] d_to_cpu_scc;
    wire [7:0] scc_addr = toCopy                 ? {3'b100,addr[4:0]} :
                          (~addr[13] && addr[7]) ? addr[7:0] ^ 8'h20  :
                          addr[7:0];

    //Copy channel 5
    reg toCopy;
    reg cp;

    always @(posedge clk) begin
        if (reset) begin
            toCopy <= 0;
            cp     <= 0;
        end
        else begin
            if (scc_req && ack) begin
                if (wr && addr[7:5] == 3'b011 && ~cp) begin
                    cp <= 1;
                end
                else begin
                    cp <= 0;
                end
            end
            if (cp)  begin toCopy <= 1; end
            if (~wr) begin toCopy <= 0; end
        end
    end

    scc_wave k051649
    (
        .clk21m ( clk        ),
        .reset  ( reset      ),
        .clkena ( clk_en     ),
        .req    ( scc_req & (~(ack & cp) | toCopy) ),
        .ack    ( ack        ),
        .wrt    ( wr         ),
        .adr    ( scc_addr   ),
        .dbi    ( d_to_cpu   ),
        .dbo    ( d_from_cpu ),
        .wave   ( scc_sound  )
    );

endmodule
