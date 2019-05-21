module ARM_MultiCycle_Memory
	#(parameter	BusWidth	= 32,
				MemSize		= 128)
	(input logic					i_CLK, i_NRESET,
	input logic						i_WriteEnable,
	input logic[(BusWidth - 1):0]	i_Address,
	input logic[(BusWidth - 1):0]	i_WriteData,
	output logic[(BusWidth - 1):0]	o_ReadData);

	//int	i;
	//	Memory array
	logic[(BusWidth - 1):0]			s_ReadData;
	logic[(BusWidth - 1):0]			s_MemoryArray[(MemSize - 1):0];


	//initial		$readmemh("ARM_Program.dat", s_MemoryArray);

	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)
		begin
			int	i;
			for (i = 0; i < MemSize; i = i + 1)		s_MemoryArray[i] <= 32'd0;
		end
		else if (i_WriteEnable)
		begin
				s_MemoryArray[i_Address[31:2]] <= i_WriteData;
		end
		//else	o_ReadData = s_MemoryArray[i_Address[31:2]];
	end

	always_comb
	begin
		case (i_Address)
			32'd0:	s_ReadData = 32'hE04F000F;
			32'd4:	s_ReadData = 32'hE2802005;
			32'd8:	s_ReadData = 32'hE280300C;
			32'd12:	s_ReadData = 32'hE2437009;
			32'd16:	s_ReadData = 32'hE1874002;
			32'd20:	s_ReadData = 32'hE0035004;
			32'd24:	s_ReadData = 32'hE0855004;
			32'd28:	s_ReadData = 32'hE0558007;
			32'd32:	s_ReadData = 32'h0A00000C;
			32'd36:	s_ReadData = 32'hE0538004;
			32'd40:	s_ReadData = 32'hAA000000;
			32'd44:	s_ReadData = 32'hE2805000;
			32'd48:	s_ReadData = 32'hE0578002;
			32'd52:	s_ReadData = 32'hB2857001;
			32'd56:	s_ReadData = 32'hE0477002;
			32'd60:	s_ReadData = 32'hE5837054;
			32'd64:	s_ReadData = 32'hE5902060;
			32'd68:	s_ReadData = 32'hE08FF000;
			32'd72:	s_ReadData = 32'hE280200E;
			32'd76:	s_ReadData = 32'hEA000001;
			32'd80:	s_ReadData = 32'hE280200D;
			32'd84:	s_ReadData = 32'hE280200A;
			32'd88:	s_ReadData = 32'hE5802064;

			default:	s_ReadData = s_MemoryArray[i_Address[31:2]];
		endcase
	end

	assign o_ReadData = s_ReadData;
	//assign o_ReadData = s_MemoryArray[i_Address[31:2]];

endmodule
