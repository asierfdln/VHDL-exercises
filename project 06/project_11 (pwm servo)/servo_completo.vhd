
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity main is
    port (
        clk         : in std_logic;
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
        servo       : out std_logic
    );
end main;

architecture Behavioral of main is

-- signals del servomotor

signal estado_servo: std_logic_vector (1 downto 0);
signal selector_aspersor_mode: std_logic;                   -- sw(11)
signal selector_input_mode: std_logic;                      -- sw(10)
signal aspersor_cont: std_logic_vector(3 downto 0);
signal selector_switches: std_logic_vector (3 downto 0);    -- sw(3 downto 0)
signal grados: integer range 0 to 180;
signal cont_flancos: integer range 0 to 2000000;            -- (20 ms) -> (50 Hz)
signal pwm_longitud_pulso: integer range 0 to 2000000;      -- (20 ms) -> (50 Hz)

-- signals servomotor-reloj

signal segundos_offset: std_logic_vector(3 downto 0);       -- sw(15 downto 12)
signal suma_o_resta: std_logic := '0';
signal cont_base: integer range 0 to 400000000; -- lleva la cuenta del reloj, puesto para 1-4 seg...
signal tope_freq: integer range 0 to 400000000;

-- signals del pulsador

signal estado_pulsador: std_logic_vector (2 downto 0);
signal cont_filtro: integer range 0 to 100000000;
signal salida: std_logic;
signal flag_suma: std_logic;
signal flag_resta: std_logic;
signal freq_min: integer range 0 to 100000000;
signal contador_centenas: std_logic_vector (3 downto 0);
signal contador_decenas: std_logic_vector (3 downto 0);
signal contador_base_enable: integer range 0 to 100000;
signal enable_seg_aux: std_logic_vector (3 downto 0);
signal dato: std_logic_vector (3 downto 0);

-- signals pulsador-pwm

signal contador_decenas_integer: integer range 0 to 9;
signal contador_centenas_integer: integer range 0 to 9;
signal numero_int: integer range 0 to 200;

begin

-- ####################################################################
-- ####################################################################
--                        LOGICA DEL SERVOMOTOR
-- ####################################################################
-- ####################################################################

segundos_offset <= sw(15 downto 12);
selector_aspersor_mode <= sw(11);
selector_input_mode <= sw(10);
selector_switches <= sw(3 downto 0);

-- process de designacià¸£à¸“n de grados por tiempo/switches/dedo

process(selector_aspersor_mode, aspersor_cont, selector_input_mode, selector_switches, suma_o_resta, numero_int)
begin

    -- grados por aspersor

    if selector_aspersor_mode = '1' then
        case aspersor_cont is
            when "0000" => grados <= 10;
            when "0001" => grados <= 20;
            when "0010" => grados <= 30;
            when "0011" => grados <= 40;
            when "0100" => grados <= 50;
            when "0101" => grados <= 60;
            when "0110" => grados <= 70;
            when "0111" => grados <= 80;
            when "1000" => grados <= 90;
            when "1001" => grados <= 100;
            when "1010" => grados <= 110;
            when "1011" => grados <= 120;
            when "1100" => grados <= 130;
            when "1101" => grados <= 140;
            when "1110" => grados <= 150;
            when "1111" => grados <= 170;
            when others => grados <= 10;
        end case;
        led(3 downto 0) <= aspersor_cont;
        led(8) <= suma_o_resta;

    -- grados por switches

    elsif selector_input_mode = '0' then
        case selector_switches is
            when "0000" => grados <= 10;
            when "0001" => grados <= 20;
            when "0010" => grados <= 30;
            when "0011" => grados <= 40;
            when "0100" => grados <= 50;
            when "0101" => grados <= 60;
            when "0110" => grados <= 70;
            when "0111" => grados <= 80;
            when "1000" => grados <= 90;
            when "1001" => grados <= 100;
            when "1010" => grados <= 110;
            when "1011" => grados <= 120;
            when "1100" => grados <= 130;
            when "1101" => grados <= 140;
            when "1110" => grados <= 150;
            when "1111" => grados <= 170;
            when others => grados <= 10;
        end case;
        led(3 downto 0) <= "0000";
        led(8) <= '0';

    -- grados por dedo

    else
        grados <= numero_int;
        led(3 downto 0) <= "0000";
        led(8) <= '0';
    end if;
end process;

pwm_longitud_pulso <= grados * 1111 + 50000;

