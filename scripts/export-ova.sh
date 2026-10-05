#!/bin/bash
# Build the OVA versions next to the OVF folders:
#   export/android16-desktop_OVA/android16-desktop.ova
#   export/android16-universal_OVA/android16-universal.ova
# An OVA is the same appliance as the OVF folder packed into one file, so it
# is made FROM the tested OVF (ovftool checks the OVF manifest on the way).
set -e
OUT=/home/student/Downloads/Android_16/export
for n in android16-desktop android16-universal; do
    echo
    echo "==============================================="
    echo "  $n  ->  ${n}_OVA/$n.ova"
    echo "==============================================="
    D="$OUT/${n}_OVA"
    rm -rf "$D"; mkdir -p "$D"
    ovftool --acceptAllEulas --overwrite "$OUT/$n/$n.ovf" "$D/$n.ova" 2>&1 | grep -vE "progress" | tail -4
    (cd "$D" && sha256sum "$n.ova" > "$n.ova.sha256")
    ls -lh "$D" | tail -n +2 | awk '{print "     ", $9, $5}'
done
bash /home/student/Downloads/Android_16/make-ova-helpers.sh
echo "ova-done"
