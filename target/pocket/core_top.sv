//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2022, Analogue Enterprises Limited
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
// Platform Specific top-level
// Instantiated by the real top-level: apf_top
//------------------------------------------------------------------------------

`default_nettype none

module core_top
    #(
         //! ------------------------------------------------------------------------
         //! System Configuration Parameters
         //! ------------------------------------------------------------------------
         // Analogizer
        parameter USE_ANALOGIZER = 1,     //! Enable Support for Analogizer
         // Memory
         parameter USE_SDRAM    = 1,       //! Enable SDRAM
         parameter USE_SRAM     = 0,       //! Enable SRAM
         parameter USE_CRAM0    = 0,       //! Enable Cellular RAM #1
         parameter USE_CRAM1    = 0,       //! Enable Cellular RAM #2
         // Video
         parameter BPP_R        = 8,       //! Bits Per Pixel Red
         parameter BPP_G        = 8,       //! Bits Per Pixel Green
         parameter BPP_B        = 8,       //! Bits Per Pixel Blue
         // Audio
         parameter AUDIO_DW     = 16,      //! Audio Bits
         parameter AUDIO_S      = 1,       //! Signed Audio
         parameter STEREO       = 0,       //! Stereo Output
         parameter AUDIO_MIX    = 0,       //! [0] No Mix | [1] 25% | [2] 50% | [3] 100% (mono)
         // Gamepad/Joystick
         parameter JOY_PADS     = 2,       //! Total Number of Gamepads
         parameter JOY_ALT      = 1,       //! 2 Players Alternate
         // Data I/O - [MPU -> FPGA]
         parameter DIO_MASK     = 4'h0,    //! Upper 4 bits of address
         parameter DIO_AW       = 27,      //! Address Width
         parameter DIO_DW       = 8,       //! Data Width (8 or 16 bits)
         parameter DIO_DELAY    = 7,       //! Number of clock cycles to delay each write output
         parameter DIO_HOLD     = 4,       //! Number of clock cycles to hold the ioctl_wr signal high
         // HiScore I/O - [MPU <-> FPGA]
         parameter HS_AW        = 16,      //! Max size of game RAM address for highscores
         parameter HS_SW        = 8,       //! Max size of capture RAM For highscore data (default 8 = 256 bytes max)
         parameter HS_CFG_AW    = 2,       //! Max size of RAM address for highscore.dat entries (default 4 = 16 entries max)
         parameter HS_CFG_LW    = 2,       //! Max size of length for each highscore.dat entries (default 1 = 256 bytes max)
         parameter HS_CONFIG    = 2,       //! Dataslot index for config transfer
         parameter HS_DATA      = 3,       //! Dataslot index for save data transfer
         parameter HS_NVM_SZ    = 32'd93,  //! Number bytes required for Save
         parameter HS_MASK      = 4'h1,    //! Upper 4 bits of address
         parameter HS_WR_DELAY  = 4,       //! Number of clock cycles to delay each write output
         parameter HS_WR_HOLD   = 1,       //! Number of clock cycles to hold the nvram_wr signal high
         parameter HS_RD_DELAY  = 4,       //! Number of clock cycles it takes for a read to complete
         // Save I/O - [MPU <-> FPGA]
         parameter SIO_MASK     = 4'h1,    //! Upper 4 bits of address
         parameter SIO_AW       = 27,      //! Address Width
         parameter SIO_DW       = 8,       //! Data Width (8 or 16 bits)
         parameter SIO_WR_DELAY = 4,       //! Number of clock cycles to delay each write output
         parameter SIO_WR_HOLD  = 1,       //! Number of clock cycles to hold the nvram_wr signal high
         parameter SIO_RD_DELAY = 4,       //! Number of clock cycles it takes for a read to complete
         parameter SIO_SAVE_IDX = 2        //! Dataslot index for save data transfer
     ) (
         //! --------------------------------------------------------------------
         //! Clock Inputs 74.25mhz.
         //! Not Phase Aligned, Treat These Domains as Asynchronous
         //! --------------------------------------------------------------------
         input wire          clk_74a, // mainclk1
         input wire          clk_74b, // mainclk1

         //! --------------------------------------------------------------------
         //! Cartridge Interface
         //! --------------------------------------------------------------------
         // switches between 3.3v and 5v mechanically
         // output enable for multibit translators controlled by pic32
         // GBA AD[15:8]
         inout  wire   [7:0] cart_tran_bank2,
         output wire         cart_tran_bank2_dir,
         // GBA AD[7:0]
         inout  wire   [7:0] cart_tran_bank3,
         output wire         cart_tran_bank3_dir,
         // GBA A[23:16]
         inout  wire   [7:0] cart_tran_bank1,
         output wire         cart_tran_bank1_dir,
         // GBA [7] PHI#
         // GBA [6] WR#
         // GBA [5] RD#
         // GBA [4] CS1#/CS#
         //     [3:0] unwired
         inout  wire   [7:4] cart_tran_bank0,
         output wire         cart_tran_bank0_dir,
         // GBA CS2#/RES#
         inout  wire         cart_tran_pin30,
         output wire         cart_tran_pin30_dir,
         // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
         // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
         // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
         // and general IO drive this pin.
         output wire         cart_pin30_pwroff_reset,
         // GBA IRQ/DRQ
         inout  wire         cart_tran_pin31,
         output wire         cart_tran_pin31_dir,

         //! --------------------------------------------------------------------
         //! Infrared
         //! --------------------------------------------------------------------
         input  wire         port_ir_rx,
         output wire         port_ir_tx,
         output wire         port_ir_rx_disable,

         //! --------------------------------------------------------------------
         //! GBA link port
         //! --------------------------------------------------------------------
         inout  wire         port_tran_si,
         output wire         port_tran_si_dir,
         inout  wire         port_tran_so,
         output wire         port_tran_so_dir,
         inout  wire         port_tran_sck,
         output wire         port_tran_sck_dir,
         inout  wire         port_tran_sd,
         output wire         port_tran_sd_dir,

         //! --------------------------------------------------------------------
         //! Cellular PSRAM 0 and 1, two chips (64mbit x2 dual die per chip)
         //! --------------------------------------------------------------------
         output wire [21:16] cram0_a,
         inout  wire  [15:0] cram0_dq,
         input  wire         cram0_wait,
         output wire         cram0_clk,
         output wire         cram0_adv_n,
         output wire         cram0_cre,
         output wire         cram0_ce0_n,
         output wire         cram0_ce1_n,
         output wire         cram0_oe_n,
         output wire         cram0_we_n,
         output wire         cram0_ub_n,
         output wire         cram0_lb_n,

         output wire [21:16] cram1_a,
         inout  wire  [15:0] cram1_dq,
         input  wire         cram1_wait,
         output wire         cram1_clk,
         output wire         cram1_adv_n,
         output wire         cram1_cre,
         output wire         cram1_ce0_n,
         output wire         cram1_ce1_n,
         output wire         cram1_oe_n,
         output wire         cram1_we_n,
         output wire         cram1_ub_n,
         output wire         cram1_lb_n,

         //! --------------------------------------------------------------------
         //! SDRAM, 512mbit 16bit
         //! --------------------------------------------------------------------
         output wire  [12:0] dram_a,        // Address bus
         output wire   [1:0] dram_ba,       // Bank select (single bits)
         inout  wire  [15:0] dram_dq,       // Bidirectional data bus
         output wire   [1:0] dram_dqm,      // High/low byte mask
         output wire         dram_clk,      // Chip clock
         output wire         dram_cke,      // Clock enable
         output wire         dram_ras_n,    // Select row address (active low)
         output wire         dram_cas_n,    // Select column address (active low)
         output wire         dram_we_n,     // Write enable (active low)

         //! --------------------------------------------------------------------
         //! SRAM, 1mbit 16bit
         //! --------------------------------------------------------------------
         output wire  [16:0] sram_a,        // Address bus
         inout  wire  [15:0] sram_dq,       // Bidirectional data bus
         output wire         sram_oe_n,     // Output enable
         output wire         sram_we_n,     // Write enable
         output wire         sram_ub_n,     // Upper Byte Mask
         output wire         sram_lb_n,     // Lower Byte Mask

         //! --------------------------------------------------------------------
         //! vblank driven by dock for sync in a certain mode
         //! --------------------------------------------------------------------
         input  wire         vblank,

         //! --------------------------------------------------------------------
         //! I/O to 6515D breakout USB UART
         //! --------------------------------------------------------------------
         output wire         dbg_tx,
         input  wire         dbg_rx,

         //! --------------------------------------------------------------------
         //! I/O pads near jtag connector user can solder to
         //! --------------------------------------------------------------------
         output wire         user1,
         input  wire         user2,

         //! --------------------------------------------------------------------
         //! RFU internal i2c bus
         //! --------------------------------------------------------------------
         inout  wire         aux_sda,
         output wire         aux_scl,

         //! --------------------------------------------------------------------
         //! RFU, do not use !!!
         //! --------------------------------------------------------------------
         output wire         vpll_feed,

         //! --------------------------------------------------------------------
         //! Logical Connections ////////////////////////////////////////////////
         //! --------------------------------------------------------------------

         //! --------------------------------------------------------------------
         //! Video Output to Scaler
         //! --------------------------------------------------------------------
         output wire  [23:0] video_rgb,
         output wire         video_rgb_clock,
         output wire         video_rgb_clock_90,
         output wire         video_hs,
         output wire         video_vs,
         output wire         video_de,
         output wire         video_skip,

         //! --------------------------------------------------------------------
         //! Audio
         //! --------------------------------------------------------------------
         output wire         audio_mclk,
         output wire         audio_lrck,
         output wire         audio_dac,
         input  wire         audio_adc,

         //! --------------------------------------------------------------------
         //! Bridge Bus Connection (synchronous to clk_74a)
         //! --------------------------------------------------------------------
         output wire         bridge_endian_little,
         input  wire  [31:0] bridge_addr,
         input  wire         bridge_rd,
         output reg   [31:0] bridge_rd_data,
         input  wire         bridge_wr,
         input  wire  [31:0] bridge_wr_data,

         //! --------------------------------------------------------------------
         //! Controller Data
         //! --------------------------------------------------------------------
         input  wire  [31:0] cont1_key,
         input  wire  [31:0] cont2_key,
         input  wire  [31:0] cont3_key,
         input  wire  [31:0] cont4_key,
         input  wire  [31:0] cont1_joy,
         input  wire  [31:0] cont2_joy,
         input  wire  [31:0] cont3_joy,
         input  wire  [31:0] cont4_joy,
         input  wire  [15:0] cont1_trig,
         input  wire  [15:0] cont2_trig,
         input  wire  [15:0] cont3_trig,
         input  wire  [15:0] cont4_trig
     );

     //Analogizer settings
    generate
    if(USE_ANALOGIZER == 1) begin
    localparam [7:0] ADDRESS_ANALOGIZER_CONFIG = 8'hF7;
    end
    endgenerate

    // not using the IR port, so turn off both the LED, and
    // disable the receive circuit to save power
    assign port_ir_tx         = 0;
    assign port_ir_rx_disable = 1;

    // bridge endianness
    assign bridge_endian_little = 0;

    // cart is unused, so set all level translators accordingly
    // directions are 0:IN, 1:OUT
    generate
    if(USE_ANALOGIZER == 0) begin
    assign cart_tran_bank3         = 8'hzz;
    assign cart_tran_bank3_dir     = 1'b0;
    assign cart_tran_bank2         = 8'hzz;
    assign cart_tran_bank2_dir     = 1'b0;
    assign cart_tran_bank1         = 8'hzz;
    assign cart_tran_bank1_dir     = 1'b0;
    assign cart_tran_bank0         = 4'hf;
    assign cart_tran_bank0_dir     = 1'b1;
    assign cart_tran_pin30         = 1'b0;  // reset or cs2, we let the hw control it by itself
    assign cart_tran_pin30_dir     = 1'bz;
    assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
    assign cart_tran_pin31         = 1'bz;  // input
    assign cart_tran_pin31_dir     = 1'b0;  // input
    end
    endgenerate

    // link port is input only
    assign port_tran_so      = 1'bz;
    assign port_tran_so_dir  = 1'b0; // SO is output only
    assign port_tran_si      = 1'bz;
    assign port_tran_si_dir  = 1'b0; // SI is input only
    assign port_tran_sck     = 1'bz;
    assign port_tran_sck_dir = 1'b0; // clock direction can change
    assign port_tran_sd      = 1'bz;
    assign port_tran_sd_dir  = 1'b0; // SD is input and not used

    assign dbg_tx    = 1'bZ;
    assign user1     = 1'bZ;
    assign aux_scl   = 1'bZ;
    assign vpll_feed = 1'bZ;


    // Tie off the memory the pins not being used
    generate
        if(USE_CRAM0 == 0) begin
            assign cram0_a     = 'h0;
            assign cram0_dq    = {16{1'bZ}};
            assign cram0_clk   = 0;
            assign cram0_adv_n = 1;
            assign cram0_cre   = 0;
            assign cram0_ce0_n = 1;
            assign cram0_ce1_n = 1;
            assign cram0_oe_n  = 1;
            assign cram0_we_n  = 1;
            assign cram0_ub_n  = 1;
            assign cram0_lb_n  = 1;
        end

        if(USE_CRAM1 == 0) begin
            assign cram1_a     = 'h0;
            assign cram1_dq    = {16{1'bZ}};
            assign cram1_clk   = 0;
            assign cram1_adv_n = 1;
            assign cram1_cre   = 0;
            assign cram1_ce0_n = 1;
            assign cram1_ce1_n = 1;
            assign cram1_oe_n  = 1;
            assign cram1_we_n  = 1;
            assign cram1_ub_n  = 1;
            assign cram1_lb_n  = 1;
        end

        if(USE_SDRAM == 0) begin
            assign dram_a     = 'h0;
            assign dram_ba    = 'h0;
            assign dram_dq    = {16{1'bZ}};
            assign dram_dqm   = 'h0;
            assign dram_clk   = 'h0;
            assign dram_cke   = 'h0;
            assign dram_ras_n = 'h1;
            assign dram_cas_n = 'h1;
            assign dram_we_n  = 'h1;
        end

        if(USE_SRAM == 0) begin
            assign sram_a    = 'h0;
            assign sram_dq   = {16{1'bZ}};
            assign sram_oe_n = 1;
            assign sram_we_n = 1;
            assign sram_ub_n = 1;
            assign sram_lb_n = 1;
        end
    endgenerate

    //! ------------------------------------------------------------------------
    //! Host/Target Command Handler
    //! ------------------------------------------------------------------------
    wire        reset_n;  // driven by host commands, can be used as core-wide reset
    wire [31:0] cmd_bridge_rd_data;

    // bridge host commands
    // synchronous to clk_74a
    wire        status_boot_done  = pll_core_locked_s;
    wire        status_setup_done = pll_core_locked_s; // rising edge triggers a target command
    wire        status_running    = reset_n;           // we are running as soon as reset_n goes high

    wire        dataslot_requestread;
    wire [15:0] dataslot_requestread_id;
    wire        dataslot_requestread_ack = 1;
    wire        dataslot_requestread_ok  = 1;

    wire        dataslot_requestwrite;
    wire [15:0] dataslot_requestwrite_id;
    wire [31:0] dataslot_requestwrite_size;
    wire        dataslot_requestwrite_ack = 1;
    wire        dataslot_requestwrite_ok  = 1;

    wire        dataslot_update;
    wire [15:0] dataslot_update_id;
    wire [31:0] dataslot_update_size;

    wire        dataslot_allcomplete;

    wire [31:0] rtc_epoch_seconds;
    wire [31:0] rtc_date_bcd;
    wire [31:0] rtc_time_bcd;
    wire        rtc_valid;

    wire        savestate_supported;
    wire [31:0] savestate_addr;
    wire [31:0] savestate_size;
    wire [31:0] savestate_maxloadsize;

    wire        savestate_start;
    wire        savestate_start_ack;
    wire        savestate_start_busy;
    wire        savestate_start_ok;
    wire        savestate_start_err;

    wire        savestate_load;
    wire        savestate_load_ack;
    wire        savestate_load_busy;
    wire        savestate_load_ok;
    wire        savestate_load_err;

    wire        osnotify_inmenu;

    // bridge target commands
    // synchronous to clk_74a
    reg         target_dataslot_read;
    reg         target_dataslot_write;
    reg         target_dataslot_getfile;    // require additional param/resp structs to be mapped
    reg         target_dataslot_openfile;   // require additional param/resp structs to be mapped

    wire        target_dataslot_ack;
    wire        target_dataslot_done;
    wire  [2:0] target_dataslot_err;

    reg  [15:0] target_dataslot_id;
    reg  [31:0] target_dataslot_slotoffset;
    reg  [31:0] target_dataslot_bridgeaddr;
    reg  [31:0] target_dataslot_length;

    wire [31:0] target_buffer_param_struct; // to be mapped/implemented when using some Target commands
    wire [31:0] target_buffer_resp_struct;  // to be mapped/implemented when using some Target commands

    // bridge data slot access
    // synchronous to clk_74a
    wire  [9:0] datatable_addr;
    wire        datatable_wren;
    wire [31:0] datatable_data;
    wire [31:0] datatable_q;

    core_bridge_cmd icb
    (
        .clk                        ( clk_74a                    ),
        .reset_n                    ( reset_n                    ),

        .bridge_endian_little       ( bridge_endian_little       ),
        .bridge_addr                ( bridge_addr                ),
        .bridge_rd                  ( bridge_rd                  ),
        .bridge_rd_data             ( cmd_bridge_rd_data         ),
        .bridge_wr                  ( bridge_wr                  ),
        .bridge_wr_data             ( bridge_wr_data             ),

        .status_boot_done           ( status_boot_done           ),
        .status_setup_done          ( status_setup_done          ),
        .status_running             ( status_running             ),

        .dataslot_requestread       ( dataslot_requestread       ),
        .dataslot_requestread_id    ( dataslot_requestread_id    ),
        .dataslot_requestread_ack   ( dataslot_requestread_ack   ),
        .dataslot_requestread_ok    ( dataslot_requestread_ok    ),

        .dataslot_requestwrite      ( dataslot_requestwrite      ),
        .dataslot_requestwrite_id   ( dataslot_requestwrite_id   ),
        .dataslot_requestwrite_size ( dataslot_requestwrite_size ),
        .dataslot_requestwrite_ack  ( dataslot_requestwrite_ack  ),
        .dataslot_requestwrite_ok   ( dataslot_requestwrite_ok   ),

        .dataslot_update            ( dataslot_update            ),
        .dataslot_update_id         ( dataslot_update_id         ),
        .dataslot_update_size       ( dataslot_update_size       ),

        .dataslot_allcomplete       ( dataslot_allcomplete       ),

        .rtc_epoch_seconds          ( rtc_epoch_seconds          ),
        .rtc_date_bcd               ( rtc_date_bcd               ),
        .rtc_time_bcd               ( rtc_time_bcd               ),
        .rtc_valid                  ( rtc_valid                  ),

        .savestate_supported        ( savestate_supported        ),
        .savestate_addr             ( savestate_addr             ),
        .savestate_size             ( savestate_size             ),
        .savestate_maxloadsize      ( savestate_maxloadsize      ),

        .savestate_start            ( savestate_start            ),
        .savestate_start_ack        ( savestate_start_ack        ),
        .savestate_start_busy       ( savestate_start_busy       ),
        .savestate_start_ok         ( savestate_start_ok         ),
        .savestate_start_err        ( savestate_start_err        ),

        .savestate_load             ( savestate_load             ),
        .savestate_load_ack         ( savestate_load_ack         ),
        .savestate_load_busy        ( savestate_load_busy        ),
        .savestate_load_ok          ( savestate_load_ok          ),
        .savestate_load_err         ( savestate_load_err         ),

        .osnotify_inmenu            ( osnotify_inmenu            ),

        .target_dataslot_read       ( target_dataslot_read       ),
        .target_dataslot_write      ( target_dataslot_write      ),
        .target_dataslot_getfile    ( target_dataslot_getfile    ),
        .target_dataslot_openfile   ( target_dataslot_openfile   ),

        .target_dataslot_ack        ( target_dataslot_ack        ),
        .target_dataslot_done       ( target_dataslot_done       ),
        .target_dataslot_err        ( target_dataslot_err        ),

        .target_dataslot_id         ( target_dataslot_id         ),
        .target_dataslot_slotoffset ( target_dataslot_slotoffset ),
        .target_dataslot_bridgeaddr ( target_dataslot_bridgeaddr ),
        .target_dataslot_length     ( target_dataslot_length     ),

        .target_buffer_param_struct ( target_buffer_param_struct ),
        .target_buffer_resp_struct  ( target_buffer_resp_struct  ),

        .datatable_addr             ( datatable_addr             ),
        .datatable_wren             ( datatable_wren             ),
        .datatable_data             ( datatable_data             ),
        .datatable_q                ( datatable_q                )
    );

    //! END OF APF /////////////////////////////////////////////////////////////

    //! ////////////////////////////////////////////////////////////////////////
    //! @ System Modules
    //! ////////////////////////////////////////////////////////////////////////

    //! ------------------------------------------------------------------------
    //! APF Bridge Read Data
    //! ------------------------------------------------------------------------
    wire [31:0] int_bridge_rd_data;
    wire [31:0] nvm_bridge_rd_data, nvm_bridge_rd_data_s;

    // Synchronize nvm_bridge_rd_data into clk_74a domain before usage
    synch_3 sync_nvm(nvm_bridge_rd_data, nvm_bridge_rd_data_s, clk_74a);

 generate
    if(USE_ANALOGIZER == 1) begin
    wire [31:0] analogizer_bridge_rd_data;

    always_comb begin
        casex(bridge_addr)
            32'h10000000:                      begin bridge_rd_data <= nvm_bridge_rd_data_s;      end // HiScore/NVRAM/SRAM Save
            32'hF0000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Reset
            32'hF0000010:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Service Mode Switch
            32'hF1000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // DIP Switches
            32'hF2000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Modifiers
            32'hF3000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // A/V Filters
            32'hF4000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Extra DIP Switches
            32'hF8xxxxxx:                      begin bridge_rd_data <= cmd_bridge_rd_data;        end // APF Bridge (Reserved)
            32'hFA000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Status Low  [31:0]
            32'hFB000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Status High [63:32]
            32'hFE000000:                      begin bridge_rd_data <= {29'h0, mapper_info};      end
            {ADDRESS_ANALOGIZER_CONFIG,24'h0}: begin bridge_rd_data <= analogizer_bridge_rd_data; end // Analogizer
            default:                           begin bridge_rd_data <= 0;                         end
        endcase
    end
    end else begin
    always_comb begin
        casex(bridge_addr)
            32'h10000000:                      begin bridge_rd_data <= nvm_bridge_rd_data_s;      end // HiScore/NVRAM/SRAM Save
            32'hF0000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Reset
            32'hF0000010:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Service Mode Switch
            32'hF1000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // DIP Switches
            32'hF2000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Modifiers
            32'hF3000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // A/V Filters
            32'hF4000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Extra DIP Switches
            32'hF8xxxxxx:                      begin bridge_rd_data <= cmd_bridge_rd_data;        end // APF Bridge (Reserved)
            32'hFA000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Status Low  [31:0]
            32'hFB000000:                      begin bridge_rd_data <= int_bridge_rd_data;        end // Status High [63:32]
            32'hFE000000:                      begin bridge_rd_data <= {29'h0, mapper_info};      end
            default:                           begin bridge_rd_data <= 0;                         end
        endcase
    end
    end
 endgenerate

    //! ------------------------------------------------------------------------
    //! Pause Core (Analogue OS Menu/Module Request)
    //! ------------------------------------------------------------------------
    wire pause_core, pause_req;

    pause_crtl core_pause
    (
        .clk_sys    ( clk_sys         ),
        .os_inmenu  ( osnotify_inmenu ),
        .pause_req  ( pause_req       ),
        .pause_core ( pause_core      )
    );

    //! ------------------------------------------------------------------------
    //! Interact: Dip Switches, Modifiers, Filters and Reset
    //! ------------------------------------------------------------------------
    wire  [7:0] dip_sw0, dip_sw1, dip_sw2, dip_sw3;
    wire  [7:0] ext_sw0, ext_sw1, ext_sw2, ext_sw3;
    wire  [7:0] mod_sw0, mod_sw1, mod_sw2, mod_sw3;
    wire  [3:0] scnl_sw, smask_sw, afilter_sw, vol_att;
    wire [63:0] status;
    wire        reset_sw, svc_sw;

    interact pocket_interact
    (
        // Clocks and Reset
        .clk_74a          ( clk_74a            ),
        .clk_sync         ( clk_sys            ),
        .reset_n          ( reset_n            ),
        // Pocket Bridge
        .bridge_addr      ( bridge_addr        ),
        .bridge_wr        ( bridge_wr          ),
        .bridge_wr_data   ( bridge_wr_data     ),
        .bridge_rd        ( bridge_rd          ),
        .bridge_rd_data   ( int_bridge_rd_data ),
        // Service Mode Switch
        .svc_sw           ( svc_sw             ),
        // DIP Switches
        .dip_sw0          ( dip_sw0            ),
        .dip_sw1          ( dip_sw1            ),
        .dip_sw2          ( dip_sw2            ),
        .dip_sw3          ( dip_sw3            ),
        // Extra DIP Switches
        .ext_sw0          ( ext_sw0            ),
        .ext_sw1          ( ext_sw1            ),
        .ext_sw2          ( ext_sw2            ),
        .ext_sw3          ( ext_sw3            ),
        // Modifiers
        .mod_sw0          ( mod_sw0            ),
        .mod_sw1          ( mod_sw1            ),
        .mod_sw2          ( mod_sw2            ),
        .mod_sw3          ( mod_sw3            ),
        // Status (Legacy Support)
        .status           ( status             ),
        // Filters Switches
        .scnl_sw          ( scnl_sw            ),
        .smask_sw         ( smask_sw           ),
        .afilter_sw       ( afilter_sw         ),
        .vol_att          ( vol_att            ),
        // Reset Switch
        .reset_sw         ( reset_sw           )
    );


    //! ------------------------------------------------------------------------
    //! Audio
    //! ------------------------------------------------------------------------
    wire [AUDIO_DW-1:0] core_snd_l, core_snd_r; // Audio Mono/Left/Right

    audio_mixer #(.DW(AUDIO_DW),.STEREO(STEREO)) pocket_audio_mixer
    (
        // Clocks and Reset
        .clk_74b    ( clk_74b    ),
        .reset      ( reset_sw   ),
        // Controls
        .afilter_sw ( afilter_sw ),
        .vol_att    ( vol_att    ),
        .mix        ( AUDIO_MIX  ),
        .pause_core ( pause_core ),
        // Audio From Core
        .is_signed  ( AUDIO_S    ),
        .core_l     ( core_snd_l ),
        .core_r     ( core_snd_r ),
        // I2S
        .audio_mclk ( audio_mclk ),
        .audio_lrck ( audio_lrck ),
        .audio_dac  ( audio_dac  )
    );

    //! ------------------------------------------------------------------------
    //! Video
    //! ------------------------------------------------------------------------
    wire       [2:0] video_preset;     // Video Preset Configuration
    wire [BPP_R-1:0] core_r;           // Video Red
    wire [BPP_G-1:0] core_g;           // Video Green
    wire [BPP_B-1:0] core_b;           // Video Blue
    wire             core_hs, core_hb; // Horizontal Sync/Blank
    wire             core_vs, core_vb; // Vertical Sync/Blank
    wire             core_de;          // Display Enable
    wire [23:0] pocket_video_rgb;

    assign core_de = ~(core_hb | core_vb);

    video_mixer #(.RW(BPP_R),.GW(BPP_G),.BW(BPP_B)) pocket_video_mixer
    (
        // Clocks
        .clk_74a                  ( clk_74a                  ),
        .clk_sys                  ( clk_sys                  ),
        .clk_vid                  ( clk_vid                  ),
        .clk_vid_90deg            ( clk_vid_90deg            ),
        // Input Controls
        .video_preset             ( video_preset             ),
        .scnl_sw                  ( scnl_sw                  ),
        .smask_sw                 ( smask_sw                 ),
        // Input Video from Core
        .core_r                   ( core_r                   ),
        .core_g                   ( core_g                   ),
        .core_b                   ( core_b                   ),
        .core_vs                  ( core_vs                  ),
        .core_hs                  ( core_hs                  ),
        .core_de                  ( core_de                  ),
        // Output to Display
        .video_rgb                ( pocket_video_rgb         ),
        .video_vs                 ( video_vs                 ),
        .video_hs                 ( video_hs                 ),
        .video_de                 ( video_de                 ),
        .video_rgb_clock          ( video_rgb_clock          ),
        .video_rgb_clock_90       ( video_rgb_clock_90       ),
        // Pocket Bridge Slots
        .dataslot_requestwrite    ( dataslot_requestwrite    ), // [i]
        .dataslot_requestwrite_id ( dataslot_requestwrite_id ), // [i]
        .dataslot_allcomplete     ( dataslot_allcomplete     ), // [i]
        // MPU -> FPGA (MPU Write to FPGA)
        // Pocket Bridge
        .bridge_endian_little     ( bridge_endian_little     ), // [i]
        .bridge_addr              ( bridge_addr              ), // [i]
        .bridge_wr                ( bridge_wr                ), // [i]
        .bridge_wr_data           ( bridge_wr_data           )  // [i]
    );

    assign video_rgb = video_rgb_msx;

    //! ------------------------------------------------------------------------
    //! Data I/O
    //! ------------------------------------------------------------------------
    wire              ioctl_download;
    wire       [15:0] ioctl_index;
    wire              ioctl_wr;
    wire [DIO_AW-1:0] ioctl_addr;
    wire [DIO_DW-1:0] ioctl_data;

    data_io #(.MASK(DIO_MASK),.AW(DIO_AW),.DW(DIO_DW),.DELAY(DIO_DELAY),.HOLD(DIO_HOLD)) pocket_data_io
    (
        // Clocks and Reset
        .clk_74a                  ( clk_74a                  ),
        .clk_memory               ( clk_sys                  ),
        // Pocket Bridge Slots
        .dataslot_requestwrite    ( dataslot_requestwrite    ), // [i]
        .dataslot_requestwrite_id ( dataslot_requestwrite_id ), // [i]
        .dataslot_allcomplete     ( dataslot_allcomplete     ), // [i]
        // MPU -> FPGA (MPU Write to FPGA)
        // Pocket Bridge
        .bridge_endian_little     ( bridge_endian_little     ), // [i]
        .bridge_addr              ( bridge_addr              ), // [i]
        .bridge_wr                ( bridge_wr                ), // [i]
        .bridge_wr_data           ( bridge_wr_data           ), // [i]
        // Controller Interface
        .ioctl_download           ( ioctl_download           ), // [o]
        .ioctl_index              ( ioctl_index              ), // [o]
        .ioctl_wr                 ( ioctl_wr                 ), // [o]
        .ioctl_addr               ( ioctl_addr               ), // [o]
        .ioctl_data               ( ioctl_data               )  // [o]
    );

    //! ------------------------------------------------------------------------
    //! Gamepad/Analog Stick
    //! ------------------------------------------------------------------------
    // Player 1
    // - DPAD
    wire       p1_up,     p1_down,   p1_left,   p1_right;
    wire       p1_btn_y,  p1_btn_x,  p1_btn_b,  p1_btn_a;
    wire       p1_btn_l1, p1_btn_l2, p1_btn_l3;
    wire       p1_btn_r1, p1_btn_r2, p1_btn_r3;
    wire       p1_select, p1_start;
    // - Analog
    wire       j1_up,     j1_down,   j1_left,   j1_right;
    wire [7:0] j1_lx,     j1_ly,     j1_rx,     j1_ry;

    // Player 2
    // - DPAD
    wire       p2_up,     p2_down,   p2_left,   p2_right;
    wire       p2_btn_y,  p2_btn_x,  p2_btn_b,  p2_btn_a;
    wire       p2_btn_l1, p2_btn_l2, p2_btn_l3;
    wire       p2_btn_r1, p2_btn_r2, p2_btn_r3;
    wire       p2_select, p2_start;
    // - Analog
    wire       j2_up,     j2_down,   j2_left,   j2_right;
    wire [7:0] j2_lx,     j2_ly,     j2_rx,     j2_ry;

    // Single Player or Alternate 2 Players for Arcade
    wire m_start1, m_start2;
    wire m_coin1,  m_coin2, m_coin;
    wire m_up,     m_down,  m_left, m_right;
    wire m_btn1,   m_btn2,  m_btn3, m_btn4;
    wire m_btn5,   m_btn6,  m_btn7, m_btn8;

    gamepad #(.JOY_PADS(JOY_PADS),.JOY_ALT(JOY_ALT)) pocket_gamepad
    (
        .clk_sys   ( clk_sys   ),
        // Pocket PAD Interface
        .cont1_key ( cont1_key ), .cont1_joy ( cont1_joy ),
        .cont2_key ( cont2_key ), .cont2_joy ( cont2_joy ),
        .cont3_key ( cont3_key ), .cont3_joy ( cont3_joy ),
        .cont4_key ( cont4_key ), .cont4_joy ( cont4_joy ),
        // Player 1
        .p1_up     ( p1_up     ), .p1_down   ( p1_down   ),
        .p1_left   ( p1_left   ), .p1_right  ( p1_right  ),
        .p1_y      ( p1_btn_y  ), .p1_x      ( p1_btn_x  ),
        .p1_b      ( p1_btn_b  ), .p1_a      ( p1_btn_a  ),
        .p1_l1     ( p1_btn_l1 ), .p1_r1     ( p1_btn_r1 ),
        .p1_l2     ( p1_btn_l2 ), .p1_r2     ( p1_btn_r2 ),
        .p1_l3     ( p1_btn_l3 ), .p1_r3     ( p1_btn_r3 ),
        .p1_se     ( p1_select ), .p1_st     ( p1_start  ),
        .j1_up     ( j1_up     ), .j1_down   ( j1_down   ),
        .j1_left   ( j1_left   ), .j1_right  ( j1_right  ),
        .j1_lx     ( j1_lx     ), .j1_ly     ( j1_ly     ),
        .j1_rx     ( j1_rx     ), .j1_ry     ( j1_ry     ),
        // Player 2
        .p2_up     ( p2_up     ), .p2_down   ( p2_down   ),
        .p2_left   ( p2_left   ), .p2_right  ( p2_right  ),
        .p2_y      ( p2_btn_y  ), .p2_x      ( p2_btn_x  ),
        .p2_b      ( p2_btn_b  ), .p2_a      ( p2_btn_a  ),
        .p2_l1     ( p2_btn_l1 ), .p2_r1     ( p2_btn_r1 ),
        .p2_l2     ( p2_btn_l2 ), .p2_r2     ( p2_btn_r2 ),
        .p2_l3     ( p2_btn_l3 ), .p2_r3     ( p2_btn_r3 ),
        .p2_se     ( p2_select ), .p2_st     ( p2_start  ),
        .j2_up     ( j2_up     ), .j2_down   ( j2_down   ),
        .j2_left   ( j2_left   ), .j2_right  ( j2_right  ),
        .j2_lx     ( j2_lx     ), .j2_ly     ( j2_ly     ),
        .j2_rx     ( j2_rx     ), .j2_ry     ( j2_ry     ),
        // Single Player or Alternate 2 Players for Arcade
        .m_coin    ( m_coin    ),                           // Coinage P1 or P2
        .m_up      ( m_up      ), .m_down    ( m_down    ), // Up/Down
        .m_left    ( m_left    ), .m_right   ( m_right   ), // Left/Right
        .m_btn1    ( m_btn1    ), .m_btn4    ( m_btn4    ), // Y/X
        .m_btn2    ( m_btn2    ), .m_btn3    ( m_btn3    ), // B/A
        .m_btn5    ( m_btn5    ), .m_btn6    ( m_btn6    ), // L1/R1
        .m_btn7    ( m_btn7    ), .m_btn8    ( m_btn8    ), // L2/R2
        .m_coin1   ( m_coin1   ), .m_coin2   ( m_coin2   ), // P1/P2 Coin
        .m_start1  ( m_start1  ), .m_start2  ( m_start2  )  // P1/P2 Start
    );

    //! ------------------------------------------------------------------------
    //! Clocks
    //! ------------------------------------------------------------------------
    wire pll_core_locked, pll_core_locked_s;
    wire clk_sys;       // Core : 42.954536 Mhz
    wire clk_vid;       // Video:  5.369317 Mhz
    wire clk_vid_90deg; // Video:  5.369317 Mhz @ 90deg Phase Shift
    wire clk_ram;       // SDRAM: 85.909072 Mhz

    core_pll core_pll
    (
        .refclk   ( clk_74a ),
        .rst      ( 0       ),

        .outclk_0 ( clk_sys       ),
        .outclk_1 ( clk_vid       ),
        .outclk_2 ( clk_vid_90deg ),
        .outclk_3 ( clk_ram       ),

        .locked   ( pll_core_locked )
    );

    // Synchronize pll_core_locked into clk_74a domain before usage
    synch_3 sync_lck(pll_core_locked, pll_core_locked_s, clk_74a);

    //! ------------------------------------------------------------------------
    //! Keyboard
    //! ------------------------------------------------------------------------
    wire [10:0] ps2_key;
    wire [10:0] ps2_key_general;

    usb_keyboard u_usb_kbd
    (
        .clk        ( clk_sys    ),
        .reset      ( reset_sw   ),
        .cont3_key  ( cont3_key  ),
        .cont3_joy  ( cont3_joy  ),
        .cont3_trig ( cont3_trig ),
        .ps2_key    ( ps2_key    )
    );

    //! ------------------------------------------------------------------------
    //! @ IP Core RTL
    //! ------------------------------------------------------------------------
    wire [1:0] sdram_size     = 2'h2; // 0 - none, 1 - 32MB, 2 - 64MB, 3 - 128MB

    reg  [1:0] rom_enabled    = 2'b00;
    wire       ioctl_isROMA   = ioctl_download && ioctl_index == 16'h0;
    wire       ioctl_isROMB   = ioctl_download && ioctl_index == 16'h1;
    wire       ioctl_isBIOS   = ioctl_download && ioctl_index == 16'h2;
    wire       ioctl_isFWBIOS = ioctl_download && ioctl_index == 16'h3;
    wire       ioctl_isCAS    = ioctl_download && ioctl_index == 16'h4;

    always @(posedge clk_sys) begin
        if (svc_sw) begin // Reset & Detach ROM Cartridges
            rom_enabled <= 2'b00;
        end
        else begin
            if (ioctl_isROMA) begin rom_enabled[0] <= 1'b1; end
            if (ioctl_isROMB) begin rom_enabled[1] <= 1'b1; end
        end
    end

    //! CLOCKS
    reg ce_10m7 = 0;
    reg ce_5m3  = 0;

    always @(posedge clk_sys) begin
        reg [2:0] div;

        div     <=  div + 1'd1;
        ce_10m7 <= !div[1:0];
        ce_5m3  <= !div[2:0];
    end

    //! RESET
    reg [7:0] last_mapper = 8'h0;
    always @(posedge clk_sys) begin
        last_mapper <= dip_sw0;
    end

    wire mapper_reset = last_mapper != dip_sw0;
    wire msx_reset = ioctl_isROMA | ioctl_isROMB | ioctl_isBIOS | mapper_reset;

    //! CORE
    wire        hsync_n, vsync_n;
    wire        ioctl_waitROM;
    wire  [2:0] mapper_info;

    reg hs_o, vs_o;
    always @(posedge clk_sys) begin
        hs_o <= ~hsync_n;
        if(~hs_o & ~hsync_n) begin
            vs_o <= ~vsync_n;
        end
    end

    assign core_hs = hs_o;
    assign core_vs = vs_o;
    assign video_preset = (dip_sw1[1]) ? 3'd1 : 3'd0;

    wire  [5:0] joy0;   
    wire  [5:0] joy1 ;  
    wire [10:0] joy_key;

    generate
        if(USE_ANALOGIZER == 0) begin
            assign joy0    = { p1_btn_b, p1_btn_a, p1_up, p1_down, p1_left, p1_right };
            assign joy1    = { p2_btn_b, p2_btn_a, p2_up, p2_down, p2_left, p2_right };
            assign joy_key = { p1_start, p1_select, p1_btn_r1, p1_btn_l1, p1_btn_x, p1_btn_y };
            assign ps2_key_general = ps2_key | ps2_joy;
        end
        else begin
            assign joy0    = { p1_controls[5],p1_controls[4],p1_controls[0],p1_controls[1],p1_controls[2],p1_controls[3]};
            assign joy1    = { p2_controls[5],p2_controls[4],p2_controls[0],p2_controls[1],p2_controls[2],p2_controls[3]};
            assign joy_key = { p1_controls[15],p1_controls[14],p1_controls[9],p1_controls[8],p1_controls[6],p1_controls[7]};
            assign ps2_key_general = ps2_key | ps2_joy | snac_ps2_key;
        end
    endgenerate
    
    wire [23:0] key_map = { mod_sw2, mod_sw1, mod_sw0 };

    wire [10:0] ps2_joy;

    joy2ps2 u_joy2key
    (
        .clk     ( clk_sys    ),
        .reset   ( reset_sw   ),
        .enable  ( dip_sw1[2] ),
        .key_map ( key_map    ),
        .joy_key ( joy_key    ),
        .ps2_key ( ps2_joy    )
    );

    msx1 msx1
    (
        .clk            ( clk_sys              ),      // [i]
        .ce_10m7        ( ce_10m7              ),      // [i]
        .reset          ( msx_reset | reset_sw ),      // [i]

        .vdp_pal        ( dip_sw1[0]           ),      // [i]
        .border         ( dip_sw1[1]           ),      // [i]

        .R              ( core_r               ),      // [o]
        .G              ( core_g               ),      // [o]
        .B              ( core_b               ),      // [o]
        .hsync_n        ( hsync_n              ),      // [o]
        .vsync_n        ( vsync_n              ),      // [o]
        .hblank         ( core_hb              ),      // [o]
        .vblank         ( core_vb              ),      // [o]

        .audio          ( core_snd_l           ),      // [o]

        .ps2_key ( ps2_key_general ),                  // [i]

        .joy0           ( joy0                 ),      // [i]
        .joy1           ( joy1                 ),      // [i]

        .ioctl_download ( ioctl_download       ),      // [i]
        .ioctl_index    ( ioctl_index[7:0]     ),      // [i]
        .ioctl_wr       ( ioctl_wr             ),      // [i]
        .ioctl_addr     ( ioctl_addr           ),      // [i]
        .ioctl_dout     ( ioctl_data           ),      // [i]
        .ioctl_isROMA   ( ioctl_isROMA         ),      // [i]
        .ioctl_isROMB   ( ioctl_isROMB         ),      // [i]
        .ioctl_isBIOS   ( ioctl_isBIOS         ),      // [i]
        .ioctl_isFWBIOS ( ioctl_isFWBIOS       ),      // [i]
        .ioctl_wait     ( ioctl_waitROM        ),      // [o]

        .cas_motor      ( /* CAS_motor      */ ),      // [o]
        .cas_audio_in   ( /* CAS_dout       */ ),      // [i]

        .rom_enabled    ( rom_enabled          ),      // [i]
        .slot_A         ( dip_sw0[3:0]         ),      // [i]
        .slot_B         ( dip_sw0[7:4]         ),      // [i]
        .mapper_info    ( mapper_info          ),      // [o]

        .img_mounted    ( /* img_mounted    */ ),      // signaling that new image has been mounted
        .img_size       ( /* img_size       */ ),      // size of image in bytes
        .img_wp         ( /* img_readonly   */ ),      // write protect

        .sd_lba         ( /* sd_lba[0]      */ ),
        .sd_rd          ( /* sd_rd          */ ),
        .sd_wr          ( /* sd_wr          */ ),
        .sd_ack         ( /* sd_ack         */ ),
        .sd_buff_addr   ( /* sd_buff_addr   */ ),
        .sd_buff_dout   ( /* sd_buff_dout   */ ),
        .sd_buff_din    ( /* sd_buff_din[0] */ ),
        .sd_buff_wr     ( /* sd_buff_wr     */ ),

        .sdram_dout     ( sdram_dout           ),
        .sdram_din      ( sdram_din            ),
        .sdram_addr     ( sdram_addr           ),
        .sdram_we       ( sdram_we             ),
        .sdram_rd       ( sdram_rd             ),
        .sdram_ready    ( sdram_ready          ),
        .sdram_size     ( sdram_size           )
    );

    //! SDRAM
    wire  [7:0] sdram_dout;
    wire  [7:0] sdram_din;
    wire [24:0] sdram_addr;
    wire        sdram_we;
    wire        sdram_rd;
    wire        sdram_ready;

    sdram sdram
    (
        .init       ( ~pll_core_locked_s ),
        .clk        ( clk_ram            ),

        .SDRAM_DQ   ( dram_dq            ),
        .SDRAM_A    ( dram_a             ),
        .SDRAM_DQML ( dram_dqm[0]        ),
        .SDRAM_DQMH ( dram_dqm[1]        ),
        .SDRAM_BA   ( dram_ba            ),
        .SDRAM_nCS  (                    ),
        .SDRAM_nWE  ( dram_we_n          ),
        .SDRAM_nRAS ( dram_ras_n         ),
        .SDRAM_nCAS ( dram_cas_n         ),
        .SDRAM_CKE  ( dram_cke           ),
        .SDRAM_CLK  ( dram_clk           ),

        .dout       ( sdram_dout         ),
        .din        ( sdram_din          ),
        .addr       ( sdram_addr         ),
        .we         ( sdram_we           ),
        .rd         ( sdram_rd           ),
        .ready      ( sdram_ready        )
    );

    // TODO: Implement Cassette on PSRAM/SRAM instead of DDR
    //! CAS load
    // wire        buff_mem_ready;

    // ddram buffer
    // (
    //     .reset (  reset_sw                                  ),
    //     .we    (  ioctl_isCAS && ioctl_wr                   ),
    //     .rd    ( ~ioctl_isCAS && CAS_rd                     ),
    //     .addr  (  ioctl_isCAS ? ioctl_addr[26:0] : CAS_addr ),
    //     .din   (  ioctl_data                                ),
    //     .dout  (  CAS_di                                    ),
    //     .ready (  buff_mem_ready                            ),
    // );

    // wire        CAS_rd;
    // wire [26:0] CAS_addr;
    // wire        CAS_dout;
    // wire  [7:0] CAS_di;
    // wire        CAS_motor;
    // wire        CAS_rewind = status[13] | ioctl_isCAS | reset;

    // tape cass
    // (
    //     .clk            ( clk_sys        ),
    //     .ce_5m3         ( ce_5m3         ),
    //     .cas_out        ( CAS_dout       ),
    //     .ram_a          ( CAS_addr       ),
    //     .ram_di         ( CAS_di         ),
    //     .ram_rd         ( CAS_rd         ),
    //     .buff_mem_ready ( buff_mem_ready ),
    //     .play           ( ~CAS_motor     ),
    //     .rewind         ( CAS_rewind     )
    // );


    /*[ANALOGIZER_HOOK_BEGIN]*/
    generate
    if(USE_ANALOGIZER == 1) begin
	 logic [7:0]  snac_ps2_code;
    logic        snac_ps2_code_new;
    logic [10:0] snac_ps2_key;

    ps2_to_key #(
    .STROBE_TOGGLE (1'b0),
    .HANDLE_PAUSE  (1'b1)
    ) u_ps2_to_key (
        .clk          (clk_sys),
        .reset        (msx_reset | reset_sw),
        .enable       (analogizer_ena),
        .ps2_code_new (snac_ps2_code_new),
        .ps2_code     (snac_ps2_code),
        .ps2_key      (snac_ps2_key)
    );
	 
    wire analogizer_ena;
    wire [3:0] analogizer_video_type;
    wire [4:0] snac_game_cont_type;
    wire [3:0] snac_cont_assignment;
    wire       pocket_blank_screen;

    //create aditional switch to blank Pocket screen.
    wire [23:0] video_rgb_msx;
    assign video_rgb_msx = (pocket_blank_screen && analogizer_ena) ? 24'h000000: pocket_video_rgb;

    //switch between Analogizer SNAC and Pocket Controls for P1-P2
    wire [15:0] p1_btn; 
    wire [15:0] p2_btn;
    wire [31:0] p1_joy; 
    wire [31:0] p2_joy;
    reg [31:0] p1_joystick;
    reg [31:0] p2_joystick;
    reg  [15:0] p1_controls;
    reg  [15:0] p2_controls;

    wire snac_is_analog = (snac_game_cont_type == 5'h12) || (snac_game_cont_type == 5'h13);

    //! Player 1 ---------------------------------------------------------------------------
    reg snac_p1_up, snac_p1_down, snac_p1_left, snac_p1_right;
    wire snac_p1_up_analog, snac_p1_down_analog, snac_p1_left_analog, snac_p1_right_analog;
    //using left analog joypad
    assign snac_p1_up_analog    = (p1_joy[15:8] < 8'h40) ? 1'b1 : 1'b0; //analog range UP 0x00 Idle 0x7F DOWN 0xFF, DEADZONE +- 0x15
    assign snac_p1_down_analog  = (p1_joy[15:8] > 8'hC0) ? 1'b1 : 1'b0; 
    assign snac_p1_left_analog  = (p1_joy[7:0]  < 8'h40) ? 1'b1 : 1'b0; //analog range LEFT 0x00 Idle 0x7F RIGHT 0xFF, DEADZONE +- 0x15
    assign snac_p1_right_analog = (p1_joy[7:0]  > 8'hC0) ? 1'b1 : 1'b0;

    always @(posedge clk_74a) begin
        snac_p1_up    <= (snac_is_analog) ? snac_p1_up_analog    : p1_btn[0];
        snac_p1_down  <= (snac_is_analog) ? snac_p1_down_analog  : p1_btn[1];
        snac_p1_left  <= (snac_is_analog) ? snac_p1_left_analog  : p1_btn[2];
        snac_p1_right <= (snac_is_analog) ? snac_p1_right_analog : p1_btn[3];
    end
    //! Player 2 ---------------------------------------------------------------------------
    reg snac_p2_up, snac_p2_down, snac_p2_left, snac_p2_right;
    wire snac_p2_up_analog, snac_p2_down_analog, snac_p2_left_analog, snac_p2_right_analog;
    //using left analog joypad
    assign snac_p2_up_analog    = (p2_joy[15:8] < 8'h40) ? 1'b1 : 1'b0; //analog range UP 0x00 Idle 0x7F DOWN 0xFF, DEADZONE +- 0x15
    assign snac_p2_down_analog  = (p2_joy[15:8] > 8'hC0) ? 1'b1 : 1'b0; 
    assign snac_p2_left_analog  = (p2_joy[7:0]  < 8'h40) ? 1'b1 : 1'b0; //analog range LEFT 0x00 Idle 0x7F RIGHT 0xFF, DEADZONE +- 0x15
    assign snac_p2_right_analog = (p2_joy[7:0]  > 8'hC0) ? 1'b1 : 1'b0;

    always @(posedge clk_74a) begin
        snac_p2_up    <= (snac_is_analog) ? snac_p2_up_analog    : p2_btn[0];
        snac_p2_down  <= (snac_is_analog) ? snac_p2_down_analog  : p2_btn[1];
        snac_p2_left  <= (snac_is_analog) ? snac_p2_left_analog  : p2_btn[2];
        snac_p2_right <= (snac_is_analog) ? snac_p2_right_analog : p2_btn[3];
    end
    always @(posedge clk_74a) begin
        reg [31:0] p1_pocket_btn, p1_pocket_joy;
        reg [31:0] p2_pocket_btn, p2_pocket_joy;

        if((snac_game_cont_type == 5'h0) || !analogizer_ena) begin //SNAC is disabled
        //if((snac_game_cont_type == 5'h0)) begin //SNAC is disabled
            p1_controls <= cont1_key;
            p2_controls <= cont2_key;
        end
        else begin
        case(snac_cont_assignment[1:0])
        2'h0: begin  //SNAC P1 -> Pocket P1
            p1_controls <= {p1_btn[15:4],snac_p1_right,snac_p1_left,snac_p1_down,snac_p1_up};
            p2_controls <= cont1_key;
            end
        2'h1: begin  //SNAC P1 -> Pocket P2
            p1_controls <= cont1_key;
            p2_controls <= p1_btn;
            end
        2'h2: begin //SNAC P1 -> Pocket P1, SNAC P2 -> Pocket P2
            p1_controls <= {p1_btn[15:4],snac_p1_right,snac_p1_left,snac_p1_down,snac_p1_up};
            p2_controls <= {p2_btn[15:4],snac_p2_right,snac_p2_left,snac_p2_down,snac_p2_up};
            end
        2'h3: begin //SNAC P1 -> Pocket P2, SNAC P2 -> Pocket P1
            p1_controls <= {p2_btn[15:4],snac_p2_right,snac_p2_left,snac_p2_down,snac_p2_up};
            p2_controls <= {p1_btn[15:4],snac_p1_right,snac_p1_left,snac_p1_down,snac_p1_up};
            end
        default: begin 
            p1_controls <= cont1_key;
            p2_controls <= cont2_key;
            end
        endcase
        end
    end

    wire [15:0] p1_btn_CK; 
    wire [15:0] p2_btn_CK;
    wire [31:0] p1_joy_CK; 
    wire [31:0] p2_joy_CK;
    
    synch_3 #(
    .WIDTH(16)
    ) p1b_s (
        p1_btn_CK,
        p1_btn,
        clk_74a
    );

   synch_3 #(
       .WIDTH(16)
   ) p2b_s (
       p2_btn_CK,
       p2_btn,
       clk_74a
   );

    synch_3 #(
    .WIDTH(32)
    ) p3b_s (
        p1_joy_CK,
        p1_joy,
        clk_74a
    );
        
    synch_3 #(
        .WIDTH(32)
    ) p4b_s (
        p2_joy_CK,
        p2_joy,
        clk_74a
    );


    // Video Y/C Encoder settings
    // Follows the Mike Simone Y/C encoder settings:
    // https://github.com/MikeS11/MiSTerFPGA_YC_Encoder
    // SET PAL and NTSC TIMING and pass through status bits. ** YC must be enabled in the qsf file **
    wire [39:0] CHROMA_PHASE_INC;
    wire [26:0] COLORBURST_RANGE;

    wire PALFLAG;

    parameter NTSC_REF = 3.579545;   
    parameter PAL_REF = 4.43361875;

    // Parameters to be modifed
    parameter CLK_VIDEO_NTSC = 42.954545; // Must be filled E.g XX.X Hz - CLK_VIDEO
    parameter CLK_VIDEO_PAL  = 42.954545; // Must be filled E.g XX.X Hz - CLK_VIDEO

    localparam [39:0] NTSC_PHASE_INC1 = 40'd91625958316; // ((NTSC_REF * 2^40) / CLK_VIDEO_NTSC)
    localparam [39:0] PAL_PHASE_INC1  = 40'd113487766399; // ((PAL_REF * 2^40) / CLK_VIDEO_PAL)
  
	localparam [6:0] COLORBURST_START1 = (3.7 * (CLK_VIDEO_NTSC/NTSC_REF));
	localparam [9:0] COLORBURST_NTSC_END1 = (9 * (CLK_VIDEO_NTSC/NTSC_REF)) + COLORBURST_START1;
	localparam [9:0] COLORBURST_PAL_END1 = (10 * (CLK_VIDEO_PAL/PAL_REF)) + COLORBURST_START1;

    assign PALFLAG = dip_sw1[0]; 

    assign CHROMA_PHASE_INC = PALFLAG ? PAL_PHASE_INC1 : NTSC_PHASE_INC1; 
    assign COLORBURST_RANGE = {COLORBURST_START1, COLORBURST_NTSC_END1, COLORBURST_PAL_END1};

    wire busy;

    openFPGA_Pocket_Analogizer #(.MASTER_CLK_FREQ(42_954_545), .LINE_LENGTH(290), .ADDRESS_ANALOGIZER_CONFIG(ADDRESS_ANALOGIZER_CONFIG)) analogizer (
        .clk_74a(clk_74a),
        .i_clk(clk_sys),
        .i_rst_apf(msx_reset | reset_sw), //i_rst_apf is active high
        .i_rst_core(msx_reset | reset_sw), //i_rst_core is active high

        //Video interface
        .video_clk(clk_sys),
        .R(core_r),
        .G(core_g),
        .B(core_b),
        .Hblank(core_hb),
        .Vblank(core_vb),
        .Hsync(~hsync_n), //composite SYNC on HSync.
        .Vsync(~vsync_n),

        //openFPGA Bridge interface
        .bridge_endian_little(bridge_endian_little),
        .bridge_addr(bridge_addr),
        .bridge_rd(bridge_rd),
        .analogizer_bridge_rd_data(analogizer_bridge_rd_data),
        .bridge_wr(bridge_wr),
        .bridge_wr_data(bridge_wr_data),

        //Analogizer settings
        .analogizer_ena_out(analogizer_ena),
        .snac_game_cont_type_out(snac_game_cont_type),
        .snac_cont_assignment_out(snac_cont_assignment),
        .analogizer_video_type_out(analogizer_video_type),
        .SC_fx_out(),
        .pocket_blank_screen_out(pocket_blank_screen),
        .analogizer_osd_out(),

        //Video Y/C Encoder interface
        .CHROMA_PHASE_INC(CHROMA_PHASE_INC),
        .COLORBURST_RANGE(COLORBURST_RANGE),
        .CHROMA_ADD(0),
        .CHROMA_MUL(0),
        .PALFLAG(PALFLAG),
        //Video SVGA Scandoubler interface
        .ce_pix(ce_10m7),
        .scandoubler(1'b1), //logic for disable/enable the scandoubler
        //SNAC interface
        .p1_btn_state(p1_btn_CK),
        .p1_joy_state(p1_joy_CK),
        .p2_btn_state(p2_btn_CK),  
        .p2_joy_state(p2_joy_CK),
        .p3_btn_state(),  
        .p4_btn_state(),
        .busy(busy),    
        //Pocket Analogizer IO interface to the Pocket cartridge port
        .cart_tran_bank2(cart_tran_bank2),
        .cart_tran_bank2_dir(cart_tran_bank2_dir),
        .cart_tran_bank3(cart_tran_bank3),
        .cart_tran_bank3_dir(cart_tran_bank3_dir),
        .cart_tran_bank1(cart_tran_bank1),
        .cart_tran_bank1_dir(cart_tran_bank1_dir),
        .cart_tran_bank0(cart_tran_bank0),
        .cart_tran_bank0_dir(cart_tran_bank0_dir),
        .cart_tran_pin30(cart_tran_pin30),
        .cart_tran_pin30_dir(cart_tran_pin30_dir),
        .cart_pin30_pwroff_reset(cart_pin30_pwroff_reset),
        .cart_tran_pin31(cart_tran_pin31),
        .cart_tran_pin31_dir(cart_tran_pin31_dir),
        //debug
        .o_stb(),
        .o_ps2_code_new(snac_ps2_code_new),
        .o_ps2_code(snac_ps2_code)
    );
    end
     endgenerate
    /*[ANALOGIZER_HOOK_END]*/

endmodule
