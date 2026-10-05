#!/bin/bash
# Build export/Github_Push_OVA/release from the final OVA folders.
# Each .ova is COPIED and the copy split into parts under 2 GB (GitHub's
# per-file limit). The originals in export/*_OVA stay whole.
set -e
SRC=/home/student/Downloads/Android_16/export
DEST=$SRC/Github_Push_OVA/release
PARTMB=1900

rm -rf "$SRC/Github_Push_OVA"; mkdir -p "$DEST"
for n in android16-desktop android16-universal; do
    echo "=== ${n}_OVA ==="
    D="$DEST/${n}_OVA"; mkdir -p "$D"
    cp "$SRC/${n}_OVA/README.txt" "$D/"
    split -b ${PARTMB}M -d -a 3 "$SRC/${n}_OVA/$n.ova" "$D/$n.ova.part"
    NP=$(ls "$D/$n.ova".part* | wc -l)
    echo "   $n.ova -> $NP parts"
    WIN=$(cd "$D" && ls "$n.ova".part* | tr '\n' ' ' | sed 's/ $//; s/ / + /g')

    cat > "$D/rejoin.sh" <<REOF
#!/bin/bash
# Put the downloaded parts back together into $n.ova
cd "\$(dirname "\$0")"
if ! ls $n.ova.part000 >/dev/null 2>&1; then echo "No .part files here."; exit 1; fi
echo "Joining $NP parts into $n.ova ..."
cat $n.ova.part* > $n.ova && rm -f $n.ova.part*
echo "Done: $n.ova"
echo "Check it with:  sha256sum $n.ova   (compare with README.txt, section 2)"
REOF
    chmod +x "$D/rejoin.sh"

    printf '@echo off\r\ncd /d "%%~dp0"\r\necho Joining %s parts into %s.ova ...\r\ncopy /b %s %s.ova >nul\r\nif errorlevel 1 (echo Joining failed. & pause & exit /b 1)\r\ndel %s.ova.part*\r\necho Done: %s.ova\r\necho Check it with:  certutil -hashfile %s.ova SHA256\r\npause\r\n' \
        "$NP" "$n" "$WIN" "$n" "$n" "$n" "$n" > "$D/rejoin.bat"

    cat > "$D/JOIN-PARTS.txt" <<JEOF
GitHub does not accept a single file larger than 2 GB, so the virtual
machine $n.ova was split into $NP parts for uploading.

Download ALL $NP files named  $n.ova.part000 ... part$(printf '%03d' $((NP-1)))
into one folder, together with README.txt and rejoin.sh / rejoin.bat.
Then put them back together:

  WINDOWS:      double-click  rejoin.bat
                (or in Command Prompt, in that folder:
                 copy /b $WIN $n.ova )

  LINUX / MAC:  bash rejoin.sh
                (or:  cat $n.ova.part* > $n.ova )

The result is ONE file:  $n.ova
Check it is complete (README.txt, section 2), then follow README.txt
to open it in VMware Workstation or VirtualBox.
JEOF

    # prove the parts rebuild the exact original
    A=$(cat "$D/$n.ova".part* | sha256sum | cut -d' ' -f1)
    O=$(grep -A1 "SHA-256 of" "$D/README.txt" | tail -1 | tr -d ' ')
    [ "$A" = "$O" ] && echo "   rejoin check: OK (matches README checksum)" || { echo "   rejoin check: MISMATCH"; exit 1; }
done
du -sh "$DEST"/*
echo "github-ova-done"