-- process del automata del pwm del servo

process(clk, btnC)
begin
    if btnC = '1' then
        estado_servo <= "00";
        cont_flancos <= 0;
    elsif rising_edge(clk) then
        case estado_servo is
            when "00" =>
                cont_flancos <= 0;
                estado_servo <= "01";
            when "01" =>
                cont_flancos <= 1;
                estado_servo <= "10";
            when "10" =>
                cont_flancos <= cont_flancos + 1;
                if cont_flancos = pwm_longitud_pulso then
                    estado_servo <= "11";
                else
                    estado_servo <= "10";
                end if;
            when "11" =>
                cont_flancos <= cont_flancos + 1;
                if cont_flancos = 2000000 then
                    estado_servo <= "01";
                else
                    estado_servo <= "11";
                end if;
            when others =>
                cont_flancos <= 0;
                estado_servo <= "00";
        end case;
    end if;
end process;

-- process de salidas del servo

process(estado_servo)
begin
    case estado_servo is
        when "00" => servo <= '0';
        when "01" => servo <= '1';
        when "10" => servo <= '1';
        when "11" => servo <= '0';
        when others => servo <= '0';
    end case;
end process;

-- ####################################################################
-- ####################################################################
--                         LOGICA DEL RELOJ
-- ####################################################################
-- ####################################################################

-- proceso de reloj

process(btnC, clk)
begin
    if btnC = '1' then
        cont_base <= 0;
    elsif rising_edge(clk) then
        if cont_base = tope_freq then
            cont_base <= 0;
        else
            cont_base <= cont_base + 1;
        end if;
    end if;
end process;

-- process de cambio de vel.

process(segundos_offset)
begin
    if segundos_offset = "XXX1" then
        led(15 downto 12) <= "0001";
        tope_freq <= 100000000;
    elsif segundos_offset = "XX10" then
        led(15 downto 12) <= "0010";
        tope_freq <= 200000000;
    elsif segundos_offset = "X100" then
        led(15 downto 12) <= "0100";
        tope_freq <= 300000000;
    elsif segundos_offset = "1000" then
        led(15 downto 12) <= "1000";
        tope_freq <= 400000000;
    else
        led(15 downto 12) <= "0000";
        tope_freq <= 100000000;
    end if;
end process;

-- process de cambio de aspersor_cont

process(btnC, clk)
begin
    if btnC = '1' then
        suma_o_resta <= '0';
        aspersor_cont <= "0000";
    elsif rising_edge(clk) then
        if selector_aspersor_mode = '1' then
            if cont_base = tope_freq then
                if aspersor_cont = "1111" then
                    suma_o_resta <= '1';
                elsif aspersor_cont = "0000" then
                    suma_o_resta <= '0';
                end if;
                if suma_o_resta = '0' and aspersor_cont /= "1111" then
                    aspersor_cont <= aspersor_cont + 1;
                elsif suma_o_resta = '1' and aspersor_cont /= "0000" then
                    aspersor_cont <= aspersor_cont - 1;
                end if;
            end if;
        else
            suma_o_resta <= '0';
            aspersor_cont <= "0000";
        end if;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                         LOGICA DEL PULSADOR
-- ####################################################################
-- ####################################################################

-- process del automata del pulsador

process(btnC, clk)
begin
    if btnC = '1' then
        estado_pulsador <= "000";
        cont_filtro <= 0;
    elsif rising_edge(clk) then
        case estado_pulsador is
            when "000" => -- INICIO
                cont_filtro <= 0;
                if btnU = '1' or btnD = '1' then
                    estado_pulsador <= "001";
                else
                    estado_pulsador <= "000";
                end if;  
            when "001" => -- FILTRADO
                cont_filtro <= cont_filtro + 1;
                if (btnU = '1' or btnD = '1') and cont_filtro < 100000 then
                    estado_pulsador <= "001";
                elsif (btnU = '1' or btnD = '1') and cont_filtro = 100000 then
                    if btnU = '1'then
                        estado_pulsador <= "010";
                    elsif btnD = '1' then
                        estado_pulsador <= "100";
                    end if;
                else
                    estado_pulsador <= "000";
                end if;
            when "010" => -- UNO +
                cont_filtro <= 0;
                if btnU = '1' then
                    estado_pulsador <= "010";
                else
                    estado_pulsador <= "011";
                end if;
            when "011" => -- SUMA
                cont_filtro <= 0;
                if btnU = '1' then
                    estado_pulsador <= "001";
                else
                    estado_pulsador <= "000";
                end if;
            when "100" => -- UNO -
                cont_filtro <= 0;
                if btnD = '1' then
                    estado_pulsador <= "100";
                else
                    estado_pulsador <= "101";
                end if;
            when "101" => -- RESTA
                cont_filtro <= 0;
                if btnD = '1' then
                    estado_pulsador <= "001";
                else
                    estado_pulsador <= "000";
                end if;
            when others =>
                cont_filtro <= 0;
                estado_pulsador <= "000";
        end case;
      end if;
