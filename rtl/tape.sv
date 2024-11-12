//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2024, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// MSX1 CAS Player
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
// Notes from:
// https://konamiman.github.io/MSX2-Technical-Handbook/md/Chapter5a.html
//
// CASSETTE INTERFACE
//
// Cassette tape recorders are the least expensive external storage devices
// available for the MSX. Knowledge of the cassette interface is required to
// treat information in cassette tapes within assembly language programs.
// This section offers the necessary information.
//
// Baud Rate
//
// The following two baud rates can be used by the MSX cassette interface.
// When BASIC is invoked, 1200bps is set by default.
//
// ------------------------------------------------
// |  Baud rate  |        Characteristics         |
// |-------------+--------------------------------|
// |  1200 bps   |  Low speed / high reliability  |
// |-------------+--------------------------------|
// |  2400 bps   |  High speed / low reliability  |
// ------------------------------------------------
//
// The baud rate is specified by the fourth parameter of the SCREEN instruction
// or the second parameter of the CSAVE instruction. Once the baud rate is set,
// it stays at that value.
//
// SCREEN ,,,<baud rate>
// CSAVE  "filename",<baud rate>
//        (<baud rate> is 1 for 1200bps, 2 for 2400 bps)
//
//------------------------------------------------------------------------------

module tape
    (
        input          clk,
        input          ce_5m3,
        input          play,
        input          rewind,
        output [26:0]  ram_a,
        input  [7:0]   ram_di,
        output         ram_rd,
        input          buff_mem_ready,
        output         cas_out
    );

    typedef enum {
                STATE_SLEEP,
                STATE_INIT,
                STATE_SEARCH,
                STATE_PLAY_SILLENT,
                STATE_PLAY_SYNC,
                STATE_PLAY_DATA
            } player_state_t;

    player_state_t  state = STATE_SLEEP;

    wire[63:0] cas_sig = 64'h1FA6DEBACC137d74;
    wire[63:0] sig_pos = cas_sig  >> (8'd56 - (ram_a[2:0]<<3));

    assign cas_out = output_bit & output_on;

    // signature check
    reg sig_ok;

    always @(posedge clk) begin
        reg sig_temp_ok;
        if (buff_mem_ready && ~ram_rd) begin
            if (ram_a[2:0] == 0) begin
                sig_temp_ok <= (sig_pos[7:0] == ram_di);
                sig_ok      <= 0;
            end
            else begin
                sig_ok <= 0;
                if (~(sig_pos[7:0] == ram_di)) begin
                    sig_temp_ok <= 0;
                end
                else begin
                    if (ram_a[2:0] == 3'h7) begin
                        sig_ok <= sig_temp_ok & (sig_pos[7:0] == ram_di);
                    end
                end
            end
        end
    end

    reg        output_on = 0;
    reg        header;
    reg [10:0] counter;

    always @(posedge clk) begin
        if (buff_mem_ready)
            ram_rd <= 0;
        case (state)
            STATE_SLEEP: begin end
            STATE_INIT: begin
                if (buff_mem_ready && ~ram_rd) begin
                    ram_a     <= 0;
                    output_on <= 0;
                    state     <= STATE_SEARCH;
                    ram_rd    <= 1;
                end
            end
            STATE_SEARCH: begin
                if (sig_ok) begin
                    state   <= STATE_PLAY_SILLENT;
                    counter <= 1000;
                end
                else if (buff_mem_ready && ~ram_rd) begin
                    ram_a  <= ram_a + 1'd1;
                    ram_rd <= 1;
                end
            end
            STATE_PLAY_SILLENT: begin
                if (ce_baud) begin
                    counter <= counter - 1'b1;
                    if (counter == 0) begin
                        state   <= STATE_PLAY_SYNC;
                        counter <= 1454;
                    end
                end
            end
            STATE_PLAY_SYNC: begin
                if (counter == 0) begin
                    state  <= STATE_PLAY_DATA;
                    header <= 0;
                end
                else
                    header <= 1;
                if (byte_pos == 0) begin
                    output_on <= 1;
                    counter   <= counter - 1'b1;
                end
            end
            STATE_PLAY_DATA: begin
                if (sig_ok) begin
                    state <= STATE_PLAY_SYNC;
                    counter <= 1454;
                    if (buff_mem_ready && ~ram_rd) begin
                        ram_a  <= ram_a + 1'd1;
                        ram_rd <= 1;
                    end
                end
                else if (byte_pos == 0) begin
                    if (buff_mem_ready && ~ram_rd) begin
                        ram_a  <= ram_a + 1'd1;
                        ram_rd <= 1;
                    end
                end
            end
        endcase
        if (rewind) begin
            state <= STATE_INIT;
        end
    end

    // Send byte
    reg [3:0] byte_pos = 0;
    reg [7:0] send_byte;

    always @(posedge clk) begin
        reg [10:0] byte_out;
        if (byte_pos == 0) begin
            byte_out = header ? 11'h7FF : {2'b11, ram_di, 1'b0}; // 1'b0 startbit, 2'b11 stop bit
            byte_pos = 4'd11;
        end
        if (cnt == 0) begin
            send_bit = byte_out[0];
            if (ce_baud) begin
                byte_out = {1'b0, byte_out[10:1]};
                byte_pos = byte_pos - 1'b1;
            end
        end
    end

    // Send bit
    reg send_bit;
    reg output_bit;

    always @(posedge clk) begin
        reg bit_out;
        if (ce_baud) begin
            if (cnt == 2'h0) begin
                output_bit = 1;
                bit_out    = send_bit;
            end
            else begin
                output_bit = (bit_out & ~cnt[0]) | (~bit_out & ~cnt[1]);
            end
        end
    end

    // Baud generator
    reg [1:0] cnt = 2'h0;
    reg       ce_baud;

    always @(posedge clk) begin
        reg [10:0] baud_div;
        ce_baud = 0;

        if (ce_5m3 && play) begin
            if (baud_div == 11'h0) begin
                ce_baud  = 1;
                baud_div = 11'd559;
                cnt      = cnt + 1'b1;
            end
            else begin
                baud_div = baud_div - 1'b1;
            end
        end
    end

endmodule
