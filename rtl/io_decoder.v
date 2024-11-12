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

module io_decoder
    (
        input  wire [7:0] addr,
        input  wire       iorq_n,
        input  wire       m1_n,
        output wire       vdp_n,
        output wire       psg_n,
        output wire       ppi_n,
        output wire       cen_n
    );

    wire io_en = ~iorq_n & m1_n;

    assign cen_n = ~((addr[7:3] == 5'b10010) & io_en);
    assign vdp_n = ~((addr[7:3] == 5'b10011) & io_en);
    assign psg_n = ~((addr[7:3] == 5'b10100) & io_en);
    assign ppi_n = ~((addr[7:3] == 5'b10101) & io_en);

endmodule
