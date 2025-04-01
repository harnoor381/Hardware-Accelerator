module dot(
    input logic clk,
    input logic rst_n,
    // Slave interface (CPU-facing)
    output logic slave_waitrequest,
    input logic [3:0] slave_address,
    input logic slave_read,
    output logic [31:0] slave_readdata,
    input logic slave_write,
    input logic [31:0] slave_writedata,
    // Master interface (SDRAM-facing)
    input logic master_waitrequest,
    output logic [31:0] master_address,
    output logic master_read,
    input logic [31:0] master_readdata,
    input logic master_readdatavalid,
    output logic master_write,            
    output logic [31:0] master_writedata  
);

    // Parameters from CPU
    logic [31:0] weight_addr;
    logic [31:0] input_addr;
    logic [31:0] vector_length;
	 logic signed [63:0] product_full;

    // Control signals
    logic [31:0] element_index;
    logic signed [63:0] accumulator;
    logic signed [31:0] temp_weight;
    logic signed [31:0] temp_input;

    // State machine states
    typedef enum logic[2:0] {IDLE, READ_WEIGHT, WAIT_WEIGHT_READ, READ_INPUT, WAIT_INPUT_READ, COMPUTE, ACCUMULATE} state_t;
    state_t present_state;
	 
	 assign slave_readdata = ((slave_address == 4'd0) && slave_read) ? accumulator : 32'd0;

    // State machine and control signals
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            // Reset all registers and signals
            present_state <= IDLE;
            weight_addr <= 32'd0;
            input_addr <= 32'd0;
            vector_length <= 32'd0;
            element_index <= 32'd0;
            accumulator <= 64'd0;
            temp_weight <= 32'd0;
            temp_input <= 32'd0;
            master_read <= 1'b0;
            master_write <= 1'b0;
            master_address <= 32'd0;
				slave_waitrequest <= 1'b0;
				product_full <= 64'd0;
        end else begin
            case (present_state)
                IDLE: begin
                    master_read <= 1'b0;
                    master_write <= 1'b0;
           
                    if (slave_write) begin
                        // Handle parameter writes from CPU
                        case (slave_address)
                            4'd0: begin
                                // Start computation command
										  slave_waitrequest <= 1'b1;
										  present_state <= READ_WEIGHT;
										  element_index <= 0;
										  accumulator <= 64'd0;
                            end
                            4'd2: weight_addr <= slave_writedata;
                            4'd3: input_addr <= slave_writedata;
                            4'd5: vector_length <= slave_writedata;
                        endcase
                    end
                end

                READ_WEIGHT: begin
						  master_write <= 1'b0;
                    if (element_index < vector_length) begin
									present_state <= WAIT_WEIGHT_READ;
									master_read <= 1'b1;
									master_address <= weight_addr + element_index * 4;
                    end else begin
									slave_waitrequest <= 1'b0;
									present_state <= IDLE;
                    end	
                end

                WAIT_WEIGHT_READ: begin
                    if (master_readdatavalid && !master_waitrequest) begin
                        temp_weight <= master_readdata;
                        master_read <= 1'b0;
                        present_state <= READ_INPUT;
                    end
                end

                READ_INPUT: begin
                    master_read <= 1'b1;
                    master_address <= input_addr + element_index * 4;
                    present_state <= WAIT_INPUT_READ;
                end

                WAIT_INPUT_READ: begin
                    if (master_readdatavalid && !master_waitrequest) begin
                        temp_input <= master_readdata;
                        master_read <= 1'b0;
                        present_state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    product_full <= temp_weight * temp_input; // 32-bit x 32-bit
						  present_state <= ACCUMULATE;
					 end
					 
					 ACCUMULATE: begin 
						  accumulator <= accumulator + product_full[47:16];        // Shift to maintain Q16.16 format
						  element_index <= element_index + 1;
						  present_state <= READ_WEIGHT;				 
					 end
					 
                default: present_state <= IDLE;
            endcase
        end
    end	 
endmodule
	 
