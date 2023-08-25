
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY main IS
    PORT (
        clk     : IN STD_LOGIC;
        sw      : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- interruptores
        btnU    : IN STD_LOGIC; -- boton arriba
        btnD    : IN STD_LOGIC; -- boton abajo
        btnL    : IN STD_LOGIC; -- boton izquierda
        btnR    : IN STD_LOGIC; -- boton derecha
        btnC    : IN STD_LOGIC; -- boton central
        led     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- leds
        seg     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- siete segmentos
        dp      : OUT STD_LOGIC; -- punto decimal del seite segmentos
        an      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        dcmotor : OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
    );
END main;

ARCHITECTURE Behavioral OF main IS

    -- signals del pulsador de dedo

    SIGNAL switch_unidades_o_decenas : STD_LOGIC; -- sw(0)
    SIGNAL estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL cont_filtro : INTEGER RANGE 0 TO 100000000;
    SIGNAL salida : STD_LOGIC;
    SIGNAL flag_suma : STD_LOGIC;
    SIGNAL flag_resta : STD_LOGIC;
    SIGNAL freq_min : INTEGER RANGE 0 TO 100000000;
    SIGNAL contador_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL contador_base_enable : INTEGER RANGE 0 TO 100000;
    SIGNAL enable_seg_aux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL dato : STD_LOGIC_VECTOR (3 DOWNTO 0);

    -- signals pulsador-pwm

    SIGNAL contador_unidades_integer : INTEGER RANGE 0 TO 9;
    SIGNAL contador_decenas_integer : INTEGER RANGE 0 TO 9;
    SIGNAL numero_int : INTEGER RANGE 0 TO 99;

    -- signals del pwm

    SIGNAL estado_pwm : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL duty_cycle : INTEGER RANGE 0 TO 100; -- numero_int
    SIGNAL sentido_giro : STD_LOGIC; -- sw(1)
    SIGNAL cont_flancos : INTEGER RANGE 0 TO 100000000;
    SIGNAL pwm_longitud_pulso : INTEGER RANGE 0 TO 100000000; -- longitud del pulso
    SIGNAL pwm_longitud_ciclo : INTEGER RANGE 0 TO 100000000; -- longitud del ciclo
    SIGNAL pwm_hz : INTEGER RANGE 0 TO 500;
    SIGNAL pwm_out : STD_LOGIC;

BEGIN

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

    switch_unidades_o_decenas <= sw(0);

    -- process de sumar/restar unidades (no da tiempo a llegar hasta 99 con weblab)

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            contador_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' AND switch_unidades_o_decenas = '0' THEN
                IF flag_suma = '1' THEN
                    IF contador_unidades = 9 THEN
                        contador_unidades <= "1001";
                    ELSE
                        contador_unidades <= contador_unidades + 1;
                    END IF;
                ELSIF flag_resta = '1' THEN
                    IF contador_unidades = 0 THEN
                        contador_unidades <= "0000";
                    ELSE
                        contador_unidades <= contador_unidades - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de sumar/restar decenas (no da tiempo a llegar hasta 99 con weblab)

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            contador_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF salida = '1' AND switch_unidades_o_decenas = '1' THEN
                IF flag_suma = '1' THEN
                    IF contador_decenas = 9 THEN
                        contador_decenas <= "1001";
                    ELSE
                        contador_decenas <= contador_decenas + 1;
                    END IF;
                ELSIF flag_resta = '1' THEN
                    IF contador_decenas = 0 THEN
                        contador_decenas <= "0000";
                    ELSE
                        contador_decenas <= contador_decenas - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    contador_unidades_integer <= conv_integer(contador_unidades);
    contador_decenas_integer <= conv_integer(contador_decenas);
    numero_int <= (contador_decenas_integer * 10) + contador_unidades_integer;

    led(6 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(numero_int, 7));

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

    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DEL MOTOR DC
    -- ####################################################################
    -- ####################################################################

    duty_cycle <= numero_int;
    sentido_giro <= sw(1);

    -- process del sentido de giro del motor

    PROCESS (sentido_giro)
    BEGIN
        IF sentido_giro = '0' THEN
            dcmotor <= "0" & pwm_out;
        ELSE
            dcmotor <= pwm_out & "0";
        END IF;
    END PROCESS;

    pwm_hz <= 200; -- (200 Hz) -> (500000 flancos) -> (0.5 ms)

    -- process de definicion de pwm_longitud_ciclo como (frecuencia base de
    -- la fpga) / (pwm_hz)

    PROCESS (pwm_hz)
    BEGIN
        pwm_longitud_ciclo <= 100000000 / pwm_hz;
    END PROCESS;

    -- process de definicion de pwm_longitud_pulso como porcentaje X de
    -- pwm_longitud_ciclo en función del valor de duty_cycle

    PROCESS (pwm_longitud_ciclo, duty_cycle)
    BEGIN
        pwm_longitud_pulso <= pwm_longitud_ciclo * duty_cycle / 100;
    END PROCESS;

    -- process del automata del pwm

    PROCESS (clk, btnC)
    BEGIN
        IF btnC = '1' THEN
            estado_pwm <= "000";
            cont_flancos <= 0;
        ELSIF rising_edge(clk) THEN
            CASE estado_pwm IS
                WHEN "000" =>
                    cont_flancos <= 0;
                    IF duty_cycle /= 0 THEN
                        estado_pwm <= "001";
                    ELSE
                        estado_pwm <= "100";
                    END IF;
                WHEN "001" =>
                    cont_flancos <= 1;
                    estado_pwm <= "010";
                WHEN "010" =>
                    cont_flancos <= cont_flancos + 1;
                    IF cont_flancos < pwm_longitud_pulso THEN
                        estado_pwm <= "010";
                    ELSE
                        IF duty_cycle /= 100 THEN
                            estado_pwm <= "011";
                        ELSE
                            estado_pwm <= "001";
                        END IF;
                    END IF;
                WHEN "011" =>
                    cont_flancos <= cont_flancos + 1;
                    IF cont_flancos < pwm_longitud_ciclo THEN
                        estado_pwm <= "011";
                    ELSE
                        IF duty_cycle /= 0 THEN
                            estado_pwm <= "001";
                        ELSE
                            estado_pwm <= "100";
                        END IF;
                    END IF;
                WHEN "100" =>
                    cont_flancos <= 1;
                    estado_pwm <= "011";
                WHEN OTHERS =>
                    cont_flancos <= 0;
                    estado_pwm <= "000";
            END CASE;
        END IF;
    END PROCESS;

    --process de las salidas del pwm

    PROCESS (estado_pwm)
    BEGIN
        CASE estado_pwm IS
            WHEN "000" => pwm_out <= '0';
            WHEN "001" => pwm_out <= '1';
            WHEN "010" => pwm_out <= '1';
            WHEN "011" => pwm_out <= '0';
            WHEN "100" => pwm_out <= '0';
            WHEN OTHERS => pwm_out <= '0';
        END CASE;
    END PROCESS;

END Behavioral;