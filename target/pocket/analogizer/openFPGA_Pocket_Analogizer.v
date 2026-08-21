//This module encapsulates all Analogizer adapter signals
// Original work by @RndMnkIII. With code modules from @MikeSimonson, @Mist-Project, @RandyS, @jotego, Scott Larson,  @tomasz and others.
// Releases: 
// * 1.0 [01/01/2024] Initial RGBS output mode
// * 1.1              Added SOG modes: RGsB, YPbPt
// * 1.2              Added Mike Simon Y/C module, Scandoubler SVGA Mist module.     
// * 1.3 [11/02/2025] Added Bridge interface to directly access to the Analogizer settings, now returns the settings. Added NES SNAC Zapper support.
// * 1.4 [20/08/2026] Added PS/2 Keyboard and Mouse support (hook) + NES/SNES/DB15 SNAC game adapter. Needs custom SNAC adapter. Analogizer global enable/disable is read from configuration file.

// *** Analogizer R.3 adapter ***
// * WHEN SOG SWITCH IS IN ON POSITION, OUTPUTS CSYNC ON G CHANNEL
// # WHEN YPbPr VIDEO OUTPUT IS SELECTED, Y->G, Pr->R, Pb->B
//Pin mappings:                                               VGA CONNECTOR                                                                                          USB3 TYPE A FEMALE CONNECTOR (SNAC)
//                        ______________________________________________________________________________________________________________________________________________________________________________________________________                             
//                       /                              VS  HS          R#  G*# B#                                                                  1      2       3       4      5       6       7       8       9              \
//                       |                              |   |           |   |   |                                                                 VBUS   D-      D+      GND     RX-     RX+     GND_D   TX-     TX+             |
//FUNCTION:              |                              |   |           |   |   |                                                                 +5V    OUT1    OUT2    GND     IO3     IN4     IO5     IO6     IN7             |
//                       |  A                           |   |           |   |   |                                                                          ^       ^              ^       |       ^       ^       |              |
//                       |  N             SOG           |   |           |   |   |                                                                          |       |              V       V       V       V       V              |
//                       |  A           -------         |   |           |   |   |                                                                                                                                                |                              
//                       |  O    OFF   |   S   |--GND   |   |         +------------+                                                                                                                                             |
//                       |  L          |   W   |        |   |   SYNC  |            |                                                                                                                                             |            
//  PIN DIR:             |  G          |   I   +--------------------->|            |---------------------------------------------------------------------------------------------------------+                                   |
//  ^ OUTPUT             |  I          |   T   |        |   |         |  RGB DAC   |                                                                                                         |                                   |
//  V INPUT              |  Z          |   C   |        |   |         |            |===================================================================++                                    |                                   |
//                       |  E    ON ===|   H   |--------+   |         +------------+                                                                   ||                                    |                                   |
//                       |  R           -------         |   |            ||  |   | /BLANK                                                              ||                                    |                                   |         
//                       |                              |   +--------+   ||  |   +------------------------------------------------------------------+  ||                                    |                                   |                                  |
//                       |  R                           +------+     |   ||  +===============================++                                     |  ||                                    |                                   |
//                       |  2                                  |     |   ||                                  ||                                     |  ||                                    |                                   |
//                       |     CONF.B        IO5V       ---    |     |   \\================================  \\================================     |  \\================================   VID               IO3^  IO6^         |  
//                       |     CONF.A   IN4  ---  IN7   IO3V   VS    HS    R0    R1    R2    R3    R4    R5    G0    G1    G2    G3    G4    G5   /BLK   B0    B1    B2    B3    B4    B5   CLK  OUT1   OUT2  IO5^  IO6V         |  
//                       |      __3.3V__ |___ | __ |_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____^__GND__    |                                
//POCKET                 |     /         V    V    V     V     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     V       \   | 
//CARTRIDGE PIN #:       \____|     1    2    3    4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20    21    22    23    24    25    26    27    28    29    30    31   32  |___/
//                             \_________|____|____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_______/
//Pocket Pin Name:                       |    |    |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 
//cart_tran_bank0[7] --------------------+    |    |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 
//cart_tran_bank0[6] -------------------------+    |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank0[5] ------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank0[4] ------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank3[0] ------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 
//cart_tran_bank3[1] ------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     
//cart_tran_bank3[2] ------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank3[3] ------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank3[4] ------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank3[5] ------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank3[6] ------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank3[7] ------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//------------------                                                                                           |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[0] ------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     
//cart_tran_bank2[1] ------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[2] ------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[3] ------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[4] ------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[5] ------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[6] ------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |
//cart_tran_bank2[7] ------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |                                   
//------------------                                                                                                                                           |     |     |     |     |     |     |     |     |     |
//cart_tran_bank1[0] ------------------------------------------------------------------------------------------------------------et_sw------------------------------+     |     |     |     |     |     |     |     |     |
//cart_tran_bank1[1] ------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |
//cart_tran_bank1[2] ------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |
//cart_tran_bank1[3] ------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |
//cart_tran_bank1[4] ------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |
//cart_tran_bank1[5] ------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |
//cart_tran_bank1[6] ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |
//cart_tran_bank1[7] ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |
//cart_tran_pin30    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     | 
//cart_tran_pin31    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
`default_nettype none
`timescale 1ns / 1ps

