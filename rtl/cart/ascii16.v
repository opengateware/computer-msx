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

module cart_asci16
    (
        input            clk,
        input            reset,
        input     [24:0] rom_size,
        input     [15:0] addr,
        input      [7:0] d_from_cpu,
        input            wr,
        input            cs,
        input            r_type,
        output    [24:0] mem_addr,
        output    [12:0] sram_addr,
        output           sram_we,
        output           sram_oe
    );

    reg  [7:0] bank0, bank1;
    wire [7:0] mask      = rom_size[20:13] - 1'd1;
    wire [7:0] sram_mask = rom_size[20:13] > 8'h10 ? rom_size[20:13] : 8'h10;

    always @(posedge reset, posedge clk) begin
        if (reset) begin
            bank0 <= r_type ? 8'h0f : 8'h00;
            bank1 <= 8'h00;
        end
        else begin
            if (cs && wr) begin
                if (r_type) begin
                    if (addr[15:12] == 4'b0111) begin
                        bank1 <= d_from_cpu[4] ? {5'b00010,d_from_cpu[2:0]} : {3'b000,d_from_cpu[4:0]};
                    end
                end
                else begin
                    case (addr[15:11])
                        5'b01100: bank0 <= d_from_cpu; // 6000-67ffh
                        5'b01110: bank1 <= d_from_cpu; // 7000-77ffh
                    endcase
                end
            end
        end
    end

    wire [7:0] bank_base = addr[15] == 0 ? bank0 : bank1;

    assign mem_addr  = {2'h0, (bank_base & mask), addr[13:0]};

    assign sram_addr = addr[12:0];
    assign sram_we   = cs && (bank1 & sram_mask) && addr[15:14] == 2'b10 && wr;
    assign sram_oe   = cs && (bank_base & sram_mask);

endmodule
