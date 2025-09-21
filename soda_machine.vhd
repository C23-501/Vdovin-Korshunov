library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soda_machine is
	port (
		clk : in std_logic; -- вход: таковый сигнал
		rst_n : in std_logic; -- вход: сброс (активный 0)
		coin1: in std_logic; -- вход: сигнал "вставлена номинал 1 копейка"
		coin3: in std_logic; -- вход: сигнал "вставлены номинал 3 копейки" - здесь приоритет!
		
		syrup_valve : out std_logic; -- выход: открыть клапан сиропа
		water_valve : out std_logic; -- выход : открыть клапан воды
		gas_valve : out std_logic; -- выход: включить газ
		reserve_water_valve : out std_logic -- выход: наливать резервный стакан
	);
end entity soda_machine;

architecture rtl of soda_machine is
	-- Объявление типа состояний автомата
	type state_t is (IDLE, -- ождиание монеты
						  SYRUP, -- наливаем сироп
						  WATER, -- наливаем воду
						  GAS); -- подаём газ
	signal state : state_t := IDLE;
	
	-- Объявление таймера клапана
	signal timer : integer := 0;
	
	-- Объявление константных длительностей в тактах clk
	constant T_SYRUP : integer := 10; -- сироп
	constant T_WATER : integer := 20; -- вода
	constant T_GAS : integer := 15; -- газ
	constant T_RES : integer := 25; -- резервная вода
	
	signal kick_reserve : std_logic := '0'; -- флаг-импульс для того, чтобы фоновый автомат залили резеврную копию воды в стакан
	
	-- Фоновый автомат
	signal r_fill : std_logic := '0'; -- сигнал льем ли мы воду дополнительно сейчас
	signal r_timer: integer := 0; -- таймер длительности доп. воды
	
begin
	--  Связь выходов-клапанов от состояний
	syrup_valve <= '1' when state = SYRUP else '0';
	water_valve <= '1' when state = WATER else '0';
	gas_valve <= '1' when state = GAS else '0';
	reserve_water_valve <= r_fill;
	
	-- ГЛАВНЫЙ АВТОМАТ
	process (clk, rst_n)
	begin
		if rst_n = '0' then
			--СБРОС
			state <= IDLE;
			timer <= 0;
			kick_reserve <= '0';
		elsif rising_edge(clk) then
			kick_reserve <= '0'; -- сброс импульса долива воды в резервный стакан
			
			case state is
				when IDLE =>
					if coin3 ='1' then -- вход 3 копейки активен
						state <= SYRUP;
						timer <= T_SYRUP - 1;
					elsif coin1 = '1' then -- вход 1 копейка активен
						state <= WATER;
						timer <= T_WATER - 1;
					end if;
						
				when SYRUP =>
					if timer = 0 then
						state <= WATER;
						timer <= T_WATER - 1;
					else
						timer <= timer -1;
					end if;
						
				when WATER =>
					if timer = 0 then
						state <= GAS;
						timer <= T_GAS - 1;
					else
						timer <= timer -1;
					end if;
			
				when GAS =>
					if timer = 0 then
						state <= IDLE;
						kick_reserve <= '1'; -- сообщение фоновому автомату начать заполнять резерв
					else
						timer <= timer - 1;
					end if;
			end case;
		end if;
	end process;
	
	-- Фоновая заливка резервной воды
	process (clk, rst_n)
	begin
		if rst_n = '0' then
			r_fill  <= '0';
			r_timer <= 0;
		elsif rising_edge(clk) then
			if r_fill = '0' then
				-- ждём импульс от главного автомата (после газирования)
				if kick_reserve = '1' then
					r_fill  <= '1';
					r_timer <= T_RES - 1;
				end if;
			else
				-- льём резервную воду
				if r_timer = 0 then
					r_fill <= '0';
				else
					r_timer <= r_timer - 1;
				end if;
			end if;
		end if;
	end process;
		
end architecture rtl;