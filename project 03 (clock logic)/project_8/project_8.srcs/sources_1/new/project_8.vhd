----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2020 10:06:40
-- Design Name: 
-- Module Name: project_8 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY project_8 IS
    PORT (
        clk : IN STD_LOGIC;
        init : IN STD_LOGIC;
        select_mode : IN STD_LOGIC;
        fast : IN STD_LOGIC;
        pausa : IN STD_LOGIC;
        siete_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        enable_seg : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );

END project_8;

ARCHITECTURE Behavioral OF project_8 IS

    SIGNAL cont_centesimas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_decimas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_segs_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_segs_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_mins_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_mins_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_horas_unidades : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_horas_decenas : STD_LOGIC_VECTOR (3 DOWNTO 0);

    SIGNAL cont_centesimas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_decimas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_segs_unidades_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_segs_decenas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_mins_unidades_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_mins_decenas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_horas_unidades_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_horas_decenas_temp : STD_LOGIC_VECTOR (3 DOWNTO 0);
    -- signal cont_base: integer range 0 to 100000000; -- lleva la cuenta del reloj, puesto para 1 seg...
    SIGNAL cont_base : INTEGER RANGE 0 TO 1000000; -- lleva la cuenta del reloj, puesto para 1 centesima...
    SIGNAL tope_freq : INTEGER RANGE 0 TO 1000000;

    SIGNAL enable_aux : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL cont_base_enable : INTEGER RANGE 0 TO 100000; -- 100,000,000 / 100,000 = 1kHz de freq (cada siete_seg encendido este tiempo / (num de siete_segs)...)
    SIGNAL sal_mux : STD_LOGIC_VECTOR (3 DOWNTO 0);

