; kiini.s -- boot stub ya mkono ya Kawira (kioo cha jukumu la
; msingi/mbegu.s kwenye lugha-swa/swa: KIINI CHA UAMINIFU, kila
; mstari una sababu iliyoandikwa hapa, si tu kinachofanyika).
;
; Kazi: kuanzia Multiboot1 (32-bit protected mode, PE=1 PG=0),
; kuweka jedwali dogo la paging (identity-map MB 2 za kwanza kwa
; ukurasa mkubwa mmoja), kuwezesha long mode (PAE+LME+PG), kuruka
; kwenda 64-bit code segment kupitia GDT ndogo, kuweka IDT+PIC (Sehemu
; 3 -- angalia chini), kisha kuita kernel_main() (Swa HALISI,
; iliyozalishwa na "stage1 --kernel", Sehemu 2). Baada ya kernel_main
; kurudi, kibodi (IRQ1) inawezeshwa (sti) na CPU inangoja matukio
; kwenye kitanzi cha "hlt" (Sehemu 3, kwa maelezo kamili angalia chini
; ya faili hii, karibu na isr_kbd_trampoline).
;
; Fomati: BINARY GHAFI (si ELF) -- Multiboot "a.out kludge" (bit 16
; ya flags) inaeleza bootloader/QEMU wapi pa kupakia na wapi pa
; kuruka MOJA KWA MOJA kwenye maandishi ya header, hivyo HAKUNA
; linker (ld) wala ELF program headers zinazohitajika kabisa kwa
; hatua hii -- uamuzi wa makusudi kurahisisha (kioo cha jinsi
; mbegu.bin inavyozalishwa moja kwa moja bila ld).

[BITS 32]
[ORG 0x100000]                  ; anwani ya kudumu, salama (1MB) --
                                 ; juu ya eneo la chini lililohifadhiwa
                                 ; (real-mode IVT, BIOS data, n.k.)

MB_MAGIC     equ 0x1BADB002
MB_FLAGS     equ 0x00010000     ; bit 16 = a.out kludge (header ina
                                 ; anwani za kupakia/kuruka moja kwa
                                 ; moja -- hakuna ELF inayohitajika)
MB_CHECKSUM  equ -(MB_MAGIC + MB_FLAGS)

mb_header:
    dd MB_MAGIC
    dd MB_FLAGS
    dd MB_CHECKSUM
    dd mb_header                ; header_addr: anwani ya header hii
    dd mb_header                ; load_addr: mwanzo wa faili = mwanzo
                                 ; wa picha ya kupakiwa
    dd 0                        ; load_end_addr: 0 = pakia faili
                                 ; LOTE (hakuna .bss tofauti nje ya
                                 ; faili -- rafu/majedwali ya paging
                                 ; yametengwa NDANI ya faili kupitia
                                 ; "resb"/"times" hapa chini)
    dd 0                        ; bss_end_addr: 0 = hakuna bss ya
                                 ; ziada ya kusafisha
    dd _start32                  ; entry_addr: hapa ndipo bootloader
                                 ; inaruka baada ya kupakia

_start32:
    cli                          ; zima interrupts -- IDT haijawekwa
                                 ; bado, interrupt yoyote ingeanguka
    mov esp, stack_top32         ; rafu ya 32-bit ya muda (Multiboot
                                 ; haiahidi ESP yoyote maalum)

    mov [mb_magic_saved], eax    ; hifadhi eax (0x2BADB002 ikiwa
                                 ; sahihi) na ebx (anwani ya taarifa
                                 ; za Multiboot) -- HAZITUMIKI bado
    mov [mb_info_saved], ebx     ; kwenye Awamu hii, lakini
                                 ; zimehifadhiwa kwa Awamu 2+

    cmp eax, 0x2BADB002          ; thibitisha huu ni Multiboot HALISI
    je .magic_sahihi             ; -- kama si sahihi, SIMAMA kwa
    jmp .kosa_magic               ; wazi (usiendelee kimya na hali
                                 ; isiyojulikana)
