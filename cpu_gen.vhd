LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
ENTITY CPU_gen IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        trig : IN STD_LOGIC;
        -- Interface to the Cache Controller.
        Address : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        wr_rd : OUT STD_LOGIC;
        cs : OUT STD_LOGIC;
        DOut : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END CPU_gen; 
architecture Behavioral of cpu_gen is
	-- Pattern storage and control.
	signal patOut : std_logic_vector(24 downto 0);
	signal patCtrl : std_logic_vector(2 downto 0) := "111";
	signal updPat : std_logic;
	-- Main control.
	signal st1 : std_logic_vector(2 downto 0) := "000";
	signal st1N : std_logic_vector(2 downto 0);
	-- Rising edge detection.
	signal rReg1, rReg2 : std_logic;
	signal trig_r : std_logic;
begin
	--------------------------------------------------------------------------
	-- Main control FSM.
	--------------------------------------------------------------------------
	-- State storage.
	process(clk, rst, st1N)
	begin
		if(rst = '1')then
			st1 <= "000";
		else
			if(clk'event and clk = '1')then
				st1 <= st1N;
			end if;
		end if;
	end process;
	-- Next state generation.
	process(st1, trig_r)
	begin
		if(ieee.std_logic_unsigned."=" (st1, "000") )then
		-- if(st1 = "000")then
			if(trig_r = '1')then
				st1N <= "001";
			else
				st1N <= "000";
			end if;
		elsif(ieee.std_logic_unsigned."=" (st1, "001"))then
		-- elsif(st1 = "001")then
			st1N <= "010";
		elsif(ieee.std_logic_unsigned."=" (st1, "010"))then
			-- elsif(st1 = "010")then
			st1N <= "011";
		elsif(ieee.std_logic_unsigned."=" (st1, "011"))then
		-- elsif(st1 = "011")then
			st1N <= "100";
		elsif(ieee.std_logic_unsigned."=" (st1, "100"))then
		-- elsif(st1 = "100")then
			st1N <= "101";
		elsif(ieee.std_logic_unsigned."=" (st1, "101"))then
		-- elsif(st1 = "101")then
			st1N <= "000";
		else
			st1N <= "000";
		end if;
	end process;
	
	-- Output generation.
	process(st1)
	begin
		
		if(ieee.std_logic_unsigned."=" (st1, "000"))then
		-- if(st1 = "000")then
			updPat <= '0';
			cs <= '0';
		elsif(ieee.std_logic_unsigned."=" (st1, "001"))then
		-- elsif(st1 = "001")then
			updPat <= '1';
			cs <= '0';
		elsif(ieee.std_logic_unsigned."=" (st1, "010"))then
		-- elsif(st1 = "010")then
			updPat <= '0';
			cs <= '1';
		elsif(ieee.std_logic_unsigned."=" (st1, "011"))then
		-- elsif(st1 = "011")then
			updPat <= '0';
			cs <= '1';
		elsif(ieee.std_logic_unsigned."=" (st1, "100"))then
		-- elsif(st1 = "100")then
			updPat <= '0';
			cs <= '1';
		elsif(ieee.std_logic_unsigned."=" (st1, "101"))then
		-- elsif(st1 = "101")then
			updPat <= '0';
			cs <= '1';
		else
		end if;
	end process;
	--------------------------------------------------------------------------
	-- Pattern generator and control circuit.
	 
	-- Generator control circuit.
	process(clk, rst, updPat, patCtrl)
	begin
		if(rst = '1')then
			patCtrl <= "111";
		else
			if(clk'event and clk = '1')then
				if(updPat = '1')then
					patCtrl <= patCtrl + "001";
				else
					patCtrl <= patCtrl;
				end if;
			end if;
		end if;
	end process;
	
	-- Pattern storage.
	process(patCtrl)
	begin
		if(ieee.std_logic_unsigned."=" (patCtrl, "000"))then
		-- if(patCtrl = "000")then
			patOut <= "0001000100000000101010101";
		elsif(ieee.std_logic_unsigned."=" (patCtrl, "001"))then
		-- elsif(PatCtrl = "001")then
			patOut <= "0001000100000010101110111";
		elsif(ieee.std_logic_unsigned."=" (patCtrl, "010"))then
		-- elsif(PatCtrl = "010")then
			patOut <= "0001000100000000000000000";
		elsif(ieee.std_logic_unsigned."=" (patCtrl, "011"))then
		-- elsif(PatCtrl = "011")then
			patOut <= "0001000100000010000000000";
		elsif(ieee.std_logic_unsigned."=" (patCtrl, "100"))then
		-- elsif(PatCtrl = "100")then
			patOut <= "0011001101000110000000000";
		elsif(ieee.std_logic_unsigned."=" (patCtrl, "101"))then
		-- elsif(PatCtrl = "101")then
			patOut <= "0100010001000100000000000";
		elsif(ieee.std_logic_unsigned."=" (patCtrl, "110"))then
		-- elsif(PatCtrl = "110")then
			patOut <= "0101010100000100110011001";
		else
			patOut <= "0110011000000110000000000";
		end if;
	end process;
	--------------------------------------------------------------------------
	-- Rising edge detector.
	--------------------------------------------------------------------------
	-- Register 1
	process(clk, trig)
	begin
		if(clk'event and clk = '1')then
			rReg1 <= trig;
		end if;
	end process;
	
	-- Register 2
	process(clk, rReg1)
	begin
		if(clk'event and clk = '1')then
			rReg2 <= rReg1;
		end if;
	end process;
	trig_r <= rReg1 and (not rReg2);
	--------------------------------------------------------------------------
	-- Output connections.
	--------------------------------------------------------------------------
	
	-- Output mapping:
	-- Address [24 .. 9]
	-- Data [8 .. 1]
	-- Wr/Rd [0]
	
	Address(15 downto 0) <= patOut(24 downto 9);
	DOut(7 downto 0) <= patOut(8 downto 1);
	wr_rd <= patOut(0);


end Behavioral;