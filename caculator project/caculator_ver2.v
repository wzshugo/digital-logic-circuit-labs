module ascii_calculator (
    input [7:0] ascii_a_tens,    // 第一个数字的十位，ASCII码表示
    input [7:0] ascii_a_units,   // 第一个数字的个位，ASCII码表示
    input [7:0] ascii_b_tens,    // 第二个数字的十位，ASCII码表示
    input [7:0] ascii_b_units,   // 第二个数字的个位，ASCII码表示
    input [7:0] ascii_op,        // 输入的操作符（+，-，*，/，^）
    output reg [7:0] ascii_units, // 结果的个位数字，ASCII码表示
    output reg [7:0] ascii_tens   // 结果的十位数字，ASCII码表示
);

    reg [6:0] bin_a;     // 第一个数字的二进制表示
    reg [6:0] bin_b;     // 第二个数字的二进制表示
    reg [13:0] bin_result; // 结果的二进制表示
    reg [3:0] units;     // 结果的个位数字，二进制表示
    reg [3:0] tens;      // 结果的十位数字，二进制表示

    always @(*) begin
        // 将ASCII码转换为二进制数
        bin_a = (ascii_a_tens - 8'd48) * 10 + (ascii_a_units - 8'd48);
        bin_b = (ascii_b_tens - 8'd48) * 10 + (ascii_b_units - 8'd48);

        // 根据操作符进行运算
        case (ascii_op)
            8'd43: bin_result = bin_a + bin_b; // '+' 操作
            8'd45: bin_result = bin_a - bin_b; // '-' 操作
            8'd42: bin_result = bin_a * bin_b; // '*' 操作
            8'd47: bin_result = bin_b != 0 ? bin_a / bin_b : 14'd0; // '/' 操作，防止除以0
            // 8'd94: bin_result = bin_a ** bin_b; // '^' 操作，乘方运算
            default: bin_result = 14'd0; // 默认结果为0
        endcase

        // 提取结果的个位和十位
        units = bin_result % 10;
        tens = (bin_result / 10) % 10;

        // 将个位和十位转换回ASCII码
        ascii_units = units + 8'd48;
        ascii_tens = tens + 8'd48;
    end

endmodule

