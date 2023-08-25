
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY main IS
    PORT (
        clk     : IN STD_LOGIC;
        sw      : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --interruptores
        -- btnU        : in  STD_LOGIC; --boton arriba
        -- btnD        : in  STD_LOGIC; --boton abajo
        btnL    : IN STD_LOGIC; --boton izquierda
        btnR    : IN STD_LOGIC; --boton derecha
        btnC    : IN STD_LOGIC; --boton central
        led     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); --leds
        seg     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); --siete segmentos
        dp      : OUT STD_LOGIC; --punto decimal del siete segmentos
        an      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        dcmotor : OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
    );
END main;

ARCHITECTURE Behavioral OF main IS

    -- signals de pulsador dedo

    SIGNAL switch_unidades_decenas : STD_LOGIC;
    SIGNAL estado : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL cont_filtro : INTEGER RANGE 0 TO 500000000;
    SIGNAL salida : STD_LOGIC;
    SIGNAL flag_suma : STD_LOGIC;
    SIGNAL flag_resta : STD_LOGIC;
    SIGNAL freq_min : INTEGER RANGE 0 TO 100000000;
    SIGNAL contador_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_base_enable : INTEGER RANGE 0 TO 100000;
    SIGNAL enable_seg_aux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL dato : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL btnU : STD_LOGIC;
    SIGNAL btnD : STD_LOGIC;
    SIGNAL flag_origen_start_rapido : STD_LOGIC := '0';

