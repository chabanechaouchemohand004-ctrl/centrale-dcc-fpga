----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- Projet Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- MAE_DCC : machine a etats globale de la centrale.
--
-- Cycle :  LOAD -> READ_BIT -> GEN_1/GEN_0 -> RELACHE -> SHIFT -> READ_BIT -> ...
--          (51 bits) -> TEMPO (6 ms) -> LOAD
--
-- Codee selon le patron 3-process du cours C03 (registre d'etat sequentiel,
-- etats futurs combinatoire, sorties combinatoires) + un 4eme process pour
-- le compteur de bits restants.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MAE_DCC is
    Port (
        Clk          : in  STD_LOGIC;
        Reset        : in  STD_LOGIC;
        -- Interface registre a decalage
        Bit_Courant  : in  STD_LOGIC;
        COM_REG      : out STD_LOGIC_VECTOR(1 downto 0);
        -- Interface generateur bit '1'
        Go_1         : out STD_LOGIC;
        Fin_1        : in  STD_LOGIC;
        -- Interface generateur bit '0'
        Go_0         : out STD_LOGIC;
        Fin_0        : in  STD_LOGIC;
        -- Interface compteur de temporisation
        Start_Tempo  : out STD_LOGIC;
        Fin_Tempo    : in  STD_LOGIC
    );
end MAE_DCC;

architecture Behavioral of MAE_DCC is

    type etat_type is (LOAD, READ_BIT, GEN_1, GEN_0, RELACHE, SHIFT, TEMPO);
    signal EP, EF : etat_type;

    -- Initialise a 50 au LOAD : le MSB est lu directement, les 50 bits restants
    -- demandent un SHIFT chacun. Total = 51 bits transmis.
    signal Cpt_Bits : integer range 0 to 50;

begin

    -- Registre d'etat
    process(Clk, Reset)
    begin
        if Reset = '1' then
            EP <= LOAD;
        elsif rising_edge(Clk) then
            EP <= EF;
        end if;
    end process;

    -- Calcul d'etat futur
    process(EP, Bit_Courant, Fin_1, Fin_0, Fin_Tempo, Cpt_Bits)
    begin
        EF <= EP;

        case EP is
            when LOAD =>
                EF <= READ_BIT;

            when READ_BIT =>
                if Bit_Courant = '1' then
                    EF <= GEN_1;
                else
                    EF <= GEN_0;
                end if;

            when GEN_1 =>
                if Fin_1 = '1' then
                    EF <= RELACHE;
                end if;

            when GEN_0 =>
                if Fin_0 = '1' then
                    EF <= RELACHE;
                end if;

            when RELACHE =>
                -- Tous les bits envoyes : on passe a la tempo inter-trames
                if Cpt_Bits = 0 then
                    EF <= TEMPO;
                else
                    EF <= SHIFT;
                end if;

            when SHIFT =>
                EF <= READ_BIT;

            when TEMPO =>
                if Fin_Tempo = '1' then
                    EF <= LOAD;
                end if;
        end case;
    end process;

    -- Sorties (Moore : depend uniquement de EP)
    process(EP)
    begin
        COM_REG     <= "00";
        Go_1        <= '0';
        Go_0        <= '0';
        Start_Tempo <= '0';

        case EP is
            when LOAD =>
                COM_REG <= "01";       -- chargement parallele du registre

            when READ_BIT =>
                COM_REG <= "00";

            when GEN_1 =>
                Go_1 <= '1';

            when GEN_0 =>
                Go_0 <= '1';

            when RELACHE =>
                null;                  -- handshake : Go redescend

            when SHIFT =>
                COM_REG <= "10";       -- decalage d'un bit

            when TEMPO =>
                Start_Tempo <= '1';
        end case;
    end process;

    -- Compteur de bits restants
    process(Clk, Reset)
    begin
        if Reset = '1' then
            Cpt_Bits <= 50;
        elsif rising_edge(Clk) then
            if EP = LOAD then
                Cpt_Bits <= 50;
            elsif EP = SHIFT then
                Cpt_Bits <= Cpt_Bits - 1;
            end if;
        end if;
    end process;

end Behavioral;
