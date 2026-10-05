----------------------------------------------------------------------------------
-- Centrale DCC sur FPGA
-- Auteur : Mohand CHABANE CHAOUCHE
--
-- TB_CENTRALE_DCC_AXI : testbench AUTO-VERIFIANT de l'IP AXI-Lite (Phase 2).
--
-- Le testbench joue le role du MicroBlaze : il ecrit les registres de l'IP
-- par de vraies transactions AXI4-Lite (procedure axi_write), puis decode le
-- signal Sortie_DCC pour verifier la trame reellement emise.
--
-- Scenarios verifies :
--   1) Apres reset : l'IP emet la trame d'arret par defaut (securite)
--   2) REG0/REG1 ecrits SANS validation : la trame emise ne change pas
--   3) Front montant sur REG2(0) : la nouvelle trame est emise
--   4) Flag REG2(0) laisse a '1' puis REG0/REG1 reecrits : pas de changement
--      (la validation est sur front, pas sur niveau)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_CENTRALE_DCC_AXI is
end TB_CENTRALE_DCC_AXI;

architecture Behavioral of TB_CENTRALE_DCC_AXI is

    constant CLK_PERIOD : time := 10 ns;
    constant ADRESSE    : std_logic_vector(7 downto 0) := x"03";

    constant OFFSET_REG0 : std_logic_vector(3 downto 0) := x"0";
    constant OFFSET_REG1 : std_logic_vector(3 downto 0) := x"4";
    constant OFFSET_REG2 : std_logic_vector(3 downto 0) := x"8";

    signal ACLK    : std_logic := '0';
    signal ARESETN : std_logic := '0';

    signal AWADDR  : std_logic_vector(3 downto 0) := (others => '0');
    signal AWPROT  : std_logic_vector(2 downto 0) := (others => '0');
    signal AWVALID : std_logic := '0';
    signal AWREADY : std_logic;
    signal WDATA   : std_logic_vector(31 downto 0) := (others => '0');
    signal WSTRB   : std_logic_vector(3 downto 0) := (others => '1');
    signal WVALID  : std_logic := '0';
    signal WREADY  : std_logic;
    signal BRESP   : std_logic_vector(1 downto 0);
    signal BVALID  : std_logic;
    signal BREADY  : std_logic := '0';
    signal ARADDR  : std_logic_vector(3 downto 0) := (others => '0');
    signal ARPROT  : std_logic_vector(2 downto 0) := (others => '0');
    signal ARVALID : std_logic := '0';
    signal ARREADY : std_logic;
    signal RDATA   : std_logic_vector(31 downto 0);
    signal RRESP   : std_logic_vector(1 downto 0);
    signal RVALID  : std_logic;
    signal RREADY  : std_logic := '0';

    signal Sortie_DCC : std_logic;

    signal Trame_Lue   : std_logic_vector(50 downto 0);
    signal Nb_Bits_Lus : integer := 0;
    signal Evt_Trame   : boolean := false;

    function trame_1_octet(addr, cmd : std_logic_vector(7 downto 0))
        return std_logic_vector is
    begin
        return (22 downto 0 => '1') & '0' & addr & '0' & cmd & '0'
               & (addr xor cmd) & '1';
    end function;

