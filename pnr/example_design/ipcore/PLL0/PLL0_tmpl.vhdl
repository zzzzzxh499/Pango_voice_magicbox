-- Created by IP Generator (Version 2022.2-SP1-Lite build 132640)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT PLL0
  PORT (
    clkin1 : IN STD_LOGIC;
    pll_lock : OUT STD_LOGIC;
    clkout0 : OUT STD_LOGIC;
    clkout1 : OUT STD_LOGIC;
    clkout2 : OUT STD_LOGIC
  );
END COMPONENT;


the_instance_name : PLL0
  PORT MAP (
    clkin1 => clkin1,
    pll_lock => pll_lock,
    clkout0 => clkout0,
    clkout1 => clkout1,
    clkout2 => clkout2
  );
