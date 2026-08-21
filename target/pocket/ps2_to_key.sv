// *********************************************************************************
// Analogizer support conversion from raw ps2 scan codes to key events for PocketMSX
// @author: @RndMnkIII
// @date: 2026-08-21
// ps2_to_key.sv
// **********************************************************************************
`default_nettype none
`timescale 1ns/1ps

module ps2_to_key #(parameter STROBE_TOGGLE = 1'b0, parameter HANDLE_PAUSE  = 1'b1) (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,

    input  wire        ps2_code_new,
    input  wire  [7:0] ps2_code,

    output logic [10:0] ps2_key 
);

    logic code_new_d;
    always_ff @(posedge clk) begin
        code_new_d <= ps2_code_new;
    end
    wire byte_stb = ps2_code_new & ~code_new_d;

    logic       ext; 
    logic       brk;
    logic [1:0] e1_cnt;
    wire        e1_active = (e1_cnt != 2'd0);

    // Registros de salida
    logic       key_strobe;
    logic       key_toggle;
    logic       key_pressed;
    logic [8:0] key_code;

    always_ff @(posedge clk) begin
        if (reset) begin
            ext         <= 1'b0;
            brk         <= 1'b0;
            e1_cnt      <= 2'd0;
            key_strobe  <= 1'b0;
            key_toggle  <= 1'b0;
            key_pressed <= 1'b0;
            key_code    <= 9'h000;
        end
        else begin
            key_strobe <= 1'b0;

            if (byte_stb) begin
                if (e1_active) begin
                    if (ps2_code != 8'hF0) begin
                        e1_cnt <= e1_cnt - 1'b1;
                    end
                end
                else begin
                    case (ps2_code)
                        8'hE0: begin
                            ext <= 1'b1;
                        end
                        8'hF0: begin
                            brk <= 1'b1;
                        end
                        8'hE1: begin
                            if (HANDLE_PAUSE) begin
                                e1_cnt <= 2'd2;
                            end
                            else begin
                                key_code    <= {ext, ps2_code};
                                key_pressed <= ~brk;
                                key_strobe  <= 1'b1;
                                key_toggle  <= ~key_toggle;
                                ext         <= 1'b0;
                                brk         <= 1'b0;
                            end
                        end
                        default: begin
                            key_code    <= {ext, ps2_code};
                            key_pressed <= ~brk;
                            key_strobe  <= 1'b1;
                            key_toggle  <= ~key_toggle;
                            ext         <= 1'b0;
                            brk         <= 1'b0;
                        end
                    endcase
                end
            end
        end
    end

    wire strobe_bit = STROBE_TOGGLE ? key_toggle : key_strobe;

    assign ps2_key = enable ? {strobe_bit, key_pressed, key_code} : 11'h0;

endmodule