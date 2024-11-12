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

module cart_konami
    (
        input            clk,
        input            reset,
        input     [24:0] rom_size,
        input     [15:0] addr,
        input      [7:0] d_from_cpu,
        input            wr,
        input            cs,
        output    [24:0] mem_addr
    );

    reg  [7:0] bank1, bank2, bank3;
    wire [7:0] mask = rom_size[20:13] - 1'd1;

    always @(posedge reset, posedge clk) begin
        if (reset) begin
            bank1 <= 8'h01;
            bank2 <= 8'h02;
            bank3 <= 8'h03;
        end
        else begin
            if (cs && wr) begin
                case (addr[15:13])
                    3'b011: bank1 <= d_from_cpu; // 6000-7fffh
                    3'b100: bank2 <= d_from_cpu; // 8000-9fffh
                    3'b101: bank3 <= d_from_cpu; // a000-bfffh
                endcase
            end
        end
    end

    wire [7:0] bank_base = addr[15:13] == 3'b010 ? 8'h00 :
                           addr[15:13] == 3'b011 ? bank1 :
                           addr[15:13] == 3'b100 ? bank2 : bank3;

    assign mem_addr = {3'h0, (bank_base & mask), addr[12:0]};

endmodule
