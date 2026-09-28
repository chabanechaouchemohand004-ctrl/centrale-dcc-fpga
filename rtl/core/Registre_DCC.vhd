----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA - projet M1 SYSCOM, Sorbonne Universite
-- TP Centrale DCC
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- REGISTRE_DCC : registre a decalage 51 bits, pilote par la MAE globale.
--
-- Commande COM_REG :
--   "01" -> chargement parallele de Trame_DCC
--   "10" -> decalage a gauche (un '0' entre a droite)
--   autre -> maintien
--
-- La sortie Bit_Courant donne le MSB du registre (prochain bit a transmettre).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity REGISTRE_DCC is
    Port (
        Clk          : in  STD_LOGIC;
        Reset        : in  STD_LOGIC;
        Trame_DCC    : in  STD_LOGIC_VECTOR(50 downto 0);
        COM_REG      : in  STD_LOGIC_VECTOR(1 downto 0);
        Bit_Courant  : out STD_LOGIC
    );
end REGISTRE_DCC;

architecture Behavioral of REGISTRE_DCC is

    signal Reg : STD_LOGIC_VECTOR(50 downto 0);

begin

    process(Clk, Reset)
    begin
        if Reset = '1' then
            -- Registre rempli de '1' : si la MAE emet avant le premier chargement,
            -- on envoie du preambule au lieu de bits aleatoires
            Reg <= (others => '1');

        elsif rising_edge(Clk) then
            case COM_REG is
                when "01" =>
                    Reg <= Trame_DCC;

                when "10" =>
                    Reg <= Reg(49 downto 0) & '0';

                when others =>
                    Reg <= Reg;
            end case;
        end if;
    end process;

    Bit_Courant <= Reg(50);

end Behavioral;