BEGIN

    -- proceso de reloj
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_base <= 0;
        ELSIF rising_edge(clk) THEN
            IF cont_base = tope_freq THEN
                cont_base <= 0;
            ELSE
                cont_base <= cont_base + 1;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de cambio de vel.
    PROCESS (fast)
    BEGIN
        IF fast = '0' THEN
            tope_freq <= 1000000;
        ELSE
            tope_freq <= 100;
        END IF;
    END PROCESS;

    PROCESS (pausa, select_mode, clk)
    BEGIN
        IF pausa = '0' AND rising_edge(clk) THEN
            IF select_mode = '0' THEN
                cont_centesimas_temp <= cont_centesimas;
                cont_decimas_temp <= cont_decimas;
                cont_segs_unidades_temp <= cont_segs_unidades;
                cont_segs_decenas_temp <= cont_segs_decenas;
            ELSE
                cont_mins_unidades_temp <= cont_mins_unidades;
                cont_mins_decenas_temp <= cont_mins_decenas;
                cont_horas_unidades_temp <= cont_horas_unidades;
                cont_horas_decenas_temp <= cont_horas_decenas;
            END IF;
        ELSE

        END IF;
    END PROCESS;

    -- proceso de monitoreo de segundos.unidades
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_centesimas <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo

            IF cont_base = tope_freq THEN
                IF cont_centesimas = "1001" THEN
                    cont_centesimas <= "0000";
                ELSE
                    cont_centesimas <= cont_centesimas + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de segundos.decenas
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_decimas <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9

            IF cont_base = tope_freq AND cont_centesimas = "1001" THEN
                IF cont_decimas = "1001" THEN
                    cont_decimas <= "0000";
                ELSE
                    cont_decimas <= cont_decimas + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de minutos.unidades
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_segs_unidades <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9 y segundos.decenas = 5

            IF cont_base = tope_freq AND cont_centesimas = "1001" AND cont_decimas = "1001" THEN
                IF cont_segs_unidades = "1001" THEN
                    cont_segs_unidades <= "0000";
                ELSE
                    cont_segs_unidades <= cont_segs_unidades + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de segundos.decenas
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_segs_decenas <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9 y segundos.decenas = 5 y minutos.unidades = 9

            IF cont_base = tope_freq AND cont_centesimas = "1001" AND cont_decimas = "1001" AND cont_segs_unidades = "1001" THEN
                IF cont_segs_decenas = "0101" THEN
                    cont_segs_decenas <= "0000";
                ELSE
                    cont_segs_decenas <= cont_segs_decenas + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de minutos.unidades
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_mins_unidades <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9 y segundos.decenas = 5 y minutos.unidades = 9

            IF cont_base = tope_freq AND cont_centesimas = "1001" AND cont_decimas = "1001" AND cont_segs_unidades = "1001" AND cont_segs_decenas = "0101" THEN
                IF cont_mins_unidades = "1001" THEN
                    cont_mins_unidades <= "0000";
                ELSE
                    cont_mins_unidades <= cont_mins_unidades + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de minutos.decenas
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_mins_decenas <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9 y segundos.decenas = 5 y minutos.unidades = 9

            IF cont_base = tope_freq AND cont_centesimas = "1001" AND cont_decimas = "1001" AND cont_segs_unidades = "1001" AND cont_segs_decenas = "0101" AND cont_mins_unidades = "1001" THEN
                IF cont_mins_decenas = "0101" THEN
                    cont_mins_decenas <= "0000";
                ELSE
                    cont_mins_decenas <= cont_mins_decenas + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de horas.unidades
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_horas_unidades <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9 y segundos.decenas = 5 y minutos.unidades = 9

            IF cont_base = tope_freq AND cont_centesimas = "1001" AND cont_decimas = "1001" AND cont_segs_unidades = "1001" AND cont_segs_decenas = "0101" AND cont_mins_unidades = "1001" AND cont_mins_decenas = "0101" THEN
                IF cont_horas_unidades = "1001" THEN
                    cont_horas_unidades <= "0000";
                ELSIF cont_horas_unidades = "0011" AND cont_horas_decenas = "0010" THEN
                    cont_horas_unidades <= "0000";
                ELSE
                    cont_horas_unidades <= cont_horas_unidades + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de monitoreo de horas.decenas
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_horas_decenas <= "0000";
        ELSIF rising_edge(clk) THEN

            -- si ha pasado un segundo y las segundos.unidades = 9 y segundos.decenas = 5 y minutos.unidades = 9

            IF cont_base = tope_freq AND cont_centesimas = "1001" AND cont_decimas = "1001" AND cont_segs_unidades = "1001" AND cont_segs_decenas = "0101" AND cont_mins_unidades = "1001" AND cont_mins_decenas = "0101" AND (cont_horas_unidades = "1001" OR cont_horas_unidades = "0011") THEN
                IF cont_horas_decenas = "0010" THEN
                    cont_horas_decenas <= "0000";
                ELSIF cont_horas_unidades = "1001" THEN
                    cont_horas_decenas <= cont_horas_decenas + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- proceso de conteo y modificacion del cont_base_enable (el que da la freq de 1kHz para cambio de siete_seg)
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            cont_base_enable <= 0;
        ELSIF rising_edge(clk) THEN
            IF cont_base_enable = 1000000 THEN
                cont_base_enable <= 0;
            ELSE
                cont_base_enable <= cont_base_enable + 1;
            END IF;
        END IF;
    END PROCESS;

    -- modificacion de la signal para ir de siete_seg en siete_seg (rotacion izquierda 1000 veces por segundo)
    PROCESS (init, clk)
    BEGIN
        IF init = '1' THEN
            enable_aux <= "1110"; -- TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
        ELSIF rising_edge(clk) THEN
            IF cont_base_enable = 100000 THEN
                enable_aux <= enable_aux(2 DOWNTO 0) & enable_aux(3); -- desplazamiento a la izquierda
                -- enable_aux <= enable_aux(0) & enable_aux(3 downto 1); -- desplazamiento a la derecha
            END IF;
        END IF;
    END PROCESS;

    enable_seg <= enable_aux;

    --multiplexado de las entradas al 7-seg
    PROCESS (enable_aux, pausa, select_mode, cont_centesimas, cont_decimas, cont_segs_unidades, cont_segs_decenas, cont_mins_unidades, cont_mins_decenas, cont_horas_unidades, cont_horas_decenas)
    BEGIN
        IF pausa = '0' THEN
            IF select_mode = '0' THEN
                CASE enable_aux IS
                    WHEN "1110" => sal_mux <= cont_mins_unidades;
                    WHEN "1101" => sal_mux <= cont_mins_decenas;
                    WHEN "1011" => sal_mux <= cont_horas_unidades;
                    WHEN "0111" => sal_mux <= cont_horas_decenas;
                    WHEN OTHERS => sal_mux <= "0000";
                END CASE;
            ELSE
                CASE enable_aux IS
                    WHEN "1110" => sal_mux <= cont_centesimas;
                    WHEN "1101" => sal_mux <= cont_decimas;
                    WHEN "1011" => sal_mux <= cont_segs_unidades;
                    WHEN "0111" => sal_mux <= cont_segs_decenas;
                    WHEN OTHERS => sal_mux <= "0000";
                END CASE;
            END IF;
        ELSE
            IF select_mode = '0' THEN
                CASE enable_aux IS
                    WHEN "1110" => sal_mux <= cont_mins_unidades_temp;
                    WHEN "1101" => sal_mux <= cont_mins_decenas_temp;
                    WHEN "1011" => sal_mux <= cont_horas_unidades_temp;
                    WHEN "0111" => sal_mux <= cont_horas_decenas_temp;
                    WHEN OTHERS => sal_mux <= "0000";
                END CASE;
            ELSE
                CASE enable_aux IS
                    WHEN "1110" => sal_mux <= cont_centesimas_temp;
                    WHEN "1101" => sal_mux <= cont_decimas_temp;
                    WHEN "1011" => sal_mux <= cont_segs_unidades_temp;
                    WHEN "0111" => sal_mux <= cont_segs_decenas_temp;
                    WHEN OTHERS => sal_mux <= "0000";
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (sal_mux)
    BEGIN
        CASE sal_mux IS
            WHEN "0000" => siete_seg <= "0000001";
            WHEN "0001" => siete_seg <= "1001111";
            WHEN "0010" => siete_seg <= "0010010";
            WHEN "0011" => siete_seg <= "0000110";
            WHEN "0100" => siete_seg <= "1001100";
            WHEN "0101" => siete_seg <= "0100100";
            WHEN "0110" => siete_seg <= "1100000";
            WHEN "0111" => siete_seg <= "0001111";
            WHEN "1000" => siete_seg <= "0000000";
            WHEN "1001" => siete_seg <= "0001100";
            WHEN OTHERS => siete_seg <= "1111111";
        END CASE;
    END PROCESS;

END behavioral;