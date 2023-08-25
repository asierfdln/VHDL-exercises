----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.02.2020 11:44:50
-- Design Name: 
-- Module Name: project_2_diamante - Behavioral
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

ENTITY project_2_diamante IS

    PORT (
        sensor_bajo : IN STD_LOGIC;
        sensor_medio : IN STD_LOGIC;
        sensor_alto : IN STD_LOGIC;
        sensor_peso : IN STD_LOGIC;
        salida_bajo : OUT STD_LOGIC;
        salida_medio : OUT STD_LOGIC;
        salida_alto : OUT STD_LOGIC;
        salida_rechazado : OUT STD_LOGIC;
        salida_error : OUT STD_LOGIC;
        siete_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );

END project_2_diamante;

ARCHITECTURE Behavioral OF project_2_diamante IS

    SIGNAL sensores : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL flags : STD_LOGIC_VECTOR (4 DOWNTO 0); -- (0) baj (1) med (2) alt (3) rech (4) err

BEGIN

    enable_seg <= "1110";

    -- procesamos entradas
    sensores <= sensor_peso & sensor_alto & sensor_medio & sensor_bajo;

    PROCESS (sensores)
    BEGIN
        CASE sensores IS
                -- bajo
            WHEN "0110" => flags <= "00001";
                -- medio
            WHEN "1100" => flags <= "00010";
                -- alto
            WHEN "1000" => flags <= "00100";
                -- rechazado
            WHEN "1110" | "1111" | "0111" | "0000" | "0100" => flags <= "01000";
                -- error
            WHEN OTHERS => flags <= "10000";
        END CASE;
    END PROCESS;

    -- procesamos salidas
    salida_bajo <= flags(0);
    salida_medio <= flags(1);
    salida_alto <= flags(2);
    salida_rechazado <= flags(3);
    salida_error <= flags(4);

    PROCESS (flags)
    BEGIN
        CASE flags IS
                -- bajo
            WHEN "00001" => siete_seg <= "0001100";
                -- medio
            WHEN "00010" => siete_seg <= "0001001";
                -- alto
            WHEN "00100" => siete_seg <= "0000010";
                -- rechazado
            WHEN "01000" => siete_seg <= "0101111";
                -- error
            WHEN "10000" => siete_seg <= "0000110";
            WHEN OTHERS => siete_seg <= "1111111";
        END CASE;
    END PROCESS;

END Behavioral;