end process;

-- process de las salidas del pulsador

process(estado_pulsador)
begin
    case estado_pulsador is
        when "000" =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
        when "001" =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
        when "010" =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
        when "011" =>
            salida <= '1';
            flag_suma <= '1';
            flag_resta <= '0';
        when "100" =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
        when "101" =>
            salida <= '1';
            flag_suma <= '0';
            flag_resta <= '1';
        when others => salida <= '0';
    end case;
end process;

-- process de sumar/restar decenas

process(btnC, clk)
begin
    if btnC = '1' then
        contador_decenas <= "0001";
    elsif rising_edge(clk) then
        if salida = '1' then
            if flag_suma = '1' then
                if contador_decenas = 7 and contador_centenas = 1 then
                    contador_decenas <= "0111";
                elsif contador_decenas = 9 then
                    contador_decenas <= "0000";
                else
                    contador_decenas <= contador_decenas + 1;
                end if;
            elsif flag_resta = '1' then
                if contador_decenas = 1 and contador_centenas = 0 then
                    contador_decenas <= "0001";
                elsif contador_decenas = 0 then
                    contador_decenas <= "1001";
                else
                    contador_decenas <= contador_decenas - 1;
                end if;
            end if;
       end if;
    end if;
end process;

-- process de sumar/restar centenas

process(btnC, clk)
begin
    if btnC = '1' then
        contador_centenas <= "0000";
    elsif rising_edge(clk) then
        if salida = '1' then
            if flag_suma = '1' then
                if contador_decenas = 9 then
                    contador_centenas <= contador_centenas + 1;
                end if;
            elsif flag_resta = '1' then
                if contador_centenas = 1 and contador_decenas = 0 then
                    contador_centenas <= contador_centenas - 1;
                end if;
            end if;
       end if;
    end if;
end process;

contador_decenas_integer <= conv_integer(contador_decenas);
contador_centenas_integer <= conv_integer(contador_centenas);
numero_int <= ((contador_centenas_integer * 10) +  contador_decenas_integer) * 10;

-- proceso de frecuencia para el control del enable_seg_aux

process(clk, btnC)
begin
    if btnC = '1' then
        contador_base_enable <= 0;
    elsif rising_edge(clk) then
        if contador_base_enable = 100000 then
            contador_base_enable <= 0;
        else
            contador_base_enable <= contador_base_enable + 1;
        end if;
    end if;
end process;

-- proceso de control del enable_seg_aux

process(clk, btnC)
begin
    if btnC = '1' then
        enable_seg_aux <= "0111";
    elsif rising_edge(clk) then
        if contador_base_enable = 100000 then
            enable_seg_aux <= enable_seg_aux(2 downto 0) & enable_seg_aux(3);
        end if;
    end if;
end process;

an <= enable_seg_aux;

-- proceso de display de diferentes valores en diferentes siete_segs

process(enable_seg_aux, contador_decenas, contador_centenas)
begin
    if grados < 100 then
        case enable_seg_aux is
            when "0111" => dato <= "1111";
            when "1011" => dato <= std_logic_vector(to_unsigned(grados / 100, 4));
            when "1101" => dato <= std_logic_vector(to_unsigned(grados / 10, 4));
            when "1110" => dato <= "0000";
            when others => dato <= "1111";
        end case;
    else
        case enable_seg_aux is
            when "0111" => dato <= "1111";
            when "1011" => dato <= std_logic_vector(to_unsigned(grados / 100, 4));
            when "1101" => dato <= std_logic_vector(to_unsigned((grados / 10) - 10, 4));
            when "1110" => dato <= "0000";
            when others => dato <= "1111";
        end case;
    end if;
end process;

-- proceso de display de diferentes valores en diferentes siete_segs

process(dato)
begin
    case dato is
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

end Behavioral;
