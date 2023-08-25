
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

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
        dp      : OUT STD_LOGIC; -- punto decimal del siete segmentos
        an      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        servo   : OUT STD_LOGIC;
        dcmotor : OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
    );
END main;

ARCHITECTURE Behavioral OF main IS

    -- signals de control de modos y comunes

    SIGNAL vector_modo : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL sal_mux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL enable_aux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_base_enable : INTEGER RANGE 0 TO 100000;

    -- signals del reloj

    SIGNAL reloj_inicio : STD_LOGIC;
    SIGNAL reloj_cont_centesimas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_decimas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_segs_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_segs_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_mins_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_mins_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_horas_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_horas_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_cont_base : INTEGER RANGE 0 TO 1000000;
    SIGNAL reloj_tope_freq : INTEGER RANGE 0 TO 1000000;
    SIGNAL reloj_select_display_hhmm_ss : STD_LOGIC;
    SIGNAL reloj_fast : STD_LOGIC;
    SIGNAL reloj_pausa : STD_LOGIC;

    -- signals del reloj - pulsador de dedo del dp

    SIGNAL reloj_puesta_en_hora_switch : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_dp_display_m_h : STD_LOGIC := '0';
    SIGNAL reloj_puesta_en_hora_dp_estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL reloj_puesta_en_hora_dp_cont_filtro : INTEGER RANGE 0 TO 100000000;
    SIGNAL reloj_puesta_en_hora_dp_salida : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_dp_flag_suma : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_dp_flag_resta : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_dp_btnL : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_dp_btnR : STD_LOGIC;

    -- signals del reloj - switches de suma y resta

    SIGNAL reloj_puesta_en_hora_estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL reloj_puesta_en_hora_cont_filtro : INTEGER RANGE 0 TO 500000000;
    SIGNAL reloj_puesta_en_hora_flag_salida : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_flag_suma : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_flag_resta : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_sumar : STD_LOGIC;
    SIGNAL reloj_puesta_en_hora_restar : STD_LOGIC;

    -- signals del reloj-dcmotor

    SIGNAL reloj_dcmotor_cont_horas_unidades_integer : INTEGER RANGE 0 TO 9;
    SIGNAL reloj_dcmotor_cont_horas_decenas_integer : INTEGER RANGE 0 TO 9;
    SIGNAL reloj_dcmotor_cont_horas_integer_dcmotor : INTEGER RANGE 0 TO 100;
    SIGNAL reloj_dcmotor_estado_pwm : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL reloj_dcmotor_duty_cycle : INTEGER RANGE 0 TO 100;
    SIGNAL reloj_dcmotor_sentido_giro : STD_LOGIC;
    SIGNAL reloj_dcmotor_cont_flancos : INTEGER RANGE 0 TO 100000000;
    SIGNAL reloj_dcmotor_pwm_longitud_pulso : INTEGER RANGE 0 TO 100000000;
    SIGNAL reloj_dcmotor_pwm_longitud_ciclo : INTEGER RANGE 0 TO 100000000;
    SIGNAL reloj_dcmotor_pwm_hz : INTEGER RANGE 0 TO 500;
    SIGNAL reloj_dcmotor_pwm_out : STD_LOGIC;

    -- signals del reloj-alarma

    SIGNAL reloj_alarma_switch_off_on : STD_LOGIC;
    SIGNAL reloj_alarma_minutos_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_alarma_minutos_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_alarma_horas_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_alarma_horas_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_alarma_sonar : STD_LOGIC;
    SIGNAL reloj_alarma_switch_settime : STD_LOGIC;
    SIGNAL reloj_alarma_led_estado : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL reloj_alarma_led_contflancos : INTEGER RANGE 0 TO 100000000;
    SIGNAL reloj_alarma_led : STD_LOGIC;
    SIGNAL reloj_alarma_snooze_estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL reloj_alarma_snooze_cont_filtro : INTEGER RANGE 0 TO 100005;
    SIGNAL reloj_alarma_snooze_btnU : STD_LOGIC;
    SIGNAL reloj_alarma_snooze_btnD : STD_LOGIC;
    SIGNAL reloj_alarma_snooze_salida : STD_LOGIC;
    SIGNAL reloj_alarma_snooze_salida_suma : STD_LOGIC;
    SIGNAL reloj_alarma_snooze_salida_resta : STD_LOGIC;

    -- signals del servomotor

    SIGNAL servo_inicio : STD_LOGIC;
    SIGNAL servo_estado_servo : STD_LOGIC_VECTOR (1 DOWNTO 0);
    SIGNAL servo_selector_aspersor_mode : STD_LOGIC;
    SIGNAL servo_selector_input_mode : STD_LOGIC;
    SIGNAL servo_aspersor_cont : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL servo_selector_switches : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL servo_grados : INTEGER RANGE 0 TO 180;
    SIGNAL servo_cont_flancos : INTEGER RANGE 0 TO 2000000;
    SIGNAL servo_pwm_longitud_pulso : INTEGER RANGE 0 TO 2000000;

    -- signals del servomotor-reloj

    SIGNAL servo_segundos_offset : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL servo_suma_o_resta : STD_LOGIC := '0';
    SIGNAL servo_cont_base : INTEGER RANGE 0 TO 400000000;
    SIGNAL servo_tope_freq : INTEGER RANGE 0 TO 400000000;

    -- signals del servomotor-pulsador

    SIGNAL servo_estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL servo_cont_filtro : INTEGER RANGE 0 TO 500000000;
    SIGNAL servo_salida : STD_LOGIC;
    SIGNAL servo_flag_suma : STD_LOGIC;
    SIGNAL servo_flag_resta : STD_LOGIC;
    SIGNAL servo_freq_min : INTEGER RANGE 0 TO 100000000;
    SIGNAL servo_contador_centenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL servo_contador_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL servo_botonMas : STD_LOGIC;
    SIGNAL servo_botonMenos : STD_LOGIC;

    -- signals del servomotor-pulsador-pwm

    SIGNAL servo_contador_decenas_integer : INTEGER RANGE 0 TO 9;
    SIGNAL servo_contador_centenas_integer : INTEGER RANGE 0 TO 9;
    SIGNAL servo_numero_int : INTEGER RANGE 0 TO 200;

    -- signals del conversor binario-BCD

    SIGNAL binario_bcd_inicio : STD_LOGIC;
    SIGNAL binario_bcd_binario : STD_LOGIC_VECTOR (9 DOWNTO 0);
    SIGNAL binario_bcd_enable : STD_LOGIC;
    SIGNAL binario_bcd_fin : STD_LOGIC;
    SIGNAL binario_bcd_vector : STD_LOGIC_VECTOR (25 DOWNTO 0);
    SIGNAL binario_bcd_estado_conversion : STD_LOGIC_VECTOR (1 DOWNTO 0);
    SIGNAL binario_bcd_contador_desplazamientos : INTEGER RANGE 0 TO 9;
    SIGNAL binario_bcd_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL binario_bcd_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL binario_bcd_centenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL binario_bcd_millar : STD_LOGIC_VECTOR (3 DOWNTO 0);

    -- signals del conversor binario-BCD - reloj

    SIGNAL binario_bcd_cont_base_enable : INTEGER RANGE 0 TO 100000;
    SIGNAL binario_bcd_cont : INTEGER RANGE 0 TO 100000000;
    SIGNAL binario_bcd_tope_freq : INTEGER RANGE 0 TO 400000000;
    SIGNAL binario_bcd_modo_lento_rapido : STD_LOGIC;

    -- signals del cronometro

    SIGNAL cronom_inicio : STD_LOGIC;
    SIGNAL cronom_cont_centesimas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_decimas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_segs_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_segs_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_mins_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_mins_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_horas_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_horas_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_base : INTEGER RANGE 0 TO 1000000;
    SIGNAL cronom_tope_freq : INTEGER RANGE 0 TO 1000000;
    SIGNAL cronom_pausa : STD_LOGIC;
    SIGNAL cronom_select_display_hhmm_ss : STD_LOGIC;
    SIGNAL cronom_split : STD_LOGIC;
    SIGNAL cronom_cont_centesimas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_decimas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_segs_unidades_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cronom_cont_segs_decenas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);

    -- signals del cronometro - func

    SIGNAL cronom_func_btnU_stop : STD_LOGIC;
    SIGNAL cronom_func_btnD_split : STD_LOGIC;
    SIGNAL cronom_func_estado_pulsador : STD_LOGIC_VECTOR (2 DOWNTO 0);
    SIGNAL cronom_func_cont_filtro : INTEGER RANGE 0 TO 100000000;
    SIGNAL cronom_func_flag_salida : STD_LOGIC;
    SIGNAL cronom_func_flag_salida_flag_pausa : STD_LOGIC;
    SIGNAL cronom_func_flag_salida_flag_split : STD_LOGIC;
    SIGNAL cronom_func_flag_pausa : STD_LOGIC := '0';
    SIGNAL cronom_func_flag_split : STD_LOGIC := '0';

    --signals del LIFO

    SIGNAL reloj_visualizar_pila : STD_LOGIC;
    SIGNAL reloj_pila_push : STD_LOGIC;
    SIGNAL reloj_pila_pop : STD_LOGIC;
    SIGNAL reloj_pila_stack_pointer : INTEGER RANGE -8 TO 8 := 7;
    TYPE data IS ARRAY (7 DOWNTO 0) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL reloj_pila : data := (OTHERS => (OTHERS => '0'));
    SIGNAL reloj_pila_entrada : STD_LOGIC_VECTOR (15 DOWNTO 0);
    SIGNAL reloj_pila_entrada_hora_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_entrada_hora_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_entrada_min_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_entrada_min_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_salida : STD_LOGIC_VECTOR (15 DOWNTO 0) := "0000000000000000";
    SIGNAL reloj_pila_salida_hora_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_salida_hora_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_salida_min_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL reloj_pila_salida_min_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    TYPE estado IS (idle, mete_push, saca_pop, llena, vacia, overflow, underflow);
    SIGNAL reloj_estado_pila : estado;
    SIGNAL reloj_pila_llena : STD_LOGIC;
    SIGNAL reloj_pila_vacia : STD_LOGIC;
    SIGNAL reloj_pila_error_overflow : STD_LOGIC;
    SIGNAL reloj_pila_error_underflow : STD_LOGIC;
    SIGNAL reloj_pila_estado_push : STD_LOGIC_VECTOR (1 DOWNTO 0);
    SIGNAL reloj_pila_cont_filtro_push : INTEGER RANGE 0 TO 100000;
    SIGNAL reloj_pila_salida_push : STD_LOGIC;
    SIGNAL reloj_pila_estado_pop : STD_LOGIC_VECTOR (1 DOWNTO 0);
    SIGNAL reloj_pila_cont_filtro_pop : INTEGER RANGE 0 TO 100000;
    SIGNAL reloj_pila_salida_pop : STD_LOGIC;

