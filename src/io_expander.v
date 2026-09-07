module io_expander #(
	parameter NUMREGS = 16
) (
	input clk,
	input run,

	input wire [7:0] ui_in,
	output wire [7:0] uo_out,

	input [15:0][7:0] regs_i,
	output [15:0][7:0] regs_o
);
	assign regs_o['h0] = ui_in;
	assign regs_o['h1] = regs_i['h1];
	assign regs_o['h2] = regs_i['h2];
	assign regs_o['h3] = regs_i['h3];
	assign regs_o['h4] = regs_i['h4];
	assign regs_o['h5] = regs_i['h5];
	assign regs_o['h6] = regs_i['h6];
	assign regs_o['h7] = regs_i['h7];
	assign regs_o['h8] = regs_i['h8];
	assign regs_o['h9] = regs_i['h9];
	assign regs_o['ha] = regs_i['ha];
	assign regs_o['hb] = pwm_in_high;
	assign regs_o['hc] = pwm_in_low;
	assign regs_o['hd] = pwm_in_period;
	assign regs_o['he] = regs_i['he];
	assign regs_o['hf] = regs_i['hf];

	wire [7:0] or_out_pins;
	assign or_out_pins = regs_i[3];
	wire [7:0] or_in_pins;
	assign or_in_pins = regs_i[2];
	wire or_enable;
	assign or_enable = or_out_pins != 0;
	wire or_out;
	assign or_out =
		  (or_in_pins[7] == 0 ? 0 : ui_in[7])
		| (or_in_pins[6] == 0 ? 0 : ui_in[6])
		| (or_in_pins[5] == 0 ? 0 : ui_in[5])
		| (or_in_pins[4] == 0 ? 0 : ui_in[4])
		| (or_in_pins[3] == 0 ? 0 : ui_in[3])
		| (or_in_pins[2] == 0 ? 0 : ui_in[2])
		| (or_in_pins[1] == 0 ? 0 : ui_in[1])
		| (or_in_pins[0] == 0 ? 0 : ui_in[0]);

	wire pwm_out[2];
	wire [7:0] pwm_enable_pin[2];

	generate for (i = 0; i < 2; i++) begin
		assign pwm_enable_pin[i] = regs_i[6 + 3*i];

		wire [7:0] pwm_loop;
		assign pwm_loop = regs_i[4 + 3*i];
		wire [7:0] pwm_cutoff;
		assign pwm_cutoff = regs_i[5 + 3*i];

		reg [7:0] counter;
		always @ (negedge clk or negedge run) begin
			if (!run)
				counter <= 0;
			else if (counter == pwm_loop)
				counter <= 0;
			else
				counter <= counter + 1;
		end

		wire pwm_on;
		assign pwm_on = pwm_enable_pin[i] != 0;
		assign pwm_out[i] =
			  (pwm_on && counter > pwm_cutoff)
				? 1 : 0;
	end
	endgenerate

	wire [7:0] pwm_in_enable;
	assign pwm_in_enable = regs_i['ha];

	reg [7:0] pwm_in_high;
	reg [7:0] pwm_in_low;
	reg [7:0] pwm_in_period;

	reg [7:0] high_count;
	reg [7:0] low_count;
	wire any_high;
	wire any_low;
	assign any_high =
		  (pwm_in_enable[0] ? ui_in[0] : 0)
		| (pwm_in_enable[1] ? ui_in[1] : 0)
		| (pwm_in_enable[2] ? ui_in[2] : 0)
		| (pwm_in_enable[3] ? ui_in[3] : 0)
		| (pwm_in_enable[4] ? ui_in[4] : 0)
		| (pwm_in_enable[5] ? ui_in[5] : 0)
		| (pwm_in_enable[6] ? ui_in[6] : 0)
		| (pwm_in_enable[7] ? ui_in[7] : 0);
	assign any_low =
		~((pwm_in_enable[0] ? ui_in[0] : 1)
		& (pwm_in_enable[1] ? ui_in[1] : 1)
		& (pwm_in_enable[2] ? ui_in[2] : 1)
		& (pwm_in_enable[3] ? ui_in[3] : 1)
		& (pwm_in_enable[4] ? ui_in[4] : 1)
		& (pwm_in_enable[5] ? ui_in[5] : 1)
		& (pwm_in_enable[6] ? ui_in[6] : 1)
		& (pwm_in_enable[7] ? ui_in[7] : 1));

	reg prev_any_high;
	reg [7:0] prev_edge;

	reg [7:0] counter;
	always @ (negedge clk or negedge run) begin
		if (!run) begin
			counter <= 0;
			pwm_in_high <= 0;
			pwm_in_low <= 0;
			pwm_in_period <= 0;
			high_count <= 0;
			low_count <= 0;
			prev_any_high <= 0;
			prev_edge <= 0;
		end else begin
			counter <= counter + 1;

			if (counter == 0) begin
				pwm_in_high <= high_count;
				pwm_in_low <= low_count;
				high_count <= {7'h0, any_high};
				low_count <= {7'h0, any_low};
			end else begin
				high_count <= high_count + {7'h0, any_high};
				low_count <= low_count + {7'h0, any_low};
			end

			if (any_high && !prev_any_high) begin
				pwm_in_period <= counter - prev_edge;
				prev_edge <= counter;
			end

			prev_any_high <= any_high;
		end
	end

	genvar i;
	generate for (i = 0; i < 8; i++) begin
		assign uo_out[i] =
			  or_out_pins[i] ? or_out
			: pwm_enable_pin[0][i] ? pwm_out[0]
			: pwm_enable_pin[1][i] ? pwm_out[1]
			: regs_i[1][i];
	end
	endgenerate

endmodule
