#!/bin/bash
# jaribu.sh — jenga kawira.bin kisha iwashe kwenye QEMU: bango la boot
# lazima liwe kwenye VGA (0xB8000), na vitufe vinavyobonyezwa kupitia
# QEMU monitor (sendkey) lazima vionekane baada yake -- uthibitisho wa
# kumbukumbu halisi ya skrini, si "haikuanguka".
set -eu
cd "$(dirname "$0")/.."
bash gharama/jenga.sh > /dev/null
SWA="${SWA:-$(command -v swa || true)}"
[ -n "$SWA" ] || { echo "KOSA: SWA haipatikani (angalia gharama/jenga.sh)" >&2; exit 1; }
"$SWA" --programu majaribio/endesha.swa > jengo_endesha
chmod +x jengo_endesha
SKRINI="$(./jengo_endesha kawira.bin a b c)"
rm -f jengo_endesha
TARAJIWA="Kawira -- Swa kwenye ring 0abc"
case "$SKRINI" in
    "$TARAJIWA"*) echo "SAWA: $TARAJIWA" ;;
    *) echo "SHINDWA: skrini ni '$SKRINI', tarajiwa inaanza na '$TARAJIWA'"; exit 1 ;;
esac
