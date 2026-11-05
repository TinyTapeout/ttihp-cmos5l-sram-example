/*
 * Copyright (c) 2026 Tiny Tapeout B.V.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Minimal demo of the IHP RM_IHPSG13_1P_256x16_c2_bm_bist SRAM macro on IHP SG13CMOS5L.
//
// One command per clock cycle, sampled on the rising edge of clk:
//   ui_in[7:6] = 2'b00: read       - the SRAM reads the word at the address register
//                2'b01: address    - address register <= uio_in
//                2'b10: write low  - low byte of the addressed word <= uio_in
//                2'b11: write high - high byte of the addressed word <= uio_in
//   ui_in[0]   = byte select for uo_out (0: low byte, 1: high byte)
//
// The inputs are registered, so a command reaches the SRAM one clock edge after
// it is sampled. uo_out shows the selected byte of the last word the SRAM read,
// and writes don't change it. After a set address command, the word is on uo_out
// after the third rising edge of clk, counting the one that samples the command.

module tt_um_cmos5l_sram_demo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Register the inputs, so that every SRAM input comes from a flip-flop:
  reg  [1:0]  cmd_q;
  reg  [7:0]  data_q;
  reg         men_q;

  reg  [7:0]  addr;
  wire        write = cmd_q[1];
  wire [15:0] dout;

  always @(posedge clk) begin
    men_q  <= rst_n;
    cmd_q  <= rst_n ? ui_in[7:6] : 2'b00;
    data_q <= uio_in;
    if (!rst_n) begin
      addr <= 8'd0;
    end else if (cmd_q == 2'b01) begin
      addr <= data_q;
    end
  end

  // The instance name ("sram") is referenced by MACROS and PDN_MACRO_CONNECTIONS in src/config.json
  RM_IHPSG13_1P_256x16_c2_bm_bist sram (
      .A_CLK      (clk),
      .A_MEN      (men_q),
      .A_WEN      (write),
      .A_REN      (~write),
      .A_ADDR     (addr),
      .A_DIN      ({data_q, data_q}),
      .A_DLY      (1'b1),               // must be tied high (see the macro datasheet)
      .A_DOUT     (dout),
      .A_BM       (cmd_q[0] ? 16'hFF00 : 16'h00FF),
      .A_BIST_CLK (1'b0),
      .A_BIST_EN  (1'b0),
      .A_BIST_MEN (1'b0),
      .A_BIST_WEN (1'b0),
      .A_BIST_REN (1'b0),
      .A_BIST_ADDR(8'd0),
      .A_BIST_DIN (16'd0),
      .A_BIST_BM  (16'd0)
  );

  assign uo_out  = ui_in[0] ? dout[15:8] : dout[7:0];
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[5:1], 1'b0};

endmodule
