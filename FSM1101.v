module SequenceDetector (
    input wire clk,     // 时钟信号
    input wire din,     // 输入序列
    input wire clr,     // 清空输入序列信号
    output wire dout    // 输出结果
);
    reg [2:0] state;    // 状态寄存器，3位宽度

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            state <= 3'b000;    // 复位时，将状态置为初始状态S0
        end else begin
            case (state)
                3'b000: begin   // S0 状态
                    if (din) begin
                        state <= 3'b001;    // 输入为1，转移到 S1 状态
                    end else begin
                        state <= 3'b000;    // 输入为0，保持在 S0 状态
                    end
                end
                3'b001: begin   // S1 状态
                    if (din) begin
                        state <= 3'b010;    // 输入为1，转移到 S2 状态
                    end else begin
                        state <= 3'b000;    // 输入为0，返回初始状态 S0
                    end
                end
                3'b010: begin   // S2 状态
                    if (din) begin
                        state <= 3'b010;    // 输入为1，转移到 S2 状态
                    end else begin
                        state <= 3'b011;    // 输入为0，转到状态 S3
                    end
                end
                3'b011: begin   // S3 状态
                    if (din) begin
                        state <= 3'b100;    // 输入为1，转移到 S4 状态
                    end else begin
                        state <= 3'b000;    // 输入为0，返回初始状态 S0
                    end
                end
                3'b100: begin   // S4 状态
                    if (din) begin
                        state <= 3'b010;    // 输入为1，返回 S2 状态
                    end else begin
                        state <= 3'b000;    // 输入为0，返回初始状态 S0
                    end
                end
            endcase
        end
    end

    assign dout = (state == 3'b100) ? 1'b1 : 1'b0;    // 当状态为 S4 时，输出为 1，否则为 0
endmodule

module SequenceDetector_tb;
    reg clk;       // 时钟信号
    reg din;       // 输入序列
    reg clr;       // 清空输入序列信号
    wire dout;     // 输出结果

    SequenceDetector dut (
        .clk(clk),
        .din(din),
        .clr(clr),
        .dout(dout)
    );

    initial begin
        clk = 0;     // 初始时钟信号置为0
        din = 0;     // 初始输入序列置为0
        clr = 1;     // 清空输入序列信号置为1

        // 等待一段时间以进行复位
        #20;

        clr = 0;   // 复位信号置为0

        // 输入序列为1010
        din = 1;
        #10;
        din = 0;
        #10;
        din = 1;
        #10;
        din = 0;
        #10;

        // 输入序列为1101
        din = 1;
        #10;
        din = 1;
        #10;
        din = 0;
        #10;
        din = 1;
        #10;

        // 输入序列为1011
        din = 1;
        #10;
        din = 0;
        #10;
        din = 1;
        #10;
        din = 1;
        #10;

        // 输入序列为0101
        din = 0;
        #10;
        din = 1;
        #10;
        din = 0;
        #10;
        din = 1;
        #10;

        // 清空输入序列
        clr = 1;
        #10;
        clr = 0;

		// 输入序列为0101
        din = 0;
        #10;
        din = 1;
        #10;
        din = 0;
        #10;
        din = 1;
        #10;

        $finish;     // 结束仿真
    end

    always begin
        #5;        
        clk = ~clk; 
    end

endmodule