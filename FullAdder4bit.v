module FullAdder4bit (
    input [3:0] x,
    input [3:0] y,
    input cin,
    output [3:0] s,
    output cout
);
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

module FullAdder_tb;

    reg [3:0] x;
    reg [3:0] y;
    reg cin = 0;
    wire [3:0] s;
    wire cout;
  
    FullAdder4bit dut(.x(x), .y(y), .cin(cin), .s(s), .cout(cout));
     
	parameter INPUT_COUNT = 8;        
    reg [3:0] random; // random generate input

    integer i;
  
    initial begin        
        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
             
            x = $random;
            y = $random;         
             
            $display("%2t %6s %0d: x=%2d, y=%2d, cin=%b", $time, "Input", i, x, y, cin); 

            #5; 
                              
            $display("%2t %6s %0d: s=%2d, cout=%b", $time, "Ouput", i, s, cout);
            
        end
    	$finish;
  	end
  
endmodule