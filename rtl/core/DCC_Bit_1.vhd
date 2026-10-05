----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- Projet Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- DCC_BIT_1 : generateur d'un bit DCC '1' (116 us : 58 us bas + 58 us haut)
-- Structure identique a DCC_BIT_0, seule la duree par phase change.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DCC_BIT_1 is
    Port (
        Clk      : in  STD_LOGIC;
        Clk1M    : in  STD_LOGIC;
        Reset    : in  STD_LOGIC;
        Go       : in  STD_LOGIC;
        Fin      : out STD_LOGIC;
        DCC_1    : out STD_LOGIC
    );
end DCC_BIT_1;

architecture Behavioral of DCC_BIT_1 is

    type etat_type is (IDLE, PHASE_LOW, PHASE_HIGH, DONE);
    signal EP, EF : etat_type;

    -- Echantillonnage de Clk1M dans le domaine 100 MHz pour detecter son front
    signal Clk1M_r   : std_logic;
    signal Tick_1us  : std_logic;

    -- La phase se termine au 58e tick de 1 us = 58 us (mesure en simulation)
    constant DUREE_BIT1 : integer := 58;

    signal Cpt      : integer range 0 to 127;
    signal Raz_Cpt  : std_logic;
    signal Inc_Cpt  : std_logic;
    signal Fin_Cpt  : std_logic;

begin

    -- Detection de front montant de Clk1M
    process(Clk, Reset)
    begin
        if Reset = '1' then
            Clk1M_r <= '0';
        elsif rising_edge(Clk) then
            Clk1M_r <= Clk1M;
        end if;
    end process;

    Tick_1us <= Clk1M and (not Clk1M_r);

    -- Registre d'etat
    process(Clk, Reset)
    begin
        if Reset = '1' then
            EP <= IDLE;
        elsif rising_edge(Clk) then
            EP <= EF;
        end if;
    end process;

    -- Calcul d'etat futur
    process(EP, Go, Fin_Cpt)
    begin
        EF <= EP;
        case EP is
            when IDLE =>
                if Go = '1' then
                    EF <= PHASE_LOW;
                end if;

            when PHASE_LOW =>
                if Fin_Cpt = '1' then
                    EF <= PHASE_HIGH;
                end if;

            when PHASE_HIGH =>
                if Fin_Cpt = '1' then
                    EF <= DONE;
                end if;

            when DONE =>
                -- On reste ici tant que la MAE globale n'a pas relache Go
                if Go = '0' then
                    EF <= IDLE;
                end if;
        end case;
    end process;

    -- RAZ aussi a la transition entre les deux phases pour relancer un comptage propre
    Raz_Cpt <= '1' when (EP = IDLE) or (EP = DONE) or
                        (EP = PHASE_LOW  and EF = PHASE_HIGH) or
                        (EP = PHASE_HIGH and EF = DONE) else '0';

    Inc_Cpt <= '1' when (EP = PHASE_LOW) or (EP = PHASE_HIGH) else '0';

    -- Compteur cadence par Clk 100 MHz, incremente sur le tick de 1 us
    -- (la RAZ prend effet immediatement, plus de probleme de CDC)
    process(Clk, Reset)
    begin
        if Reset = '1' then
            Cpt <= 0;
        elsif rising_edge(Clk) then
            if Raz_Cpt = '1' then
                Cpt <= 0;
            elsif Inc_Cpt = '1' and Tick_1us = '1' then
                Cpt <= Cpt + 1;
            end if;
        end if;
    end process;

    Fin_Cpt <= '1' when (Cpt = DUREE_BIT1) else '0';

    DCC_1 <= '1' when (EP = PHASE_HIGH) else '0';
    Fin   <= '1' when (EP = DONE) else '0';

end Behavioral;
