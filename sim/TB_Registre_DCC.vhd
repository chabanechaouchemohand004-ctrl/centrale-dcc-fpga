----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- TP Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- Testbench du REGISTRE_DCC.
-- Strategie : reset, chargement d'une trame connue, decalage des 51 bits avec
-- verification que la sequence sortie correspond bien a la trame, puis
-- rechargement pour controler la re-entrance.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_REGISTRE_DCC is
end TB_REGISTRE_DCC;

architecture Behavioral of TB_REGISTRE_DCC is

    component REGISTRE_DCC
        Port (
            Clk          : in  STD_LOGIC;
            Reset        : in  STD_LOGIC;
            Trame_DCC    : in  STD_LOGIC_VECTOR(50 downto 0);
            COM_REG      : in  STD_LOGIC_VECTOR(1 downto 0);
            Bit_Courant  : out STD_LOGIC
        );
    end component;

    signal Clk          : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Trame_DCC    : std_logic_vector(50 downto 0);
    signal COM_REG      : std_logic_vector(1 downto 0) := "00";
    signal Bit_Courant  : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    -- Trame de reference : marche avant step 10 du train d'adresse 3
    constant TRAME_TEST : std_logic_vector(50 downto 0) :=
        "11111111111111111111111" &
        "0" & "00000011" &
        "0" & "01110110" &
        "0" & "01110101" &
        "1";

begin

    UUT: REGISTRE_DCC
        port map (
            Clk         => Clk,
            Reset       => Reset,
            Trame_DCC   => Trame_DCC,
            COM_REG     => COM_REG,
            Bit_Courant => Bit_Courant
        );

    process
    begin
        Clk <= '0'; wait for CLK_PERIOD / 2;
        Clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    process
    begin
        -- Reset
        Reset <= '1';
        COM_REG <= "00";
        Trame_DCC <= (others => '0');
        wait for 100 ns;
        Reset <= '0';
        wait for 20 ns;

        -- Apres reset, le registre est rempli de '1'
        assert Bit_Courant = '1'
            report "Bit_Courant devrait etre '1' apres reset"
            severity error;

        -- Chargement de la trame de test
        Trame_DCC <= TRAME_TEST;
        COM_REG <= "01";
        wait for CLK_PERIOD;
        COM_REG <= "00";
        wait for CLK_PERIOD;

        assert Bit_Courant = '1'
            report "Bit_Courant devrait etre '1' (debut du preambule)"
            severity error;

        -- Decalage des 51 bits, on verifie la sequence sortie
        for i in 50 downto 0 loop
            assert Bit_Courant = TRAME_TEST(i)
                report "Erreur au bit " & integer'image(i) &
                       " : attendu " & std_logic'image(TRAME_TEST(i)) &
                       ", obtenu " & std_logic'image(Bit_Courant)
                severity error;

            COM_REG <= "10";
            wait for CLK_PERIOD;
            COM_REG <= "00";
            wait for CLK_PERIOD;
        end loop;

        -- Apres 51 decalages, le registre est entierement rempli de '0'
        assert Bit_Courant = '0'
            report "Bit_Courant devrait etre '0' apres 51 decalages"
            severity error;

        -- Rechargement pour verifier que ca fonctionne plusieurs fois
        Trame_DCC <= TRAME_TEST;
        COM_REG <= "01";
        wait for CLK_PERIOD;
        COM_REG <= "00";
        wait for CLK_PERIOD;

        assert Bit_Courant = '1'
            report "Bit_Courant devrait etre '1' apres rechargement"
            severity error;

        report "Test REGISTRE_DCC termine" severity note;
        wait;
    end process;

end Behavioral;
