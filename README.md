# Soda Machine (USSR)

Краткое поведение автомата:

- Состояние ожидания **IDLE**: ждём монету `coin1` (1 коп.) или `coin3` (3 коп., **приоритет**).
- Если пришла **3 коп.** → льём **сироп** → затем **воду** → включаем **газ**.
- Если пришла **1 коп.** → пропускаем сироп, льём **воду** → включаем **газ**.
- Когда газирование завершено, автомат возвращается в **IDLE** и **параллельно** запускает
  **резервную** заливку воды для следующего стакана (не блокируя ожидание следующей монеты).

---

## Диаграммы

**State diagram**

![FSM](docs/img/SM_rg_state.jpg)

**RTL (Quartus RTL Viewer)**

![RTL](docs/img/SM_RTL.jpg)


<p align="center">
  <img src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbm8xb3BoczBzdGR1bzFpOTBzaDQ2cndkamR6eXc5cXc1czh3YW5wNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/82nxC1u2BC8VU1wiZq/giphy.gif" alt="fizzy soda" width="420">
</p>
