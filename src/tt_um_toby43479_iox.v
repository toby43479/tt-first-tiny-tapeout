
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
	assign run = ~rst_n;

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

        wire [7:0] rx_data;
        wire rx_data_ready;
        wire rx_data_continue;
	wire rx_data_wanted;
        wire [7:0] tx_data;
        wire tx_data_ready;
        wire tx_data_latched;
        wire tx_data_done;
	wire tx_data_wanted;

	assign tx_data = 0;
	assign tx_data_ready = 0;
	assign rx_data_continue = 0;
	assign rx_data_wanted = 0;

        reg [15:0][7:0] regs_o;
        wire [15:0][7:0] regs_i;

	i2c_follow i2c(
		.run(run),
                .clk(clk),
                .sda(sda),
                .sda_out(sda_follow),
                .scl(scl),
                .scl_out(scl_follow),
                .tx_data(tx_data),
                .tx_data_ready(tx_data_ready),
                .tx_data_latched(tx_data_latched),
                .tx_data_done(tx_data_done),
                .tx_data_wanted(tx_data_wanted),
                .rx_data(rx_data),
                .rx_data_ready(rx_data_ready),
                .rx_data_continue(rx_data_continue),
		.rx_data_wanted(rx_data_wanted),
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
