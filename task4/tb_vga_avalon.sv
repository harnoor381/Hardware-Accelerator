`timescale 1ps/1ps

module tb_vga_avalon();

    // Clock and reset signals
    logic clk;
    logic reset_n;

    // Avalon interface signals
    logic [3:0] address;
    logic read;
    logic write;
    logic [31:0] writedata;
    logic [31:0] readdata;

    // VGA signals
    logic [7:0] vga_red;
    logic [7:0] vga_grn;
    logic [7:0] vga_blu;
    logic vga_hsync;
    logic vga_vsync;
    logic vga_clk;

    // Instantiate the vga_avalon module
    vga_avalon dut (
        .clk(clk),
        .reset_n(reset_n),
        .address(address),
        .read(read),
        .readdata(readdata),
        .write(write),
        .writedata(writedata),
        .vga_red(vga_red),
        .vga_grn(vga_grn),
        .vga_blu(vga_blu),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_clk(vga_clk)
    );

    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Period = 20 ns
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset_n = 0;
        address = 4'd0;
        read = 0;
        write = 0;
        writedata = 32'd0;

        // Release reset after some time
        #50 reset_n = 1;

        // Wait for the system to stabilize
        #20;

        // Test Case 1: Valid write within screen boundaries
        write_pixel(8'd50, 7'd60, 8'hFF); // Plot a white pixel at (50,60)
        #20;

        // Test Case 2: Invalid X coordinate (out of bounds)
        write_pixel(8'd160, 7'd60, 8'hAA); // Should be ignored
        #20;

        // Test Case 3: Invalid Y coordinate (out of bounds)
        write_pixel(8'd50, 7'd120, 8'h55); // Should be ignored
        #20;

        // Test Case 4: Valid write at another position
        write_pixel(8'd100, 7'd80, 8'h00); // Plot a black pixel at (100,80)
        #20;

        // Test Case 5: Write to a different address (should be ignored)
        address = 4'd1;
        write_pixel(8'd70, 7'd50, 8'h77); // Should be ignored
        #20;

        // Finish simulation
        #100 $stop;
    end

    // Task to simulate a write operation
    task write_pixel(input [7:0] x, input [6:0] y, input [7:0] brightness);
        begin
            // Prepare writedata according to the specified format
            writedata = {1'b0, y, x, 8'd0, brightness};
            address = 4'd0; // Ensure address is 0 for valid write
            write = 1;
            #20; // Hold write high for one clock cycle
            write = 0;
        end
    endtask

    // Monitor internal signals
    initial begin
        $monitor("Time=%0t | write=%b, address=%h, x=%d, y=%d, colour=%h, vga_plot=%b",
                 $time, write, address, dut.vga_x, dut.vga_y, dut.vga_colour, dut.vga_plot);
    end
	 

endmodule: tb_vga_avalon

