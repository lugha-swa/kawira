#!/bin/bash
# jenga.sh — kusanya kernel_main.swa NA kernel_kbd_isr.swa (kila
# moja kwa mwito WAKE WENYEWE, TOFAUTI, wa "stage1 --kernel" ya
# lugha-swa/swa, Sehemu 2+3 -- angalia hati/mipaka.md) kuwa .bin mbili,
# kisha kiini.s (nasm, ikijumuisha zote mbili kupitia incbin) kuwa
# kawira.bin -- binary ghafi ya Multiboot1, a.out kludge -- HAKUNA
# ELF, HAKUNA linker (ld) inayohitajika.
#
# Inahitaji "stage1" ya lugha-swa/swa (mkusanyaji wa Swa uliojijenga)
# ipatikane -- toa njia yake kupitia kigezo cha mazingira STAGE1, au
# iwe kwenye PATH. Hii SI tegemeo lisilo la lazima -- Kawira NI Swa
# kwenye ring 0, kernel_main.swa ni chanzo halisi cha Swa, kinahitaji
# mkusanyaji wa Swa ili kukusanywa, kama tu kernel ya C inavyohitaji
# gcc.
set -eu
cd "$(dirname "$0")/.."

STAGE1="${STAGE1:-}"
if [ -z "$STAGE1" ]; then
    if command -v stage1 > /dev/null 2>&1; then
        STAGE1="$(command -v stage1)"
    else
        echo "KOSA: stage1 (mkusanyaji wa Swa) haipatikani." >&2
        echo "Jenga lugha-swa/swa (bash gharama/jaribu-mnyororo.sh humo hujenga stage1 kama sehemu ya majaribio," >&2
        echo "au angalia CONTRIBUTING.md yake), kisha toa njia yake: STAGE1=/njia/kwenda/stage1 bash gharama/jenga.sh" >&2
        exit 1
    fi
fi

"$STAGE1" --kernel kernel_main.swa > kernel_main.bin
echo "imejengwa: kernel_main.bin ($(stat -c%s kernel_main.bin) baiti, kutoka kernel_main.swa)"

"$STAGE1" --kernel kernel_kbd_isr.swa > kernel_kbd_isr.bin
echo "imejengwa: kernel_kbd_isr.bin ($(stat -c%s kernel_kbd_isr.bin) baiti, kutoka kernel_kbd_isr.swa)"

nasm -f bin kiini.s -o kawira.bin
echo "imejengwa: kawira.bin ($(stat -c%s kawira.bin) baiti)"
