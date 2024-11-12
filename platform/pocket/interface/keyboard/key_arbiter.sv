//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket USB HID Keyboard/Mouse and PS/2 Scan Code Translation
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

module key_arbiter
    (
        input  logic         clk,        //! Clock input
        input  logic         reset,      //! Reset input
        input  logic         fifo_ready, //! FIFO is not empty
        input  logic [125:0] fifo_din,   //! FIFO 126-bit input data
        output logic         fifo_rd,    //! Read Request to FIFO when no data is being processed
        output logic   [3:0] key_idx,    //! Key Index
        output logic   [8:0] scancode    //! 9-bit output chunk
    );

    //! ------------------------------------------------------------------------
    //! Request new data when all chunks have been processed
    //! ------------------------------------------------------------------------
    assign fifo_rd = !data_valid && fifo_ready;

    //! ------------------------------------------------------------------------
    //! State Machine Controller
    //! ------------------------------------------------------------------------
    logic [3:0] cycle_counter; // Counter for clock cycles
    logic       data_valid;    // Flag to indicate if the current data is valid

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_idx       <= 4'h0;
            cycle_counter <= 4'h0;
            data_valid    <= 1'b0;
        end
        else if(fifo_ready && !data_valid) begin
            key_idx       <= 4'h1;
            cycle_counter <= 4'h0;
            data_valid    <= 1'b1;
        end
        else if(data_valid) begin
            if (scancode == 9'h0) begin
                if (key_idx < 4'hE) begin
                    key_idx <= key_idx + 4'b1;
                end else begin
                    key_idx    <= 4'h0;
                    data_valid <= 1'b0;
                end
                cycle_counter <= 4'h0;
            end
            else if (cycle_counter == 4'h4) begin
                if (key_idx < 4'hE) begin
                    key_idx <= key_idx + 4'b1;
                end else begin
                    key_idx    <= 4'h0;
                    data_valid <= 1'b0;
                end
                cycle_counter <= 4'h0;
            end
            else begin
                cycle_counter <= cycle_counter + 4'b1;
            end
        end
    end

    //! ------------------------------------------------------------------------
    //! State Machine Logic
    //! ------------------------------------------------------------------------
    always_comb begin
        case (key_idx)
            4'h1:    scancode = fifo_din[125:117]; // Scancode MOD 1
            4'h2:    scancode = fifo_din[116:108]; // Scancode MOD 2
            4'h3:    scancode = fifo_din[107:099]; // Scancode MOD 3
            4'h4:    scancode = fifo_din[098:090]; // Scancode MOD 4
            4'h5:    scancode = fifo_din[089:081]; // Scancode MOD 5
            4'h6:    scancode = fifo_din[080:072]; // Scancode MOD 6
            4'h7:    scancode = fifo_din[071:063]; // Scancode MOD 7
            4'h8:    scancode = fifo_din[062:054]; // Scancode MOD 8
            4'h9:    scancode = fifo_din[053:045]; // Scancode 1
            4'hA:    scancode = fifo_din[044:036]; // Scancode 2
            4'hB:    scancode = fifo_din[035:027]; // Scancode 3
            4'hC:    scancode = fifo_din[026:018]; // Scancode 4
            4'hD:    scancode = fifo_din[017:009]; // Scancode 5
            4'hE:    scancode = fifo_din[008:000]; // Scancode 6
            default: scancode = 9'h0;
        endcase
    end

endmodule