begin

    UUT : entity work.Centrale_DCC_v1_0
        port map (
            Sortie_DCC      => Sortie_DCC,
            s00_axi_aclk    => ACLK,
            s00_axi_aresetn => ARESETN,
            s00_axi_awaddr  => AWADDR,
            s00_axi_awprot  => AWPROT,
            s00_axi_awvalid => AWVALID,
            s00_axi_awready => AWREADY,
            s00_axi_wdata   => WDATA,
            s00_axi_wstrb   => WSTRB,
            s00_axi_wvalid  => WVALID,
            s00_axi_wready  => WREADY,
            s00_axi_bresp   => BRESP,
            s00_axi_bvalid  => BVALID,
            s00_axi_bready  => BREADY,
            s00_axi_araddr  => ARADDR,
            s00_axi_arprot  => ARPROT,
            s00_axi_arvalid => ARVALID,
            s00_axi_arready => ARREADY,
            s00_axi_rdata   => RDATA,
            s00_axi_rresp   => RRESP,
            s00_axi_rvalid  => RVALID,
            s00_axi_rready  => RREADY
        );

    ACLK <= not ACLK after CLK_PERIOD / 2;

    -- Moniteur : decodage de Sortie_DCC (fin de trame = tempo > 1 ms a '0')
    moniteur : process
        variable t_front : time;
        variable trame   : std_logic_vector(50 downto 0);
        variable n       : integer := 0;
    begin
        wait until ARESETN = '1';
        t_front := now;
        loop
            wait until rising_edge(Sortie_DCC);
            if now - t_front > 1 ms and n > 0 then
                Trame_Lue   <= trame;
                Nb_Bits_Lus <= n;
                Evt_Trame   <= not Evt_Trame;
                n := 0;
            end if;
            t_front := now;
            wait until falling_edge(Sortie_DCC);
            if n <= 50 then
                if now - t_front < 80 us then
                    trame(50 - n) := '1';
                else
                    trame(50 - n) := '0';
                end if;
            end if;
            n := n + 1;
            t_front := now;
        end loop;
    end process;

    stimulus : process

        -- Ecriture AXI4-Lite : adresse et donnee presentees ensemble,
        -- puis attente de la reponse d'ecriture (BVALID)
        procedure axi_write(addr : std_logic_vector(3 downto 0);
                            data : std_logic_vector(31 downto 0)) is
        begin
            wait until rising_edge(ACLK);
            AWADDR  <= addr;  AWVALID <= '1';
            WDATA   <= data;  WVALID  <= '1';
            BREADY  <= '1';
            wait until rising_edge(ACLK) and AWREADY = '1' and WREADY = '1';
            AWVALID <= '0';
            WVALID  <= '0';
            wait until rising_edge(ACLK) and BVALID = '1';
            BREADY  <= '0';
        end procedure;

        procedure ecrire_trame(t : std_logic_vector(50 downto 0)) is
        begin
            axi_write(OFFSET_REG0, t(31 downto 0));
            axi_write(OFFSET_REG1, "0000000000000" & t(50 downto 32));
        end procedure;

        procedure attendre_et_verifier(attendu : std_logic_vector(50 downto 0);
                                       nom     : string) is
        begin
            wait on Evt_Trame;
            wait on Evt_Trame;
            assert Nb_Bits_Lus = 51 and Trame_Lue = attendu
                report nom & " : ECHEC" severity error;
            if Nb_Bits_Lus = 51 and Trame_Lue = attendu then
                report nom & " : OK" severity note;
            end if;
        end procedure;

        constant T_ARRET  : std_logic_vector(50 downto 0) := trame_1_octet(ADRESSE, "01100000");
        constant T_AVANT  : std_logic_vector(50 downto 0) := trame_1_octet(ADRESSE, "01110110");
        constant T_PHARES : std_logic_vector(50 downto 0) := trame_1_octet(ADRESSE, "10010000");

    begin
        ARESETN <= '0';
        wait for 200 ns;
        ARESETN <= '1';

        -- 1) Trame d'arret par defaut apres reset
        attendre_et_verifier(T_ARRET, "1) Trame d'arret apres reset");

        -- 2) Ecriture sans validation : aucun effet
        ecrire_trame(T_AVANT);
        attendre_et_verifier(T_ARRET, "2) REG0/REG1 sans validation -> inchange");

        -- 3) Validation par front montant de REG2(0)
        axi_write(OFFSET_REG2, x"00000001");
        axi_write(OFFSET_REG2, x"00000000");
        attendre_et_verifier(T_AVANT, "3) Validation -> marche avant emise");

        -- 4) Flag laisse a '1' puis nouvelle trame : doit rester invisible
        axi_write(OFFSET_REG2, x"00000001");
        ecrire_trame(T_PHARES);
        attendre_et_verifier(T_AVANT, "4) Flag bloque a 1 + nouvelle trame -> inchange");

        -- 5) Nouveau front : la trame phares est enfin prise en compte
        axi_write(OFFSET_REG2, x"00000000");
        axi_write(OFFSET_REG2, x"00000001");
        attendre_et_verifier(T_PHARES, "5) Nouveau front -> phares ON emise");

        report "=== FIN TB_CENTRALE_DCC_AXI ===" severity note;
        std.env.finish;
    end process;

end Behavioral;
