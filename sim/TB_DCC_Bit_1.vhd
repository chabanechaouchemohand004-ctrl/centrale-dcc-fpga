----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- TP Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- Testbench du module DCC_BIT_1.
-- Verifie le repos apres reset, le timing des deux phases (58 us chacune),
-- le handshake Go/Fin et la reactivation pour une seconde emission.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_DCC_BIT_1 is
end TB_DCC_BIT_1;

architecture Behavioral of TB_DCC_BIT_1 is

    signal Clk       : STD_LOGIC := '0';
    signal Reset     : STD_LOGIC := '0';
    signal Clk1M     : STD_LOGIC := '0';
    signal Go        : STD_LOGIC := '0';
    signal Fin       : STD_LOGIC;
    signal DCC_1     : STD_LOGIC;

    constant CLK_PERIOD   : time := 10 ns;    -- 100 MHz
    constant CLK1M_PERIOD : time := 1000 ns;  -- 1 MHz

begin

    UUT: entity work.DCC_BIT_1
        port map (
            Clk   => Clk,
            Reset => Reset,
            Clk1M => Clk1M,
            Go    => Go,
            Fin   => Fin,
            DCC_1 => DCC_1
        );

    -- Horloges
    process
    begin
        Clk <= '0'; wait for CLK_PERIOD / 2;
        Clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    process
    begin
        Clk1M <= '0'; wait for CLK1M_PERIOD / 2;
        Clk1M <= '1'; wait for CLK1M_PERIOD / 2;
    end process;

    -- Stimulus
    process
    begin
        Reset <= '1';
        wait for 100 ns;
        Reset <= '0';
        wait for 100 ns;

        assert DCC_1 = '0'
            report "DCC_1 devrait etre a '0' apres reset"
            severity ERROR;
        assert Fin = '0'
            report "Fin devrait etre a '0' apres reset"
            severity ERROR;

        -- Premiere emission
        wait until rising_edge(Clk);
        Go <= '1';

        -- Au milieu de la phase basse (58 us au total)
        wait for 10 us;
        assert DCC_1 = '0'
            report "DCC_1 devrait etre a '0' pendant la phase basse"
            severity ERROR;

        wait until DCC_1 = '1';
        wait for 30 us;
        assert DCC_1 = '1'
            report "DCC_1 devrait etre a '1' au milieu de la phase haute"
            severity ERROR;

        wait until Fin = '1';
        assert DCC_1 = '0'
            report "DCC_1 devrait etre a '0' dans l'etat DONE"
            severity ERROR;

        -- Handshake : on relache Go pour repasser en IDLE
        wait for 5 us;
        Go <= '0';
        wait for 1 us;
        assert Fin = '0'
            report "Fin devrait redescendre a '0' quand Go='0'"
            severity ERROR;

        -- Seconde emission pour verifier la reactivation
        wait for 10 us;
        wait until rising_edge(Clk);
        Go <= '1';
        wait until Fin = '1';
        assert DCC_1 = '0'
            report "DCC_1 devrait etre a '0' apres la 2eme emission"
            severity ERROR;
        Go <= '0';
        wait for 5 us;

        report "Test DCC_BIT_1 termine" severity NOTE;
        wait;
    end process;

end Behavioral;
