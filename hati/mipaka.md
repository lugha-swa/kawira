# Mipaka ya Kawira

Hati hii ni marejeo rasmi ya kikomo cha kila hatua ya Kawira — kila
dai lina msingi wa uthibitisho halisi (jaribio la vitendo), si dhana.
Kioo cha falsafa ya `hati/mipaka.md` ya lugha-swa/swa: kilicho kamili
kimeandikwa kamili, kilicho na kikomo kimeandikwa na kikomo chake.

## Sehemu 1 — `kiini.s` (boot stub, IMEKAMILIKA na IMETHIBITISHWA)

**Kinachofanya kazi (kimethibitishwa kwa vitendo, si kudhani):**
Kawira inaanza kutoka Multiboot1 (32-bit protected mode), inaweka
jedwali dogo la paging (identity-map ya MB 2 za kwanza kwa ukurasa
mkubwa mmoja wa 2MB), inawezesha PAE + long mode (EFER.LME) + paging
(CR0.PG), inaruka kwenda 64-bit code segment kupitia GDT ndogo (null +
code + data), na kuita `kernel_main()` (stub ya mkono kwa sasa —
angalia Sehemu 2 hapa chini). `kernel_main` inaandika herufi moja
moja kwa moja kwenye VGA text buffer (0xB8000) kisha kurudi; `kiini.s`
inashughulikia hilo kwa `cli; hlt` loop (HAKUNA `exit` syscall — hakuna
mfumo wa uendeshaji chini yetu wa kuipokea).

**Uthibitisho uliofanywa (QEMU 11.1.1 + KVM):**
- Baiti za VGA memory zilisomwa MOJA KWA MOJA kupitia QEMU monitor
  (`xp /8xb 0xb8000`) baada ya kuendesha: `0x4f 0x4b ...` — sawa
  KABISA na herufi/rangi iliyoandikwa na `kernel_main`.
- `info registers` baada ya kusimama (halt) ilithibitisha long mode
  HALISI (si tu compatibility mode): `EFER=...0500` (bits LME=0x100
  NA LMA=0x400 zote mbili zimewekwa — LMA huwekwa na CPU YENYEWE tu
  ikiwa long mode imeamilika kikamilifu), `CS=0008 ... CS64` (lebo ya
  QEMU ikithibitisha CS ni 64-bit code segment), `CR0=80000011` (PG
  na PE zote zimewekwa), `CR4=00000020` (PAE imewekwa), `CR3` ikilingana
  na anwani ya PML4 iliyowekwa na `kiini.s`.
- Kichwa cha Multiboot1 (magic/flags/checksum/anwani) kimehesabiwa
  kwa mkono na Python, kimelinganishwa baiti kwa baiti na matokeo ya
  `nasm` (`od -t x4`) — sahihi kabisa.

**Kikomo cha wazi cha Sehemu 1 (makusudi, kwa muda):**
- `kernel_main` bado ni stub ya mkono (assembly), SI Swa halisi —
  hilo ni Sehemu 2.
- Identity-map ni MB 2 za kwanza PEKEE — kumbukumbu zaidi ya hapo
  haijapangiwa (haihitajiki bado, hakuna ugawaji wa kumbukumbu wa
  aina yoyote).
- HAKUNA interrupts (IDT haijawekwa), HAKUNA input ya kibodi, HAKUNA
  multitasking, HAKUNA mfumo wa faili.
- Herufi MOJA tu inaandikwa (uthibitisho wa dhana), SI mfumo kamili
  wa kuandika mfuatano/kusogeza kaka (cursor) — hilo linakuja na
  `vga_andika()` ya Sehemu 2.

## Sehemu 2 — `--kernel` mode ya mkusanyaji (INAENDELEA)

Bado haijaanzishwa — angalia mpango kamili (uliokubaliwa) kwenye
maoni ya PR ya kwanza ya hazina hii.

## Kanuni ya kudumu

`kiini.s` ni KIINI CHA UAMINIFU cha mradi huu (sawa na jukumu la
`msingi/mbegu.s` kwenye lugha-swa/swa) — badiliko lolote LAZIMA
lithibitishwe kwa QEMU (uthibitisho wa yaliyomo ya kumbukumbu NA
register state, si tu "haianguki") KABLA ya kuaminiwa, hakuna
ubaguzi.
