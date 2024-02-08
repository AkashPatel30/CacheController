library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CacheController is
    Port ( clk 	      : in  STD_LOGIC;
			address 	  		: out  STD_LOGIC_VECTOR(15 downto 0); 	-- WORD REGISTER
			DOUT 	  			: out  STD_LOGIC_VECTOR(7 downto 0);	-- actual data from output
																					-- address
			sramAddress    : out  STD_LOGIC_VECTOR(7 downto 0);	-- address in cache memory
			sramDin     	: out  STD_LOGIC_VECTOR(7 downto 0);	-- 
			sramDout    	: out  STD_LOGIC_VECTOR(7 downto 0);	-- data from cache memory
			sdramAddress  	: out  STD_LOGIC_VECTOR(15 downto 0);	-- address in main memory
			sdramDin   		: out  STD_LOGIC_VECTOR(7 downto 0);	-- 
			sdramDout  		: out  STD_LOGIC_VECTOR(7 downto 0);	-- data from main memory
			cacheAddr 		: out  STD_LOGIC_VECTOR(7 downto 0);	-- 
            WR_RD, MEMSTRB, RDY ,CS	: out  STD_LOGIC);
end CacheController;

architecture Behavioral of CacheController is
-- CPU Signals
	signal CPU_Dout, CPU_Din		: STD_LOGIC_VECTOR(7 downto 0);
	signal CPU_ADD 					: STD_LOGIC_VECTOR (15 downto 0);
	signal CPU_W_R,CPU_CS 			: STD_LOGIC;
	signal CPU_RDY						: STD_LOGIC;
	signal cpu_tag				      : STD_LOGIC_VECTOR(7 downto 0);
	signal index				      : STD_LOGIC_VECTOR(2 downto 0);
	signal offset		           	: STD_LOGIC_VECTOR(4 downto 0);
	signal Tag_index					: STD_LOGIC_VECTOR(10 downto 0);
	
-- SRAM(cache memory) Signals
	signal dirtyBit									: STD_LOGIC_VECTOR(7 downto 0):= "00000000";
	signal validBit									: STD_LOGIC_VECTOR(7 downto 0):= "00000000";
	signal SRAM_ADD, SRAM_Din, SRAM_Dout 		: STD_LOGIC_VECTOR(7 downto 0);
	signal SRAM_Wen									: STD_LOGIC_VECTOR(0 DOWNTO 0);
	signal TAGWen										: STD_LOGIC := '0';
	
-- SDRAM Signals
	signal SDRAM_Din,SDRAM_Dout	: STD_LOGIC_VECTOR(7 downto 0);
	signal SDRAM_ADD					: STD_LOGIC_VECTOR(15 downto 0);
	signal SDRAM_MSTRB,SDRAM_W_R	: STD_LOGIC;
	signal counter						: integer := 0;
	signal SDRAM_Offset				: integer := 0;

