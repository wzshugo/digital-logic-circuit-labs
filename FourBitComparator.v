module FourBitComparator(
    input [3:0] a,
    input [3:0] b,
	input g0,
	input l0,
    output greater,
    output equal,
    output less
);

    OneBitComparator comp0(a[0], b[0], g0, l0, g1, e1, l1);
    OneBitComparator comp1(a[1], b[1], g1, l1, g2, e2, l2);
    OneBitComparator comp2(a[2], b[2], g2, l2, g3, e3, l3);
    OneBitComparator comp3(a[3], b[3], g3, l3, g4, e4, l4);

    assign greater = g4;    
	assign equal = e4;
    assign less = l4;

endmodule


module OneBitComparator(
	input a,
	input b,
	input g0,
	input l0,
    output greater,
    output equal,
    output less
);

    assign equal = (a == b) & (g0 == 0) & (l0 == 0);
    assign greater = (a > b) | (a == b) & (g0 == 1);
    assign less = (a < b) | (a == b) & (l0 == 1);

endmodule

module FourBitComp_tb;
    reg [3:0] x;
    reg [3:0] y;
    wire greater;
    wire equal;
    wire less;

    FourBitComparator dut(
        .a(x),
        .b(y),
	    .g0(0),
	    .l0(0),
        .greater(greater),
        .equal(equal),
        .less(less)
    );

    always #5 x = x + 1;

    initial begin
    	x = 4'b0000;
    	y = 4'b1001;

		$display("%-5s %-4s %-4s %-7s %-5s %-4s", "Time", "x", "y", "greater", "equal", "less");
		$monitor("%-5t %-4d %-4d %-7b %-5b %-4b", $time, x, y, greater, equal, less);

		#80;

    	$finish;
  	end
endmodule