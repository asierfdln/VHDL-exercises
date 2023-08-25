
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
        dp          : out STD_LOGIC; -- punto decimal del seite segmentos
        an          : out STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        dcmotor     : out std_logic_vector (1 downto 0)
    );
end main;

architecture Behavioral of main is

-- signals del pulsador de dedo

signal switch_unidades_o_decenas: std_logic; -- sw(0)
signal estado_pulsador: std_logic_vector (2 downto 0);
signal cont_filtro: integer range 0 to 100000000;
signal salida: std_logic;
signal flag_suma: std_logic;
signal flag_resta: std_logic;
signal freq_min: integer range 0 to 100000000;
signal contador_unidades: std_logic_vector (3 downto 0);
signal contador_decenas: std_logic_vector (3 downto 0);
signal contador_base_enable: integer range 0 to 100000;
signal enable_seg_aux: std_logic_vector (3 downto 0);
signal dato: std_logic_vector (3 downto 0);

-- signals pulsador-pwm

signal contador_unidades_integer: integer range 0 to 9;
signal contador_decenas_integer: integer range 0 to 9;
signal numero_int: integer range 0 to 99;

-- signals del pwm

signal estado_pwm: std_logic_vector (2 downto 0);
signal duty_cycle: integer range 0 to 100; -- numero_int
signal sentido_giro: std_logic; -- sw(1)
signal cont_flancos: integer range 0 to 100000000;
signal pwm_longitud_pulso: integer range 0 to 100000000; -- longitud del pulso
signal pwm_longitud_ciclo: integer range 0 to 100000000; -- longitud del ciclo
signal pwm_hz: integer range 0 to 500;
signal pwm_out: std_logic;

begin

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

switch_unidades_o_decenas <= sw(0);

-- process de sumar/restar unidades (no da tiempo a llegar hasta 99 con weblab)

process(btnC, clk)
begin
    if btnC = '1' then
        contador_unidades <= "0000";
    elsif rising_edge(clk) then
        if salida = '1' and switch_unidades_o_decenas = '0' then
            if flag_suma = '1' then
                if contador_unidades = 9 then
                    contador_unidades <= "1001";
                else
                    contador_unidades <= contador_unidades + 1;
                end if;
            elsif flag_resta = '1' then
                if contador_unidades = 0 then
                    contador_unidades <= "0000";
                else
                    contador_unidades <= contador_unidades - 1;
                end if;
            end if;
       end if;
    end if;
end process;

-- process de sumar/restar decenas (no da tiempo a llegar hasta 99 con weblab)

process(btnC, clk)
begin
    if btnC = '1' then
        contador_decenas <= "0000";
    elsif rising_edge(clk) then
        if salida = '1' and switch_unidades_o_decenas = '1' then
            if flag_suma = '1' then
                if contador_decenas = 9 then
                    contador_decenas <= "1001";
                else
                    contador_decenas <= contador_decenas + 1;
                end if;
            elsif flag_resta = '1' then
                if contador_decenas = 0 then
                    contador_decenas <= "0000";
                else
                    contador_decenas <= contador_decenas - 1;
                end if;
            end if;
       end if;
    end if;
end process;

contador_unidades_integer <= conv_integer(contador_unidades);
contador_decenas_integer <= conv_integer(contador_decenas);
numero_int <= (contador_decenas_integer * 10) +  contador_unidades_integer;

led(6 downto 0) <= std_logic_vector(to_unsigned(numero_int, 7));

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

process(enable_seg_aux, contador_unidades, contador_decenas)
begin
    case enable_seg_aux is
        when "0111" => dato <= "1111";
        when "1011" => dato <= "1111";
        when "1101" => dato <= contador_decenas;
        when "1110" => dato <= contador_unidades;
        when others => dato <= "1111";
    end case;
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

-- ####################################################################
-- ####################################################################
--                        LOGICA DEL MOTOR DC
-- ####################################################################
-- ####################################################################

duty_cycle <= numero_int;
sentido_giro <= sw(1);

-- process del sentido de giro del motor

process(sentido_giro)
begin
    if sentido_giro = '0' then
        dcmotor <= "0" & pwm_out;
    else
        dcmotor <= pwm_out & "0";
    end if;
end process;

pwm_hz <= 200; -- (200 Hz) -> (500000 flancos) -> (0.5 ms)

-- process de definicion de pwm_longitud_ciclo como (frecuencia base de
-- la fpga) / (pwm_hz)

process(pwm_hz)
begin
    pwm_longitud_ciclo <= 100000000 / pwm_hz;
end process;

-- process de definicion de pwm_longitud_pulso como porcentaje X de
-- pwm_longitud_ciclo en función del valor de duty_cycle

process(pwm_longitud_ciclo, duty_cycle)
begin
    pwm_longitud_pulso <= pwm_longitud_ciclo * duty_cycle / 100;
end process;

-- process del automata del pwm

process(clk, btnC)
begin
    if btnC = '1' then
        estado_pwm <= "000";
        cont_flancos <= 0;
    elsif rising_edge(clk) then
        case estado_pwm is
            when "000" =>
                cont_flancos <= 0;
                if duty_cycle /= 0 then
                    estado_pwm <= "001";
                else
                    estado_pwm <= "100";
                end if;
            when "001" =>
                cont_flancos <= 1;
                estado_pwm <= "010";
            when "010" =>
                cont_flancos <= cont_flancos + 1;
                if cont_flancos < pwm_longitud_pulso then
                    estado_pwm <= "010";
                else
                    if duty_cycle /= 100 then
                        estado_pwm <= "011";
                    else
                        estado_pwm <= "001";
                    end if;
                end if;
            when "011" =>
                cont_flancos <= cont_flancos + 1;
                if cont_flancos < pwm_longitud_ciclo then
                    estado_pwm <= "011";
                else
                    if duty_cycle /= 0 then
                        estado_pwm <= "001";
                    else
                        estado_pwm <= "100";
                    end if;
                end if;
            when "100" =>
                cont_flancos <= 1;
                estado_pwm <= "011";
            when others =>
                cont_flancos <= 0;
                estado_pwm <= "000";
        end case;
    end if;
end process;

--process de las salidas del pwm

process(estado_pwm)
begin
    case estado_pwm is
        when "000" => pwm_out <= '0';
        when "001" => pwm_out <= '1';
        when "010" => pwm_out <= '1';
        when "011" => pwm_out <= '0';
        when "100" => pwm_out <= '0';
        when others => pwm_out <= '0';
    end case;
end process;

end Behavioral;
