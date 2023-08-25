
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY main IS
    PORT (
        clk   : IN STD_LOGIC;
        sw    : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- interruptores
        btnU  : IN STD_LOGIC; -- boton arriba
        btnD  : IN STD_LOGIC; -- boton abajo
        btnL  : IN STD_LOGIC; -- boton izquierda
        btnR  : IN STD_LOGIC; -- boton derecha
        btnC  : IN STD_LOGIC; -- boton central
        led   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- leds
        seg   : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- siete segmentos
        dp    : OUT STD_LOGIC; -- punto decimal del siete segmentos
        an    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        servo : OUT STD_LOGIC
    );
END main;

ARCHITECTURE Behavioral OF main IS

    -- signals del servomotor

    SIGNAL estado_servo : STD_LOGIC_VECTOR (1 DOWNTO 0);
    SIGNAL selector_aspersor_mode : STD_LOGIC; -- sw(11)
    SIGNAL selector_input_mode : STD_LOGIC; -- sw(10)
    SIGNAL aspersor_cont : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL selector_switches : STD_LOGIC_VECTOR (3 DOWNTO 0); -- sw(3 downto 0)
    SIGNAL grados : INTEGER RANGE 0 TO 180;
    SIGNAL cont_flancos : INTEGER RANGE 0 TO 2000000; -- (20 ms) -> (50 Hz)
    SIGNAL pwm_longitud_pulso : INTEGER RANGE 0 TO 2000000; -- (20 ms) -> (50 Hz)

    -- signals servomotor-reloj

    SIGNAL segundos_offset : STD_LOGIC_VECTOR(3 DOWNTO 0); -- sw(15 downto 12)
    SIGNAL suma_o_resta : STD_LOGIC := '0';
    SIGNAL cont_base : INTEGER RANGE 0 TO 400000000; -- lleva la cuenta del reloj, puesto para 1-4 seg...
    SIGNAL tope_freq : INTEGER RANGE 0 TO 400000000;

    -- signals del pulsador

    SIGNAL estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL cont_filtro : INTEGER RANGE 0 TO 100000000;
    SIGNAL salida : STD_LOGIC;
    SIGNAL flag_suma : STD_LOGIC;
    SIGNAL flag_resta : STD_LOGIC;
    SIGNAL freq_min : INTEGER RANGE 0 TO 100000000;
    SIGNAL contador_centenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_base_enable : INTEGER RANGE 0 TO 100000;
    SIGNAL enable_seg_aux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL dato : STD_LOGIC_VECTOR (3 DOWNTO 0);

    -- signals pulsador-pwm

    SIGNAL contador_decenas_integer : INTEGER RANGE 0 TO 9;
    SIGNAL contador_centenas_integer : INTEGER RANGE 0 TO 9;
    SIGNAL numero_int : INTEGER RANGE 0 TO 200;

