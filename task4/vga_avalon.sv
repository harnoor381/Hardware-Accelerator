module vga_avalon(
    input logic clk, input logic reset_n,
    input logic [3:0] address,
    input logic read, output logic [31:0] readdata,
    input logic write, input logic [31:0] writedata,
    output logic [7:0] vga_red, output logic [7:0] vga_grn, output logic [7:0] vga_blu,
    output logic vga_hsync, output logic vga_vsync, output logic vga_clk
);

    logic [9:0] vga_r, vga_g, vga_b;
    logic vga_plot;
    logic [7:0] vga_x, x_in;
    logic [6:0] vga_y, y_in;
    logic [7:0] vga_colour;
    logic [7:0] colour;

    // Instantiate the VGA adapter
    vga_adapter #(
        .RESOLUTION("160x120"),
        .MONOCHROME("TRUE"),
        .BITS_PER_COLOUR_CHANNEL(8)
    ) vga (
        .resetn(reset_n),
        .clock(clk),
        .colour(vga_colour),
        .x(vga_x),
        .y(vga_y),
        .plot(vga_plot),
        .VGA_R(vga_r),
        .VGA_G(vga_g),
        .VGA_B(vga_b),
        .VGA_HS(vga_hsync),
        .VGA_VS(vga_vsync),
        .VGA_BLANK(),
        .VGA_SYNC(),
        .VGA_CLK(vga_clk)
    );

    // Assign VGA outputs
    assign vga_red = vga_r[9:2];
    assign vga_grn = vga_g[9:2];
    assign vga_blu = vga_b[9:2];

    // Extract input data
    assign x_in = writedata[23:16];
    assign y_in = writedata[30:24];
    assign colour = writedata[7:0];

    always_ff @(posedge clk) begin
        if (~reset_n) begin
            vga_x <= 8'd0;
            vga_y <= 7'd0;
            vga_plot <= 1'b0;
            vga_colour <= 8'd0;
            readdata <= 32'd0;
        end else begin
            // Default state for vga_plot
            vga_plot <= 1'b0;

            if (write && address == 4'd0) begin
                if (x_in < 8'd160 && y_in < 7'd120) begin
                    vga_x <= x_in;
                    vga_y <= y_in;
                    vga_colour <= colour;
                    vga_plot <= 1'b1;
                end
                // Ignore invalid coordinates
            end		
				
            // Ignore other addresses and reads
        end
    end

endmodule: vga_avalon
