module i2c_follow #(
	parameter BITWIDTH = 8,
	parameter NUMREGS = 16
) (
	input clk,
	input run,

	input [7:0] tx_data,
	input tx_data_ready,
	output reg tx_data_wanted,
	output reg tx_data_latched,
	output reg tx_data_done,

	output reg [7:0] rx_data,
	output reg rx_data_ready,
	input rx_data_wanted,
	input rx_data_continue,

	input scl,
	output scl_out,
	input sda,
	output sda_out,

	input [15:0][7:0] regs_i,
	output reg [15:0][7:0] regs_o
);
	localparam max_bitcount = BITWIDTH - 1;
	localparam logbits = $clog2(max_bitcount);

	localparam state_idle = 0;
	localparam state_select = 1;
	localparam state_select_ack = 2;
	localparam state_write = 3;
	localparam state_pending_write_ack = 4;
	localparam state_write_ack = 5;
	localparam state_pending_read = 6;
	localparam state_read = 7;
	localparam state_read_ack = 8;
	localparam state_max = state_read_ack;

	reg [$clog2(state_max+1)-1:0] state;

	reg [max_bitcount:0] bitstream;
	reg [$clog2(max_bitcount+1)-1:0] bitcount;

	reg readmode;

	wire sda_falling;
	wire sda_rising;
	wire scl_falling;
	wire scl_rising;
	edgedet #(.DEFAULT(1)) sda_edge(.clk(clk), .run(run), .in(sda),
		.rising(sda_rising), .falling(sda_falling));
	edgedet #(.DEFAULT(1)) scl_edge(.clk(clk), .run(run), .in(scl),
		.rising(scl_rising), .falling(scl_falling));

	reg sda_raw;
	assign sda_out = sda_raw == 0 ? 0 : 1;

	reg scl_raw;
	assign scl_out = scl_raw == 0 ? 0 : 1;

	wire start;
	assign start = run & scl & sda_falling;
	wire stop;
	assign stop = run & scl & sda_rising;

	reg got_reg;
	reg autoincr;
	reg [3:0] reg_num;

	always @ (negedge clk or negedge run) begin
		if (!run) begin
			state <= state_idle;
			sda_raw <= 1;
			scl_raw <= 1;
			got_reg <= 0;
			reg_num <= 0;
			autoincr <= 0;

		end else begin

			if (start) begin
				state <= state_select;
				sda_raw <= 1;
				scl_raw <= 1;
				bitcount <= 3'b111;
				bitstream <= 0;

			end else if (stop) begin
				state <= state_idle;
				sda_raw <= 1;
				scl_raw <= 1;
				got_reg <= 0;
				autoincr <= 0;

			end else if (state != state_idle) begin

			rx_data_ready <= 0;
			tx_data_latched <= 0;
			tx_data_done <= 0;
			tx_data_wanted <= 0;

			case (state)
			state_read: begin
				if (scl_falling) begin
					bitcount <= bitcount - 1;
					bitstream <= {bitstream[6:0], 1'bx};
					sda_raw <= bitstream[7];

				end
				if (scl_rising) begin
					if (bitcount == 3'b111)
						state <= state_read_ack;
				end
			end
			state_read_ack: begin
				if (scl_falling) begin
					sda_raw <= 1;

				end
				if (scl_rising) begin
					if (!sda) begin
						tx_data_done <= 1;
						if (tx_data_ready) begin
							bitstream <= tx_data;
							tx_data_latched <= 1;
						end else begin
							bitstream <= regs_i[reg_num];
							if (autoincr)
								reg_num <= reg_num + 1;
						end
					end

					state <= state_read;
					bitcount <= logbits'(max_bitcount);
				end
			end

			state_write: begin
				if (scl_falling) begin
					sda_raw <= 1;

				end
				if (scl_rising) begin
					bitcount <= bitcount - 1;
					bitstream <= {bitstream[6:0], sda};

					if (bitcount == 0)
						state <= state_write_ack;
				end
			end
			state_write_ack: begin
				if (scl_falling) begin
					if (rx_data_wanted) begin
						rx_data <= bitstream;
						rx_data_ready <= 1;

						if (rx_data_continue) begin
							sda_raw <= 0;
						end else begin
							scl_raw <= 0; // stretch clock
							state <= state_pending_write_ack;
						end
					end else begin
						sda_raw <= 0;

						if (!got_reg) begin
							got_reg <= 1;
							reg_num <= bitstream[3:0];
							autoincr <= bitstream[7];
						end else begin
							regs_o[reg_num] <= bitstream;
							if (autoincr)
								reg_num <= reg_num + 1;
						end
					end
				end
				if (scl_rising) begin
					state <= state_write;
					bitcount <= logbits'(max_bitcount);
				end
			end

			state_select: begin
				if (scl_falling) begin

				end
				if (scl_rising) begin
					bitcount <= bitcount - 1;
					bitstream <= {bitstream[6:0], sda};

					if (bitcount == 0)
						state <= state_select_ack;
				end
			end
			state_select_ack: begin
				if (scl_falling) begin
					if (bitstream[7:1] == 7'h52) begin
						sda_raw <= 0;
					end else begin
						state <= state_idle;
						sda_raw <= 1;
						bitcount <= 3'b111;
						bitstream <= 0;
					end

					readmode <= bitstream[0];
				end
				if (scl_rising) begin
					state <= readmode ? state_read : state_write;

					if (readmode) begin
						if (tx_data_ready) begin
							bitstream <= tx_data;
							tx_data_latched <= 1;
						end else begin
							bitstream <= regs_i[reg_num];
							if (autoincr)
								reg_num <= reg_num + 1;
						end
					end
				end
			end
			endcase
			end
		end
	end
endmodule
