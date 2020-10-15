module huffman(clk, reset, sram_a, sram_d, sram_wen, sram_q, finish);

input            clk;
input            reset;
output reg [9:0] sram_a;
output reg [7:0] sram_d;
output reg       sram_wen;
input  [7:0]     sram_q;
output reg       finish;
reg [7:0] sram_a_r;
wire [9:0] sram_a_w;
wire [7:0] sram_d_w;
wire sram_wen_w;
wire finish_w;

// This Sram is only used for synthesis
wire   [7:0] sram_q_internal;
sram_1024x8_t13 u_sram(
                    .Q          (sram_q_internal ),
                    .CLK        (clk             ),
                    .CEN        (1'b0            ),
                    .WEN        (sram_wen        ),
                    .A          (sram_a          ),
                    .D          (sram_d          )
);

reg [6:0] CNT [0:5]; //symbols
reg [6:0] n_CNT [0:5];
reg [5:0] index_value [0:5];//probabilty count
reg [5:0] n_index_value [0:5];
reg [2:0] CNT_size;
wire [2:0] CNT_size_w;
wire [12:0] insert_value_w;
wire [5:0] sort_w, insert_w;
reg [4:0] HC [0:5]; //huffman code
reg [4:0] n_HC [0:5];
reg [4:0] M [0:5]; //masked value
reg [4:0] n_M [0:5];


integer i, j;

//check whether sram_a is at which address 
assign sram_a_w = sram_a_r == 10'd100 ? 8'd128 :
                  sram_a_r == 10'd133 ? 8'd123 :
                  sram_a_r == 10'd127 ? 8'd134 : sram_a_r + 8'd1;



assign sram_d_w = sram_a_r[4:0] == 5'd0 ? {1'd0, n_CNT[0]} :
                  sram_a_r[4:0] == 5'd6 ? {3'd0, n_HC[0]} :
                  sram_a_r[4:0] < 5'd6 ? {1'd0, CNT[sram_a_r[2:0]]} :
                  sram_a_r[4:0] >= 5'd6 && sram_a_r[4:0] < 5'd12 ? {3'd0, HC[sram_a_r[3:0] - 4'd6]} :
                  {3'd0, M[sram_a_r[4:0] - 5'd12]};
assign sram_wen_w = ~sram_a_r[7];
assign finish_w = (sram_a_r == 10'd146);


assign insert_w[0] = sort_w[0];
generate
genvar g;
    for(g = 0; g < 6; g = g +1) assign sort_w[g] = CNT[g] < insert_value_w[12:6];
    for(g = 1; g < 6; g = g +1) assign  insert_w[g] = sort_w[g] && ~sort_w[g-1] && g <= CNT_size;
endgenerate

assign insert_value_w = sram_a_r[7] || sram_a_r == 8'd123 ? {CNT[CNT_size], index_value[CNT_size]} : {CNT[CNT_size] + CNT[CNT_size + 3'd1], index_value[CNT_size] | index_value[CNT_size + 3'd1]};


assign CNT_size_w = (sram_a_r > 128 && sram_a_r <= 133) ? CNT_size + 3'd1 : 
                    (sram_a_r[7:4] == 4'b0111) ? CNT_size - 3'd1 : 
                    CNT_size;
//sorting

always @(*) begin
    for(i = 0; i < 6; i = i+1)
        n_CNT[i] = CNT[i];
    for(i = 0; i < 6; i = i+1)
        n_index_value[i] = index_value[i];
    
    if(CNT_size != 3'd0) begin
        for(i = 0; i < 6; i = i+1) begin
            if(i < CNT_size) begin
                if(insert_w[i]) begin
                    n_CNT[i] = insert_value_w[12:6];
                    n_index_value[i] = insert_value_w[5:0];
                end
                else if (sort_w[i]) begin
                    n_CNT[i] = CNT[i-1];
                    n_index_value[i] = index_value[i-1];
                end
            end else if (i == CNT_size && i != 0) begin
                n_CNT[i] = sort_w[i-1] ? CNT[i-1] : insert_value_w[12:6];
                n_index_value[i] = sort_w[i-1] ? index_value[i-1] : insert_value_w[5:0];
            end
        end
    end else begin
        if((sram_a_r < 8'd101 && sram_a_r > 8'd1) || sram_a_r == 8'd128) begin
            for(i = 0; i < 6; i = i+1)n_CNT[i] = sram_q[2:0] == i+1 ? CNT[i] + 7'd1 : CNT[i];
        end
    end
end

//HC and mask generation
always @(*) begin
    for(i = 0; i < 6; i = i+1)n_HC[i] = HC[i];
    for(i = 0; i < 6; i = i+1)n_M[i]  =  M[i];

    if(sram_a_r[7:2] == 6'b011111 || sram_a_r == 8'd134) begin 
        for(i = 0; i < 6; i = i+1)begin
            if(index_value[CNT_size][i] || index_value[CNT_size + 3'd1][i]) n_M[i] = {M[i][3:0], 1'd1};
            if(index_value[CNT_size + 3'd1][i]) begin
                if(M[i][0] ==1) begin
                    n_HC[i][0] = HC[i][0];
                end else begin
                    n_HC[i][0] = 1'b1;
                end
                for(j = 1; j < 5; j = j+1)
                    if(~M[i][j] & M[i][j-1]) begin
                        n_HC[i][j] = 1'b1;
                    end else begin
                        n_HC[i][j] = HC[i][j];
                    end 
            end
        end
    end
end

always @(posedge clk) begin
    if(reset) begin
        sram_a <= 10'h0;
        sram_a_r <= 8'd1;
        sram_d <= 8'd0;
        sram_wen <= 1'd1;
        finish <= 1'd0;

        for (i = 0; i < 6; i = i+1) begin
            CNT[i] <= 7'd0;
            index_value[i] <= 1 << i;
            HC[i] <= 5'd0;
            M[i] <= 5'd0;
        end
        CNT_size <= 3'd0;

    end else begin
        sram_a <= {2'd0, sram_a_r};
        sram_a_r <= sram_a_w;
        sram_d <= sram_d_w;
        sram_wen <= sram_wen_w;
        finish <= finish_w;

        for (i = 0; i < 6; i = i+1) begin
            CNT[i] <= n_CNT[i];
            index_value[i] <= n_index_value[i];
            HC[i] <= n_HC[i];
            M[i] <= n_M[i];
        end
        CNT_size <= CNT_size_w;
    end
end


    
endmodule
