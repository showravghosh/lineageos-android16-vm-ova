#!/bin/bash
# README, verify and one-click installers for the OVA folders.
# The installers are the tested OVF ones, pointed at the .ova instead, with the
# file check done against <name>.ova.sha256 (an OVA carries its manifest inside).
OUT=/home/student/Downloads/Android_16/export
for n in android16-desktop android16-universal; do
  D="$OUT/${n}_OVA"; [ -d "$D" ] || continue
  if [ "$n" = "android16-desktop" ]; then SPEC="12 GB RAM / 8 CPU cores - for PCs with 16 GB RAM or more, VMware Workstation 17.5+"
  else SPEC="6 GB RAM / 4 CPU cores - suits most PCs, older VMware and Player too"; fi

  # --- installer (Linux/Mac) ------------------------------------------
  sed -e 's/OVF=$(ls \*\.ovf 2>\/dev\/null | head -1)/OVF=$(ls *.ova 2>\/dev\/null | head -1)/' \
      -e 's/NAME="${OVF%\.ovf}"/NAME="${OVF%.ova}"/' \
      "$OUT/$n/INSTALL-AND-RUN.sh" > "$D/INSTALL-AND-RUN.sh"
  python3 - "$D/INSTALL-AND-RUN.sh" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
s=re.sub(r"# --- join split parts.*?\nfi\n\n", "", s, flags=re.S)
old=s[s.index("# --- check the files are intact"):s.index("# --- check the computer")]
new='''# --- check the file is intact ----------------------------------------
if [ -f "$OVF.sha256" ]; then
    echo "Checking the file (takes a minute)..."
    if ! sha256sum -c "$OVF.sha256" >/dev/null 2>&1; then
        echo "  The .ova file is damaged. Please copy or download it again."
        exit 1
    fi
fi

'''
s=s.replace(old,new)
assert "ls *.ova" in s and "${OVF%.ova}" in s and ".ovf" not in s, "installer conversion failed"
open(p,"w").write(s)
PY
  chmod +x "$D/INSTALL-AND-RUN.sh"

  # --- installer (Windows) --------------------------------------------
  python3 - "$OUT/$n/INSTALL-AND-RUN.bat" "$D/INSTALL-AND-RUN.bat" <<'PY'
import sys,re
s=open(sys.argv[1]).read()
s=re.sub(r'if exist "%NAME%-disk1\.vmdk\.gz\.part000" \(.*?\n\)\n\n', "", s, flags=re.S)
s=s.replace('"%NAME%.ovf"','"%NAME%.ova"')
assert '.ovf"' not in s and '"%NAME%.ova"' in s, "bat conversion failed"
open(sys.argv[2],"w").write(s)
PY

  # --- verify ---------------------------------------------------------
  cat > "$D/verify.sh" <<VEOF
#!/bin/bash
# Check that the .ova arrived undamaged.
cd "\$(dirname "\$0")"
echo "Checking $n.ova (takes a minute)..."
if sha256sum -c "$n.ova.sha256"; then
    echo; echo "The file is intact. You can import the .ova now."
else
    echo; echo "The file is damaged. Copy or download it again."; exit 1
fi
VEOF
  chmod +x "$D/verify.sh"

  # --- README ---------------------------------------------------------
  cat > "$D/README.txt" <<REOF
Android 16 (LineageOS 23.2) - virtual machine, OVA version
==========================================================

$SPEC

Google Play Store and Google services included, plus ARM app translation
so ARM-only apps run. Works in VMware Workstation / Player, VirtualBox and
on Linux, Windows and Intel Macs.


WHAT IS IN THIS FOLDER
----------------------
  $n.ova            the whole virtual machine in ONE file
  $n.ova.sha256     checksum, used to detect a damaged copy
  INSTALL-AND-RUN   one click: checks, imports and starts it
  verify.sh         checks the .ova is undamaged (Linux/Mac)

The same machine also exists as an OVF folder (several files). Both work
the same - use whichever you prefer.


EASIEST WAY
-----------
  Windows:      double-click  INSTALL-AND-RUN.bat
  Linux / Mac:  bash INSTALL-AND-RUN.sh

It finds VirtualBox or VMware, imports the machine with the right
settings and starts it.


VMWARE WORKSTATION / PLAYER
---------------------------
  File -> Open...  ->  select  $n.ova  ->  Import  ->  Power on

Nothing else to set.


ORACLE VIRTUALBOX
-----------------
  File -> Import Appliance...  ->  select  $n.ova  ->  Import

  Then, BEFORE starting it, change these settings (the first two are
  needed to boot, the third gives sound):

    Settings -> System -> Motherboard  ->  tick "Enable EFI"
    Settings -> Display -> Screen      ->  Graphics Controller: VMSVGA
    Settings -> Audio                  ->  Audio Controller: ICH AC97

  Recommended as well:
    Settings -> Display -> Video Memory: 128 MB
    Settings -> Input/Motherboard -> Pointing Device: USB Tablet

  (INSTALL-AND-RUN does all of this automatically.)


USING IT
--------
First start takes about a minute. Sign in to the Play Store with a
Google account to install apps.

Shut it down from inside Android (power menu), or:
  VMware:     VM -> Power -> Shut Down Guest
  VirtualBox: Machine -> ACPI Shutdown

Avoid "Power Off" or closing the window while it runs. That is the
equivalent of pulling the plug and can damage the virtual disk.


SOUND AND VOLUME
----------------
Sound works in VMware and VirtualBox (VirtualBox: ICH AC97 sound card).

A virtual machine has no volume buttons, so Android shows no volume
slider while a video plays. To change the volume:
  - the speaker icon of your own computer, or
  - Settings -> Sound & vibration -> Media volume, or
  - Settings -> Accessibility -> Accessibility Menu -> turn on; its
    on-screen button gives Volume up / Volume down.


SPACE NEEDED
------------
About 13 GB for the .ova, plus about 20 GB once imported.
REOF
  echo "  OVA helpers -> ${n}_OVA/"
done
