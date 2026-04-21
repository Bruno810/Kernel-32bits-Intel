 #include "task_lib.h"

#define WIDTH TASK_VIEWPORT_WIDTH
#define HEIGHT TASK_VIEWPORT_HEIGHT

#define SHARED_SCORE_BASE_VADDR (PAGE_ON_DEMAND_BASE_VADDR + 0xF00)
#define CANT_PONGS 3


void task(void) {
    screen pantalla;
    // ¿Una tarea debe terminar en nuestro sistema?
    while (true){
    // Completar:
    // - Pueden definir funciones auxiliares para imprimir en pantalla
    // - Pueden usar `task_print`, `task_print_dec`, etc.
        task_print(pantalla, "Task 1", WIDTH / 2 - 3, 4, C_FG_WHITE);
        task_print(pantalla, "Task 2", WIDTH / 2 - 3, 7, C_FG_WHITE);
        task_print(pantalla, "Task 3", WIDTH / 2 - 3, 10, C_FG_WHITE);
    
        for (int8_t pong_idx = 0; pong_idx < CANT_PONGS; pong_idx++){
            uint32_t* current_task_record = (uint32_t*) (SHARED_SCORE_BASE_VADDR + ((uint32_t) pong_idx * sizeof(uint32_t)*2));
            task_print_dec(pantalla, current_task_record[0], 2, WIDTH / 2 - 3, 5+3*pong_idx, C_FG_CYAN);
            task_print_dec(pantalla, current_task_record[1], 2, WIDTH / 2 + 1, 5+3*pong_idx, C_FG_MAGENTA);
        }

        syscall_draw(pantalla);
    }
}