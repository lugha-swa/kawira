#!/bin/bash
# kimbiza-qemu.sh — anzisha kawira.bin kwenye QEMU. Hutumia KVM
# ikiwa /dev/kvm inapatikana (haraka zaidi), inarudi kwenye TCG
# (uigaji wa programu, polepole lakini bila hitaji la maunzi ya
# uvirtualishaji) kama sivyo.
#
# HII HAIHITAJI GRUB WALA ISO — QEMU YENYEWE inaelewa Multiboot1
# moja kwa moja kupitia "-kernel" (imethibitishwa kwa vitendo).
set -eu
cd "$(dirname "$0")/.."

if [ ! -f kawira.bin ]; then
    bash gharama/jenga.sh
fi

ACCEL="-accel tcg"
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    ACCEL="-accel kvm"
fi

exec qemu-system-x86_64 $ACCEL -kernel kawira.bin -m 64 -display none -serial mon:stdio
