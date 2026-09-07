
`default_nettype none

module tt_um_toby43479_iox(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,    // Dedicated outputs
  input  wire [7:0] uio_in,    // IOs: Input path
  output wire [7:0] uio_out,    // IOs: Output path
  output wire [7:0] uio_oe,    // IOs: Enable path (active high: 0=input, 1=output)
  input ena,
  input clk,
  input rst_n
);
	assign uio_out[7:2] = 0;
	assign uio_oe[7:2] = 0;

	wire run;
	assign run = rst_n;

        wire sda;
        wire sda_follow;
        wire sda_lead;

	assign sda_lead = uio_in[1];
	assign uio_oe[1] = sda_follow == 0 ? 1 : 0;
	assign uio_out[1] = sda_follow == 0 ? 0 : 1; //'z;
	assign sda =
		  sda_lead == 0 ? 0
		: sda_follow == 0 ? 0
		: 1;

        wire scl;
        wire scl_follow;
        wire scl_lead;

	assign scl_lead = uio_in[0];
	assign uio_oe[0] = scl_follow == 0 ? 1 : 0;
	assign uio_out[0] = scl_follow == 0 ? 0 : 1; //'z;
	assign scl =
		  scl_lead == 0 ? 0
		: scl_follow == 0 ? 0
		: 1;

        wire [15:0][7:0] regs_o;
        wire [15:0][7:0] regs_i;

	i2c_follow i2c(
		.run(run),
                .clk(clk),
                .sda(sda),
                .sda_out(sda_follow),
                .scl(scl),
                .scl_out(scl_follow),
		.regs_o(regs_o),
		.regs_i(regs_i)
	);

        io_expander iox(
                .run(run),
                .clk(clk),

                .ui_in(ui_in),
                .uo_out(uo_out),

                .regs_i(regs_o),
                .regs_o(regs_i)
        );

endmodule
