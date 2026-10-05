----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- COMPTEUR_TEMPO : temporisation inter-trames de 6 ms.
--
-- Reecriture personnelle du module fourni avec le sujet (memes ports).
-- Le compteur est cadence a 100 MHz et n'avance que sur le front montant
-- de Clk1M (tick 1 us) : pas de second domaine d'horloge, pas de CDC.
--
-- Protocole avec la MAE :
--   Start_Tempo = '1' -> comptage ; Fin_Tempo passe a '1' apres 6000 us
--   Start_Tempo = '0' -> compteur remis a zero, Fin_Tempo = '0'
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity COMPTEUR_TEMPO is
    Port (
        Clk         : in  STD_LOGIC;   -- 100 MHz
        Reset       : in  STD_LOGIC;
        Clk1M       : in  STD_LOGIC;   -- carre 1 MHz (echantillonne, pas une horloge)
        Start_Tempo : in  STD_LOGIC;
        Fin_Tempo   : out STD_LOGIC
    );
end COMPTEUR_TEMPO;

architecture Behavioral of COMPTEUR_TEMPO is

    constant DUREE_TEMPO_US : integer := 6000;   -- 6 ms

    signal Clk1M_r  : std_logic;
    signal Tick_1us : std_logic;
    signal Cpt      : integer range 0 to DUREE_TEMPO_US;

begin

    -- Detection de front montant de Clk1M dans le domaine 100 MHz
    process(Clk, Reset)
    begin
        if Reset = '1' then
            Clk1M_r <= '0';
        elsif rising_edge(Clk) then
            Clk1M_r <= Clk1M;
        end if;
    end process;

    Tick_1us <= Clk1M and (not Clk1M_r);

    -- Compteur de microsecondes, sature a DUREE_TEMPO_US
    process(Clk, Reset)
    begin
        if Reset = '1' then
            Cpt <= 0;
        elsif rising_edge(Clk) then
            if Start_Tempo = '0' then
                Cpt <= 0;
            elsif Tick_1us = '1' and Cpt < DUREE_TEMPO_US then
                Cpt <= Cpt + 1;
            end if;
        end if;
    end process;

    Fin_Tempo <= '1' when (Start_Tempo = '1' and Cpt = DUREE_TEMPO_US) else '0';

end Behavioral;
