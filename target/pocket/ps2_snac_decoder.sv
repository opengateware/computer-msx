//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ps2_snac_decoder — Host-side PS/2 (Set 2) via transceptores SNAC. RX-only.
// Salida ps2_key[10:0] MiSTer {toggle, pressed, ext, sc[7:0]}
//------------------------------------------------------------------------------
`default_nettype none
`timescale 1ns/1ps

module ps2_snac_decoder
    #(
        parameter int CLK_HZ = 5_600_000,
        parameter int WD_US  = 200         //! Timeout de trama (us) para resync
    )
    (
        input  logic        clk,
        input  logic        reset,
        input  logic        ps2_clk_in,
        input  logic        ps2_dat_in,
        output logic        ps2_clk_oe,
        output logic        ps2_dat_oe,
        output logic        ps2_clk_out,
        output logic        ps2_dat_out,
        output logic [10:0] ps2_key
    );

    localparam int WD_MAX = (CLK_HZ/1_000_000)*WD_US; // ciclos de watchdog

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
    wire ps2_bit      = dat_sr[1];

    //! ---- Recepcion: bit_cnt 0=start, 1..8=datos, 9=parity, 10=stop ------
    logic  [9:0] data_r;    // [7:0]=datos [8]=parity [9]=stop
    logic  [3:0] bit_cnt;
    logic        rx_busy;
    logic [$clog2(WD_MAX+1)-1:0] wd_free;
    logic        byte_valid;
    logic  [7:0] byte_data;

    always_ff @(posedge clk) begin
        if (reset) begin
            bit_cnt<=0; rx_busy<=0; data_r<=0; wd_free<='0;
            byte_valid<=0; byte_data<=8'h00;
        end else begin
            byte_valid <= 1'b0;

            if (rx_busy) begin
                wd_free <= wd_free + 1'b1;
                if (wd_free >= WD_MAX[$bits(wd_free)-1:0]) begin
                    rx_busy<=0; bit_cnt<=0;        // trama cortada -> resync
                end
            end else wd_free <= '0;

            if (ps2_clk_fall) begin
                wd_free <= '0;
                if (!rx_busy) begin
                    if (ps2_bit == 1'b0) begin     // start=0 valido
                        rx_busy <= 1'b1;
                        bit_cnt <= 4'd1;           // el proximo flanco es d0
                    end
                end else begin
                    // insertar por MSB: al 10o bit -> data_r[7:0]=d0..d7,[8]=par,[9]=stop
                    data_r <= {ps2_bit, data_r[9:1]};
                    if (bit_cnt == 4'd10) begin
                        rx_busy <= 1'b0;
                        bit_cnt <= 4'd0;
                        // parity impar: ^{8 datos, parity}==1 ; stop==1
                        // en este ciclo el bit que entra (ps2_bit) es el STOP,
                        // y data_r[8:0] ya contiene d0..d7 + parity
                        if ((^{data_r[8], data_r[7:0]} == 1'b1) && (ps2_bit == 1'b1)) begin
                            byte_valid <= 1'b1;
                            byte_data  <= data_r[7:0];
                        end
                    end else begin
                        bit_cnt <= bit_cnt + 4'd1;
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