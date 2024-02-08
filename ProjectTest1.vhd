LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TEST IS
END TEST;
 
ARCHITECTURE behavior OF TEST IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT CacheController
    PORT(
         clk : IN  std_logic;
         address : OUT  std_logic_vector(15 downto 0);
         DOUT : OUT  std_logic_vector(7 downto 0);
         --STATE: OUT STD_LOGIC_VECTOR(3 downto 0);
			WR_RD : OUT  std_logic;
         MEMSTRB : OUT  std_logic;
         RDY : OUT  std_logic;
			CS		:OUT STD_LOGIC
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';

 	--Outputs
   signal address: std_logic_vector(15 downto 0);
   signal DOUT : std_logic_vector(7 downto 0);
   signal WR_RD : std_logic;
	--signal STATE: STD_LOGIC_VECTOR(3 downto 0);
   signal MEMSTRB : std_logic;
   signal RDY : std_logic;
	signal CS	:Std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: CacheController PORT MAP (
          clk => clk,
          address=> address,
          DOUT => DOUT,
          WR_RD => WR_RD,
			 --STATE => STATE,
          MEMSTRB => MEMSTRB,
          RDY => RDY,
			 CS	=> CS
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
     

      -- insert stimulus here 

      wait;
   end process;

END;