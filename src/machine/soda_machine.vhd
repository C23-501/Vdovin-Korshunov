library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soda_machine is
    generic (
        cn_width : integer := 5  -- разрядность таймера
    );
    port (
        clk   : in std_logic;   -- тактовый сигнал
        rst_n : in std_logic;   -- сброс (активный низ)
        in_m1 : in std_logic;   -- монета 1 копейка
        in_m3 : in std_logic;   -- монета 3 копейки (приоритет)

        out_valve_syrup         : out std_logic; -- клапан сиропа
        out_valve_water         : out std_logic; -- клапан воды
        out_valve_gas           : out std_logic; -- клапан газа
        out_valve_reserve_water : out std_logic; -- клапан резервной воды
        out_valve_reserve_syrup : out std_logic  -- клапан резервного сиропа
    );
end entity soda_machine;

architecture rtl of soda_machine is

    ----------------------------------------------------------------------
    -- Типы состояний
    ----------------------------------------------------------------------
    type st_main_t is (st_idle, st_syrup, st_water, st_gas);
    signal rg_state, ns_state : st_main_t := st_idle;

    ----------------------------------------------------------------------
    -- Таймер
    ----------------------------------------------------------------------
    signal fl_tm_start   : std_logic := '0';
    signal fl_tm_done    : std_logic := '0';
    signal dv_tm_loadval : std_logic_vector(cn_width-1 downto 0) := (others => '0');

    ----------------------------------------------------------------------
    -- Резервные автоматы
    ----------------------------------------------------------------------
    signal fl_kick_reserve_water : std_logic := '0';
    signal fl_kick_reserve_syrup : std_logic := '0';

    ----------------------------------------------------------------------
    -- Константы длительностей (std_logic_vector)
    ----------------------------------------------------------------------
    constant dv_t_syrup : std_logic_vector(cn_width-1 downto 0) := std_logic_vector(to_unsigned(10, cn_width));
    constant dv_t_water : std_logic_vector(cn_width-1 downto 0) := std_logic_vector(to_unsigned(20, cn_width));
    constant dv_t_gas   : std_logic_vector(cn_width-1 downto 0) := std_logic_vector(to_unsigned(15, cn_width));
    constant dv_t_res   : std_logic_vector(cn_width-1 downto 0) := std_logic_vector(to_unsigned(25, cn_width));

begin

    ----------------------------------------------------------------------
    -- Экземпляр таймера
    ----------------------------------------------------------------------
    u_timer : entity work.timer
        generic map (
            cn_width => cn_width
        )
        port map (
            in_clk     => clk,
            in_rst_n   => rst_n,
            in_start   => fl_tm_start,
            in_loadval => dv_tm_loadval,
            out_done   => fl_tm_done
        );

    ----------------------------------------------------------------------
    -- Экземпляр блока резервной дозаправки
    ----------------------------------------------------------------------
    u_reserve : entity work.reserve_unit
        generic map (
            cn_width => cn_width
        )
        port map (
            in_clk            => clk,
            in_rst_n          => rst_n,
            in_start_water    => fl_kick_reserve_water,
            in_start_syrup    => fl_kick_reserve_syrup,
            in_dv_time_water  => dv_t_res,
            in_dv_time_syrup  => dv_t_res,
            out_valve_water   => out_valve_reserve_water,
            out_valve_syrup   => out_valve_reserve_syrup
        );

    ----------------------------------------------------------------------
    -- 1. Регистр состояния
    ----------------------------------------------------------------------
    pr_state_reg : process(clk, rst_n)
    begin
        if rst_n = '0' then
            rg_state <= st_idle;
        elsif rising_edge(clk) then
            rg_state <= ns_state;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 2. Логика переходов
    ----------------------------------------------------------------------
    pr_next_state : process(rg_state, in_m1, in_m3, fl_tm_done)
    begin
        ns_state <= rg_state;

        case rg_state is
            when st_idle =>
                if in_m3 = '1' then
                    ns_state <= st_syrup;
                elsif in_m1 = '1' then
                    ns_state <= st_water;
                end if;

            when st_syrup =>
                if fl_tm_done = '1' then
                    ns_state <= st_water;
                end if;

            when st_water =>
                if fl_tm_done = '1' then
                    ns_state <= st_gas;
                end if;

            when st_gas =>
                if fl_tm_done = '1' then
                    ns_state <= st_idle;
                end if;
        end case;
    end process;

    ----------------------------------------------------------------------
    -- 3. Действия (таймер + резервы + клапаны)
    ----------------------------------------------------------------------
    pr_outputs : process(rg_state, in_m1, in_m3, fl_tm_done)
    begin
        -- значения по умолчанию
        fl_tm_start           <= '0';
        dv_tm_loadval         <= (others => '0');
        fl_kick_reserve_water <= '0';
        fl_kick_reserve_syrup <= '0';

        out_valve_syrup <= '0';
        out_valve_water <= '0';
        out_valve_gas   <= '0';

        case rg_state is
            when st_idle =>
                if in_m3 = '1' then
                    fl_tm_start   <= '1';
                    dv_tm_loadval <= dv_t_syrup;
                elsif in_m1 = '1' then
                    fl_tm_start   <= '1';
                    dv_tm_loadval <= dv_t_water;
                end if;

            when st_syrup =>
                out_valve_syrup <= '1';
                if fl_tm_done = '1' then
                    fl_tm_start   <= '1';
                    dv_tm_loadval <= dv_t_water;
                end if;

            when st_water =>
                out_valve_water <= '1';
                if fl_tm_done = '1' then
                    fl_tm_start   <= '1';
                    dv_tm_loadval <= dv_t_gas;
                end if;

            when st_gas =>
                out_valve_gas <= '1';
                if fl_tm_done = '1' then
                    fl_kick_reserve_water <= '1';
                    if in_m3 = '1' then
                        fl_kick_reserve_syrup <= '1';
                    end if;
                end if;
        end case;
    end process;

end architecture rtl;