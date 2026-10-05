#!/bin/bash
# Write the user manual (README.txt) next to each final .ova.
# The checksum is computed from the .ova itself, so re-run this after any rebuild.
OUT=/home/student/Downloads/Android_16/export
for n in android16-desktop android16-universal; do
  D="$OUT/${n}_OVA"; F="$D/$n.ova"; [ -f "$F" ] || continue
  if [ "$n" = "android16-desktop" ]; then
    PROFILE="Desktop version"
    SPEC="12 GB memory and 8 processor cores for the virtual phone.
Best for computers with 16 GB of RAM or more."
    NEED="A 64-bit PC with 16 GB RAM or more, 8 CPU threads or more"
    VMWARE_VER="VMware Workstation 17.5 or newer (Pro or free edition)"
  else
    PROFILE="Universal version"
    SPEC="6 GB memory and 4 processor cores for the virtual phone.
Suits most computers, including ones with 8 GB of RAM (see below)."
    NEED="A 64-bit PC with 8 GB RAM or more, 4 CPU threads or more"
    VMWARE_VER="VMware Workstation / Player 16.2 or newer"
  fi
  echo "computing checksum of $n.ova ..."
  SUM=$(sha256sum "$F" | cut -d' ' -f1)
  SIZE=$(du -h "$F" | cut -f1)

  cat > "$D/README.txt" <<EOF
===========================================================================
  ANDROID 16 (LineageOS 23.2) - VIRTUAL PHONE FOR YOUR COMPUTER
  $PROFILE  -  user manual
===========================================================================

This folder contains two files:

  $n.ova      the complete virtual machine, in ONE file ($SIZE)
  README.txt  this manual

$SPEC

WHAT YOU GET
------------
  - Android 16 (LineageOS 23.2), 128 GB storage for apps and data
  - Google Play Store and Google services (Gmail, Maps, YouTube, ...)
  - ARM app support, so apps made only for phones can also run
  - Sound, mouse and keyboard work out of the box
  - Works in VMware Workstation and Oracle VirtualBox,
    on Windows, Linux and Intel Macs

Everything is already set up inside the .ova - there are no settings to
change, in either VMware or VirtualBox.


===========================================================================
 1. BEFORE YOU START
===========================================================================

You need:
  - $NEED
  - About 35 GB of free disk space
    (13 GB for the .ova, about 20 GB more once it is imported)
  - ONE of these programs (both are free):
      VMware Workstation  - $VMWARE_VER
                            https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion
      Oracle VirtualBox   - version 7.0 or newer (tested with 7.2)
                            https://www.virtualbox.org/

Hardware virtualization must be switched on:
  Most computers have it on already. If the program later says
  "VT-x is not available" or "virtualization is disabled", restart the
  computer, open the BIOS/UEFI setup (usually F2, F10, Del or Esc at
  start-up) and enable "Intel Virtualization Technology (VT-x)" or
  "AMD-V / SVM Mode".

Windows only - Hyper-V must be off:
  Hyper-V (also used by WSL2, Docker Desktop, Windows Sandbox and
  "Memory Integrity") slows down or blocks VMware and VirtualBox.
  To switch it off: open Command Prompt as Administrator, type
      bcdedit /set hypervisorlaunchtype off
  and restart Windows.
  (To turn it back on later: bcdedit /set hypervisorlaunchtype auto)

Apple Silicon Macs (M1/M2/M3/M4) cannot run this machine - it is built
for Intel/AMD (x86_64) processors.


===========================================================================
 2. CHECK THE FILE (optional, recommended after copying or downloading)
===========================================================================

A damaged copy will not import. To check it, compare its fingerprint with
the one below:

  SHA-256 of $n.ova:
  $SUM

  Windows (Command Prompt, in this folder):
      certutil -hashfile $n.ova SHA256
  Linux:
      sha256sum $n.ova
  Mac:
      shasum -a 256 $n.ova

The long code printed must match exactly. If it does not, copy the file
again (when copying to a USB stick, always use "Eject" / "Safely remove"
before unplugging, or the copy may be incomplete).


===========================================================================
 3. INSTALL IN VMWARE WORKSTATION
===========================================================================

  1. Open VMware Workstation.
  2. Menu  File -> Open...
  3. Select  $n.ova  and click Open.
  4. A window asks for a name and a place to store it.
       Name:  Android 16  (or anything you like)
       Storage path: any folder with about 20 GB free.
     Click  Import.
  5. Wait until the import finishes (a few minutes).
     If VMware shows a message that the file did not pass a format or
     specification check, click  Retry  - it then imports normally.
  6. Click  Power on this virtual machine  (the green play button).

