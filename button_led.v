module detector(clk, rstn, left, right, out);
    input clk, rstn, left, right;
    output out;

    reg[3:0] state, next_state;

    always @(posedge clk or negedge rstn)
        if (!rstn)
            state <= 0;
        else
            state <= next_state;
        
    wire[1:0] button;
    assign button = {left, right};
    
    always @(*)
    case(state)
        0 : next_state = (button==2'b10) ? 1 : 0;
        1 : next_state = (button==2'b00) ? 2 : (button==2'b10) ? 1 : 0;
        2 : next_state = (button==2'b10) ? 3 : (button==2'b00) ? 2 : 0;
        3 : next_state = (button==2'b00) ? 4 : (button==2'b10) ? 3 : 0;
        4 : next_state = (button==2'b01) ? 5 : (button==2'b00) ? 4 : (button==2'b10) ? 3 : 0;
        5 : next_state = (button==2'b00) ? 6 : (button==2'b01) ? 5 : 0;
        6 : next_state = (button==2'b10) ? 7 : (button==2'b00) ? 6 : 0;
        7 : next_state = (button==2'b00) ? 8 : (button==2'b10) ? 7 : 0;
        8 : next_state = (button==2'b10) ? 3 : (button==2'b00) ? 8 : 0;
    endcase

    assign out = next_state == 8;
endmodule

module debounce(clk, rstn, button_in, button_out);
    input clk, rstn, button_in;
    output button_out;
    reg button_out;
    reg button_reg;

    reg[1:0] counter;
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

module top(clk, rstn, left, right, led_out, led_left, led_right);
    input clk, rstn, left, right;
    output led_out, led_left, led_right;
     
    debounce s3_init(clk, rstn, left, led_left);
    debounce s0_init(clk, rstn, right, led_right);
    detector detector_init(clk, rstn, led_left, led_right, led_out);

endmodule

module top_tb;
    reg clk;
    reg rstn;
    reg left;
    reg right;

    wire led_out;
    wire led_left;
    wire led_right;

    top uut(clk, rstn, left, right, led_out, led_left, led_right);

    always #5 clk = ~clk;

	parameter INPUT_COUNT = 8;  

    initial begin
        clk = 0;
        rstn = 0;
        left = 0;
        right = 0;
        @(posedge clk);
        rstn = 1;

        left = 1; right = 0; #50;
        left = 0; right = 0; #50;
        left = 1; right = 0; #50;
        left = 0; right = 0; #50;
        left = 0; right = 1; #50;
        left = 0; right = 0; #50;
        left = 1; right = 0; #50;
        left = 0; right = 0; #50;
        left = 1; right = 0; #50;
        left = 0; right = 0; #50;
        left = 0; right = 1; #50;
        left = 0; right = 0; #50;
        left = 1; right = 0; #50;
        left = 0; right = 0; #50;

        $finish;
    end

endmodule