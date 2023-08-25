
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity project_BCD_simulacion is
    port (
        clk         : in std_logic;
        binario     : in std_logic_vector (3 downto 0);
        btnU        : in  STD_LOGIC; -- boton arriba
        btnC        : in  STD_LOGIC; -- boton central
        led         : out STD_LOGIC_VECTOR(11 DOWNTO 0); -- leds
        seg         : out STD_LOGIC_VECTOR(6 DOWNTO 0); -- siete seg
        an          : out STD_LOGIC_VECTOR(3 DOWNTO 0) -- control de 7-seg
    );
end project_BCD_simulacion;

architecture Behavioral of project_BCD_simulacion is

-- signals de control

signal inicio: std_logic;
--signal binario: std_logic_vector (3 downto 0);
signal enable: std_logic;
signal fin: std_logic;

-- signals de conversion

signal estado_conversion: std_logic_vector (1 downto 0);
signal vector: std_logic_vector (11 downto 0);
signal contador_desplazamientos: integer range 0 to 7;
signal unidades: std_logic_vector (3 downto 0);
signal decenas: std_logic_vector (3 downto 0);

-- signals del reloj

signal cont_base_enable: integer range 0 to 100000;
signal cont: integer range 0 to 100000000;
signal tope_freq: integer range 0 to 400000000;
signal modo_lento_rapido: std_logic;

-- signals de siete-segmentos

signal sal_mux: std_logic_vector (3 downto 0);
signal enable_seg: std_logic_vector (3 downto 0);
signal segmentos: std_logic_vector (6 downto 0);

begin

inicio <= btnC;
--binario <= sw(3 downto 0);
--enable <= sw(15);
--modo_lento_rapido <= sw(14);

--led(15) <= fin;
--led(14) <= modo_lento_rapido;
led(11 downto 0) <= vector;

-- ####################################################################
-- ####################################################################
--                        LOGICA DE CONVERSION
-- ####################################################################
-- ####################################################################

-- process del automata de la conversion

process(clk, inicio)
begin
    if inicio = '1' then
        vector <= "000000000000";
        estado_conversion <= "00";
        contador_desplazamientos <= 0;
        unidades <= "0000";
        decenas <= "0000";
        fin <= '0';
    elsif rising_edge(clk) then

            case estado_conversion is

                -- start

                when "00" =>
                    contador_desplazamientos <= 0;
                    vector <= "00000000" & binario;
                    if btnU = '1' then
                        estado_conversion <= "01";
                    else
                        estado_conversion <= "00";
                    end if;
                    fin <= '0';

                -- despl

                when "01" =>
                    contador_desplazamientos <= contador_desplazamientos + 1;
                    vector <= vector(10 downto 0) & '0';
                    if contador_desplazamientos < 3 then
                        estado_conversion <= "10";
                    else
                        estado_conversion <= "11";
                    end if;
                    fin <= '0';

                -- ¿sumar+3?

                when "10" =>
                    contador_desplazamientos <= contador_desplazamientos;
                    if vector(11 downto 8) > 4 then
                        vector(11 downto 8) <= vector(11 downto 8) + "0011";
                    end if;
                    if vector(7 downto 4) > 4 then
                        vector(7 downto 4) <= vector(7 downto 4) + "0011";
                    end if;
                    estado_conversion <= "01";
                    fin <= '0';

                -- final

                when "11" =>
                    contador_desplazamientos <= contador_desplazamientos;
                    vector <= vector;
                    estado_conversion <= "00";
                    fin <= '1';
                    unidades <= vector(7 downto 4);
                    decenas <= vector(11 downto 8);

                when others =>
                    contador_desplazamientos <= 0;
                    vector <= "000000000000";
                    estado_conversion <= "00";
                    fin <= '0';
                    unidades <= "0000";
                    decenas <= "0000";

            end case;
    end if;
end process;

-- ####################################################################
-- ####################################################################
--                         LOGICA DEL RELOJ
-- ####################################################################
-- ####################################################################

-- process de conteo de segundos

process(clk, inicio)
begin
    if inicio = '1' then
        cont <= 0;
    elsif rising_edge(clk) then
        if cont = 100000000 then
            cont <= 0;
        else
            cont <= cont + 1;
        end if;
    end if;
end process;


-- ####################################################################
-- ####################################################################
--                         LOGICA DEL 7SEG
-- ####################################################################
-- ####################################################################

an <= enable_seg;
seg <= segmentos;

-- process de conteo de freq para multiplex del siete-segmentos

process(inicio, clk)
begin
    if inicio = '1' then
        cont_base_enable <= 0;
    elsif rising_edge(clk) then
        if cont_base_enable = 100000 then
            cont_base_enable <= 0;
        else
            cont_base_enable <= cont_base_enable + 1;
        end if;
    end if;
end process;

-- process de multiplexado del siete-segmentos

process(clk,inicio)
begin
    if inicio = '1' then
        enable_seg <= "1110";
    elsif rising_edge(clk) then
        if cont_base_enable = 100000 then
            enable_seg <= enable_seg(2 downto 0) & enable_seg(3);
        end if;
    end if;
end process;

--process de multiplexado de las entradas al 7-seg

process(enable_seg, unidades, decenas)
begin
    case enable_seg is
        when "0111" => sal_mux <= "0000";
        when "1011" => sal_mux <= "0000";
        when "1101" => sal_mux <= decenas;
        when "1110" => sal_mux <= unidades;
        when others => sal_mux <= "0000";
    end case;
end process;

-- process de salidas al siete-segmentos

process(sal_mux)
begin
    case sal_mux is
        when "0000" => segmentos <= "0000001";
        when "0001" => segmentos <= "1001111";
        when "0010" => segmentos <= "0010010";
        when "0011" => segmentos <= "0000110";
        when "0100" => segmentos <= "1001100";
        when "0101" => segmentos <= "0100100";
        when "0110" => segmentos <= "1100000";
        when "0111" => segmentos <= "0001111";
        when "1000" => segmentos <= "0000000";
        when "1001" => segmentos <= "0001100";
        when others => segmentos <= "1111111";
    end case;
end process;

end Behavioral;
