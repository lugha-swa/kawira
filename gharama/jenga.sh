#!/bin/bash
# jenga.sh — kusanya kazi_kuu.swa NA kibodi.swa (kila moja kwa
# mwito WAKE WENYEWE, TOFAUTI, wa "swa --kiini" ya lugha-swa/swa,
# Sehemu 2+3 -- angalia hati/mipaka.md) kuwa .bin mbili, kisha kiini.swm
# (kusanyiko -- lugha ya mashine ya Swa, ikijumuisha zote mbili kupitia
# "jumuisha") kuwa kawira.bin -- picha tambarare ya Multiboot1, a.out
# kludge -- HAKUNA ELF, HAKUNA linker, HAKUNA NASM.
#
# Inahitaji kutoka lugha-swa/swa:
#   SWA        mkusanyaji wa Swa (bin/swa kutoka gharama/jenga.mapishi)
#   KUSANYIKO  assembler ya lugha ya mashine ya Swa, iliyojengwa kutoka
#              baiti 393 za mkono: ./msingi/mjenzi.bin gharama/kusanyiko.mapishi
#              (matokeo: jengo/kusanyiko ndani ya lugha-swa/swa)
# Kila kimoja kinaweza pia kuwa kwenye PATH (swa, kusanyiko).
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
SWA="$(tafuta SWA swa "Jenga lugha-swa/swa (./msingi/mjenzi.bin gharama/jenga.mapishi hutoa bin/swa), kisha: SWA=/njia/ya/swa/bin/swa")"
KUSANYIKO="$(tafuta KUSANYIKO kusanyiko "Ndani ya lugha-swa/swa: ./msingi/mjenzi.bin gharama/kusanyiko.mapishi, kisha: KUSANYIKO=/njia/ya/swa/jengo/kusanyiko")"

"$SWA" --kiini kazi_kuu.swa > kazi_kuu.bin
echo "imejengwa: kazi_kuu.bin ($(stat -c%s kazi_kuu.bin) baiti, kutoka kazi_kuu.swa)"

"$SWA" --kiini kibodi.swa > kibodi.bin
echo "imejengwa: kibodi.bin ($(stat -c%s kibodi.bin) baiti, kutoka kibodi.swa)"

"$KUSANYIKO" < kiini.swm > kawira.bin
echo "imejengwa: kawira.bin ($(stat -c%s kawira.bin) baiti)"
