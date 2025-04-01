module dotopt(input logic clk, input logic rst_n,
           // slave (CPU-facing)
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,

           // master_* (SDRAM-facing): weights (anb biases for task7)
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata,

           // master2_* (SRAM-facing to bank0 and bank1): input activations (and output activations for task7)
           input logic master2_waitrequest,
           output logic [31:0] master2_address,
           output logic master2_read, input logic [31:0] master2_readdata, input logic master2_readdatavalid,
           output logic master2_write, output logic [31:0] master2_writedata);

    logic [31:0] weight_base;
    logic [31:0] vector_base;
    logic [31:0] length;
    logic [31:0] addr_index;

    logic signed [31:0] temp_weight; 
    logic signed [31:0] temp_vector; 
    logic signed [63:0] product;     
    logic signed [31:0] sum;         


    enum{IDLE, READBOTH, WAITBOTH, COMPUTE, DONE} present_state;

    assign slave_readdata = (slave_read && slave_address == 4'd0) ? sum : 32'b0;
	 assign product = temp_weight * temp_vector;

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            present_state <= IDLE;
				slave_waitrequest <= 1'b0;
				master_write <= 1'b0;
				master2_write <= 1'b0;
				addr_index <= 32'b0;
				weight_base <= 32'b0;
				vector_base <= 32'b0;
				length <= 32'b0;
		  end
        else begin
            case(present_state)
            
				IDLE: begin
                addr_index <= 32'd0;
                if (slave_write) begin
                    sum <= 32'b0;       
                    case(slave_address)
                    4'd0: begin 
                        present_state <= READBOTH;  
                        slave_waitrequest <= 1'b1;          
                    end
                    4'd2: weight_base <= slave_writedata;   
                    4'd3: vector_base <= slave_writedata;   
                    4'd5: length <= slave_writedata;        
                    endcase
                end
            end

            READBOTH: begin
                if (addr_index < length) begin
                    master_read <= 1'b1;
                    master2_read <= 1'b1;
                    master_address <= weight_base + addr_index * 4;
                    master2_address <= vector_base + addr_index * 4;
                    present_state <= WAITBOTH;
                end
                else
                    present_state <= DONE;
            end

            WAITBOTH: begin
                if (master_waitrequest == 1'b0 && master2_waitrequest == 1'b0) begin
                    if (master_readdatavalid == 1'b1 && master2_readdatavalid == 1'b1) begin
                        master_read <= 1'b0;
                        master2_read <= 1'b0;
                        temp_weight <= master_readdata;   
                        temp_vector <= master2_readdata;
                        present_state <= COMPUTE;
                    end
                end
            end

            COMPUTE: begin
                sum <= sum + product[47:16]; 
                present_state <= READBOTH;
                addr_index <= addr_index + 1; 
            end

            DONE: begin
                slave_waitrequest <= 1'b0;
                present_state <= IDLE;
            end

            endcase
        end
    end

endmodule: dotopt