BEGIN

    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DEL SERVOMOTOR
    -- ####################################################################
    -- ####################################################################

    segundos_offset <= sw(15 DOWNTO 12);
    selector_aspersor_mode <= sw(11);
    selector_input_mode <= sw(10);
    selector_switches <= sw(3 DOWNTO 0);

    -- process de designacià¸£à¸“n de grados por tiempo/switches/dedo

    PROCESS (selector_aspersor_mode, aspersor_cont, selector_input_mode, selector_switches, suma_o_resta, numero_int)
    BEGIN

        -- grados por aspersor

        IF selector_aspersor_mode = '1' THEN
            CASE aspersor_cont IS
                WHEN "0000" => grados <= 10;
                WHEN "0001" => grados <= 20;
                WHEN "0010" => grados <= 30;
                WHEN "0011" => grados <= 40;
                WHEN "0100" => grados <= 50;
                WHEN "0101" => grados <= 60;
                WHEN "0110" => grados <= 70;
                WHEN "0111" => grados <= 80;
                WHEN "1000" => grados <= 90;
                WHEN "1001" => grados <= 100;
                WHEN "1010" => grados <= 110;
                WHEN "1011" => grados <= 120;
                WHEN "1100" => grados <= 130;
                WHEN "1101" => grados <= 140;
                WHEN "1110" => grados <= 150;
                WHEN "1111" => grados <= 170;
                WHEN OTHERS => grados <= 10;
            END CASE;
            led(3 DOWNTO 0) <= aspersor_cont;
            led(8) <= suma_o_resta;

            -- grados por switches

        ELSIF selector_input_mode = '0' THEN
            CASE selector_switches IS
                WHEN "0000" => grados <= 10;
                WHEN "0001" => grados <= 20;
                WHEN "0010" => grados <= 30;
                WHEN "0011" => grados <= 40;
                WHEN "0100" => grados <= 50;
                WHEN "0101" => grados <= 60;
                WHEN "0110" => grados <= 70;
                WHEN "0111" => grados <= 80;
                WHEN "1000" => grados <= 90;
                WHEN "1001" => grados <= 100;
                WHEN "1010" => grados <= 110;
                WHEN "1011" => grados <= 120;
                WHEN "1100" => grados <= 130;
                WHEN "1101" => grados <= 140;
                WHEN "1110" => grados <= 150;
                WHEN "1111" => grados <= 170;
                WHEN OTHERS => grados <= 10;
            END CASE;
            led(3 DOWNTO 0) <= "0000";
            led(8) <= '0';

            -- grados por dedo

        ELSE
            grados <= numero_int;
            led(3 DOWNTO 0) <= "0000";
            led(8) <= '0';
        END IF;
    END PROCESS;

    pwm_longitud_pulso <= grados * 1111 + 50000;

    -- process del automata del pwm del servo

    PROCESS (clk, btnC)
    BEGIN
        IF btnC = '1' THEN
            estado_servo <= "00";
            cont_flancos <= 0;
        ELSIF rising_edge(clk) THEN
            CASE estado_servo IS
                WHEN "00" =>
                    cont_flancos <= 0;
                    estado_servo <= "01";
                WHEN "01" =>
                    cont_flancos <= 1;
                    estado_servo <= "10";
                WHEN "10" =>
                    cont_flancos <= cont_flancos + 1;
                    IF cont_flancos = pwm_longitud_pulso THEN
                        estado_servo <= "11";
                    ELSE
                        estado_servo <= "10";
                    END IF;
                WHEN "11" =>
                    cont_flancos <= cont_flancos + 1;
                    IF cont_flancos = 2000000 THEN
                        estado_servo <= "01";
                    ELSE
                        estado_servo <= "11";
                    END IF;
                WHEN OTHERS =>
                    cont_flancos <= 0;
                    estado_servo <= "00";
            END CASE;
        END IF;
    END PROCESS;

    -- process de salidas del servo

    PROCESS (estado_servo)
    BEGIN
        CASE estado_servo IS
            WHEN "00" => servo <= '0';
            WHEN "01" => servo <= '1';
            WHEN "10" => servo <= '1';
            WHEN "11" => servo <= '0';
            WHEN OTHERS => servo <= '0';
        END CASE;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DEL RELOJ
    -- ####################################################################
    -- ####################################################################

    -- proceso de reloj

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            cont_base <= 0;
        ELSIF rising_edge(clk) THEN
            IF cont_base = tope_freq THEN
                cont_base <= 0;
            ELSE
                cont_base <= cont_base + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de cambio de vel.

    PROCESS (segundos_offset)
    BEGIN
        IF segundos_offset = "XXX1" THEN
            led(15 DOWNTO 12) <= "0001";
            tope_freq <= 100000000;
        ELSIF segundos_offset = "XX10" THEN
            led(15 DOWNTO 12) <= "0010";
            tope_freq <= 200000000;
        ELSIF segundos_offset = "X100" THEN
            led(15 DOWNTO 12) <= "0100";
            tope_freq <= 300000000;
        ELSIF segundos_offset = "1000" THEN
            led(15 DOWNTO 12) <= "1000";
            tope_freq <= 400000000;
        ELSE
            led(15 DOWNTO 12) <= "0000";
            tope_freq <= 100000000;
        END IF;
    END PROCESS;

    -- process de cambio de aspersor_cont

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            suma_o_resta <= '0';
            aspersor_cont <= "0000";
        ELSIF rising_edge(clk) THEN
            IF selector_aspersor_mode = '1' THEN
                IF cont_base = tope_freq THEN
                    IF aspersor_cont = "1111" THEN
                        suma_o_resta <= '1';
                    ELSIF aspersor_cont = "0000" THEN
                        suma_o_resta <= '0';
                    END IF;
                    IF suma_o_resta = '0' AND aspersor_cont /= "1111" THEN
                        aspersor_cont <= aspersor_cont + 1;
                    ELSIF suma_o_resta = '1' AND aspersor_cont /= "0000" THEN
                        aspersor_cont <= aspersor_cont - 1;
                    END IF;
                END IF;
            ELSE
                suma_o_resta <= '0';
                aspersor_cont <= "0000";
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DEL PULSADOR
    -- ####################################################################
    -- ####################################################################

    -- process del automata del pulsador

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            estado_pulsador <= "000";
            cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE estado_pulsador IS
                WHEN "000" => -- INICIO
                    cont_filtro <= 0;
                    IF btnU = '1' OR btnD = '1' THEN
                        estado_pulsador <= "001";
                    ELSE
                        estado_pulsador <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    cont_filtro <= cont_filtro + 1;
                    IF (btnU = '1' OR btnD = '1') AND cont_filtro < 100000 THEN
                        estado_pulsador <= "001";
                    ELSIF (btnU = '1' OR btnD = '1') AND cont_filtro = 100000 THEN
                        IF btnU = '1'THEN
                            estado_pulsador <= "010";
                        ELSIF btnD = '1' THEN
                            estado_pulsador <= "100";
                        END IF;
                    ELSE
                        estado_pulsador <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    cont_filtro <= 0;
                    IF btnU = '1' THEN
                        estado_pulsador <= "010";
                    ELSE
                        estado_pulsador <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    cont_filtro <= 0;
                    IF btnU = '1' THEN
                        estado_pulsador <= "001";
                    ELSE
                        estado_pulsador <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    cont_filtro <= 0;
                    IF btnD = '1' THEN
                        estado_pulsador <= "100";
                    ELSE
                        estado_pulsador <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    cont_filtro <= 0;
                    IF btnD = '1' THEN
                        estado_pulsador <= "001";
                    ELSE
                        estado_pulsador <= "000";
                    END IF;
                WHEN OTHERS =>
                    cont_filtro <= 0;
                    estado_pulsador <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas del pulsador

    PROCESS (estado_pulsador)
    BEGIN
        CASE estado_pulsador IS
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

    -- process de sumar/restar decenas

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            contador_decenas <= "0001";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' THEN
                IF flag_suma = '1' THEN
                    IF contador_decenas = 7 AND contador_centenas = 1 THEN
                        contador_decenas <= "0111";
                    ELSIF contador_decenas = 9 THEN
                        contador_decenas <= "0000";
                    ELSE
                        contador_decenas <= contador_decenas + 1;
                    END IF;
                ELSIF flag_resta = '1' THEN
                    IF contador_decenas = 1 AND contador_centenas = 0 THEN
                        contador_decenas <= "0001";
                    ELSIF contador_decenas = 0 THEN
                        contador_decenas <= "1001";
                    ELSE
                        contador_decenas <= contador_decenas - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de sumar/restar centenas

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            contador_centenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' THEN
                IF flag_suma = '1' THEN
                    IF contador_decenas = 9 THEN
                        contador_centenas <= contador_centenas + 1;
                    END IF;
                ELSIF flag_resta = '1' THEN
                    IF contador_centenas = 1 AND contador_decenas = 0 THEN
                        contador_centenas <= contador_centenas - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    contador_decenas_integer <= conv_integer(contador_decenas);
    contador_centenas_integer <= conv_integer(contador_centenas);
    numero_int <= ((contador_centenas_integer * 10) + contador_decenas_integer) * 10;

    -- proceso de frecuencia para el control del enable_seg_aux

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

    -- proceso de control del enable_seg_aux

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

    -- proceso de display de diferentes valores en diferentes siete_segs

    PROCESS (enable_seg_aux, contador_decenas, contador_centenas)
    BEGIN
        IF grados < 100 THEN
            CASE enable_seg_aux IS
                WHEN "0111" => dato <= "1111";
                WHEN "1011" => dato <= STD_LOGIC_VECTOR(to_unsigned(grados / 100, 4));
                WHEN "1101" => dato <= STD_LOGIC_VECTOR(to_unsigned(grados / 10, 4));
                WHEN "1110" => dato <= "0000";
                WHEN OTHERS => dato <= "1111";
            END CASE;
        ELSE
            CASE enable_seg_aux IS
                WHEN "0111" => dato <= "1111";
                WHEN "1011" => dato <= STD_LOGIC_VECTOR(to_unsigned(grados / 100, 4));
                WHEN "1101" => dato <= STD_LOGIC_VECTOR(to_unsigned((grados / 10) - 10, 4));
                WHEN "1110" => dato <= "0000";
                WHEN OTHERS => dato <= "1111";
            END CASE;
        END IF;
    END PROCESS;

    -- proceso de display de diferentes valores en diferentes siete_segs

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