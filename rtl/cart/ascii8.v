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

module cart_asci8
    (
        input            clk,
        input            reset,
        input     [24:0] rom_size,
        input     [15:0] addr,
        input      [7:0] d_from_cpu,
        input            wr,
        input            cs,
        output    [24:0] mem_addr,
        output    [12:0] sram_addr,
        output           sram_we,
        output           sram_oe
    );

    reg  [7:0] bank0, bank1, bank2, bank3;
    wire [7:0] mask      = rom_size[20:13] - 1'd1;
    wire [7:0] sram_mask = rom_size[20:13];

    always @(posedge reset, posedge clk) begin
        if (reset) begin
            bank0 <= 8'h00;
            bank1 <= 8'h00;
            bank2 <= 8'h00;
            bank3 <= 8'h00;
        end
        else begin
            if (cs && wr) begin
                case (addr[15:11])
                    5'b01100: bank0 <= d_from_cpu; // 6000-67ffh
                    5'b01101: bank1 <= d_from_cpu; // 6800-6fffh
                    5'b01110: bank2 <= d_from_cpu; // 7000-77ffh
                    5'b01111: bank3 <= d_from_cpu; // 7800-7fffh
                endcase
            end
        end
    end

    wire [7:0] bank_base = addr[15:13] == 3'b010 ? bank0 :
                           addr[15:13] == 3'b011 ? bank1 :
                           addr[15:13] == 3'b100 ? bank2 : bank3;

    assign mem_addr  = {3'h0, (bank_base & mask), addr[12:0]};

    assign sram_addr = addr[12:0];
    assign sram_we   = cs && ((bank2 & sram_mask && addr[15:13] == 3'b100) || (bank3 & sram_mask && addr[15:13] == 3'b101)) && wr;
    assign sram_oe   = cs && (bank_base & sram_mask);

endmodule
