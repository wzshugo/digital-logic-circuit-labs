module keyboard(rstn, ps2_clk, ps2_data, key_valid, key);
    input rstn, ps2_clk, ps2_data;
    output key_valid;
    output[7:0] key;

    reg[10:0] shift_reg;
    always @(negedge ps2_clk or negedge rstn)
        if (!rstn)
            shift_reg <= 0;
        else
            shift_reg <= {ps2_data, shift_reg[10:1]};

    reg[3:0] counter;
    always @(negedge ps2_clk or negedge rstn)
        if (!rstn)
            counter <= 0;
        else if (counter == 10)
            counter <= 0;
        else
            counter <= counter + 1;
    
    reg key_valid;
    always @(negedge ps2_clk or negedge rstn)
        if (!rstn)
            key_valid <= 0;
        else if (counter == 10 && shift_reg[10] == ~^shift_reg[9:2])
            key_valid <= 1;
        else
            key_valid <= 0;
    
    assign key = shift_reg[8:1];   
endmodule

module debounce(clk, rstn, button_in, button_out);
    input clk, rstn, button_in;
    output button_out;
    reg button_out;
    reg button_reg;

    reg[12:0] counter;
    always @(negedge clk or negedge rstn)
        if (!rstn)
            counter <= 0;
        else if (button_reg != button_in || |counter)
            counter <= counter + 1;
        else
            counter <= 0;

    always @(negedge clk or negedge rstn)
        if (!rstn)
            button_out <= 0;
        else if (|counter)
            button_out <= button_out;
        else
            button_out <= button_reg;

    always @(negedge clk or negedge rstn)
        if (!rstn)
            button_reg <= 0;
        else if (|counter)
            button_reg <= button_reg;
        else
            button_reg <= button_in;

endmodule

module display(key_valid, key, led, led_dn);
    input key_valid;
    input[7:0] key;
    output reg[6:0] led;
    output led_dn;

    assign led_dn = 1;
    reg[7:0] pre_key;

    always @(*)
    if(key_valid) begin
        case(key)
            8'h45: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1111110; // 键码为 8'h45 时显示 '0'
            8'h16: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b0110000; // 键码为 8'h16 时显示 '1'
            8'h1e: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1101101; // 键码为 8'h1e 时显示 '2'
            8'h26: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1111001; // 键码为 8'h26 时显示 '3'
            8'h25: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b0110011; // 键码为 8'h25 时显示 '4'
            8'h2e: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1011011; // 键码为 8'h2e 时显示 '5'
            8'h36: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1011111; // 键码为 8'h36 时显示 '6'
            8'h3d: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1110000; // 键码为 8'h3d 时显示 '7'
            8'h3e: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1111111; // 键码为 8'h3e 时显示 '8'
            8'h46: led <= (pre_key == 8'hf0) ? 7'b0000000 : 7'b1111011; // 键码为 8'h46 时显示 '9'
            default: led <= 7'b0000000; // 其他键码时不显示
        endcase
        pre_key <= key; // 存储当前键码作为下一个周期的前一个键码
    end

endmodule

module top(clk, rstn, ps2_clk, ps2_data, led, led_dn);
    input clk, rstn, ps2_clk, ps2_data;
    output[6:0] led;
    output led_dn;
    wire ps2_clk_deb, ps2_data_deb, key_valid;
    wire[7:0] key;

    debounce clk_deb(clk, rstn, ps2_clk , ps2_clk_deb);
    debounce data_deb(clk, rstn, ps2_data, ps2_data_deb);
    keyboard my_keyboard(rstn, ps2_clk_deb, ps2_data_deb, key_valid, key);
    display led_dis(key_valid, key, led, led_dn);

endmodule

module keybord_tb;
    reg rstn, ps2_clk, ps2_data;
    wire key_valid;
    wire[7:0] key;

    keyboard my_keyboard(rstn, ps2_clk, ps2_data, key_valid, key);
    
    reg[10:0] data;
    integer i;
    initial
    begin
        rstn = 1;
        ps2_clk = 1;
        ps2_data = 1;
        data = 11'b10000101100;

        #3 rstn = 0;
        #3 rstn = 1;
        for (i = 0; i < 22; i= i + 1)
        begin
            #10;
            ps2_clk = ~ps2_clk;
            ps2_data = data[(i/2)%11];
        end
        #100 $finish;
    end
endmodule