module FullAdder4bit (
    input [3:0] x,
    input [3:0] y,
    input cin,
    output [3:0] s,
    output cout
);
    wire c1, c2, c3, c4;

	FullAdder1bit add0(x[0], y[0], cin, s[0], c1);
	FullAdder1bit add1(x[1], y[1], c1, s[1], c2);
	FullAdder1bit add2(x[2], y[2], c2, s[2], c3);
	FullAdder1bit add3(x[3], y[3], c3, s[3], c4);

	assign cout = c4;

endmodule

module FullAdder1bit (
	input a,
	input b,
	input cin,
	output s,
	output cout
);
	assign s = ({cin, a, b} == 3'b001 || {cin, a, b} == 3'b010 || {cin, a, b} == 3'b100 || {cin, a, b} == 3'b111) ? 1 : 0;
    assign cout = ({cin, a, b} == 3'b011 || {cin, a, b} == 3'b101 || {cin, a, b} == 3'b110 || {cin, a, b} == 3'b111) ? 1 : 0;
	
endmodule

// 生成分频时钟信号
module add_clk_division(
    input clk,
    input rstn,
    output div_clk
);
    reg [27:0] adder_clk_reg;
    assign div_clk = adder_clk_reg[27];

    always @(posedge clk)
        if (!rstn)
            adder_clk_reg <= 28'b0;
        else
            adder_clk_reg <= adder_clk_reg + 1;

endmodule

// 生成数码管时钟信号
module led_clk_division(
    input clk,
    input rstn,
    output led_clk
);
    reg [19:0] led_clk_reg;
    assign led_clk = led_clk_reg[19];

    always @(posedge clk)
        if (!rstn)
            led_clk_reg <= 20'b0;
        else
            led_clk_reg <= led_clk_reg + 1;

endmodule

// 生成led_mux
module led_mux_generate(
    input [3:0] s,
    input led_clk,
    input rstn,
    output reg [3:0] led_mux
);
    always @(posedge led_clk or negedge rstn) begin
        if (!rstn)
            led_mux <= 4'b1;
        else
            led_mux <= {led_mux[2:0], led_mux[3]};
    end
endmodule

// 生成小数码管的信号
module led_diplay(
    input [3:0] led_mux,
    input [3:0] s,
    output reg [6:0] led
);
    always @(*) begin
        if (|(led_mux & s))
            led = 7'b0110000;
        else
            led = 7'b1111110;
    end
endmodule

// 生成输入x、y
module input_generate(
    input div_clk,
    input rstn,
    output reg [3:0] x,
    output reg [3:0] y
);
    always @(posedge div_clk or negedge rstn)
        if(!rstn) begin
            x <= 4'b0;
            y <= 4'b0;
        end
        else begin
            x <= x + 1;
            y <= y + 2;
        end

endmodule

// top module
module led_adder_top(
    input clk,
    input rstn,
    output [3:0] led_mux,
    output [6:0] led
);   

    wire [3:0] x;
    wire [3:0] y;
    wire [3:0] s;
    wire [3:0] led_mux_;
    wire [6:0] led_;
    wire cout;
    led_clk_division led_division_inst (clk, rstn, led_clk);
    add_clk_division add_division_inst (clk, rstn, div_clk);
    input_generate input_inst (div_clk, rstn, x, y);
    FullAdder4bit full_adder_inst (x, y, 0, s, cout);
    led_mux_generate led_mux_inst (s, led_clk, rstn, led_mux_);
    led_diplay led_inst (led_mux_, s, led_);

    assign led_mux = led_mux_;
    assign led = led_;
    
endmodule

// testbench
module led_tb;
    reg clk;
    reg rstn;
    wire [3:0] led_mux;
    wire [6:0] led;

    led_adder_top top (clk, rstn, led_mux, led);
    
    always #5 clk = ~clk;     

    initial begin
        clk = 0;
        rstn = 0;
        #10;
        rstn = 1;
    end

endmodule