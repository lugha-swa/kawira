#!/bin/bash
# jenga.sh — kusanya kernel_main.swa NA kernel_kbd_isr.swa (kila moja kwa
# mwito WAKE WENYEWE, TOFAUTI, wa "stage1 --kernel" ya lugha-swa/swa,
# Sehemu 2+3 -- angalia hati/mipaka.md) kuwa .bin mbili, kisha kiini.swm
# (kusanyiko -- lugha ya mashine ya Swa, ikijumuisha zote mbili kupitia
# "jumuisha") kuwa kawira.bin -- picha tambarare ya Multiboot1, a.out
# kludge -- HAKUNA ELF, HAKUNA linker, HAKUNA NASM.
#
# Inahitaji kutoka lugha-swa/swa:
#   STAGE1     mkusanyaji wa Swa (bin/swa kutoka gharama/jenga.sh, au stage1)
#   KUSANYIKO  assembler ya lugha ya mashine ya Swa, iliyojengwa kutoka
#              baiti 393 za mkono: bash gharama/jenga-kusanyiko.sh /njia/kusanyiko
# Kila kimoja kinaweza pia kuwa kwenye PATH (stage1, kusanyiko).
set -eu
cd "$(dirname "$0")/.."

tafuta() {  # $1 jina la kigezo, $2 amri kwenye PATH, $3 maelekezo
    local thamani="${!1:-}"
    if [ -z "$thamani" ] && command -v "$2" > /dev/null 2>&1; then
        thamani="$(command -v "$2")"
    fi
    if [ -z "$thamani" ]; then
        echo "KOSA: $1 haipatikani. $3" >&2
        exit 1
    fi
    printf '%s' "$thamani"
}
STAGE1="$(tafuta STAGE1 stage1 "Jenga lugha-swa/swa (bash gharama/jenga.sh hutoa bin/swa), kisha: STAGE1=/njia/ya/swa/bin/swa")"
KUSANYIKO="$(tafuta KUSANYIKO kusanyiko "Ndani ya lugha-swa/swa: bash gharama/jenga-kusanyiko.sh /njia/kusanyiko, kisha: KUSANYIKO=/njia/kusanyiko")"

"$STAGE1" --kernel kernel_main.swa > kernel_main.bin
echo "imejengwa: kernel_main.bin ($(stat -c%s kernel_main.bin) baiti, kutoka kernel_main.swa)"

"$STAGE1" --kernel kernel_kbd_isr.swa > kernel_kbd_isr.bin
echo "imejengwa: kernel_kbd_isr.bin ($(stat -c%s kernel_kbd_isr.bin) baiti, kutoka kernel_kbd_isr.swa)"

"$KUSANYIKO" < kiini.swm > kawira.bin
echo "imejengwa: kawira.bin ($(stat -c%s kawira.bin) baiti)"
