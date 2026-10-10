

module sync_fifo (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       wr_en,
    input  logic       rd_en,
    input  logic [7:0] wdata,

    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

    logic [7:0] mem [0:15];
    logic [3:0] wr_ptr;
    logic [3:0] rd_ptr;
    logic [4:0] count;

    logic wr_accept;
    logic rd_accept;

    assign full      = (count == 5'd16);
    assign empty     = (count == 5'd0);
    assign wr_accept = wr_en && !full;
    assign rd_accept = rd_en && !empty;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
            count  <= 5'd0;
            rdata  <= 8'd0;
        end else begin
            
            if (wr_accept) begin
                mem[wr_ptr] <= wdata;
                wr_ptr      <= wr_ptr + 4'd1;
            end

            if (rd_accept) begin
                rdata  <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 4'd1;
            end

            
            case ({wr_accept, rd_accept})
                2'b10:   count <= count + 5'd1;
                2'b01:   count <= count - 5'd1;
                default: count <= count;
            endcase
        end
    end

endmodule
