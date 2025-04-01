#include "vga_plot.c"

#define SCREEN_WIDTH 160
#define SCREEN_HEIGHT 120

unsigned char frame_buffer[SCREEN_HEIGHT][SCREEN_WIDTH];
unsigned char greyscale_buffer[SCREEN_HEIGHT][SCREEN_WIDTH];

unsigned char pixel_list[] = {
#include "../misc/pixels.txt"
};
unsigned num_pixels = sizeof(pixel_list) / 2;

int weights[5][5] = {
    {1, 2, 4, 2, 1},
    {2, 4, 8, 4, 2},
    {4, 8, 16, 8, 4},
    {2, 4, 8, 4, 2},
    {1, 2, 4, 2, 1}
};

void clear_frame_buffer()
{
    for (unsigned y = 0; y < SCREEN_HEIGHT; y++) {
        for (unsigned x = 0; x < SCREEN_WIDTH; x++) {
            frame_buffer[y][x] = 0;
        }
    }
}

void set_pixels_from_list()
{
    for (unsigned int i = 0; i < num_pixels; i++) {
        unsigned char x = pixel_list[i * 2];
        unsigned char y = pixel_list[i * 2 + 1];
        if (x < SCREEN_WIDTH && y < SCREEN_HEIGHT) {
            frame_buffer[y][x] = 255;
        }
    }
}

void draw_buffer(unsigned char buffer[SCREEN_HEIGHT][SCREEN_WIDTH])
{
    for (unsigned y = 0; y < SCREEN_HEIGHT; y++) {
        for (unsigned x = 0; x < SCREEN_WIDTH; x++) {
            unsigned char colour = buffer[y][x];
            vga_plot(x, y, colour);
        }
    }
}

unsigned char compute_brightness(int x, int y)
{
    signed int brightness = 0;
    for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
            int nx = x + dx;
            int ny = y + dy;
            if (nx >= 0 && nx < SCREEN_WIDTH && ny >= 0 && ny < SCREEN_HEIGHT) {
                int weight = weights[dy + 2][dx + 2];
                int pixel_value = frame_buffer[ny][nx];
                brightness += pixel_value * weight;
            }
        }
    }
    brightness = (brightness/100); // Normalize based on total weight
    return (unsigned char)brightness;
}

void apply_grayscale_transformation()
{
    for (int y = 0; y < SCREEN_HEIGHT; y++) {
        for (int x = 0; x < SCREEN_WIDTH; x++) {
            greyscale_buffer[y][x] = compute_brightness(x, y);
        }
    }
}

int main()
{
    clear_frame_buffer();
    set_pixels_from_list();
    draw_buffer(frame_buffer); // Draw initial image
    apply_grayscale_transformation();
    draw_buffer(greyscale_buffer);  // Draw grayscale image

    while (1);
    return 0;
}
