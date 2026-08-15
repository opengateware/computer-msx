// =====================================================================
// ps2_host.sv
// Bidirectional PS/2 host controller for open-collector lines driven
// through tri-state (dir-controlled) FPGA pins, e.g. Analogue Pocket
// cart pins 30/31 via the Analogizer SNAC harness.
//
// The module NEVER drives a line high. Each line is only ever:
//   released  -> *_oe = 0  (pin = input / Hi-Z, external pull-up -> '1')
//   driven low -> *_oe = 1  (pin = output, data hard-wired to 1'b0)
//
// Wiring in core_top (verify APF dir polarity: here 1 = OUTPUT):
//   assign cart_tran_pin30      = 1'b0;
//   assign cart_tran_pin30_dir  = ps2_clk_oe;   // 1 => drive '0'
//   assign ps2_clk_i            = cart_tran_pin30; // reads pin when Hi-Z
//   assign cart_tran_pin31      = 1'b0;
//   assign cart_tran_pin31_dir  = ps2_dat_oe;
//   assign ps2_dat_i            = cart_tran_pin31;
//   // Also gate with cart_pin30_pwroff_reset as needed.
//
// Frame format:
//   device->host : start(0) d0..d7(LSB) parity(odd) stop(1)
//   host->device : inhibit CLK >=100us, DATA low (start), release CLK,
//                  device clocks 8 data + parity + stop, then drives ACK.
// =====================================================================
module ps2_host #(
    parameter int CLK_HZ = 50_000_000
)(
    input  logic       clk,
    input  logic       rst,          // synchronous, active high

    // Open-collector line interface (to dir-controlled pins)
    input  logic       ps2_clk_i,    // raw pin value (valid when released)
    input  logic       ps2_dat_i,
    output logic       ps2_clk_oe,   // 1 => pull CLK low
    output logic       ps2_dat_oe,   // 1 => pull DATA low

    // Receive (device -> host)
    output logic [7:0] rx_data,
    output logic       rx_valid,     // 1-cycle strobe
    output logic       rx_err,       // 1-cycle strobe (parity/framing)

    // Transmit (host -> device)
    input  logic [7:0] tx_data,
    input  logic       tx_send,      // 1-cycle strobe to start
    output logic       tx_busy,
    output logic       tx_done,      // 1-cycle strobe, ACK received
    output logic       tx_err        // 1-cycle strobe, no ACK / timeout
);

    // ---------------- timing ----------------
    localparam int US          = CLK_HZ / 1_000_000;
    localparam int INHIBIT_CYC = US * 120;   // ~120 us CLK-low inhibit
    localparam int WATCHDOG_CYC= US * 200;    // abort if line goes idle mid-frame

    // ---------------- input sync + debounce ----------------
    logic [1:0] clk_sync, dat_sync;
    always_ff @(posedge clk) begin
        clk_sync <= {clk_sync[0], ps2_clk_i};
        dat_sync <= {dat_sync[0], ps2_dat_i};
    end
    wire clk_s = clk_sync[1];
    wire dat_bit = dat_sync[1];

    localparam int FILT = 4;
    logic [FILT-1:0] clk_filt;
    logic            clk_stable, clk_stable_d;
    always_ff @(posedge clk) begin
        clk_filt <= {clk_filt[FILT-2:0], clk_s};
        if (&clk_filt)       clk_stable <= 1'b1;
        else if (~|clk_filt) clk_stable <= 1'b0;
        clk_stable_d <= clk_stable;
    end
    wire clk_fedge = clk_stable_d & ~clk_stable;
    wire clk_redge = ~clk_stable_d & clk_stable;

    // ---------------- FSM ----------------
    typedef enum logic [3:0] {
        S_IDLE, RX_BITS,
        TX_INHIBIT, TX_BITS, TX_STOP, TX_ACK
    } state_t;

    state_t      state;
    logic [3:0]  bitcnt;
    logic [7:0]  rxbuf;
    logic        rx_par;
    logic [8:0]  tx_shift;     // {parity, d7..d0}, shifted out from bit0
    logic [31:0] timer;

    always_ff @(posedge clk) begin
        // default strobes low
        rx_valid <= 1'b0;
        rx_err   <= 1'b0;
        tx_done  <= 1'b0;
        tx_err   <= 1'b0;

        if (rst) begin
            state      <= S_IDLE;
            ps2_clk_oe <= 1'b0;
            ps2_dat_oe <= 1'b0;
            tx_busy    <= 1'b0;
            bitcnt     <= '0;
            timer      <= '0;
        end else begin
            case (state)
            // -------------------------------------------------- IDLE
            S_IDLE: begin
                ps2_clk_oe <= 1'b0;
                ps2_dat_oe <= 1'b0;
                tx_busy    <= 1'b0;
                bitcnt     <= '0;
                if (tx_send) begin
                    tx_busy    <= 1'b1;
                    ps2_clk_oe <= 1'b1;                 // begin inhibit
                    timer      <= INHIBIT_CYC;
                    tx_shift   <= {~(^tx_data), tx_data}; // odd parity
                    state      <= TX_INHIBIT;
                end else if (clk_fedge && (dat_bit == 1'b0)) begin
                    // start bit of an incoming frame
                    bitcnt <= 4'd0;
                    timer  <= WATCHDOG_CYC;
                    state  <= RX_BITS;
                end
            end
            // -------------------------------------------------- RX
            RX_BITS: begin
                // watchdog: reset while CLK toggles, abort if idle too long
                if (clk_fedge || clk_redge) timer <= WATCHDOG_CYC;
                else if (timer != 0)        timer <= timer - 1;

                if (timer == 0) begin
                    rx_err <= 1'b1;
                    state  <= S_IDLE;
                end else if (clk_fedge) begin
                    case (bitcnt)
                        4'd0,4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7:
                            rxbuf[bitcnt[2:0]] <= dat_bit;
                        4'd8: rx_par <= dat_bit;         // parity
                        default: ;                       // 4'd9 = stop
                    endcase
                    bitcnt <= bitcnt + 4'd1;
                    if (bitcnt == 4'd9) begin            // stop bit now on dat_bit
                        // odd parity: XOR of 8 data + parity must be 1; stop==1
                        if ((^{rxbuf, rx_par}) == 1'b1 && dat_bit == 1'b1) begin
                            rx_data  <= rxbuf;
                            rx_valid <= 1'b1;
                        end else begin
                            rx_err <= 1'b1;
                        end
                        state <= S_IDLE;
                    end
                end
            end
            // -------------------------------------------------- TX
            TX_INHIBIT: begin
                ps2_clk_oe <= 1'b1;                       // hold CLK low
                if (timer != 0) timer <= timer - 1;
                if (timer == 0) begin
                    ps2_dat_oe <= 1'b1;                   // DATA low = start/request
                    ps2_clk_oe <= 1'b0;                   // release CLK
                    bitcnt     <= 4'd0;
                    timer      <= WATCHDOG_CYC;
                    state      <= TX_BITS;
                end
            end
            TX_BITS: begin
                if (clk_fedge || clk_redge) timer <= WATCHDOG_CYC;
                else if (timer != 0)        timer <= timer - 1;

                if (timer == 0) begin
                    ps2_dat_oe <= 1'b0; ps2_clk_oe <= 1'b0;
                    tx_err <= 1'b1; state <= S_IDLE;
                end else if (clk_fedge) begin
                    ps2_dat_oe <= ~tx_shift[0];           // '0' => drive low, '1' => release
                    tx_shift   <= {1'b0, tx_shift[8:1]};
                    bitcnt     <= bitcnt + 4'd1;
                    if (bitcnt == 4'd8) state <= TX_STOP; // presented d0..d7,parity
                end
            end
            TX_STOP: begin
                if (clk_fedge || clk_redge) timer <= WATCHDOG_CYC;
                else if (timer != 0)        timer <= timer - 1;

                if (timer == 0) begin
                    ps2_dat_oe <= 1'b0; tx_err <= 1'b1; state <= S_IDLE;
                end else if (clk_fedge) begin
                    ps2_dat_oe <= 1'b0;                   // release DATA (stop)
                    state      <= TX_ACK;
                end
            end
            TX_ACK: begin
                if (clk_fedge || clk_redge) timer <= WATCHDOG_CYC;
                else if (timer != 0)        timer <= timer - 1;

                if (timer == 0) begin
                    tx_err <= 1'b1; state <= S_IDLE;
                end else if (clk_fedge) begin
                    if (dat_bit == 1'b0) tx_done <= 1'b1; // device pulled DATA low = ACK
                    else                 tx_err  <= 1'b1;
                    state <= S_IDLE;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule