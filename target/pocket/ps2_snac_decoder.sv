//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
//------------------------------------------------------------------------------
// ps2_snac_decoder — Host-side PS/2 (Set 2) via transceptores de bus SNAC.
//   Sin tri-state en FPGA: por cada linea se exponen  in / out / oe.
//   Para teclado MSX solo se recibe => oe=0 permanente (transceptor en RX).
//   Salida: ps2_key[10:0] formato MiSTer {toggle, pressed, ext, sc[7:0]}
//------------------------------------------------------------------------------
`default_nettype none
`timescale 1ns/1ps

module ps2_snac_decoder
    #(
        parameter int CLK_HZ = 50_000_000, //! Frecuencia de clk
        parameter int WD_US  = 120         //! Timeout de trama (us) para resync
    )
    (
        input  logic        clk,
        input  logic        reset,
        // Interfaz hacia el transceptor SNAC (unidireccional + control de sentido)
        input  logic        ps2_clk_in,   //! CLK  leido del transceptor (modo RX)
        input  logic        ps2_dat_in,   //! DATA leido del transceptor (modo RX)
        output logic        ps2_clk_oe,   //! 1 = FPGA conduce CLK  (aqui siempre 0)
        output logic        ps2_dat_oe,   //! 1 = FPGA conduce DATA (aqui siempre 0)
        output logic        ps2_clk_out,  //! valor a emitir si oe=1 (idle 1)
        output logic        ps2_dat_out,  //! valor a emitir si oe=1 (idle 1)
        // Salida decodificada
        output logic [10:0] ps2_key       //! {toggle, pressed, ext, sc[7:0]}
    );

    localparam int WD_MAX = (CLK_HZ/1_000_000)*WD_US;

    // Solo recepcion: nunca conducimos el bus. Idle alto por las pull-up a 5V.
    assign ps2_clk_oe  = 1'b0;
    assign ps2_dat_oe  = 1'b0;
    assign ps2_clk_out = 1'b1;
    assign ps2_dat_out = 1'b1;

    //! ---- Sync 2FF + flanco de bajada de PS2_CLK -------------------------
    logic [2:0] clk_sr;
    logic [1:0] dat_sr;
    always_ff @(posedge clk) begin
        if (reset) begin clk_sr <= 3'b111; dat_sr <= 2'b11; end
        else       begin clk_sr <= {clk_sr[1:0], ps2_clk_in};
                         dat_sr <= {dat_sr[0],   ps2_dat_in}; end
    end
    wire ps2_clk_fall = (clk_sr[2:1] == 2'b10);
    wire ps2_data_s   = dat_sr[1];

    //! ---- Recepcion trama 11 bits (start,8 LSB-first,parity impar,stop) ---
    logic [10:0] shreg;
    logic  [3:0] bit_cnt;
    logic        rx_busy;
    logic [$clog2(WD_MAX+1)-1:0] wd_free;
    logic        byte_valid;
    logic  [7:0] byte_data;

    always_ff @(posedge clk) begin
        if (reset) begin
            bit_cnt<=0; rx_busy<=0; shreg<=11'h7FF; wd_free<='0;
            byte_valid<=0; byte_data<=8'h00;
        end else begin
            byte_valid <= 1'b0;
            if (rx_busy) begin
                wd_free <= wd_free + 1'b1;
                if (wd_free >= WD_MAX[$bits(wd_free)-1:0]) begin
                    rx_busy<=0; bit_cnt<=0;
                end
            end else wd_free <= '0;

            if (ps2_clk_fall) begin
                wd_free <= '0;
                if (!rx_busy) begin
                    if (ps2_data_s == 1'b0) begin           // start valido
                        rx_busy<=1'b1; bit_cnt<=4'd1; shreg<={ps2_data_s,10'h000};
                    end
                end else begin
                    shreg   <= {ps2_data_s, shreg[10:1]};
                    bit_cnt <= bit_cnt + 4'd1;
                    if (bit_cnt == 4'd10) begin
                        rx_busy<=1'b0; bit_cnt<=4'd0;
                        if ((^{shreg[9],shreg[8:1]}==1'b1) && (shreg[10]==1'b1)) begin
                            byte_valid<=1'b1; byte_data<=shreg[8:1];
                        end
                    end
                end
            end
        end
    end

    //! ---- FSM Set 2: E0 (extendido) + F0 (break) --------------------------
    logic ext_f, brk_f, tgl;
    logic out_pressed, out_ext;
    logic [7:0] out_sc;

    always_ff @(posedge clk) begin
        if (reset) begin
            ext_f<=0; brk_f<=0; tgl<=0;
            out_pressed<=0; out_ext<=0; out_sc<=8'h00;
        end else if (byte_valid) begin
            case (byte_data)
                8'hE0: ext_f<=1'b1;
                8'hF0: brk_f<=1'b1;
                8'hE1: begin ext_f<=1'b0; brk_f<=1'b0; end // Pause: ignorado
                default: begin
                    out_sc<=byte_data; out_ext<=ext_f; out_pressed<=~brk_f;
                    tgl<=~tgl; ext_f<=1'b0; brk_f<=1'b0;
                end
            endcase
        end
    end

    assign ps2_key = {tgl, out_pressed, out_ext, out_sc};

endmodule