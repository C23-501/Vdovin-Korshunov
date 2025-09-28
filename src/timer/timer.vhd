library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    generic (
        cn_width : integer := 5  -- разрядность таймера (число бит в счетчике)
    );
    port (
        in_clk     : in  std_logic;                              -- тактовый сигнал
        in_rst_n   : in  std_logic;                              -- сброс (активный 0)
        in_start   : in  std_logic;                              -- запуск таймера
        in_loadval : in  std_logic_vector(cn_width-1 downto 0);  -- загружаемое значение
        out_done   : out std_logic                               -- флаг окончания
    );
end entity timer;

architecture fsm of timer is

    ----------------------------------------------------------------------
    -- Типы и внутренние сигналы
    ----------------------------------------------------------------------
    type st_timer_t is (st_idle, st_run);                           
    signal rg_state, rg_next_state : st_timer_t := st_idle;        

    signal rg_count : std_logic_vector(cn_width-1 downto 0) := (others => '0');

    signal fl_done : std_logic := '0';

begin

    ----------------------------------------------------------------------
    -- Процесс: регистр состояний
    ----------------------------------------------------------------------
    pr_state_reg : process(in_clk, in_rst_n)
    begin
        if in_rst_n = '0' then
            rg_state <= st_idle;
        elsif rising_edge(in_clk) then
            rg_state <= rg_next_state;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Процесс: логика переходов
    ----------------------------------------------------------------------
    pr_next_state : process(rg_state, in_start, rg_count)
    begin
        rg_next_state <= rg_state;

        case rg_state is
            when st_idle =>
                if in_start = '1' then
                    rg_next_state <= st_run;
                end if;

            when st_run =>
                if unsigned(rg_count) = 0 then
                    rg_next_state <= st_idle;
                end if;
        end case;
    end process;

    ----------------------------------------------------------------------
    -- Процесс: действия
    ----------------------------------------------------------------------
    pr_outputs : process(in_clk, in_rst_n)
    begin
        if in_rst_n = '0' then
            rg_count <= (others => '0');
            fl_done  <= '0';
        elsif rising_edge(in_clk) then
            fl_done <= '0'; -- по умолчанию

            case rg_state is
                when st_idle =>
                    if in_start = '1' then
                        rg_count <= std_logic_vector(unsigned(in_loadval) - 1);
                    end if;

                when st_run =>
                    if unsigned(rg_count) = 0 then
                        fl_done <= '1';
                    else
                        rg_count <= std_logic_vector(unsigned(rg_count) - 1);
                    end if;
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Привязка выхода
    ----------------------------------------------------------------------
    out_done <= fl_done;

end architecture fsm;
