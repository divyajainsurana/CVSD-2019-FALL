module MicroController #(parameter SWITCH = 8)(
    input clk,
    input rst_n,

    output reg m0_ready, m1_ready,
    input  m0_valid, m1_valid,

    output reg select,

    input fifo_iready,
    input fifo_almost_full, fifo_full
);
wire n_m0_ready, n_m1_ready;
wire n_select;

parameter SWITCH_BIT = $clog2(SWITCH);
reg [SWITCH_BIT-1 : 0] counter, n_counter;

assign n_m0_ready = ~fifo_almost_full & ~n_select;
assign n_m1_ready = ~fifo_almost_full &  n_select;
assign n_select = select ? ~(counter == SWITCH-1 && m1_ready && m1_valid) : (counter == SWITCH-1 && m0_ready && m0_valid);

always @(*) begin
    if ( (m0_ready & m0_valid) | (m1_ready & m1_valid) )n_counter = (counter == SWITCH-1) ? 0 : counter +1;
    else n_counter = counter;
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        counter <= 0;
        m0_ready <= 1'b0;
        m1_ready <= 1'b0;
        select <= 1'b0;
    
    end else begin
        counter <= n_counter;
        m0_ready <= n_m0_ready;
        m1_ready <= n_m1_ready;
        select <= n_select;
    
    end
end
endmodule

module controller #(parameter SWITCH = 8)(
    input clk,
    input rst_n,

    output m0_awready, m1_awready, m0_wready, m1_wready,
    input  m0_awvalid, m1_awvalid, m0_wvalid, m1_wvalid,

    output aw_select, w_select,

    input awfifo_iready, wfifo_iready,
    input awfifo_almost_full, awfifo_full, wfifo_almost_full, wfifo_full
);

MicroController #(.SWITCH(SWITCH)) aw (.clk(clk), .rst_n(rst_n), .m0_ready(m0_awready), .m1_ready(m1_awready), 
    .m0_valid(m0_awvalid), .m1_valid(m1_awvalid), 
    .select(aw_select), .fifo_iready(awfifo_iready), .fifo_almost_full(awfifo_almost_full), .fifo_full(awfifo_full));

MicroController #(.SWITCH(SWITCH))  w(.clk(clk), .rst_n(rst_n), .m0_ready(m0_wready), .m1_ready(m1_wready), 
    .m0_valid(m0_wvalid), .m1_valid(m1_wvalid), 
    .select(w_select), .fifo_iready(wfifo_iready), .fifo_almost_full(wfifo_almost_full), .fifo_full(wfifo_full));
endmodule