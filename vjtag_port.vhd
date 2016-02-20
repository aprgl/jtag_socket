library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library vjtag;

--============================================================================
--  Virtual JTAG Port Generation Block
--============================================================================
-- Generate a vuirt JTAG block to allow control and data to flow from
-- the FPGA under development.
-- Version: 0.0.0 Initial Commit - half dead time block - compiles -Shaun
------------------------------------------------------------------------------

entity vjtag_port is
Port (
    --rst_n_in        : in    std_logic;
    --clk_in          : in    std_logic;
    --ena_in          : in    std_logic;
    --high_side_in    : in    std_logic;
    --low_side_in     : in    std_logic;
    --dead_time_in    : in    std_logic_vector(7 downto 0);
    --high_side_out   : out   std_logic;
    leds_out    : out   std_logic_vector(7 downto 0)
    );
end entity vjtag_port;

architecture rtl of vjtag_port is
    
		signal tdi_sig, tdo_sig, tck, ir_solid, sdr_valid	:	std_logic;
		signal ir	: std_logic_vector(7 downto 0);
		signal dr	:	std_logic_vector(31 downto 0) := X"87654321";
		
    begin

	virtual_jtag : entity vjtag.vjtag(rtl)
	port map(
		TDI 	=> tdi_sig,
		TDO 	=> tdo_sig,
		TCK	=> tck,
		IR_IN		=> ir,
		virtual_state_uir => ir_solid,
		virtual_state_sdr => sdr_valid
	 );

	 tdo_sig <= dr(0);
	 
	 dr_proc: process (tck, tdi_sig, tdo_sig) begin
		if (rising_edge(tck) and sdr_valid = '1') then
			dr <= (tdi_sig & dr(31 downto 1));
		end if;
	 end process;
	 
	 leds_out <= not dr(7 downto 0);
	 
--	 ir_lock_proc: process (tck, ir, ir_solid) begin
--		if (rising_edge(tck) and ir_solid = '1') then
--			leds_out <= ir;
--		end if;
--	end process;

end architecture rtl;