module openFPGA_Pocket_Analogizer #(parameter MASTER_CLK_FREQ=50_000_000, parameter LINE_LENGTH, parameter ADDRESS_ANALOGIZER_CONFIG=8'hF7) (
	input  wire clk_74a,
	input  wire i_clk,
	input  wire i_rst_apf, //active High
    input  wire i_rst_core,//active High
	//Video interface
	input  wire video_clk,
	input  wire [7:0] R,
	input  wire [7:0] G,
	input  wire [7:0] B,
	input  wire Hblank,
	input  wire Vblank,
	input  wire Hsync,
	input  wire Vsync,

	//openFPGA Bridge interface
	input wire bridge_endian_little,
	input  wire [31:0] bridge_addr,
	input  wire        bridge_rd,
	output reg  [31:0] analogizer_bridge_rd_data,
	input  wire        bridge_wr,
	input  wire [31:0] bridge_wr_data,

	//Analogizer settings
	output wire       analogizer_ena_out,
	output wire [4:0] snac_game_cont_type_out,
	output wire [3:0] snac_cont_assignment_out,
	output wire [3:0] analogizer_video_type_out,
	output wire [2:0] SC_fx_out,
	output wire pocket_blank_screen_out,
	output wire analogizer_osd_out,

	//Video Y/C Encoder interface
	input  wire [39:0] CHROMA_PHASE_INC,
	input wire  [26:0] COLORBURST_RANGE,
	input  wire [4:0] CHROMA_ADD,
	input  wire [4:0] CHROMA_MUL,
	input  wire PALFLAG,
	//Video SVGA Scandoubler interface
	input  wire ce_pix,
	input  wire scandoubler, //logic for disable/enable the scandoubler
	//SNAC interface
    output wire [15:0] p1_btn_state,
	output wire [31:0] p1_joy_state,
    output wire [15:0] p2_btn_state,
	output wire [31:0] p2_joy_state,
    output wire [15:0] p3_btn_state,
    output wire [15:0] p4_btn_state,
	//PSX rumble interface joy1, joy2
    input [1:0] i_VIB_SW1,  //  Vibration SW  VIB_SW[0] Small Moter OFF 0:ON  1:
                                //VIB_SW[1] Bic Moter   OFF 0:ON  1(Dualshook Only)
	input [7:0] i_VIB_DAT1,  //  Vibration(Bic Moter)Data   8'H00-8'HFF (Dualshook Only)
    input [1:0] i_VIB_SW2,
	input [7:0] i_VIB_DAT2, 
	// 
	output wire busy, 
	//Pocket Analogizer IO interface to the cartridge port
	inout   wire    [7:0]   cart_tran_bank2,
	output  wire            cart_tran_bank2_dir,
	inout   wire    [7:0]   cart_tran_bank3,
	output  wire            cart_tran_bank3_dir,
	inout   wire    [7:0]   cart_tran_bank1,
	output  wire            cart_tran_bank1_dir,
	inout   wire    [7:4]   cart_tran_bank0,
	output  wire            cart_tran_bank0_dir,
	inout   wire            cart_tran_pin30,
	output  wire            cart_tran_pin30_dir,
	output  wire            cart_pin30_pwroff_reset,
	inout   wire            cart_tran_pin31,
	output  wire            cart_tran_pin31_dir,
    //debug
	output wire [3:0] DBG_TX,
    output wire o_stb,
	//PS/2 Keyboard SNAC interface decoded
    output wire       o_ps2_code_new,
    output wire [7:0] o_ps2_code, 
     //PS/2 Mouse SNAC raw interface
    output wire o_mouse_clk,  //pin31    (MCLK)
    output wire o_mouse_dat   //bank0[5] (MDAT)
);

	//Configuration file dat
	//reg [31:0] analogizer_bridge_rd_data;
	reg  [31:0] analogizer_config = 0;
	wire [31:0] analogizer_config_s;
	reg  [31:0] config_mem [16]; //configuration memory
	
	synch_3 #(.WIDTH(32)) analogizer_sync({i_busyr,analogizer_config[30:0]}, analogizer_config_s, i_clk);

	wire [31:0] memory_out;
	reg [3:0] word_cnt;
	reg i_busyr;

	// handle memory mapped I/O from pocket
	always @(posedge clk_74a) begin
		if(i_rst_apf) begin
			i_busyr <= 1'b1;
		end
		else begin
			i_busyr <= 1'b0;
		end
	end

	always @(posedge clk_74a) begin
		if(bridge_wr) begin
			case(bridge_addr[31:24])
			ADDRESS_ANALOGIZER_CONFIG: begin
				if (bridge_addr[3:0] == 4'h0) begin
					word_cnt <= 4'h1;
					analogizer_config <= bridge_endian_little ? bridge_wr_data  : {bridge_wr_data[7:0],bridge_wr_data[15:8],bridge_wr_data[23:16],bridge_wr_data[31:24]}; 
				end
				else begin
					word_cnt <= word_cnt + 4'h1;
					config_mem[bridge_addr[3:0]] <= bridge_endian_little ? bridge_wr_data  : {bridge_wr_data[7:0],bridge_wr_data[15:8],bridge_wr_data[23:16],bridge_wr_data[31:24]}; 
				end
			end
			endcase
		end
		if(bridge_rd) begin
			case(bridge_addr[31:24])
			ADDRESS_ANALOGIZER_CONFIG: begin
				if (bridge_addr[3:0] == 4'h0) analogizer_bridge_rd_data <= bridge_endian_little ?  analogizer_config_s : {analogizer_config_s[7:0],analogizer_config_s[15:8],analogizer_config_s[23:16],analogizer_config_s[31:24]}; //invert byte order to writeback to the Sav folders
				else analogizer_bridge_rd_data <= bridge_endian_little ? config_mem[bridge_addr[3:0]] : {memory_out[7:0],memory_out[15:8],memory_out[23:16],memory_out[31:24]};
			end
			endcase
		end
	end
	assign memory_out = config_mem[bridge_addr[3:0]];
	assign busy = i_busyrr;
	reg i_busyrr;

  always @(posedge i_clk) begin
	analogizer_ena        <= analogizer_config_s[5];
    snac_game_cont_type   <= analogizer_config_s[4:0];
    snac_cont_assignment  <= analogizer_config_s[9:6];
    analogizer_video_type <= analogizer_config_s[13:10];	
	pocket_blank_screen   <= analogizer_config_s[14];
    analogizer_osd_out2	  <= analogizer_config_s[15];
	i_busyrr		      <= analogizer_config_s[31];
  end

  wire conf_AB = (snac_game_cont_type >= 5'd16);

  //0 disable, 1 scanlines 25%, 2 scanlines 50%, 3 scanlines 75%, 4 hq2x
  always @(posedge i_clk) begin
	if(analogizer_video_type >= 4'd5) SC_fx <= analogizer_video_type - 4'd5;
end

reg       analogizer_ena;
reg [3:0] analogizer_video_type;
reg [4:0] snac_game_cont_type;
reg [3:0] snac_cont_assignment;
reg [2:0] SC_fx;
reg       pocket_blank_screen;
reg       analogizer_osd_out2;

assign analogizer_ena_out        = analogizer_ena;
assign analogizer_video_type_out = analogizer_video_type;
assign snac_game_cont_type_out   = snac_game_cont_type;
assign snac_cont_assignment_out  = snac_cont_assignment;
assign SC_fx_out                 = SC_fx;
assign pocket_blank_screen_out   = pocket_blank_screen;
assign analogizer_osd_out        = analogizer_osd_out2;
//------------------------------------------------------------------------

	wire [7:4] CART_BK0_OUT ;
    wire [7:4] CART_BK0_IN ;
    wire CART_BK0_DIR ; 
    wire [7:6] CART_BK1_OUT_P76 ;
    wire CART_PIN30_OUT ;
    wire CART_PIN30_IN ;
    wire CART_PIN30_DIR ; 
    wire CART_PIN31_OUT ;
    wire CART_PIN31_IN ;
    wire CART_PIN31_DIR ;

	openFPGA_Pocket_Analogizer_SNAC #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ)) snac
	(
		.i_clk(i_clk),
		.i_rst(i_rst_apf),
		.conf_AB(conf_AB),              //0 conf. A(default), 1 conf. B (see graph above)
		.game_cont_type(snac_game_cont_type), //0-15 Conf. A, 16-31 Conf. B
		//.game_cont_sample_rate(game_cont_sample_rate), //0 compatibility mode (slowest), 1 normal mode, 2 fast mode, 3 superfast mode
		.p1_btn_state(p1_btn_state),
		.p1_joy_state(p1_joy_state),
		.p2_btn_state(p2_btn_state),
		.p2_joy_state(p2_joy_state),
		.p3_btn_state(p3_btn_state),
		.p4_btn_state(p4_btn_state),
		.i_VIB_SW1(i_VIB_SW1), .i_VIB_DAT1(i_VIB_DAT1), .i_VIB_SW2(i_VIB_SW2), .i_VIB_DAT2(i_VIB_DAT2), 
		.busy(),    
		//SNAC Pocket cartridge port interface (see graph above)   
		.CART_BK0_OUT(CART_BK0_OUT),
		.CART_BK0_IN(CART_BK0_IN),
		.CART_BK0_DIR(CART_BK0_DIR), 
		.CART_BK1_OUT_P76(CART_BK1_OUT_P76),
		.CART_PIN30_OUT(CART_PIN30_OUT),
		.CART_PIN30_IN(CART_PIN30_IN),
		.CART_PIN30_DIR(CART_PIN30_DIR), 
		.CART_PIN31_OUT(CART_PIN31_OUT),
		.CART_PIN31_IN(CART_PIN31_IN),
		.CART_PIN31_DIR(CART_PIN31_DIR),
		//debug
		.DBG_TX(DBG_TX),
    	.o_stb(o_stb),
		//PS/2 Keyboard SNAC: scancodes
		.o_ps2_code_new(o_ps2_code_new),
		.o_ps2_code(o_ps2_code)
	); 


//---------------------------------------------------------------------
// Fix video
//---------------------------------------------------------------------
wire  ANALOGIZER_DE = ~(HBL || VBL);
wire ANALOGIZER_CSYNC = ~^{HS, VS};

wire hs_fix,vs_fix;
sync_fix sync_h(i_clk, Hsync, hs_fix);
sync_fix sync_v(i_clk, Vsync, vs_fix);

reg [7:0] R_fix,G_fix,B_fix;

reg CE,HS,VS,HBL,VBL;
always @(posedge i_clk) begin
	reg old_ce;
	old_ce <= ce_pix;
	CE <= 0;
	if(~old_ce & ce_pix) begin
		CE <= 1;
		HS <= hs_fix;
		// if(~HS & hs_fix) VS <= vs_fix;
		//FIX ONLY FOR XAIN'D SLEENA
		VS <= vs_fix;

		{R_fix,G_fix,B_fix} <= {R,G,B};
		HBL <= Hblank;
		// if(HBL & ~Hblank) VBL <= Vblank;
		//FIX ONLY FOR XAIN'D SLEENA
		VBL <= Vblank;
	end
end
//---------------------------------------------------------------------------

	//Choose type of analog video type of signal
	reg [5:0] Rout, Gout, Bout ;
	reg HsyncOut, VsyncOut, BLANKnOut ;
	wire [7:0] Yout, PrOut, PbOut ;
	wire [7:0] R_Sd, G_Sd, B_Sd ;
	wire Hsync_Sd, Vsync_Sd ;
	wire Hblank_Sd, Vblank_Sd ;
	wire BLANKn_SD = ~(Hblank_Sd || Vblank_Sd) ;

	always @(*) begin
		case(analogizer_video_type)
			4'h0: begin //RGBS
				Rout = R_fix[7:2]&{6{ANALOGIZER_DE}};
				Gout = G_fix[7:2]&{6{ANALOGIZER_DE}};
				Bout = B_fix[7:2]&{6{ANALOGIZER_DE}};
				HsyncOut = ANALOGIZER_CSYNC;
				VsyncOut = 1'b1;
				BLANKnOut = ANALOGIZER_DE;
			end
			4'h3, 4'h4: begin// Y/C Modes works for Analogizer R1, R2 Adapters
				Rout = yc_o[23:18];
				Gout = yc_o[15:10];
				Bout = yc_o[7:2];
				HsyncOut = yc_cs;
				VsyncOut = 1'b1;
				BLANKnOut = 1'b1;
			end
			4'h1: begin //RGsB
				Rout = R_fix[7:2]&{6{ANALOGIZER_DE}};
				Gout = G_fix[7:2]&{6{ANALOGIZER_DE}};
				Bout = B_fix[7:2]&{6{ANALOGIZER_DE}};
				HsyncOut = 1'b1;
				VsyncOut = ANALOGIZER_CSYNC; //to DAC SYNC pin, SWITCH SOG ON
				BLANKnOut = ANALOGIZER_DE;
			end
			4'h2: begin //YPbPr
				Rout = PrOut[7:2];
				Gout = Yout[7:2];
				Bout = PbOut[7:2];
				HsyncOut = 1'b1;
				VsyncOut = YPbPr_sync; //to DAC SYNC pin, SWITCH SOG ON
				BLANKnOut = 1'b1; //ADV7123 needs this
			end
			4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin //Scandoubler modes
				Rout = vga_data_sl[23:18]; //R_Sd[7:2];
				Gout = vga_data_sl[15:10]; //G_Sd[7:2];
				Bout = vga_data_sl[7:2]; //B_Sd[7:2];
				HsyncOut = vga_hs_sl; //Hsync_Sd;
				VsyncOut = vga_vs_sl; //Vsync_Sd;
				BLANKnOut = 1'b1;
			end
			default: begin
				Rout = 6'h0;
				Gout = 6'h0;
				Bout = 6'h0;
				HsyncOut = HS;
				VsyncOut = 1'b1;
				BLANKnOut = ANALOGIZER_DE;
			end
		endcase
	end

	wire YPbPr_sync, YPbPr_blank;
	vga_out ybpr_video
	(
		.clk(video_clk),
		.ypbpr_en(1'b1),
		.csync(ANALOGIZER_CSYNC),
		.de(ANALOGIZER_DE),
		.din({R_fix[7:0],G_fix[7:0],B_fix[7:0]}), //24 bits input
		.dout({PrOut,Yout,PbOut}), //24 bits output
		.csync_o(YPbPr_sync),
		.de_o(YPbPr_blank)
	);

	wire [23:0] yc_o ;
	//wire yc_hs, yc_vs, 
	wire yc_cs ;

	yc_out_legacy yc_out
	(
		.clk(i_clk),
		.PAL_EN(PALFLAG),
		.PHASE_INC(CHROMA_PHASE_INC),
		.COLORBURST_RANGE(COLORBURST_RANGE),
		.MULFLAG(CHROMA_MUL),
		.CHRADD(CHROMA_ADD),
		.CHRMUL(CHROMA_MUL),	
		.hsync(HS),
		.vsync(VS),
		.csync(ANALOGIZER_CSYNC),
		.dout(yc_o),
		.din({R_fix, G_fix, B_fix}), //24bits input
		.hsync_o(),
		.vsync_o(),
		.csync_o(yc_cs) //24bits output
	);

	wire ce_pix_Sd ;
	scandoubler_2 #(.LENGTH(LINE_LENGTH), .HALF_DEPTH(0)) sd
	(
		.clk_vid(i_clk),
		.hq2x(SC_fx[2]),

		.ce_pix(CE),
		.hs_in(HS),
		.vs_in(VS),
		.hb_in(HBL),
		.vb_in(VBL),
		.r_in({R_fix[7:0]&{8{ANALOGIZER_DE}}}),
		.g_in({G_fix[7:0]&{8{ANALOGIZER_DE}}}),
		.b_in({B_fix[7:0]&{8{ANALOGIZER_DE}}}),

		.ce_pix_out(ce_pix_Sd),
		.hs_out(Hsync_Sd),
		.vs_out(Vsync_Sd),
		.hb_out(Hblank_Sd),
		.vb_out(Vblank_Sd),
		.r_out(R_Sd),
		.g_out(G_Sd),
		.b_out(B_Sd)
	);

	reg Hsync_SL, Vsync_SL, Hblank_SL, Vblank_SL ;
	reg [7:0] R_SL, G_SL, B_SL ;
	reg CE_PIX_SL, DE_SL ;

	always @(posedge video_clk) begin
		Hsync_SL <= (scandoubler) ? Hsync_Sd : HS;
		Vsync_SL <= (scandoubler) ? Vsync_Sd : VS;
		Hblank_SL <= (scandoubler) ? Hblank_Sd : HBL;
		Vblank_SL <= (scandoubler) ? Vblank_Sd : VBL;
		R_SL <= (scandoubler) ? R_Sd    : {R_fix[7:0]&{8{ANALOGIZER_DE}}};
		G_SL <= (scandoubler) ? G_Sd    : {G_fix[7:0]&{8{ANALOGIZER_DE}}};
		B_SL <= (scandoubler) ? B_Sd    : {B_fix[7:0]&{8{ANALOGIZER_DE}}};
		CE_PIX_SL <= (scandoubler) ? ce_pix_Sd : CE;
		DE_SL <= ANALOGIZER_DE;
	end


wire [23:0] vga_data_sl ;
wire        vga_vs_sl, vga_hs_sl ;
scanlines_analogizer #(0) VGA_scanlines
(
	.clk(video_clk),

	.scanlines(SC_fx[1:0]),
	//.din(de_emu ? {R_SL, G_SL,B_SL} : 24'd0),
	.din({R_SL, G_SL,B_SL}),
	.hs_in(Hsync_SL),
	.vs_in(Vsync_SL),
	.de_in(DE_SL),
	.ce_in(CE_PIX_SL),

	.dout(vga_data_sl),
	.hs_out(vga_hs_sl),
	.vs_out(vga_vs_sl),
	.de_out(),
	.ce_out()
);


	//infer tri-state buffers for cartridge data signals
	//BK0
	assign cart_tran_bank0         = i_rst_apf | ~analogizer_ena ? 4'hf : ((CART_BK0_DIR) ? CART_BK0_OUT : 4'hZ);     //on reset state set ouput value to 4'hf
	assign cart_tran_bank0_dir     = i_rst_apf | ~analogizer_ena ? 1'b1 : CART_BK0_DIR;                              //on reset state set pin dir to output
	assign CART_BK0_IN             = cart_tran_bank0;
	//BK3
	assign cart_tran_bank3         = i_rst_apf | ~analogizer_ena ? 8'hzz : {Rout[5:0],HsyncOut,VsyncOut};                          //on reset state set ouput value to 8'hZ
	assign cart_tran_bank3_dir     = i_rst_apf | ~analogizer_ena ? 1'b0  : 1'b1;                                     //on reset state set pin dir to input
	//BK2
	assign cart_tran_bank2         = i_rst_apf | ~analogizer_ena ? 8'hzz : {Bout[0],BLANKnOut,Gout[5:0]};                          //on reset state set ouput value to 8'hZ
	assign cart_tran_bank2_dir     = i_rst_apf | ~analogizer_ena ? 1'b0  : 1'b1;                                     //on reset state set pin dir to input
	//BK1
	assign cart_tran_bank1         = i_rst_apf | ~analogizer_ena ? 8'hzz : {CART_BK1_OUT_P76,video_clk,Bout[5:1]};      //on reset state set ouput value to 8'hZ
	assign cart_tran_bank1_dir     = i_rst_apf | ~analogizer_ena ? 1'b0  : 1'b1;                                     //on reset state set pin dir to input
	//PIN30
	assign cart_tran_pin30         = i_rst_apf | ~analogizer_ena ? 1'bz : ((CART_PIN30_DIR) ? CART_PIN30_OUT : 1'bZ); //on reset state set ouput value to 4'hf
	assign cart_tran_pin30_dir     = i_rst_apf | ~analogizer_ena ? 1'b0 : CART_PIN30_DIR;                              //on reset state set pin dir to output
	assign CART_PIN30_IN           = cart_tran_pin30;
	assign cart_pin30_pwroff_reset = i_rst_apf | ~analogizer_ena ? 1'b0 : 1'b1;                                      //1'b1 (GPIO USE)
	//PIN31
	assign cart_tran_pin31         = i_rst_apf | ~analogizer_ena ? 1'bz : ((CART_PIN31_DIR) ? CART_PIN31_OUT : 1'bZ); //on reset state set ouput value to 4'hf
	assign cart_tran_pin31_dir     = i_rst_apf | ~analogizer_ena ? 1'b0 : CART_PIN31_DIR;                            //on reset state set pin dir to input
	assign CART_PIN31_IN           = cart_tran_pin31;
	//--- PS/2 Mouse (holder) ---
	assign o_mouse_clk = cart_tran_pin31;    //MCLK
	assign o_mouse_dat = cart_tran_bank0[5]; //MDAT
endmodule

module sync_fix
(
	input clk,
	
	input sync_in,
	output sync_out
);

assign sync_out = sync_in ^ pol;

reg pol;
always @(posedge clk) begin
	reg [31:0] cnt;
	reg s1,s2;

	s1 <= sync_in;
	s2 <= s1;
	cnt <= s2 ? (cnt - 1) : (cnt + 1);

	if(~s2 & s1) begin
		cnt <= 0;
		pol <= cnt[31];
	end
end
endmodule