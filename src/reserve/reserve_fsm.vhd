library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reserve_fsm is
    generic (
        cn_width : integer := 5  -- разрядность таймера
    );
    port (
        in_clk     : in  std_logic;                              -- тактовый сигнал
        in_rst_n   : in  std_logic;                              -- сброс (активный 0)

        in_start   : in  std_logic;                              -- запуск дозаправки
        in_dv_time : in  std_logic_vector(cn_width-1 downto 0);  -- длительность дозаправки

        out_valve  : out std_logic                               -- открыть клапан
    );
end entity reserve_fsm;

architecture rtl of reserve_fsm is

    ----------------------------------------------------------------------
    -- Типы и сигналы состояний
    ----------------------------------------------------------------------
    type st_reserve_t is (st_idle, st_fill);

    signal rg_state    : st_reserve_t := st_idle;   -- текущее состояние
    signal ns_state    : st_reserve_t := st_idle;   -- следующее состояние

    ----------------------------------------------------------------------
    -- Управляющие сигналы
    ----------------------------------------------------------------------
    signal fl_valve    : std_logic := '0';          -- флаг открытия клапана
    signal fl_tm_start : std_logic := '0';          -- флаг запуска таймера
    signal fl_tm_done  : std_logic;                 -- флаг окончания таймера
    signal dv_tm_load  : std_logic_vector(cn_width-1 downto 0) := (others => '0'); -- загружаемое значение таймера

begin

    ----------------------------------------------------------------------
    -- Экземпляр таймера
    ----------------------------------------------------------------------
    u_timer : entity work.timer
        generic map (
            cn_width => cn_width
        )
        port map (
            in_clk     => in_clk,
            in_rst_n   => in_rst_n,
            in_start   => fl_tm_start,
            in_loadval => dv_tm_load,
            out_done   => fl_tm_done
        );

    ----------------------------------------------------------------------
    -- 1. Регистр состояний
    ----------------------------------------------------------------------
    pr_state_reg : process(in_clk, in_rst_n)
    begin
        if in_rst_n = '0' then
            rg_state <= st_idle;
        elsif rising_edge(in_clk) then
            rg_state <= ns_state;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- 2. Логика переходов
    ----------------------------------------------------------------------
    pr_next_state : process(rg_state, in_start, fl_tm_done)
    begin
        ns_state <= rg_state;

        case rg_state is
            when st_idle =>
                if in_start = '1' then
                    ns_state <= st_fill;
                end if;

            when st_fill =>
                if fl_tm_done = '1' then
                    ns_state <= st_idle;
                end if;
        end case;
    end process;

    ----------------------------------------------------------------------
    -- 3. Действия
    ----------------------------------------------------------------------
    pr_outputs : process(in_clk, in_rst_n)
    begin
        if in_rst_n = '0' then
            fl_valve    <= '0';
            fl_tm_start <= '0';
            dv_tm_load  <= (others => '0');
        elsif rising_edge(in_clk) then
            fl_tm_start <= '0';

            case rg_state is
                when st_idle =>
                    if in_start = '1' then
                        fl_valve    <= '1';
                        fl_tm_start <= '1';
                        dv_tm_load  <= in_dv_time;
                    else
                        fl_valve <= '0';
                    end if;

                when st_fill =>
                    if fl_tm_done = '1' then
                        fl_valve <= '0';
                    end if;
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Привязка выхода
    ----------------------------------------------------------------------
    out_valve <= fl_valve;

end architecture rtl;