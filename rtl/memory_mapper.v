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

module memory_mapper
    (
        input        reset,
        input        ppi_n,
        input [15:0] addr,
        input [7:0]  RAM_CS,
        input        mreq_n,
        input        rfrsh_n,
        input        rd_n,
        output [3:0] SLTSL_n,
        output       CS1_n,
        output       CS01_n,
        output       CS12_n,
        output       CS2_n
    );

    wire ppi_en = ~ppi_n;
    reg  enable;

    initial begin
        enable = 0;
    end

    always @(posedge reset, posedge ppi_en) begin
        if (reset) begin
            enable = 0;
        end
        else if (ppi_en) begin
            enable = 1;
        end
    end

    wire selmem = ~mreq_n & rfrsh_n;

    wire [1:0] sel = {addr[15:14]};
    wire [1:0] CS_n = ~enable      ?       2'b00 :
                      sel == 2'b00 ? RAM_CS[1:0] :
                      sel == 2'b01 ? RAM_CS[3:2] :
                      sel == 2'b10 ? RAM_CS[5:4] : RAM_CS[7:6];

    assign SLTSL_n[0] = ~(CS_n == 2'b00 & selmem);
    assign SLTSL_n[1] = ~(CS_n == 2'b01 & selmem);
    assign SLTSL_n[2] = ~(CS_n == 2'b10 & selmem);
    assign SLTSL_n[3] = ~(CS_n == 2'b11 & selmem);

    wire   CS0_n  = ~(addr[15:14] == 2'b00 & ~rd_n);
    assign CS1_n  = ~(addr[15:14] == 2'b01 & ~rd_n);
    assign CS2_n  = ~(addr[15:14] == 2'b10 & ~rd_n);
    assign CS01_n = CS0_n & CS1_n;
    assign CS12_n = CS1_n & CS2_n;

endmodule
