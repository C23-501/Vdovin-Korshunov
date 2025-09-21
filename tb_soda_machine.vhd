library ieee;
use ieee.std_logic_1164.all;

entity tb_soda_machine is
end entity;

architecture sim of tb_soda_machine is
	-- такт
	constant TCK : time := 10 ns;

	-- провода между DUT и тестером
	signal clk : std_logic := '0';
	signal rst_n : std_logic := '0';
	signal coin1 : std_logic := '0';
	signal coin3 : std_logic := '0';

	signal syrup_valve : std_logic;
	signal water_valve : std_logic;
	signal gas_valve : std_logic;
	signal reserve_water_valve : std_logic;
begin
	-- генератор такта
	clk <= not clk after TCK/2;

	-- DUT
	dut: entity work.soda_machine
		port map (
			clk   => clk,
			rst_n => rst_n,
			coin1 => coin1,
			coin3 => coin3,
			syrup_valve => syrup_valve,
			water_valve => water_valve,
			gas_valve => gas_valve,
			reserve_water_valve => reserve_water_valve
		);

	-- TESTER
	u_tester: entity work.tester_soda_machine
		generic map(
			-- ожидания: должны совпадать с T_SYRUP/T_WATER/T_GAS/T_RES внутри DUT
			EXP_T_SYRUP => 10,
			EXP_T_WATER => 20,
			EXP_T_GAS   => 15,
			EXP_T_RES   => 25
		)
		port map(
			clk   => clk,
			rst_n => rst_n,
			coin1 => coin1,
			coin3 => coin3,

			syrup_valve         => syrup_valve,
			water_valve         => water_valve,
			gas_valve           => gas_valve,
			reserve_water_valve => reserve_water_valve
		 );
end architecture;