BEGIN

    btnU <= sw(1);
    btnD <= sw(0);
    freq_min <= 100000;

    -- switch_unidades_decenas <= sw(15);
    -- led(15) <= flag_origen_start_rapido;

    -- process del automata pulsador dedo

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            estado <= "000";
            cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE estado IS
                WHEN "000" => -- INICIO
                    cont_filtro <= 0;
                    IF btnU = '1' OR btnD = '1' THEN
                        estado <= "001";
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    cont_filtro <= cont_filtro + 1;
                    IF (btnU = '1' OR btnD = '1') AND cont_filtro < freq_min THEN
                        estado <= "001";
                    ELSIF (btnU = '1' OR btnD = '1') AND cont_filtro = freq_min THEN
                        IF btnU = '1'THEN
                            estado <= "010";
                        ELSIF btnD = '1' THEN
                            estado <= "100";
                        END IF;
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    cont_filtro <= cont_filtro + 1;
                    IF btnU = '1' AND cont_filtro < 200000000 THEN
                        estado <= "010";
                    ELSIF btnU = '1' AND cont_filtro = 200000000 THEN
                        estado <= "110";
                    ELSIF btnU = '0' THEN
                        estado <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    cont_filtro <= 0;
                    IF btnU = '1' THEN
                        estado <= "001";
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    cont_filtro <= cont_filtro + 1;
                    IF btnD = '1' AND cont_filtro < 200000000 THEN
                        estado <= "100";
                    ELSIF btnD = '1' AND cont_filtro = 200000000 THEN
                        estado <= "110";
                    ELSIF btnD = '0' THEN
                        estado <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    cont_filtro <= 0;
                    IF btnD = '1' THEN
                        estado <= "001";
                    ELSE
                        estado <= "000";
                    END IF;
                WHEN "110" => -- START_RAPIDO
                    cont_filtro <= 0;
                    IF btnU = '1' OR btnD = '1' THEN
                        estado <= "111";
                    ELSIF btnU = '0' AND flag_origen_start_rapido = '0' THEN
                        estado <= "000";
                    ELSIF btnD = '0' AND flag_origen_start_rapido = '1' THEN
                        estado <= "000";
                    END IF;
                WHEN "111" => -- RAPIDO
                    cont_filtro <= cont_filtro + 1;
                    IF (btnU = '1' OR btnD = '1') AND cont_filtro < 20000000 THEN
                        estado <= "111";
                    ELSIF (btnU = '1' OR btnD = '1') AND cont_filtro = 20000000 THEN
                        estado <= "110";
                    ELSIF btnU = '0' AND flag_origen_start_rapido = '0' THEN
                        estado <= "000";
                    ELSIF btnD = '0' AND flag_origen_start_rapido = '1' THEN
                        estado <= "000";
                    END IF;
                WHEN OTHERS =>
                    cont_filtro <= 0;
                    estado <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas pulsador dedo

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
                flag_origen_start_rapido <= '0';
            WHEN "011" =>
                salida <= '1';
                flag_suma <= '1';
                flag_resta <= '0';
            WHEN "100" =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
                flag_origen_start_rapido <= '1';
            WHEN "101" =>
                salida <= '1';
                flag_suma <= '0';
                flag_resta <= '1';
            WHEN "110" =>
                salida <= '1';
                IF btnU = '1' THEN
                    flag_suma <= '1';
                    flag_resta <= '0';
                ELSIF btnD = '1' THEN
                    flag_suma <= '0';
                    flag_resta <= '1';
                END IF;
            WHEN "111" =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
            WHEN OTHERS =>
                salida <= '0';
                flag_suma <= '0';
                flag_resta <= '0';
                flag_origen_start_rapido <= '0';
        END CASE;
    END PROCESS;

    -- process de cambio de frecuencia minima para sumar/restar 1

    -- process(switch_unidades_decenas)
    -- begin
    --     if switch_unidades_decenas = '0' then
    --         freq_min <= 100000;
    --     else
    --         freq_min <= 100000000;
    --     end if;
    -- end process;

    -- process suma unidades por switch

    -- process(btnC, clk)
    -- begin
    --     if btnC = '1' then
    --         contador_unidades <= "0000";
    --     elsif rising_edge(clk) then
    --         if salida = '1' and switch_unidades_decenas = '0' then
    --             if flag_suma = '1' then
    --                 if contador_unidades = 9 then
    --                     contador_unidades <= "1001";
    --                 else
    --                     contador_unidades <= contador_unidades + 1;
    --                 end if;
    --             elsif flag_resta = '1' then
    --                 if contador_unidades = 0 then
    --                     contador_unidades <= "0000";
    --                 else
    --                     contador_unidades <= contador_unidades - 1;
    --                 end if;
    --             end if;
    --        end if;
    --     end if;
    -- end process;

    -- process suma decenas por switch

    -- process(btnC, clk)
    -- begin
    --     if btnC = '1' then
    --         contador_decenas <= "0000";
    --     elsif rising_edge(clk) then
    --         if salida = '1' and switch_unidades_decenas = '1' then
    --             if flag_suma = '1' then
    --                 if contador_decenas = 9 then
    --                     contador_decenas <= "1001";
    --                 else
    --                     contador_decenas <= contador_decenas + 1;
    --                 end if;
    --             elsif flag_resta = '1' then
    --                 if contador_decenas = 0 then
    --                     contador_decenas <= "0000";
    --                 else
    --                     contador_decenas <= contador_decenas - 1;
    --                 end if;
    --             end if;
    --        end if;
    --     end if;
    -- end process;

    -- process suma unidades sin switch

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            contador_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' THEN
                IF flag_suma = '1' THEN
                    IF contador_unidades = 9 AND contador_decenas < 9 THEN
                        contador_unidades <= "0000";
                    ELSIF contador_decenas = 9 AND contador_unidades = 9 THEN
                        contador_unidades <= "1001";
                    ELSE
                        contador_unidades <= contador_unidades + 1;
                    END IF;
                ELSIF flag_resta = '1' THEN
                    IF contador_unidades = 0 AND contador_decenas > 0 THEN
                        contador_unidades <= "1001";
                    ELSIF contador_decenas = 0 AND contador_unidades = 0 THEN
                        contador_unidades <= "0000";
                    ELSE
                        contador_unidades <= contador_unidades - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process suma decenas sin switch

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            contador_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' THEN
                IF flag_suma = '1' AND contador_unidades = 9 THEN
                    IF contador_decenas = 9 THEN
                        contador_decenas <= "1001";
                    ELSE
                        contador_decenas <= contador_decenas + 1;
                    END IF;
                ELSIF flag_resta = '1' AND contador_unidades = 0 THEN
                    IF contador_decenas = 0 THEN
                        contador_decenas <= "0000";
                    ELSE
                        contador_decenas <= contador_decenas - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de frecuencia de display de sietesegs

    PROCESS (clk, btnC)
    BEGIN
        IF btnC = '1' THEN
            contador_base_enable <= 0;
        ELSIF rising_edge(clk) THEN
            IF contador_base_enable = 100000 THEN
                contador_base_enable <= 0;
            ELSE
                contador_base_enable <= contador_base_enable + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de seleccion de display de sietesegs

    PROCESS (clk, btnC)
    BEGIN
        IF btnC = '1' THEN
            enable_seg_aux <= "0111";
        ELSIF rising_edge(clk) THEN
            IF contador_base_enable = 100000 THEN
                enable_seg_aux <= enable_seg_aux(2 DOWNTO 0) & enable_seg_aux(3);
            END IF;
        END IF;
    END PROCESS;

    an <= enable_seg_aux;

    -- process de display de valores en sietesegs

    PROCESS (enable_seg_aux, contador_unidades, contador_decenas)
    BEGIN
        CASE enable_seg_aux IS
            WHEN "0111" => dato <= "1111";
            WHEN "1011" => dato <= "1111";
            WHEN "1101" => dato <= contador_decenas;
            WHEN "1110" => dato <= contador_unidades;
            WHEN OTHERS => dato <= "1111";
        END CASE;
    END PROCESS;

    -- process de valores en sietesegs

    PROCESS (dato)
    BEGIN
        CASE dato IS
            WHEN "0000" => seg <= "0000001";
            WHEN "0001" => seg <= "1001111";
            WHEN "0010" => seg <= "0010010";
            WHEN "0011" => seg <= "0000110";
            WHEN "0100" => seg <= "1001100";
            WHEN "0101" => seg <= "0100100";
            WHEN "0110" => seg <= "1100000";
            WHEN "0111" => seg <= "0001111";
            WHEN "1000" => seg <= "0000000";
            WHEN "1001" => seg <= "0001100";
            WHEN OTHERS => seg <= "1111111";
        END CASE;
    END PROCESS;

END Behavioral;