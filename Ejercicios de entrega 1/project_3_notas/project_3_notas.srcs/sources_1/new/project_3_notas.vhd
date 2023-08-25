----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.02.2020 17:20:10
-- Design Name: 
-- Module Name: project_3_notas - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
--use IEEE.std_logic_signed.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY project_3_notas IS

    PORT (
        nota : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        siete_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );

END project_3_notas;

ARCHITECTURE Behavioral OF project_3_notas IS

BEGIN

    enable_seg <= "1110";

    PROCESS (nota)
    BEGIN

        CASE nota IS

            WHEN "0000" => siete_seg <= "0111111";
            WHEN "0001" => siete_seg <= "0111111";
            WHEN "0010" => siete_seg <= "0111111";
            WHEN "0011" => siete_seg <= "0111111";
            WHEN "0100" => siete_seg <= "0111111";
            WHEN "0101" => siete_seg <= "1111110";
            WHEN "0110" => siete_seg <= "1111100";
            WHEN "0111" => siete_seg <= "1111000";
            WHEN "1000" => siete_seg <= "1111000";
            WHEN "1001" => siete_seg <= "1110000";
            WHEN "1010" => siete_seg <= "1000000";
            WHEN OTHERS => siete_seg <= "1111111";

        END CASE;

    END PROCESS;

END Behavioral;