
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity main is
    port (
        clk         : in  std_logic;
        sw          : in  STD_LOGIC_VECTOR(15 DOWNTO 0); -- interruptores
        btnU        : in  STD_LOGIC; -- boton arriba
        btnD        : in  STD_LOGIC; -- boton abajo
        btnL        : in  STD_LOGIC; -- boton izquierda
        btnR        : in  STD_LOGIC; -- boton derecha
        btnC        : in  STD_LOGIC; -- boton central
        led         : out STD_LOGIC_VECTOR(15 DOWNTO 0); -- leds
        seg         : out STD_LOGIC_VECTOR(6 DOWNTO 0); -- siete segmentos
        dp          : out STD_LOGIC; -- punto decimal del siete segmentos
        an          : out STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        servo       : out std_logic;
        dcmotor     : out std_logic_vector (1 downto 0)
    );
end main;

architecture Behavioral of main is

-- signals de control de modos y comunes

signal vector_modo: std_logic_vector(1 downto 0);
signal sal_mux: std_logic_vector (3 downto 0);
signal enable_aux: std_logic_vector (3 downto 0);
signal cont_base_enable: integer range 0 to 100000;

-- signals del reloj

signal reloj_inicio: std_logic;
signal reloj_cont_centesimas: std_logic_vector (3 downto 0);
signal reloj_cont_decimas: std_logic_vector (3 downto 0);
signal reloj_cont_segs_unidades: std_logic_vector (3 downto 0);
signal reloj_cont_segs_decenas: std_logic_vector (3 downto 0);
signal reloj_cont_mins_unidades: std_logic_vector (3 downto 0);
signal reloj_cont_mins_decenas: std_logic_vector (3 downto 0);
signal reloj_cont_horas_unidades: std_logic_vector (3 downto 0);
signal reloj_cont_horas_decenas: std_logic_vector (3 downto 0);
signal reloj_cont_base: integer range 0 to 1000000;
signal reloj_tope_freq: integer range 0 to 1000000;
signal reloj_select_display_hhmm_ss: std_logic;
signal reloj_fast: std_logic;
signal reloj_pausa: std_logic;

-- signals del reloj - pulsador de dedo del dp

signal reloj_puesta_en_hora_switch: std_logic;
signal reloj_puesta_en_hora_dp_display_m_h: std_logic := '0';
signal reloj_puesta_en_hora_dp_estado_pulsador: std_logic_vector (2 downto 0);
signal reloj_puesta_en_hora_dp_cont_filtro: integer range 0 to 100000000;
signal reloj_puesta_en_hora_dp_salida: std_logic;
signal reloj_puesta_en_hora_dp_flag_suma: std_logic;
signal reloj_puesta_en_hora_dp_flag_resta: std_logic;
signal reloj_puesta_en_hora_dp_btnL: std_logic;
signal reloj_puesta_en_hora_dp_btnR: std_logic;

-- signals del reloj - switches de suma y resta

signal reloj_puesta_en_hora_estado_pulsador: std_logic_vector (2 downto 0);
signal reloj_puesta_en_hora_cont_filtro: integer range 0 to 500000000;
signal reloj_puesta_en_hora_flag_salida: std_logic;
signal reloj_puesta_en_hora_flag_suma: std_logic;
signal reloj_puesta_en_hora_flag_resta: std_logic;
signal reloj_puesta_en_hora_sumar: std_logic;
signal reloj_puesta_en_hora_restar: std_logic;

-- signals del reloj-dcmotor

signal reloj_dcmotor_cont_horas_unidades_integer: integer range 0 to 9;
signal reloj_dcmotor_cont_horas_decenas_integer: integer range 0 to 9;
signal reloj_dcmotor_cont_horas_integer_dcmotor: integer range 0 to 100;
signal reloj_dcmotor_estado_pwm: std_logic_vector (2 downto 0);
signal reloj_dcmotor_duty_cycle: integer range 0 to 100;
signal reloj_dcmotor_sentido_giro: std_logic;
signal reloj_dcmotor_cont_flancos: integer range 0 to 100000000;
signal reloj_dcmotor_pwm_longitud_pulso: integer range 0 to 100000000;
signal reloj_dcmotor_pwm_longitud_ciclo: integer range 0 to 100000000;
signal reloj_dcmotor_pwm_hz: integer range 0 to 500;
signal reloj_dcmotor_pwm_out: std_logic;

-- signals del reloj-alarma

signal reloj_alarma_switch_off_on: std_logic;
signal reloj_alarma_minutos_unidades: std_logic_vector (3 downto 0);
signal reloj_alarma_minutos_decenas : std_logic_vector (3 downto 0);
signal reloj_alarma_horas_unidades : std_logic_vector (3 downto 0);
signal reloj_alarma_horas_decenas : std_logic_vector (3 downto 0);
signal reloj_alarma_sonar: std_logic;
signal reloj_alarma_switch_settime: std_logic;
signal reloj_alarma_led_estado: std_logic_vector(1 downto 0);
signal reloj_alarma_led_contflancos: integer range 0 to 100000000;
signal reloj_alarma_led: std_logic;
signal reloj_alarma_snooze_estado_pulsador: std_logic_vector (2 downto 0);
signal reloj_alarma_snooze_cont_filtro: integer range 0 to 100005;
signal reloj_alarma_snooze_btnU: std_logic;
signal reloj_alarma_snooze_btnD: std_logic;
signal reloj_alarma_snooze_salida: std_logic;
signal reloj_alarma_snooze_salida_suma: std_logic;
signal reloj_alarma_snooze_salida_resta: std_logic;

-- signals del servomotor

signal servo_inicio: std_logic;
signal servo_estado_servo: std_logic_vector (1 downto 0);
signal servo_selector_aspersor_mode: std_logic;
signal servo_selector_input_mode: std_logic;
signal servo_aspersor_cont: std_logic_vector(3 downto 0);
signal servo_selector_switches: std_logic_vector (3 downto 0);
signal servo_grados: integer range 0 to 180;
signal servo_cont_flancos: integer range 0 to 2000000;
signal servo_pwm_longitud_pulso: integer range 0 to 2000000;

-- signals del servomotor-reloj

signal servo_segundos_offset: std_logic_vector(3 downto 0);
signal servo_suma_o_resta: std_logic := '0';
signal servo_cont_base: integer range 0 to 400000000;
signal servo_tope_freq: integer range 0 to 400000000;

-- signals del servomotor-pulsador

signal servo_estado_pulsador: std_logic_vector (2 downto 0);
signal servo_cont_filtro: integer range 0 to 500000000;
signal servo_salida: std_logic;
signal servo_flag_suma: std_logic;
signal servo_flag_resta: std_logic;
signal servo_freq_min: integer range 0 to 100000000;
signal servo_contador_centenas: std_logic_vector (3 downto 0);
signal servo_contador_decenas: std_logic_vector (3 downto 0);
signal servo_botonMas: std_logic;
signal servo_botonMenos: std_logic;

-- signals del servomotor-pulsador-pwm

signal servo_contador_decenas_integer: integer range 0 to 9;
signal servo_contador_centenas_integer: integer range 0 to 9;
signal servo_numero_int: integer range 0 to 200;

-- signals del conversor binario-BCD

signal binario_bcd_inicio: std_logic;
signal binario_bcd_binario: std_logic_vector (9 downto 0);
signal binario_bcd_enable: std_logic;
signal binario_bcd_fin: std_logic;
signal binario_bcd_vector: std_logic_vector (25 downto 0);
signal binario_bcd_estado_conversion: std_logic_vector (1 downto 0);
signal binario_bcd_contador_desplazamientos: integer range 0 to 9;
signal binario_bcd_unidades: std_logic_vector (3 downto 0);
signal binario_bcd_decenas: std_logic_vector (3 downto 0);
signal binario_bcd_centenas: std_logic_vector (3 downto 0);
signal binario_bcd_millar: std_logic_vector (3 downto 0);

-- signals del conversor binario-BCD - reloj

signal binario_bcd_cont_base_enable: integer range 0 to 100000;
signal binario_bcd_cont: integer range 0 to 100000000;
signal binario_bcd_tope_freq: integer range 0 to 400000000;
signal binario_bcd_modo_lento_rapido: std_logic;

-- signals del cronometro

signal cronom_inicio: std_logic;
signal cronom_cont_centesimas: std_logic_vector (3 downto 0);
signal cronom_cont_decimas: std_logic_vector (3 downto 0);
signal cronom_cont_segs_unidades: std_logic_vector (3 downto 0);
signal cronom_cont_segs_decenas: std_logic_vector (3 downto 0);
signal cronom_cont_mins_unidades: std_logic_vector (3 downto 0);
signal cronom_cont_mins_decenas: std_logic_vector (3 downto 0);
signal cronom_cont_horas_unidades: std_logic_vector (3 downto 0);
signal cronom_cont_horas_decenas: std_logic_vector (3 downto 0);
signal cronom_cont_base: integer range 0 to 1000000;
signal cronom_tope_freq: integer range 0 to 1000000;
signal cronom_pausa: std_logic;
signal cronom_select_display_hhmm_ss: std_logic;
signal cronom_split: std_logic;
signal cronom_cont_centesimas_temp: std_logic_vector (3 downto 0);
signal cronom_cont_decimas_temp: std_logic_vector (3 downto 0);
signal cronom_cont_segs_unidades_temp: std_logic_vector (3 downto 0);
signal cronom_cont_segs_decenas_temp: std_logic_vector (3 downto 0);

-- signals del cronometro - func

signal cronom_func_btnU_stop: std_logic;
signal cronom_func_btnD_split: std_logic;
signal cronom_func_estado_pulsador: std_logic_vector (2 downto 0);
signal cronom_func_cont_filtro: integer range 0 to 100000000;
signal cronom_func_flag_salida: std_logic;
signal cronom_func_flag_salida_flag_pausa: std_logic;
signal cronom_func_flag_salida_flag_split: std_logic;
signal cronom_func_flag_pausa: std_logic := '0';
signal cronom_func_flag_split: std_logic := '0';

--signals del LIFO

signal reloj_visualizar_pila: std_logic;
signal reloj_pila_push: std_logic;
signal reloj_pila_pop: std_logic;
signal reloj_pila_stack_pointer: integer range -8 to 8 :=7;
type data is array (7 downto 0) of std_logic_vector(15 downto 0);
signal reloj_pila: data := (others => (others => '0'));
signal reloj_pila_entrada: std_logic_vector (15 downto 0);
signal reloj_pila_entrada_hora_decenas: std_logic_vector (3 downto 0);
signal reloj_pila_entrada_hora_unidades: std_logic_vector (3 downto 0);
signal reloj_pila_entrada_min_decenas: std_logic_vector (3 downto 0);
signal reloj_pila_entrada_min_unidades: std_logic_vector (3 downto 0);
signal reloj_pila_salida: std_logic_vector (15 downto 0) := "0000000000000000";
signal reloj_pila_salida_hora_decenas: std_logic_vector (3 downto 0);
signal reloj_pila_salida_hora_unidades: std_logic_vector (3 downto 0);
signal reloj_pila_salida_min_decenas: std_logic_vector (3 downto 0);
signal reloj_pila_salida_min_unidades: std_logic_vector (3 downto 0);
type estado is (idle, mete_push, saca_pop, llena, vacia, overflow, underflow);
signal reloj_estado_pila: estado;
signal reloj_pila_llena: std_logic;
signal reloj_pila_vacia: std_logic;
signal reloj_pila_error_overflow: std_logic;
signal reloj_pila_error_underflow: std_logic;
signal reloj_pila_estado_push: std_logic_vector (1 downto 0);
signal reloj_pila_cont_filtro_push: integer range 0 to 100000;
signal reloj_pila_salida_push: std_logic;
signal reloj_pila_estado_pop: std_logic_vector (1 downto 0);
signal reloj_pila_cont_filtro_pop: integer range 0 to 100000;
signal reloj_pila_salida_pop: std_logic;

