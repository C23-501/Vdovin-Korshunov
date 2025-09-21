library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tester_soda_machine is
	generic (
		EXP_T_SYRUP : integer := 10;
		EXP_T_WATER : integer := 20;
		EXP_T_GAS   : integer := 15;
		EXP_T_RES   : integer := 25
	);
	port (
		clk : in  std_logic;

		-- тестер ДОЛЖЕН управлять этими сигналами
		rst_n : out std_logic;
		coin1 : out std_logic;
		coin3 : out std_logic;

		-- тестер читает выходы DUT
		syrup_valve : in  std_logic;
		water_valve : in  std_logic;
		gas_valve : in  std_logic;
		reserve_water_valve : in  std_logic
	);
end entity;

architecture behav of tester_soda_machine is
	-- вспомогательная процедура: дождаться фронта clk
	procedure wait_clk is
	begin
		wait until rising_edge(clk);
	end procedure;

	-- дождаться, пока сигнал станет '1'
	procedure wait_high(signal s : std_logic) is
	begin
		while s = '0' loop
			wait_clk;
		end loop;
	end procedure;

	-- проверить, что сигнал держится '1' ровно N тактов
	procedure check_high_for(signal s : std_logic; N : natural; name : string) is
		variable cnt : natural := 0;
	begin
		-- ждём включение
		wait_high(s);
		-- считаем количество тактов, пока '1'
		while s = '1' loop
			cnt := cnt + 1;
			wait_clk;
		end loop;
		assert cnt = N report
			name & " duration mismatch: got " & integer'image(cnt) & ", expected " & integer'image(N)
			severity error;
	end procedure;

	-- подать монеты одной тактовой длительности
	procedure pulse(signal s : out std_logic) is
	begin
		s <= '1';
		wait_clk;
		s <= '0';
	end procedure;

begin
	main: process
	begin
		-- Инициализация
		rst_n <= '0';
		coin1 <= '0';
		coin3 <= '0';
		wait_clk; wait_clk; wait_clk;  -- несколько тактов
		rst_n <= '1';
		wait_clk; wait_clk;

		-- TC1: 3 копейки
		pulse(coin3);

		check_high_for(syrup_valve, EXP_T_SYRUP, "TC1.syrup");
		check_high_for(water_valve, EXP_T_WATER, "TC1.water");
		check_high_for(gas_valve,   EXP_T_GAS,   "TC1.gas");

		-- резервная заливка должна включиться после газирования
		check_high_for(reserve_water_valve, EXP_T_RES, "TC1.reserve");

		report "ALL TESTS PASSED" severity note;
		assert false report "SIM DONE" severity failure;
	end process;
end architecture;
