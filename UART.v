module uart_tx(clk, rstn, send, data, txd);
    input clk, rstn, send;
    input[7:0] data;
    output txd;
    
    localparam TX_IDLE = 0, TX_START = 1, TX_DATA = 2, TX_FINISH = 3;
    reg[7:0] data_reg;
    reg[2:0] counter;
    reg[1:0] state, next_state;
    reg txd;
    
    always @(posedge clk or negedge rstn)
        if (!rstn)
            state <= TX_IDLE;
        else
            state <= next_state;

    always @(*)
    case(state)
        TX_IDLE : next_state = send ? TX_START : TX_IDLE;
        TX_START : next_state = TX_DATA;
        TX_DATA : next_state = counter == 7 ? TX_FINISH : TX_DATA;
        TX_FINISH : next_state = TX_IDLE;
    endcase

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
            data_reg <= data;
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

    reg[4:0] counter;
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

/*module valid_hold(clk, rstn, valid_in, valid_out);
    input clk, rstn, valid_in;
    output reg valid_out;

    parameter [27:0] HOLD_CYCLES = 28'h1000000;
    reg [27:0] counter;

    always @(posedge clk or negedge rstn)
        if (!rstn) begin
            counter <= 28'd0;
            valid_out <= 1'b0;
        end
        else begin
            if (valid_in) begin
                counter <= HOLD_CYCLES - 1;
                valid_out <= 1'b1;
            end
            else if (counter > 0) begin
                counter <= counter - 1;
                valid_out <= 1'b1;
            end
            else
                valid_out <= 1'b0;
        end

endmodule*/

module display_reveiver(clk, rstn, data_to_fpga, valid, led, led_dn);
    input rstn, clk, valid;
    input[7:0] data_to_fpga;
    output reg[6:0] led;
    output led_dn;
    reg[6:0] pre_led;

    assign led_dn = 1;

    always @(posedge clk or negedge rstn)
        if(!rstn)
            led <= 7'b0000000;
        else if(valid == 1) begin
            case(data_to_fpga)
                8'h30: led <= 7'b1111110; // 键码为 8'h30 时显示 '0'
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
            pre_led <= led;
        end
        else
            led <= pre_led;

endmodule

module top(clk, rstn, s3, rxd, txd, out, led, led_dn);
    input clk, rstn, s3, rxd;
    output txd, out;
    output[6:0] led;
    output led_dn;
    
    reg[7:0] data_from_fpga = 8'h31;
    wire uart_clk, valid, valid_out;
    wire[7:0] data_to_fpga; 

    clk_div my_clk(clk, rstn, uart_clk);
    debounce s3_init(clk, rstn, s3, s3_deb);
    button_transmitter button_tran(clk, rstn, s3_deb, out);
    uart_tx my_tx(uart_clk, rstn, out, data_from_fpga, txd);
    uart_rx my_rx(uart_clk, rstn, rxd, valid, data_to_fpga);
    // valid_hold my_valid(clk, rstn, valid, valid_out);
    display_reveiver display_rev(clk, rstn, data_to_fpga, valid, led, led_dn);

endmodule

module uart_tb();
    localparam CLK_PERIOD = 10;
    reg clk, rstn, send;
    reg [7:0] tx_data;
    wire txd, valid;
    wire [7:0] rx_data;

    uart_tx my_tx(clk, rstn, send, tx_data, txd);
    uart_rx my_rx(clk, rstn, txd, valid, rx_data);
    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2);
        clk = 1'b1;
        #(CLK_PERIOD/2);
    end

    initial begin
        rstn = 1'b0;
        send = 1'b0;
        tx_data = 8'b0;
        #100;
        rstn = 1'b1;
        #100;

        // Send a byte
        tx_data = 8'hA5;
        send = 1'b1;
        #CLK_PERIOD;
        send = 1'b0;

        // Wait for transmission to complete
        wait(valid);
        #CLK_PERIOD;

        // Check received data
        if (rx_data == tx_data) begin
            $display("Test passed: received data = %h", rx_data);
        end else begin
            $display("Test failed: received data = %h", rx_data);
        end

        #100;
        $stop;
    end

endmodule
