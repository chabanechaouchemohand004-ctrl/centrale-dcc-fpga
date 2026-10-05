----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- TB_TOP_DCC_AUTO : testbench systeme AUTO-VERIFIANT du TOP_DCC (Phase 1).
--
-- Un moniteur decode le signal Sortie_DCC comme le ferait un decodeur :
--   * mesure la duree de chaque demi-periode (basse puis haute)
--   * classe chaque bit en '0' ou '1' selon sa phase haute
--   * detecte la fin de trame grace a la temporisation (> 1 ms a '0')
--
-- Verifications par assertions :
--   1) timing NMRA S-9.1 cote centrale :
--        bit '1' : chaque demi-periode entre 55 et 61 us, |A - B| <= 3 us
--        bit '0' : chaque demi-periode entre 95 et 9900 us
--   2) contenu : chaque trame decodee = trame attendue, calculee ICI de facon
--      independante (preambule, bits de start, XOR de controle, stop bit)
--
-- Lancement (GHDL) : voir sim/run_sim.sh
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_TOP_DCC_AUTO is
end TB_TOP_DCC_AUTO;

architecture Behavioral of TB_TOP_DCC_AUTO is

    constant CLK_PERIOD : time := 10 ns;
    constant ADRESSE    : std_logic_vector(7 downto 0) := x"03";

    signal CLK_100MHz   : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Interrupteur : std_logic_vector(7 downto 0) := (others => '0');
    signal Sortie_DCC   : std_logic;

    -- Sortie du moniteur
    signal Trame_Lue    : std_logic_vector(50 downto 0);
    signal Nb_Bits_Lus  : integer := 0;
    signal Evt_Trame    : boolean := false;
    signal Nb_Erreurs_Timing : integer := 0;

    -- Trame attendue, format 1 octet de commande (preambule 23 bits)
    function trame_1_octet(addr, cmd : std_logic_vector(7 downto 0))
        return std_logic_vector is
    begin
        return (22 downto 0 => '1') & '0' & addr & '0' & cmd & '0'
               & (addr xor cmd) & '1';
    end function;

    -- Trame attendue, format 2 octets de commande (preambule 14 bits)
    function trame_2_octets(addr, cmd1, cmd2 : std_logic_vector(7 downto 0))
        return std_logic_vector is
    begin
        return (13 downto 0 => '1') & '0' & addr & '0' & cmd1 & '0' & cmd2 & '0'
               & (addr xor cmd1 xor cmd2) & '1';
    end function;

