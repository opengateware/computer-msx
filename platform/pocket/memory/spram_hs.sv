//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Generic Simple Single-Port RAM (Single Clock)
//
// Copyright (c) 2022, Marcus Andrade <marcus@opengateware.org>
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

module spram_hs
    #(
         parameter                 aWidth = 10, //! Address Port Width
         parameter                 dWidth = 8,  //! Data Port Width
         // Used as attributes, not values
         parameter                 rStyle = "no_rw_check"
     ) (
         input  logic              clk,   //! Clock
         input  logic              we,    //! Write Enable
         input  logic [aWidth-1:0] addr,  //! Address
         input  logic [dWidth-1:0] d,     //! Input Data Bus
         output logic [dWidth-1:0] q = 0  //! Output Data Bus
     );

    // Set the ram style to control implementation.
    (* ramstyle = rStyle *)
    logic [dWidth-1:0] ram[(1 << aWidth)-1:0]; //! Register to Hold Data

    // Read/Write from/to Memory
    always_ff @(posedge clk) begin : singlePort
        if(we) begin
            ram[addr] <= d;
            q <= d;
        end
        else begin
            q <= ram[addr];
        end
    end

endmodule
