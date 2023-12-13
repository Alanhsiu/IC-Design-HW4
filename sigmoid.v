module sigmoid (
	input         clk,
	input         rst_n,
	input         i_in_valid,
	input  [ 7:0] i_x,
	output [15:0] o_y,
	output        o_out_valid,
	output [50:0] number
);

wire [50:0]  gate_count[100:0];

reg [7:0] y_reg; 
reg [7:0] y_reg_next;
wire out_valid_reg;
wire out_valid_reg_next;

parameter b1 = 8'b0100_0000; // 0.25,  -4 <= x <= -2
parameter b2 = 8'b0110_0000; // 0.375, -2 <= x <= -1
parameter b3 = 8'b1000_0000; // 0.5,   -1 <= x <= 1
parameter b4 = 8'b1010_0000; // 0.625,  1 <= x <= 2
parameter b5 = 8'b1100_0000; // 0.75,   2 <= x <= 4

// use first two or three bits of x to select which segment to use
wire not_i_x[7:0];
IV iv_not_i_x7(.Z(not_i_x[7]), .A(i_x[7]), .number());
IV iv_not_i_x6(.Z(not_i_x[6]), .A(i_x[6]), .number());
IV iv_not_i_x5(.Z(not_i_x[5]), .A(i_x[5]), .number());

wire condition[4:0];

// i_x[7:6] == 2'b10;
NR2 and_gate1(.Z(condition[0]), .A(not_i_x[7]), .B(i_x[6]), .number());
// i_x[7:5] == 3'b110;
AN3 and_gate2(.Z(condition[1]), .A(i_x[7]), .B(i_x[6]), .C(not_i_x[5]), .number());
// i_x[7:5] == 3'b000 || i_x[7:5] == 3'b111;
// i_x[7:5] == 3'b001;
AN3 and_gate4(.Z(condition[3]), .A(not_i_x[7]), .B(not_i_x[6]), .C(i_x[5]), .number());
// i_x[7:6] == 2'b01;
NR2 and_gate5(.Z(condition[4]), .A(i_x[7]), .B(not_i_x[6]), .number());

wire condition0[1:0];
// if i_x[7] == 1'b0, then first two bits of y_reg_next = 2'b11, else 2'b00
MUX21H condition0_0(.Z(condition0[0]), .A(1'b1), .B(1'b0), .CTRL(i_x[7]), .number());
assign condition0[1] = condition0[0];

wire condition1[2:0];
wire condition1_carryout[1:0];
HA1 condition1_0(.O(condition1_carryout[0]), .S(condition1[0]), .A(1'b1), .B(i_x[5]), .number());
FA1 condition1_1(.CO(condition1_carryout[1]), .S(condition1[1]), .A(1'b1), .B(i_x[6]), .CI(condition1_carryout[0]), .number());
EO  condition1_2(.Z(condition1[2]), .A(i_x[7]), .B(condition1_carryout[1]), .number());

wire condition2;
IV iv_condition2(.Z(condition2), .A(i_x[6]), .number());

wire condition3[2:0];
wire condition3_carryout[1:0];
HA1 condition3_0(.O(condition3_carryout[0]), .S(condition3[0]), .A(1'b1), .B(i_x[5]), .number());
HA1 condition3_1(.O(condition3_carryout[1]), .S(condition3[1]), .A(i_x[6]), .B(condition3_carryout[0]), .number());
EN  condition3_2(.Z(condition3[2]), .A(i_x[7]), .B(condition3_carryout[1]), .number());

wire condition4[1:0];
wire condition4_carryout;
HA1 condition4_0(.O(condition4_carryout), .S(condition4[0]), .A(i_x[7]), .B(1'b1), .number());
IV  condition4_1(.Z(condition4[1]), .A(condition4_carryout), .number());

// assign y_reg_next = condition[0] ? {1'b1, i_x[7:1]} + b1 : 
// 					condition[1] ? {i_x[7:0]} + b2 :
// 					condition[4] ? {1'b0, i_x[7:1]} + b5 :
// 					condition[3] ? {i_x[7:0]} + b4 :
// 					{i_x[6:0], 1'b0} + b3;

wire [7:0] result[4:0];

assign result[0] = {condition0[1], condition0[0], i_x[6:1]};
assign result[1] = {condition1[2], condition1[1], condition1[0], i_x[4:0]};
assign result[2] = {condition2, i_x[5:0], 1'b0};
assign result[3] = {condition3[2], condition3[1], condition3[0], i_x[4:0]};
assign result[4] = {condition4[1], condition4[0], i_x[6:1]};

// assign y_reg_next = condition[0] ? result[0]:
// 					condition[1] ? result[1]:
// 					condition[4] ? result[4]:
// 					condition[3] ? result[3]:
// 					result[2];

wire [7:0] intermediate [3:0];

// wire condition0or1;
// assign condition0or1 = i_x[7];

// assign y_reg_next = condition0or1 ? (condition[0] ? result[0] : result[1]) : 
//                                     (condition[4] ? result[4] : (condition[3] ? result[3] : result[2]));

wire condition0or4;
wire condition1or3;
EO condition0or4_0(.Z(condition0or4), .A(i_x[7]), .B(i_x[6]), .number());
EO condition1or3_0(.Z(condition1or3), .A(i_x[6]), .B(i_x[5]), .number());

// assign y_reg_next = condition0or4 ? (condition[0] ? result[0] : result[4]) :
//                                     (condition1or3 ? (condition[1] ? result[1] : result[3]) : result[2]);

// genvar i;
// generate
// 	for (i = 0; i < 8; i = i + 1) begin : gen_mux
// 		// condition[0] ? result[0] : result[1]
// 		MUX21H mux0(.Z(intermediate[0][i]), .A(result[1][i]), .B(result[0][i]), .CTRL(condition[0]), .number());
// 		// condition[3] ? result[3] : result[2]
// 		MUX21H mux1(.Z(intermediate[1][i]), .A(result[2][i]), .B(result[3][i]), .CTRL(condition[3]), .number());
// 		// condition[4] ? result[4] : intermediate[1]
// 		MUX21H mux2(.Z(intermediate[2][i]), .A(intermediate[1][i]), .B(result[4][i]), .CTRL(condition[4]), .number());
// 		// condition0or1 ? intermediate[0] : intermediate[2]
// 		MUX21H mux3(.Z(y_reg_next[i]), .A(intermediate[2][i]), .B(intermediate[0][i]), .CTRL(condition0or1), .number());
// 	end
// endgenerate

genvar i;
generate
	for (i = 0; i < 8; i = i + 1) begin : gen_mux
		// condition[0] ? result[0] : result[4]
		MUX21H mux0(.Z(intermediate[0][i]), .A(result[4][i]), .B(result[0][i]), .CTRL(condition[0]), .number());
		// condition[1] ? result[1] : result[3]
		MUX21H mux1(.Z(intermediate[1][i]), .A(result[3][i]), .B(result[1][i]), .CTRL(condition[1]), .number());
		// condition1or3 ? intermediate[1] : result[2]
		MUX21H mux2(.Z(intermediate[2][i]), .A(result[2][i]), .B(intermediate[1][i]), .CTRL(condition1or3), .number());
		// condition0or4 ? intermediate[0] : intermediate[2]
		MUX21H mux3(.Z(y_reg_next[i]), .A(intermediate[2][i]), .B(intermediate[0][i]), .CTRL(condition0or4), .number());
	end
endgenerate


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