begin

    UUT : entity work.TOP_DCC
        port map (
            CLK_100MHz   => CLK_100MHz,
            Reset        => Reset,
            Interrupteur => Interrupteur,
            Sortie_DCC   => Sortie_DCC
        );

    CLK_100MHz <= not CLK_100MHz after CLK_PERIOD / 2;

    ------------------------------------------------------------------------------
    -- Moniteur : decodage de Sortie_DCC + verification du timing NMRA S-9.1
    ------------------------------------------------------------------------------
    moniteur : process
        variable t_front    : time := 0 ns;
        variable duree_bas  : time;
        variable duree_haut : time;
        variable premier    : boolean := true;   -- 1er bit d'une trame (phase basse
                                                 -- fusionnee avec la tempo)
        variable trame      : std_logic_vector(50 downto 0);
        variable n          : integer := 0;
        variable bit_lu     : std_logic;
        variable erreurs    : integer := 0;
    begin
        wait until Reset = '0';
        t_front := now;

        loop
            -- Fin de la phase basse
            wait until rising_edge(Sortie_DCC);
            duree_bas := now - t_front;
            t_front   := now;

            if duree_bas > 1 ms then
                -- Temporisation inter-trames detectee : la trame precedente est finie
                if n > 0 then
                    Trame_Lue   <= trame;
                    Nb_Bits_Lus <= n;
                    Evt_Trame   <= not Evt_Trame;
                end if;
                n       := 0;
                premier := true;
            end if;

            -- Fin de la phase haute
            wait until falling_edge(Sortie_DCC);
            duree_haut := now - t_front;
            t_front    := now;

            if duree_haut < 80 us then
                bit_lu := '1';
                if duree_haut < 55 us or duree_haut > 61 us then
                    report "Timing bit '1' : phase haute = " & time'image(duree_haut)
                        & " (attendu 55..61 us)" severity error;
                    erreurs := erreurs + 1;
                end if;
                if not premier then
                    if duree_bas < 55 us or duree_bas > 61 us then
                        report "Timing bit '1' : phase basse = " & time'image(duree_bas)
                            & " (attendu 55..61 us)" severity error;
                        erreurs := erreurs + 1;
                    end if;
                    if abs(duree_haut - duree_bas) > 3 us then
                        report "Timing bit '1' : |A-B| = "
                            & time'image(abs(duree_haut - duree_bas))
                            & " (max 3 us)" severity error;
                        erreurs := erreurs + 1;
                    end if;
                end if;
            else
                bit_lu := '0';
                if duree_haut < 95 us or duree_haut > 9900 us then
                    report "Timing bit '0' : phase haute = " & time'image(duree_haut)
                        & " (attendu 95..9900 us)" severity error;
                    erreurs := erreurs + 1;
                end if;
                if not premier and (duree_bas < 95 us or duree_bas > 9900 us) then
                    report "Timing bit '0' : phase basse = " & time'image(duree_bas)
                        & " (attendu 95..9900 us)" severity error;
                    erreurs := erreurs + 1;
                end if;
            end if;

            if n <= 50 then
                trame(50 - n) := bit_lu;   -- MSB transmis en premier
            end if;
            n       := n + 1;
            premier := false;
            Nb_Erreurs_Timing <= erreurs;
        end loop;
    end process;

    ------------------------------------------------------------------------------
    -- Stimulus + verification du contenu des trames
    ------------------------------------------------------------------------------
    stimulus : process

        procedure verifier(sw      : std_logic_vector(7 downto 0);
                           attendu : std_logic_vector(50 downto 0);
                           nom     : string) is
        begin
            Interrupteur <= sw;
            -- La 1re trame complete apres le changement peut encore etre l'ancienne
            -- (chargee avant le changement) : on verifie la 2e.
            wait on Evt_Trame;
            wait on Evt_Trame;
            assert Nb_Bits_Lus = 51
                report nom & " : " & integer'image(Nb_Bits_Lus)
                       & " bits recus au lieu de 51" severity error;
            assert Trame_Lue = attendu
                report nom & " : trame recue differente de la trame attendue"
                severity error;
            if Nb_Bits_Lus = 51 and Trame_Lue = attendu then
                report nom & " : OK" severity note;
            end if;
        end procedure;

    begin
        Reset <= '1';
        wait for 1 us;
        Reset <= '0';

        verifier("00000000", trame_1_octet(ADRESSE, "01100000"), "Arret (defaut)");
        verifier("10000000", trame_1_octet(ADRESSE, "01110110"), "SW7 marche avant");
        verifier("01000000", trame_1_octet(ADRESSE, "01010110"), "SW6 marche arriere");
        verifier("00100000", trame_1_octet(ADRESSE, "10010000"), "SW5 phares ON");
        verifier("00000010", trame_2_octets(ADRESSE, "11011110", "00000001"),
                 "SW1 annonce F13 ON (2 octets)");
        -- Priorite : SW7 doit l'emporter sur SW5
        verifier("10100000", trame_1_octet(ADRESSE, "01110110"), "Priorite SW7 > SW5");

        assert Nb_Erreurs_Timing = 0
            report integer'image(Nb_Erreurs_Timing) & " erreur(s) de timing NMRA"
            severity error;

        report "=== FIN TB_TOP_DCC_AUTO ===" severity note;
        std.env.finish;
    end process;

end Behavioral;
