----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.02.2020 10:17:03
-- Design Name: 
-- Module Name: project_1 - Behavioral
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

-- ZONA LIBRERIAS
-- COPIAS DEL TEMPLATE
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;
--use IEEE.std_logic_signed.all; -- SE PILLA LA ULTIMA DE LAS DOS...

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- ZONA DECLARACION ENTRADAS Y SALIDAS
ENTITY project_1 IS
    PORT (
        num_a : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        num_b : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        selector : IN STD_LOGIC;
        siete_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        --blank_input: in std_logic;
        suma : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- OJO AL PUNTO Y COMA ESTE...
        signo : OUT STD_LOGIC
    );
END project_1;

ARCHITECTURE Behavioral OF project_1 IS

    -- ZONA SIGNALS
    SIGNAL resultado : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL resultado_entero : INTEGER RANGE -15 TO 30;
    SIGNAL resultado_entero_final : INTEGER RANGE -15 TO 30;
    SIGNAL num_a_entero : INTEGER RANGE 0 TO 15;
    SIGNAL num_b_entero : INTEGER RANGE 0 TO 15;
    SIGNAL blank_input : STD_LOGIC;

BEGIN

    -- ZONA DECLARACION VHDL

    enable_seg <= "1110";
    -- ojo que esto siguiente es para el SINTETIZADOR, ES DECIR, NO CONSUME HARDWAREMENTE...
    num_a_entero <= to_integer(unsigned(num_a)); -- los cuatro bits de num_a los transformas a un signed que luego sea integer y tal...
    num_b_entero <= to_integer(unsigned(num_b));

    PROCESS (num_a_entero, num_b_entero, selector)
    BEGIN
        IF selector = '0' THEN
            resultado_entero <= num_a_entero + num_b_entero;
        ELSE
            resultado_entero <= num_a_entero - num_b_entero;
        END IF;
    END PROCESS;

    --suma <= resultado; -- algo de las signals de que "siempre a la derecha", confirmar logica con docus o algo...
    suma <= STD_LOGIC_VECTOR(to_signed(resultado_entero, 4));

    PROCESS (resultado_entero)
    BEGIN
        IF resultado_entero < 0 THEN
            signo <= '1';
            -- resultado_entero <= - resultado_entero; -- no microinstrucciones, esto es caca
            resultado_entero_final <= - resultado_entero;
        ELSE
            signo <= '0';
            -- resultado_entero <= - resultado_entero; -- no microinstrucciones, esto es caca
            resultado_entero_final <= resultado_entero;
        END IF;
    END PROCESS;

    PROCESS (resultado_entero_final)
    BEGIN
        IF resultado_entero_final <= 9 AND resultado_entero_final >= - 9 THEN
            blank_input <= '0';
        ELSE
            blank_input <= '1';
        END IF;
    END PROCESS;

    PROCESS (resultado_entero_final, blank_input)
    BEGIN
        IF blank_input = '0' THEN
            CASE resultado_entero_final IS
                WHEN 0 => siete_seg <= "1000000";
                WHEN 1 => siete_seg <= "1111001";
                WHEN 2 => siete_seg <= "0100100";
                WHEN 3 => siete_seg <= "0110000";
                WHEN 4 => siete_seg <= "0011001";
                WHEN 5 => siete_seg <= "0010010";
                WHEN 6 => siete_seg <= "0000011";
                WHEN 7 => siete_seg <= "1111000";
                WHEN 8 => siete_seg <= "0000000";
                WHEN 9 => siete_seg <= "0011000";
                WHEN OTHERS => siete_seg <= "0000110";
            END CASE;
        ELSE
            siete_seg <= "1111111";
        END IF;
    END PROCESS;

END Behavioral;