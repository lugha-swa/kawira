; kiini.s -- boot stub ya mkono ya Kawira (kioo cha jukumu la
; msingi/mbegu.s kwenye lugha-swa/swa: KIINI CHA UAMINIFU, kila
; mstari una sababu iliyoandikwa hapa, si tu kinachofanyika).
;
; Kazi: kuanzia Multiboot1 (32-bit protected mode, PE=1 PG=0),
; kuweka jedwali dogo la paging (identity-map MB 2 za kwanza kwa
; ukurasa mkubwa mmoja), kuwezesha long mode (PAE+LME+PG), kuruka
; kwenda 64-bit code segment kupitia GDT ndogo, kisha kuita
; kernel_main() (bado stub ya mkono katika hatua hii -- itabadilishwa
; na baiti zilizozalishwa na "stage1 --kernel" kwenye Sehemu 2).
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

    call kernel_main               ; SWA (au, kwenye hatua hii ya
                                   ; kwanza ya uthibitisho, stub ya
                                   ; mkono chini) -- HAKUNA hoja
                                   ; (argc/argv haina maana kwenye
                                   ; ring 0, hakuna mfumo wa
                                   ; uendeshaji unaotupatia hayo)

    ; kernel_main HAIPASWI kurudi (ni kosa la kimantiki kama
    ; itafanya hivyo) -- HAKUNA "exit" syscall ya kuiita (hakuna wa
    ; kuipokea), hivyo SIMAMA kwa uwazi badala ya kuendelea kimya.
    cli
.halt64:
    hlt
    jmp .halt64

; ---------------------------------------------------------------
; kernel_main -- STUB YA MKONO YA MUDA (Sehemu 1 pekee, kuthibitisha
; kiini.s peke yake KABLA ya kuunganisha na mkusanyaji wa Swa).
; Itabadilishwa na baiti halisi zilizozalishwa na "stage1 --kernel"
; (incbin) kwenye Sehemu 2 ya mpango.
; ---------------------------------------------------------------
kernel_main:
    mov rax, 0xB8000               ; anwani ya kudumu ya VGA text
                                    ; buffer (80x25, herufi+rangi
                                    ; kila baiti mbili)
    mov word [rax], 0x4B4F          ; 'O' rangi 0x4B (chaguo-msingi
                                    ; hapa: nyekundu chinichini,
                                    ; njano juu) -- rangi ya bandia
                                    ; ya makusudi ili ITOFAUTIANE na
                                    ; rangi ya kawaida ya maandishi
                                    ; (0x0F), kuthibitisha kwa jicho
                                    ; hii ni herufi TULIYOANDIKA SISI,
                                    ; si maandishi ya awali ya BIOS
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
