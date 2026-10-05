----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- Projet Centrale DCC - Phase 2 (integration MicroBlaze)
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- COEUR_DCC : Top_DCC de la Phase 1 prive du generateur de trames et des
-- interrupteurs. La trame DCC arrive maintenant directement en entree,
-- preparee par le MicroBlaze et validee (front montant de REG2) dans le wrapper AXI.
--
-- Reset actif haut : l'inversion du reset AXI (actif bas) est faite dans
-- le wrapper, avant d'attaquer cette entree.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity COEUR_DCC is
    Port (
        CLK_100MHz   : in  STD_LOGIC;
        Reset        : in  STD_LOGIC;
        Trame_DCC    : in  STD_LOGIC_VECTOR(50 downto 0);
        Sortie_DCC   : out STD_LOGIC
    );
end COEUR_DCC;

architecture Structural of COEUR_DCC is

    component CLK_DIV
        Port (
            Reset   : in  STD_LOGIC;
            Clk_In  : in  STD_LOGIC;
            Clk_Out : out STD_LOGIC
        );
    end component;

    component COMPTEUR_TEMPO
        Port (
            Clk         : in  STD_LOGIC;
            Reset       : in  STD_LOGIC;
            Clk1M       : in  STD_LOGIC;
            Start_Tempo : in  STD_LOGIC;
            Fin_Tempo   : out STD_LOGIC
        );
    end component;

    component REGISTRE_DCC
        Port (
            Clk         : in  STD_LOGIC;
            Reset       : in  STD_LOGIC;
            Trame_DCC   : in  STD_LOGIC_VECTOR(50 downto 0);
            COM_REG     : in  STD_LOGIC_VECTOR(1 downto 0);
            Bit_Courant : out STD_LOGIC
        );
    end component;

    component MAE_DCC
        Port (
            Clk         : in  STD_LOGIC;
            Reset       : in  STD_LOGIC;
            Bit_Courant : in  STD_LOGIC;
            COM_REG     : out STD_LOGIC_VECTOR(1 downto 0);
            Go_1        : out STD_LOGIC;
            Fin_1       : in  STD_LOGIC;
            Go_0        : out STD_LOGIC;
            Fin_0       : in  STD_LOGIC;
            Start_Tempo : out STD_LOGIC;
            Fin_Tempo   : in  STD_LOGIC
        );
    end component;

    component DCC_BIT_1
        Port (
            Clk   : in  STD_LOGIC;
            Clk1M : in  STD_LOGIC;
            Reset : in  STD_LOGIC;
            Go    : in  STD_LOGIC;
            Fin   : out STD_LOGIC;
            DCC_1 : out STD_LOGIC
        );
    end component;

    component DCC_BIT_0
        Port (
            Clk   : in  STD_LOGIC;
            Clk1M : in  STD_LOGIC;
            Reset : in  STD_LOGIC;
            Go    : in  STD_LOGIC;
            Fin   : out STD_LOGIC;
            DCC_0 : out STD_LOGIC
        );
    end component;

    signal CLK_1MHz     : STD_LOGIC;
    signal COM_REG      : STD_LOGIC_VECTOR(1 downto 0);
    signal Bit_Courant  : STD_LOGIC;
    signal Go_1, Fin_1  : STD_LOGIC;
    signal Go_0, Fin_0  : STD_LOGIC;
    signal DCC_1_out    : STD_LOGIC;
    signal DCC_0_out    : STD_LOGIC;
    signal Start_Tempo  : STD_LOGIC;
    signal Fin_Tempo    : STD_LOGIC;

begin

    inst_CLK_DIV : CLK_DIV
        port map (Reset => Reset, Clk_In => CLK_100MHz, Clk_Out => CLK_1MHz);

    inst_TEMPO : COMPTEUR_TEMPO
        port map (
            Clk => CLK_100MHz, Reset => Reset, Clk1M => CLK_1MHz,
            Start_Tempo => Start_Tempo, Fin_Tempo => Fin_Tempo
        );

    inst_REG : REGISTRE_DCC
        port map (
            Clk => CLK_100MHz, Reset => Reset,
            Trame_DCC => Trame_DCC, COM_REG => COM_REG,
            Bit_Courant => Bit_Courant
        );

    inst_MAE : MAE_DCC
        port map (
            Clk => CLK_100MHz, Reset => Reset,
            Bit_Courant => Bit_Courant, COM_REG => COM_REG,
            Go_1 => Go_1, Fin_1 => Fin_1,
            Go_0 => Go_0, Fin_0 => Fin_0,
            Start_Tempo => Start_Tempo, Fin_Tempo => Fin_Tempo
        );

    inst_BIT1 : DCC_BIT_1
        port map (
            Clk => CLK_100MHz, Clk1M => CLK_1MHz, Reset => Reset,
            Go => Go_1, Fin => Fin_1, DCC_1 => DCC_1_out
        );

    inst_BIT0 : DCC_BIT_0
        port map (
            Clk => CLK_100MHz, Clk1M => CLK_1MHz, Reset => Reset,
            Go => Go_0, Fin => Fin_0, DCC_0 => DCC_0_out
        );

    Sortie_DCC <= DCC_1_out or DCC_0_out;

end Structural;
