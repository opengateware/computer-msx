//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2024, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Simple SDRAM controller with universal 8/16 bit mode
//
// Copyright (c) 2015-2019, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2013, Mike Field <hamster@snap.net.nz>
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
// Implementation using Micron MT48LC16M16A2 – 4 Meg x 16 x 4 banks SDR SDRAM
//------------------------------------------------------------------------------

module sdram
    (
        input             init,        // Reset to initialize RAM
        input             clk,         // Clock ~100MHz
        // SDRAM signals
        inout  reg [15:0] SDRAM_DQ,    // 16 bit bidirectional data bus
        output reg [12:0] SDRAM_A,     // 13 bit multiplexed address bus
        output reg        SDRAM_DQML,  // Lower Input/Output Mask
        output reg        SDRAM_DQMH,  // Upper Input/Output Mask
        output reg  [1:0] SDRAM_BA,    // Two banks
        output            SDRAM_nCS,   // A single chip select
        output            SDRAM_nWE,   // Write enable
        output            SDRAM_nRAS,  // Row address select
        output            SDRAM_nCAS,  // Columns address select
        output            SDRAM_CKE,   // Clock enable
        output            SDRAM_CLK,   // SDRAM Clock
        // User Interface
        input      [24:0] addr,        // 25 bit address for 8bit mode. addr[0] = 0 for 16bit mode for correct operations.
        output      [7:0] dout,        // Data output to cpu
        input       [7:0] din,         // Data input from cpu
        input             we,          // Cpu requests write
        input             rd,          // Cpu requests read
        output reg        ready        // Dout is valid. Ready to accept new read/write.
    );

    assign SDRAM_CKE  = 1;
    assign SDRAM_nCS  = 0;
    assign SDRAM_nRAS = command[2];
    assign SDRAM_nCAS = command[1];
    assign SDRAM_nWE  = command[0];
    assign {SDRAM_DQMH,SDRAM_DQML} = SDRAM_A[12:11];

    // no burst configured
    localparam BURST_LENGTH         = 3'b000;   // 000=1, 001=2, 010=4, 011=8
    localparam ACCESS_TYPE          = 1'b0;     // 0=sequential, 1=interleaved
    localparam CAS_LATENCY          = 3'd2;     // 2 for < 100MHz, 3 for >100MHz
    localparam OP_MODE              = 2'b00;    // only 00 (standard operation) allowed
    localparam NO_WRITE_BURST       = 1'b1;     // 0= write burst enabled, 1=only single access write
    localparam MODE                 = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};

    localparam sdram_startup_cycles = 14'd12100;// 100us, plus a little more, @ 100MHz
    localparam cycles_per_refresh   = 14'd780;  // (64000*100)/8192-1 Calc'd as (64ms @ 100MHz)/8192 rose
    localparam startup_refresh_max  = 14'b11111111111111;

    // SDRAM commands
    wire [2:0] CMD_NOP              = 3'b111;
    wire [2:0] CMD_ACTIVE           = 3'b011;
    wire [2:0] CMD_READ             = 3'b101;
    wire [2:0] CMD_WRITE            = 3'b100;
    wire [2:0] CMD_PRECHARGE        = 3'b010;
    wire [2:0] CMD_AUTO_REFRESH     = 3'b001;
    wire [2:0] CMD_LOAD_MODE        = 3'b000;

    reg [13:0] refresh_count = startup_refresh_max - sdram_startup_cycles;
    reg  [2:0] command;
    reg [24:0] save_addr;

    reg [15:0] data;
    assign dout = save_addr[0] ? data[15:8] : data[7:0];

    typedef enum {
        STATE_STARTUP,
        STATE_OPEN_1, STATE_OPEN_2,
        STATE_IDLE,	  STATE_IDLE_1, STATE_IDLE_2, STATE_IDLE_3,
        STATE_IDLE_4, STATE_IDLE_5, STATE_IDLE_6, STATE_IDLE_7
    } state_t;

    always @(posedge clk) begin
        reg old_we, old_rd;
        reg [CAS_LATENCY:0] data_ready_delay;

        reg  [7:0] new_data;
        reg        new_we;
        reg        new_rd;
        reg        save_we = 1'b1;

        state_t state = STATE_STARTUP;

        SDRAM_DQ <= 16'bZ;
        command  <= CMD_NOP;
        refresh_count  <= refresh_count+1'b1;

        data_ready_delay <= {1'b0, data_ready_delay[CAS_LATENCY:1]};

        if(data_ready_delay[0])
            {ready, data}  <= {1'b1, SDRAM_DQ};

        case(state)
            STATE_STARTUP: begin
                SDRAM_A    <= 0;
                SDRAM_BA   <= 0;

                if (refresh_count == startup_refresh_max-31) begin
                    command     <= CMD_PRECHARGE;
                    SDRAM_A[10] <= 1;  // all banks
                    SDRAM_BA    <= 2'b00;
                end
                if (refresh_count == startup_refresh_max-23) begin
                    command     <= CMD_AUTO_REFRESH;
                end
                if (refresh_count == startup_refresh_max-15) begin
                    command     <= CMD_AUTO_REFRESH;
                end
                if (refresh_count == startup_refresh_max-7) begin
                    command     <= CMD_LOAD_MODE;
                    SDRAM_A     <= MODE;
                end

                if(!refresh_count) begin
                    state         <= STATE_IDLE;
                    ready         <= 1;
                    refresh_count <= 0;
                end
            end

            STATE_IDLE_7: begin state <= STATE_IDLE_6; end
            STATE_IDLE_6: begin state <= STATE_IDLE_5; end
            STATE_IDLE_5: begin state <= STATE_IDLE_4; end
            STATE_IDLE_4: begin state <= STATE_IDLE_3; end
            STATE_IDLE_3: begin state <= STATE_IDLE_2; end
            STATE_IDLE_2: begin state <= STATE_IDLE_1; end
            STATE_IDLE_1: begin
                state <= STATE_IDLE;
                // mask possible refresh to reduce colliding.
                if(refresh_count > cycles_per_refresh) begin
                    state         <= STATE_IDLE_7;
                    command       <= CMD_AUTO_REFRESH;
                    refresh_count <= 0;
                end
            end

            STATE_IDLE: begin
                // Priority is to issue a refresh if one is outstanding
                if(refresh_count > (cycles_per_refresh<<1))
                    state <= STATE_IDLE_1;
                else if(new_rd | new_we) begin
                    new_we    <= 0;
                    new_rd    <= 0;
                    save_addr <= addr;
                    save_we   <= new_we;
                    state     <= STATE_OPEN_1;
                    command   <= CMD_ACTIVE;
                    SDRAM_A   <= addr[13:1];
                    SDRAM_BA  <= addr[24:23];
                end
            end

            STATE_OPEN_1: begin state <= STATE_OPEN_2; end

            STATE_OPEN_2: begin
                SDRAM_A      <= {save_we & ~save_addr[0], save_we & save_addr[0], 2'b10, save_addr[22:14]};
                if(save_we) begin
                    command  <= CMD_WRITE;
                    SDRAM_DQ <= {new_data[7:0], new_data[7:0]};
                    ready    <= 1;
                    state    <= STATE_IDLE_2;
                end
                else begin
                    command                       <= CMD_READ;
                    data_ready_delay[CAS_LATENCY] <= 1;
                    state                         <= STATE_IDLE_5;
                end
            end
        endcase

        if(init) begin
            state         <= STATE_STARTUP;
            refresh_count <= startup_refresh_max - sdram_startup_cycles;
        end

        old_we <= we;
        if(we & ~old_we) begin
            {ready, new_we, new_data} <= {1'b0, 1'b1, din};
        end

        old_rd <= rd;
        if(rd & ~old_rd) begin
            if(ready & ~save_we & (save_addr[24:1] == addr[24:1])) begin
                save_addr <= addr;
            end
            else begin
                {ready, new_rd} <= {1'b0, 1'b1};
            end
        end
    end

    altddio_out #(
        .extend_oe_disable      ( "OFF"          ),
        .intended_device_family ( "Cyclone V"    ),
        .invert_output          ( "OFF"          ),
        .lpm_hint               ( "UNUSED"       ),
        .lpm_type               ( "altddio_out"  ),
        .oe_reg                 ( "UNREGISTERED" ),
        .power_up_high          ( "OFF"          ),
        .width                  ( 1              )
    ) sdramclk_ddr (
        .datain_h               ( 1'b0           ),
        .datain_l               ( 1'b1           ),
        .outclock               ( clk            ),
        .dataout                ( SDRAM_CLK      ),
        .aclr                   ( 1'b0           ),
        .aset                   ( 1'b0           ),
        .oe                     ( 1'b1           ),
        .outclocken             ( 1'b1           ),
        .sclr                   ( 1'b0           ),
        .sset                   ( 1'b0           )
    );

endmodule
