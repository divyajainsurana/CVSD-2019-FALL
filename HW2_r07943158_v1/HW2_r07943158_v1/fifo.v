module fifo # (
	parameter DATA_WIDTH = 8,
	parameter FIFO_DEPTH = 8
) 
(
	input                       clk,
	input                       rst_n,
	input      [DATA_WIDTH-1:0] idata,
	input                       ivalid,
	output reg                  iready,
	output reg [DATA_WIDTH-1:0] odata,
	output reg                  ovalid,
	input                       oready,
	output reg                  full,
	output                      almost_full
);
	wire [DATA_WIDTH-1:0] n_odata;
	wire n_almost_full, n_full, n_iready, n_ovalid;

	wire send, received;

	parameter PTR_WIDTH = $clog2(FIFO_DEPTH);  // clog2 = log2 + ceiling
	reg [DATA_WIDTH-1:0] fifo_data [FIFO_DEPTH-1:0];
	wire [DATA_WIDTH-1:0] n_fifo_data [FIFO_DEPTH-1:0];
	reg [ PTR_WIDTH-1:0] read_ptr, write_ptr;
	wire [ PTR_WIDTH-1:0] n_read_ptr, n_write_ptr;
	reg [PTR_WIDTH : 0] size, n_size;

	assign send = oready & ovalid;
	assign received = iready & ivalid;
	assign almost_full = n_full;
	
	assign n_full = (size >= FIFO_DEPTH-1 & received & ~send) | (full & ~send);
	assign n_iready = ~n_full;
	assign n_ovalid = ( size != 0 ) && ~send;
	assign n_odata = fifo_data[read_ptr];
	assign n_read_ptr = send ? (read_ptr == FIFO_DEPTH -1 ? 0 : read_ptr +1) : read_ptr;
	assign n_write_ptr = received ? (write_ptr == FIFO_DEPTH -1 ? 0 : write_ptr +1) : write_ptr;

	genvar idx;
	generate 
		for ( idx= 0;idx < FIFO_DEPTH ; idx = idx+1) begin
			assign n_fifo_data[idx] = (write_ptr == idx && received) ? idata : fifo_data[idx];
		end
	endgenerate

	always @(*) begin
		case({received, send})
			2'b10 : n_size = size +1;
			2'b01 : n_size = size -1;
			default : n_size = size;
		endcase
	end

	integer i;
	always @ (posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			iready <= 1'd1;
			odata <= 0;
			ovalid <= 1'd0;
			full <= 1'd0;
			read_ptr <= 0;
			write_ptr <= 0;
			size <= 0;

			for (i = 0;i < FIFO_DEPTH ;i = i+1 )fifo_data[i] <= 0;
		end else begin
			iready <= n_iready;
			odata <= n_odata;
			ovalid <= n_ovalid;
			full <= n_full;
			read_ptr <= n_read_ptr;
			write_ptr <= n_write_ptr;
			size <= n_size;

			for (i = 0;i < FIFO_DEPTH ;i = i+1 )fifo_data[i] <= n_fifo_data[i];
		end
	end
endmodule
