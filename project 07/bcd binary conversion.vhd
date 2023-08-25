
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
        seg     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- siete seg
        dp      : OUT STD_LOGIC; -- punto decimal del siete seg
        an      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- control de 7-seg
        dcmotor : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        servo   : OUT STD_LOGIC
    );
END main;

ARCHITECTURE Behavioral OF main IS

    -- signals de control

    SIGNAL inicio : STD_LOGIC;
    SIGNAL binario : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL enable : STD_LOGIC;
    SIGNAL fin : STD_LOGIC;

    -- signals de conversion

    SIGNAL estado_conversion : STD_LOGIC_VECTOR (1 DOWNTO 0);
    SIGNAL vector : STD_LOGIC_VECTOR (11 DOWNTO 0);
    SIGNAL contador_desplazamientos : INTEGER RANGE 0 TO 7;
    SIGNAL unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);

    -- signals del reloj

    SIGNAL cont_base_enable : INTEGER RANGE 0 TO 100000;
    SIGNAL cont : INTEGER RANGE 0 TO 100000000;
    SIGNAL tope_freq : INTEGER RANGE 0 TO 400000000;
    SIGNAL modo_lento_rapido : STD_LOGIC;

    -- signals de siete-segmentos

    SIGNAL sal_mux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL enable_seg : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL segmentos : STD_LOGIC_VECTOR (6 DOWNTO 0);

BEGIN

    inicio <= btnC;
    binario <= sw(3 DOWNTO 0);
    enable <= sw(15);
    modo_lento_rapido <= sw(14);

    led(15) <= fin;
    led(14) <= modo_lento_rapido;
    led(11 DOWNTO 0) <= vector;

    -- ####################################################################
    -- ####################################################################
    --                        LOGICA DE CONVERSION
    -- ####################################################################
    -- ####################################################################

    -- process del automata de la conversion

    PROCESS (clk, inicio)
    BEGIN
        IF inicio = '1' THEN
            vector <= "000000000000";
            estado_conversion <= "00";
            contador_desplazamientos <= 0;
            unidades <= "0000";
            decenas <= "0000";
            fin <= '0';
        ELSIF rising_edge(clk) THEN

            IF cont = 0 AND fin = '0' THEN

                CASE estado_conversion IS

                        -- start

                    WHEN "00" =>
                        contador_desplazamientos <= 0;
                        vector <= "00000000" & binario;
                        IF enable = '1' OR btnU = '1' THEN
                            estado_conversion <= "01";
                        ELSE
                            estado_conversion <= "00";
                        END IF;
                        fin <= '0';

                        -- despl

                    WHEN "01" =>
                        contador_desplazamientos <= contador_desplazamientos + 1;
                        vector <= vector(10 DOWNTO 0) & '0';
                        IF contador_desplazamientos < 3 THEN
                            estado_conversion <= "10";
                        ELSE
                            estado_conversion <= "11";
                        END IF;
                        fin <= '0';

                        -- ¿sumar+3?

                    WHEN "10" =>
                        contador_desplazamientos <= contador_desplazamientos;
                        IF vector(11 DOWNTO 8) > 4 THEN
                            vector(11 DOWNTO 8) <= vector(11 DOWNTO 8) + "0011";
                        END IF;
                        IF vector(7 DOWNTO 4) > 4 THEN
                            vector(7 DOWNTO 4) <= vector(7 DOWNTO 4) + "0011";
                        END IF;
                        estado_conversion <= "01";
                        fin <= '0';

                        -- final

                    WHEN "11" =>
                        contador_desplazamientos <= contador_desplazamientos;
                        vector <= vector;
                        estado_conversion <= "00";
                        fin <= '1';
                        unidades <= vector(7 DOWNTO 4);
                        decenas <= vector(11 DOWNTO 8);

                    WHEN OTHERS =>
                        contador_desplazamientos <= 0;
                        vector <= "000000000000";
                        estado_conversion <= "00";
                        fin <= '0';
                        unidades <= "0000";
                        decenas <= "0000";

                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DEL RELOJ
    -- ####################################################################
    -- ####################################################################

    -- process de conteo de segundos

    PROCESS (clk, inicio)
    BEGIN
        IF inicio = '1' THEN
            cont <= 0;
        ELSIF rising_edge(clk) THEN
            IF cont = tope_freq THEN
                cont <= 0;
            ELSE
                cont <= cont + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de cambio de vel.

    PROCESS (modo_lento_rapido)
    BEGIN
        IF modo_lento_rapido = '1' THEN
            tope_freq <= 0;
        ELSE
            tope_freq <= 50000000;
        END IF;
    END PROCESS;

    -- ####################################################################
    -- ####################################################################
    --                         LOGICA DEL 7SEG
    -- ####################################################################
    -- ####################################################################

    an <= enable_seg;
    seg <= segmentos;

    -- process de conteo de freq para multiplex del siete-segmentos

    PROCESS (inicio, clk)
    BEGIN
        IF inicio = '1' THEN
            cont_base_enable <= 0;
        ELSIF rising_edge(clk) THEN
            IF cont_base_enable = 100000 THEN
                cont_base_enable <= 0;
            ELSE
                cont_base_enable <= cont_base_enable + 1;
            END IF;
        END IF;
    END PROCESS;

    -- process de multiplexado del siete-segmentos

    PROCESS (clk, inicio)
    BEGIN
        IF inicio = '1' THEN
            enable_seg <= "1110";
        ELSIF rising_edge(clk) THEN
            IF cont_base_enable = 100000 THEN
                enable_seg <= enable_seg(2 DOWNTO 0) & enable_seg(3);
            END IF;
        END IF;
    END PROCESS;

    --process de multiplexado de las entradas al 7-seg

    PROCESS (enable_seg, unidades, decenas)
    BEGIN
        CASE enable_seg IS
            WHEN "0111" => sal_mux <= "0000";
            WHEN "1011" => sal_mux <= "0000";
            WHEN "1101" => sal_mux <= decenas;
            WHEN "1110" => sal_mux <= unidades;
            WHEN OTHERS => sal_mux <= "0000";
        END CASE;
    END PROCESS;

    -- process de salidas al siete-segmentos

    PROCESS (sal_mux)
    BEGIN
        CASE sal_mux IS
            WHEN "0000" => segmentos <= "0000001";
            WHEN "0001" => segmentos <= "1001111";
            WHEN "0010" => segmentos <= "0010010";
            WHEN "0011" => segmentos <= "0000110";
            WHEN "0100" => segmentos <= "1001100";
            WHEN "0101" => segmentos <= "0100100";
            WHEN "0110" => segmentos <= "1100000";
            WHEN "0111" => segmentos <= "0001111";
            WHEN "1000" => segmentos <= "0000000";
            WHEN "1001" => segmentos <= "0001100";
            WHEN OTHERS => segmentos <= "1111111";
        END CASE;
    END PROCESS;

END Behavioral;