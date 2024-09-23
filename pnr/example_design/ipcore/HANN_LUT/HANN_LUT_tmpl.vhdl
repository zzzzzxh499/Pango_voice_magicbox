-- Created by IP Generator (Version 2022.2-SP1-Lite build 132640)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT HANN_LUT
  PORT (
    wr_data : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    rd_data : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : HANN_LUT
  PORT MAP (
    wr_data => wr_data,
    addr => addr,
    wr_en => wr_en,
    clk => clk,
    rst => rst,
    rd_data => rd_data
  );