BEGIN

    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DE CONTROL
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    vector_modo <= sw(15 DOWNTO 14);
    reloj_alarma_switch_off_on <= sw(13);
    servo_pwm_longitud_pulso <= servo_grados * 1111 + 50000;

    -- process de asignacion de switches

    PROCESS (btnC, clk, vector_modo)
    BEGIN
        IF btnC = '1' THEN
            CASE vector_modo IS
                WHEN "00" => -- reloj
                    reloj_inicio <= '1';
                WHEN "01" => -- servomotor
                    servo_inicio <= '1';
                WHEN "10" => -- bin-bcd
                    binario_bcd_inicio <= '1';
                WHEN OTHERS => -- cronometro
                    cronom_inicio <= '1';
            END CASE;
        ELSIF rising_edge(clk) THEN
            reloj_inicio <= '0';
            servo_inicio <= '0';
            binario_bcd_inicio <= '0';
            cronom_inicio <= '0';
            CASE vector_modo IS
                WHEN "00" => -- reloj
                    reloj_select_display_hhmm_ss <= sw(0);
                    reloj_fast <= sw(1);
                    reloj_pausa <= sw(2);
                    reloj_puesta_en_hora_switch <= sw(3);
                    reloj_alarma_switch_settime <= sw(4);
                    reloj_puesta_en_hora_restar <= sw(6);
                    reloj_puesta_en_hora_sumar <= sw(7);
                    reloj_dcmotor_sentido_giro <= sw(8);
                    reloj_puesta_en_hora_dp_btnL <= btnL;
                    reloj_puesta_en_hora_dp_btnR <= btnR;
                    reloj_dcmotor_pwm_hz <= 200; -- (200 Hz) -> (500000 flancos) -> (0.5 ms)
                    reloj_alarma_snooze_btnU <= btnU;
                    reloj_alarma_snooze_btnD <= btnD;
                    led(3 DOWNTO 0) <= "0000";
                    reloj_dcmotor_cont_horas_integer_dcmotor <= (reloj_dcmotor_cont_horas_decenas_integer * 10) + reloj_dcmotor_cont_horas_unidades_integer;
                    IF reloj_alarma_sonar = '0' THEN
                        reloj_dcmotor_cont_horas_unidades_integer <= conv_integer(reloj_cont_horas_unidades);
                        reloj_dcmotor_cont_horas_decenas_integer <= conv_integer(reloj_cont_horas_decenas);
                        reloj_dcmotor_duty_cycle <= reloj_dcmotor_cont_horas_integer_dcmotor * 99 / 23;
                    ELSE
                        reloj_dcmotor_cont_horas_unidades_integer <= conv_integer(reloj_cont_segs_unidades);
                        reloj_dcmotor_cont_horas_decenas_integer <= conv_integer(reloj_cont_segs_decenas);
                        reloj_dcmotor_duty_cycle <= reloj_dcmotor_cont_horas_integer_dcmotor * 99 / 59;
                    END IF;
                    --led(2 downto 0) <= std_logic_vector(to_unsigned(reloj_pila_stack_pointer, 3));
                    reloj_visualizar_pila <= sw(9);
                    reloj_pila_pop <= sw(10);
                    reloj_pila_push <= btnU;
                WHEN "01" => -- servomotor
                    servo_segundos_offset <= sw(11 DOWNTO 8);
                    servo_selector_aspersor_mode <= sw(7);
                    servo_selector_input_mode <= sw(6);
                    servo_botonMas <= sw(5);
                    servo_botonMenos <= sw(4);
                    servo_selector_switches <= sw(3 DOWNTO 0);
                    servo_freq_min <= 100000;
                    servo_contador_decenas_integer <= conv_integer(servo_contador_decenas);
                    servo_contador_centenas_integer <= conv_integer(servo_contador_centenas);
                    servo_numero_int <= ((servo_contador_centenas_integer * 10) + servo_contador_decenas_integer) * 10;
                    led(3 DOWNTO 0) <= "0000";
                    IF servo_segundos_offset = "XXX1" THEN
                        led(15 DOWNTO 12) <= "0001";
                    ELSIF servo_segundos_offset = "XX10" THEN
                        led(15 DOWNTO 12) <= "0010";
                    ELSIF servo_segundos_offset = "X100" THEN
                        led(15 DOWNTO 12) <= "0100";
                    ELSIF servo_segundos_offset = "1000" THEN
                        led(15 DOWNTO 12) <= "1000";
                    ELSE
                        led(15 DOWNTO 12) <= "0000";
                    END IF;
                WHEN "10" => -- bin-bcd
                    binario_bcd_binario <= sw(9 DOWNTO 0);
                    binario_bcd_enable <= sw(11);
                    binario_bcd_modo_lento_rapido <= sw(10);
                    led(15) <= binario_bcd_fin;
                    led(14) <= binario_bcd_modo_lento_rapido;
                    -- led(11 downto 0) <= binario_bcd_vector;
                WHEN OTHERS => -- cronometro
                    cronom_select_display_hhmm_ss <= sw(0);
                    cronom_func_btnU_stop <= btnU;
                    cronom_func_btnD_split <= btnD;
                    cronom_tope_freq <= 1000000;
                    led(3 DOWNTO 0) <= "0000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de la alarma

    PROCESS (reloj_alarma_switch_off_on, reloj_alarma_minutos_unidades,
        reloj_cont_mins_unidades, reloj_alarma_minutos_decenas, reloj_cont_mins_decenas,
        reloj_alarma_horas_unidades, reloj_cont_horas_unidades, reloj_alarma_horas_decenas,
        reloj_cont_horas_decenas)
    BEGIN
        IF reloj_alarma_switch_off_on = '0' THEN
            reloj_alarma_sonar <= '0';
        ELSE
            IF reloj_alarma_minutos_unidades = reloj_cont_mins_unidades AND
                reloj_alarma_minutos_decenas = reloj_cont_mins_decenas AND
                reloj_alarma_horas_unidades = reloj_cont_horas_unidades AND
                reloj_alarma_horas_decenas = reloj_cont_horas_decenas
                THEN
                reloj_alarma_sonar <= '1';
            ELSE
                reloj_alarma_sonar <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DEL 7-SEG
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    an <= enable_aux;

    -- process de conteo y modificacion del cont_base_enable (el que da la freq de 1kHz para cambio de seg)

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            cont_base_enable <= 0;
        ELSIF rising_edge(clk) THEN
            IF cont_base_enable = 100000 THEN
                cont_base_enable <= 0;
            ELSE
                cont_base_enable <= cont_base_enable + 1;
            END IF;
        END IF;
    END PROCESS;

    -- modificacion de la signal para ir de seg en seg (rotacion izquierda 1000 veces por segundo)

    PROCESS (btnC, clk)
    BEGIN
        IF btnC = '1' THEN
            enable_aux <= "1110";
        ELSIF rising_edge(clk) THEN
            IF cont_base_enable = 100000 THEN
                enable_aux <= enable_aux(2 DOWNTO 0) & enable_aux(3); -- desplazamiento a la izquierda
                -- enable_aux <= enable_aux(0) & enable_aux(3 downto 1); -- desplazamiento a la derecha
            END IF;
        END IF;
    END PROCESS;

    -- multiplexado de las entradas al 7-seg

    PROCESS (enable_aux, vector_modo, reloj_select_display_hhmm_ss, reloj_cont_centesimas,
        reloj_cont_decimas, reloj_cont_segs_unidades, reloj_cont_segs_decenas,
        reloj_cont_mins_unidades, reloj_cont_mins_decenas, reloj_cont_horas_unidades,
        reloj_cont_horas_decenas, servo_grados, binario_bcd_unidades,
        binario_bcd_decenas, binario_bcd_centenas, binario_bcd_millar, reloj_puesta_en_hora_switch, reloj_puesta_en_hora_dp_display_m_h,
        reloj_alarma_minutos_unidades, reloj_alarma_minutos_decenas, reloj_alarma_horas_unidades,
        reloj_alarma_horas_decenas, reloj_alarma_sonar, reloj_alarma_switch_settime, reloj_alarma_led,
        cronom_split, cronom_cont_centesimas_temp, cronom_cont_decimas_temp, cronom_cont_segs_unidades_temp,
        cronom_cont_segs_decenas_temp, cronom_select_display_hhmm_ss, cronom_cont_mins_unidades,
        cronom_cont_mins_decenas, cronom_cont_horas_unidades, cronom_cont_horas_decenas, cronom_cont_centesimas,
        cronom_cont_decimas, cronom_cont_segs_unidades, cronom_cont_segs_decenas, reloj_visualizar_pila, reloj_pila_salida)
    BEGIN
        IF vector_modo = "00" THEN -- reloj
            IF reloj_puesta_en_hora_switch = '1' THEN
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= reloj_cont_mins_unidades;
                        IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                            dp <= '0';
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= reloj_cont_mins_decenas;
                        dp <= '1';
                    WHEN "1011" =>
                        sal_mux <= reloj_cont_horas_unidades;
                        IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                            dp <= '0';
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= reloj_cont_horas_decenas;
                        dp <= '1';
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            ELSIF reloj_alarma_switch_settime = '1' THEN
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= reloj_alarma_minutos_unidades;
                        IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                            dp <= '0';
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= reloj_alarma_minutos_decenas;
                        dp <= '1';
                    WHEN "1011" =>
                        sal_mux <= reloj_alarma_horas_unidades;
                        IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                            dp <= '0';
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= reloj_alarma_horas_decenas;
                        dp <= '1';
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            ELSIF reloj_visualizar_pila = '1' THEN
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= reloj_pila_salida(3 DOWNTO 0);
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= reloj_pila_salida(7 DOWNTO 4);
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= reloj_pila_salida(11 DOWNTO 8);
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= reloj_pila_salida(15 DOWNTO 12);
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            ELSIF reloj_select_display_hhmm_ss = '0' THEN
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= reloj_cont_mins_unidades;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= reloj_cont_mins_decenas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= reloj_cont_horas_unidades;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= reloj_cont_horas_decenas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            ELSE
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= reloj_cont_centesimas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= reloj_cont_decimas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= reloj_cont_segs_unidades;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= reloj_cont_segs_decenas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            END IF;
        ELSIF vector_modo = "01" THEN -- servomotor
            IF servo_grados < 100 THEN
                CASE enable_aux IS
                    WHEN "0111" =>
                        sal_mux <= "1111";
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= STD_LOGIC_VECTOR(to_unsigned(servo_grados / 100, 4));
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= STD_LOGIC_VECTOR(to_unsigned(servo_grados / 10, 4));
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1110" =>
                        sal_mux <= "0000";
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "1111";
                        dp <= '1';
                END CASE;
            ELSE
                CASE enable_aux IS
                    WHEN "0111" =>
                        sal_mux <= "1111";
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= STD_LOGIC_VECTOR(to_unsigned(servo_grados / 100, 4));
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= STD_LOGIC_VECTOR(to_unsigned((servo_grados / 10) - 10, 4));
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1110" =>
                        sal_mux <= "0000";
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "1111";
                        dp <= '1';
                END CASE;
            END IF;
        ELSIF vector_modo = "10" THEN -- conversor bin-bcd
            CASE enable_aux IS
                WHEN "0111" =>
                    sal_mux <= binario_bcd_millar;
                    IF reloj_alarma_sonar = '1' THEN
                        dp <= reloj_alarma_led;
                    ELSE
                        dp <= '1';
                    END IF;
                WHEN "1011" =>
                    sal_mux <= binario_bcd_centenas;
                    IF reloj_alarma_sonar = '1' THEN
                        dp <= reloj_alarma_led;
                    ELSE
                        dp <= '1';
                    END IF;
                WHEN "1101" =>
                    sal_mux <= binario_bcd_decenas;
                    IF reloj_alarma_sonar = '1' THEN
                        dp <= reloj_alarma_led;
                    ELSE
                        dp <= '1';
                    END IF;
                WHEN "1110" =>
                    sal_mux <= binario_bcd_unidades;
                    IF reloj_alarma_sonar = '1' THEN
                        dp <= reloj_alarma_led;
                    ELSE
                        dp <= '1';
                    END IF;
                WHEN OTHERS =>
                    sal_mux <= "0000";
                    dp <= '1';
            END CASE;
        ELSE -- cronometro
            IF cronom_split = '1' THEN
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= cronom_cont_centesimas_temp;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= cronom_cont_decimas_temp;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= cronom_cont_segs_unidades_temp;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= cronom_cont_segs_decenas_temp;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            ELSIF cronom_select_display_hhmm_ss = '1' THEN
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= cronom_cont_mins_unidades;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= cronom_cont_mins_decenas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= cronom_cont_horas_unidades;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= cronom_cont_horas_decenas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            ELSE
                CASE enable_aux IS
                    WHEN "1110" =>
                        sal_mux <= cronom_cont_centesimas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1101" =>
                        sal_mux <= cronom_cont_decimas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "1011" =>
                        sal_mux <= cronom_cont_segs_unidades;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN "0111" =>
                        sal_mux <= cronom_cont_segs_decenas;
                        IF reloj_alarma_sonar = '1' THEN
                            dp <= reloj_alarma_led;
                        ELSE
                            dp <= '1';
                        END IF;
                    WHEN OTHERS =>
                        sal_mux <= "0000";
                        dp <= '1';
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de display de diferentes valores en diferentes siete_segs

    PROCESS (sal_mux)
    BEGIN
        CASE sal_mux IS
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
    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DEL RELOJ
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    -- process de reloj

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_base <= 0;
        ELSIF rising_edge(clk) THEN
            IF reloj_cont_base = reloj_tope_freq THEN
                reloj_cont_base <= 0;
            ELSE
                reloj_cont_base <= reloj_cont_base + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de cambio de vel.

    PROCESS (reloj_fast)
    BEGIN
        IF reloj_fast = '0' THEN
            reloj_tope_freq <= 1000000;
        ELSE
            reloj_tope_freq <= 500;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.centesimas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_centesimas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas
                IF reloj_cont_base = reloj_tope_freq THEN
                    IF reloj_cont_centesimas = "1001" THEN
                        reloj_cont_centesimas <= "0000";
                    ELSE
                        reloj_cont_centesimas <= reloj_cont_centesimas + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.decimas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_decimas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" THEN
                    IF reloj_cont_decimas = "1001" THEN
                        reloj_cont_decimas <= "0000";
                    ELSE
                        reloj_cont_decimas <= reloj_cont_decimas + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.unidades

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_segs_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" AND reloj_cont_decimas = "1001" THEN
                    IF reloj_cont_segs_unidades = "1001" THEN
                        reloj_cont_segs_unidades <= "0000";
                    ELSE
                        reloj_cont_segs_unidades <= reloj_cont_segs_unidades + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.decenas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_segs_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" AND reloj_cont_decimas = "1001" AND reloj_cont_segs_unidades = "1001" THEN
                    IF reloj_cont_segs_decenas = "0101" THEN
                        reloj_cont_segs_decenas <= "0000";
                    ELSE
                        reloj_cont_segs_decenas <= reloj_cont_segs_decenas + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de minutos.unidades

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_mins_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" AND reloj_cont_decimas = "1001" AND reloj_cont_segs_unidades = "1001" AND reloj_cont_segs_decenas = "0101" THEN
                    IF reloj_cont_mins_unidades = "1001" THEN
                        reloj_cont_mins_unidades <= "0000";
                    ELSE
                        reloj_cont_mins_unidades <= reloj_cont_mins_unidades + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' THEN
                            IF reloj_cont_mins_unidades = 9 AND reloj_cont_mins_decenas < 5 THEN
                                reloj_cont_mins_unidades <= "0000";
                            ELSIF reloj_cont_mins_unidades = 9 AND reloj_cont_mins_decenas = 5 THEN
                                reloj_cont_mins_unidades <= "1001";
                            ELSE
                                reloj_cont_mins_unidades <= reloj_cont_mins_unidades + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' THEN
                            IF reloj_cont_mins_unidades = 0 AND reloj_cont_mins_decenas > 0 THEN
                                reloj_cont_mins_unidades <= "1001";
                            ELSIF reloj_cont_mins_unidades = 0 AND reloj_cont_mins_decenas = 0 THEN
                                reloj_cont_mins_unidades <= "0000";
                            ELSE
                                reloj_cont_mins_unidades <= reloj_cont_mins_unidades - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de minutos.decenas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_mins_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5 y las minutos.unidades = 9
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" AND reloj_cont_decimas = "1001" AND reloj_cont_segs_unidades = "1001" AND reloj_cont_segs_decenas = "0101" AND reloj_cont_mins_unidades = "1001" THEN
                    IF reloj_cont_mins_decenas = "0101" THEN
                        reloj_cont_mins_decenas <= "0000";
                    ELSE
                        reloj_cont_mins_decenas <= reloj_cont_mins_decenas + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' AND reloj_cont_mins_unidades = 9 THEN
                            IF reloj_cont_mins_decenas = 5 THEN
                                reloj_cont_mins_decenas <= "0101";
                            ELSE
                                reloj_cont_mins_decenas <= reloj_cont_mins_decenas + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' AND reloj_cont_mins_unidades = 0 THEN
                            IF reloj_cont_mins_decenas = 0 THEN
                                reloj_cont_mins_decenas <= "0000";
                            ELSE
                                reloj_cont_mins_decenas <= reloj_cont_mins_decenas - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de horas.unidades

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_horas_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" AND reloj_cont_decimas = "1001" AND reloj_cont_segs_unidades = "1001" AND reloj_cont_segs_decenas = "0101" AND reloj_cont_mins_unidades = "1001" AND reloj_cont_mins_decenas = "0101" THEN
                    IF reloj_cont_horas_unidades = "1001" THEN
                        reloj_cont_horas_unidades <= "0000";
                    ELSIF reloj_cont_horas_unidades = "0011" AND reloj_cont_horas_decenas = "0010" THEN
                        reloj_cont_horas_unidades <= "0000";
                    ELSE
                        reloj_cont_horas_unidades <= reloj_cont_horas_unidades + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' THEN
                            IF reloj_cont_horas_unidades = 9 AND reloj_cont_horas_decenas < 2 THEN
                                reloj_cont_horas_unidades <= "0000";
                            ELSIF reloj_cont_horas_unidades = 3 AND reloj_cont_horas_decenas = 2 THEN
                                reloj_cont_horas_unidades <= "0011";
                            ELSE
                                reloj_cont_horas_unidades <= reloj_cont_horas_unidades + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' THEN
                            IF reloj_cont_horas_unidades = 0 AND reloj_cont_horas_decenas > 0 THEN
                                reloj_cont_horas_unidades <= "1001";
                            ELSIF reloj_cont_horas_unidades = 0 AND reloj_cont_horas_decenas = 0 THEN
                                reloj_cont_horas_unidades <= "0000";
                            ELSE
                                reloj_cont_horas_unidades <= reloj_cont_horas_unidades - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de horas.decenas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_cont_horas_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pausa = '0' AND reloj_puesta_en_hora_switch = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5 y las horas.unidades = 9 or 3
                IF reloj_cont_base = reloj_tope_freq AND reloj_cont_centesimas = "1001" AND reloj_cont_decimas = "1001" AND reloj_cont_segs_unidades = "1001" AND reloj_cont_segs_decenas = "0101" AND reloj_cont_mins_unidades = "1001" AND reloj_cont_mins_decenas = "0101" AND (reloj_cont_horas_unidades = "1001" OR reloj_cont_horas_unidades = "0011") THEN
                    IF reloj_cont_horas_decenas = "0010" THEN
                        reloj_cont_horas_decenas <= "0000";
                    ELSIF reloj_cont_horas_unidades = "1001" THEN
                        reloj_cont_horas_decenas <= reloj_cont_horas_decenas + 1;
                    END IF;
                END IF;
            ELSIF reloj_pausa = '1' THEN
                -- hacer cosas
            ELSIF reloj_puesta_en_hora_switch = '1' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' AND reloj_cont_horas_unidades = 9 THEN
                            IF reloj_cont_horas_decenas = 2 THEN
                                reloj_cont_horas_decenas <= "0010";
                            ELSE
                                reloj_cont_horas_decenas <= reloj_cont_horas_decenas + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' AND reloj_cont_horas_unidades = 0 THEN
                            IF reloj_cont_horas_decenas = 0 THEN
                                reloj_cont_horas_decenas <= "0000";
                            ELSE
                                reloj_cont_horas_decenas <= reloj_cont_horas_decenas - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de alarma.minutos.unidades

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_minutos_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_alarma_switch_settime = '1' AND reloj_puesta_en_hora_switch = '0' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' THEN
                            IF reloj_alarma_minutos_unidades = 9 AND reloj_alarma_minutos_decenas < 5 THEN
                                reloj_alarma_minutos_unidades <= "0000";
                            ELSIF reloj_alarma_minutos_unidades = 9 AND reloj_alarma_minutos_decenas = 5 THEN
                                reloj_alarma_minutos_unidades <= "1001";
                            ELSE
                                reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' THEN
                            IF reloj_alarma_minutos_unidades = 0 AND reloj_alarma_minutos_decenas > 0 THEN
                                reloj_alarma_minutos_unidades <= "1001";
                            ELSIF reloj_alarma_minutos_unidades = 0 AND reloj_alarma_minutos_decenas = 0 THEN
                                reloj_alarma_minutos_unidades <= "0000";
                            ELSE
                                reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF reloj_alarma_sonar = '1' THEN
                IF reloj_alarma_snooze_salida = '1' THEN
                    IF reloj_alarma_snooze_salida_suma = '1' OR reloj_alarma_snooze_salida_resta = '1' THEN
                        IF reloj_alarma_minutos_unidades >= 5 THEN
                            reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades - 5;
                        ELSIF reloj_alarma_minutos_unidades < 5 THEN
                            reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades + 5;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de alarma.minutos.decenas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_minutos_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_alarma_switch_settime = '1' AND reloj_puesta_en_hora_switch = '0' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' AND reloj_alarma_minutos_unidades = 9 THEN
                            IF reloj_alarma_minutos_decenas = 5 THEN
                                reloj_alarma_minutos_decenas <= "0101";
                            ELSE
                                reloj_alarma_minutos_decenas <= reloj_alarma_minutos_decenas + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' AND reloj_alarma_minutos_unidades = 0 THEN
                            IF reloj_alarma_minutos_decenas = 0 THEN
                                reloj_alarma_minutos_decenas <= "0000";
                            ELSE
                                reloj_alarma_minutos_decenas <= reloj_alarma_minutos_decenas - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF reloj_alarma_sonar = '1' THEN
                IF reloj_alarma_snooze_salida = '1' THEN
                    IF reloj_alarma_snooze_salida_suma = '1' OR reloj_alarma_snooze_salida_resta = '1' THEN
                        IF reloj_alarma_minutos_unidades >= 5 THEN
                            IF reloj_alarma_minutos_decenas < 5 THEN
                                reloj_alarma_minutos_decenas <= reloj_alarma_minutos_decenas + 1;
                            ELSE
                                reloj_alarma_minutos_decenas <= "0000";
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de alarma.horas.unidades

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_horas_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_alarma_switch_settime = '1' AND reloj_puesta_en_hora_switch = '0' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' THEN
                            IF reloj_alarma_horas_unidades = 9 AND reloj_alarma_horas_decenas < 2 THEN
                                reloj_alarma_horas_unidades <= "0000";
                            ELSIF reloj_alarma_horas_unidades = 3 AND reloj_alarma_horas_decenas = 2 THEN
                                reloj_alarma_horas_unidades <= "0011";
                            ELSE
                                reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' THEN
                            IF reloj_alarma_horas_unidades = 0 AND reloj_alarma_horas_decenas > 0 THEN
                                reloj_alarma_horas_unidades <= "1001";
                            ELSIF reloj_alarma_horas_unidades = 0 AND reloj_alarma_horas_decenas = 0 THEN
                                reloj_alarma_horas_unidades <= "0000";
                            ELSE
                                reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF reloj_alarma_sonar = '1' THEN
                IF reloj_alarma_snooze_salida = '1' THEN
                    IF reloj_alarma_snooze_salida_suma = '1' OR reloj_alarma_snooze_salida_resta = '1' THEN
                        IF reloj_alarma_minutos_unidades >= 5 THEN
                            IF reloj_alarma_minutos_decenas = 5 THEN
                                IF reloj_alarma_horas_decenas < 2 THEN
                                    IF reloj_alarma_horas_unidades < 9 THEN
                                        reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades + 1;
                                    ELSE
                                        reloj_alarma_horas_unidades <= "0000";
                                    END IF;
                                ELSE
                                    IF reloj_alarma_horas_unidades < 3 THEN
                                        reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades + 1;
                                    ELSE
                                        reloj_alarma_horas_unidades <= "0000";
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de alarma.horas.decenas

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_horas_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_alarma_switch_settime = '1' AND reloj_puesta_en_hora_switch = '0' THEN
                IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                    IF reloj_puesta_en_hora_flag_salida = '1' THEN
                        IF reloj_puesta_en_hora_flag_suma = '1' AND reloj_alarma_horas_unidades = 9 THEN
                            IF reloj_alarma_horas_decenas = 2 THEN
                                reloj_alarma_horas_decenas <= "0010";
                            ELSE
                                reloj_alarma_horas_decenas <= reloj_alarma_horas_decenas + 1;
                            END IF;
                        ELSIF reloj_puesta_en_hora_flag_resta = '1' AND reloj_alarma_horas_unidades = 0 THEN
                            IF reloj_alarma_horas_decenas = 0 THEN
                                reloj_alarma_horas_decenas <= "0000";
                            ELSE
                                reloj_alarma_horas_decenas <= reloj_alarma_horas_decenas - 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF reloj_alarma_sonar = '1' THEN
                IF reloj_alarma_snooze_salida = '1' THEN
                    IF reloj_alarma_snooze_salida_suma = '1' OR reloj_alarma_snooze_salida_resta = '1' THEN
                        IF reloj_alarma_minutos_unidades >= 5 THEN
                            IF reloj_alarma_minutos_decenas = 5 THEN
                                IF reloj_alarma_horas_decenas < 2 THEN
                                    IF reloj_alarma_horas_unidades = 9 THEN
                                        reloj_alarma_horas_decenas <= reloj_alarma_horas_decenas + 1;
                                    END IF;
                                ELSE
                                    IF reloj_alarma_horas_unidades = 3 THEN
                                        reloj_alarma_horas_decenas <= "0000";
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DEL MOTOR DC
    -- ####################################################################
    -- ####################################################################

    -- process del sentido de giro del motor

    PROCESS (reloj_dcmotor_sentido_giro, reloj_dcmotor_pwm_out)
    BEGIN
        IF reloj_dcmotor_sentido_giro = '0' THEN
            dcmotor <= "0" & reloj_dcmotor_pwm_out;
        ELSE
            dcmotor <= reloj_dcmotor_pwm_out & "0";
        END IF;
    END PROCESS;

    -- process de definicion de reloj_dcmotor_pwm_longitud_ciclo como (frecuencia base de
    -- la fpga) / (reloj_dcmotor_pwm_hz)

    PROCESS (reloj_dcmotor_pwm_hz)
    BEGIN
        reloj_dcmotor_pwm_longitud_ciclo <= 100000000 / reloj_dcmotor_pwm_hz;
    END PROCESS;

    -- process de definicion de reloj_dcmotor_pwm_longitud_pulso como porcentaje X de
    -- reloj_dcmotor_pwm_longitud_ciclo en funciรณn del valor de reloj_dcmotor_duty_cycle

    PROCESS (reloj_dcmotor_pwm_longitud_ciclo, reloj_dcmotor_duty_cycle)
    BEGIN
        reloj_dcmotor_pwm_longitud_pulso <= reloj_dcmotor_pwm_longitud_ciclo * reloj_dcmotor_duty_cycle / 100;
    END PROCESS;

    -- process del automata del pwm

    PROCESS (clk, reloj_inicio)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_dcmotor_estado_pwm <= "000";
            reloj_dcmotor_cont_flancos <= 0;
        ELSIF rising_edge(clk) THEN
            CASE reloj_dcmotor_estado_pwm IS
                WHEN "000" =>
                    reloj_dcmotor_cont_flancos <= 0;
                    IF reloj_dcmotor_duty_cycle /= 0 THEN
                        reloj_dcmotor_estado_pwm <= "001";
                    ELSE
                        reloj_dcmotor_estado_pwm <= "100";
                    END IF;
                WHEN "001" =>
                    reloj_dcmotor_cont_flancos <= 1;
                    reloj_dcmotor_estado_pwm <= "010";
                WHEN "010" =>
                    reloj_dcmotor_cont_flancos <= reloj_dcmotor_cont_flancos + 1;
                    IF reloj_dcmotor_cont_flancos < reloj_dcmotor_pwm_longitud_pulso THEN
                        reloj_dcmotor_estado_pwm <= "010";
                    ELSE
                        IF reloj_dcmotor_duty_cycle /= 100 THEN
                            reloj_dcmotor_estado_pwm <= "011";
                        ELSE
                            reloj_dcmotor_estado_pwm <= "001";
                        END IF;
                    END IF;
                WHEN "011" =>
                    reloj_dcmotor_cont_flancos <= reloj_dcmotor_cont_flancos + 1;
                    IF reloj_dcmotor_cont_flancos < reloj_dcmotor_pwm_longitud_ciclo THEN
                        reloj_dcmotor_estado_pwm <= "011";
                    ELSE
                        IF reloj_dcmotor_duty_cycle /= 0 THEN
                            reloj_dcmotor_estado_pwm <= "001";
                        ELSE
                            reloj_dcmotor_estado_pwm <= "100";
                        END IF;
                    END IF;
                WHEN "100" =>
                    reloj_dcmotor_cont_flancos <= 1;
                    reloj_dcmotor_estado_pwm <= "011";
                WHEN OTHERS =>
                    reloj_dcmotor_cont_flancos <= 0;
                    reloj_dcmotor_estado_pwm <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas del pwm

    PROCESS (reloj_dcmotor_estado_pwm)
    BEGIN
        CASE reloj_dcmotor_estado_pwm IS
            WHEN "000" => reloj_dcmotor_pwm_out <= '0';
            WHEN "001" => reloj_dcmotor_pwm_out <= '1';
            WHEN "010" => reloj_dcmotor_pwm_out <= '1';
            WHEN "011" => reloj_dcmotor_pwm_out <= '0';
            WHEN "100" => reloj_dcmotor_pwm_out <= '0';
            WHEN OTHERS => reloj_dcmotor_pwm_out <= '0';
        END CASE;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                    LOGICA DEL PULSADOR DE DEDO DP
    -- ####################################################################
    -- ####################################################################

    -- process del automata del pulsador

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_puesta_en_hora_dp_estado_pulsador <= "000";
            reloj_puesta_en_hora_dp_cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE reloj_puesta_en_hora_dp_estado_pulsador IS
                WHEN "000" => -- INICIO
                    reloj_puesta_en_hora_dp_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_dp_btnL = '1' OR reloj_puesta_en_hora_dp_btnR = '1' THEN
                        reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                    ELSE
                        reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    reloj_puesta_en_hora_dp_cont_filtro <= reloj_puesta_en_hora_dp_cont_filtro + 1;
                    IF (reloj_puesta_en_hora_dp_btnL = '1' OR reloj_puesta_en_hora_dp_btnR = '1') AND reloj_puesta_en_hora_dp_cont_filtro < 100000 THEN
                        reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                    ELSIF (reloj_puesta_en_hora_dp_btnL = '1' OR reloj_puesta_en_hora_dp_btnR = '1') AND reloj_puesta_en_hora_dp_cont_filtro = 100000 THEN
                        IF reloj_puesta_en_hora_dp_btnL = '1'THEN
                            reloj_puesta_en_hora_dp_estado_pulsador <= "010";
                        ELSIF reloj_puesta_en_hora_dp_btnR = '1' THEN
                            reloj_puesta_en_hora_dp_estado_pulsador <= "100";
                        END IF;
                    ELSE
                        reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    reloj_puesta_en_hora_dp_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_dp_btnL = '1' THEN
                        reloj_puesta_en_hora_dp_estado_pulsador <= "010";
                    ELSE
                        reloj_puesta_en_hora_dp_estado_pulsador <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    reloj_puesta_en_hora_dp_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_dp_btnL = '1' THEN
                        reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                    ELSE
                        reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    reloj_puesta_en_hora_dp_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_dp_btnR = '1' THEN
                        reloj_puesta_en_hora_dp_estado_pulsador <= "100";
                    ELSE
                        reloj_puesta_en_hora_dp_estado_pulsador <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    reloj_puesta_en_hora_dp_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_dp_btnR = '1' THEN
                        reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                    ELSE
                        reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                    END IF;
                WHEN OTHERS =>
                    reloj_puesta_en_hora_dp_cont_filtro <= 0;
                    reloj_puesta_en_hora_dp_estado_pulsador <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas del pulsador

    PROCESS (reloj_puesta_en_hora_dp_estado_pulsador)
    BEGIN
        CASE reloj_puesta_en_hora_dp_estado_pulsador IS
            WHEN "000" =>
                reloj_puesta_en_hora_dp_salida <= '0';
                reloj_puesta_en_hora_dp_flag_suma <= '0';
                reloj_puesta_en_hora_dp_flag_resta <= '0';
            WHEN "001" =>
                reloj_puesta_en_hora_dp_salida <= '0';
                reloj_puesta_en_hora_dp_flag_suma <= '0';
                reloj_puesta_en_hora_dp_flag_resta <= '0';
            WHEN "010" =>
                reloj_puesta_en_hora_dp_salida <= '0';
                reloj_puesta_en_hora_dp_flag_suma <= '0';
                reloj_puesta_en_hora_dp_flag_resta <= '0';
            WHEN "011" =>
                reloj_puesta_en_hora_dp_salida <= '1';
                reloj_puesta_en_hora_dp_flag_suma <= '1';
                reloj_puesta_en_hora_dp_flag_resta <= '0';
            WHEN "100" =>
                reloj_puesta_en_hora_dp_salida <= '0';
                reloj_puesta_en_hora_dp_flag_suma <= '0';
                reloj_puesta_en_hora_dp_flag_resta <= '0';
            WHEN "101" =>
                reloj_puesta_en_hora_dp_salida <= '1';
                reloj_puesta_en_hora_dp_flag_suma <= '0';
                reloj_puesta_en_hora_dp_flag_resta <= '1';
            WHEN OTHERS =>
                reloj_puesta_en_hora_dp_salida <= '0';
                reloj_puesta_en_hora_dp_flag_suma <= '0';
                reloj_puesta_en_hora_dp_flag_resta <= '0';
        END CASE;
    END PROCESS;

    -- process de sumar/restar el reloj_puesta_en_hora_dp_display_m_h

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_puesta_en_hora_dp_display_m_h <= '0';
        ELSIF rising_edge(clk) THEN
            IF reloj_puesta_en_hora_dp_salida = '1' THEN
                IF reloj_puesta_en_hora_dp_flag_suma = '1' THEN
                    -- sumar si esta a 0
                    IF reloj_puesta_en_hora_dp_display_m_h = '0' THEN
                        reloj_puesta_en_hora_dp_display_m_h <= '1';
                    END IF;
                ELSIF reloj_puesta_en_hora_dp_flag_resta = '1' THEN
                    -- restar si esta a 1
                    IF reloj_puesta_en_hora_dp_display_m_h = '1' THEN
                        reloj_puesta_en_hora_dp_display_m_h <= '0';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --             LOGICA DEL RELOJ - PULSADOR - SUMAR - RESTAR
    -- ####################################################################
    -- ####################################################################

    -- process del automata pulsador dedo

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_puesta_en_hora_estado_pulsador <= "000";
            reloj_puesta_en_hora_cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE reloj_puesta_en_hora_estado_pulsador IS
                WHEN "000" => -- INICIO
                    reloj_puesta_en_hora_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_sumar = '1' OR reloj_puesta_en_hora_restar = '1' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "001";
                    ELSE
                        reloj_puesta_en_hora_estado_pulsador <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                    IF (reloj_puesta_en_hora_sumar = '1' OR reloj_puesta_en_hora_restar = '1') AND reloj_puesta_en_hora_cont_filtro < 100000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "001";
                    ELSIF (reloj_puesta_en_hora_sumar = '1' OR reloj_puesta_en_hora_restar = '1') AND reloj_puesta_en_hora_cont_filtro = 100000 THEN
                        IF reloj_puesta_en_hora_sumar = '1'THEN
                            reloj_puesta_en_hora_estado_pulsador <= "010";
                        ELSIF reloj_puesta_en_hora_restar = '1' THEN
                            reloj_puesta_en_hora_estado_pulsador <= "100";
                        END IF;
                    ELSE
                        reloj_puesta_en_hora_estado_pulsador <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                    IF reloj_puesta_en_hora_sumar = '1' AND reloj_puesta_en_hora_cont_filtro < 200000000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "010";
                    ELSIF reloj_puesta_en_hora_sumar = '1' AND reloj_puesta_en_hora_cont_filtro = 200000000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "110";
                    ELSIF reloj_puesta_en_hora_sumar = '0' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    reloj_puesta_en_hora_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_sumar = '1' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "001";
                    ELSE
                        reloj_puesta_en_hora_estado_pulsador <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                    IF reloj_puesta_en_hora_restar = '1' AND reloj_puesta_en_hora_cont_filtro < 200000000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "100";
                    ELSIF reloj_puesta_en_hora_restar = '1' AND reloj_puesta_en_hora_cont_filtro = 200000000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "110";
                    ELSIF reloj_puesta_en_hora_restar = '0' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    reloj_puesta_en_hora_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_restar = '1' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "001";
                    ELSE
                        reloj_puesta_en_hora_estado_pulsador <= "000";
                    END IF;
                WHEN "110" => -- START_RAPIDO
                    reloj_puesta_en_hora_cont_filtro <= 0;
                    IF reloj_puesta_en_hora_sumar = '1' OR reloj_puesta_en_hora_restar = '1' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "111";
                    ELSIF reloj_puesta_en_hora_sumar = '0' AND reloj_puesta_en_hora_restar = '0' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "000";
                    END IF;
                WHEN OTHERS => -- RAPIDO
                    reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                    IF (reloj_puesta_en_hora_sumar = '1' OR reloj_puesta_en_hora_restar = '1') AND reloj_puesta_en_hora_cont_filtro < 20000000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "111";
                    ELSIF (reloj_puesta_en_hora_sumar = '1' OR reloj_puesta_en_hora_restar = '1') AND reloj_puesta_en_hora_cont_filtro = 20000000 THEN
                        reloj_puesta_en_hora_estado_pulsador <= "110";
                    ELSIF reloj_puesta_en_hora_sumar = '0' AND reloj_puesta_en_hora_restar = '0' THEN
                        reloj_puesta_en_hora_estado_pulsador <= "000";
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas pulsador dedo

    PROCESS (reloj_puesta_en_hora_estado_pulsador, reloj_puesta_en_hora_sumar, reloj_puesta_en_hora_restar, reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_puesta_en_hora_flag_salida <= '0';
            reloj_puesta_en_hora_flag_suma <= '0';
            reloj_puesta_en_hora_flag_resta <= '0';
        ELSIF rising_edge(clk) THEN
            CASE reloj_puesta_en_hora_estado_pulsador IS
                WHEN "000" =>
                    reloj_puesta_en_hora_flag_salida <= '0';
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '0';
                WHEN "001" =>
                    reloj_puesta_en_hora_flag_salida <= '0';
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '0';
                WHEN "010" =>
                    reloj_puesta_en_hora_flag_salida <= '0';
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '0';
                WHEN "011" =>
                    reloj_puesta_en_hora_flag_salida <= '1';
                    reloj_puesta_en_hora_flag_suma <= '1';
                    reloj_puesta_en_hora_flag_resta <= '0';
                WHEN "100" =>
                    reloj_puesta_en_hora_flag_salida <= '0';
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '0';
                WHEN "101" =>
                    reloj_puesta_en_hora_flag_salida <= '1';
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '1';
                WHEN "110" =>
                    reloj_puesta_en_hora_flag_salida <= '1';
                    IF reloj_puesta_en_hora_sumar = '1' THEN
                        reloj_puesta_en_hora_flag_suma <= '1';
                        reloj_puesta_en_hora_flag_resta <= '0';
                    ELSIF reloj_puesta_en_hora_restar = '1' THEN
                        reloj_puesta_en_hora_flag_suma <= '0';
                        reloj_puesta_en_hora_flag_resta <= '1';
                    END IF;
                WHEN OTHERS =>
                    reloj_puesta_en_hora_flag_salida <= '0';
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '0';
            END CASE;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                          LED DE LA ALARMA
    -- ####################################################################
    -- ####################################################################

    -- process del automata de la alarma del reloj

    PROCESS (clk, reloj_inicio, reloj_alarma_sonar)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_led_estado <= "00";
            reloj_alarma_led_contflancos <= 0;
        ELSIF rising_edge(clk) THEN
            IF reloj_alarma_sonar = '1' THEN
                CASE reloj_alarma_led_estado IS
                    WHEN "00" =>
                        reloj_alarma_led_contflancos <= 0;
                        reloj_alarma_led_estado <= "01";
                    WHEN "01" =>
                        reloj_alarma_led_contflancos <= 1;
                        reloj_alarma_led_estado <= "10";
                    WHEN "10" =>
                        reloj_alarma_led_contflancos <= reloj_alarma_led_contflancos + 1;
                        IF reloj_alarma_led_contflancos = 50000000 THEN
                            reloj_alarma_led_estado <= "11";
                        ELSE
                            reloj_alarma_led_estado <= "10";
                        END IF;
                    WHEN OTHERS =>
                        reloj_alarma_led_contflancos <= reloj_alarma_led_contflancos + 1;
                        IF reloj_alarma_led_contflancos = 100000000 THEN
                            reloj_alarma_led_estado <= "01";
                        ELSE
                            reloj_alarma_led_estado <= "11";
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- process de salidas del led de la alarma del reloj

    PROCESS (reloj_alarma_led_estado, reloj_alarma_sonar)
    BEGIN
        IF reloj_alarma_sonar = '1' THEN
            CASE reloj_alarma_led_estado IS
                WHEN "00" => reloj_alarma_led <= '0';
                WHEN "01" => reloj_alarma_led <= '1';
                WHEN "10" => reloj_alarma_led <= '1';
                WHEN OTHERS => reloj_alarma_led <= '0';
            END CASE;
        ELSE
            reloj_alarma_led <= '0';
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                          LOGICA DE SNOOZE
    -- ####################################################################
    -- ####################################################################

    -- process del automata del pulsador de snooze

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_snooze_estado_pulsador <= "000";
            reloj_alarma_snooze_cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE reloj_alarma_snooze_estado_pulsador IS
                WHEN "000" => -- INICIO
                    reloj_alarma_snooze_cont_filtro <= 0;
                    IF reloj_alarma_snooze_btnU = '1' OR reloj_alarma_snooze_btnD = '1' THEN
                        reloj_alarma_snooze_estado_pulsador <= "001";
                    ELSE
                        reloj_alarma_snooze_estado_pulsador <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    reloj_alarma_snooze_cont_filtro <= reloj_alarma_snooze_cont_filtro + 1;
                    IF (reloj_alarma_snooze_btnU = '1' OR reloj_alarma_snooze_btnD = '1') AND reloj_alarma_snooze_cont_filtro < 100000 THEN
                        reloj_alarma_snooze_estado_pulsador <= "001";
                    ELSIF (reloj_alarma_snooze_btnU = '1' OR reloj_alarma_snooze_btnD = '1') AND reloj_alarma_snooze_cont_filtro = 100000 THEN
                        IF reloj_alarma_snooze_btnU = '1'THEN
                            reloj_alarma_snooze_estado_pulsador <= "010";
                        ELSIF reloj_alarma_snooze_btnD = '1' THEN
                            reloj_alarma_snooze_estado_pulsador <= "100";
                        END IF;
                    ELSE
                        reloj_alarma_snooze_estado_pulsador <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    reloj_alarma_snooze_cont_filtro <= 0;
                    IF reloj_alarma_snooze_btnU = '1' THEN
                        reloj_alarma_snooze_estado_pulsador <= "010";
                    ELSE
                        reloj_alarma_snooze_estado_pulsador <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    reloj_alarma_snooze_cont_filtro <= 0;
                    IF reloj_alarma_snooze_btnU = '1' THEN
                        reloj_alarma_snooze_estado_pulsador <= "001";
                    ELSE
                        reloj_alarma_snooze_estado_pulsador <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    reloj_alarma_snooze_cont_filtro <= 0;
                    IF reloj_alarma_snooze_btnD = '1' THEN
                        reloj_alarma_snooze_estado_pulsador <= "100";
                    ELSE
                        reloj_alarma_snooze_estado_pulsador <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    reloj_alarma_snooze_cont_filtro <= 0;
                    IF reloj_alarma_snooze_btnD = '1' THEN
                        reloj_alarma_snooze_estado_pulsador <= "001";
                    ELSE
                        reloj_alarma_snooze_estado_pulsador <= "000";
                    END IF;
                WHEN OTHERS =>
                    reloj_alarma_snooze_cont_filtro <= 0;
                    reloj_alarma_snooze_estado_pulsador <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas del pulsador de snooze

    PROCESS (reloj_alarma_snooze_estado_pulsador, clk, reloj_inicio)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_alarma_snooze_salida <= '0';
            reloj_alarma_snooze_salida_suma <= '0';
            reloj_alarma_snooze_salida_resta <= '0';
        ELSIF rising_edge(clk) THEN
            CASE reloj_alarma_snooze_estado_pulsador IS
                WHEN "000" =>
                    reloj_alarma_snooze_salida <= '0';
                    reloj_alarma_snooze_salida_suma <= '0';
                    reloj_alarma_snooze_salida_resta <= '0';
                WHEN "001" =>
                    reloj_alarma_snooze_salida <= '0';
                    reloj_alarma_snooze_salida_suma <= '0';
                    reloj_alarma_snooze_salida_resta <= '0';
                WHEN "010" =>
                    reloj_alarma_snooze_salida <= '0';
                    reloj_alarma_snooze_salida_suma <= '0';
                    reloj_alarma_snooze_salida_resta <= '0';
                WHEN "011" =>
                    reloj_alarma_snooze_salida <= '1';
                    reloj_alarma_snooze_salida_suma <= '1';
                    reloj_alarma_snooze_salida_resta <= '0';
                WHEN "100" =>
                    reloj_alarma_snooze_salida <= '0';
                    reloj_alarma_snooze_salida_suma <= '0';
                    reloj_alarma_snooze_salida_resta <= '0';
                WHEN "101" =>
                    reloj_alarma_snooze_salida <= '1';
                    reloj_alarma_snooze_salida_suma <= '0';
                    reloj_alarma_snooze_salida_resta <= '1';
                WHEN OTHERS =>
                    reloj_alarma_snooze_salida <= '0';
                    reloj_alarma_snooze_salida_suma <= '0';
                    reloj_alarma_snooze_salida_resta <= '0';
            END CASE;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DEL SERVOMOTOR
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    -- process de designacion de servo_grados por tiempo/switches/dedo

    PROCESS (servo_selector_aspersor_mode, servo_aspersor_cont,
        servo_selector_input_mode, servo_selector_switches, servo_suma_o_resta,
        servo_numero_int, reloj_alarma_sonar)
    BEGIN

        -- servo_grados por aspersor

        IF servo_selector_aspersor_mode = '1' OR reloj_alarma_sonar = '1' THEN
            CASE servo_aspersor_cont IS
                WHEN "0000" => servo_grados <= 10;
                WHEN "0001" => servo_grados <= 20;
                WHEN "0010" => servo_grados <= 30;
                WHEN "0011" => servo_grados <= 40;
                WHEN "0100" => servo_grados <= 50;
                WHEN "0101" => servo_grados <= 60;
                WHEN "0110" => servo_grados <= 70;
                WHEN "0111" => servo_grados <= 80;
                WHEN "1000" => servo_grados <= 90;
                WHEN "1001" => servo_grados <= 100;
                WHEN "1010" => servo_grados <= 110;
                WHEN "1011" => servo_grados <= 120;
                WHEN "1100" => servo_grados <= 130;
                WHEN "1101" => servo_grados <= 140;
                WHEN "1110" => servo_grados <= 150;
                WHEN OTHERS => servo_grados <= 170;
            END CASE;

            -- servo_grados por switches

        ELSIF servo_selector_input_mode = '0' THEN
            CASE servo_selector_switches IS
                WHEN "0000" => servo_grados <= 10;
                WHEN "0001" => servo_grados <= 20;
                WHEN "0010" => servo_grados <= 30;
                WHEN "0011" => servo_grados <= 40;
                WHEN "0100" => servo_grados <= 50;
                WHEN "0101" => servo_grados <= 60;
                WHEN "0110" => servo_grados <= 70;
                WHEN "0111" => servo_grados <= 80;
                WHEN "1000" => servo_grados <= 90;
                WHEN "1001" => servo_grados <= 100;
                WHEN "1010" => servo_grados <= 110;
                WHEN "1011" => servo_grados <= 120;
                WHEN "1100" => servo_grados <= 130;
                WHEN "1101" => servo_grados <= 140;
                WHEN "1110" => servo_grados <= 150;
                WHEN OTHERS => servo_grados <= 170;
            END CASE;

            -- servo_grados por dedo

        ELSE
            servo_grados <= servo_numero_int;
        END IF;
    END PROCESS;

    -- process del automata del pwm del servo

    PROCESS (clk, servo_inicio)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_estado_servo <= "00";
            servo_cont_flancos <= 0;
        ELSIF rising_edge(clk) THEN
            CASE servo_estado_servo IS
                WHEN "00" =>
                    servo_cont_flancos <= 0;
                    servo_estado_servo <= "01";
                WHEN "01" =>
                    servo_cont_flancos <= 1;
                    servo_estado_servo <= "10";
                WHEN "10" =>
                    servo_cont_flancos <= servo_cont_flancos + 1;
                    IF servo_cont_flancos = servo_pwm_longitud_pulso THEN
                        servo_estado_servo <= "11";
                    ELSE
                        servo_estado_servo <= "10";
                    END IF;
                WHEN OTHERS =>
                    servo_cont_flancos <= servo_cont_flancos + 1;
                    IF servo_cont_flancos = 2000000 THEN
                        servo_estado_servo <= "01";
                    ELSE
                        servo_estado_servo <= "11";
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    -- process de salidas del servo

    PROCESS (servo_estado_servo)
    BEGIN
        CASE servo_estado_servo IS
            WHEN "00" => servo <= '0';
            WHEN "01" => servo <= '1';
            WHEN "10" => servo <= '1';
            WHEN OTHERS => servo <= '0';
        END CASE;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                       LOGICA DEL SERVO-RELOJ
    -- ####################################################################
    -- ####################################################################

    -- proceso de reloj

    PROCESS (servo_inicio, clk)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_cont_base <= 0;
        ELSIF rising_edge(clk) THEN
            IF servo_cont_base = servo_tope_freq THEN
                servo_cont_base <= 0;
            ELSE
                servo_cont_base <= servo_cont_base + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de cambio de vel.

    PROCESS (servo_segundos_offset)
    BEGIN
        IF servo_segundos_offset = "XXX1" THEN
            servo_tope_freq <= 100000000;
        ELSIF servo_segundos_offset = "XX10" THEN
            servo_tope_freq <= 200000000;
        ELSIF servo_segundos_offset = "X100" THEN
            servo_tope_freq <= 300000000;
        ELSIF servo_segundos_offset = "1000" THEN
            servo_tope_freq <= 400000000;
        ELSE
            servo_tope_freq <= 100000000;
        END IF;
    END PROCESS;

    -- process de cambio de servo_aspersor_cont

    PROCESS (servo_inicio, clk)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_suma_o_resta <= '0';
            servo_aspersor_cont <= "0000";
        ELSIF rising_edge(clk) THEN
            IF servo_selector_aspersor_mode = '1' OR reloj_alarma_sonar = '1' THEN
                IF servo_cont_base = servo_tope_freq THEN
                    IF servo_aspersor_cont = "1111" THEN
                        servo_suma_o_resta <= '1';
                    ELSIF servo_aspersor_cont = "0000" THEN
                        servo_suma_o_resta <= '0';
                    END IF;
                    IF servo_suma_o_resta = '0' AND servo_aspersor_cont /= "1111" THEN
                        servo_aspersor_cont <= servo_aspersor_cont + 1;
                    ELSIF servo_suma_o_resta = '1' AND servo_aspersor_cont /= "0000" THEN
                        servo_aspersor_cont <= servo_aspersor_cont - 1;
                    END IF;
                END IF;
            ELSE
                servo_suma_o_resta <= '0';
                servo_aspersor_cont <= "0000";
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                      LOGICA DEL SERVO-PULSADOR
    -- ####################################################################
    -- ####################################################################

    -- process del automata pulsador dedo

    PROCESS (servo_inicio, clk)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_estado_pulsador <= "000";
            servo_cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE servo_estado_pulsador IS
                WHEN "000" => -- INICIO
                    servo_cont_filtro <= 0;
                    IF servo_botonMas = '1' OR servo_botonMenos = '1' THEN
                        servo_estado_pulsador <= "001";
                    ELSE
                        servo_estado_pulsador <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    servo_cont_filtro <= servo_cont_filtro + 1;
                    IF (servo_botonMas = '1' OR servo_botonMenos = '1') AND servo_cont_filtro < servo_freq_min THEN
                        servo_estado_pulsador <= "001";
                    ELSIF (servo_botonMas = '1' OR servo_botonMenos = '1') AND servo_cont_filtro = servo_freq_min THEN
                        IF servo_botonMas = '1'THEN
                            servo_estado_pulsador <= "010";
                        ELSIF servo_botonMenos = '1' THEN
                            servo_estado_pulsador <= "100";
                        END IF;
                    ELSE
                        servo_estado_pulsador <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    servo_cont_filtro <= servo_cont_filtro + 1;
                    IF servo_botonMas = '1' AND servo_cont_filtro < 200000000 THEN
                        servo_estado_pulsador <= "010";
                    ELSIF servo_botonMas = '1' AND servo_cont_filtro = 200000000 THEN
                        servo_estado_pulsador <= "110";
                    ELSIF servo_botonMas = '0' THEN
                        servo_estado_pulsador <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    servo_cont_filtro <= 0;
                    IF servo_botonMas = '1' THEN
                        servo_estado_pulsador <= "001";
                    ELSE
                        servo_estado_pulsador <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    servo_cont_filtro <= servo_cont_filtro + 1;
                    IF servo_botonMenos = '1' AND servo_cont_filtro < 200000000 THEN
                        servo_estado_pulsador <= "100";
                    ELSIF servo_botonMenos = '1' AND servo_cont_filtro = 200000000 THEN
                        servo_estado_pulsador <= "110";
                    ELSIF servo_botonMenos = '0' THEN
                        servo_estado_pulsador <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    servo_cont_filtro <= 0;
                    IF servo_botonMenos = '1' THEN
                        servo_estado_pulsador <= "001";
                    ELSE
                        servo_estado_pulsador <= "000";
                    END IF;
                WHEN "110" => -- START_RAPIDO
                    servo_cont_filtro <= 0;
                    IF servo_botonMas = '1' OR servo_botonMenos = '1' THEN
                        servo_estado_pulsador <= "111";
                    ELSIF servo_botonMas = '0' AND servo_botonMenos = '0' THEN
                        servo_estado_pulsador <= "000";
                    END IF;
                WHEN OTHERS => -- RAPIDO
                    servo_cont_filtro <= servo_cont_filtro + 1;
                    IF (servo_botonMas = '1' OR servo_botonMenos = '1') AND servo_cont_filtro < 20000000 THEN
                        servo_estado_pulsador <= "111";
                    ELSIF (servo_botonMas = '1' OR servo_botonMenos = '1') AND servo_cont_filtro = 20000000 THEN
                        servo_estado_pulsador <= "110";
                    ELSIF servo_botonMas = '0' AND servo_botonMenos = '0' THEN
                        servo_estado_pulsador <= "000";
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas pulsador dedo

    PROCESS (servo_estado_pulsador, servo_botonMas, servo_botonMenos, servo_inicio, clk)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_salida <= '0';
            servo_flag_suma <= '0';
            servo_flag_resta <= '0';
        ELSIF rising_edge(clk) THEN
            CASE servo_estado_pulsador IS
                WHEN "000" =>
                    servo_salida <= '0';
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '0';
                WHEN "001" =>
                    servo_salida <= '0';
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '0';
                WHEN "010" =>
                    servo_salida <= '0';
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '0';
                WHEN "011" =>
                    servo_salida <= '1';
                    servo_flag_suma <= '1';
                    servo_flag_resta <= '0';
                WHEN "100" =>
                    servo_salida <= '0';
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '0';
                WHEN "101" =>
                    servo_salida <= '1';
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '1';
                WHEN "110" =>
                    servo_salida <= '1';
                    IF servo_botonMas = '1' THEN
                        servo_flag_suma <= '1';
                        servo_flag_resta <= '0';
                    ELSIF servo_botonMenos = '1' THEN
                        servo_flag_suma <= '0';
                        servo_flag_resta <= '1';
                    END IF;
                WHEN OTHERS =>
                    servo_salida <= '0';
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '0';
            END CASE;
        END IF;
    END PROCESS;

    -- process de sumar/restar decenas

    PROCESS (servo_inicio, clk)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_contador_decenas <= "0001";
        ELSIF rising_edge(clk) THEN
            IF servo_salida = '1' THEN
                IF servo_flag_suma = '1' THEN
                    IF servo_contador_decenas = 7 AND servo_contador_centenas = 1 THEN
                        servo_contador_decenas <= "0111";
                    ELSIF servo_contador_decenas = 9 THEN
                        servo_contador_decenas <= "0000";
                    ELSE
                        servo_contador_decenas <= servo_contador_decenas + 1;
                    END IF;
                ELSIF servo_flag_resta = '1' THEN
                    IF servo_contador_decenas = 1 AND servo_contador_centenas = 0 THEN
                        servo_contador_decenas <= "0001";
                    ELSIF servo_contador_decenas = 0 THEN
                        servo_contador_decenas <= "1001";
                    ELSE
                        servo_contador_decenas <= servo_contador_decenas - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- process de sumar/restar centenas

    PROCESS (servo_inicio, clk)
    BEGIN
        IF servo_inicio = '1' THEN
            servo_contador_centenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF servo_salida = '1' THEN
                IF servo_flag_suma = '1' THEN
                    IF servo_contador_decenas = 9 THEN
                        servo_contador_centenas <= servo_contador_centenas + 1;
                    END IF;
                ELSIF servo_flag_resta = '1' THEN
                    IF servo_contador_centenas = 1 AND servo_contador_decenas = 0 THEN
                        servo_contador_centenas <= servo_contador_centenas - 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DE CONVERSION
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    -- process del automata de la conversion

    PROCESS (clk, binario_bcd_inicio)
    BEGIN
        IF binario_bcd_inicio = '1' THEN
            binario_bcd_vector <= "00000000000000000000000000";
            binario_bcd_estado_conversion <= "00";
            binario_bcd_contador_desplazamientos <= 0;
            binario_bcd_unidades <= "0000";
            binario_bcd_decenas <= "0000";
            binario_bcd_centenas <= "0000";
            binario_bcd_millar <= "0000";
            binario_bcd_fin <= '0';
        ELSIF rising_edge(clk) THEN
            IF binario_bcd_cont = 0 AND binario_bcd_fin = '0' THEN
                CASE binario_bcd_estado_conversion IS
                        -- start
                    WHEN "00" =>
                        binario_bcd_contador_desplazamientos <= 0;
                        binario_bcd_vector <= "0000000000000000" & binario_bcd_binario;
                        IF binario_bcd_enable = '1' THEN
                            binario_bcd_estado_conversion <= "01";
                        ELSE
                            binario_bcd_estado_conversion <= "00";
                        END IF;
                        binario_bcd_fin <= '0';
                        -- despl
                    WHEN "01" =>
                        binario_bcd_contador_desplazamientos <= binario_bcd_contador_desplazamientos + 1;
                        binario_bcd_vector <= binario_bcd_vector(24 DOWNTO 0) & '0';
                        IF binario_bcd_contador_desplazamientos < 9 THEN
                            binario_bcd_estado_conversion <= "10";
                        ELSE
                            binario_bcd_estado_conversion <= "11";
                        END IF;
                        binario_bcd_fin <= '0';
                        -- ¿sumar+3?
                    WHEN "10" =>
                        binario_bcd_contador_desplazamientos <= binario_bcd_contador_desplazamientos;
                        IF binario_bcd_vector(13 DOWNTO 10) > 4 THEN
                            binario_bcd_vector(13 DOWNTO 10) <= binario_bcd_vector(13 DOWNTO 10) + "0011";
                        END IF;
                        IF binario_bcd_vector(17 DOWNTO 14) > 4 THEN
                            binario_bcd_vector(17 DOWNTO 14) <= binario_bcd_vector(17 DOWNTO 14) + "0011";
                        END IF;
                        IF binario_bcd_vector(21 DOWNTO 18) > 4 THEN
                            binario_bcd_vector(21 DOWNTO 18) <= binario_bcd_vector(21 DOWNTO 18) + "0011";
                        END IF;
                        IF binario_bcd_vector(25 DOWNTO 22) > 4 THEN
                            binario_bcd_vector(25 DOWNTO 22) <= binario_bcd_vector(25 DOWNTO 22) + "0011";
                        END IF;
                        binario_bcd_estado_conversion <= "01";
                        binario_bcd_fin <= '0';
                        -- final
                    WHEN OTHERS =>
                        binario_bcd_contador_desplazamientos <= binario_bcd_contador_desplazamientos;
                        binario_bcd_vector <= binario_bcd_vector;
                        binario_bcd_estado_conversion <= "00";
                        binario_bcd_fin <= '1';
                        binario_bcd_unidades <= binario_bcd_vector(13 DOWNTO 10);
                        binario_bcd_decenas <= binario_bcd_vector(17 DOWNTO 14);
                        binario_bcd_centenas <= binario_bcd_vector(21 DOWNTO 18);
                        binario_bcd_millar <= binario_bcd_vector(25 DOWNTO 22);
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- process de conteo de segundos

    PROCESS (clk, binario_bcd_inicio)
    BEGIN
        IF binario_bcd_inicio = '1' THEN
            binario_bcd_cont <= 0;
        ELSIF rising_edge(clk) THEN
            IF binario_bcd_cont = binario_bcd_tope_freq THEN
                binario_bcd_cont <= 0;
            ELSE
                binario_bcd_cont <= binario_bcd_cont + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de cambio de vel.

    PROCESS (binario_bcd_modo_lento_rapido)
    BEGIN
        IF binario_bcd_modo_lento_rapido = '1' THEN
            binario_bcd_tope_freq <= 0;
        ELSE
            binario_bcd_tope_freq <= 50000000;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DEL CRONOMETRO
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    -- process de variables temporales para el split del cronometro

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_centesimas_temp <= "0000";
            cronom_cont_decimas_temp <= "0000";
            cronom_cont_segs_unidades_temp <= "0000";
            cronom_cont_segs_decenas_temp <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_split = '0' THEN
                cronom_cont_centesimas_temp <= cronom_cont_centesimas;
                cronom_cont_decimas_temp <= cronom_cont_decimas;
                cronom_cont_segs_unidades_temp <= cronom_cont_segs_unidades;
                cronom_cont_segs_decenas_temp <= cronom_cont_segs_decenas;
            END IF;
        END IF;
    END PROCESS;

    -- process de reloj del cronometro

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_base <= 0;
        ELSIF rising_edge(clk) THEN
            IF cronom_cont_base = cronom_tope_freq THEN
                cronom_cont_base <= 0;
            ELSE
                cronom_cont_base <= cronom_cont_base + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.centesimas

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_centesimas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas
                IF cronom_cont_base = cronom_tope_freq THEN
                    IF cronom_cont_centesimas = "1001" THEN
                        cronom_cont_centesimas <= "0000";
                    ELSE
                        cronom_cont_centesimas <= cronom_cont_centesimas + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.decimas

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_decimas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" THEN
                    IF cronom_cont_decimas = "1001" THEN
                        cronom_cont_decimas <= "0000";
                    ELSE
                        cronom_cont_decimas <= cronom_cont_decimas + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.unidades

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_segs_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" AND cronom_cont_decimas = "1001" THEN
                    IF cronom_cont_segs_unidades = "1001" THEN
                        cronom_cont_segs_unidades <= "0000";
                    ELSE
                        cronom_cont_segs_unidades <= cronom_cont_segs_unidades + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de segundos.decenas

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_segs_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" AND cronom_cont_decimas = "1001" AND cronom_cont_segs_unidades = "1001" THEN
                    IF cronom_cont_segs_decenas = "0101" THEN
                        cronom_cont_segs_decenas <= "0000";
                    ELSE
                        cronom_cont_segs_decenas <= cronom_cont_segs_decenas + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de minutos.unidades

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_mins_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" AND cronom_cont_decimas = "1001" AND cronom_cont_segs_unidades = "1001" AND cronom_cont_segs_decenas = "0101" THEN
                    IF cronom_cont_mins_unidades = "1001" THEN
                        cronom_cont_mins_unidades <= "0000";
                    ELSE
                        cronom_cont_mins_unidades <= cronom_cont_mins_unidades + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de minutos.decenas

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_mins_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5 y las minutos.unidades = 9
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" AND cronom_cont_decimas = "1001" AND cronom_cont_segs_unidades = "1001" AND cronom_cont_segs_decenas = "0101" AND cronom_cont_mins_unidades = "1001" THEN
                    IF cronom_cont_mins_decenas = "0101" THEN
                        cronom_cont_mins_decenas <= "0000";
                    ELSE
                        cronom_cont_mins_decenas <= cronom_cont_mins_decenas + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de horas.unidades

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_horas_unidades <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" AND cronom_cont_decimas = "1001" AND cronom_cont_segs_unidades = "1001" AND cronom_cont_segs_decenas = "0101" AND cronom_cont_mins_unidades = "1001" AND cronom_cont_mins_decenas = "0101" THEN
                    IF cronom_cont_horas_unidades = "1001" THEN
                        cronom_cont_horas_unidades <= "0000";
                    ELSIF cronom_cont_horas_unidades = "0011" AND cronom_cont_horas_decenas = "0010" THEN
                        cronom_cont_horas_unidades <= "0000";
                    ELSE
                        cronom_cont_horas_unidades <= cronom_cont_horas_unidades + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- process de monitoreo de horas.decenas

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_cont_horas_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF cronom_pausa = '0' THEN
                -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
                -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5 y las horas.unidades = 9 or 3
                IF cronom_cont_base = cronom_tope_freq AND cronom_cont_centesimas = "1001" AND cronom_cont_decimas = "1001" AND cronom_cont_segs_unidades = "1001" AND cronom_cont_segs_decenas = "0101" AND cronom_cont_mins_unidades = "1001" AND cronom_cont_mins_decenas = "0101" AND (cronom_cont_horas_unidades = "1001" OR cronom_cont_horas_unidades = "0011") THEN
                    IF cronom_cont_horas_decenas = "0010" THEN
                        cronom_cont_horas_decenas <= "0000";
                    ELSIF cronom_cont_horas_unidades = "1001" THEN
                        cronom_cont_horas_decenas <= cronom_cont_horas_decenas + 1;
                    END IF;
                END IF;
            ELSIF cronom_pausa = '1' THEN
                -- hacer cosas
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                 LOGICA DEL PULSADOR DE DEDO STOP SPLIT
    -- ####################################################################
    -- ####################################################################

    -- process del automata del pulsador

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_func_estado_pulsador <= "000";
            cronom_func_cont_filtro <= 0;
        ELSIF rising_edge(clk) THEN
            CASE cronom_func_estado_pulsador IS
                WHEN "000" => -- INICIO
                    cronom_func_cont_filtro <= 0;
                    IF cronom_func_btnU_stop = '1' OR cronom_func_btnD_split = '1' THEN
                        cronom_func_estado_pulsador <= "001";
                    ELSE
                        cronom_func_estado_pulsador <= "000";
                    END IF;
                WHEN "001" => -- FILTRADO
                    cronom_func_cont_filtro <= cronom_func_cont_filtro + 1;
                    IF (cronom_func_btnU_stop = '1' OR cronom_func_btnD_split = '1') AND cronom_func_cont_filtro < 100000 THEN
                        cronom_func_estado_pulsador <= "001";
                    ELSIF (cronom_func_btnU_stop = '1' OR cronom_func_btnD_split = '1') AND cronom_func_cont_filtro = 100000 THEN
                        IF cronom_func_btnU_stop = '1'THEN
                            cronom_func_estado_pulsador <= "010";
                        ELSIF cronom_func_btnD_split = '1' THEN
                            cronom_func_estado_pulsador <= "100";
                        END IF;
                    ELSE
                        cronom_func_estado_pulsador <= "000";
                    END IF;
                WHEN "010" => -- UNO +
                    cronom_func_cont_filtro <= 0;
                    IF cronom_func_btnU_stop = '1' THEN
                        cronom_func_estado_pulsador <= "010";
                    ELSE
                        cronom_func_estado_pulsador <= "011";
                    END IF;
                WHEN "011" => -- SUMA
                    cronom_func_cont_filtro <= 0;
                    IF cronom_func_btnU_stop = '1' THEN
                        cronom_func_estado_pulsador <= "001";
                    ELSE
                        cronom_func_estado_pulsador <= "000";
                    END IF;
                WHEN "100" => -- UNO -
                    cronom_func_cont_filtro <= 0;
                    IF cronom_func_btnD_split = '1' THEN
                        cronom_func_estado_pulsador <= "100";
                    ELSE
                        cronom_func_estado_pulsador <= "101";
                    END IF;
                WHEN "101" => -- RESTA
                    cronom_func_cont_filtro <= 0;
                    IF cronom_func_btnD_split = '1' THEN
                        cronom_func_estado_pulsador <= "001";
                    ELSE
                        cronom_func_estado_pulsador <= "000";
                    END IF;
                WHEN OTHERS =>
                    cronom_func_cont_filtro <= 0;
                    cronom_func_estado_pulsador <= "000";
            END CASE;
        END IF;
    END PROCESS;

    -- process de las salidas del pulsador

    PROCESS (cronom_func_estado_pulsador)
    BEGIN
        CASE cronom_func_estado_pulsador IS
            WHEN "000" =>
                cronom_func_flag_salida <= '0';
                cronom_func_flag_salida_flag_pausa <= '0';
                cronom_func_flag_salida_flag_split <= '0';
            WHEN "001" =>
                cronom_func_flag_salida <= '0';
                cronom_func_flag_salida_flag_pausa <= '0';
                cronom_func_flag_salida_flag_split <= '0';
            WHEN "010" =>
                cronom_func_flag_salida <= '0';
                cronom_func_flag_salida_flag_pausa <= '0';
                cronom_func_flag_salida_flag_split <= '0';
            WHEN "011" =>
                cronom_func_flag_salida <= '1';
                cronom_func_flag_salida_flag_pausa <= '1';
                cronom_func_flag_salida_flag_split <= '0';
            WHEN "100" =>
                cronom_func_flag_salida <= '0';
                cronom_func_flag_salida_flag_pausa <= '0';
                cronom_func_flag_salida_flag_split <= '0';
            WHEN "101" =>
                cronom_func_flag_salida <= '1';
                cronom_func_flag_salida_flag_pausa <= '0';
                cronom_func_flag_salida_flag_split <= '1';
            WHEN OTHERS =>
                cronom_func_flag_salida <= '0';
                cronom_func_flag_salida_flag_pausa <= '0';
                cronom_func_flag_salida_flag_split <= '0';
        END CASE;
    END PROCESS;

    -- process de sumar/restar el cronom_func_flag_pausa

    PROCESS (cronom_inicio, clk)
    BEGIN
        IF cronom_inicio = '1' THEN
            cronom_func_flag_pausa <= '0';
        ELSIF rising_edge(clk) THEN
            IF cronom_func_flag_salida = '1' THEN
                IF cronom_func_flag_salida_flag_pausa = '1' THEN
                    IF cronom_func_flag_pausa = '0' THEN
                        cronom_func_flag_pausa <= '1';
                        cronom_pausa <= '1';
                    ELSIF cronom_func_flag_pausa = '1' THEN
                        cronom_func_flag_pausa <= '0';
                        cronom_pausa <= '0';
                    END IF;
                ELSIF cronom_func_flag_salida_flag_split = '1' THEN
                    IF cronom_func_flag_split = '0' THEN
                        cronom_func_flag_split <= '1';
                        cronom_split <= '1';
                    ELSIF cronom_func_flag_split = '1' THEN
                        cronom_func_flag_split <= '0';
                        cronom_split <= '0';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DE LA PILA
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################
    -- ####################################################################

    reloj_pila_entrada <= reloj_pila_entrada_hora_decenas &
        reloj_pila_entrada_hora_unidades &
        reloj_pila_entrada_min_decenas &
        reloj_pila_entrada_min_unidades;

    PROCESS (reloj_inicio, clk)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_pila_entrada_min_unidades <= "0000";
            reloj_pila_entrada_min_decenas <= "0000";
            reloj_pila_entrada_hora_unidades <= "0000";
            reloj_pila_entrada_hora_decenas <= "0000";
        ELSIF rising_edge(clk) THEN
            IF reloj_pila_push = '1' AND reloj_alarma_sonar = '1' THEN
                reloj_pila_entrada_min_unidades <= reloj_alarma_minutos_unidades;
                reloj_pila_entrada_min_decenas <= reloj_alarma_minutos_decenas;
                reloj_pila_entrada_hora_unidades <= reloj_alarma_horas_unidades;
                reloj_pila_entrada_hora_decenas <= reloj_alarma_horas_decenas;
            END IF;
        END IF;
    END PROCESS;

    -- AUTOMATA DE LA PILA
    PROCESS (clk, reloj_inicio)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_estado_pila <= vacia;
            reloj_pila_stack_pointer <= 7;
            reloj_pila <= ("0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
                "0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000");
        ELSIF rising_edge(clk) THEN
            CASE reloj_estado_pila IS
                WHEN idle =>
                    IF reloj_pila_salida_push = '1' THEN
                        reloj_estado_pila <= mete_push;
                        reloj_pila(reloj_pila_stack_pointer) <= reloj_pila_entrada;
                    ELSIF reloj_pila_salida_pop = '1' THEN
                        reloj_estado_pila <= saca_pop;
                        reloj_pila_stack_pointer <= reloj_pila_stack_pointer + 1;
                    END IF;
                WHEN mete_push =>
                    reloj_pila_stack_pointer <= reloj_pila_stack_pointer - 1;
                    IF reloj_pila_stack_pointer /= 0 THEN
                        reloj_estado_pila <= idle;
                    ELSE
                        reloj_estado_pila <= llena;
                    END IF;
                WHEN saca_pop =>
                    reloj_pila_salida <= reloj_pila(reloj_pila_stack_pointer);
                    IF reloj_pila_stack_pointer /= 7 THEN
                        reloj_estado_pila <= idle;
                    ELSE
                        reloj_estado_pila <= vacia;
                    END IF;
                WHEN llena =>
                    IF reloj_pila_salida_pop = '1' THEN
                        reloj_estado_pila <= saca_pop;
                        reloj_pila_stack_pointer <= reloj_pila_stack_pointer + 1;
                    ELSIF reloj_pila_salida_push = '1' THEN
                        reloj_estado_pila <= overflow;
                    END IF;
                WHEN vacia =>
                    IF reloj_pila_salida_push = '1' THEN
                        reloj_estado_pila <= mete_push;
                        reloj_pila(reloj_pila_stack_pointer) <= reloj_pila_entrada;
                    ELSIF reloj_pila_salida_pop = '1' THEN
                        reloj_estado_pila <= underflow;
                    END IF;
                WHEN overflow =>
                    IF reloj_pila_salida_pop = '1' THEN
                        reloj_estado_pila <= saca_pop;
                        reloj_pila_stack_pointer <= reloj_pila_stack_pointer + 1;
                    END IF;
                WHEN underflow =>
                    IF reloj_pila_salida_push = '1' THEN
                        reloj_estado_pila <= mete_push;
                        reloj_pila(reloj_pila_stack_pointer) <= reloj_pila_entrada;
                    END IF;
                WHEN OTHERS =>
                    reloj_pila_salida <= "0000000000000000";
                    reloj_estado_pila <= idle;
                    reloj_pila_stack_pointer <= 7;
            END CASE;
        END IF;
    END PROCESS;

    PROCESS (reloj_estado_pila)
    BEGIN
        CASE reloj_estado_pila IS
            WHEN idle =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '0';
            WHEN mete_push =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '0';
            WHEN saca_pop =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '0';
            WHEN llena =>
                reloj_pila_llena <= '1';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '0';
            WHEN vacia =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '1';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '0';
            WHEN overflow =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '1';
                reloj_pila_error_underflow <= '0';
            WHEN underflow =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '1';
            WHEN OTHERS =>
                reloj_pila_llena <= '0';
                reloj_pila_vacia <= '0';
                reloj_pila_error_overflow <= '0';
                reloj_pila_error_underflow <= '0';
        END CASE;
    END PROCESS;
    -- FIN DEL AUTOMATA DE LA PILA

    -- DETECCIÃ“N Y FILTRADO DE PULSO DE PUSH
    PROCESS (clk, reloj_inicio)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_pila_estado_push <= "00";
            reloj_pila_cont_filtro_push <= 0;
        ELSIF rising_edge(clk) THEN
            CASE reloj_pila_estado_push IS
                WHEN "00" =>
                    reloj_pila_cont_filtro_push <= 0;
                    IF reloj_pila_push = '0' THEN
                        reloj_pila_estado_push <= "00";
                    ELSE
                        reloj_pila_estado_push <= "01";
                    END IF;
                WHEN "01" =>
                    reloj_pila_cont_filtro_push <= reloj_pila_cont_filtro_push + 1;
                    IF reloj_pila_push = '1' AND reloj_pila_cont_filtro_push < 100000 THEN
                        reloj_pila_estado_push <= "01";
                    ELSIF reloj_pila_push = '1' AND reloj_pila_cont_filtro_push = 100000 THEN
                        reloj_pila_estado_push <= "10";
                    ELSE --pulsador = '0'
                        reloj_pila_estado_push <= "00";
                    END IF;
                WHEN "10" =>
                    reloj_pila_cont_filtro_push <= 0;
                    IF reloj_pila_push = '1' THEN
                        reloj_pila_estado_push <= "10";
                    ELSE
                        IF reloj_alarma_sonar = '1' THEN
                            reloj_pila_estado_push <= "11";
                        ELSE
                            reloj_pila_estado_push <= "00";
                        END IF;
                    END IF;
                WHEN OTHERS =>
                    reloj_pila_cont_filtro_push <= 0;
                    reloj_pila_estado_push <= "00";
            END CASE;
        END IF;
    END PROCESS;

    PROCESS (reloj_pila_estado_push)
    BEGIN
        CASE reloj_pila_estado_push IS
            WHEN "00" => reloj_pila_salida_push <= '0';
            WHEN "01" => reloj_pila_salida_push <= '0';
            WHEN "10" => reloj_pila_salida_push <= '0';
            WHEN OTHERS => reloj_pila_salida_push <= '1';
        END CASE;
    END PROCESS;

    -- DETECCIÃ“N Y FILTRADO DE PULSO DE POP
    PROCESS (clk, reloj_inicio)
    BEGIN
        IF reloj_inicio = '1' THEN
            reloj_pila_estado_pop <= "00";
        ELSIF rising_edge(clk) THEN
            CASE reloj_pila_estado_pop IS
                WHEN "00" =>
                    reloj_pila_cont_filtro_pop <= 0;
                    IF reloj_pila_pop = '0' THEN
                        reloj_pila_estado_pop <= "00";
                    ELSE
                        reloj_pila_estado_pop <= "01";
                    END IF;
                WHEN "01" =>
                    reloj_pila_cont_filtro_pop <= reloj_pila_cont_filtro_pop + 1;
                    IF reloj_pila_pop = '1' AND reloj_pila_cont_filtro_pop < 100000 THEN
                        reloj_pila_estado_pop <= "01";
                    ELSIF reloj_pila_pop = '1' AND reloj_pila_cont_filtro_pop = 100000 THEN
                        reloj_pila_estado_pop <= "10";
                    ELSE --pulsador = '0'
                        reloj_pila_estado_pop <= "00";
                    END IF;
                WHEN "10" =>
                    reloj_pila_cont_filtro_pop <= 0;
                    IF reloj_pila_pop = '1' THEN
                        reloj_pila_estado_pop <= "10";
                    ELSE
                        reloj_pila_estado_pop <= "11";
                    END IF;
                WHEN OTHERS =>
                    reloj_pila_cont_filtro_pop <= 0;
                    reloj_pila_estado_pop <= "00";
            END CASE;
        END IF;
    END PROCESS;

    PROCESS (reloj_pila_estado_pop)
    BEGIN
        CASE reloj_pila_estado_pop IS
            WHEN "00" => reloj_pila_salida_pop <= '0';
            WHEN "01" => reloj_pila_salida_pop <= '0';
            WHEN "10" => reloj_pila_salida_pop <= '0';
            WHEN OTHERS => reloj_pila_salida_pop <= '1';
        END CASE;
    END PROCESS;

END Behavioral;