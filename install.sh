#!/bin/bash
source ./vars.sh

failed=()

run_step() {
    local name="$1"
    shift
    echo ""
    echo "============================================"
    echo "  Step: $name"
    echo "============================================"
    if "$@"; then
        echo "  [OK] $name"
    else
        echo "  [FAIL] $name" >&2
        failed+=("$name")
    fi
}

run_chroot() {
    local name="$1"
    local script="$2"
    echo ""
    echo "============================================"
    echo "  Step: $name (inside chroot)"
    echo "============================================"
    if arch-chroot /mnt bash -c 'cd /archinstall && ./'"$script"; then
        echo "  [OK] $name"
    else
        echo "  [FAIL] $name" >&2
        failed+=("$name")
    fi
}

run_step "1_part" ./1_part
run_step "2_partition_and_mount" ./2_partition_and_mount
run_step "3_install" ./3_install
run_chroot "4_base" "4_base"
run_chroot "5_bootloader" "5_bootloader"
run_chroot "6_gui" "6_gui"
run_chroot "7_common_apps" "7_common_apps"

echo ""
echo "============================================"
echo "            INSTALLATION SUMMARY"
echo "============================================"
if [ ${#failed[@]} -eq 0 ]; then
    echo "  All steps completed successfully!"
else
    echo "  The following steps FAILED:"
    for f in "${failed[@]}"; do
        echo "    - $f"
    done
fi
echo "============================================"
