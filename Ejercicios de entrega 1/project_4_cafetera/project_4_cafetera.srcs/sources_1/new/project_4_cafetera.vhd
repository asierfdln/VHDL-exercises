----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.02.2020 17:47:58
-- Design Name: 
-- Module Name: project_4_cafetera - Behavioral
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

ENTITY project_4_cafetera IS
    PORT (
        INT : IN STD_LOGIC; -- encendido/apagado
        NB : IN STD_LOGIC; -- sensor agua bajo
        NA : IN STD_LOGIC; -- sensor agua alto
        C : IN STD_LOGIC; -- cantidad cafe
        siete_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END project_4_cafetera;

ARCHITECTURE Behavioral OF project_4_cafetera IS

BEGIN

    enable_seg <= "1110";

    PROCESS (INT, NB, NA, C)
    BEGIN

        -- cafetera apagada
        IF INT = '0' THEN
            siete_seg <= "1000000"; -- cero

            -- cafetera encendida
        ELSE

            -- no hay agua
            IF NA = '0' AND NB = '0' THEN
                siete_seg <= "0000110"; -- "E" error

                -- hay agua
            ELSE

                -- cafe suave
                IF NA = '1' AND NB = '1' AND C = '0' THEN
                    siete_seg <= "1110111"; -- segmento d

                    -- cafe normal
                ELSIF (NA = '1' AND NB = '1' AND C = '1') OR (NA = '0' AND NB = '1' AND C = '0') THEN
                    siete_seg <= "0110111"; -- segmento d y g

                    -- cafe fuerte
                ELSIF NA = '0' AND NB = '1' AND C = '1' THEN
                    siete_seg <= "0110110"; -- segmento d y g y a

                    -- condiciones libres...
                ELSE
                    siete_seg <= "0000110"; -- "E" error
                END IF;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;