The machine appears in VMware's Library on the left. From then on just
select it and press the play button.


===========================================================================
 4. INSTALL IN ORACLE VIRTUALBOX
===========================================================================

  1. Open VirtualBox.
  2. Menu  File -> Import Appliance...
  3. Select  $n.ova  and click Next (or Import).
  4. A summary of the settings is shown. Leave everything as it is,
     except the name if you want to change it. Click  Finish / Import.
  5. Wait until the import finishes (a few minutes).
  6. Select the new machine in the list and click  Start.

All needed settings (EFI start-up, graphics, sound, mouse) come from the
.ova itself - do not change them.


===========================================================================
 5. FIRST START
===========================================================================

What you will see:
  1. A boot menu with "LineageOS 23.2" - it starts by itself after
     3 seconds. (If the countdown has stopped, press Enter.)
  2. A few lines "Booting ... Loading ..." then a black screen
  3. The LineageOS animation
  4. The lock screen

The first start takes about 1 minute (up to 3 minutes on slower
computers). Later starts are faster.

Unlock:  click and drag upward on the lock screen.

The screen is a phone shape (portrait). Use the mouse like a finger:
click = tap, click-and-drag = swipe.

To get the mouse back to your own computer:
  VMware:      press  Ctrl + Alt
  VirtualBox:  press the right-hand  Ctrl  key


===========================================================================
 6. USING ANDROID
===========================================================================

Navigation:  the three buttons at the bottom -  <  back,  o  home,
             []  recent apps.

Google Play Store:
  Open Play Store and sign in with your Google account. Then install
  apps exactly as on a phone (WhatsApp, Telegram, Facebook, Instagram,
  ...). Messenger is already installed.

Internet:
  Works automatically through your computer's connection. Android shows
  it as a wired connection, not Wi-Fi.

Sound and volume:
  Sound plays through your computer's speakers or headphones.
  A virtual machine has no volume buttons, so no volume slider appears
  while a video plays. To change the volume:
    - use your own computer's volume control, or
    - Settings -> Sound & vibration -> Media volume, or
    - Settings -> Accessibility -> Accessibility Menu -> turn it on.
      A small button appears on screen; it gives Volume up / Volume
      down, Screenshot, Power and more.

Screenshot (saved to the Gallery):
  Recent apps button -> Screenshot, or the Accessibility Menu button.

No phone calls or SMS:
  This is a computer version of Android with no SIM card. Apps that
  need a phone number (e.g. WhatsApp) send the code to your real phone.


===========================================================================
 7. SHUTTING DOWN - IMPORTANT
===========================================================================

Always shut Android down properly, like a phone:
  - inside Android: Accessibility Menu -> Power -> Power off, or
  - VMware:      menu  VM -> Power -> Shut Down Guest
  - VirtualBox:  menu  Machine -> ACPI Shutdown

Do NOT use "Power Off" or close the window while Android is running.
That is like pulling the battery out and can damage the virtual disk.

Your apps and data are kept between starts.


===========================================================================
 8. IF SOMETHING GOES WRONG
===========================================================================

"VT-x is not available" / "virtualization disabled"
    Enable virtualization in the BIOS (see section 1). On Windows also
    switch off Hyper-V.

Stays at the boot menu
    Press Enter.

Black screen for a long time on first start
    Wait up to 3 minutes. On slow computers the first start is slow.

No sound
    Check your own computer's sound works (play any video on it) and is
    not muted. Then raise the volume inside Android (section 6).
    VirtualBox: the sound card must be "ICH AC97" (Settings -> Audio);
    it is set by the .ova, so only check it if it was changed.

Import fails / "file is damaged" / "error on read"
    The .ova is incomplete - check it (section 2) and copy it again.

Mouse does not move inside Android
    Click once inside the Android window.

Not enough memory (computer with 8 GB RAM)
    Before the first start, lower the memory of the virtual machine:
      VMware:      VM -> Settings -> Memory -> 4096 MB
      VirtualBox:  Settings -> System -> Base Memory -> 4096 MB
    Android still runs, a little slower.

Machine will not start after a sudden power cut
    VMware: if it says the disk "needs repair", allow the repair.
    Otherwise import the .ova again (your previous apps will be gone).


===========================================================================
 9. REMOVING IT
===========================================================================

  VMware:      right-click the machine -> Manage -> Delete from Disk
  VirtualBox:  right-click the machine -> Remove -> Delete all files

The .ova file stays, so you can install it again at any time.

===========================================================================
EOF
  echo "  README.txt -> ${n}_OVA/"
done
