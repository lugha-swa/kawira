<div align="center">
  <p>
    <a href="https://github.com/lugha-swa/kawira">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/lugha-swa/.github/main/rasilimali/mabango/kawira-giza.png">
        <img width="100%" src="https://raw.githubusercontent.com/lugha-swa/.github/main/rasilimali/mabango/kawira-mwanga.png" alt="Kawira — Swa kwenye ring 0">
      </picture>
    </a>
  </p>

[Tovuti](https://lugha-swa.github.io) | [Swa](https://github.com/lugha-swa/swa) | [Mipaka](hati/mipaka.md) | [Jamii](https://lugha-swa.github.io/jamii.html)

<br>

<a href="https://github.com/lugha-swa/swa"><img src="https://img.shields.io/badge/imeandikwa_kwa-Swa-A34E14" alt="Imeandikwa kwa Swa"></a>
<a href="#leseni"><img src="https://img.shields.io/badge/leseni-MIT%20%2F%20Apache--2.0-6B5E4A" alt="Leseni"></a>
<img src="https://img.shields.io/badge/lengo-x86--64%20ring%200-6B5E4A" alt="x86-64 ring 0">

</div>
<br>

**Kawira** ni kiini kinachoanzisha, iliyoandikwa kwa [Swa](https://github.com/lugha-swa/swa) — bila Linux, bila libc, bila syscalls za mfumo mwingine. Swa ikiwa na mamlaka ya moja kwa moja juu ya maunzi. Sehemu pekee isiyo Swa ni `kiini.s`, assembly ndogo ya mkono inayovuka kutoka boot hadi 64-bit long mode.

Leo Kawira **inaingiliana**: inaanza kutoka Multiboot1, inaingia long mode, inaandika ujumbe kwenye skrini kupitia Swa halisi (`kazi_kuu.swa`), kisha inasikiliza kibodi (IDT + PIC) — kila kitufe kinaonekana papo hapo.

## Anza

<details open>
<summary><b>Jenga na uendeshe</b></summary>
<br>

Mahitaji: mkusanyaji wa Swa (`bin/swa` kutoka `./msingi/mjenzi.bin gharama/jenga.mapishi` ya [lugha-swa/swa](https://github.com/lugha-swa/swa)), `kusanyiko` (assembler ya lugha ya mashine ya Swa: `./msingi/mjenzi.bin gharama/kusanyiko.mapishi` ndani ya lugha-swa/swa, kisha `jengo/kusanyiko` -- hujengwa kutoka baiti 393 za mkono, bila NASM), na `qemu-system-x86_64`.

```sh
export SWA=/njia/ya/swa/bin/swa KUSANYIKO=/njia/ya/swa/jengo/kusanyiko
bash gharama/jenga.sh          # kazi_kuu.swa (--kiini) + kiini.swm (kusanyiko)
bash gharama/kimbiza-qemu.sh   # anzisha kwenye QEMU (KVM ikiwepo)
bash gharama/jaribu.sh         # washa, bonyeza a b c, thibitisha skrini ya VGA
```

Hakuna GRUB, hakuna ISO, hakuna linker — QEMU inaelewa Multiboot1 moja kwa moja kupitia `-kernel`.

</details>

<details>
<summary><b>Mnyororo wa kuanzisha</b></summary>
<br>

| Hatua | Faili | Kinachotokea |
|---|---|---|
| 1 | `kiini.swm` | kichwa cha Multiboot1 → 32-bit → jedwali la paging → PAE + EFER.LME → long mode |
| 2 | `kazi_kuu.swa` | Swa halisi, imekusanywa kwa `--kiini`, inaandika kwenye VGA (`0xB8000`) |
| 3 | `kibodi.swa` | IDT + PIC iliyohamishwa; ISR ya kibodi inaandika kila kitufe kwenye skrini |

Kila hatua imethibitishwa mwisho hadi mwisho kwa QEMU: `sendkey` kupitia monitor socket, usomaji wa kumbukumbu ya VGA, na rejesta (`EFER.LMA`) — si kwa kudhania.

</details>

## Hali

Hali kamili, kila dai likiwa na uthibitisho wake, iko kwenye [`hati/mipaka.md`](hati/mipaka.md).

| Sehemu | Maelezo | Hali |
|---|---|---|
| 1 | kianzishi cha mkono, long mode | imekamilika |
| 2 | `anza` ya Swa halisi | imekamilika |
| 3 | IDT, PIC, kibodi | imekamilika |
| 4 | exceptions na faults, funguo maalum (shift, backspace, enter) | inayofuata |

## Kwa nini

[lugha-swa/swa](https://github.com/lugha-swa/swa) ina lengo la muda mrefu: kuchukua nafasi ambazo C inashikilia duniani na kuipiga kwenye vipimo vyake vyenyewe. Uwanja mmoja ambao C bado inashikilia bila mpinzani ni kernels, OS na firmware — kuandika kwenye ring 0 kunahitaji lugha isiyo na tegemeo la mfumo wa uendeshaji mwingine chini yake. Kawira ni jaribio la Swa kufika huko.

Kawira **si mradi wa faragha**. Tofauti na TempleOS — kazi ya ajabu ya mtu mmoja, lakini iliyofungwa kwake mwenyewe — Kawira ni wazi kwa jamii tangu commit ya kwanza, na inapitia mchakato ule ule wa ukaguzi unaotumika kwenye lugha-swa/swa.

## Ikolojia

| Hazina | Maelezo |
|---|---|
| [lugha-swa/swa](https://github.com/lugha-swa/swa) | mkusanyaji na maktaba ya msingi |
| [lugha-swa/kawira](https://github.com/lugha-swa/kawira) | Swa kwenye ring 0 — hazina hii |
| [lugha-swa/uchapaji-swa](https://github.com/lugha-swa/uchapaji-swa) | msomaji wa TrueType na kijazaji cha glyph, bila FreeType |
| [lugha-swa/tree-sitter-swa](https://github.com/lugha-swa/tree-sitter-swa) | sarufi ya Tree-sitter — rangi za sintaksia kwenye vihariri |
| [lugha-swa.github.io](https://github.com/lugha-swa/lugha-swa.github.io) | tovuti na mwongozo wa lugha |

## Leseni

Kwa chaguo lako, [Apache 2.0](LICENSE-APACHE) au [MIT](LICENSE-MIT).

<br>
<div align="center">
  <a href="https://github.com/lugha-swa"><img src="https://raw.githubusercontent.com/lugha-swa/.github/main/rasilimali/nembo/nembo-64.png" width="28" alt="lugha-swa"></a>
  <br>
  <sub>lugha-swa · Afrika ya Mashariki</sub>
</div>
