module uart_tx(clk, rstn, send, data1, data2, txd);
    input clk, rstn, send;
    input [7:0] data1, data2;
    output txd;
    
    // 定义状态
    localparam TX_IDLE = 0, TX_START = 1, TX_DATA = 2, TX_WAIT = 3, TX_FINISH = 4;

    reg [7:0] data_reg;
    reg [2:0] counter;
    reg [2:0] state, next_state; // 使用3位状态寄存器来表示多种状态
    reg txd;
    reg data_select; // 用于选择传输data1还是data2

    always @(posedge clk or negedge rstn)
        if (!rstn)
            state <= TX_IDLE;
        else
            state <= next_state;

    always @(*) begin
        case (state)
            TX_IDLE: next_state = send ? TX_START : TX_IDLE;
            TX_START: next_state = TX_DATA;
            TX_DATA: next_state = (counter == 7) ? (data_select ? TX_FINISH : TX_WAIT) : TX_DATA;
            TX_WAIT: next_state = TX_START;
            TX_FINISH: next_state = TX_IDLE;
        endcase
    end

    always @(posedge clk or negedge rstn)
        if (!rstn)
            counter <= 0;
        else if (state == TX_DATA)
            counter <= counter + 1;
        else
            counter <= 0;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            data_reg <= 0;
        else if (state == TX_IDLE && send)
            data_reg <= data1;
        else if (state == TX_WAIT)
            data_reg <= data2;
        else if (state == TX_DATA)
            data_reg <= {1'b0, data_reg[7:1]};
        else
            data_reg <= data_reg;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            txd <= 1;
        else if (state == TX_IDLE)
            txd <= 1;
        else if (state == TX_START)
            txd <= 0;
        else if (state == TX_DATA)
            txd <= data_reg[0];
        else if (state == TX_FINISH)
            txd <= 1;
        else
            txd <= 1;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            data_select <= 0;
        else if (state == TX_WAIT)
            data_select <= 1;
        else if (state == TX_FINISH)
            data_select <= 0;
        else
            data_select <= data_select;

endmodule

module uart_rx(clk, rstn, rxd, valid, data);
    input clk, rstn, rxd;
    output valid;
    output[7:0] data;

    localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_FINISH = 3;
    reg[9:0] data_reg;
    reg[2:0] counter;
    reg[1:0] state, next_state;
    reg valid;
    
    always @(posedge clk or negedge rstn)
        if (!rstn)
            state <= RX_IDLE;
        else
            state <= next_state;
    
    always @(*)
    case(state)
        RX_IDLE : next_state = !data_reg[9] ? RX_START : RX_IDLE;
        RX_START : next_state = RX_DATA;
        RX_DATA : next_state = counter == 7 ? RX_FINISH : RX_DATA;
        RX_FINISH : next_state = RX_IDLE;
    endcase

    always @(posedge clk or negedge rstn)
        if (!rstn)
            counter <= 0;
        else if (state == RX_DATA)
            counter <= counter + 1;
        else
            counter <= 0;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            data_reg <= 10'b1111111111;
        else
            data_reg <= {rxd, data_reg[9:1]};
    
    always @(posedge clk or negedge rstn)
        if (!rstn)
            valid <= 0;
        else if (counter == 7)
            valid <= 1;
        else
            valid <= 0;

    assign data = data_reg[7:0];

endmodule

module clk_div(clk, rstn, uart_clk);
    input clk, rstn;
    output uart_clk;
    localparam div_num = 100000000/19200;
    reg[15:0] num;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            num <= 0;
        else if (num != div_num)
            num <= num + 1;
        else
            num <= 0;

    reg uart_clk;
    always @(posedge clk or negedge rstn)
        if (!rstn)
            uart_clk <= 0;
        else if (num == div_num)
            uart_clk <= ~uart_clk;
        else
            uart_clk <= uart_clk;

endmodule

module debounce(clk, rstn, button_in, button_out);
    input clk, rstn, button_in;
    output button_out;
    reg button_out;
    reg button_reg;

    reg[15:0] counter;
    always @(posedge clk or negedge rstn)
        if (!rstn)
            counter <= 0;
        else if (button_reg != button_in || |counter)
            counter <= counter + 1;
        else
            counter <= 0;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            button_out <= 0;
        else if (|counter)
            button_out <= button_out;
        else
            button_out <= button_reg;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            button_reg <= 0;
        else if (|counter)
            button_reg <= button_reg;
        else
            button_reg <= button_in;

endmodule

module button_transmitter(clk, rstn, s3, out);
    input clk, rstn, s3;
    output out;

    reg state, next_state;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            state <= 0;
        else
            state <= next_state;

    always @(*)
    case(state)
        0 : next_state = (s3 == 1) ? 1 : 0;
        1 : next_state = (s3 == 1) ? 1 : 0;
    endcase

    assign out = (next_state == 1);

endmodule

// 生成数码管时钟信号
module led_clk_division(clk, rstn, led_clk);
    input clk, rstn;
    output led_clk;
    reg [15:0] led_clk_reg;
    assign led_clk = led_clk_reg[15];

    always @(posedge clk)
        if (!rstn)
            led_clk_reg <= 20'b0;
        else
            led_clk_reg <= led_clk_reg + 1;

endmodule

// 生成led_mux
module led_mux_generate(led_clk, rstn, led_mux);
    input led_clk, rstn;
    output reg [3:0] led_mux;
    always @(posedge led_clk or negedge rstn) begin
        if (!rstn)
            led_mux <= 4'b0001;
        else
            led_mux <= {led_mux[2:0], led_mux[3]};
    end

endmodule

module led_display(led_mux, ascii_units, ascii_tens, led); 
    input [3:0] led_mux;
    input [7:0] ascii_units;  // 结果的个位数字，ASCII码表示
    input [7:0] ascii_tens;  // 结果的十位数字，ASCII码表示
    output reg [6:0] led;

    always @(*) begin
        case (led_mux)
            4'b0001: begin
                case (ascii_units)
                    8'h30: led <= 7'b1111110;
                    8'h31: led <= 7'b0110000; // 键码为 8'h31 时显示 '1'
                    8'h32: led <= 7'b1101101; // 键码为 8'h32 时显示 '2'
                    8'h33: led <= 7'b1111001; // 键码为 8'h33 时显示 '3'
                    8'h34: led <= 7'b0110011; // 键码为 8'h34 时显示 '4'
                    8'h35: led <= 7'b1011011; // 键码为 8'h35 时显示 '5'
                    8'h36: led <= 7'b1011111; // 键码为 8'h36 时显示 '6'
                    8'h37: led <= 7'b1110000; // 键码为 8'h37 时显示 '7'
                    8'h38: led <= 7'b1111111; // 键码为 8'h38 时显示 '8'
                    8'h39: led <= 7'b1111011; // 键码为 8'h39 时显示 '9'
                    default: led <= 7'b0000000;
                endcase
            end
            4'b0010: begin
                case (ascii_tens)
                    // 8'h30: led <= 7'b1111110;
                    8'h31: led <= 7'b0110000; // 键码为 8'h31 时显示 '1'
                    8'h32: led <= 7'b1101101; // 键码为 8'h32 时显示 '2'
                    8'h33: led <= 7'b1111001; // 键码为 8'h33 时显示 '3'
                    8'h34: led <= 7'b0110011; // 键码为 8'h34 时显示 '4'
                    8'h35: led <= 7'b1011011; // 键码为 8'h35 时显示 '5'
                    8'h36: led <= 7'b1011111; // 键码为 8'h36 时显示 '6'
                    8'h37: led <= 7'b1110000; // 键码为 8'h37 时显示 '7'
                    8'h38: led <= 7'b1111111; // 键码为 8'h38 时显示 '8'
                    8'h39: led <= 7'b1111011; // 键码为 8'h39 时显示 '9'
                    default: led <= 7'b0000000;
                endcase
            end
            default: led <= 7'b0000000;
        endcase
    end

endmodule

module ascii_calculator (ascii_a_tens, ascii_a_units, ascii_b_tens, ascii_b_units, ascii_op, ascii_units, ascii_tens);
    input [7:0] ascii_a_tens;    // 第一个数字的十位，ASCII码表示
    input [7:0] ascii_a_units;   // 第一个数字的个位，ASCII码表示
    input [7:0] ascii_b_tens;    // 第二个数字的十位，ASCII码表示
    input [7:0] ascii_b_units;   // 第二个数字的个位，ASCII码表示
    input [7:0] ascii_op;        // 输入的操作符（+，-，*，/，^）
    output reg [7:0] ascii_units; // 结果的个位数字，ASCII码表示
    output reg [7:0] ascii_tens;   // 结果的十位数字，ASCII码表示

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

module calculator_fsm (clk, rstn, data, valid, ascii_units, ascii_tens);
    input clk, rstn;
    input [7:0] data;        // 输入的ASCII码
    input valid;             // 表明data是否有效
    output reg [7:0] ascii_units; // 结果的个位数字，ASCII码表示
    output reg [7:0] ascii_tens;  // 结果的十位数字，ASCII码表示

    reg [7:0] op;            // 当前的操作符
    reg [7:0] operand_tens;  // 当前操作数的十位
    reg [7:0] operand_units; // 当前操作数的个位
    reg [7:0] result_units;  // 中间结果的个位数字
    reg [7:0] result_tens;   // 中间结果的十位数字
    reg [7:0] state;         // 状态寄存器

    localparam S_IDLE = 8'd0;               // 闲置状态
    localparam S_BUF_1 = 8'd1;              // 输入第一个数后的缓冲状态
    localparam S_OPERAND_UNITS_1 = 8'd2;    // 输入第一个数的个位数字后的状态
    localparam S_OPERATOR = 8'd3;           // 输入运算符后的状态
    localparam S_OPERAND_TENS = 8'd4;       // 输入第二个数的第一个数字后的状态
    localparam S_BUF_2 = 8'd5;              // 输入第二个数后的缓冲状态
    localparam S_OPERAND_UNITS_2 = 8'd6;    // 输入第二个数的各位数字的状态
    localparam S_CALCULATE = 8'd7;          // 输入=后的计算状态（当第二个运算数是两位数字时）
    localparam S_CALCULATE_2 = 8'd8;        // 计算状态2（当第二个运算数是一位数字时）

    wire [7:0] calc_units;
    wire [7:0] calc_tens;

    // 调用ascii_caculator进行计算
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
            ascii_units <= 8'd0; // 不显示
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
                ascii_units <= 8'd0; // 不显示
                ascii_tens <= 8'd48;  // ASCII '0'
                operand_units <= 8'd48;
                operand_tens <= 8'd48;
                op <= 8'd43;
            end else begin
                case (state)
                    S_IDLE: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            ascii_units <= 8'd0;
                            ascii_tens <= 8'd48;
                            result_units <= data;
                            result_tens <= data;
                            state <= S_BUF_1;
                        end
                    end
                    S_BUF_1: begin
                        if (data == 8'd32) begin
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
                        else if (data == 8'd43 || data == 8'd45 || data == 8'd42 || data == 8'd47) begin
                            op <= data;
                            result_tens <= 8'd48;
                            ascii_tens <= 8'd48;
                            ascii_units <= result_units;
                            state <= S_OPERAND_TENS;
                        end
                    end
                    S_OPERATOR: begin
                        if (data == 8'd43 || data == 8'd45 || data == 8'd42 || data == 8'd47) begin
                            op <= data;
                            state <= S_OPERAND_TENS;
                        end
                    end
                    S_OPERAND_TENS: begin
                        if (data >= 8'd48 && data <= 8'd57) begin
                            operand_units <= data;
                            operand_tens <= data;
                            state <= S_BUF_2;
                        end
                    end
                    S_BUF_2: begin
                        if (data == 8'd32) begin
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
                        if (data == 8'd61) begin
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

module top(clk, rstn, s3, rxd, txd, out, led, led_mux);
    input clk, rstn, s3, rxd;
    output txd, out;
    output[6:0] led;
    output[3:0] led_mux;
    wire s3_deb, led_clk;
    wire uart_clk, valid;
    wire[7:0] data_to_fpga;
    wire[7:0] ascii_units;
    wire[7:0] ascii_tens;
    wire[3:0] led_mux_;
    wire[6:0] led_;

    // 主机→FPGA→计算
    clk_div my_clk(clk, rstn, uart_clk);
    uart_rx my_rx(uart_clk, rstn, rxd, valid, data_to_fpga);
    calculator_fsm my_calculator(clk, rstn, data_to_fpga, valid, ascii_units, ascii_tens);
    
    // 计算结果→FPGA→LED显示
    led_clk_division led_division_inst (clk, rstn, led_clk);
    led_mux_generate led_mux_inst (led_clk, rstn, led_mux_);
    led_display led_inst (led_mux_, ascii_units, ascii_tens, led_);

    // 按键→FPGA→主机显示
    debounce s3_init(clk, rstn, s3, s3_deb);
    button_transmitter button_tran(clk, rstn, s3_deb, out); 
    uart_tx my_tx_units(uart_clk, rstn, out, ascii_tens, ascii_units, txd);

    assign led_mux = led_mux_;
    assign led = led_;

endmodule
