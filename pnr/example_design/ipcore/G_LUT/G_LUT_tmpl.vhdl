-- Created by IP Generator (Version 2022.2-SP1-Lite build 132640)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT G_LUT
  PORT (
    addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    rd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : G_LUT
  PORT MAP (
    addr => addr,
    clk => clk,
    rst => rst,
    rd_data => rd_data
  );