begin

-- ####################################################################
-- ####################################################################
-- ####################################################################
-- ####################################################################
--                         LOGICA DE CONTROL
-- ####################################################################
-- ####################################################################
-- ####################################################################
-- ####################################################################

vector_modo                 <= sw(15 downto 14);
reloj_alarma_switch_off_on  <= sw(13);
servo_pwm_longitud_pulso    <= servo_grados * 1111 + 50000;

-- process de asignacion de switches

process(btnC, clk, vector_modo)
begin
    if btnC = '1' then
        case vector_modo is
            when "00" =>              -- reloj
                reloj_inicio        <= '1';
            when "01" =>              -- servomotor
                servo_inicio        <= '1';
            when "10" =>              -- bin-bcd
                binario_bcd_inicio  <= '1';
            when others =>            -- cronometro
                cronom_inicio       <= '1';
        end case;
    elsif rising_edge(clk) then
        reloj_inicio        <= '0';
        servo_inicio        <= '0';
        binario_bcd_inicio  <= '0';
        cronom_inicio       <= '0';
        case vector_modo is
            when "00" =>                                                -- reloj
                reloj_select_display_hhmm_ss                <= sw(0);
                reloj_fast                                  <= sw(1);
                reloj_pausa                                 <= sw(2);
                reloj_puesta_en_hora_switch                 <= sw(3);
                reloj_alarma_switch_settime                 <= sw(4);
                reloj_puesta_en_hora_restar                 <= sw(6);
                reloj_puesta_en_hora_sumar                  <= sw(7);
                reloj_dcmotor_sentido_giro                  <= sw(8);
                reloj_puesta_en_hora_dp_btnL                <= btnL;
                reloj_puesta_en_hora_dp_btnR                <= btnR;
                reloj_dcmotor_pwm_hz                        <= 200; -- (200 Hz) -> (500000 flancos) -> (0.5 ms)
                reloj_alarma_snooze_btnU                    <= btnU;
                reloj_alarma_snooze_btnD                    <= btnD;
                led(3 downto 0)                             <= "0000";
                reloj_dcmotor_cont_horas_integer_dcmotor    <= (reloj_dcmotor_cont_horas_decenas_integer * 10) +  reloj_dcmotor_cont_horas_unidades_integer;
                if reloj_alarma_sonar = '0' then
                    reloj_dcmotor_cont_horas_unidades_integer   <= conv_integer(reloj_cont_horas_unidades);
                    reloj_dcmotor_cont_horas_decenas_integer    <= conv_integer(reloj_cont_horas_decenas);
                    reloj_dcmotor_duty_cycle                    <= reloj_dcmotor_cont_horas_integer_dcmotor * 99 / 23;
                else
                    reloj_dcmotor_cont_horas_unidades_integer   <= conv_integer(reloj_cont_segs_unidades);
                    reloj_dcmotor_cont_horas_decenas_integer    <= conv_integer(reloj_cont_segs_decenas);
                    reloj_dcmotor_duty_cycle                    <= reloj_dcmotor_cont_horas_integer_dcmotor * 99 / 59;
                end if;
                --led(2 downto 0) <= std_logic_vector(to_unsigned(reloj_pila_stack_pointer, 3));
                reloj_visualizar_pila           <= sw(9);
                reloj_pila_pop                  <= sw(10);
                reloj_pila_push                 <= btnU;
            when "01" =>                                                -- servomotor
                servo_segundos_offset               <= sw(11 downto 8);
                servo_selector_aspersor_mode        <= sw(7);
                servo_selector_input_mode           <= sw(6);
                servo_botonMas                      <= sw(5);
                servo_botonMenos                    <= sw(4);
                servo_selector_switches             <= sw(3 downto 0);
                servo_freq_min                      <= 100000;
                servo_contador_decenas_integer      <= conv_integer(servo_contador_decenas);
                servo_contador_centenas_integer     <= conv_integer(servo_contador_centenas);
                servo_numero_int                    <= ((servo_contador_centenas_integer * 10) +  servo_contador_decenas_integer) * 10;
                led(3 downto 0)                     <= "0000";
                if servo_segundos_offset = "XXX1" then
                    led(15 downto 12) <= "0001";
                elsif servo_segundos_offset = "XX10" then
                    led(15 downto 12) <= "0010";
                elsif servo_segundos_offset = "X100" then
                    led(15 downto 12) <= "0100";
                elsif servo_segundos_offset = "1000" then
                    led(15 downto 12) <= "1000";
                else
                    led(15 downto 12) <= "0000";
                end if;
            when "10" =>                                                -- bin-bcd
                binario_bcd_binario             <= sw(9 downto 0);
                binario_bcd_enable              <= sw(11);
                binario_bcd_modo_lento_rapido   <= sw(10);
                led(15)                         <= binario_bcd_fin;
                led(14)                         <= binario_bcd_modo_lento_rapido;
                -- led(11 downto 0) <= binario_bcd_vector;
            when others =>                                              -- cronometro
                cronom_select_display_hhmm_ss   <= sw(0);
                cronom_func_btnU_stop           <= btnU;
                cronom_func_btnD_split          <= btnD;
                cronom_tope_freq                <= 1000000;
                led(3 downto 0)                 <= "0000";
        end case;
    end if;
end process;

-- process de la alarma

process(reloj_alarma_switch_off_on, reloj_alarma_minutos_unidades,
reloj_cont_mins_unidades, reloj_alarma_minutos_decenas, reloj_cont_mins_decenas,
reloj_alarma_horas_unidades, reloj_cont_horas_unidades, reloj_alarma_horas_decenas,
reloj_cont_horas_decenas)
begin
    if reloj_alarma_switch_off_on = '0' then
        reloj_alarma_sonar <= '0';
    else
        if reloj_alarma_minutos_unidades    = reloj_cont_mins_unidades  and
           reloj_alarma_minutos_decenas     = reloj_cont_mins_decenas   and
           reloj_alarma_horas_unidades      = reloj_cont_horas_unidades and
           reloj_alarma_horas_decenas       = reloj_cont_horas_decenas
        then
            reloj_alarma_sonar <= '1';
        else
            reloj_alarma_sonar <= '0';
        end if;
    end if;
end process;

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

process(btnC, clk)
begin
    if btnC = '1' then
        cont_base_enable <= 0;
    elsif rising_edge(clk) then
        if cont_base_enable = 100000 then
            cont_base_enable <= 0;
        else
            cont_base_enable <= cont_base_enable + 1;
        end if;
    end if;
end process;

-- modificacion de la signal para ir de seg en seg (rotacion izquierda 1000 veces por segundo)

process(btnC, clk)
begin
    if btnC = '1' then
        enable_aux <= "1110";
    elsif rising_edge(clk) then
        if cont_base_enable = 100000 then
            enable_aux <= enable_aux(2 downto 0) & enable_aux(3); -- desplazamiento a la izquierda
            -- enable_aux <= enable_aux(0) & enable_aux(3 downto 1); -- desplazamiento a la derecha
        end if;
    end if;
end process;

-- multiplexado de las entradas al 7-seg

