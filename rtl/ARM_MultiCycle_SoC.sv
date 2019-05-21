module ARM_MultiCycle_SoC
	#(parameter	BusWidth	= 32)
	(input logic				i_CLK, i_NRESET,
	output logic				o_MemWrite,
	output logic[(BusWidth - 1):0]	o_Address,
	output logic[(BusWidth - 1):0]	o_WriteData, o_ReadData);

	logic[(BusWidth - 1):0]	s_Address, s_WriteData, s_ReadData;
	logic					s_MemWrite;


	ARM_MultiCycle_CPU		CPU
		(i_CLK, i_NRESET,
		s_MemWrite,
		s_Address,
		s_WriteData, s_ReadData);

	ARM_MultiCycle_Memory	InstructionDataMemory	//MainMemory
		(i_CLK, i_NRESET,
		s_MemWrite,
		s_Address,
		s_WriteData, s_ReadData);


	assign o_MemWrite	= s_MemWrite;
	assign o_Address	= s_Address;
	assign o_WriteData	= s_WriteData;
	assign o_ReadData	= s_ReadData;

endmodule
