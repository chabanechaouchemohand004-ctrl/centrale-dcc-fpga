----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- TP Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- Testbench systeme du TOP_DCC.
-- On laisse tourner le systeme avec differents reglages d'interrupteurs
-- pour observer la sequence des trames sur Sortie_DCC.
--
-- Une trame complete + tempo prend environ 14 ms : pour voir 2 cycles,
-- regler la duree de simulation a au moins 30 ms dans Vivado
-- (Settings > Simulation > xsim.simulate.runtime = 30ms).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_TOP_DCC is
end TB_TOP_DCC;

architecture Behavioral of TB_TOP_DCC is

    component TOP_DCC
        Port (
            CLK_100MHz   : in  STD_LOGIC;
            Reset        : in  STD_LOGIC;
            Interrupteur : in  STD_LOGIC_VECTOR(7 downto 0);
            Sortie_DCC   : out STD_LOGIC
        );
    end component;

    signal CLK_100MHz   : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Interrupteur : std_logic_vector(7 downto 0) := "00000000";
    signal Sortie_DCC   : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: TOP_DCC
        port map (
            CLK_100MHz   => CLK_100MHz,
            Reset        => Reset,
            Interrupteur => Interrupteur,
            Sortie_DCC   => Sortie_DCC
        );

    process
    begin
        CLK_100MHz <= '0'; wait for CLK_PERIOD / 2;
        CLK_100MHz <= '1'; wait for CLK_PERIOD / 2;
    end process;

    process
    begin
        -- Reset : trame d'arret par defaut
        Reset <= '1';
        Interrupteur <= "00000000";
        wait for 10 us;
        Reset <= '0';
        report "Demarrage : trame d'arret (aucun SW)" severity note;

        -- Une trame complete + tempo
        wait for 15 ms;

        -- Marche avant (SW7) : le changement est pris en compte au prochain LOAD
        Interrupteur <= "10000000";
        report "Changement : marche avant (SW7)" severity note;
        wait for 15 ms;

        -- Phares ON (SW5)
        Interrupteur <= "00100000";
        report "Changement : phares ON (SW5)" severity note;
        wait for 15 ms;

        report "Fin de simulation" severity note;
        wait;
    end process;

end Behavioral;
