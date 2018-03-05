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
-- Version: 0.0.1 More general interfaces -Shaun
------------------------------------------------------------------------------

entity vjtag_port is
Port (
    ir_out	: out std_logic_vector(7 downto 0) := X"00";
    dr_out	: out std_logic_vector(31 downto 0) := X"00000000"
    );
end entity vjtag_port;

architecture rtl of vjtag_port is
    
		signal tdi_sig, tdo_sig, tck, sdr_valid, ir_solid, load_dr	:	std_logic;
		signal ir, ir_sig	: std_logic_vector(7 downto 0);
		signal dr	: std_logic_vector(31 downto 0) := X"87654321";

    begin
	 
-- The instantiation will create connect this block to the JTAG chain
	virtual_jtag : entity vjtag.vjtag(rtl)
	port map(
		TDI 	=> tdi_sig,
		TDO 	=> tdo_sig,
		TCK		=> tck,
		IR_IN	=> ir_sig,
		virtual_state_uir => ir_solid,
		virtual_state_sdr => sdr_valid,
		virtual_state_cdr => load_dr
	 );

	-- Virtual JTAG
	tdo_sig <= dr(0);

	-- IR latch process
	ir_proc: process (tck, ir_solid) begin
		if (rising_edge(tck)) then
			if (ir_solid = '1') then
				ir <= ir_sig;
			end if;
		end if;
	end process;

	-- Virtual JTAG FPGA -> CPU Data
	data_out_proc: process (tck, tdi_sig, load_dr, sdr_valid) begin
		if (rising_edge(tck)) then
			if (load_dr = '1') then
				if(ir = X"00") then
					dr <= X"12345678";
				elsif(ir = X"01") then
					dr <= X"87654321";
				elsif(ir = X"02") then
					dr <= X"c0ffee" & ir;
				else
					dr <= X"00000000";
				end if;
			elsif (sdr_valid = '1') then
				dr <= (tdi_sig & dr(31 downto 1));
			end if;
		end if;
	end process;
	
	-- Virtual JTAG CPU -> FPGA Data
	data_in_proc: process (data_ready) begin
		if (data_ready = '1') then
			if(ir = X"01") then
				dr_out <= dr;
			else
				dr_out <= X"00000055";
			end if;
		end if;
	end process;

--==============================================
-- Stateless Signals
--==============================================
	dr_out <= ir(7 downto 0);
	ir_out <= dr(31 downto 0);

end architecture rtl;
