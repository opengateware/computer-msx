//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Async SRAM Controller
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

module sram_async
    #(
         parameter AW = 17,               //! Address Width
         parameter DW = 16                //! Data Width
     ) (
         // User Interface
         input  logic [AW-1:0] addr,      //! Address
         input  logic [DW-1:0] din,       //! Data In
         output logic [DW-1:0] dout,      //! Data Out
         input  logic          we_n,      //! Write Enable
         input  logic          oe_n,      //! Output Enable
         input  logic    [1:0] be_n,      //! Byte Enable - [1] Upper Byte Mask | [0] Lower Byte Mask
         // SRAM Interface
         output logic [AW-1:0] sram_addr, //! Address
         inout  logic [DW-1:0] sram_dq,   //! Data In/Out
         output logic          sram_we_n, //! Write Enable
         output logic          sram_oe_n, //! Output Enable
         output logic          sram_ub_n, //! Upper Byte Mask
         output logic          sram_lb_n  //! Lower Byte Mask
     );

    assign sram_addr = addr;
    assign sram_dq   = sram_we_n ? {DW{1'bZ}} : din;
    assign dout      = sram_dq;
    assign sram_we_n = we_n;
    assign sram_oe_n = oe_n;
    assign sram_ub_n = be_n[1];
    assign sram_lb_n = be_n[0];

endmodule


