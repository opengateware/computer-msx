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

module msx1
    (
        input         clk,
        input         ce_10m7,
        input         reset,
        input         border,
        // Video
        output  [7:0] R,
        output  [7:0] G,
        output  [7:0] B,
        output        hsync_n,
        output        vsync_n,
        output        hblank,
        output        vblank,
        input         vdp_pal,
        // Audio
        output [15:0] audio,
        // Keyboard
        input  [10:0] ps2_key,
        // Gamepad/Joystick
        input   [5:0] joy0,
        input   [5:0] joy1,
        // I/O Controller
        input         ioctl_download,
        input   [7:0] ioctl_index,
        input         ioctl_wr,
        input  [24:0] ioctl_addr,
        input   [7:0] ioctl_dout,
        input         ioctl_isROMA,
        input         ioctl_isROMB,
        input         ioctl_isBIOS,
        input         ioctl_isFWBIOS,
        output        ioctl_wait,
        // Cassette
        output        cas_motor,
        input         cas_audio_in,
        // User Mode
        input   [1:0] rom_enabled,
        input   [3:0] slot_A,
        input   [3:0] slot_B,
        output  [2:0] mapper_info,
        // SDRAM
        input   [7:0] sdram_dout,
        output  [7:0] sdram_din,
        output [24:0] sdram_addr,
        output        sdram_we,
        output        sdram_rd,
        input         sdram_ready,
        input   [1:0] sdram_size,
        // VHD Image
        input         img_mounted,
        input  [31:0] img_size,
        input         img_wp,
        output [31:0] sd_lba,
        output        sd_rd,
        output        sd_wr,
        input         sd_ack,
        input   [8:0] sd_buff_addr,
        input   [7:0] sd_buff_dout,
        output  [7:0] sd_buff_din,
        input         sd_buff_wr,
        input         sd_din_strobe
    );

    //--------------------------------------------------------------------------
    // Audio MIX
    //--------------------------------------------------------------------------
    wire  [9:0] audioPSG   = ay_ch_mix + {keybeep, 5'b00000} + {(cas_audio_in & ~cas_motor), 4'b0000};
    wire [15:0] fm         = {2'b0, audioPSG, 4'b0000};
    wire [16:0] audio_mix  = {sound_slots[15], sound_slots} + {fm[15], fm};
    wire [15:0] compr[7:0] = '{{1'b1, audio_mix[13:0], 1'b0}, 16'h8000, 16'h8000, 16'h8000, 16'h7FFF, 16'h7FFF, 16'h7FFF,  {1'b0, audio_mix[13:0], 1'b0}};

    assign audio = compr[audio_mix[16:14]];

    //--------------------------------------------------------------------------
    // Clock generation
    //--------------------------------------------------------------------------
    wire clk_en_3m58_p, clk_en_3m58_n;

    cv_clock clock
    (
        .clk_i           ( clk           ),
        .clk_en_10m7_i   ( ce_10m7       ),
        .reset_n_i       ( ~reset        ),
        .clk_en_3m58_p_o ( clk_en_3m58_p ),
        .clk_en_3m58_n_o ( clk_en_3m58_n )
    );

    //--------------------------------------------------------------------------
    // Z80 CPU
    //--------------------------------------------------------------------------
    wire [15:0] a;
    wire  [7:0] d_to_cpu, d_from_cpu;
    wire        mreq_n, wr_n, m1_n, iorq_n, rd_n, rfrsh_n, wait_n;

    t80pa #(.Mode(0)) u_t80
    (
        .RESET_n ( ~reset        ),
        .CLK     ( clk           ),
        .CEN_p   ( clk_en_3m58_p ),
        .CEN_n   ( clk_en_3m58_n ),
        .WAIT_n  ( wait_n        ),
        .INT_n   ( vdp_int_n     ),
        .NMI_n   ( 1             ),
        .BUSRQ_n ( 1             ),
        .M1_n    ( m1_n          ),
        .MREQ_n  ( mreq_n        ),
        .IORQ_n  ( iorq_n        ),
        .RD_n    ( rd_n          ),
        .WR_n    ( wr_n          ),
        .RFSH_n  ( rfrsh_n       ),
        .HALT_n  ( 1             ),
        .BUSAK_n (               ),
        .A       ( a             ),
        .DI      ( d_to_cpu      ),
        .DO      ( d_from_cpu    )
    );

    //--------------------------------------------------------------------------
    // WAIT
    //--------------------------------------------------------------------------
    wire u1_2_q;
    wire exwait_n = 1;
    reg  wait_n2;

    ls74 u1_1
    (
        .clr ( exwait_n      ),
        .pre ( u1_2_q        ),
        .clk ( clk_en_3m58_p ),
        .d   ( m1_n          ),
        .q   ( wait_n        )
    );

    ls74 u1_2
    (
        .clr ( 1             ),
        .pre ( exwait_n      ),
        .clk ( clk_en_3m58_p ),
        .d   ( wait_n        ),
        .q   ( u1_2_q        )
    );

    //--------------------------------------------------------------------------
    // BIOS ROM
    //--------------------------------------------------------------------------
    wire [7:0] rom_q;
    wire [7:0] fw_rom_q;

    spram #(.addr_width(15), .mem_init_file("rom/cbios_main_msx1.mif"), .mem_name("ROM")) rom
    (
        .clock   ( clk          ),
        .address ( ioctl_isBIOS ? ioctl_addr[14:0] : a[14:0] ),
        .q       ( rom_q        ),
        .wren    ( ioctl_isBIOS ),
        .data    ( ioctl_dout   )
    );

    spram #(.addr_width(14), .mem_name("FWROM")) fw_rom
    (
        .clock   ( clk            ),
        .address ( ioctl_isFWBIOS ? ioctl_addr[13:0] : a[13:0] ),
        .q       ( fw_rom_q       ),
        .wren    ( ioctl_isFWBIOS ),
        .data    ( ioctl_dout     )
    );

    //--------------------------------------------------------------------------
    // Video RAM 16k
    //--------------------------------------------------------------------------
    wire [13:0] vram_a;
    wire  [7:0] vram_do;
    wire  [7:0] vram_di;
    wire        vram_we;

    spram #(.addr_width(14),.mem_name("VRAM")) vram
    (
        .clock   ( clk     ),
        .address ( vram_a  ),
        .wren    ( vram_we ),
        .data    ( vram_do ),
        .q       ( vram_di )
    );

    //--------------------------------------------------------------------------
    // TMS9928A Video Display Processor
    //--------------------------------------------------------------------------
    wire [7:0] d_from_vdp;
    wire       vdp_int_n;

    vdp18_core #(.compat_rgb_g(0)) vdp18
    (
        .clk_i         ( clk          ),
        .clk_en_10m7_i ( ce_10m7      ),
        .reset_n_i     ( ~reset       ),

        .csr_n_i       ( vdp_n | rd_n ),
        .csw_n_i       ( vdp_n | wr_n ),
        .mode_i        ( a[0]         ),
        .int_n_o       ( vdp_int_n    ),
        .cd_i          ( d_from_cpu   ),
        .cd_o          ( d_from_vdp   ),

        .vram_we_o     ( vram_we      ),
        .vram_a_o      ( vram_a       ),
        .vram_d_o      ( vram_do      ),
        .vram_d_i      ( vram_di      ),

        .border_i      ( border       ),
        .is_pal_i      ( vdp_pal      ),
        .rgb_r_o       ( R            ),
        .rgb_g_o       ( G            ),
        .rgb_b_o       ( B            ),
        .hsync_n_o     ( hsync_n      ),
        .vsync_n_o     ( vsync_n      ),
        .hblank_o      ( hblank       ),
        .vblank_o      ( vblank       ),
    );

    //--------------------------------------------------------------------------
    // IO Decoder
    //--------------------------------------------------------------------------
    wire vdp_n, psg_n, ppi_n, cen_n;

    io_decoder io_decoder
    (
        .addr   ( a      ),
        .iorq_n ( iorq_n ),
        .m1_n   ( m1_n   ),
        .vdp_n  ( vdp_n  ),
        .psg_n  ( psg_n  ),
        .ppi_n  ( ppi_n  ),
        .cen_n  ( cen_n  )
    );

    //--------------------------------------------------------------------------
    // 82C55 PPI
    //--------------------------------------------------------------------------
    wire [7:0] d_from_8255;
    wire [7:0] ppi_out_a, ppi_out_c;
    wire       keybeep = ppi_out_c[7];

    assign     cas_motor =  ppi_out_c[4];

    jt8255 PPI
    (
        .rst        ( reset       ),
        .clk        ( clk         ),
        .addr       ( a[1:0]      ),
        .din        ( d_from_cpu  ),
        .dout       ( d_from_8255 ),
        .rdn        ( rd_n        ),
        .wrn        ( wr_n        ),
        .csn        ( ppi_n       ),

        .porta_din  ( 8'h0        ),
        .portb_din  ( d_from_kb   ),
        .portc_din  ( 8'h0        ),

        .porta_dout ( ppi_out_a   ),
        .portb_dout (             ),
        .portc_dout ( ppi_out_c   )
    );

    //--------------------------------------------------------------------------
    // Memory mapper
    //--------------------------------------------------------------------------
    wire [3:0] SLTSL_n;
    wire       CS1_n, CS01_n, CS12_n, CS2_n;

    memory_mapper memory_mapper
    (
        .reset   ( reset     ),
        .addr    ( a         ),
        .ppi_n   ( ppi_n     ),
        .RAM_CS  ( ppi_out_a ),
        .mreq_n  ( mreq_n    ),
        .rfrsh_n ( rfrsh_n   ),
        .rd_n    ( rd_n      ),
        .SLTSL_n ( SLTSL_n   ),
        .CS1_n   ( CS1_n     ),
        .CS01_n  ( CS01_n    ),
        .CS12_n  ( CS12_n    ),
        .CS2_n   ( CS2_n     )
    );

    //--------------------------------------------------------------------------
    // CPU data multiplex
    //--------------------------------------------------------------------------
    assign d_to_cpu = ~(CS01_n | SLTSL_n[0]) ? rom_q        :
                      ~(CS2_n  | SLTSL_n[0]) ? fw_rom_q     :
                      ~(SLTSL_n[1])          ? d_from_slots :
                      ~(SLTSL_n[2])          ? d_from_slots :
                      ~(SLTSL_n[3])          ? d_from_slots :
                      ~(vdp_n | rd_n)        ? d_from_vdp   :
                      ~(psg_n | rd_n)        ? d_from_psg   :
                      ~(ppi_n | rd_n)        ? d_from_8255  :
                      8'hFF;

    //--------------------------------------------------------------------------
    // Keyboard decoder
    //--------------------------------------------------------------------------
    wire [7:0] d_from_kb;

    keyboard msx_key
    (
        .reset_n_i  ( ~reset         ),
        .clk_i      ( clk            ),
        .ps2_code_i ( ps2_key        ),
        .kb_addr_i  ( ppi_out_c[3:0] ),
        .kb_data_o  ( d_from_kb      )
    );

    //--------------------------------------------------------------------------
    // Sound AY-3-8910
    //--------------------------------------------------------------------------
    wire [7:0] d_from_psg, psg_ioa, psg_iob;
    wire [5:0] joy_a = psg_iob[4] ? 6'b111111 : {~joy0[5], ~joy0[4], ~joy0[0], ~joy0[1], ~joy0[2], ~joy0[3]};
    wire [5:0] joy_b = psg_iob[5] ? 6'b111111 : {~joy1[5], ~joy1[4], ~joy1[0], ~joy1[1], ~joy1[2], ~joy1[3]};
    wire [5:0] joyA  = joy_a & {psg_iob[0], psg_iob[1], 4'b1111};
    wire [5:0] joyB  = joy_b & {psg_iob[2], psg_iob[3], 4'b1111};

    assign psg_ioa = {cas_audio_in,1'b0, psg_iob[6] ? joyB : joyA};

    wire [9:0] ay_ch_mix;

    wire u21_1_q;
    ls74 u21_1
    (
        .clr ( !psg_n        ),
        .pre ( 1             ),
        .clk ( clk_en_3m58_p ),
        .d   ( !psg_n        ),
        .q   ( u21_1_q       )
    );

    wire u21_2_q;
    ls74 u21_2
    (
        .clr ( !psg_n        ),
        .pre ( 1             ),
        .clk ( clk_en_3m58_p ),
        .d   ( u21_1_q       ),
        .q   ( u21_2_q       )
    );

    wire psg_e    = !(!u21_2_q | clk_en_3m58_p) | psg_n;
    wire psg_bc   = !(a[0] | psg_e);
    wire psg_bdir = !(a[1] | psg_e);

    jt49_bus PSG
    (
        .rst_n   ( ~reset        ),
        .clk     ( clk           ),
        .clk_en  ( clk_en_3m58_n ),
        .bdir    ( psg_bdir      ),
        .bc1     ( psg_bc        ),
        .din     ( d_from_cpu    ),
        .sel     ( 0             ),
        .dout    ( d_from_psg    ),
        .sound   ( ay_ch_mix     ),
        .A       (               ),
        .B       (               ),
        .C       (               ),
        .IOA_in  ( psg_ioa       ),
        .IOA_out (               ),
        .IOB_in  ( 8'hFF         ),
        .IOB_out ( psg_iob       )
    );

    //--------------------------------------------------------------------------
    // SLOTS
    //--------------------------------------------------------------------------
    wire  [7:0] d_from_slots;
    wire [15:0] sound_slots;

    slots slots
    (
        .clk           ( clk           ),
        .clk_en        ( clk_en_3m58_p ),
        .reset         ( reset         ),
        .addr          ( a             ),
        .wr_n          ( wr_n          ),
        .rd_n          ( rd_n          ),
        .CS1_n         ( CS1_n         ),
        .CS2_n         ( CS2_n         ),
        .CS12_n        ( CS12_n        ),
        .SLTSL_n       ( SLTSL_n       ),
        .d_from_cpu    ( d_from_cpu    ),
        .d_to_cpu      ( d_from_slots  ),
        .sound         ( sound_slots   ),
        .ioctl_wr      ( ioctl_wr      ),
        .ioctl_addr    ( ioctl_addr    ),
        .ioctl_dout    ( ioctl_dout    ),
        .ioctl_isROMA  ( ioctl_isROMA  ),
        .ioctl_isROMB  ( ioctl_isROMB  ),
        .ioctl_wait    ( ioctl_wait    ),
        .sdram_dout    ( sdram_dout    ),
        .sdram_din     ( sdram_din     ),
        .sdram_addr    ( sdram_addr    ),
        .sdram_we      ( sdram_we      ),
        .sdram_rd      ( sdram_rd      ),
        .sdram_ready   ( sdram_ready   ),
        .sdram_size    ( sdram_size    ),
        .slot_A        ( slot_A        ),
        .slot_B        ( slot_B        ),
        .mapper_info   ( mapper_info   ),
        .rom_enabled   ( rom_enabled   ),
        .img_mounted   ( img_mounted   ),
        .img_size      ( img_size      ),
        .img_wp        ( img_wp        ),
        .sd_lba        ( sd_lba        ),
        .sd_rd         ( sd_rd         ),
        .sd_wr         ( sd_wr         ),
        .sd_ack        ( sd_ack        ),
        .sd_buff_addr  ( sd_buff_addr  ),
        .sd_buff_dout  ( sd_buff_dout  ),
        .sd_buff_din   ( sd_buff_din   ),
        .sd_buff_wr    ( sd_buff_wr    ),
        .sd_din_strobe ( sd_din_strobe )
    );

endmodule
