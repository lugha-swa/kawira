# Mipaka ya Kawira

Hati hii ni marejeo rasmi ya kikomo cha kila hatua ya Kawira — kila
dai lina msingi wa uthibitisho halisi (jaribio la vitendo), si dhana.
Kioo cha falsafa ya `hati/mipaka.md` ya lugha-swa/swa: kilicho kamili
kimeandikwa kamili, kilicho na kikomo kimeandikwa na kikomo chake.

## Sehemu 1+2 — `kiini.s` + `kernel_main.swa` (IMEKAMILIKA na IMETHIBITISHWA)

**Kinachofanya kazi (kimethibitishwa kwa vitendo, si kudhani):**
Kawira inaanza kutoka Multiboot1 (32-bit protected mode), inaweka
jedwali dogo la paging (identity-map ya MB 2 za kwanza kwa ukurasa
mkubwa mmoja wa 2MB), inawezesha PAE + long mode (EFER.LME) + paging
(CR0.PG), inaruka kwenda 64-bit code segment kupitia GDT ndogo (null +
code + data), na kuita `kernel_main()` -- **SASA NI SWA HALISI**,
iliyokusanywa na `stage1 --kernel` (Sehemu 2, `lugha-swa/swa` PR
#290) kutoka `kernel_main.swa` chanzo kilichomo kwenye hazina hii, SI
stub ya mkono tena. `kernel_main` inaandika mfuatano kamili ("Kawira
-- Swa kwenye ring 0") kupitia `vga_andika()` kwenye VGA text buffer
(0xB8000); `kiini.s` inashughulikia kurudi kwake kwa `cli; hlt` loop
(HAKUNA `exit` syscall -- hakuna mfumo wa uendeshaji chini yetu wa
kuipokea).

**Uthibitisho uliofanywa (QEMU 11.1.1 + KVM):**
- Baiti za VGA memory zilisomwa MOJA KWA MOJA kupitia QEMU monitor
  (`xp /54xb 0xb8000`) baada ya kuendesha, na kusimbuliwa kwa mkono
  (herufi + attribute kila baiti mbili): `"Kawira -- Swa kwenye ring
  0"` -- SAWA KABISA na mfuatano ulioandikwa kwenye `kernel_main.swa`.
- `info registers` baada ya kusimama (halt) ilithibitisha long mode
  HALISI (si tu compatibility mode): `EFER=...0500` (bits LME=0x100
  NA LMA=0x400 zote mbili zimewekwa), `CS=0008 ... CS64`, `HLT=1`
  (imesimama sahihi, hakuna anguko).
- Kichwa cha Multiboot1 (magic/flags/checksum/anwani) kimehesabiwa
  kwa mkono na Python, kimelinganishwa baiti kwa baiti na matokeo ya
  `nasm` (`od -t x4`) -- sahihi kabisa.
- Ukubwa wa jumla wa `kawira.bin` (36880 baiti) HAUKUBADILIKA kati ya
  toleo la stub (~16 baiti za `kernel_main`) na toleo halisi la Swa
  (1113 baiti) -- imethibitishwa hii ni kwa sababu ya `align 4096`
  kabla ya majedwali ya paging (yote mawili yanatoshea ukurasa mmoja
  wa 4096 kabla ya alignment), SI mdudu.
- Backend ya `--kernel` yenyewe (`uzalishaji.swa`, `hali_exe==2`)
  imekaguliwa kwa kina TOFAUTI kwenye `lugha-swa/swa` PR #290 (grep
  ya kila tukio la `hali_exe`/`hali_exe_sasa` faili nzima, mnyororo
  411/411 + WASM 36/36 hazijaathirika, jaribio la 13/13 la vitendo
  likiwemo uthibitisho wa mkono wa mzunguko/wito wa mbele/hesabu).

**Kikomo cha wazi (makusudi, kwa muda):**
- Identity-map ni MB 2 za kwanza PEKEE -- kumbukumbu zaidi ya hapo
  haijapangiwa (haihitajiki bado, hakuna ugawaji wa kumbukumbu wa
  aina yoyote -- `tenga()` haipo kwenye wigo wa `--kernel`).
- `vga_andika()` (literal) inahitaji hoja iwe mfuatano halisi, SI
  kigezo -- angalia `lugha-swa/swa` `uzalishaji_vga_andika`. (Sehemu
  3 iliongeza `vga_herufi(usemi)`, inayokubali usemi WOWOTE -- angalia
  chini.)
- Miundo, D32/D64, `chagua`, vigezo vya ulimwengu -- vyote nje ya
  wigo wa `--kernel` (kosa la wazi wakati wa kukusanya).

## Sehemu 3 — Interrupts na Uingizaji wa Kibodi (IMEKAMILIKA na IMETHIBITISHWA)

**Kinachofanya kazi (kimethibitishwa kwa vitendo):** `kiini.s` sasa
inaweka IDT (256 entries, entry 0x21 pekee ina maana -- angalia
chini), inaremapa PIC ya 8259 (IRQ0-7 -> vectors 0x20-0x27, IRQ8-15
-> 0x28-0x2F, kuepuka mgongano na CPU exception vectors), na baada ya
`kernel_main()` kurudi, inafungua (unmask) IRQ1 PEKEE na `sti`,
kisha inangoja kwenye kitanzi cha `hlt`. Kila bonyezo la kitufe
linaloshughulikiwa (herufi ndogo a-z, tarakimu 0-9, nafasi) linaita
`isr_kbd_trampoline` (assembly, inahifadhi/kurudisha rejesta ZOTE za
general-purpose) -> `kernel_kbd_isr` (Swa HALISI, `kernel_kbd_isr.swa`,
iliyokusanywa TOFAUTI na `kernel_main.swa` kwa mwito wake wenyewe wa
`stage1 --kernel`) -> `kbd_scancode()` kusoma port 0x60, tafsiri
Scan Code Set 1 kwenda ASCII, `vga_herufi(herufi)` kuandika kwenye
skrini bila kuvuruga kaka (cursor) iliyopo -- herufi mpya zinaendelea
KUTOKA pale ujumbe wa boot ulipoishia, SI kuandika juu yake.

Builtins mbili mpya ziliongezwa kwenye `lugha-swa/swa` (`--kernel`
mode, `hali_exe==2`) kwa Sehemu hii: `kbd_scancode() -> n32` (PR #291)
na `vga_herufi(usemi)` (PR #291, inatathmini USEMI WOWOTE wakati wa
kukimbia -- KIOO cha `vga_andika()` lakini kwa herufi MOJA
iliyokokotolewa, SI mfuatano halisi).

**Uthibitisho uliofanywa (QEMU + monitor socket, `sendkey`):**
- Boot ya kawaida ilithibitishwa KWANZA (ujumbe wa boot bado sahihi,
  register state -- `EFER=...0500`, `CS64`, `HLT=1` -- bado sahihi,
  kama Sehemu 1+2).
- Funguo NNE tofauti zilitumwa kupitia QEMU monitor (`sendkey a`,
  `sendkey 5`, `sendkey spc`, `sendkey z`) -- baada ya KILA moja, VGA
  memory (0xB8000) ilisomwa (`xp`) na kusimbuliwa kwa mkono: herufi
  SAHIHI ilionekana KILA WAKATI, ikiongezeka KATIKA MFUATANO sahihi
  moja kwa moja baada ya ujumbe wa boot (`"...ring 0" -> "...ring 0a"
  -> "...ring 0a5" -> "...ring 0a5 " -> "...ring 0a5 z"`), ikithibitisha
  TAFSIRI ya scancode (funguo tofauti kabisa kwenye jedwali la Scan
  Code Set 1, SI bahati ya kesi moja) NA usimamizi sahihi wa kaka.
- `info registers` ililinganishwa KABLA na BAADA ya kila `sendkey`:
  RAX/RBX/RCX/RDX/RSI/RDI/RBP/**RSP**/R8-R15/RIP ZOTE zilibaki SAWA
  KABISA -- inathibitisha `isr_kbd_trampoline` inahifadhi/kurudisha
  rejesta zote sahihi (hakuna uvujaji wa rafu -- RSP isiyobadilika ni
  uthibitisho wa moja kwa moja kuwa idadi ya push == idadi ya pop).
- Uthibitisho wa ZIADA usio wa moja kwa moja lakini WENYE NGUVU: funguo
  NNE zilizofuatana ZOTE zilishughulikiwa kwa mafanikio -- kama EOI
  (`out 0x20, 0x20`) ingekosewa au kukosekana, PIC ingezuia IRQ1 YOYOTE
  ya PILI isifike kabisa (IRQ ya kiwango kile kile "bado inahudumiwa"
  kwa PIC ya 8259) -- funguo za 2, 3, na 4 kufanikiwa ni uthibitisho
  kwamba EOI inatumwa KWA USAHIHI kila wakati, si tu mara ya kwanza.

**Ugunduzi wa kando ulioandikwa wakati wa maendeleo (SI mdudu, ni
tabia ya makusudi iliyoshughulikiwa kwa uwazi):**
- `stage1 --kernel` HUONGEZA baiti 11 za `mov dword [0x9000], 0`
  (kusafisha kaka) MWANZONI kabisa mwa KILA pato lake, bila masharti
  (ni sahihi kwa `kernel_main.bin`, ambayo INAPASWA kuanzisha kaka
  mara moja). `kernel_kbd_isr.bin` (Sehemu 3) inaitwa MARA NYINGI
  (kila bonyezo), hivyo baiti hizi 11 zinarukwa MOJA KWA MOJA kwenye
  `incbin` (`incbin "kernel_kbd_isr.bin", 11`, angalia maoni kwenye
  `kiini.s`) -- imethibitishwa kwa usahihi kwa Python (`d[:11].hex()
  == "c704250090000000000000"`, na `d[11:15] == push rbp; mov
  rbp,rsp` prologue HALISI ya kazi).
- NASM haikubali `(lebo & 0xFFFF)`/`(lebo >> 16)` MOJA KWA MOJA hata
  kwenye `-f bin` (jaribio dogo tofauti lilithibitisha hili ni tabia
  ya JUMLA ya NASM, SI kosa la muundo wa IDT yetu) -- suluhisho
  (linalotumika kwenye `idt_table`, `kiini.s`): `(lebo - $$) +
  KIINI_BASE` ni SCALAR halali (tofauti ya lebo mbili kwenye sehemu
  moja, kioo cha `dw $ - gdt64 - 1` iliyopo tayari), kisha shift/AND
  zinafanya kazi kama kawaida.

**Kikomo cha wazi (makusudi, kwa muda):**
- IDT ina entry MOJA TU (0x21/IRQ1) -- zilizobaki 255 zinabaki "not
  present". Exception/interrupt yoyote NJE ya IRQ1 (mfano #DE, #PF
  kutoka kwa mdudu wa baadaye) itasababisha triple fault (QEMU
  inasimama/inarudisha upya) -- handler ya jumla ya exceptions NI
  Sehemu 4+ (inahitaji kushughulikia error-code-on-stack kwa baadhi
  ya vectors, utata usiohitajika kwa lengo la Sehemu 3).
- Ni SUBSET ya kibodi: herufi ndogo a-z, tarakimu 0-9, nafasi PEKEE.
  Shift/ctrl/backspace/enter/herufi kubwa/funguo maalum -- HAZITAMBULIKI
  (zinapuuzwa kimya, SI hitilafu -- ni za kawaida kwa kibodi halisi).
- Multitasking, kumbukumbu halisi (physical allocator), framebuffer ya
  kweli, mfumo wa faili -- bado NJE ya wigo (Sehemu 4+).

## Kanuni ya kudumu

`kiini.s` ni KIINI CHA UAMINIFU cha mradi huu (sawa na jukumu la
`msingi/mbegu.s` kwenye lugha-swa/swa) — badiliko lolote LAZIMA
lithibitishwe kwa QEMU (uthibitisho wa yaliyomo ya kumbukumbu NA
register state, si tu "haianguki") KABLA ya kuaminiwa, hakuna
ubaguzi. Vivyo hivyo kwa `kernel_main.swa` sasa ikiwa Swa halisi --
badiliko lolote kwake linahitaji uthibitisho ule ule wa QEMU wa
mwisho hadi mwisho, si kuamini `--kernel` peke yake bila kujaribu
boot ya kweli.

## Kazi ya baadaye (Sehemu 4+)

Handler ya jumla ya exceptions/faults (IDT nzima, si vector moja),
funguo maalum (shift/ctrl/backspace/enter, herufi kubwa), kumbukumbu
halisi (physical page allocator), framebuffer ya kweli, multitasking,
mfumo wa faili -- ramani kamili ya njia hii imehifadhiwa kwenye
mazungumzo yaliyosababisha mradi huu.
