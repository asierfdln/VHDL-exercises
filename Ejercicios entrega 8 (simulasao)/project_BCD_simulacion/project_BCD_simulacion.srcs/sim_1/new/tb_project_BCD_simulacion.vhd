LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_bin_bcd IS
END tb_bin_bcd; -- se declara una simulacion con ese nombre
 
ARCHITECTURE behavior OF tb_bin_bcd IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT project_bcd_simulacion --declaro lo que quiero simular
    PORT(
        clk: in std_logic;
        btnC: in std_logic;
        binario: in std_logic_vector (3 downto 0);
        btnU: in std_logic;
        led: out std_logic_vector (11 downto 0);
        an: out std_logic_vector (3 downto 0);
        seg: out std_logic_vector (6 downto 0)
        );
    END COMPONENT;
    --hay que declarar a mano inputs y outputs
 
   --Inputs
   signal clk : std_logic := '0';
   signal btnC : std_logic := '0';
   signal binario : std_logic_vector(3 downto 0) := (others => '0');
   signal btnU : std_logic :='0';

 	--Outputs
   signal seg : std_logic_vector(6 downto 0);
   signal an : std_logic_vector(3 downto 0);
   signal led : std_logic_vector (11 downto 0);
    
   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: project_bcd_simulacion PORT MAP (
          clk => clk,
          btnC => btnC,
          btnU => btnU,
          binario => binario,
          an => an,
          seg => seg,
          led =>led
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
     btnC <= '1', '0' after 30 ns;
     btnU<='1';		
     binario <= "0000";
     wait for 200 ns;
     binario <= "0111";
     wait for 200 ns;
     binario <= "1111";
     wait for 200 ns;
     binario <= "1001";
     wait for 200 ns;
     binario <= "1101";
     wait for 200 ns;
     binario <= "0000";
     wait for 200 ns;

      wait;
   end process;

END;