process(enable_aux, vector_modo, reloj_select_display_hhmm_ss, reloj_cont_centesimas,
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
begin
    if vector_modo = "00" then              -- reloj
        if reloj_puesta_en_hora_switch = '1' then
            case enable_aux is
                when "1110" =>
                    sal_mux <= reloj_cont_mins_unidades;
                    if reloj_puesta_en_hora_dp_display_m_h = '0' then
                        dp <= '0';
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= reloj_cont_mins_decenas;
                    dp <= '1';
                when "1011" =>
                    sal_mux <= reloj_cont_horas_unidades;
                    if reloj_puesta_en_hora_dp_display_m_h = '1' then
                        dp <= '0';
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= reloj_cont_horas_decenas;
                    dp <= '1';
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        elsif reloj_alarma_switch_settime = '1' then
            case enable_aux is
                when "1110" =>
                    sal_mux <= reloj_alarma_minutos_unidades;
                    if reloj_puesta_en_hora_dp_display_m_h = '0' then
                        dp <= '0';
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= reloj_alarma_minutos_decenas;
                    dp <= '1';
                when "1011" =>
                    sal_mux <= reloj_alarma_horas_unidades;
                    if reloj_puesta_en_hora_dp_display_m_h = '1' then
                        dp <= '0';
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= reloj_alarma_horas_decenas;
                    dp <= '1';
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        elsif reloj_visualizar_pila = '1' then
            case enable_aux is
                when "1110" =>
                    sal_mux <= reloj_pila_salida(3 downto 0);
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= reloj_pila_salida(7 downto 4);
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= reloj_pila_salida(11 downto 8);
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= reloj_pila_salida(15 downto 12);
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        elsif reloj_select_display_hhmm_ss = '0' then
            case enable_aux is
                when "1110" =>
                    sal_mux <= reloj_cont_mins_unidades;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= reloj_cont_mins_decenas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= reloj_cont_horas_unidades;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= reloj_cont_horas_decenas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        else
            case enable_aux is
                when "1110" =>
                    sal_mux <= reloj_cont_centesimas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= reloj_cont_decimas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= reloj_cont_segs_unidades;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= reloj_cont_segs_decenas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        end if;
    elsif vector_modo = "01" then           -- servomotor
        if servo_grados < 100 then
            case enable_aux is
                when "0111" =>
                    sal_mux <= "1111";
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= std_logic_vector(to_unsigned(servo_grados / 100, 4));
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= std_logic_vector(to_unsigned(servo_grados / 10, 4));
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1110" =>
                    sal_mux <= "0000";
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "1111";
                    dp <= '1';
            end case;
        else
            case enable_aux is
                when "0111" =>
                    sal_mux <= "1111";
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= std_logic_vector(to_unsigned(servo_grados / 100, 4));
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= std_logic_vector(to_unsigned((servo_grados / 10) - 10, 4));
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1110" =>
                    sal_mux <= "0000";
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "1111";
                    dp <= '1';
            end case;
        end if;
    elsif vector_modo = "10" then           -- conversor bin-bcd
        case enable_aux is
            when "0111" =>
                sal_mux <= binario_bcd_millar;
                if reloj_alarma_sonar = '1' then
                    dp <= reloj_alarma_led;
                else
                    dp <= '1';
                end if;
            when "1011" =>
                sal_mux <= binario_bcd_centenas;
                if reloj_alarma_sonar = '1' then
                    dp <= reloj_alarma_led;
                else
                    dp <= '1';
                end if;
            when "1101" =>
                sal_mux <= binario_bcd_decenas;
                if reloj_alarma_sonar = '1' then
                    dp <= reloj_alarma_led;
                else
                    dp <= '1';
                end if;
            when "1110" =>
                sal_mux <= binario_bcd_unidades;
                if reloj_alarma_sonar = '1' then
                    dp <= reloj_alarma_led;
                else
                    dp <= '1';
                end if;
            when others =>
                sal_mux <= "0000";
                dp <= '1';
        end case;
    else                                    -- cronometro
        if cronom_split = '1' then
            case enable_aux is
                when "1110" =>
                    sal_mux <= cronom_cont_centesimas_temp;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= cronom_cont_decimas_temp;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= cronom_cont_segs_unidades_temp;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= cronom_cont_segs_decenas_temp;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        elsif cronom_select_display_hhmm_ss = '1' then
            case enable_aux is
                when "1110" =>
                    sal_mux <= cronom_cont_mins_unidades;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= cronom_cont_mins_decenas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= cronom_cont_horas_unidades;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= cronom_cont_horas_decenas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        else
            case enable_aux is
                when "1110" =>
                    sal_mux <= cronom_cont_centesimas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1101" =>
                    sal_mux <= cronom_cont_decimas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "1011" =>
                    sal_mux <= cronom_cont_segs_unidades;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when "0111" =>
                    sal_mux <= cronom_cont_segs_decenas;
                    if reloj_alarma_sonar = '1' then
                        dp <= reloj_alarma_led;
                    else
                        dp <= '1';
                    end if;
                when others =>
                    sal_mux <= "0000";
                    dp <= '1';
            end case;
        end if;
    end if;
end process;

-- proceso de display de diferentes valores en diferentes siete_segs

process(sal_mux)
begin
    case sal_mux is
        when "0000" => seg <= "0000001";
        when "0001" => seg <= "1001111";
        when "0010" => seg <= "0010010";
        when "0011" => seg <= "0000110";
        when "0100" => seg <= "1001100";
        when "0101" => seg <= "0100100";
        when "0110" => seg <= "1100000";
        when "0111" => seg <= "0001111";
        when "1000" => seg <= "0000000";
        when "1001" => seg <= "0001100";
        when others => seg <= "1111111";
    end case;
end process;

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

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_base <= 0;
    elsif rising_edge(clk) then
        if reloj_cont_base = reloj_tope_freq then
            reloj_cont_base <= 0;
        else
            reloj_cont_base <= reloj_cont_base + 1;
        end if;
    end if;
end process;

-- process de cambio de vel.

process(reloj_fast)
begin
    if reloj_fast = '0' then
        reloj_tope_freq <= 1000000;
    else
        reloj_tope_freq <= 500;
    end if;
end process;

-- process de monitoreo de segundos.centesimas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_centesimas <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas
            if reloj_cont_base = reloj_tope_freq then
                if reloj_cont_centesimas = "1001" then
                    reloj_cont_centesimas <= "0000";
                else
                    reloj_cont_centesimas <= reloj_cont_centesimas + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de segundos.decimas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_decimas <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" then
                if reloj_cont_decimas = "1001" then
                    reloj_cont_decimas <= "0000";
                else
                    reloj_cont_decimas <= reloj_cont_decimas + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de segundos.unidades

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_segs_unidades <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" and reloj_cont_decimas = "1001" then
                if reloj_cont_segs_unidades = "1001" then
                    reloj_cont_segs_unidades <= "0000";
                else
                    reloj_cont_segs_unidades <= reloj_cont_segs_unidades + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de segundos.decenas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_segs_decenas <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" and reloj_cont_decimas = "1001" and reloj_cont_segs_unidades = "1001" then
                if reloj_cont_segs_decenas = "0101" then
                    reloj_cont_segs_decenas <= "0000";
                else
                    reloj_cont_segs_decenas <= reloj_cont_segs_decenas + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de minutos.unidades

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_mins_unidades <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" and reloj_cont_decimas = "1001" and reloj_cont_segs_unidades = "1001" and reloj_cont_segs_decenas = "0101" then
                if reloj_cont_mins_unidades = "1001" then
                    reloj_cont_mins_unidades <= "0000";
                else
                    reloj_cont_mins_unidades <= reloj_cont_mins_unidades + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            if reloj_puesta_en_hora_dp_display_m_h = '0' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' then
                        if reloj_cont_mins_unidades = 9 and reloj_cont_mins_decenas < 5 then
                            reloj_cont_mins_unidades <= "0000";
                        elsif reloj_cont_mins_unidades = 9 and reloj_cont_mins_decenas = 5 then
                            reloj_cont_mins_unidades <= "1001";
                        else
                            reloj_cont_mins_unidades <= reloj_cont_mins_unidades + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' then
                        if reloj_cont_mins_unidades = 0 and reloj_cont_mins_decenas > 0 then
                            reloj_cont_mins_unidades <= "1001";
                        elsif reloj_cont_mins_unidades = 0 and reloj_cont_mins_decenas = 0 then
                            reloj_cont_mins_unidades <= "0000";
                        else
                            reloj_cont_mins_unidades <= reloj_cont_mins_unidades - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de minutos.decenas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_mins_decenas <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5 y las minutos.unidades = 9
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" and reloj_cont_decimas = "1001" and reloj_cont_segs_unidades = "1001" and reloj_cont_segs_decenas = "0101" and reloj_cont_mins_unidades = "1001" then
                if reloj_cont_mins_decenas = "0101" then
                    reloj_cont_mins_decenas <= "0000";
                else
                    reloj_cont_mins_decenas <= reloj_cont_mins_decenas + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            if reloj_puesta_en_hora_dp_display_m_h = '0' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' and reloj_cont_mins_unidades = 9 then
                        if reloj_cont_mins_decenas = 5 then
                            reloj_cont_mins_decenas <= "0101";
                        else
                            reloj_cont_mins_decenas <= reloj_cont_mins_decenas + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' and reloj_cont_mins_unidades = 0 then
                        if reloj_cont_mins_decenas = 0 then
                            reloj_cont_mins_decenas <= "0000";
                        else
                            reloj_cont_mins_decenas <= reloj_cont_mins_decenas - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de horas.unidades

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_horas_unidades <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" and reloj_cont_decimas = "1001" and reloj_cont_segs_unidades = "1001" and reloj_cont_segs_decenas = "0101" and reloj_cont_mins_unidades = "1001" and reloj_cont_mins_decenas = "0101" then
                if reloj_cont_horas_unidades = "1001" then
                    reloj_cont_horas_unidades <= "0000";
                elsif reloj_cont_horas_unidades = "0011" and reloj_cont_horas_decenas = "0010" then
                    reloj_cont_horas_unidades <= "0000";
                else
                    reloj_cont_horas_unidades <= reloj_cont_horas_unidades + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            if reloj_puesta_en_hora_dp_display_m_h = '1' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' then
                        if reloj_cont_horas_unidades = 9 and reloj_cont_horas_decenas < 2 then
                            reloj_cont_horas_unidades <= "0000";
                        elsif reloj_cont_horas_unidades = 3 and reloj_cont_horas_decenas = 2 then
                            reloj_cont_horas_unidades <= "0011";
                        else
                            reloj_cont_horas_unidades <= reloj_cont_horas_unidades + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' then
                        if reloj_cont_horas_unidades = 0 and reloj_cont_horas_decenas > 0 then
                            reloj_cont_horas_unidades <= "1001";
                        elsif reloj_cont_horas_unidades = 0 and reloj_cont_horas_decenas = 0 then
                            reloj_cont_horas_unidades <= "0000";
                        else
                            reloj_cont_horas_unidades <= reloj_cont_horas_unidades - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de horas.decenas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_cont_horas_decenas <= "0000";
    elsif rising_edge(clk) then
        if reloj_pausa = '0' and reloj_puesta_en_hora_switch = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5 y las horas.unidades = 9 or 3
            if reloj_cont_base = reloj_tope_freq and reloj_cont_centesimas = "1001" and reloj_cont_decimas = "1001" and reloj_cont_segs_unidades = "1001" and reloj_cont_segs_decenas = "0101" and reloj_cont_mins_unidades = "1001" and reloj_cont_mins_decenas = "0101" and (reloj_cont_horas_unidades = "1001" or reloj_cont_horas_unidades = "0011") then
                if reloj_cont_horas_decenas = "0010" then
                    reloj_cont_horas_decenas <= "0000";
                elsif reloj_cont_horas_unidades = "1001" then
                    reloj_cont_horas_decenas <= reloj_cont_horas_decenas + 1;
                end if;
            end if;
        elsif reloj_pausa = '1' then
            -- hacer cosas
        elsif reloj_puesta_en_hora_switch = '1' then
            if reloj_puesta_en_hora_dp_display_m_h = '1' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' and reloj_cont_horas_unidades = 9 then
                        if reloj_cont_horas_decenas = 2 then
                            reloj_cont_horas_decenas <= "0010";
                        else
                            reloj_cont_horas_decenas <= reloj_cont_horas_decenas + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' and reloj_cont_horas_unidades = 0 then
                        if reloj_cont_horas_decenas = 0 then
                            reloj_cont_horas_decenas <= "0000";
                        else
                            reloj_cont_horas_decenas <= reloj_cont_horas_decenas - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de alarma.minutos.unidades

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_alarma_minutos_unidades <= "0000";
    elsif rising_edge(clk) then
        if reloj_alarma_switch_settime = '1' and reloj_puesta_en_hora_switch = '0' then
            if reloj_puesta_en_hora_dp_display_m_h = '0' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' then
                        if reloj_alarma_minutos_unidades = 9 and reloj_alarma_minutos_decenas < 5 then
                            reloj_alarma_minutos_unidades <= "0000";
                        elsif reloj_alarma_minutos_unidades = 9 and reloj_alarma_minutos_decenas = 5 then
                            reloj_alarma_minutos_unidades <= "1001";
                        else
                            reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' then
                        if reloj_alarma_minutos_unidades = 0 and reloj_alarma_minutos_decenas > 0 then
                            reloj_alarma_minutos_unidades <= "1001";
                        elsif reloj_alarma_minutos_unidades = 0 and reloj_alarma_minutos_decenas = 0 then
                            reloj_alarma_minutos_unidades <= "0000";
                        else
                            reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades - 1;
                        end if;
                    end if;
                end if;
            end if;
        elsif reloj_alarma_sonar = '1' then
            if reloj_alarma_snooze_salida = '1' then
                if reloj_alarma_snooze_salida_suma = '1' or reloj_alarma_snooze_salida_resta = '1' then
                    if reloj_alarma_minutos_unidades >= 5 then
                        reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades - 5;
                    elsif reloj_alarma_minutos_unidades < 5 then
                        reloj_alarma_minutos_unidades <= reloj_alarma_minutos_unidades + 5;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de alarma.minutos.decenas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_alarma_minutos_decenas <= "0000";
    elsif rising_edge(clk) then
        if reloj_alarma_switch_settime = '1' and reloj_puesta_en_hora_switch = '0' then
            if reloj_puesta_en_hora_dp_display_m_h = '0' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' and reloj_alarma_minutos_unidades = 9 then
                        if reloj_alarma_minutos_decenas = 5 then
                            reloj_alarma_minutos_decenas <= "0101";
                        else
                            reloj_alarma_minutos_decenas <= reloj_alarma_minutos_decenas + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' and reloj_alarma_minutos_unidades = 0 then
                        if reloj_alarma_minutos_decenas = 0 then
                            reloj_alarma_minutos_decenas <= "0000";
                        else
                            reloj_alarma_minutos_decenas <= reloj_alarma_minutos_decenas - 1;
                        end if;
                    end if;
                end if;
            end if;
        elsif reloj_alarma_sonar = '1' then
            if reloj_alarma_snooze_salida = '1' then
                if reloj_alarma_snooze_salida_suma = '1' or reloj_alarma_snooze_salida_resta = '1' then
                    if reloj_alarma_minutos_unidades >= 5 then
                        if reloj_alarma_minutos_decenas < 5 then
                            reloj_alarma_minutos_decenas <= reloj_alarma_minutos_decenas + 1;
                        else
                            reloj_alarma_minutos_decenas <= "0000";
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de alarma.horas.unidades

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_alarma_horas_unidades <= "0000";
    elsif rising_edge(clk) then
        if reloj_alarma_switch_settime = '1' and reloj_puesta_en_hora_switch = '0' then
            if reloj_puesta_en_hora_dp_display_m_h = '1' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' then
                        if reloj_alarma_horas_unidades = 9 and reloj_alarma_horas_decenas < 2 then
                            reloj_alarma_horas_unidades <= "0000";
                        elsif reloj_alarma_horas_unidades = 3 and reloj_alarma_horas_decenas = 2 then
                            reloj_alarma_horas_unidades <= "0011";
                        else
                            reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' then
                        if reloj_alarma_horas_unidades = 0 and reloj_alarma_horas_decenas > 0 then
                            reloj_alarma_horas_unidades <= "1001";
                        elsif reloj_alarma_horas_unidades = 0 and reloj_alarma_horas_decenas = 0 then
                            reloj_alarma_horas_unidades <= "0000";
                        else
                            reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades - 1;
                        end if;
                    end if;
                end if;
            end if;
        elsif reloj_alarma_sonar = '1' then
            if reloj_alarma_snooze_salida = '1' then
                if reloj_alarma_snooze_salida_suma = '1' or reloj_alarma_snooze_salida_resta = '1' then
                    if reloj_alarma_minutos_unidades >= 5 then
                        if reloj_alarma_minutos_decenas = 5 then
                            if reloj_alarma_horas_decenas < 2 then
                                if reloj_alarma_horas_unidades < 9 then
                                    reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades + 1;
                                else
                                    reloj_alarma_horas_unidades <= "0000";
                                end if;
                            else
                                if reloj_alarma_horas_unidades < 3 then
                                    reloj_alarma_horas_unidades <= reloj_alarma_horas_unidades + 1;
                                else
                                    reloj_alarma_horas_unidades <= "0000";
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- process de monitoreo de alarma.horas.decenas

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_alarma_horas_decenas <= "0000";
    elsif rising_edge(clk) then
        if reloj_alarma_switch_settime = '1' and reloj_puesta_en_hora_switch = '0' then
            if reloj_puesta_en_hora_dp_display_m_h = '1' then
                if reloj_puesta_en_hora_flag_salida = '1' then
                    if reloj_puesta_en_hora_flag_suma = '1' and reloj_alarma_horas_unidades = 9 then
                        if reloj_alarma_horas_decenas = 2 then
                            reloj_alarma_horas_decenas <= "0010";
                        else
                            reloj_alarma_horas_decenas <= reloj_alarma_horas_decenas + 1;
                        end if;
                    elsif reloj_puesta_en_hora_flag_resta = '1' and reloj_alarma_horas_unidades = 0 then
                        if reloj_alarma_horas_decenas = 0 then
                            reloj_alarma_horas_decenas <= "0000";
                        else
                            reloj_alarma_horas_decenas <= reloj_alarma_horas_decenas - 1;
                        end if;
                    end if;
                end if;
            end if;
        elsif reloj_alarma_sonar = '1' then
            if reloj_alarma_snooze_salida = '1' then
                if reloj_alarma_snooze_salida_suma = '1' or reloj_alarma_snooze_salida_resta = '1' then
                    if reloj_alarma_minutos_unidades >= 5 then
                        if reloj_alarma_minutos_decenas = 5 then
                            if reloj_alarma_horas_decenas < 2 then
                                if reloj_alarma_horas_unidades = 9 then
                                    reloj_alarma_horas_decenas <= reloj_alarma_horas_decenas + 1;
                                end if;
                            else
                                if reloj_alarma_horas_unidades = 3 then
                                    reloj_alarma_horas_decenas <= "0000";
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                        LOGICA DEL MOTOR DC
-- ####################################################################
-- ####################################################################

-- process del sentido de giro del motor

process(reloj_dcmotor_sentido_giro, reloj_dcmotor_pwm_out)
begin
    if reloj_dcmotor_sentido_giro = '0' then
        dcmotor <= "0" & reloj_dcmotor_pwm_out;
    else
        dcmotor <= reloj_dcmotor_pwm_out & "0";
    end if;
end process;

-- process de definicion de reloj_dcmotor_pwm_longitud_ciclo como (frecuencia base de
-- la fpga) / (reloj_dcmotor_pwm_hz)

process(reloj_dcmotor_pwm_hz)
begin
    reloj_dcmotor_pwm_longitud_ciclo <= 100000000 / reloj_dcmotor_pwm_hz;
end process;

-- process de definicion de reloj_dcmotor_pwm_longitud_pulso como porcentaje X de
-- reloj_dcmotor_pwm_longitud_ciclo en funciรณn del valor de reloj_dcmotor_duty_cycle

process(reloj_dcmotor_pwm_longitud_ciclo, reloj_dcmotor_duty_cycle)
begin
    reloj_dcmotor_pwm_longitud_pulso <= reloj_dcmotor_pwm_longitud_ciclo * reloj_dcmotor_duty_cycle / 100;
end process;

-- process del automata del pwm

process(clk, reloj_inicio)
begin
    if reloj_inicio = '1' then
        reloj_dcmotor_estado_pwm <= "000";
        reloj_dcmotor_cont_flancos <= 0;
    elsif rising_edge(clk) then
        case reloj_dcmotor_estado_pwm is
            when "000" =>
                reloj_dcmotor_cont_flancos <= 0;
                if reloj_dcmotor_duty_cycle /= 0 then
                    reloj_dcmotor_estado_pwm <= "001";
                else
                    reloj_dcmotor_estado_pwm <= "100";
                end if;
            when "001" =>
                reloj_dcmotor_cont_flancos <= 1;
                reloj_dcmotor_estado_pwm <= "010";
            when "010" =>
                reloj_dcmotor_cont_flancos <= reloj_dcmotor_cont_flancos + 1;
                if reloj_dcmotor_cont_flancos < reloj_dcmotor_pwm_longitud_pulso then
                    reloj_dcmotor_estado_pwm <= "010";
                else
                    if reloj_dcmotor_duty_cycle /= 100 then
                        reloj_dcmotor_estado_pwm <= "011";
                    else
                        reloj_dcmotor_estado_pwm <= "001";
                    end if;
                end if;
            when "011" =>
                reloj_dcmotor_cont_flancos <= reloj_dcmotor_cont_flancos + 1;
                if reloj_dcmotor_cont_flancos < reloj_dcmotor_pwm_longitud_ciclo then
                    reloj_dcmotor_estado_pwm <= "011";
                else
                    if reloj_dcmotor_duty_cycle /= 0 then
                        reloj_dcmotor_estado_pwm <= "001";
                    else
                        reloj_dcmotor_estado_pwm <= "100";
                    end if;
                end if;
            when "100" =>
                reloj_dcmotor_cont_flancos <= 1;
                reloj_dcmotor_estado_pwm <= "011";
            when others =>
                reloj_dcmotor_cont_flancos <= 0;
                reloj_dcmotor_estado_pwm <= "000";
        end case;
    end if;
end process;

-- process de las salidas del pwm

process(reloj_dcmotor_estado_pwm)
begin
    case reloj_dcmotor_estado_pwm is
        when "000" => reloj_dcmotor_pwm_out <= '0';
        when "001" => reloj_dcmotor_pwm_out <= '1';
        when "010" => reloj_dcmotor_pwm_out <= '1';
        when "011" => reloj_dcmotor_pwm_out <= '0';
        when "100" => reloj_dcmotor_pwm_out <= '0';
        when others => reloj_dcmotor_pwm_out <= '0';
    end case;
end process;

-- ####################################################################
-- ####################################################################
--                    LOGICA DEL PULSADOR DE DEDO DP
-- ####################################################################
-- ####################################################################

-- process del automata del pulsador

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_puesta_en_hora_dp_estado_pulsador <= "000";
        reloj_puesta_en_hora_dp_cont_filtro <= 0;
    elsif rising_edge(clk) then
        case reloj_puesta_en_hora_dp_estado_pulsador is
            when "000" => -- INICIO
                reloj_puesta_en_hora_dp_cont_filtro <= 0;
                if reloj_puesta_en_hora_dp_btnL = '1' or reloj_puesta_en_hora_dp_btnR = '1' then
                    reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                else
                    reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                end if;  
            when "001" => -- FILTRADO
                reloj_puesta_en_hora_dp_cont_filtro <= reloj_puesta_en_hora_dp_cont_filtro + 1;
                if (reloj_puesta_en_hora_dp_btnL = '1' or reloj_puesta_en_hora_dp_btnR = '1') and reloj_puesta_en_hora_dp_cont_filtro < 100000 then
                    reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                elsif (reloj_puesta_en_hora_dp_btnL = '1' or reloj_puesta_en_hora_dp_btnR = '1') and reloj_puesta_en_hora_dp_cont_filtro = 100000 then
                    if reloj_puesta_en_hora_dp_btnL = '1'then
                        reloj_puesta_en_hora_dp_estado_pulsador <= "010";
                    elsif reloj_puesta_en_hora_dp_btnR = '1' then
                        reloj_puesta_en_hora_dp_estado_pulsador <= "100";
                    end if;
                else
                    reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                end if;
            when "010" => -- UNO +
                reloj_puesta_en_hora_dp_cont_filtro <= 0;
                if reloj_puesta_en_hora_dp_btnL = '1' then
                    reloj_puesta_en_hora_dp_estado_pulsador <= "010";
                else
                    reloj_puesta_en_hora_dp_estado_pulsador <= "011";
                end if;
            when "011" => -- SUMA
                reloj_puesta_en_hora_dp_cont_filtro <= 0;
                if reloj_puesta_en_hora_dp_btnL = '1' then
                    reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                else
                    reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                end if;
            when "100" => -- UNO -
                reloj_puesta_en_hora_dp_cont_filtro <= 0;
                if reloj_puesta_en_hora_dp_btnR = '1' then
                    reloj_puesta_en_hora_dp_estado_pulsador <= "100";
                else
                    reloj_puesta_en_hora_dp_estado_pulsador <= "101";
                end if;
            when "101" => -- RESTA
                reloj_puesta_en_hora_dp_cont_filtro <= 0;
                if reloj_puesta_en_hora_dp_btnR = '1' then
                    reloj_puesta_en_hora_dp_estado_pulsador <= "001";
                else
                    reloj_puesta_en_hora_dp_estado_pulsador <= "000";
                end if;
            when others =>
                reloj_puesta_en_hora_dp_cont_filtro <= 0;
                reloj_puesta_en_hora_dp_estado_pulsador <= "000";
        end case;
      end if;
end process;

-- process de las salidas del pulsador

process(reloj_puesta_en_hora_dp_estado_pulsador)
begin
    case reloj_puesta_en_hora_dp_estado_pulsador is
        when "000" =>
            reloj_puesta_en_hora_dp_salida      <= '0';
            reloj_puesta_en_hora_dp_flag_suma   <= '0';
            reloj_puesta_en_hora_dp_flag_resta  <= '0';
        when "001" =>
            reloj_puesta_en_hora_dp_salida      <= '0';
            reloj_puesta_en_hora_dp_flag_suma   <= '0';
            reloj_puesta_en_hora_dp_flag_resta  <= '0';
        when "010" =>
            reloj_puesta_en_hora_dp_salida      <= '0';
            reloj_puesta_en_hora_dp_flag_suma   <= '0';
            reloj_puesta_en_hora_dp_flag_resta  <= '0';
        when "011" =>
            reloj_puesta_en_hora_dp_salida      <= '1';
            reloj_puesta_en_hora_dp_flag_suma   <= '1';
            reloj_puesta_en_hora_dp_flag_resta  <= '0';
        when "100" =>
            reloj_puesta_en_hora_dp_salida      <= '0';
            reloj_puesta_en_hora_dp_flag_suma   <= '0';
            reloj_puesta_en_hora_dp_flag_resta  <= '0';
        when "101" =>
            reloj_puesta_en_hora_dp_salida      <= '1';
            reloj_puesta_en_hora_dp_flag_suma   <= '0';
            reloj_puesta_en_hora_dp_flag_resta  <= '1';
        when others =>
            reloj_puesta_en_hora_dp_salida      <= '0';
            reloj_puesta_en_hora_dp_flag_suma   <= '0';
            reloj_puesta_en_hora_dp_flag_resta  <= '0';
    end case;
end process;

-- process de sumar/restar el reloj_puesta_en_hora_dp_display_m_h

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_puesta_en_hora_dp_display_m_h <= '0';
    elsif rising_edge(clk) then
        if reloj_puesta_en_hora_dp_salida = '1' then
            if reloj_puesta_en_hora_dp_flag_suma = '1' then
                -- sumar si esta a 0
                if reloj_puesta_en_hora_dp_display_m_h = '0' then
                    reloj_puesta_en_hora_dp_display_m_h <= '1';
                end if;
            elsif reloj_puesta_en_hora_dp_flag_resta = '1' then
                -- restar si esta a 1
                if reloj_puesta_en_hora_dp_display_m_h = '1' then
                    reloj_puesta_en_hora_dp_display_m_h <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--             LOGICA DEL RELOJ - PULSADOR - SUMAR - RESTAR
-- ####################################################################
-- ####################################################################

-- process del automata pulsador dedo

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_puesta_en_hora_estado_pulsador <= "000";
        reloj_puesta_en_hora_cont_filtro <= 0;
    elsif rising_edge(clk) then
        case reloj_puesta_en_hora_estado_pulsador is
            when "000" => -- INICIO
                reloj_puesta_en_hora_cont_filtro <= 0;
                if reloj_puesta_en_hora_sumar = '1' or reloj_puesta_en_hora_restar = '1' then
                    reloj_puesta_en_hora_estado_pulsador <= "001";
                else
                    reloj_puesta_en_hora_estado_pulsador <= "000";
                end if;  
            when "001" => -- FILTRADO
                reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                if (reloj_puesta_en_hora_sumar = '1' or reloj_puesta_en_hora_restar = '1') and reloj_puesta_en_hora_cont_filtro < 100000 then
                    reloj_puesta_en_hora_estado_pulsador <= "001";
                elsif (reloj_puesta_en_hora_sumar = '1' or reloj_puesta_en_hora_restar = '1') and reloj_puesta_en_hora_cont_filtro = 100000 then
                    if reloj_puesta_en_hora_sumar = '1'then
                        reloj_puesta_en_hora_estado_pulsador <= "010";
                    elsif reloj_puesta_en_hora_restar = '1' then
                        reloj_puesta_en_hora_estado_pulsador <= "100";
                    end if;
                else
                    reloj_puesta_en_hora_estado_pulsador <= "000";
                end if;
            when "010" => -- UNO +
                reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                if reloj_puesta_en_hora_sumar = '1' and reloj_puesta_en_hora_cont_filtro < 200000000 then
                    reloj_puesta_en_hora_estado_pulsador <= "010";
                elsif reloj_puesta_en_hora_sumar = '1' and reloj_puesta_en_hora_cont_filtro = 200000000 then
                    reloj_puesta_en_hora_estado_pulsador <= "110";
                elsif reloj_puesta_en_hora_sumar = '0' then
                    reloj_puesta_en_hora_estado_pulsador <= "011";
                end if;
            when "011" => -- SUMA
                reloj_puesta_en_hora_cont_filtro <= 0;
                if reloj_puesta_en_hora_sumar = '1' then
                    reloj_puesta_en_hora_estado_pulsador <= "001";
                else
                    reloj_puesta_en_hora_estado_pulsador <= "000";
                end if;
            when "100" => -- UNO -
                reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                if reloj_puesta_en_hora_restar = '1' and reloj_puesta_en_hora_cont_filtro < 200000000 then
                    reloj_puesta_en_hora_estado_pulsador <= "100";
                elsif reloj_puesta_en_hora_restar = '1' and reloj_puesta_en_hora_cont_filtro = 200000000 then
                    reloj_puesta_en_hora_estado_pulsador <= "110";
                elsif reloj_puesta_en_hora_restar = '0' then
                    reloj_puesta_en_hora_estado_pulsador <= "101";
                end if;
            when "101" => -- RESTA
                reloj_puesta_en_hora_cont_filtro <= 0;
                if reloj_puesta_en_hora_restar = '1' then
                    reloj_puesta_en_hora_estado_pulsador <= "001";
                else
                    reloj_puesta_en_hora_estado_pulsador <= "000";
                end if;
            when "110" => -- START_RAPIDO
                reloj_puesta_en_hora_cont_filtro <= 0;
                if reloj_puesta_en_hora_sumar = '1' or reloj_puesta_en_hora_restar = '1' then
                    reloj_puesta_en_hora_estado_pulsador <= "111";
                elsif reloj_puesta_en_hora_sumar = '0' and reloj_puesta_en_hora_restar = '0' then
                    reloj_puesta_en_hora_estado_pulsador <= "000";
                end if;
            when others => -- RAPIDO
                reloj_puesta_en_hora_cont_filtro <= reloj_puesta_en_hora_cont_filtro + 1;
                if (reloj_puesta_en_hora_sumar = '1' or reloj_puesta_en_hora_restar = '1') and reloj_puesta_en_hora_cont_filtro < 20000000 then
                    reloj_puesta_en_hora_estado_pulsador <= "111";
                elsif (reloj_puesta_en_hora_sumar = '1' or reloj_puesta_en_hora_restar = '1') and reloj_puesta_en_hora_cont_filtro = 20000000 then
                    reloj_puesta_en_hora_estado_pulsador <= "110";
                elsif reloj_puesta_en_hora_sumar = '0' and reloj_puesta_en_hora_restar = '0' then
                    reloj_puesta_en_hora_estado_pulsador <= "000";
                end if;
        end case;
      end if;
end process;

-- process de las salidas pulsador dedo

process(reloj_puesta_en_hora_estado_pulsador, reloj_puesta_en_hora_sumar, reloj_puesta_en_hora_restar, reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_puesta_en_hora_flag_salida    <= '0';
        reloj_puesta_en_hora_flag_suma      <= '0';
        reloj_puesta_en_hora_flag_resta     <= '0';
    elsif rising_edge(clk) then
        case reloj_puesta_en_hora_estado_pulsador is
            when "000" =>
                reloj_puesta_en_hora_flag_salida    <= '0';
                reloj_puesta_en_hora_flag_suma      <= '0';
                reloj_puesta_en_hora_flag_resta     <= '0';
            when "001" =>
                reloj_puesta_en_hora_flag_salida    <= '0';
                reloj_puesta_en_hora_flag_suma      <= '0';
                reloj_puesta_en_hora_flag_resta     <= '0';
            when "010" =>
                reloj_puesta_en_hora_flag_salida    <= '0';
                reloj_puesta_en_hora_flag_suma      <= '0';
                reloj_puesta_en_hora_flag_resta     <= '0';
            when "011" =>
                reloj_puesta_en_hora_flag_salida    <= '1';
                reloj_puesta_en_hora_flag_suma      <= '1';
                reloj_puesta_en_hora_flag_resta     <= '0';
            when "100" =>
                reloj_puesta_en_hora_flag_salida    <= '0';
                reloj_puesta_en_hora_flag_suma      <= '0';
                reloj_puesta_en_hora_flag_resta     <= '0';
            when "101" =>
                reloj_puesta_en_hora_flag_salida    <= '1';
                reloj_puesta_en_hora_flag_suma      <= '0';
                reloj_puesta_en_hora_flag_resta     <= '1';
            when "110" =>
                reloj_puesta_en_hora_flag_salida <= '1';
                if reloj_puesta_en_hora_sumar = '1' then
                    reloj_puesta_en_hora_flag_suma <= '1';
                    reloj_puesta_en_hora_flag_resta <= '0';
                elsif reloj_puesta_en_hora_restar = '1' then
                    reloj_puesta_en_hora_flag_suma <= '0';
                    reloj_puesta_en_hora_flag_resta <= '1';
                end if;
            when others =>
                reloj_puesta_en_hora_flag_salida    <= '0';
                reloj_puesta_en_hora_flag_suma      <= '0';
                reloj_puesta_en_hora_flag_resta     <= '0';
        end case;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                          LED DE LA ALARMA
-- ####################################################################
-- ####################################################################

-- process del automata de la alarma del reloj

process(clk, reloj_inicio, reloj_alarma_sonar)
begin
    if reloj_inicio = '1' then
        reloj_alarma_led_estado <= "00";
        reloj_alarma_led_contflancos <= 0;
    elsif rising_edge(clk) then
        if reloj_alarma_sonar = '1' then
            case reloj_alarma_led_estado is
                when "00" =>
                    reloj_alarma_led_contflancos <= 0;
                    reloj_alarma_led_estado <= "01";
                when "01" =>
                    reloj_alarma_led_contflancos <= 1;
                    reloj_alarma_led_estado <= "10";
                when "10" =>
                    reloj_alarma_led_contflancos <= reloj_alarma_led_contflancos + 1;
                    if reloj_alarma_led_contflancos = 50000000 then
                        reloj_alarma_led_estado <= "11";
                    else
                        reloj_alarma_led_estado <= "10";
                    end if;
                when others =>
                    reloj_alarma_led_contflancos <= reloj_alarma_led_contflancos + 1;
                    if reloj_alarma_led_contflancos = 100000000 then
                        reloj_alarma_led_estado <= "01";
                    else
                        reloj_alarma_led_estado <= "11";
                    end if;
            end case;
        end if;
    end if;
end process;

-- process de salidas del led de la alarma del reloj

process(reloj_alarma_led_estado, reloj_alarma_sonar)
begin
    if reloj_alarma_sonar = '1' then
        case reloj_alarma_led_estado is
            when "00" => reloj_alarma_led <= '0';
            when "01" => reloj_alarma_led <= '1';
            when "10" => reloj_alarma_led <= '1';
            when others => reloj_alarma_led <= '0';
        end case;
    else
        reloj_alarma_led <= '0';
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                          LOGICA DE SNOOZE
-- ####################################################################
-- ####################################################################

-- process del automata del pulsador de snooze

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_alarma_snooze_estado_pulsador <= "000";
        reloj_alarma_snooze_cont_filtro <= 0;
    elsif rising_edge(clk) then
        case reloj_alarma_snooze_estado_pulsador is
            when "000" => -- INICIO
                reloj_alarma_snooze_cont_filtro <= 0;
                if reloj_alarma_snooze_btnU = '1' or reloj_alarma_snooze_btnD = '1' then
                    reloj_alarma_snooze_estado_pulsador <= "001";
                else
                    reloj_alarma_snooze_estado_pulsador <= "000";
                end if;  
            when "001" => -- FILTRADO
                reloj_alarma_snooze_cont_filtro <= reloj_alarma_snooze_cont_filtro + 1;
                if (reloj_alarma_snooze_btnU = '1' or reloj_alarma_snooze_btnD = '1') and reloj_alarma_snooze_cont_filtro < 100000 then
                    reloj_alarma_snooze_estado_pulsador <= "001";
                elsif (reloj_alarma_snooze_btnU = '1' or reloj_alarma_snooze_btnD = '1') and reloj_alarma_snooze_cont_filtro = 100000 then
                    if reloj_alarma_snooze_btnU = '1'then
                        reloj_alarma_snooze_estado_pulsador <= "010";
                    elsif reloj_alarma_snooze_btnD = '1' then
                        reloj_alarma_snooze_estado_pulsador <= "100";
                    end if;
                else
                    reloj_alarma_snooze_estado_pulsador <= "000";
                end if;
            when "010" => -- UNO +
                reloj_alarma_snooze_cont_filtro <= 0;
                if reloj_alarma_snooze_btnU = '1' then
                    reloj_alarma_snooze_estado_pulsador <= "010";
                else
                    reloj_alarma_snooze_estado_pulsador <= "011";
                end if;
            when "011" => -- SUMA
                reloj_alarma_snooze_cont_filtro <= 0;
                if reloj_alarma_snooze_btnU = '1' then
                    reloj_alarma_snooze_estado_pulsador <= "001";
                else
                    reloj_alarma_snooze_estado_pulsador <= "000";
                end if;
            when "100" => -- UNO -
                reloj_alarma_snooze_cont_filtro <= 0;
                if reloj_alarma_snooze_btnD = '1' then
                    reloj_alarma_snooze_estado_pulsador <= "100";
                else
                    reloj_alarma_snooze_estado_pulsador <= "101";
                end if;
            when "101" => -- RESTA
                reloj_alarma_snooze_cont_filtro <= 0;
                if reloj_alarma_snooze_btnD = '1' then
                    reloj_alarma_snooze_estado_pulsador <= "001";
                else
                    reloj_alarma_snooze_estado_pulsador <= "000";
                end if;
            when others =>
                reloj_alarma_snooze_cont_filtro <= 0;
                reloj_alarma_snooze_estado_pulsador <= "000";
        end case;
      end if;
end process;

-- process de las salidas del pulsador de snooze

process(reloj_alarma_snooze_estado_pulsador, clk, reloj_inicio)
begin
    if reloj_inicio = '1' then
        reloj_alarma_snooze_salida          <= '0';
        reloj_alarma_snooze_salida_suma     <= '0';
        reloj_alarma_snooze_salida_resta    <= '0';
    elsif rising_edge(clk) then
        case reloj_alarma_snooze_estado_pulsador is
            when "000" =>
                reloj_alarma_snooze_salida          <= '0';
                reloj_alarma_snooze_salida_suma     <= '0';
                reloj_alarma_snooze_salida_resta    <= '0';
            when "001" =>
                reloj_alarma_snooze_salida          <= '0';
                reloj_alarma_snooze_salida_suma     <= '0';
                reloj_alarma_snooze_salida_resta    <= '0';
            when "010" =>
                reloj_alarma_snooze_salida          <= '0';
                reloj_alarma_snooze_salida_suma     <= '0';
                reloj_alarma_snooze_salida_resta    <= '0';
            when "011" =>
                reloj_alarma_snooze_salida          <= '1';
                reloj_alarma_snooze_salida_suma     <= '1';
                reloj_alarma_snooze_salida_resta    <= '0';
            when "100" =>
                reloj_alarma_snooze_salida          <= '0';
                reloj_alarma_snooze_salida_suma     <= '0';
                reloj_alarma_snooze_salida_resta    <= '0';
            when "101" =>
                reloj_alarma_snooze_salida          <= '1';
                reloj_alarma_snooze_salida_suma     <= '0';
                reloj_alarma_snooze_salida_resta    <= '1';
            when others =>
                reloj_alarma_snooze_salida          <= '0';
                reloj_alarma_snooze_salida_suma     <= '0';
                reloj_alarma_snooze_salida_resta    <= '0';
        end case;
    end if;
end process;

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

process(servo_selector_aspersor_mode, servo_aspersor_cont,
servo_selector_input_mode, servo_selector_switches, servo_suma_o_resta,
servo_numero_int, reloj_alarma_sonar)
begin

    -- servo_grados por aspersor

    if servo_selector_aspersor_mode = '1' or reloj_alarma_sonar = '1' then
        case servo_aspersor_cont is
            when "0000" => servo_grados <= 10;
            when "0001" => servo_grados <= 20;
            when "0010" => servo_grados <= 30;
            when "0011" => servo_grados <= 40;
            when "0100" => servo_grados <= 50;
            when "0101" => servo_grados <= 60;
            when "0110" => servo_grados <= 70;
            when "0111" => servo_grados <= 80;
            when "1000" => servo_grados <= 90;
            when "1001" => servo_grados <= 100;
            when "1010" => servo_grados <= 110;
            when "1011" => servo_grados <= 120;
            when "1100" => servo_grados <= 130;
            when "1101" => servo_grados <= 140;
            when "1110" => servo_grados <= 150;
            when others => servo_grados <= 170;
        end case;

    -- servo_grados por switches

    elsif servo_selector_input_mode = '0' then
        case servo_selector_switches is
            when "0000" => servo_grados <= 10;
            when "0001" => servo_grados <= 20;
            when "0010" => servo_grados <= 30;
            when "0011" => servo_grados <= 40;
            when "0100" => servo_grados <= 50;
            when "0101" => servo_grados <= 60;
            when "0110" => servo_grados <= 70;
            when "0111" => servo_grados <= 80;
            when "1000" => servo_grados <= 90;
            when "1001" => servo_grados <= 100;
            when "1010" => servo_grados <= 110;
            when "1011" => servo_grados <= 120;
            when "1100" => servo_grados <= 130;
            when "1101" => servo_grados <= 140;
            when "1110" => servo_grados <= 150;
            when others => servo_grados <= 170;
        end case;

    -- servo_grados por dedo

    else
        servo_grados <= servo_numero_int;
    end if;
end process;

-- process del automata del pwm del servo

process(clk, servo_inicio)
begin
    if servo_inicio = '1' then
        servo_estado_servo <= "00";
        servo_cont_flancos <= 0;
    elsif rising_edge(clk) then
        case servo_estado_servo is
            when "00" =>
                servo_cont_flancos <= 0;
                servo_estado_servo <= "01";
            when "01" =>
                servo_cont_flancos <= 1;
                servo_estado_servo <= "10";
            when "10" =>
                servo_cont_flancos <= servo_cont_flancos + 1;
                if servo_cont_flancos = servo_pwm_longitud_pulso then
                    servo_estado_servo <= "11";
                else
                    servo_estado_servo <= "10";
                end if;
            when others =>
                servo_cont_flancos <= servo_cont_flancos + 1;
                if servo_cont_flancos = 2000000 then
                    servo_estado_servo <= "01";
                else
                    servo_estado_servo <= "11";
                end if;
        end case;
    end if;
end process;

-- process de salidas del servo

process(servo_estado_servo)
begin
    case servo_estado_servo is
        when "00" => servo <= '0';
        when "01" => servo <= '1';
        when "10" => servo <= '1';
        when others => servo <= '0';
    end case;
end process;

-- ####################################################################
-- ####################################################################
--                       LOGICA DEL SERVO-RELOJ
-- ####################################################################
-- ####################################################################

-- proceso de reloj

process(servo_inicio, clk)
begin
    if servo_inicio = '1' then
        servo_cont_base <= 0;
    elsif rising_edge(clk) then
        if servo_cont_base = servo_tope_freq then
            servo_cont_base <= 0;
        else
            servo_cont_base <= servo_cont_base + 1;
        end if;
    end if;
end process;

-- process de cambio de vel.

process(servo_segundos_offset)
begin
    if servo_segundos_offset = "XXX1" then
        servo_tope_freq <= 100000000;
    elsif servo_segundos_offset = "XX10" then
        servo_tope_freq <= 200000000;
    elsif servo_segundos_offset = "X100" then
        servo_tope_freq <= 300000000;
    elsif servo_segundos_offset = "1000" then
        servo_tope_freq <= 400000000;
    else
        servo_tope_freq <= 100000000;
    end if;
end process;

-- process de cambio de servo_aspersor_cont

process(servo_inicio, clk)
begin
    if servo_inicio = '1' then
        servo_suma_o_resta <= '0';
        servo_aspersor_cont <= "0000";
    elsif rising_edge(clk) then
        if servo_selector_aspersor_mode = '1' or reloj_alarma_sonar = '1' then
            if servo_cont_base = servo_tope_freq then
                if servo_aspersor_cont = "1111" then
                    servo_suma_o_resta <= '1';
                elsif servo_aspersor_cont = "0000" then
                    servo_suma_o_resta <= '0';
                end if;
                if servo_suma_o_resta = '0' and servo_aspersor_cont /= "1111" then
                    servo_aspersor_cont <= servo_aspersor_cont + 1;
                elsif servo_suma_o_resta = '1' and servo_aspersor_cont /= "0000" then
                    servo_aspersor_cont <= servo_aspersor_cont - 1;
                end if;
            end if;
        else
            servo_suma_o_resta <= '0';
            servo_aspersor_cont <= "0000";
        end if;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                      LOGICA DEL SERVO-PULSADOR
-- ####################################################################
-- ####################################################################

-- process del automata pulsador dedo

process(servo_inicio, clk)
begin
    if servo_inicio = '1' then
        servo_estado_pulsador <= "000";
        servo_cont_filtro <= 0;
    elsif rising_edge(clk) then
        case servo_estado_pulsador is
            when "000" => -- INICIO
                servo_cont_filtro <= 0;
                if servo_botonMas = '1' or servo_botonMenos = '1' then
                    servo_estado_pulsador <= "001";
                else
                    servo_estado_pulsador <= "000";
                end if;
            when "001" => -- FILTRADO
                servo_cont_filtro <= servo_cont_filtro + 1;
                if (servo_botonMas = '1' or servo_botonMenos = '1') and servo_cont_filtro < servo_freq_min then
                    servo_estado_pulsador <= "001";
                elsif (servo_botonMas = '1' or servo_botonMenos = '1') and servo_cont_filtro = servo_freq_min then
                    if servo_botonMas = '1'then
                        servo_estado_pulsador <= "010";
                    elsif servo_botonMenos = '1' then
                        servo_estado_pulsador <= "100";
                    end if;
                else
                    servo_estado_pulsador <= "000";
                end if;
            when "010" => -- UNO +
                servo_cont_filtro <= servo_cont_filtro + 1;
                if servo_botonMas = '1' and servo_cont_filtro < 200000000 then
                    servo_estado_pulsador <= "010";
                elsif servo_botonMas = '1' and servo_cont_filtro = 200000000 then
                    servo_estado_pulsador <= "110";
                elsif servo_botonMas = '0' then
                    servo_estado_pulsador <= "011";
                end if;
            when "011" => -- SUMA
                servo_cont_filtro <= 0;
                if servo_botonMas = '1' then
                    servo_estado_pulsador <= "001";
                else
                    servo_estado_pulsador <= "000";
                end if;
            when "100" => -- UNO -
                servo_cont_filtro <= servo_cont_filtro + 1;
                if servo_botonMenos = '1' and servo_cont_filtro < 200000000 then
                    servo_estado_pulsador <= "100";
                elsif servo_botonMenos = '1' and servo_cont_filtro = 200000000 then
                    servo_estado_pulsador <= "110";
                elsif servo_botonMenos = '0' then
                    servo_estado_pulsador <= "101";
                end if;
            when "101" => -- RESTA
                servo_cont_filtro <= 0;
                if servo_botonMenos = '1' then
                    servo_estado_pulsador <= "001";
                else
                    servo_estado_pulsador <= "000";
                end if;
            when "110" => -- START_RAPIDO
                servo_cont_filtro <= 0;
                if servo_botonMas = '1' or servo_botonMenos = '1' then
                    servo_estado_pulsador <= "111";
                elsif servo_botonMas = '0' and servo_botonMenos = '0' then
                    servo_estado_pulsador <= "000";
                end if;
            when others => -- RAPIDO
                servo_cont_filtro <= servo_cont_filtro + 1;
                if (servo_botonMas = '1' or servo_botonMenos = '1') and servo_cont_filtro < 20000000 then
                    servo_estado_pulsador <= "111";
                elsif (servo_botonMas = '1' or servo_botonMenos = '1') and servo_cont_filtro = 20000000 then
                    servo_estado_pulsador <= "110";
                elsif servo_botonMas = '0' and servo_botonMenos = '0' then
                    servo_estado_pulsador <= "000";
                end if;
        end case;
      end if;
end process;

-- process de las salidas pulsador dedo

process(servo_estado_pulsador, servo_botonMas, servo_botonMenos, servo_inicio, clk)
begin
    if servo_inicio = '1' then
        servo_salida <= '0';
        servo_flag_suma <= '0';
        servo_flag_resta <= '0';
    elsif rising_edge(clk) then
        case servo_estado_pulsador is
            when "000" =>
                servo_salida <= '0';
                servo_flag_suma <= '0';
                servo_flag_resta <= '0';
            when "001" =>
                servo_salida <= '0';
                servo_flag_suma <= '0';
                servo_flag_resta <= '0';
            when "010" =>
                servo_salida <= '0';
                servo_flag_suma <= '0';
                servo_flag_resta <= '0';
            when "011" =>
                servo_salida <= '1';
                servo_flag_suma <= '1';
                servo_flag_resta <= '0';
            when "100" =>
                servo_salida <= '0';
                servo_flag_suma <= '0';
                servo_flag_resta <= '0';
            when "101" =>
                servo_salida <= '1';
                servo_flag_suma <= '0';
                servo_flag_resta <= '1';
            when "110" =>
                servo_salida <= '1';
                if servo_botonMas = '1' then
                    servo_flag_suma <= '1';
                    servo_flag_resta <= '0';
                elsif servo_botonMenos = '1' then
                    servo_flag_suma <= '0';
                    servo_flag_resta <= '1';
                end if;
            when others =>
                servo_salida <= '0';
                servo_flag_suma <= '0';
                servo_flag_resta <= '0';
        end case;
    end if;
end process;

-- process de sumar/restar decenas

process(servo_inicio, clk)
begin
    if servo_inicio = '1' then
        servo_contador_decenas <= "0001";
    elsif rising_edge(clk) then
        if servo_salida = '1' then
            if servo_flag_suma = '1' then
                if servo_contador_decenas = 7 and servo_contador_centenas = 1 then
                    servo_contador_decenas <= "0111";
                elsif servo_contador_decenas = 9 then
                    servo_contador_decenas <= "0000";
                else
                    servo_contador_decenas <= servo_contador_decenas + 1;
                end if;
            elsif servo_flag_resta = '1' then
                if servo_contador_decenas = 1 and servo_contador_centenas = 0 then
                    servo_contador_decenas <= "0001";
                elsif servo_contador_decenas = 0 then
                    servo_contador_decenas <= "1001";
                else
                    servo_contador_decenas <= servo_contador_decenas - 1;
                end if;
            end if;
       end if;
    end if;
end process;

-- process de sumar/restar centenas

process(servo_inicio, clk)
begin
    if servo_inicio = '1' then
        servo_contador_centenas <= "0000";
    elsif rising_edge(clk) then
        if servo_salida = '1' then
            if servo_flag_suma = '1' then
                if servo_contador_decenas = 9 then
                    servo_contador_centenas <= servo_contador_centenas + 1;
                end if;
            elsif servo_flag_resta = '1' then
                if servo_contador_centenas = 1 and servo_contador_decenas = 0 then
                    servo_contador_centenas <= servo_contador_centenas - 1;
                end if;
            end if;
       end if;
    end if;
end process;

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

process(clk, binario_bcd_inicio)
begin
    if binario_bcd_inicio = '1' then
        binario_bcd_vector <= "00000000000000000000000000";
        binario_bcd_estado_conversion <= "00";
        binario_bcd_contador_desplazamientos <= 0;
        binario_bcd_unidades <= "0000";
        binario_bcd_decenas <= "0000";
        binario_bcd_centenas <= "0000";
        binario_bcd_millar <= "0000";
        binario_bcd_fin <= '0';
    elsif rising_edge(clk) then
        if binario_bcd_cont = 0 and binario_bcd_fin = '0' then
            case binario_bcd_estado_conversion is
                -- start
                when "00" =>
                    binario_bcd_contador_desplazamientos <= 0;
                    binario_bcd_vector <= "0000000000000000" & binario_bcd_binario;
                    if binario_bcd_enable = '1' then
                        binario_bcd_estado_conversion <= "01";
                    else
                        binario_bcd_estado_conversion <= "00";
                    end if;
                    binario_bcd_fin <= '0';
                -- despl
                when "01" =>
                    binario_bcd_contador_desplazamientos <= binario_bcd_contador_desplazamientos + 1;
                    binario_bcd_vector <= binario_bcd_vector(24 downto 0) & '0';
                    if binario_bcd_contador_desplazamientos < 9 then
                        binario_bcd_estado_conversion <= "10";
                    else
                        binario_bcd_estado_conversion <= "11";
                    end if;
                    binario_bcd_fin <= '0';
                -- ¿sumar+3?
                when "10" =>
                    binario_bcd_contador_desplazamientos <= binario_bcd_contador_desplazamientos;
                    if binario_bcd_vector(13 downto 10) > 4 then
                        binario_bcd_vector(13 downto 10) <= binario_bcd_vector(13 downto 10) + "0011";
                    end if;
                    if binario_bcd_vector(17 downto 14) > 4 then
                        binario_bcd_vector(17 downto 14) <= binario_bcd_vector(17 downto 14) + "0011";
                    end if;
                    if binario_bcd_vector(21 downto 18) > 4 then
                        binario_bcd_vector(21 downto 18) <= binario_bcd_vector(21 downto 18) + "0011";
                    end if;
                    if binario_bcd_vector(25 downto 22) > 4 then
                        binario_bcd_vector(25 downto 22) <= binario_bcd_vector(25 downto 22) + "0011";
                    end if;
                    binario_bcd_estado_conversion <= "01";
                    binario_bcd_fin <= '0';
                -- final
                when others =>
                    binario_bcd_contador_desplazamientos <= binario_bcd_contador_desplazamientos;
                    binario_bcd_vector <= binario_bcd_vector;
                    binario_bcd_estado_conversion <= "00";
                    binario_bcd_fin <= '1';
                    binario_bcd_unidades <= binario_bcd_vector(13 downto 10);
                    binario_bcd_decenas <= binario_bcd_vector(17 downto 14);
                    binario_bcd_centenas <= binario_bcd_vector(21 downto 18);
                    binario_bcd_millar <= binario_bcd_vector(25 downto 22);
            end case;
        end if;
    end if;
end process;

-- process de conteo de segundos

process(clk, binario_bcd_inicio)
begin
    if binario_bcd_inicio = '1' then
        binario_bcd_cont <= 0;
    elsif rising_edge(clk) then
        if binario_bcd_cont = binario_bcd_tope_freq then
            binario_bcd_cont <= 0;
        else
            binario_bcd_cont <= binario_bcd_cont + 1;
        end if;
    end if;
end process;

-- process de cambio de vel.

process(binario_bcd_modo_lento_rapido)
begin
    if binario_bcd_modo_lento_rapido = '1' then
        binario_bcd_tope_freq <= 0;
    else
        binario_bcd_tope_freq <= 50000000;
    end if;
end process;

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

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_centesimas_temp <= "0000";
        cronom_cont_decimas_temp <= "0000";
        cronom_cont_segs_unidades_temp <= "0000";
        cronom_cont_segs_decenas_temp <= "0000";
    elsif rising_edge(clk) then
        if cronom_split = '0' then
            cronom_cont_centesimas_temp     <= cronom_cont_centesimas;
            cronom_cont_decimas_temp        <= cronom_cont_decimas;
            cronom_cont_segs_unidades_temp  <= cronom_cont_segs_unidades;
            cronom_cont_segs_decenas_temp   <= cronom_cont_segs_decenas;
        end if;
    end if;
end process;

-- process de reloj del cronometro

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_base <= 0;
    elsif rising_edge(clk) then
        if cronom_cont_base = cronom_tope_freq then
            cronom_cont_base <= 0;
        else
            cronom_cont_base <= cronom_cont_base + 1;
        end if;
    end if;
end process;

-- process de monitoreo de segundos.centesimas

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_centesimas <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas
            if cronom_cont_base = cronom_tope_freq then
                if cronom_cont_centesimas = "1001" then
                    cronom_cont_centesimas <= "0000";
                else
                    cronom_cont_centesimas <= cronom_cont_centesimas + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de segundos.decimas

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_decimas <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" then
                if cronom_cont_decimas = "1001" then
                    cronom_cont_decimas <= "0000";
                else
                    cronom_cont_decimas <= cronom_cont_decimas + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de segundos.unidades

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_segs_unidades <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" and cronom_cont_decimas = "1001" then
                if cronom_cont_segs_unidades = "1001" then
                    cronom_cont_segs_unidades <= "0000";
                else
                    cronom_cont_segs_unidades <= cronom_cont_segs_unidades + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de segundos.decenas

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_segs_decenas <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" and cronom_cont_decimas = "1001" and cronom_cont_segs_unidades = "1001" then
                if cronom_cont_segs_decenas = "0101" then
                    cronom_cont_segs_decenas <= "0000";
                else
                    cronom_cont_segs_decenas <= cronom_cont_segs_decenas + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de minutos.unidades

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_mins_unidades <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" and cronom_cont_decimas = "1001" and cronom_cont_segs_unidades = "1001" and cronom_cont_segs_decenas = "0101" then
                if cronom_cont_mins_unidades = "1001" then
                    cronom_cont_mins_unidades <= "0000";
                else
                    cronom_cont_mins_unidades <= cronom_cont_mins_unidades + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de minutos.decenas

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_mins_decenas <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5 y las minutos.unidades = 9
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" and cronom_cont_decimas = "1001" and cronom_cont_segs_unidades = "1001" and cronom_cont_segs_decenas = "0101" and cronom_cont_mins_unidades = "1001" then
                if cronom_cont_mins_decenas = "0101" then
                    cronom_cont_mins_decenas <= "0000";
                else
                    cronom_cont_mins_decenas <= cronom_cont_mins_decenas + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de horas.unidades

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_horas_unidades <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" and cronom_cont_decimas = "1001" and cronom_cont_segs_unidades = "1001" and cronom_cont_segs_decenas = "0101" and cronom_cont_mins_unidades = "1001" and cronom_cont_mins_decenas = "0101" then
                if cronom_cont_horas_unidades = "1001" then
                    cronom_cont_horas_unidades <= "0000";
                elsif cronom_cont_horas_unidades = "0011" and cronom_cont_horas_decenas = "0010" then
                    cronom_cont_horas_unidades <= "0000";
                else
                    cronom_cont_horas_unidades <= cronom_cont_horas_unidades + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- process de monitoreo de horas.decenas

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_cont_horas_decenas <= "0000";
    elsif rising_edge(clk) then
        if cronom_pausa = '0' then
            -- si ha pasado una segundos.centesimas y las segundos.centesimas = 9 y las segundos.decimas = 9 y las segundos.unidades = 9 y
            -- las segundos.decenas = 5 y las minutos.unidades = 9 y las minutos.decenas = 5 y las horas.unidades = 9 or 3
            if cronom_cont_base = cronom_tope_freq and cronom_cont_centesimas = "1001" and cronom_cont_decimas = "1001" and cronom_cont_segs_unidades = "1001" and cronom_cont_segs_decenas = "0101" and cronom_cont_mins_unidades = "1001" and cronom_cont_mins_decenas = "0101" and (cronom_cont_horas_unidades = "1001" or cronom_cont_horas_unidades = "0011") then
                if cronom_cont_horas_decenas = "0010" then
                    cronom_cont_horas_decenas <= "0000";
                elsif cronom_cont_horas_unidades = "1001" then
                    cronom_cont_horas_decenas <= cronom_cont_horas_decenas + 1;
                end if;
            end if;
        elsif cronom_pausa = '1' then
            -- hacer cosas
        end if;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                 LOGICA DEL PULSADOR DE DEDO STOP SPLIT
-- ####################################################################
-- ####################################################################

-- process del automata del pulsador

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_func_estado_pulsador <= "000";
        cronom_func_cont_filtro <= 0;
    elsif rising_edge(clk) then
        case cronom_func_estado_pulsador is
            when "000" => -- INICIO
                cronom_func_cont_filtro <= 0;
                if cronom_func_btnU_stop = '1' or cronom_func_btnD_split = '1' then
                    cronom_func_estado_pulsador <= "001";
                else
                    cronom_func_estado_pulsador <= "000";
                end if;  
            when "001" => -- FILTRADO
                cronom_func_cont_filtro <= cronom_func_cont_filtro + 1;
                if (cronom_func_btnU_stop = '1' or cronom_func_btnD_split = '1') and cronom_func_cont_filtro < 100000 then
                    cronom_func_estado_pulsador <= "001";
                elsif (cronom_func_btnU_stop = '1' or cronom_func_btnD_split = '1') and cronom_func_cont_filtro = 100000 then
                    if cronom_func_btnU_stop = '1'then
                        cronom_func_estado_pulsador <= "010";
                    elsif cronom_func_btnD_split = '1' then
                        cronom_func_estado_pulsador <= "100";
                    end if;
                else
                    cronom_func_estado_pulsador <= "000";
                end if;
            when "010" => -- UNO +
                cronom_func_cont_filtro <= 0;
                if cronom_func_btnU_stop = '1' then
                    cronom_func_estado_pulsador <= "010";
                else
                    cronom_func_estado_pulsador <= "011";
                end if;
            when "011" => -- SUMA
                cronom_func_cont_filtro <= 0;
                if cronom_func_btnU_stop = '1' then
                    cronom_func_estado_pulsador <= "001";
                else
                    cronom_func_estado_pulsador <= "000";
                end if;
            when "100" => -- UNO -
                cronom_func_cont_filtro <= 0;
                if cronom_func_btnD_split = '1' then
                    cronom_func_estado_pulsador <= "100";
                else
                    cronom_func_estado_pulsador <= "101";
                end if;
            when "101" => -- RESTA
                cronom_func_cont_filtro <= 0;
                if cronom_func_btnD_split = '1' then
                    cronom_func_estado_pulsador <= "001";
                else
                    cronom_func_estado_pulsador <= "000";
                end if;
            when others =>
                cronom_func_cont_filtro <= 0;
                cronom_func_estado_pulsador <= "000";
        end case;
      end if;
end process;

-- process de las salidas del pulsador

process(cronom_func_estado_pulsador)
begin
    case cronom_func_estado_pulsador is
        when "000" =>
            cronom_func_flag_salida      <= '0';
            cronom_func_flag_salida_flag_pausa   <= '0';
            cronom_func_flag_salida_flag_split  <= '0';
        when "001" =>
            cronom_func_flag_salida      <= '0';
            cronom_func_flag_salida_flag_pausa   <= '0';
            cronom_func_flag_salida_flag_split  <= '0';
        when "010" =>
            cronom_func_flag_salida      <= '0';
            cronom_func_flag_salida_flag_pausa   <= '0';
            cronom_func_flag_salida_flag_split  <= '0';
        when "011" =>
            cronom_func_flag_salida      <= '1';
            cronom_func_flag_salida_flag_pausa   <= '1';
            cronom_func_flag_salida_flag_split  <= '0';
        when "100" =>
            cronom_func_flag_salida      <= '0';
            cronom_func_flag_salida_flag_pausa   <= '0';
            cronom_func_flag_salida_flag_split  <= '0';
        when "101" =>
            cronom_func_flag_salida      <= '1';
            cronom_func_flag_salida_flag_pausa   <= '0';
            cronom_func_flag_salida_flag_split  <= '1';
        when others =>
            cronom_func_flag_salida      <= '0';
            cronom_func_flag_salida_flag_pausa   <= '0';
            cronom_func_flag_salida_flag_split  <= '0';
    end case;
end process;

-- process de sumar/restar el cronom_func_flag_pausa

process(cronom_inicio, clk)
begin
    if cronom_inicio = '1' then
        cronom_func_flag_pausa <= '0';
    elsif rising_edge(clk) then
        if cronom_func_flag_salida = '1' then
            if cronom_func_flag_salida_flag_pausa = '1' then
                if cronom_func_flag_pausa = '0' then
                    cronom_func_flag_pausa <= '1';
                    cronom_pausa <= '1';
                elsif cronom_func_flag_pausa = '1' then
                    cronom_func_flag_pausa <= '0';
                    cronom_pausa <= '0';
                end if;
            elsif cronom_func_flag_salida_flag_split = '1' then
                if cronom_func_flag_split = '0' then
                    cronom_func_flag_split <= '1';
                    cronom_split <= '1';
                elsif cronom_func_flag_split = '1' then
                    cronom_func_flag_split <= '0';
                    cronom_split <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

-- ####################################################################
-- ####################################################################
-- ####################################################################
-- ####################################################################
--                        LOGICA DE LA PILA
-- ####################################################################
-- ####################################################################
-- ####################################################################
-- ####################################################################

reloj_pila_entrada <=   reloj_pila_entrada_hora_decenas & 
                        reloj_pila_entrada_hora_unidades & 
                        reloj_pila_entrada_min_decenas & 
                        reloj_pila_entrada_min_unidades;

process(reloj_inicio, clk)
begin
    if reloj_inicio = '1' then
        reloj_pila_entrada_min_unidades     <= "0000";
        reloj_pila_entrada_min_decenas      <= "0000";
        reloj_pila_entrada_hora_unidades    <= "0000";
        reloj_pila_entrada_hora_decenas     <= "0000";
    elsif rising_edge(clk) then
        if reloj_pila_push = '1' and reloj_alarma_sonar = '1' then
            reloj_pila_entrada_min_unidades     <= reloj_alarma_minutos_unidades;
            reloj_pila_entrada_min_decenas      <= reloj_alarma_minutos_decenas;
            reloj_pila_entrada_hora_unidades    <= reloj_alarma_horas_unidades;
            reloj_pila_entrada_hora_decenas     <= reloj_alarma_horas_decenas;
        end if;
    end if;
end process;

-- AUTOMATA DE LA PILA
process(clk, reloj_inicio)
begin
    if reloj_inicio = '1' then
        reloj_estado_pila <= vacia;
        reloj_pila_stack_pointer <= 7;
        reloj_pila <= ("0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000", 
                       "0000000000000000", "0000000000000000", "0000000000000000", "0000000000000000");
    elsif rising_edge(clk) then
        case reloj_estado_pila is
            when idle =>
                if reloj_pila_salida_push='1' then
                    reloj_estado_pila <= mete_push;
                    reloj_pila(reloj_pila_stack_pointer) <= reloj_pila_entrada;
                elsif reloj_pila_salida_pop = '1' then
                    reloj_estado_pila <= saca_pop;
                    reloj_pila_stack_pointer <= reloj_pila_stack_pointer + 1;
                end if;
            when mete_push =>
                reloj_pila_stack_pointer <= reloj_pila_stack_pointer - 1;
                if reloj_pila_stack_pointer /= 0 then
                    reloj_estado_pila <= idle;
                else
                    reloj_estado_pila <= llena;
                end if;
            when saca_pop =>
                reloj_pila_salida <= reloj_pila(reloj_pila_stack_pointer);
                if reloj_pila_stack_pointer /= 7 then
                    reloj_estado_pila <= idle;
                else
                    reloj_estado_pila <= vacia;
                end if;
            when llena =>
                if reloj_pila_salida_pop = '1' then
                    reloj_estado_pila <= saca_pop;
                    reloj_pila_stack_pointer <= reloj_pila_stack_pointer + 1;
                elsif reloj_pila_salida_push = '1' then
                    reloj_estado_pila <= overflow;
                end if;
            when vacia =>
                if reloj_pila_salida_push = '1' then
                    reloj_estado_pila <= mete_push;
                    reloj_pila(reloj_pila_stack_pointer) <= reloj_pila_entrada;
                elsif reloj_pila_salida_pop = '1' then
                    reloj_estado_pila <= underflow;
                end if;
            when overflow =>
                if reloj_pila_salida_pop = '1' then
                    reloj_estado_pila <= saca_pop;
                    reloj_pila_stack_pointer <= reloj_pila_stack_pointer + 1;
                end if;
            when underflow =>
                if reloj_pila_salida_push = '1' then
                    reloj_estado_pila <= mete_push;
                    reloj_pila(reloj_pila_stack_pointer) <= reloj_pila_entrada;
                end if;
            when others =>
                reloj_pila_salida <= "0000000000000000";
                reloj_estado_pila <= idle;
                reloj_pila_stack_pointer <= 7;
        end case;
    end if;
end process;

process(reloj_estado_pila)
begin
    case reloj_estado_pila is
        when idle =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '0';
        when mete_push =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '0';
        when saca_pop =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '0';
        when llena =>
            reloj_pila_llena <= '1';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '0';
        when vacia =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '1';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '0';
        when overflow =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '1';
            reloj_pila_error_underflow <= '0';
        when underflow =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '1';
        when others =>
            reloj_pila_llena <= '0';
            reloj_pila_vacia <= '0';
            reloj_pila_error_overflow <= '0';
            reloj_pila_error_underflow <= '0';
    end case;
end process;
-- FIN DEL AUTOMATA DE LA PILA

-- DETECCIÃ“N Y FILTRADO DE PULSO DE PUSH
process(clk, reloj_inicio)
begin
    if reloj_inicio = '1' then
        reloj_pila_estado_push <= "00";
        reloj_pila_cont_filtro_push <= 0;
    elsif rising_edge(clk) then
        case reloj_pila_estado_push is
            when "00" =>
                reloj_pila_cont_filtro_push <= 0;
                if reloj_pila_push = '0' then
                    reloj_pila_estado_push <= "00";
                else
                    reloj_pila_estado_push <= "01";
                end if;
            when "01" =>
                reloj_pila_cont_filtro_push <= reloj_pila_cont_filtro_push+1;
                if reloj_pila_push = '1' and reloj_pila_cont_filtro_push < 100000 then
                    reloj_pila_estado_push <= "01";
                elsif reloj_pila_push = '1' and reloj_pila_cont_filtro_push = 100000 then
                    reloj_pila_estado_push <= "10";
                else --pulsador = '0'
                    reloj_pila_estado_push <= "00";
                end if;
            when "10" =>
                reloj_pila_cont_filtro_push <= 0;
                if reloj_pila_push = '1' then
                    reloj_pila_estado_push <= "10";
                else
                    if reloj_alarma_sonar = '1' then
                        reloj_pila_estado_push <= "11";
                    else
                        reloj_pila_estado_push <= "00";
                    end if;
                end if;
            when others =>
                reloj_pila_cont_filtro_push <= 0;
                reloj_pila_estado_push <= "00";
        end case;
    end if;
end process;

process(reloj_pila_estado_push)
begin
    case reloj_pila_estado_push is
        when "00"   => reloj_pila_salida_push <= '0';
        when "01"   => reloj_pila_salida_push <= '0';
        when "10"   => reloj_pila_salida_push <= '0';
        when others => reloj_pila_salida_push <= '1';
    end case;
end process;

-- DETECCIÃ“N Y FILTRADO DE PULSO DE POP
process(clk, reloj_inicio)
begin
    if reloj_inicio = '1' then
        reloj_pila_estado_pop <= "00";
    elsif rising_edge(clk) then
        case reloj_pila_estado_pop is
            when "00" =>
                reloj_pila_cont_filtro_pop <= 0;
                if reloj_pila_pop = '0' then
                    reloj_pila_estado_pop <= "00";
                else
                    reloj_pila_estado_pop <= "01";
                end if;
            when "01" =>
                reloj_pila_cont_filtro_pop <= reloj_pila_cont_filtro_pop+1;
                if reloj_pila_pop = '1' and reloj_pila_cont_filtro_pop < 100000 then
                    reloj_pila_estado_pop <= "01";
                elsif reloj_pila_pop = '1' and reloj_pila_cont_filtro_pop = 100000 then
                    reloj_pila_estado_pop <= "10";
                else --pulsador = '0'
                    reloj_pila_estado_pop <= "00";
                end if;
            when "10" =>
                reloj_pila_cont_filtro_pop <= 0;
                if reloj_pila_pop = '1' then
                    reloj_pila_estado_pop <= "10";
                else
                    reloj_pila_estado_pop <= "11";
                end if;
            when others =>
                reloj_pila_cont_filtro_pop <= 0;
                reloj_pila_estado_pop <= "00";
        end case;
    end if;
end process;

process(reloj_pila_estado_pop)
begin
    case reloj_pila_estado_pop is
        when "00"   => reloj_pila_salida_pop <= '0';
        when "01"   => reloj_pila_salida_pop <= '0';
        when "10"   => reloj_pila_salida_pop <= '0';
        when others => reloj_pila_salida_pop <= '1';
    end case;
end process;

end Behavioral;
