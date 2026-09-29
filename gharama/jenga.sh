#!/bin/bash
# jenga.sh — kusanya kiini.s kwenda kawira.bin (binary ghafi ya
# Multiboot1, a.out kludge -- HAKUNA ELF, HAKUNA linker (ld)
# inayohitajika, kioo cha jinsi mbegu.bin ya lugha-swa/swa
# inavyozalishwa moja kwa moja bila ld).
set -eu
cd "$(dirname "$0")/.."
nasm -f bin kiini.s -o kawira.bin
echo "imejengwa: kawira.bin ($(stat -c%s kawira.bin) baiti)"
