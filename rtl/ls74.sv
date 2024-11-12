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

module ls74
    (
        input   wire clr,
        input   wire pre,
        input   wire clk,
        input   wire d,
        output logic q
    );

    always_ff @(posedge clk, negedge clr, negedge pre) begin
        if      (!clr) q <= 1'b0;
        else if (!pre) q <= 1'b1;
        else           q <= d;
    end

endmodule
