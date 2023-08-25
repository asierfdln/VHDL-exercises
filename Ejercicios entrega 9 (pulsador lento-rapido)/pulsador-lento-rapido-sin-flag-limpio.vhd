
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity main is
    port (
        clk         : in std_logic;
        sw          : in  STD_LOGIC_VECTOR(15 DOWNTO 0); --interruptores
        -- btnU        : in  STD_LOGIC; --boton arriba
        -- btnD        : in  STD_LOGIC; --boton abajo
        btnL        : in  STD_LOGIC; --boton izquierda
        btnR        : in  STD_LOGIC; --boton derecha
        btnC        : in  STD_LOGIC; --boton central
        led         : out STD_LOGIC_VECTOR(15 DOWNTO 0); --leds
        seg         : out STD_LOGIC_VECTOR(6 DOWNTO 0); --siete segmentos
        dp          : out STD_LOGIC; --punto decimal del siete segmentos
        an          : out STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        dcmotor     : out std_logic_vector (1 downto 0)
    );
end main;

architecture Behavioral of main is

-- signals de pulsador dedo

signal switch_unidades_decenas: std_logic;
signal estado: std_logic_vector (2 downto 0);
signal cont_filtro: integer range 0 to 500000000;
signal salida: std_logic;
signal flag_suma: std_logic;
signal flag_resta: std_logic;
signal freq_min: integer range 0 to 100000000;
signal contador_unidades: std_logic_vector (3 downto 0);
signal contador_decenas: std_logic_vector (3 downto 0);
signal contador_base_enable: integer range 0 to 100000;
signal enable_seg_aux: std_logic_vector (3 downto 0);
signal dato: std_logic_vector (3 downto 0);
signal btnU: std_logic;
signal btnD: std_logic;
-- signal flag_origen_start_rapido: std_logic := '0';

begin

btnU <= sw(1);
btnD <= sw(0);
freq_min <= 100000;

-- switch_unidades_decenas <= sw(15);
-- led(15) <= flag_origen_start_rapido;

-- process del automata pulsador dedo

process(btnC, clk)
begin
    if btnC = '1' then
        estado <= "000";
        cont_filtro <= 0;
    elsif rising_edge(clk) then
        case estado is
            when "000" => -- INICIO
                cont_filtro <= 0;
                if btnU = '1' or btnD = '1' then
                    estado <= "001";
                else
                    estado <= "000";
                end if;  
            when "001" => -- FILTRADO
                cont_filtro <= cont_filtro + 1;
                if (btnU = '1' or btnD = '1') and cont_filtro < freq_min then
                    estado <= "001";
                elsif (btnU = '1' or btnD = '1') and cont_filtro = freq_min then
                    if btnU = '1'then
                        estado <= "010";
                    elsif btnD = '1' then
                        estado <= "100";
                    end if;
                else
                    estado <= "000";
                end if;
            when "010" => -- UNO +
                cont_filtro <= cont_filtro + 1;
                if btnU = '1' and cont_filtro < 200000000 then
                    estado <= "010";
                elsif btnU = '1' and cont_filtro = 200000000 then
                    estado <= "110";
                elsif btnU = '0' then
                    estado <= "011";
                end if;
            when "011" => -- SUMA
                cont_filtro <= 0;
                if btnU = '1' then
                    estado <= "001";
                else
                    estado <= "000";
                end if;
            when "100" => -- UNO -
                cont_filtro <= cont_filtro + 1;
                if btnD = '1' and cont_filtro < 200000000 then
                    estado <= "100";
                elsif btnD = '1' and cont_filtro = 200000000 then
                    estado <= "110";
                elsif btnD = '0' then
                    estado <= "101";
                end if;
            when "101" => -- RESTA
                cont_filtro <= 0;
                if btnD = '1' then
                    estado <= "001";
                else
                    estado <= "000";
                end if;
            when "110" => -- START_RAPIDO
                cont_filtro <= 0;
                if btnU = '1' or btnD = '1' then
                    estado <= "111";
                elsif btnU = '0' and btnD = '0' then
                    estado <= "000";
                end if;
            when "111" => -- RAPIDO
                cont_filtro <= cont_filtro + 1;
                if (btnU = '1' or btnD = '1') and cont_filtro < 20000000 then
                    estado <= "111";
                elsif (btnU = '1' or btnD = '1') and cont_filtro = 20000000 then
                    estado <= "110";
                elsif btnU = '0' and btnD = '0' then
                    estado <= "000";
                end if;
            when others =>
                cont_filtro <= 0;
                estado <= "000";
        end case;
      end if;
end process;

-- process de las salidas pulsador dedo

process(estado)
begin
    case estado is
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
            -- flag_origen_start_rapido <= '0';
        when "011" =>
            salida <= '1';
            flag_suma <= '1';
            flag_resta <= '0';
        when "100" =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
            -- flag_origen_start_rapido <= '1';
        when "101" =>
            salida <= '1';
            flag_suma <= '0';
            flag_resta <= '1';
        when "110" =>
            salida <= '1';
            if btnU = '1' then
                flag_suma <= '1';
                flag_resta <= '0';
            elsif btnD = '1' then
                flag_suma <= '0';
                flag_resta <= '1';
            end if;
        when "111" =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
        when others =>
            salida <= '0';
            flag_suma <= '0';
            flag_resta <= '0';
            -- flag_origen_start_rapido <= '0';
    end case;
end process;

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

process(btnC, clk)
begin
    if btnC = '1' then
        contador_unidades <= "0000";
    elsif rising_edge(clk) then
        if salida = '1' then
            if flag_suma = '1' then
                if contador_unidades = 9 and contador_decenas < 9 then
                    contador_unidades <= "0000";
                elsif contador_decenas = 9 and contador_unidades = 9 then
                    contador_unidades <= "1001";
                else
                    contador_unidades <= contador_unidades + 1;
                end if;
            elsif flag_resta = '1' then
                if contador_unidades = 0 and contador_decenas > 0 then
                    contador_unidades <= "1001";
                elsif contador_decenas = 0 and contador_unidades = 0 then
                    contador_unidades <= "0000";
                else
                    contador_unidades <= contador_unidades - 1;
                end if;
            end if;
        end if;
    end if;
end process;

-- process suma decenas sin switch

process(btnC, clk)
begin
    if btnC = '1' then
        contador_decenas <= "0000";
    elsif rising_edge(clk) then
        if salida = '1' then
            if flag_suma = '1' and contador_unidades = 9 then
                if contador_decenas = 9 then
                    contador_decenas <= "1001";
                else
                    contador_decenas <= contador_decenas + 1;
                end if;
            elsif flag_resta = '1' and contador_unidades = 0  then
                if contador_decenas = 0 then
                    contador_decenas <= "0000";
                else
                    contador_decenas <= contador_decenas - 1;
                end if;
            end if;
       end if;
    end if;
end process;

-- process de frecuencia de display de sietesegs

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

-- process de seleccion de display de sietesegs

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

-- process de display de valores en sietesegs

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

-- process de valores en sietesegs

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
