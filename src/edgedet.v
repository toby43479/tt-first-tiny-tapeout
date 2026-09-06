module edgedet #(
	parameter DEFAULT = 0
) (
	input clk,
	input run,

	input in,
	output rising,
	output falling
);
	reg prev;
	always @ (posedge clk or negedge run)
		if (!run)
			prev <= DEFAULT;
		else
			prev <= in;

	assign rising = run & ~prev & in;
	assign falling = run & prev & ~in;

endmodule
