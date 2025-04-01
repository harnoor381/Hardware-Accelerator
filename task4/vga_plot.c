#define VGA_BASE 0x4000 

void vga_plot(unsigned x, unsigned y, unsigned colour)
{
    if (x >= 160 || y >= 120)
        return; 

    unsigned int data = ((y & 0x7F) << 24) |  // y[30:24]
        ((x & 0xFF) << 16) |  // x[23:16]
        (colour & 0xFF);      // colour[7..0]

    // Write the data to the VGA module at 0x4000
    volatile unsigned int* vga_ptr = (unsigned int*)VGA_BASE;
    *vga_ptr = data;
}

