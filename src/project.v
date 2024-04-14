/*
 * Copyright (c) 2024 Clive Chan
 * SPDX-License-Identifier: MIT
 */

`define default_netname none

module tt_um_cchan_fp8_multiplier (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    // Not using uio_out.
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Compute result_out in terms of ui_in, uio_in
    fp8mul mul1(
        .sign1(ui_in[7]),
        .exp1(ui_in[6:3]),
        .mant1(ui_in[2:0]),
        .sign2(uio_in[7]),
        .exp2(uio_in[6:3]),
        .mant2(uio_in[2:0]),
        .sign_out(uo_out[7]),
        .exp_out(uo_out[6:3]),
        .mant_out(uo_out[2:0])
    );
endmodule

module fp8mul (
  input sign1,
  input [3:0] exp1,
  input [2:0] mant1,

  input sign2,
  input [3:0] exp2,
  input [2:0] mant2,

  output sign_out,
  output [3:0] exp_out,
  output [2:0] mant_out
);
    parameter EXP_BIAS = 7;
    wire isnan = (sign1 == 1 && exp1 == 0 && mant1 == 0) || (sign2 == 1 && exp2 == 0 && mant2 == 0);
    wire [7:0] full_mant = ({exp1 != 0, mant1} * {exp2 != 0, mant2});
    wire overflow_mant = full_mant[7];
    wire [6:0] shifted_mant = overflow_mant ? full_mant[6:0] : {full_mant[5:0], 1'b0};
    // is the mantissa overflowing up to the next exponent?
    wire roundup = (exp1 + exp2 + overflow_mant < 1 + EXP_BIAS) && (shifted_mant[6:0] != 0)
                   || (shifted_mant[6:4] == 3'b111 && shifted_mant[3]);
    wire underflow = (exp1 + exp2 + overflow_mant) < 1 - roundup + EXP_BIAS;
    wire is_zero = exp1 == 0 || exp2 == 0 || isnan || underflow;
    // note: you can't use negative numbers reliably. just keep things positive during compares.
    wire [4:0] exp_out_tmp = (exp1 + exp2 + overflow_mant + roundup) < EXP_BIAS ? 0 : (exp1 + exp2 + overflow_mant + roundup - EXP_BIAS);
    assign exp_out = exp_out_tmp > 15 ? 4'b1111 : (is_zero) ? 0 : exp_out_tmp[3:0];  // Exponent bias is 7
    assign mant_out = exp_out_tmp > 15 ? 3'b111 : (is_zero || roundup) ? 0 : (shifted_mant[6:4] + (shifted_mant[3:0] > 8 || (shifted_mant[3:0] == 8 && shifted_mant[4])));
    assign sign_out = ((sign1 ^ sign2) && !(is_zero)) || isnan;
endmodule
