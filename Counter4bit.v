module Counter4bit (
    input clk,      
    input rstn,     
    output [3:0] count     
);
    reg [3:0] count_reg;     

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            count_reg <= 4'b0000;     
        end else begin
            count_reg <= count_reg + 1;     
        end
    end

    assign count = count_reg;     
endmodule

module Counter_tb;
    reg clk;
    reg rstn;
    wire [3:0] count;

    Counter4bit dut (
        .clk(clk),
        .rstn(rstn),
        .count(count)
    );

    always #5 clk = ~clk;     

    initial begin
        clk = 0;
        rstn = 0;

        #10 rstn = 1;     
        
        repeat (4) begin
            #40;
            rstn = ~rstn;
        end

        repeat (16) begin
            #10;
        end

        $finish;     
    end

    always @(posedge clk) begin
        $display("Count: %d", count);
    end
endmodule