.magic_sahihi:

    ; ---- Jedwali la paging: identity-map MB 2 za kwanza pekee,
    ; kwa ukurasa MKUBWA mmoja (2MB huge page, bit 7 ya PD entry) --
    ; inatosha kabisa kwa kernel ndogo ya Awamu hii (msimbo + data +
    ; rafu zote ziko chini ya MB 2), rahisisha kwa makusudi (hakuna
    ; jedwali la PT tofauti linalohitajika bado). ----

    mov eax, pdpt
    or eax, 0x03                 ; present(bit0) + writable(bit1)
    mov [pml4], eax
    mov dword [pml4 + 4], 0      ; nusu ya juu ya entry (biti 63-32) = 0

    mov eax, pd
    or eax, 0x03
    mov [pdpt], eax
    mov dword [pdpt + 4], 0

    mov eax, 0x83                 ; present+writable+huge(bit7) --
    mov [pd], eax                 ; anwani ya kimwili ya ukurasa ni 0
    mov dword [pd + 4], 0         ; (identity: anwani ya kimwili 0
                                   ; inayolingana na anwani ya
                                   ; kimantiki 0, biti za juu za 2MB
                                   ; huge-page zote sifuri kwa ukurasa
                                   ; wa kwanza)

    ; ---- Wezesha PAE (Physical Address Extension), CR4 bit 5 --
    ; LAZIMA kabla ya kuweka EFER.LME (SDM inaamuru mpangilio huu). ----
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov eax, pml4                ; CR3 = anwani ya kimwili ya PML4
    mov cr3, eax

    ; ---- Wezesha long mode: EFER.LME (MSR 0xC0000080, bit 8) --
    ; hii haiwezeshi long mode YENYEWE bado (inahitaji PG=1 pia,
    ; hatua inayofuata) -- ni "ruhusa", si "ubadilishaji". ----
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; ---- Wezesha paging: CR0.PG (bit 31). CR0.PE tayari ni 1
    ; (Multiboot inaahidi hili kwenye "machine state" ya kuingia).
    ; Baada ya mstari huu, tuko IA-32e COMPATIBILITY mode (bado
    ; tunatumia CS ya 32-bit kutoka GDT ya awali ya bootloader --
    ; long mode KAMILI inahitaji far jump kwenda CS ya 64-bit,
    ; hatua inayofuata). ----
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    lgdt [gdt64.pointer]          ; pakia GDT yetu ndogo ya 64-bit
                                   ; (null+code+data, angalia chini)

    jmp CODE_SEG64:_start64       ; far jump -- HII ndiyo inayobadilisha
                                   ; CS kikamilifu kwenda 64-bit long
                                   ; mode. Jump ya karibu (near jump)
                                   ; haitoshi -- CS haingebadilika.

.kosa_magic:
    ; Multiboot magic si sahihi -- hatuwezi kuamini eax/ebx wala
    ; taarifa yoyote ya bootloader. Simama kwa uwazi (hlt loop),
    ; USIENDELEE kimya na hali isiyojulikana.
.halt32:
    hlt
    jmp .halt32

[BITS 64]
_start64:
    ; Sajili za sehemu (segment registers) bado zina wachaguzi
    ; (selectors) wa zamani wa 32-bit -- zipakie upya na mchaguzi wa
    ; data ya 64-bit (thamani yenyewe haitumiki kwa msingi/mpaka
    ; katika long mode, LAKINI baadhi ya maunzi bado yanahitaji
    ; mchaguzi HALALI kwenye SS hasa).
    mov ax, DATA_SEG64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsp, stack_top64          ; rafu HALISI ya 64-bit (tofauti na
                                   ; stack_top32 -- nafasi tofauti,
                                   ; kuepuka mchanganyiko wa saizi za
                                   ; kuhifadhi kati ya njia mbili)

    ; ---- Sehemu 3: weka IDT + PIC KABLA ya kuita kernel_main --
    ; interrupts bado zimezimwa (cli tangu _start32), hivyo hakuna
    ; hatari ya IRQ kufika kabla jedwali kuwa tayari; "sti" halisi
    ; inatokea BAADA ya kernel_main kurudi, chini. ----
    call kawira_weka_idt
    call kawira_pic_remap_na_funga_zote

    call kernel_main               ; Swa HALISI (Sehemu 2) -- HAKUNA
                                   ; hoja (argc/argv haina maana
                                   ; kwenye ring 0, hakuna mfumo wa
                                   ; uendeshaji unaotupatia hayo).
                                   ; Inaandika ujumbe wa boot kwenye
                                   ; VGA kisha inarudi -- SI kosa
                                   ; tena (Sehemu 3): kazi halisi sasa
                                   ; inatokea kwenye ISR ya kibodi,
                                   ; iliyoamshwa na kitanzi cha hlt
                                   ; chini.

    ; ---- Fungua (unmask) IRQ1 (kibodi) PEKEE kwenye PIC ya master,
    ; KISHA sti -- mpangilio huu (unmask KABLA ya sti) unahakikisha
    ; hakuna dirisha ambapo IRQ1 ingefika ikiwa imefunguliwa lakini
    ; sti bado haijafanyika (isingefika kwa vyovyote, CPU haikubali
    ; interrupts hadi sti, lakini mpangilio huu bado ni wazi zaidi
    ; kusoma: "andaa KILA KITU, KISHA washa"). ----
    in al, 0x21
    and al, 0xFD                  ; safisha biti 1 (IRQ1) -- zilizobaki
                                   ; zinabaki zimefungwa (masked) kwa
                                   ; makusudi, Sehemu 3 ni kibodi TU
    out 0x21, al
    sti

