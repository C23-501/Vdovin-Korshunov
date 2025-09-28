library ieee;
use ieee.std_logic_1164.all;

entity reserve_unit is
    generic (
        cn_width : integer := 5  -- разрядность таймера
    );
    port (
        in_clk     : in  std_logic;  -- тактовый сигнал
        in_rst_n   : in  std_logic;  -- сброс (активный 0)

        -- сигналы запуска дозаправки
        in_start_water : in std_logic;
        in_start_syrup : in std_logic;

        -- длительности дозаправки
        in_dv_time_water : in std_logic_vector(cn_width-1 downto 0);
        in_dv_time_syrup : in std_logic_vector(cn_width-1 downto 0);

        -- клапаны
        out_valve_water : out std_logic;
        out_valve_syrup : out std_logic
    );
end entity reserve_unit;

architecture rtl of reserve_unit is
begin

    ----------------------------------------------------------------------
    -- Экземпляр автомата резервной дозаправки (вода)
    ----------------------------------------------------------------------
    u_reserve_water : entity work.reserve_fsm
        generic map (
            cn_width => cn_width
        )
        port map (
            in_clk     => in_clk,
            in_rst_n   => in_rst_n,
            in_start   => in_start_water,
            in_dv_time => in_dv_time_water,
            out_valve  => out_valve_water
        );

    ----------------------------------------------------------------------
    -- Экземпляр автомата резервной дозаправки (сироп)
    ----------------------------------------------------------------------
    u_reserve_syrup : entity work.reserve_fsm
        generic map (
            cn_width => cn_width
        )
        port map (
            in_clk     => in_clk,
            in_rst_n   => in_rst_n,
            in_start   => in_start_syrup,
            in_dv_time => in_dv_time_syrup,
            out_valve  => out_valve_syrup
        );

end architecture rtl;