module calculator_fsm (
    input clk,
    input rstn,
    input [7:0] data,        // 输入的ASCII码
    input valid,             // 表明data是否有效
    output reg [7:0] ascii_units, // 结果的个位数字，ASCII码表示
    output reg [7:0] ascii_tens   // 结果的十位数字，ASCII码表示
);

    reg [7:0] op;            // 当前的操作符
    reg [7:0] operand_tens;  // 当前操作数的十位
    reg [7:0] operand_units; // 当前操作数的个位
    reg [7:0] result_units;  // 中间结果的个位数字
    reg [7:0] result_tens;   // 中间结果的十位数字
    reg [7:0] state;         // 状态寄存器

    localparam S_IDLE = 8'd0;
    localparam S_OPERAND_UNITS_1 = 8'd1;
    localparam S_OPERATOR = 8'd2;
    localparam S_OPERAND_TENS = 8'd3;
    localparam S_OPERAND_UNITS_2 = 8'd4;
    localparam S_CALCULATE = 8'd5;
    localparam S_CALCULATE_2 = 8'd6;

    wire [7:0] calc_units;
    wire [7:0] calc_tens;

    ascii_calculator calc (
        .ascii_a_tens(result_tens),
        .ascii_a_units(result_units),
        .ascii_b_tens(operand_tens),
        .ascii_b_units(operand_units),
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
            operand_units <= 8'd48;
            operand_tens <= 8'd48;
            op <= 8'd43;
        end 
        else if (valid) begin
            if (data == 8'd99) begin // 'c' to clear
                state <= S_IDLE;
                result_units <= 8'd48; // ASCII '0'
                result_tens <= 8'd48;  // ASCII '0'
                ascii_units <= 8'd48; // ASCII '0'
                ascii_tens <= 8'd48;  // ASCII '0'
                operand_units <= 8'd48;
                operand_tens <= 8'd48;
                op <= 8'd43;
            end else begin
                case (state)
                    S_IDLE: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            ascii_units <= 8'd48;
                            ascii_tens <= 8'd48;
                            result_units <= data;
                            result_tens <= data;
                            state <= S_OPERAND_UNITS_1;
                        end
                    end
                    S_OPERAND_UNITS_1: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            result_units <= data;
                            ascii_units <= data;
                            ascii_tens <= result_tens;
                            state <= S_OPERATOR;
                        end
                        else if (data == 8'd43 || data == 8'd45 || data == 8'd42 || data == 8'd47 || data == 8'd94) begin
                            op <= data;
                            result_tens <= 8'd48;
                            ascii_tens <= 8'd48;
                            ascii_units <= result_units;
                            state <= S_OPERAND_TENS;
                        end
                    end
                    S_OPERATOR: begin
                        if (data == 8'd43 || data == 8'd45 || data == 8'd42 || data == 8'd47 || data == 8'd94) begin
                            op <= data;
                            state <= S_OPERAND_TENS;
                        end
                    end
                    S_OPERAND_TENS: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            operand_units <= data;
                            operand_tens <= data;
                            state <= S_OPERAND_UNITS_2;
                        end
                    end
                    S_OPERAND_UNITS_2: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            operand_units <= data;
                            ascii_units <= data;
                            ascii_tens <= operand_tens;
                            state <= S_CALCULATE;
                        end
                        else if (data == 8'd61) begin
                            operand_tens <= 8'd48;
                            ascii_tens <= 8'd48;
                            ascii_units <= operand_units;
                            state <= S_CALCULATE_2;
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
        else if (state == S_CALCULATE_2) begin
            ascii_units <= calc_units;
            ascii_tens <= calc_tens;
            result_units <= calc_units;
            result_tens <= calc_tens;
            state <= S_OPERATOR;
        end        
    end

endmodule

module testbench;
    reg clk;
    reg rstn;
    reg [7:0] data;        // 输入的ASCII码
    reg valid;             // 表明data是否有效
    wire [7:0] ascii_units; // 结果的个位数字，ASCII码表示
    wire [7:0] ascii_tens;  // 结果的十位数字，ASCII码表示

    // 实例化被测试的模块
    calculator_fsm uut (
        .clk(clk),
        .rstn(rstn),
        .data(data),
        .valid(valid),
        .ascii_units(ascii_units),
        .ascii_tens(ascii_tens)
    );

    initial begin
        // 用于观察波形
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        // 初始化
        clk = 0;
        rstn = 0;
        data = 8'd0;
        valid = 0;
        #10 rstn = 1;

        // 测试12 + 23 =
        #10 valid = 1; data = 8'd49; #10 valid = 0;  // '1'
        #10 valid = 1; data = 8'd50; #10 valid = 0;  // '2'
        #10 valid = 1; data = 8'd43; #10 valid = 0;  // '+'
        #10 valid = 1; data = 8'd50; #10 valid = 0;  // '2'
        #10 valid = 1; data = 8'd52; #10 valid = 0;  // '4'
        #10 valid = 1; data = 8'd61; #10 valid = 0;  // '='

        #10 $display("Result: Tens=%c, Units=%c", ascii_tens, ascii_units); // 输出应为 '3' '5'

        // 测试 / 2
        #10 valid = 1; data = 8'd47; #10 valid = 0;  // '/'
        #10 valid = 1; data = 8'd50; #10 valid = 0;  // '2'
        #10 valid = 1; data = 8'd61; #10 valid = 0;  // '='

        #10 $display("Result: Tens=%c, Units=%c", ascii_tens, ascii_units); // 输出应为 '1' '7'

        // 清空计算结果
        #10 valid = 1; data = 8'd99; #10 valid = 0;  // 'c'

        // 测试 3 ^ 2
        #10 valid = 1; data = 8'd48; #10 valid = 0;  // '0'
        #10 valid = 1; data = 8'd51; #10 valid = 0;  // '3'
        #10 valid = 1; data = 8'd94; #10 valid = 0;  // '^'
        #10 valid = 1; data = 8'd48; #10 valid = 0;  // '0'
        #10 valid = 1; data = 8'd50; #10 valid = 0;  // '2'
        #10 valid = 1; data = 8'd61; #10 valid = 0;  // '='
        #10 valid = 1; data = 8'd48; // '0'

        #10 $display("Result: Tens=%c, Units=%c", ascii_tens, ascii_units); // 输出应为 '9' '0'

        $stop; // 停止仿真
    end

    // 时钟信号生成
    always #5 clk = ~clk;

endmodule

`timescale 1ns / 1ps

module ascii_calculator_tb;

    // Inputs
    reg [7:0] ascii_a_tens;
    reg [7:0] ascii_a_units;
    reg [7:0] ascii_b_tens;
    reg [7:0] ascii_b_units;
    reg [7:0] ascii_op;

    // Outputs
    wire [7:0] ascii_units;
    wire [7:0] ascii_tens;

    // Instantiate the Unit Under Test (UUT)
    ascii_calculator uut (
        .ascii_a_tens(ascii_a_tens),
        .ascii_a_units(ascii_a_units),
        .ascii_b_tens(ascii_b_tens),
        .ascii_b_units(ascii_b_units),
        .ascii_op(ascii_op),
        .ascii_units(ascii_units),
        .ascii_tens(ascii_tens)
    );

    initial begin
        // Initialize Inputs
        ascii_a_tens = 8'd48;
        ascii_a_units = 8'd48;
        ascii_b_tens = 8'd48;
        ascii_b_units = 8'd48;
        ascii_op = 8'd0;

        // Test addition
        #10 ascii_a_tens = 8'd52; ascii_a_units = 8'd50; ascii_b_tens = 8'd51; ascii_b_units = 8'd53; ascii_op = 8'd43; // '+'

        // Test subtraction
        #10 ascii_a_tens = 8'd55; ascii_a_units = 8'd53; ascii_b_tens = 8'd50; ascii_b_units = 8'd51; ascii_op = 8'd45; // '-'

        // Test multiplication
        #10 ascii_a_tens = 8'd48; ascii_a_units = 8'd52; ascii_b_tens = 8'd48; ascii_b_units = 8'd54; ascii_op = 8'd42; // '*'

        // Test division
        #10 ascii_a_tens = 8'd57; ascii_a_units = 8'd48; ascii_b_tens = 8'd48; ascii_b_units = 8'd51; ascii_op = 8'd47; // '/'

        // Test exponentiation
        #10 ascii_a_tens = 8'd48; ascii_a_units = 8'd51; ascii_b_tens = 8'd48; ascii_b_units = 8'd51; ascii_op = 8'd94; // '^'

        #10;
        $finish;
    end

endmodule

negedge