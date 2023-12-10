module sigmoid (
	input         clk,
	input         rst_n,
	input         i_in_valid,
	input  [ 7:0] i_x,
	output [15:0] o_y,
	output        o_out_valid,
	output [50:0] number
);

wire [50:0]  gate_count[3:0];

wire [7:0] y_reg; 
wire [7:0] y_reg_next;
wire out_valid_reg;
wire out_valid_reg_next;

assign y_reg_next = {!i_x[7], i_x[6:0]};

MUX21H mux_gate(
	.Z(out_valid_reg_next),
	.A(1'b0),
	.B(i_in_valid),
	.CTRL(rst_n),
	.number(gate_count[1])
);

REGP #(8) regp_y(.clk(clk), .rst_n(rst_n), .Q(y_reg), .D(y_reg_next), .number(gate_count[2]));
REGP #(1) regp_out_valid(.clk(clk), .rst_n(rst_n), .Q(out_valid_reg), .D(out_valid_reg_next), .number(gate_count[3]));

assign o_y = {1'b0, y_reg[7:0], 7'b0};
assign o_out_valid = out_valid_reg;
assign number =  gate_count[1] + gate_count[2] + gate_count[3];

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