-- Created by IP Generator (Version 2022.2-SP1-Lite build 132640)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT MUL17x17
  PORT (
    a : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    ce : IN STD_LOGIC;
    p : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : MUL17x17
  PORT MAP (
    a => a,
    b => b,
    clk => clk,
    rst => rst,
    ce => ce,
    p => p
  );