-- SRAM array
-- all cache values will be stored in an array so that it's
-- easier to pull the data necessary
type cachememory is array (7 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
		signal cacheTag: cachememory := ((others=> (others=>'0')));

-- ICON & VIO  & ILA Signals 
	signal control0 : STD_LOGIC_VECTOR(35 downto 0);
	signal ila_data : std_logic_vector(99 downto 0);
	signal trig0 	: std_logic_vector(0 TO 0);

--State Signals
	--COMPARE TAG	--0000 : state0
	--ALLOCATE 		--0001 : state1
	--WRITE BACK	--0010 : state2
	--IDLE			--0011 : state3
	--READY 			--0100 : state4
	TYPE state_value IS (state4, state0, state1, state2, state3);
	signal state_current			: state_value ;
	signal state 					: STD_LOGIC_VECTOR(3 downto 0);
	
--Components
	COMPONENT BlockRAM 
    Port ( 
		clk							: in  STD_LOGIC;
		address						: in  STD_LOGIC_VECTOR (15 downto 0);
      WR_RD 						: in  STD_LOGIC;
      MEMSTRB 						: in  STD_LOGIC;
      DIN 							: in  STD_LOGIC_VECTOR (7 downto 0);
      DOUT 							: out STD_LOGIC_VECTOR (7 downto 0));
	END COMPONENT;
	
	COMPONENT SRAM
	PORT (
    clka 						: IN STD_LOGIC;
    wea 							: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra 						: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dina 						: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta 						: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT CPU_gen 
	Port ( 
		clk 							: in  STD_LOGIC;
      rst 							: in  STD_LOGIC;
      trig 							: in  STD_LOGIC;
      Address 						: out STD_LOGIC_VECTOR (15 downto 0);
      wr_rd 						: out STD_LOGIC;
      cs 							: out STD_LOGIC;
      Dout 							: out STD_LOGIC_VECTOR (7 downto 0));
	END COMPONENT;	
	
	COMPONENT icon
	PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT ila
	PORT (
    CONTROL 							: INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK 									: IN STD_LOGIC;
    DATA 								: IN STD_LOGIC_VECTOR(99 DOWNTO 0);
    TRIG0 								: IN STD_LOGIC_VECTOR(0 TO 0));
	END COMPONENT;

BEGIN
--PORT MAPS:
	myCPU_gen 							: CPU_gen			Port Map (clk,'0',CPU_RDY,CPU_ADD,CPU_W_R,CPU_CS,CPU_Dout);
	SDRAM 								: BlockRAM			Port Map (clk,SDRAM_ADD,SDRAM_W_R,SDRAM_MSTRB,SDRAM_Din,SDRAM_Dout);
	mySRAM 								: SRAM				Port Map (clk,SRAM_Wen,SRAM_ADD, SRAM_Din, SRAM_Dout);
	myIcon 								: icon 				Port Map (CONTROL0);
	myILA 								: ila					Port Map (CONTROL0,CLK,ila_data, TRIG0);
	
process(clk, CPU_CS)
	begin
		if (clk'event AND clk = '1') then -- if clock is synchronized
		
			----------------------------------
			--No current process - READY STATE
			----------------------------------
			if (state_current = state4) then --state4 == ready state
				CPU_RDY 	<= '0'; -- no longer ready
				--WORD REGISTER
				--------------------------------------------
				--tag-8bits||index-3bits||blockOffset-5bits--
				--------------------------------------------
				cpu_tag 	<= CPU_ADD(15 downto 8); -- set tag
				index		<= CPU_ADD(7  downto 5); -- set index
				offset		<= CPU_ADD(4  downto 0); -- set offset
				----------------------------------------------
				--WORD REGISTER (TAG + INDEX)
				SDRAM_ADD(15 downto 5) 	<= CPU_ADD(15 downto 5);
				----------------------------------------------
				--WORD REGISTER (INDEX + OFFSET)
				SRAM_ADD(7 downto 0)  	<= CPU_ADD(7 downto 0);
				----------------------------------------------
				SRAM_Wen <= "0"; 

				-- HIT VS MISS
				if(validBit(to_integer(unsigned(index))) = '1' 	-- if valid bit == 1 at the index
																				-- given by the cpu
					AND cacheTag(to_integer(unsigned(index))) = cpu_tag) then -- and the tag matches then hit 
					TAGWen <= '1'; -- no need to write to tag; data was a hit
					state_current 	<= state0; -- COMPARE TAG
					state 		<= "0000";
				else --miss
					TAGWen <= '0'; -- enable writing to the tag
					--Dirty and Valid bit check
					if (dirtyBit(to_integer(unsigned(index))) = '1' -- if the dirty bit is 1
						AND validBit(to_integer(unsigned(index))) = '1') then -- and valid bit is 1
						-- if the dirty bit is 1, and the valid bit is 1, then data has already been
						-- written there, but it is not what is needed.
						-- write to main memory, then to cache memory
						state_current 	<= state2; -- WRITE BACK
						state 		<= "0010";
					else -- old block is clean, no need to empty, skip write back state
						state_current	<= state1; -- ALLOCATE
						state			<= "0001";
					end if;
				end if;
				
			--------------------------------------
			-- COMPARE TAG STATE
			--------------------------------------
			elsif(state_current = state0) then
				if (CPU_W_R = '1') then -- if it is a hit
					SRAM_Wen <= "1"; --SRAM write enable
					dirtyBit(to_integer(unsigned(index))) <= '1'; --set dirty bit to 1
					validBit(to_integer(unsigned(index))) <= '1'; --set valid bit to 1
					SRAM_Din <= CPU_Dout; -- write to cache memory
					CPU_Din <= "00000000"; -- clear memory slot
					
				else 
					CPU_Din <= SRAM_Dout; -- if already empty do nothing
				end if;
				
				state_current <= state3; --Switching to idle state as request is completed
				state <= "0011";
				
			--------------------------------------------
			--loading from main memory -- ALLOCATE STATE
			--------------------------------------------
			elsif(state_current = state1) then 
				if (counter = 64) then 
				-- counter = 64 because data will only be written at every other index
				-- or 32 times total. Our block offset is 5 bits long -- 2^5 = 32, meaning
				-- each block contains 32 bits of data. This loop of 32 will allow us to write
				-- each bit from cache memory to main memory
					counter <= 0;
					validBit(to_integer(unsigned(index))) <= '1'; -- set valid bit to 1
					cacheTag(to_integer(unsigned(index))) <= cpu_tag; -- set tag in cache
					SDRAM_Offset <= 0; -- set offset to 0
					state_current <= state0; -- set current state to compare tag
					state <= "0000"; -- Return to compare state
				else -- for counter 0 to 63
					if (counter mod 2 = 1) then -- if the counter is an odd number
						SDRAM_MSTRB <= '0'; -- SDRAM 
					else -- cycle through 32 times to add entire block to cache
						-- set the block offset for main memory
						SDRAM_ADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_Offset, offset'length));
						SDRAM_W_R <= '0';
						SDRAM_MSTRB <= '1';
						-- set the index for cache memory to the current address given by the cpu
						SRAM_ADD(7 downto 5) <= index; -- set current address for cache memory to the index
						-- set the block offset for cache memory to the current offset
						SRAM_ADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_Offset, offset'length)); 	-- write the data to the block
						-- write the data from the main memory to the cache memory based on the current offset																			-- in the cache memory
						SRAM_Din <= SDRAM_Dout; -- Write data
						SRAM_Wen <= "1";
						SDRAM_Offset <= SDRAM_Offset + 1; -- move to next bit in the block
					end if;
					counter <= counter + 1; 
				end if;		
				
			----------------------------------------------------------------------------
			-- writing back to main memory as valid or dirty bit is 1 - WRITE BACK STATE
			----------------------------------------------------------------------------
			elsif(state_current = state2) then -- WRITE BACK
			if (counter = 64) then 
			
			-- counter = 64 because data will only be written at every other index
			-- or 32 times total. Our block offset is 5 bits long -- 2^5 = 32, meaning
			-- each block contains 32 bits of data. This loop of 32 will allow us to write
			-- each bit from cache memory to main memory
					counter <= 0; -- reset the counter to 0
					dirtyBit(to_integer(unsigned(index))) <= '0'; -- dirty bit at the index 
					SDRAM_Offset <= 0;
					state_current <= state1; -- ALLOCATE STATE
					state <= "0001";
				else
					if (counter mod 2 = 1) then
						-- if the SDRAM_MSTRB is set to '0', the ram will read from the
						-- selected location. If it is set to '1', it will then write from
						-- that selected location to DOUT.
						SDRAM_MSTRB <= '0';
					else
						-- set block offset in main memory
						SDRAM_ADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_Offset, offset'length));
						SDRAM_W_R <= '1';
						-- set index in cache memory
						SRAM_ADD(7 downto 5) <= index;
						-- set block offset in cache memory
						SRAM_ADD(4 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(SDRAM_Offset, offset'length));
						SRAM_Wen <= "0";
						-- write each bit of data from cache memory to main memory
						SDRAM_Din <= SRAM_Dout;
						SDRAM_MSTRB <= '1';
						-- increase offset
						SDRAM_Offset <= SDRAM_Offset + 1;
					end if;
					counter <= counter + 1;
				end if;
				
			-----------------------------
			-- IDLE STATE
			-----------------------------
			elsif(state_current = state3) then
				CPU_RDY <= '1'; -- MARK CPU AS READY
				-- ONLY NEEDED FOR MULTIPLE SRAM INSTANCES
				if (CPU_CS = '1') then -- IF CPU CHIP SELECTOR == '1'
					state_current <= state4; -- SET TO READY STATE
					state <= "0100";
				-----------------------------
				end if;
			end if;
			-----------------------------
		end if;	
end process;


	-- all below mapping is done for testing purposes
	-- and for visualizing data output.
	
	MEMSTRB <= SDRAM_MSTRB;
	address	<= CPU_ADD;
	WR_RD <= CPU_W_R;
	DOUT	<= CPU_Din;
	RDY	<= CPU_RDY;
	CS 	<= CPU_CS;
	
	sramAddress <= SRAM_ADD;
	sramDin <= SRAM_Din;
	sramDout <= SRAM_Dout;
	
	sdramAddress <= SDRAM_ADD;
	sdramDin <= SDRAM_Din;
	sdramDout <= SDRAM_Dout;
	
	cacheAddr <= CPU_ADD(15 downto 8);
	
-- MAP THE ILA PORTS
	ila_data(15 downto 0) <= CPU_ADD;
	ila_data(16) <= CPU_W_R;
	ila_data(17) <= CPU_RDY;
	ila_data(18) <= SDRAM_MSTRB;
	ila_data(26 downto 19) <= CPU_Din;
	ila_data(30 downto 27) <= state;
	ila_data(31) <= CPU_CS;
	ila_data(32) <= validBit(to_integer(unsigned(index)));
	ila_data(33) <= dirtyBit(to_integer(unsigned(index)));
	ila_data(34) <= TAGWen;
	ila_data(42 downto 35) <= SRAM_ADD;
	ila_data(50 downto 43) <= SRAM_Din;
	ila_data(58 downto 51) <= SRAM_Dout;
	ila_data(74 downto 59) <= SDRAM_ADD;
	ila_data(82 downto 75) <= SDRAM_Din;
	ila_data(90 downto 83) <= SDRAM_Dout;
	ila_data(98 downto 91) <= CPU_ADD(15 downto 8);

end Behavioral;