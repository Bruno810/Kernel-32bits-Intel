; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - Arquitectura y Organizacion de Computadoras - FCEN
; ==============================================================================

%include "print.mac"

global start


extern A20_enable
extern GDT_DESC
extern screen_draw_layout
extern idt_init
extern IDT_DESC
extern pic_reset
extern pic_enable
extern mmu_init_kernel_dir
extern mmu_init_task_dir
extern tss_init
extern sched_init
extern tasks_init
extern tasks_screen_draw


%define CS_RING_0_SEL   1 << 3
%define DS_RING_0_SEL   3 << 3   


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

DIVISOR EQU 3000

%define GDT_TASK_INITIAL        11 << 3
%define GDT_TASK_IDLE           12 << 3

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; ==============================
    ; ||  Salto a modo protegido  ||
    ; ==============================

    ; Deshabilitamos interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; Imprime mensaje de bienvenida - MODO REAL (Parte 1: Pasaje a modo protegido)
    print_text_rm start_rm_msg, start_rm_len, 0x2, 0, 0

    ; Habilita A20 (Parte 1: Pasaje a modo protegido)
    call A20_enable

    ; Carga la GDT (Parte 1: Pasaje a modo protegido)
    LGDT [GDT_DESC]

    ; Setea el bit PE del registro CR0 (Parte 1: Pasaje a modo protegido)
    mov eax, CR0
    or eax, 1
    mov CR0, eax

    ; Salta a modo protegido (far jump) (Parte 1: Pasaje a modo protegido)
    jmp CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; (Parte 1: Pasaje a modo protegido) - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    mov ax, DS_RING_0_SEL
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax

    ; Establecer el tope y la base de la pila (Parte 1: Pasaje a modo protegido)
    mov ebp, 0x25000
    mov esp, 0x25000 

    ; Imprimir mensaje de bienvenida - MODO PROTEGIDO (Parte 1: Pasaje a modo protegido)
    print_text_pm start_pm_msg, start_pm_len, 0x2, 0, 0

    ; Inicializa pantalla (Parte 1: Pasaje a modo protegido)
    call screen_draw_layout


    ; ===================================
    ; ||     (Parte 3: Paginación)     ||
    ; ===================================

    ; Inicializa el directorio de paginas
    call mmu_init_kernel_dir
    ; Carga directorio de paginas 
    mov cr3, eax
    ; Habilita paginacion 
    mov eax, cr0
    or eax, 1<<31
    mov cr0, eax

    ; ========================
    ; ||  (Parte 4: Tareas) ||
    ; ========================

    ; Inicializa tss
    call tss_init

    ; Inicializa el scheduler
    call sched_init

    ; Inicializa las tareas
    call tasks_init


    ; ===================================
    ; ||   (Parte 2: Interrupciones)   ||
    ; ===================================

    ; Inicializa y carga la IDT
    call idt_init
    LIDT [IDT_DESC]

    ; Reinicia y habilita el controlador de interrupciones
    call pic_reset
    call pic_enable


    ; (Parte 4: Tareas)- Carga tarea inicial
    call tasks_screen_draw
    mov ax, GDT_TASK_INITIAL
    LTR ax
    

    sti
    
    ; El PIT (Programmable Interrupt Timer) corre a 1193182Hz.

    ; Cada iteracion del clock decrementa un contador interno, cuando éste llega
    ; a cero se emite la interrupción. El valor inicial es 0x0 que indica 65536,
    ; es decir 18.206 Hz

    mov ax, DIVISOR
    out 0x40, al
    rol ax, 8
    out 0x40, al

    ; ========================
    ; ||  (Parte 4: Tareas)  ||
    ; ========================

    ; Salta a la primera tarea: Idle
    jmp GDT_TASK_IDLE:0

    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
