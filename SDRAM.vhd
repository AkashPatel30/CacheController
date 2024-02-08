library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BlockRAM is
    Port ( 
			  clk			: in STD_LOGIC;
			  address 		: in  STD_LOGIC_VECTOR (15 downto 0);
           WR_RD 		: in  STD_LOGIC;
           MEMSTRB 		: in  STD_LOGIC;
           DIN 		: in  STD_LOGIC_VECTOR (7 downto 0);
           DOUT 		: out  STD_LOGIC_VECTOR (7 downto 0));
end BlockRAM;

architecture Behavioral of BlockRAM is
    type ramemory is array (7 downto 0, 31 downto 0) of std_logic_vector(7 downto 0);
    signal RAM_SIG: ramemory;
	 
	signal counter : integer := 0;
begin

process (CLK)
    begin
        if CLK'event and CLK = '1' then -- if clock synchronized
            
				-- loop for initialization
				if counter = 0 then
					for I in 0 to 7 loop
						for J in 0 to 31 loop
							RAM_SIG(i,j) <= "11110000"; -- initialize all values to 11110000
						end loop;
					end loop;
					counter <= 1;	
				end if;
				
				if MEMSTRB = '1' then
					if WR_RD = '1' then
						-- Read the requested data location from DIN
						RAM_SIG(to_integer(unsigned(address(7 downto 5))),to_integer(unsigned(address(4 downto 0)))) <= DIN;    
               ELSE
						-- write the requested data location to DOUT
						DOUT <= RAM_SIG(to_integer(unsigned(address(7 downto 5))),to_integer(unsigned(address(4 downto 0))));
					end if;
				end if;
        end if;
    end process;


end Behavioral;