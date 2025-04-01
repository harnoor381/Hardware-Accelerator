module wordcopy(input logic clk, input logic rst_n,
                // slave (CPU-facing)
                output logic slave_waitrequest,
                input logic [3:0] slave_address,
                input logic slave_read, output logic [31:0] slave_readdata,
                input logic slave_write, input logic [31:0] slave_writedata,
                // master (SDRAM-facing)
                input logic master_waitrequest,
                output logic [31:0] master_address,
                output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
                output logic master_write, output logic [31:0] master_writedata);

    logic [31:0] dst_addr;
    logic [31:0] src_addr;
    logic [31:0] num_words;
    logic [31:0] word_offset;

    typedef enum logic[2:0]{IDLE, READ, WAITREAD, WRITE, WAITWRITE} state_t;
	 state_t present_state;

    assign slave_readdata = 32'b0;

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            present_state <= IDLE;
				slave_waitrequest <= 1'b0;
				dst_addr <= 32'd0;
				src_addr <= 32'd0;
				num_words <= 32'd0;
				word_offset <= 32'd0;
				master_read <= 1'b0;
				master_write <= 1'b0;
				master_address <= 32'd0; 
        end else begin
            case(present_state)
					IDLE: begin
						 word_offset <= 0;
						 if (slave_write) begin
							  case(slave_address)
							  4'd0: begin 
									present_state <= READ; 
									slave_waitrequest <= 1'b1;
							  end
							  4'd1: begin
									dst_addr <= slave_writedata;
									slave_waitrequest <= 1'b0;
							  end
							  4'd2: begin 
									src_addr <= slave_writedata;
									slave_waitrequest <= 1'b0;
							  end
							  4'd3: begin
									num_words <= slave_writedata;
									slave_waitrequest <= 1'b0;
							  end
							  endcase
						 end else slave_waitrequest <= 1'b0;
					end

					READ: begin
						 master_write <= 1'b0;
						 if (word_offset < num_words) begin
							  master_read <= 1'b1;
							  master_address <= src_addr + word_offset * 4;
							  present_state <= WAITREAD;
						 end else present_state <= IDLE;
					end

					WAITREAD: begin
						 if (!master_waitrequest) begin
							  master_read <= 1'b0;
							  present_state <= WRITE;
						 end
					end

					WRITE: begin
						 if (master_readdatavalid) begin
							  master_write <= 1'b1;
							  master_writedata <= master_readdata;
							  master_address <= dst_addr + word_offset * 4;
							  present_state <= WAITWRITE;
						 end
					end

					WAITWRITE: begin
						 if (!master_waitrequest) begin
							  master_write <= 1'b0;
							  word_offset <= word_offset + 1;
							  present_state <= READ;
						 end
					end	
           endcase
        end
    end
endmodule 