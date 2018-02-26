library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library vjtag;

--============================================================================
--  Virtual JTAG Port Generation Block
--============================================================================
-- Generate a vuirt JTAG block to allow control and data to flow from
-- the FPGA under development.
-- Version: 0.0.0 Initial Commit - vjtag port - compiles -Shaun
------------------------------------------------------------------------------

entity vjtag_port is
Port (
    leds_out    : out std_logic_vector(7 downto 0) := X"00"
    );
end entity vjtag_port;

architecture rtl of vjtag_port is
    
		signal tdi_sig, tdo_sig, tck, sdr_valid, ir_solid, load_dr	:	std_logic;
		signal ir	: std_logic_vector(7 downto 0);
		signal dr	: std_logic_vector(31 downto 0) := X"87654321";

    begin
	 
-- The instantiation will create connect this block to the JTAG chain 
	virtual_jtag : entity vjtag.vjtag(rtl)
	port map(
		TDI 	=> tdi_sig,
		TDO 	=> tdo_sig,
		TCK	=> tck,
		IR_IN		=> ir,
		virtual_state_uir => ir_solid,
		virtual_state_sdr => sdr_valid,
		virtual_state_cdr => load_dr
	 );

	tdo_sig <= dr(0);
	dr_proc: process (tck, tdi_sig, tdo_sig, load_dr, sdr_valid) begin
		if (rising_edge(tck)) then
			if (load_dr = '1') then
				dr <= X"123456" & ir;
			elsif (sdr_valid = '1') then
				dr <= (tdi_sig & dr(31 downto 1));
			end if;
		end if;
	end process;

--==============================================
-- Stateless Signals
--==============================================
	 -- leds_out <= not dr(7 downto 0);

end architecture rtl;
