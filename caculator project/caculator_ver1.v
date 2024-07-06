module ascii_calculator (ascii_a, ascii_b, ascii_op, ascii_units, ascii_tens); 
    input [7:0] ascii_a;       // 输入的第一个ASCII码数字
    input [7:0] ascii_b;       // 输入的第二个ASCII码数字
    input [7:0] ascii_op;      // 输入的操作符（+，-，*，/）
    output reg [7:0] ascii_units;  // 结果的个位数字，ASCII码表示
    output reg [7:0] ascii_tens;    // 结果的十位数字，ASCII码表示

    reg [3:0] bin_a;     // 第一个数字的二进制表示
    reg [3:0] bin_b;     // 第二个数字的二进制表示
    reg [6:0] bin_result; // 结果的二进制表示
    reg [3:0] units;     // 结果的个位数字，二进制表示
    reg [3:0] tens;      // 结果的十位数字，二进制表示

    always @(*) begin
        // 将ASCII码转换为二进制数
        if (ascii_a >= 8'd48 && ascii_a <= 8'd57) begin
            bin_a = ascii_a - 8'd48;
        end else begin
            bin_a = 4'd0; // 如果不是数字，默认为0
        end

        if (ascii_b >= 8'd48 && ascii_b <= 8'd57) begin
            bin_b = ascii_b - 8'd48;
        end else begin
            bin_b = 4'd0; // 如果不是数字，默认为0
        end

        // 根据操作符进行运算
        case (ascii_op)
            8'd43: bin_result = bin_a + bin_b; // '+' 操作
            8'd45: bin_result = bin_a - bin_b; // '-' 操作
            8'd42: bin_result = bin_a * bin_b; // '*' 操作
            8'd47: bin_result = bin_b != 0 ? bin_a / bin_b : 7'd0; // '/' 操作，防止除以0
            default: bin_result = 7'd0; // 默认结果为0
        endcase

        // 提取结果的个位和十位
        units = bin_result % 10;
        tens = bin_result / 10;

        // 将个位和十位转换回ASCII码
        ascii_units = units + 8'd48;
        ascii_tens = tens + 8'd48;
    end

endmodule

module calculator_fsm (clk, rstn, data, valid, ascii_units, ascii_tens);
    input clk, rstn;
    input [7:0] data;        // 输入的ASCII码
    input valid;             // 表明data是否有效
    output reg [7:0] ascii_units; // 结果的个位数字，ASCII码表示
    output reg [7:0] ascii_tens;   // 结果的十位数字，ASCII码表示

    reg [7:0] op;       // 当前的操作符
    reg [7:0] operand;  // 当前操作数
    reg [7:0] result_units; // 中间结果的个位数字
    reg [7:0] result_tens;  // 中间结果的十位数字
    reg [7:0] state;    // 状态寄存器

    localparam S_IDLE = 8'd0;
    localparam S_OPERAND = 8'd1;
    localparam S_OPERATOR = 8'd2;
    localparam S_CALCULATE = 8'd3;

    wire [7:0] calc_units;
    wire [7:0] calc_tens;

    ascii_calculator calc (
        .ascii_a(result_units),
        .ascii_b(operand),
        .ascii_op(op),
        .ascii_units(calc_units),
        .ascii_tens(calc_tens)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= S_IDLE;
            result_units <= 8'd48; // ASCII '0'
            result_tens <= 8'd48;  // ASCII '0'
            ascii_units <= 8'd48; // ASCII '0'
            ascii_tens <= 8'd48;  // ASCII '0'
            operand <= 8'd48;
            op <= 8'd43;
        end else if (valid) begin
            if (data == 8'd99) begin // 'c' to clear
                state <= S_IDLE;
                result_units <= 8'd48; // ASCII '0'
                result_tens <= 8'd48;  // ASCII '0'
                ascii_units <= 8'd48; // ASCII '0'
                ascii_tens <= 8'd48;  // ASCII '0'
            end else begin
                case (state)
                    S_IDLE: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            result_units <= data;
                            result_tens <= 8'd48;  // 清零十位
                            ascii_units <= data;
                            ascii_tens <= 8'd48;
                            state <= S_OPERATOR;
                        end
                    end
                    S_OPERATOR: begin
                        if (data == 8'd43 || data == 8'd45 || data == 8'd42 || data == 8'd47) begin
                            op <= data;
                            state <= S_OPERAND;
                        end
                    end
                    S_OPERAND: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            operand <= data;
                            ascii_units <= data;
                            ascii_tens <= 8'd48;
                            state <= S_CALCULATE;
                        end
                    end
                    S_CALCULATE: begin
                        if (data == 8'd61) begin // '='
                            ascii_units <= calc_units;
                            ascii_tens <= calc_tens;
                            result_units <= calc_units;
                            result_tens <= calc_tens;
                            state <= S_OPERATOR;
                        end
                    end
                endcase
            end
        end
    end

endmodule

`timescale 1ns / 1ps

module calculator_fsm_tb;

    reg clk, rstn;
    reg [7:0] data;
    reg valid;
    wire [7:0] ascii_units;
    wire [7:0] ascii_tens;

    calculator_fsm dut (
        .clk(clk),
        .rstn(rstn),
        .data(data),
        .valid(valid),
        .ascii_units(ascii_units),
        .ascii_tens(ascii_tens)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rstn = 0;
        data = 0;
        valid = 0;

        // Reset
        @(posedge clk);
        rstn = 1;

        // Test case 1: 5 + 3 = 8
        @(posedge clk);
        data = 8'd53; // '5'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd43; // '+'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd51; // '3'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd61; // '='
        valid = 1;
        @(posedge clk);
        valid = 0;
        #10;
        @(posedge clk);
        data = 8'd99; // 'c'
        valid = 1;
        @(posedge clk);
        valid = 0;
        // Test case 2: 7 - 4 = 3
        @(posedge clk);
        data = 8'd55; // '7'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd45; // '-'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd52; // '4'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd61; // '='
        valid = 1;
        @(posedge clk);
        valid = 0;
        #10;

        @(posedge clk);
        data = 8'd42; // '*'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd54; // '6'
        valid = 1;
        @(posedge clk);
        valid = 0;
        @(posedge clk);
        data = 8'd61; // '='
        valid = 1;
        @(posedge clk);
        valid = 0;
        #10;
        $finish;
    end

endmodule