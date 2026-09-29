# Kawira

Swa kwenye ring 0 — kernel inayoanzisha, iliyoandikwa kwa Swa yenyewe
(sehemu ndogo isiyoepukika ni assembly ya mkono, `kiini.s`, ya kuvuka
kutoka boot hadi 64-bit long mode — angalia chini).

## Kwa nini

[lugha-swa/swa](https://github.com/lugha-swa/swa) ina lengo la muda
mrefu: kuchukua nafasi ambazo C inashikilia duniani na kuipiga kwenye
vipimo vyake vyenyewe. Uwanja mmoja ambao C bado inashikilia bila
mpinzani ni kernels/OS/firmware — kuandika kwenye ring 0 kunahitaji
lugha isiyo na tegemeo la mfumo wa uendeshaji mwingine yeyote chini
yake. Kawira ni jaribio la Swa kufika huko: bila Linux, bila libc,
bila syscalls za mfumo mwingine — Swa ikiwa na mamlaka ya moja kwa
moja juu ya maunzi.

## Kuhusu uwazi wa mradi huu

Kawira SI mradi wa faragha. Tofauti na TempleOS (Terry Davis) —
kazi ya ajabu ya mtu mmoja, lakini iliyofungwa kwake mwenyewe — Kawira
ni wazi kwa jamii TANGU COMMIT YA KWANZA: leseni mbili (MIT/Apache-2.0,
chagua unayopenda), mchango unakaribishwa, na mchakato ule ule wa
ukaguzi wa kujitegemea unaotumika kwenye lugha-swa/swa.

## Hali ya sasa

Angalia [`hati/mipaka.md`](hati/mipaka.md) kwa hali kamili, ya kweli
(kila dai lina uthibitisho ulioandikwa) — Sehemu 1 (`kiini.s`, boot
stub) imekamilika na imethibitishwa kwa QEMU. Sehemu 2 (`--kernel`
mode ya mkusanyaji wa Swa, kuruhusu `kernel_main()` iandikwe kwa Swa
halisi) inaendelea.

## Kujaribu

```
bash gharama/jenga.sh          # kusanya kiini.s (nasm)
bash gharama/kimbiza-qemu.sh    # anzisha kwenye QEMU (KVM ikiwepo)
```

Hakuna GRUB, hakuna ISO, hakuna linker — QEMU inaelewa Multiboot1
moja kwa moja kupitia `-kernel`.
