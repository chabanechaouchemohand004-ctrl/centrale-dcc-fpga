----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- TP Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- Testbench du DCC_FRAME_GENERATOR.
-- Pour chaque interrupteur, on extrait les champs de la trame (adresse, cmd, ctrl)
-- et on verifie que l'octet de controle est bien le XOR des octets precedents.
-- On verifie aussi quelques bits caracteristiques (direction, F0, F11, F13).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_GENERATEUR_TRAMES is
end TB_GENERATEUR_TRAMES;

architecture Behavioral of TB_GENERATEUR_TRAMES is

    component DCC_FRAME_GENERATOR
        Port (
            Interrupteur : in  STD_LOGIC_VECTOR(7 downto 0);
            Trame_DCC    : out STD_LOGIC_VECTOR(50 downto 0)
        );
    end component;

    signal Interrupteur : std_logic_vector(7 downto 0) := "00000000";
    signal Trame_DCC    : std_logic_vector(50 downto 0);

begin

    UUT: DCC_FRAME_GENERATOR
        port map (
            Interrupteur => Interrupteur,
            Trame_DCC    => Trame_DCC
        );

    process
        -- Trame 1 octet (padded a 51 bits) :
        --   bits 50..28 preambule, 27 start, 26..19 addr, 18 start,
        --   17..10 cmd, 9 start, 8..1 ctrl, 0 stop
        variable addr_1oct  : std_logic_vector(7 downto 0);
        variable cmd_1oct   : std_logic_vector(7 downto 0);
        variable ctrl_1oct  : std_logic_vector(7 downto 0);
        variable xor_1oct   : std_logic_vector(7 downto 0);

        -- Trame 2 octets :
        --   bits 50..37 preambule, 36 start, 35..28 addr, 27 start,
        --   26..19 cmd1, 18 start, 17..10 cmd2, 9 start, 8..1 ctrl, 0 stop
        variable addr_2oct  : std_logic_vector(7 downto 0);
        variable cmd1_2oct  : std_logic_vector(7 downto 0);
        variable cmd2_2oct  : std_logic_vector(7 downto 0);
        variable ctrl_2oct  : std_logic_vector(7 downto 0);
        variable xor_2oct   : std_logic_vector(7 downto 0);
    begin

        wait for 10 ns;

        -- SW7 : Marche avant
        Interrupteur <= "10000000";
        wait for 10 ns;
        assert Trame_DCC(0) = '1'
            report "SW7 : Stop bit manquant" severity error;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "SW7 : XOR incorrect" severity error;
        assert addr_1oct = "00000011"
            report "SW7 : Adresse incorrecte" severity error;
        report "SW7 (Marche avant) : OK" severity note;

        -- SW6 : Marche arriere - bit 5 de la cmd a '0' pour le sens arriere
        Interrupteur <= "01000000";
        wait for 10 ns;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "SW6 : XOR incorrect" severity error;
        assert cmd_1oct(5) = '0'
            report "SW6 : bit de direction devrait etre '0' (arriere)" severity error;
        report "SW6 (Marche arriere) : OK" severity note;

        -- SW5 : Phares ON - bit 4 de la cmd a '1' (F0)
        Interrupteur <= "00100000";
        wait for 10 ns;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "SW5 : XOR incorrect" severity error;
        assert cmd_1oct(4) = '1'
            report "SW5 : F0 devrait etre ON" severity error;
        report "SW5 (Phares ON) : OK" severity note;

        -- SW4 : Phares OFF - bit 4 de la cmd a '0'
        Interrupteur <= "00010000";
        wait for 10 ns;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "SW4 : XOR incorrect" severity error;
        assert cmd_1oct(4) = '0'
            report "SW4 : F0 devrait etre OFF" severity error;
        report "SW4 (Phares OFF) : OK" severity note;

        -- SW3 : Klaxon F11 ON - bit 2 de la cmd a '1'
        Interrupteur <= "00001000";
        wait for 10 ns;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "SW3 : XOR incorrect" severity error;
        assert cmd_1oct(2) = '1'
            report "SW3 : F11 devrait etre ON" severity error;
        report "SW3 (Klaxon ON) : OK" severity note;

        -- SW2 : Klaxon F11 OFF - bit 2 de la cmd a '0'
        Interrupteur <= "00000100";
        wait for 10 ns;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "SW2 : XOR incorrect" severity error;
        assert cmd_1oct(2) = '0'
            report "SW2 : F11 devrait etre OFF" severity error;
        report "SW2 (Klaxon OFF) : OK" severity note;

        -- SW1 : F13 ON (trame 2 octets) - bit 0 de cmd2 a '1'
        Interrupteur <= "00000010";
        wait for 10 ns;
        addr_2oct := Trame_DCC(35 downto 28);
        cmd1_2oct := Trame_DCC(26 downto 19);
        cmd2_2oct := Trame_DCC(17 downto 10);
        ctrl_2oct := Trame_DCC(8 downto 1);
        xor_2oct  := addr_2oct xor cmd1_2oct xor cmd2_2oct;
        assert ctrl_2oct = xor_2oct
            report "SW1 : XOR incorrect (3 octets)" severity error;
        assert cmd2_2oct(0) = '1'
            report "SW1 : F13 devrait etre ON" severity error;
        report "SW1 (Annonce F13 ON) : OK" severity note;

        -- SW0 : F13 OFF (trame 2 octets) - bit 0 de cmd2 a '0'
        Interrupteur <= "00000001";
        wait for 10 ns;
        addr_2oct := Trame_DCC(35 downto 28);
        cmd1_2oct := Trame_DCC(26 downto 19);
        cmd2_2oct := Trame_DCC(17 downto 10);
        ctrl_2oct := Trame_DCC(8 downto 1);
        xor_2oct  := addr_2oct xor cmd1_2oct xor cmd2_2oct;
        assert ctrl_2oct = xor_2oct
            report "SW0 : XOR incorrect" severity error;
        assert cmd2_2oct(0) = '0'
            report "SW0 : F13 devrait etre OFF" severity error;
        report "SW0 (Annonce F13 OFF) : OK" severity note;

        -- Defaut (aucun SW) : trame d'arret
        Interrupteur <= "00000000";
        wait for 10 ns;
        addr_1oct := Trame_DCC(26 downto 19);
        cmd_1oct  := Trame_DCC(17 downto 10);
        ctrl_1oct := Trame_DCC(8 downto 1);
        xor_1oct  := addr_1oct xor cmd_1oct;
        assert ctrl_1oct = xor_1oct
            report "Defaut : XOR incorrect" severity error;
        report "Defaut (Arret) : OK" severity note;

        report "Tous les tests generateur passes" severity note;
        wait;
    end process;

end Behavioral;
