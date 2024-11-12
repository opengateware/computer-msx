//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Analogue Pocket Arcade Audio Filters
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

module arcade_filters
    (
        // Clock
        input  logic        clk,
        // Filter Switch
        input  logic  [3:0] afilter_sw,
        // Filter Config
        output logic [31:0] flt_rate,      // Sampling Frequency
        output logic [39:0] cx,            // Base gain
        output logic  [7:0] cx0, cx1, cx2, // gain scale for X0, X1, X2
        output logic [23:0] cy0, cy1, cy2  // gain scale for Y0, Y1, Y2
    );

    always_ff @(posedge clk) begin
        case(afilter_sw)
            1: begin // Arcade LPF 2khz 1st
                flt_rate <= 32'd7056000;
                cx       <= 40'd425898;
                cx0      <= 8'd3;
                cx1      <= 8'd3;
                cx2      <= 8'd1;
                cy0      <= -24'd6234907;
                cy1      <=  24'd6179109;
                cy2      <= -24'd2041353;
            end
            2: begin // Arcade LPF 2khz 2nd
                flt_rate <= 32'd7056000;
                cx       <= 40'd2420697;
                cx0      <= 8'd2;
                cx1      <= 8'd1;
                cx2      <= 8'd0;
                cy0      <= -24'd4189022;
                cy1      <=  24'd2091876;
                cy2      <= 24'd0;
            end
            3: begin // Arcade LPF 4khz 1st
                flt_rate <= 32'd7056000;
                cx       <= 40'd851040;
                cx0      <= 8'd3;
                cx1      <= 8'd3;
                cx2      <= 8'd1;
                cy0      <= -24'd6231182;
                cy1      <=  24'd6171753;
                cy2      <= -24'd2037720;
            end
            4: begin // Arcade LPF 4khz 2nd
                flt_rate <= 32'd7056000;
                cx       <= 40'd9670619;
                cx0      <= 8'd2;
                cx1      <= 8'd1;
                cx2      <= 8'd0;
                cy0      <= -24'd4183740;
                cy1      <=  24'd2086614;
                cy2      <= 24'd0;
            end
            5: begin // Arcade LPF 6khz 1st
                flt_rate <= 32'd7056000;
                cx       <= 40'd1275428;
                cx0      <= 8'd3;
                cx1      <= 8'd3;
                cx2      <= 8'd1;
                cy0      <= -24'd6227464;
                cy1      <=  24'd6164410;
                cy2      <= -24'd2034094;
            end
            6: begin // Arcade LPF 6khz 2nd
                flt_rate <= 32'd7056000;
                cx       <= 40'd21731566;
                cx0      <= 8'd2;
                cx1      <= 8'd1;
                cx2      <= 8'd0;
                cy0      <= -24'd4178458;
                cy1      <=  24'd2081365;
                cy2      <= 24'd0;
            end
            7: begin // Arcade LPF 8khz 1st
                flt_rate <= 32'd7056000;
                cx       <= 40'd1699064;
                cx0      <= 8'd3;
                cx1      <= 8'd3;
                cx2      <= 8'd1;
                cy0      <= -24'd6223752;
                cy1      <=  24'd6157080;
                cy2      <= -24'd2030475;
            end
            8: begin // Arcade LPF 8khz 2nd
                flt_rate <= 32'd7056000;
                cx       <= 40'd38585417;
                cx0      <= 8'd2;
                cx1      <= 8'd1;
                cx2      <= 8'd0;
                cy0      <= -24'd4173176;
                cy1      <=  24'd2076130;
                cy2      <= 24'd0;
            end
            default: begin
                flt_rate <= 7056000;
                cx       <= 4258969;
                cx0      <= 3;
                cx1      <= 3;
                cx2      <= 1;
                cy0      <= -24'd6216759;
                cy1      <=  24'd6143386;
                cy2      <= -24'd2023767;
            end
        endcase
    end

endmodule
