LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY project_9 IS
    PORT (
        clk : IN STD_LOGIC;
        inicio : IN STD_LOGIC;
        contador_up : IN STD_LOGIC;
        contador_down : IN STD_LOGIC;
        freq_switch : IN STD_LOGIC;
        seven_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END project_9;

ARCHITECTURE Behavioral OF project_9 IS

    SIGNAL estado : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL cont_filtro : INTEGER RANGE 0 TO 100000000;
    SIGNAL salida : STD_LOGIC;
    SIGNAL flag_suma : STD_LOGIC;
    SIGNAL flag_resta : STD_LOGIC;
    SIGNAL freq_min : INTEGER RANGE 0 TO 100000000;
    SIGNAL contador_unidades_seg : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_decenas_seg : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_base_enable : INTEGER RANGE 0 TO 100000;
    SIGNAL enable_seg_aux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL dato : STD_LOGIC_VECTOR (3 DOWNTO 0);

BEGIN

    -- process del automata
    PROCESS (inicio, clk)
    BEGIN
        IF inicio = '1' THEN
            estado <= "000";
            cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE estado IS
                WHEN "000" => -- INICIO
                    cont_filtro <= 0;
                    IF contador_up = '1' OR contador_down = '1' THEN
                        estado <= "001";
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    cont_filtro <= cont_filtro + 1;
                    IF (contador_up = '1' OR contador_down = '1') AND cont_filtro < freq_min THEN
                        estado <= "001";
                    ELSIF (contador_up = '1' OR contador_down = '1') AND cont_filtro = freq_min THEN
                        IF contador_up = '1'THEN
                            estado <= "010";
                        ELSIF contador_down = '1' THEN
                            estado <= "100";
                        END IF;
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    cont_filtro <= 0;
                    IF contador_up = '1' THEN
                        estado <= "010";
                    ELSE
                        estado <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    cont_filtro <= 0;
                    IF contador_up = '1' THEN
                        estado <= "001";
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    cont_filtro <= 0;
                    IF contador_down = '1' THEN
                        estado <= "100";
                    ELSE
                        estado <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    cont_filtro <= 0;
                    IF contador_down = '1' THEN
                        estado <= "001";
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN OTHERS =>
                    cont_filtro <= 0;
                    estado <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas
    PROCESS (estado)
    BEGIN
        CASE estado IS
            WHEN "000" =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
            WHEN "001" =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
            WHEN "010" =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
            WHEN "011" =>
                salida <= '1';
                flag_suma <= '1';
                flag_resta <= '0';
            WHEN "100" =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
            WHEN "101" =>
                salida <= '1';
                flag_suma <= '0';
                flag_resta <= '1';
            WHEN OTHERS => salida <= '0';
        END CASE;
    END PROCESS;

    -- process de cambio de frecuencia minima para sumar/restar 1

    PROCESS (freq_switch)
    BEGIN
        IF freq_switch = '0' THEN
            freq_min <= 100000;
        ELSE
            freq_min <= 100000000;
        END IF;
    END PROCESS;

    PROCESS (inicio, clk)
    BEGIN
        IF inicio = '1' THEN
            contador_unidades_seg <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' THEN
                IF flag_suma = '1' THEN
                    IF contador_unidades_seg = 9 AND contador_decenas_seg < 9 THEN
                        contador_unidades_seg <= "0000";
                    ELSIF contador_decenas_seg = 9 AND contador_unidades_seg = 9 THEN
                        contador_unidades_seg <= "1001";
                    ELSE
                        contador_unidades_seg <= contador_unidades_seg + 1;
                    END IF;
                ELSIF flag_resta = '1' THEN
                    IF contador_unidades_seg = 0 AND contador_decenas_seg > 0 THEN
                        contador_unidades_seg <= "1001";
                    ELSIF contador_decenas_seg = 0 AND contador_unidades_seg = 0 THEN
                        contador_unidades_seg <= "0000";
                    ELSE
                        contador_unidades_seg <= contador_unidades_seg - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (inicio, clk)
    BEGIN
        IF inicio = '1' THEN
            contador_decenas_seg <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' THEN
                IF flag_suma = '1' AND contador_unidades_seg = 9 THEN
                    IF contador_decenas_seg = 9 THEN
                        contador_decenas_seg <= "1001";
                    ELSE
                        contador_decenas_seg <= contador_decenas_seg + 1;
                    END IF;
                ELSIF flag_resta = '1' AND contador_unidades_seg = 0 THEN
                    IF contador_decenas_seg = 0 THEN
                        contador_decenas_seg <= "0000";
                    ELSE
                        contador_decenas_seg <= contador_decenas_seg - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (clk, inicio)
    BEGIN
        IF inicio = '1' THEN
            contador_base_enable <= 0;
        ELSIF rising_edge(clk) THEN
            IF contador_base_enable = 100000 THEN
                contador_base_enable <= 0;
            ELSE
                contador_base_enable <= contador_base_enable + 1;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (clk, inicio)
    BEGIN
        IF inicio = '1' THEN
            enable_seg_aux <= "0111";
        ELSIF rising_edge(clk) THEN
            IF contador_base_enable = 100000 THEN
                enable_seg_aux <= enable_seg_aux(2 DOWNTO 0) & enable_seg_aux(3);
            END IF;
        END IF;
    END PROCESS;

    enable_seg <= enable_seg_aux;

    PROCESS (enable_seg_aux, contador_unidades_seg, contador_decenas_seg)
    BEGIN
        CASE enable_seg_aux IS
            WHEN "0111" => dato <= "1111";
            WHEN "1011" => dato <= "1111";
            WHEN "1101" => dato <= contador_decenas_seg;
            WHEN "1110" => dato <= contador_unidades_seg;
            WHEN OTHERS => dato <= "1111";
        END CASE;
    END PROCESS;

    PROCESS (dato)
    BEGIN
        CASE dato IS
            WHEN "0000" => seven_seg <= "0000001";
            WHEN "0001" => seven_seg <= "1001111";
            WHEN "0010" => seven_seg <= "0010010";
            WHEN "0011" => seven_seg <= "0000110";
            WHEN "0100" => seven_seg <= "1001100";
            WHEN "0101" => seven_seg <= "0100100";
            WHEN "0110" => seven_seg <= "1100000";
            WHEN "0111" => seven_seg <= "0001111";
            WHEN "1000" => seven_seg <= "0000000";
            WHEN "1001" => seven_seg <= "0001100";
            WHEN OTHERS => seven_seg <= "1111111";
        END CASE;
    END PROCESS;

END Behavioral;