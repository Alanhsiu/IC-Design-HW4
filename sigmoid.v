module sigmoid (
	input         clk,
	input         rst_n,
	input         i_in_valid,
	input  [ 7:0] i_x,
	output [15:0] o_y,
	output        o_out_valid,
	output [50:0] number
);

wire [ 6:0]  sum;
wire [50:0]  gate_count[3:0];

wire [4:0] y_reg; 
wire [4:0] y_reg_next;
wire out_valid_reg; 
wire out_valid_reg_next;

Adder_5bit adder_0(
    .a({i_x[7:3]}), // x / 8, ignore first 3 bits
    .b(5'b10000), // b = 0.5
    .sum(sum),
    .number(gate_count[0])
);

assign y_reg_next = {sum[4:0]};

MUX21H mux_gate(
	.Z(out_valid_reg_next),
	.A(1'b0),
	.B(i_in_valid),
	.CTRL(rst_n),
	.number(gate_count[1])
);

REGP #(5) regp_y(.clk(clk), .rst_n(rst_n), .Q(y_reg), .D(y_reg_next), .number(gate_count[2]));
REGP #(1) regp_out_valid(.clk(clk), .rst_n(rst_n), .Q(out_valid_reg), .D(out_valid_reg_next), .number(gate_count[3]));

assign o_y = {1'b0, y_reg[4:0], 10'b0};
assign o_out_valid = out_valid_reg;
assign number = gate_count[0]+ gate_count[1] + gate_count[2] + gate_count[3];

endmodule

module Adder_5bit(
	input  [ 4:0] a,
	input  [ 4:0] b,
	output [ 4:0] sum,
	output [50:0] number
);

	wire [ 4:0] carry;
	wire [50:0] number_array[4:0];
	assign carry[0] = 0; 

	FA1 fa1_0 (
		.A(a[0]),
		.B(b[0]),
		.CI(0),
		.S(sum[0]),
		.CO(carry[1]),
		.number(number_array[0])
	);

	genvar i;
	generate
		for (i = 1; i < 5; i = i + 1) begin : adder_loop
			FA1 fa1 (
				.A(a[i]),
				.B(b[i]),
				.CI(carry[i - 1]),
				.S(sum[i]),
				.CO(carry[i]),
				.number(number_array[i])
			);
		end
	endgenerate

	assign number = number_array[0] + number_array[1] + number_array[2] + number_array[3] + number_array[4];

endmodule

//BW-bit FD2
module REGP#(
	parameter BW = 2
)(
	input           clk,
	input           rst_n,
	output [BW-1:0] Q,
	input  [BW-1:0] D,
	output [  50:0] number
);

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			FD2 f0(Q[i], D[i], clk, rst_n, numbers[i]);
		end
	endgenerate

	//sum number of transistors
	reg [50:0] sum;
	integer j;
	always @(*) begin
		sum = 0;
		for (j=0; j<BW; j=j+1) begin 
			sum = sum + numbers[j];
		end
	end

	assign number = sum;

endmodule