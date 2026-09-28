----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- CLK_DIV : generateur d'un signal carre 1 MHz a partir de l'horloge 100 MHz.
--
-- Reecriture personnelle du module fourni en TP (memes ports).
-- Clk_Out n'est JAMAIS utilise comme horloge : les modules DCC_BIT_x et
-- COMPTEUR_TEMPO l'echantillonnent a 100 MHz et detectent son front montant
-- (Tick 1 us). Tout le design reste donc dans un seul domaine d'horloge.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CLK_DIV is
    Port (
        Reset   : in  STD_LOGIC;
        Clk_In  : in  STD_LOGIC;   -- 100 MHz
        Clk_Out : out STD_LOGIC    -- carre 1 MHz (50 cycles haut / 50 cycles bas)
    );
end CLK_DIV;

architecture Behavioral of CLK_DIV is

    constant DEMI_PERIODE : integer := 50;   -- 50 x 10 ns = 500 ns

    signal Cpt   : integer range 0 to DEMI_PERIODE - 1;
    signal Carre : std_logic;

begin

    process(Clk_In, Reset)
    begin
        if Reset = '1' then
            Cpt   <= 0;
            Carre <= '0';
        elsif rising_edge(Clk_In) then
            if Cpt = DEMI_PERIODE - 1 then
                Cpt   <= 0;
                Carre <= not Carre;
            else
                Cpt <= Cpt + 1;
            end if;
        end if;
    end process;

    Clk_Out <= Carre;

end Behavioral;
