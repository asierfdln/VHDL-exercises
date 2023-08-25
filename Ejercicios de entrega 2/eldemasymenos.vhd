
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

ENTITY project_entrega2_1 IS
    PORT (
        num_a : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        num_b : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        siete_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END project_entrega2_1;

ARCHITECTURE Behavioral OF project_entrega2_1 IS

    SIGNAL numero : STD_LOGIC_VECTOR (3 DOWNTO 0);

BEGIN

    enable_seg <= "1110";

    PROCESS (num_a, num_b, numero)
    BEGIN
        IF num_a > num_b THEN
            numero <= num_a;
        ELSIF num_b > num_a THEN
            numero <= num_b;
        ELSE
            numero <= "1111";
        END IF;
    END PROCESS;

    PROCESS (numero)
    BEGIN
        CASE numero IS
            WHEN "0000" => siete_seg <= "1000000";
            WHEN "0001" => siete_seg <= "1111001";
            WHEN "0010" => siete_seg <= "0100100";
            WHEN "0011" => siete_seg <= "0110000";
            WHEN "0100" => siete_seg <= "0011001";
            WHEN "0101" => siete_seg <= "0010010";
            WHEN "0110" => siete_seg <= "0000011";
            WHEN "0111" => siete_seg <= "1111000";
            WHEN "1000" => siete_seg <= "0000000";
            WHEN "1001" => siete_seg <= "0011000";
            WHEN OTHERS => siete_seg <= "1111111";
        END CASE;
    END PROCESS;

END Behavioral;