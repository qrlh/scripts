#!/usr/bin/env bash
journalctl -k -f --since=now --output=cat | \
grep --line-buffered "AMDGPU device coredump file has been created" | \
while read -r _; do
    cp /sys/class/drm/card1/device/devcoredump/data /var/log/gpu-coredumps/"coredump-$(date +%Y%m%d-%H%M%S).dat" && \
    logger "amdgpu coredump backed up"
done
