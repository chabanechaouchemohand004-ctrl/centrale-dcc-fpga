----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- TP Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- DCC_FRAME_GENERATOR : genere la trame DCC de 51 bits a transmettre,
-- selon l'etat des 8 interrupteurs. Train d'adresse 3.
--
-- Si plusieurs interrupteurs sont actifs, c'est celui de plus fort indice qui
-- l'emporte (priorite naturelle de la cascade if/elsif).
--
-- Structure trame 1 octet  : [23b preambule][0][addr][0][cmd][0][ctrl][1]  = 51b
-- Structure trame 2 octets : [14b preambule][0][addr][0][cmd1][0][cmd2][0][ctrl][1] = 51b
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DCC_FRAME_GENERATOR is
    Port ( Interrupteur : in  STD_LOGIC_VECTOR(7 downto 0);
           Trame_DCC    : out STD_LOGIC_VECTOR(50 downto 0));
end DCC_FRAME_GENERATOR;

architecture Behavioral of DCC_FRAME_GENERATOR is

begin

process(Interrupteur)
begin

    -- SW7 : Marche avant, step 10
    -- Cmd = 01110110, Ctrl = adresse XOR cmd = 00000011 XOR 01110110 = 01110101
    if Interrupteur(7) = '1' then
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "01110110"
                   & "0" & "01110101"
                   & "1";

    -- SW6 : Marche arriere, step 10
    -- Cmd = 01010110, Ctrl = 00000011 XOR 01010110 = 01010101
    elsif Interrupteur(6) = '1' then
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "01010110"
                   & "0" & "01010101"
                   & "1";

    -- SW5 : Phares ON (F0)
    -- Cmd = 10010000, Ctrl = 00000011 XOR 10010000 = 10010011
    elsif Interrupteur(5) = '1' then
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "10010000"
                   & "0" & "10010011"
                   & "1";

    -- SW4 : Phares OFF (F0)
    -- Cmd = 10000000, Ctrl = 00000011 XOR 10000000 = 10000011
    elsif Interrupteur(4) = '1' then
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "10000000"
                   & "0" & "10000011"
                   & "1";

    -- SW3 : Klaxon ON (F11)
    -- Cmd = 10100100, Ctrl = 00000011 XOR 10100100 = 10100111
    elsif Interrupteur(3) = '1' then
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "10100100"
                   & "0" & "10100111"
                   & "1";

    -- SW2 : Klaxon OFF (F11)
    -- Cmd = 10100000, Ctrl = 00000011 XOR 10100000 = 10100011
    elsif Interrupteur(2) = '1' then
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "10100000"
                   & "0" & "10100011"
                   & "1";

    -- SW1 : Annonce SNCF ON (F13) - trame 2 octets
    -- Cmd1 = 11011110, Cmd2 = 00000001
    -- Ctrl = 00000011 XOR 11011110 XOR 00000001 = 11011100
    elsif Interrupteur(1) = '1' then
        Trame_DCC <= "11111111111111"
                   & "0" & "00000011"
                   & "0" & "11011110"
                   & "0" & "00000001"
                   & "0" & "11011100"
                   & "1";

    -- SW0 : Annonce SNCF OFF (F13) - trame 2 octets
    -- Cmd1 = 11011110, Cmd2 = 00000000
    -- Ctrl = 00000011 XOR 11011110 XOR 00000000 = 11011101
    elsif Interrupteur(0) = '1' then
        Trame_DCC <= "11111111111111"
                   & "0" & "00000011"
                   & "0" & "11011110"
                   & "0" & "00000000"
                   & "0" & "11011101"
                   & "1";

    -- Defaut : arret du train
    -- Cmd = 01100000, Ctrl = 00000011 XOR 01100000 = 01100011
    else
        Trame_DCC <= "11111111111111111111111"
                   & "0" & "00000011"
                   & "0" & "01100000"
                   & "0" & "01100011"
                   & "1";

    end if;

end process;

end Behavioral;
