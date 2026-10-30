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

**Kawira** ni kernel inayoanzisha, iliyoandikwa kwa [Swa](https://github.com/lugha-swa/swa) — bila Linux, bila libc, bila syscalls za mfumo mwingine. Swa ikiwa na mamlaka ya moja kwa moja juu ya maunzi. Sehemu pekee isiyo Swa ni `kiini.s`, assembly ndogo ya mkono inayovuka kutoka boot hadi 64-bit long mode.

Leo Kawira **inaingiliana**: inaanza kutoka Multiboot1, inaingia long mode, inaandika ujumbe kwenye skrini kupitia Swa halisi (`kernel_main.swa`), kisha inasikiliza kibodi (IDT + PIC) — kila kitufe kinaonekana papo hapo.

## Anza

<details open>
<summary><b>Jenga na uendeshe</b></summary>
<br>

Mahitaji: mkusanyaji wa Swa (`bin/swa` kutoka `gharama/jenga.sh` ya [lugha-swa/swa](https://github.com/lugha-swa/swa), au `stage1` yoyote), `nasm`, na `qemu-system-x86_64`.

```sh
STAGE1=/njia/ya/swa/bin/swa bash gharama/jenga.sh   # kernel_main.swa (--kernel) + kiini.s (nasm)
bash gharama/kimbiza-qemu.sh                        # anzisha kwenye QEMU (KVM ikiwepo)
```

Hakuna GRUB, hakuna ISO, hakuna linker — QEMU inaelewa Multiboot1 moja kwa moja kupitia `-kernel`.

</details>

<details>
<summary><b>Mnyororo wa kuanzisha</b></summary>
<br>

| Hatua | Faili | Kinachotokea |
|---|---|---|
| 1 | `kiini.s` | kichwa cha Multiboot1 → 32-bit → jedwali la paging → PAE + EFER.LME → long mode |
| 2 | `kernel_main.swa` | Swa halisi, imekusanywa kwa `--kernel`, inaandika kwenye VGA (`0xB8000`) |
| 3 | `kernel_kbd_isr.swa` | IDT + PIC iliyohamishwa; ISR ya kibodi inaandika kila kitufe kwenye skrini |

Kila hatua imethibitishwa mwisho hadi mwisho kwa QEMU: `sendkey` kupitia monitor socket, usomaji wa kumbukumbu ya VGA, na rejesta (`EFER.LMA`) — si kwa kudhania.

</details>

## Hali

Hali kamili, kila dai likiwa na uthibitisho wake, iko kwenye [`hati/mipaka.md`](hati/mipaka.md).

| Sehemu | Maelezo | Hali |
|---|---|---|
| 1 | boot stub ya mkono, long mode | imekamilika |
| 2 | `kernel_main` ya Swa halisi | imekamilika |
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
