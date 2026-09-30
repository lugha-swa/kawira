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
- HAKUNA interrupts (IDT haijawekwa), HAKUNA input ya kibodi, HAKUNA
  multitasking, HAKUNA mfumo wa faili.
- `vga_andika()` inahitaji hoja iwe mfuatano halisi (literal), SI
  kigezo -- angalia `lugha-swa/swa` `uzalishaji_vga_andika`.
- Miundo, D32/D64, `chagua`, vigezo vya ulimwengu -- vyote nje ya
  wigo wa `--kernel` (kosa la wazi wakati wa kukusanya).

## Kanuni ya kudumu

`kiini.s` ni KIINI CHA UAMINIFU cha mradi huu (sawa na jukumu la
`msingi/mbegu.s` kwenye lugha-swa/swa) — badiliko lolote LAZIMA
lithibitishwe kwa QEMU (uthibitisho wa yaliyomo ya kumbukumbu NA
register state, si tu "haianguki") KABLA ya kuaminiwa, hakuna
ubaguzi. Vivyo hivyo kwa `kernel_main.swa` sasa ikiwa Swa halisi --
badiliko lolote kwake linahitaji uthibitisho ule ule wa QEMU wa
mwisho hadi mwisho, si kuamini `--kernel` peke yake bila kujaribu
boot ya kweli.

## Kazi ya baadaye (Sehemu 3+)

Interrupts (IDT, PIC/APIC), keyboard input, kumbukumbu halisi
(physical page allocator), framebuffer ya kweli, multitasking, mfumo
wa faili -- ramani kamili ya njia hii imehifadhiwa kwenye mazungumzo
yaliyosababisha mradi huu.
