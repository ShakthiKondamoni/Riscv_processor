`timescale 1ns/1ps

`timescale 1ns/1ps

module riscv_processor #(
    parameter RESET_ADDR = 32'h00000000,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input reset,

    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata,
    output reg [3:0]  mem_wmask,
    input      [31:0] mem_rdata,
    output reg        mem_rstrb,
    input             mem_rbusy,
    input             mem_wbusy
);

    
    reg [31:0] program_counter;
    reg [31:0] register [0:31]; 
    integer i;

    reg [31:0] instruction; 
    reg [2:0]  state;

   
    localparam S_fetch_wait     = 3'd0;
    localparam S_execute        = 3'd1;
    localparam S_mem_read_wait  = 3'd2;
    localparam S_mem_wb         = 3'd3;
    localparam S_mem_write_wait = 3'd4;

    
    wire [31:0] current_instr = (state == S_execute) ? mem_rdata : instruction; 

    wire [6:0] opcode = current_instr[6:0];
    wire [2:0] funct3 = current_instr[14:12];
    wire [6:0] funct7 = current_instr[31:25];

    wire [4:0] rd  = current_instr[11:7];
    wire [4:0] rs1 = current_instr[19:15];
    wire [4:0] rs2 = current_instr[24:20];

    wire [31:0] rv1 = register[rs1]; 
    wire [31:0] rv2 = register[rs2]; 

    
    wire [31:0] imm_I = {{20{current_instr[31]}}, current_instr[31:20]};
    wire [31:0] imm_S = {{20{current_instr[31]}}, current_instr[31:25], current_instr[11:7]};
    wire [31:0] imm_B = {{19{current_instr[31]}}, current_instr[31], current_instr[7],
                         current_instr[30:25], current_instr[11:8], 1'b0};
    wire [31:0] imm_U = {current_instr[31:12], 12'b0};
    wire [31:0] imm_J = {{11{current_instr[31]}}, current_instr[31],
                         current_instr[19:12], current_instr[20],
                         current_instr[30:21], 1'b0};

    
    reg [31:0] alu_out;

    always @(*) begin
        alu_out = 32'b0;

        case (opcode)

            
            7'b0110011: begin
                case (funct3)
                     3'b000: alu_out = (funct7 == 7'b0100000) ? (rv1 - rv2) : (rv1 + rv2);
                    3'b001: alu_out = rv1 << rv2[4:0];
                      3'b010: alu_out = ($signed(rv1) < $signed(rv2)) ? 32'd1 : 32'd0;
                    3'b011: alu_out = (rv1 < rv2) ? 32'd1 : 32'd0;
                     3'b100: alu_out = rv1 ^ rv2;

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_out = $signed(rv1) >>> rv2[4:0]; 
                         else
                            alu_out = rv1 >> rv2[4:0];          
                    end

                     3'b110: alu_out = rv1 | rv2;
                    3'b111: alu_out = rv1 & rv2;
                 endcase
            end

           
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_out = rv1 + imm_I;
                     3'b001: alu_out = rv1 << current_instr[24:20];
                     3'b010: alu_out = ($signed(rv1) < $signed(imm_I)) ? 32'd1 : 32'd0;
                    3'b011: alu_out = (rv1 < imm_I) ? 32'd1 : 32'd0;
                     3'b100: alu_out = rv1 ^ imm_I;

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                             alu_out = $signed(rv1) >>> current_instr[24:20]; 
                        else
                              alu_out = rv1 >> current_instr[24:20];          
                    end

                     3'b110: alu_out = rv1 | imm_I;
                    3'b111: alu_out = rv1 & imm_I;
                endcase
            end

            
             7'b0000011: alu_out = rv1 + imm_I;
             7'b0100011: alu_out = rv1 + imm_S;
             7'b1100011: alu_out = program_counter + imm_B;
            7'b0110111: alu_out = imm_U;
            7'b0010111: alu_out = program_counter + imm_U;
            7'b1101111: alu_out = program_counter + imm_J;
            7'b1100111: alu_out = (rv1 + imm_I) & ~32'h1;
        endcase
    end

    
    reg take_branch;

    always @(*) begin
        take_branch = 0;

        if (opcode == 7'b1100011) begin
            case (funct3)
                3'b000: take_branch = (rv1 == rv2);
                3'b001: take_branch = (rv1 != rv2);
                3'b100: take_branch = ($signed(rv1) < $signed(rv2));
                3'b101: take_branch = ($signed(rv1) >= $signed(rv2));
                3'b110: take_branch = (rv1 < rv2);
                3'b111: take_branch = (rv1 >= rv2);
            endcase
        end
    end

    
    wire [1:0] load_offset = mem_addr[1:0];


    wire [7:0] load_byte = (load_offset == 2'b00) ? mem_rdata[7:0] :
                           (load_offset == 2'b01) ? mem_rdata[15:8] :
                           (load_offset == 2'b10) ? mem_rdata[23:16] :
                                                    mem_rdata[31:24];

    wire [15:0] load_half = (load_offset[1] == 0) ? mem_rdata[15:0] : mem_rdata[31:16];

    
    always @(posedge clk) begin

        if (!reset) begin
            program_counter <= RESET_ADDR;
             mem_addr <= RESET_ADDR;
             mem_rstrb <= 1;
             mem_wmask <= 0;
             state <= S_fetch_wait;

             for (i=0;i<32;i=i+1) register[i] <= 0; 

        end else begin
            case (state)

                S_fetch_wait: begin
                    if (!mem_rbusy) begin
                        mem_rstrb <= 0;
                        state <= S_execute;
                    end
                end

                 S_execute: begin
                    instruction <= mem_rdata; 
                      if (opcode == 7'b0000011) begin
                         mem_addr <= alu_out;
                         mem_rstrb <= 1;
                        state <= S_mem_read_wait;
                    end

                     else if (opcode == 7'b0100011) begin
                        mem_addr <= alu_out;

                         case (funct3)
                            3'b000: begin // SB
                                mem_wmask <= 4'b0001 << alu_out[1:0];
                                mem_wdata <= rv2 << (8 * alu_out[1:0]);
                            end
                            3'b001: begin // SH
                                mem_wmask <= alu_out[1] ? 4'b1100 : 4'b0011;
                                mem_wdata <= rv2 << (16 * alu_out[1]);
                            end
                            3'b010: begin // SW
                                mem_wmask <= 4'b1111;
                                mem_wdata <= rv2;
                            end
                        endcase

                        state <= S_mem_write_wait;
                    end

                    else begin
                        if (opcode == 7'b1100011) begin
                            program_counter <= take_branch ? alu_out : program_counter + 4;
                            mem_addr <= take_branch ? alu_out : program_counter + 4;
                        end
                          else if (opcode == 7'b1101111 || opcode == 7'b1100111) begin
                            if (rd != 0) register[rd] <= program_counter + 4; 
                            program_counter <= alu_out;
                            mem_addr <= alu_out;
                        end
                        else begin
                             if (rd != 0) register[rd] <= alu_out; 
                            program_counter <= program_counter + 4;
                             mem_addr <= program_counter + 4;
                        end

                        mem_rstrb <= 1;
                         state <= S_fetch_wait;
                    end
                end

                S_mem_read_wait: begin
                    if (!mem_rbusy) begin
                         mem_rstrb <= 0;
                        state <= S_mem_wb;
                    end
                end

                S_mem_wb: begin
                    if (rd != 0) begin
                        case (funct3)
                            3'b000: register[rd] <= {{24{load_byte[7]}}, load_byte}; 
                            3'b001: register[rd] <= {{16{load_half[15]}}, load_half}; 
                            3'b010: register[rd] <= mem_rdata; 
                            3'b100: register[rd] <= {24'b0, load_byte}; 
                            3'b101: register[rd] <= {16'b0, load_half}; 
                        endcase
                    end

                    program_counter <= program_counter + 4;
                    mem_addr <= program_counter + 4;
                    mem_rstrb <= 1;
                    state <= S_fetch_wait;
                end

                S_mem_write_wait: begin
                    if (!mem_wbusy) begin
                        mem_wmask <= 0;
                        program_counter <= program_counter + 4;
                        mem_addr <= program_counter + 4;
                        mem_rstrb <= 1;
                        state <= S_fetch_wait;
                    end
                end
            endcase

            register[0] <= 0; 
        end
    end

endmodule