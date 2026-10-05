#!/usr/bin/env python3
"""Make OVAs that import correctly in BOTH VMware and VirtualBox with no extra steps.

Starts from the tested OVA made by ovftool (VMware description, disks unchanged)
and adds VirtualBox's own settings section, vbox:Machine (ovf:required="false",
so VMware ignores it): EFI firmware, VMSVGA graphics, ICH AC97 sound, USB tablet,
Intel PRO/1000 network, the two disks on SATA ports 0/1. VirtualBox's defaults
would give BIOS boot (no start), VBoxVGA (no display) and HD Audio (silent).
The .mf checksums are recomputed; the archive keeps ovftool's GNU tar layout
(.ovf, .mf, disk1, disk2), needed because disk2 is larger than 8 GiB.
"""
import hashlib, re, sys, tarfile, uuid, io, os

EXPORT = "/home/student/Downloads/Android_16/export"
PROFILES = {"android16-desktop": (12288, 8), "android16-universal": (6144, 4)}

VBOX_MACHINE = '''    <vbox:Machine ovf:required="false" version="1.19-linux" uuid="{{{machine}}}" name="{name}" OSType="Linux26_64" snapshotFolder="Snapshots">
      <ovf:Info>Complete VirtualBox machine configuration in VirtualBox format</ovf:Info>
      <Hardware>
        <Memory RAMSize="{mem}"/>
        <HID Pointing="USBTablet"/>
        <Display controller="VMSVGA" VRAMSize="128"/>
        <Firmware type="EFI"/>
        <BIOS>
          <IOAPIC enabled="true"/>
          <SmbiosUuidLittleEndian enabled="true"/>
          <AutoSerialNumGen enabled="true"/>
        </BIOS>
        <USB>
          <Controllers>
            <Controller name="OHCI" type="OHCI"/>
          </Controllers>
        </USB>
        <Network>
          <Adapter slot="0" enabled="true" type="82540EM">
            <NAT localhost-reachable="true"/>
          </Adapter>
        </Network>
        <AudioAdapter controller="AC97" codec="AD1980" useDefault="true" driver="ALSA" enabled="true" enabledOut="true"/>
        <Clipboard/>
        <StorageControllers>
          <StorageController name="SATA" type="AHCI" PortCount="30" useHostIOCache="false" Bootable="true" IDE0MasterEmulationPort="0" IDE0SlaveEmulationPort="1" IDE1MasterEmulationPort="2" IDE1SlaveEmulationPort="3">
            <AttachedDevice type="HardDisk" hotpluggable="false" port="0" device="0">
              <Image uuid="{{{disk1}}}"/>
            </AttachedDevice>
            <AttachedDevice type="HardDisk" hotpluggable="false" port="1" device="0">
              <Image uuid="{{{disk2}}}"/>
            </AttachedDevice>
          </StorageController>
        </StorageControllers>
        <RTC localOrUTC="UTC"/>
        <CPU count="{cpus}">
          <HardwareVirtExLargePages enabled="false"/>
          <PAE enabled="false"/>
          <LongMode enabled="true"/>
          <X2APIC enabled="true"/>
        </CPU>
      </Hardware>
    </vbox:Machine>
'''

def build(name, mem, cpus):
    src = f"{EXPORT}/{name}_OVA/{name}.ova"
    dst_dir = f"{EXPORT}/{name}_OVA_new"
    os.makedirs(dst_dir, exist_ok=True)
    dst = f"{dst_dir}/{name}.ova"
    ids = {k: str(uuid.uuid4()) for k in ("machine", "disk1", "disk2")}

    with tarfile.open(src, "r:") as tin:
        members = tin.getmembers()
        assert [m.name for m in members] == [f"{name}.ovf", f"{name}.mf",
                f"{name}-disk1.vmdk", f"{name}-disk2.vmdk"], [m.name for m in members]
        ovf = tin.extractfile(members[0]).read().decode()
        mf = tin.extractfile(members[1]).read().decode()

        # 1. declare the vbox namespace
        ovf = ovf.replace('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
                          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
                          'xmlns:vbox="http://www.virtualbox.org/ovf/machine"', 1)
        # 2. tie each disk to the image ids used in vbox:Machine
        for d in ("vmdisk1", "vmdisk2"):
            key = "disk1" if d == "vmdisk1" else "disk2"
            ovf, n = re.subn(rf'(<Disk [^>]*ovf:diskId="{d}"[^>]*?)/>',
                             rf'\1 vbox:uuid="{ids[key]}"/>', ovf)
            assert n == 1, d
        # 3. VirtualBox settings, just before </VirtualSystem>
        block = VBOX_MACHINE.format(name=name, mem=mem, cpus=cpus, **ids)
        assert ovf.count("  </VirtualSystem>") == 1
        ovf = ovf.replace("  </VirtualSystem>", block + "  </VirtualSystem>")
        ovf_b = ovf.encode()

        # 4. manifest: new hash for the .ovf, disk hashes unchanged
        h = hashlib.sha256(ovf_b).hexdigest()
        mf = re.sub(rf"^SHA256\({re.escape(name)}\.ovf\)= [0-9a-f]+$",
                    f"SHA256({name}.ovf)= {h}", mf, flags=re.M)
        assert h in mf
        mf_b = mf.encode()

        # 5. repack: same order and GNU tar format as ovftool
        with tarfile.open(dst + ".tmp", "w:", format=tarfile.GNU_FORMAT) as tout:
            for m, data in ((members[0], ovf_b), (members[1], mf_b)):
                ti = tarfile.TarInfo(m.name); ti.size = len(data); ti.mode = 0o644
                ti.mtime = m.mtime
                tout.addfile(ti, io.BytesIO(data))
            for m in members[2:]:
                ti = tarfile.TarInfo(m.name); ti.size = m.size; ti.mode = 0o644
                ti.mtime = m.mtime
                print(f"   copying {m.name} ({m.size/2**30:.1f} GiB)", flush=True)
                tout.addfile(ti, tin.extractfile(m))
    os.replace(dst + ".tmp", dst)
    os.chmod(dst, 0o644)
    print(f"   -> {dst}")

for n, (mem, cpus) in PROFILES.items():
    if len(sys.argv) > 1 and n not in sys.argv[1:]:
        continue
    print(f"=== {n} ({mem} MB / {cpus} CPU)")
    build(n, mem, cpus)
print("build-done")