.halt64:
    hlt                            ; ngoja interrupt (IRQ1 pekee
                                   ; imefunguliwa) -- baada ya ISR
                                   ; kurudi (iretq), utekelezaji
                                   ; unaendelea HAPA HAPA (baada ya
                                   ; hlt), si mwanzoni mwa kitanzi --
                                   ; "jmp .halt64" chini inarudisha
                                   ; kwenye hlt kwa mzunguko unaofuata
    jmp .halt64

; ---------------------------------------------------------------
; kernel_main -- SASA NI SWA HALISI (Sehemu 2, lugha-swa/swa PR #290
; "stage1 --kernel"), SI stub ya mkono tena. `kernel_main.bin` ni pato
; ghafi la ".text" la kernel_main.swa (chanzo kimo kwenye hazina hii,
; kilichokusanywa na gharama/jenga.sh kabla ya nasm kuita hapa) --
; kernel_kagua_wigo (uzalishaji.swa) inathibitisha kernel_main ni kazi
; YA KWANZA iliyotangazwa, hivyo baiti hizi zinaanzia HASA kwenye
; ofseti 0 ya pato, na zinaisha na "ret" ya kawaida (injini ya codegen
; ya --exe iliyotumika tena na hali_exe==2 -- angalia PR #290) -- "call
; kernel_main" ya juu inafanya kazi bila mabadiliko yoyote zaidi.
; ---------------------------------------------------------------
kernel_main:
    incbin "kernel_main.bin"

; ---------------------------------------------------------------
; kernel_kbd_isr -- mantiki ya "kibodi imebonyezwa" (Sehemu 3),
; kutoka kernel_kbd_isr.swa, KILICHOKUSANYWA TOFAUTI na kernel_main.bin
; (mwito wake WENYEWE wa "stage1 --kernel", angalia gharama/jenga.sh).
;
; ", 11" ya incbin: "stage1 --kernel" HUONGEZA HARAKA baiti 11 za
; "mov dword [0x9000], 0" (kusafisha kaka ya VGA) MWANZONI kabisa mwa
; KILA pato lake, bila masharti (angalia uzalishaji.swa, hali_exe==2,
; karibu na "0 KABLA kernel_main") -- kwa kernel_main.bin (Sehemu 2)
; hii ni sahihi (kaka INAPASWA kuanza 0 mara moja, mwanzoni mwa boot).
; LAKINI kwa ISR hii inayoitwa MARA NYINGI (kila bonyezo la kitufe),
; ingesafisha kaka KILA WAKATI -- herufi mpya ingeandikwa JUU ya
; iliyotangulia badala ya kuendelea. Baiti 11 za kwanza (kwa
; uthibitisho: 0xC7 0x04 0x25 + disp32(0x9000) + imm32(0)) zinarukwa
; MOJA KWA MOJA hapa (ugunduzi wa kando ulioandikwa wakati wa kujaribu
; kukusanya kernel_kbd_isr.swa, angalia hati/mipaka.md) -- SI mdudu wa
; kernel_kbd_isr.swa wala wa "stage1 --kernel" yenyewe, ni matokeo
; ya makusudi ya kutumia tena mfumo wa "kazi moja kwa kila mwito"
; kwa FAILI YA PILI.
kernel_kbd_isr:
    incbin "kernel_kbd_isr.bin", 11

; ---------------------------------------------------------------
; isr_kbd_trampoline -- ISR HALISI iliyosajiliwa kwenye IDT (vector
; 0x21, IRQ1 baada ya PIC remap, angalia kawira_pic_remap_na_funga_zote
; na kawira_weka_idt chini). Assembly SAFI (mantiki iko Swa,
; kernel_kbd_isr juu) -- kazi yake PEKEE: hifadhi/rudisha rejesta
; ZOTE za general-purpose (interrupt inaweza kutokea WAKATI WOWOTE,
; hata katikati ya usemi wa kernel_main/kitanzi cha hlt -- HAKUNA
; dhana inayoweza kufanywa kuhusu rejesta gani ziko "huru"), ita
; kernel_kbd_isr, tuma EOI (End Of Interrupt) kwa PIC ya master,
; kisha rudisha kwa "iretq" (SI "ret" ya kawaida -- usanifu wa x86
; interrupt unadai iretq, ambayo pia inarudisha RFLAGS/CS/RIP
; zilizosukumwa MOJA KWA MOJA na maunzi wakati wa kuingia kwenye
; interrupt, tofauti na "call" ya kawaida).
isr_kbd_trampoline:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    call kernel_kbd_isr

    mov al, 0x20                   ; EOI (End Of Interrupt) kwa PIC
    out 0x20, al                   ; ya MASTER pekee -- IRQ1 haitoki
                                    ; kwenye slave PIC, hivyo EOI ya
                                    ; slave (port 0xA0) haihitajiki

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq

; ---------------------------------------------------------------
; kawira_weka_idt -- jenga IDT (256 entries x baiti 16 = 4096 HASA,
; angalia "idt_table" chini) na "lidt". ENTRY MOJA TU (0x21, kibodi
; baada ya PIC remap) ina maana -- zilizobaki zinabaki "not present"
; (biti ya "present" = 0, kwa sababu jedwali zima limeanzishwa 0
; kabla ya %rep kuandika entry 0x21). KIKOMO CHA WAZI (makusudi, kwa
; muda, angalia hati/mipaka.md): exception/interrupt yoyote NJE ya
; IRQ1 (mfano #DE division-by-zero, #PF page fault kutoka kwa
; mdudu) itasababisha triple fault (QEMU inasimama/inarudisha upya)
; -- handler ya jumla ya exceptions ni kazi ya Sehemu 4+ (inahitaji
; kushughulikia error-code-on-stack kwa baadhi ya vectors, utata
; usiohitajika kwa lengo la Sehemu 3 "kibodi inafanya kazi").
; ---------------------------------------------------------------
kawira_weka_idt:
    lidt [idt_pointer]
    ret

; ---------------------------------------------------------------
; kawira_pic_remap_na_funga_zote -- 8259 PIC: ICW1-4 (mlolongo wa
; kawaida wa OSDev, angalia "8259 PIC" OSDev Wiki), ukisogeza IRQ0-7
; (master) kwenda vectors 0x20-0x27 na IRQ8-15 (slave) kwenda
; 0x28-0x2F -- BILA remap hii, IRQ0-7 zingegongana na CPU exception
; vectors 0x00-0x07 (mfano IRQ0/timer ingefika kama #DE). Baada ya
; ICW4, IRQ ZOTE zinafungwa (masked, 0xFF) -- "unmask" ya IRQ1 PEKEE
; inatokea BAADAYE, kwenye _start64 (baada ya kernel_main kurudi),
; SI hapa -- mgawanyo wa makusudi: kazi hii "inaandaa" PIC, _start64
; "inaamua lini kuruhusu" IRQ1 halisi kuanza kufika.
; io_wait (andika kwenye port 0x80, "debug port" isiyotumika) kati
; ya baadhi ya hatua -- desturi ya OSDev kwa maunzi ya kale ya 8259
; yanayohitaji muda kati ya amri (QEMU haihitaji hii, LAKINI
; kuiacha ni sahihi zaidi/kinga dhidi ya maunzi halisi ya baadaye).
; ---------------------------------------------------------------
kawira_pic_remap_na_funga_zote:
    mov al, 0x11                   ; ICW1: init + "ICW4 itafuata"
    out 0x20, al
    out 0x80, al                   ; io_wait
    out 0xA0, al
    out 0x80, al                   ; io_wait

    mov al, 0x20                   ; ICW2 (master): IRQ0-7 -> 0x20-0x27
    out 0x21, al
    out 0x80, al
    mov al, 0x28                   ; ICW2 (slave): IRQ8-15 -> 0x28-0x2F
    out 0xA1, al
    out 0x80, al

    mov al, 4                      ; ICW3 (master): slave iko IRQ2 (biti 2)
    out 0x21, al
    out 0x80, al
    mov al, 2                      ; ICW3 (slave): "cascade identity" = 2
    out 0xA1, al
    out 0x80, al

    mov al, 1                      ; ICW4: hali ya 8086/8088
    out 0x21, al
    out 0x80, al
    out 0xA1, al
    out 0x80, al

    mov al, 0xFF                   ; funga (mask) IRQ ZOTE kwa sasa --
    out 0x21, al                   ; _start64 itafungua IRQ1 pekee
    out 0xA1, al                   ; baada ya kernel_main kurudi

    ret

; ---------------------------------------------------------------
; Data: GDT ndogo ya 64-bit (null + code + data PEKEE -- hakuna TSS,
; Awamu hii haina task-switching kabisa)
; ---------------------------------------------------------------
align 8
gdt64:
    dq 0                                      ; null descriptor (WAJIBU)
.code equ $ - gdt64
    dq 0x00209A0000000000                     ; 64-bit code: P=1,DPL=0,
                                               ; S=1,Type=exec/read,
                                               ; L=1(long mode),D=0
.data equ $ - gdt64
    dq 0x0000920000000000                     ; 64-bit data: P=1,DPL=0,
                                               ; S=1,Type=read/write
.pointer:
    dw $ - gdt64 - 1                          ; ukubwa - 1 (mkataba
                                               ; wa lgdt)
    dq gdt64

CODE_SEG64 equ gdt64.code
DATA_SEG64 equ gdt64.data

; ---------------------------------------------------------------
; Majedwali ya paging (yamepangwa kwenye mpaka wa ukurasa, 4096) --
; PML4 na PDPT zina entry MOJA HALISI tu (index 0), zilizobaki
; sifuri (hazitumiki -- identity-map ya MB 2 za kwanza pekee).
; ---------------------------------------------------------------
align 4096
pml4: times 512 dq 0
pdpt: times 512 dq 0
pd:   times 512 dq 0

mb_magic_saved: dd 0
mb_info_saved:  dd 0

; ---------------------------------------------------------------
; IDT (256 entries x baiti 16 = 4096 HASA -- kwa bahati, kama
; kurasa moja, lakini SI muhimu kwa usahihi, ni "align 4096" tu ya
; kawaida). Kila entry ni "interrupt gate" ya 64-bit (angalia Intel
; SDM Vol. 3A, 6.14.1): offset(16) + selector(16) + IST(3)+zero(5) +
; type_attr(8) + offset(16) + offset(32) + zero(32).
;
; %rep 256 inaandika entry 0 KILA WAKATI (yaani "not present", biti
; ya "present" = 0 kwenye type_attr) ISIPOKUWA index 0x21 (kibodi),
; ambayo inaandikwa MAALUM ikielekeza kwenye isr_kbd_trampoline juu.
; NASM haikubali "(lebo >> 16)"/"(lebo & 0xFFFF)" MOJA KWA MOJA hata
; kwenye "-f bin" (imethibitishwa kwa jaribio dogo tofauti -- lebo
; peke yake "si scalar" kwa mkusanyiko wa NASM, ingawa thamani yake
; ni namba kamili tu hapa) -- suluhisho la kawaida (linalotumika na
; jamii ya OSDev): "lebo - $$" NI scalar HALISI (tofauti ya lebo mbili
; kwenye sehemu MOJA, kama "dw $ - gdt64 - 1" iliyopo tayari juu kwa
; gdt64.pointer), kisha ongeza KIINI_BASE (0x100000, SAWA na [ORG]
; iliyotangazwa juu ya faili hii) kupata anwani KAMILI -- baada ya
; hapo, shift/AND zinafanya kazi kama kawaida kwa namba ya kawaida.
; ---------------------------------------------------------------
KIINI_BASE equ 0x100000
align 4096
idt_table:
%assign kawira_idt_i 0
%rep 256
%if kawira_idt_i == 0x21
    dw (((isr_kbd_trampoline - $$) + KIINI_BASE) & 0xFFFF)
    dw CODE_SEG64
    db 0
    db 0x8E                        ; present(1) DPL(00) S(0) type(1110)
                                    ; -- "interrupt gate" ya 64-bit
    dw (((isr_kbd_trampoline - $$) + KIINI_BASE) >> 16) & 0xFFFF
    dd (((isr_kbd_trampoline - $$) + KIINI_BASE) >> 32) & 0xFFFFFFFF
    dd 0
%else
    dq 0
    dq 0
%endif
%assign kawira_idt_i kawira_idt_i + 1
%endrep
idt_table_mwisho:

idt_pointer:
    dw idt_table_mwisho - idt_table - 1   ; ukubwa - 1 (mkataba wa lidt)
    dq idt_table

; ---------------------------------------------------------------
; Rafu mbili tofauti (32-bit ya muda kwa mpito, 64-bit ya kudumu) --
; kuzitenganisha kunaepuka mkanganyiko wa saizi/anwani kati ya
; hatua mbili za mpito.
; ---------------------------------------------------------------
align 16
resb 4096
stack_top32:

align 16
resb 16384
stack_top64:
