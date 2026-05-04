# Migrating from SD Card to SSD

Running your homelab from an SD card works but SD cards wear out faster than SSDs under constant Docker write loads. This guide covers how to clone your entire setup from SD card to an SSD with zero data loss and no reinstallation required.

---

## Why Migrate?

- SD cards have limited write cycles and fail under heavy Docker workloads
- SSDs are significantly faster for random read/write operations
- An SSD will outlast an SD card many times over in a server context
- Signs your SD card is failing: `EXT4-fs error: bad block bitmap checksum` in `sudo dmesg`, random reboots, filesystem corruption

---

## Storage Options for Pi 5

| Option | Speed | Cost | Notes |
|---|---|---|---|
| USB 3.0 SSD | Fast | Low | Easiest, any USB SSD works |
| USB 3.0 Flash Drive | Medium | Very Low | Better than SD but still limited write cycles |
| NVMe HAT (PCIe) | Fastest | Medium | Best option, uses Pi 5's PCIe slot |

> ⚠️ If using NVMe, popular HATs include the Pimoroni NVMe Base and the Argon ONE V3 NVMe. Check compatibility with Pi 5 before purchasing.

---

## What Carries Over Perfectly

- ✅ All Docker containers
- ✅ All Docker volumes (Home Assistant config, n8n workflows, Nextcloud data, etc.)
- ✅ Your homelab compose file
- ✅ Tailscale config and authentication
- ✅ Netdata config
- ✅ All system settings and installed packages
- ✅ SSH keys and authorized users

---

## Prerequisites

- Your Pi running with the SD card setup you want to preserve
- A USB SSD, USB flash drive, or NVMe HAT connected to the Pi
- SSH access to the Pi

---

## Step 1 — Connect Your SSD

Plug your USB SSD into one of the **blue USB 3.0 ports** on the Pi (not the black USB 2.0 ports).

For NVMe, install the HAT with the Pi powered off, then power back on.

---

## Step 2 — Identify Your Devices

```bash
lsblk
```

You'll see output like:

```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
mmcblk0     179:0    0 119.1G  0 disk
├─mmcblk0p1  179:1    0   512M  0 part /boot/firmware
└─mmcblk0p2  179:2    0 118.6G  0 part /
sda           8:0    0 465.8G  0 disk
└─sda1        8:1    0 465.8G  0 part
```

- `mmcblk0` = your SD card
- `sda` = USB SSD
- `nvme0n1` = NVMe SSD (if using a HAT)

Note your SSD device name for the next step.

---

## Step 3 — Install rpi-clone

```bash
sudo apt install git -y
git clone https://github.com/billw2/rpi-clone.git
cd rpi-clone && sudo cp rpi-clone /usr/local/sbin
```

---

## Step 4 — Clone SD to SSD

Replace `sda` with your actual device name from Step 2:

```bash
# For USB SSD
sudo rpi-clone sda

# For NVMe SSD
sudo rpi-clone nvme0n1
```

rpi-clone will:
1. Partition the SSD to match your SD card
2. Copy all data across
3. Update the boot configuration automatically
4. Prompt you to confirm before making any changes

This takes anywhere from 5–30 minutes depending on how much data you have and the speed of your SSD.

---

## Step 5 — Reboot

```bash
sudo reboot
```

The Pi will restart. If the SSD is properly connected and the clone succeeded, it will boot from the SSD automatically.

---

## Step 6 — Verify Boot Device

After rebooting, SSH back in and confirm you’re booted from the SSD:

```bash
lsblk
```

Your root partition (`/`) should now be mounted from `sda2` or `nvme0n1p2` rather than `mmcblk0p2`.

Also check your Docker containers are all still running:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## Step 7 — Verify Everything Works

```bash
# Check disk usage on new drive
df -h

# Check all containers are running
docker ps

# Check Tailscale is still connected
tailscale status

# Check homepage is accessible
curl -s http://localhost:3005 | head -5
```

Open your Homepage dashboard in the browser to confirm everything is accessible.

---

## Optional — Remove SD Card

Once you’ve confirmed everything is working from the SSD, the SD card is no longer needed. You can:

- Remove it entirely (Pi 5 will boot from USB/NVMe without an SD card present)
- Keep it as a backup boot device
- Reuse it for something else

---

## Troubleshooting

### Pi still boots from SD card after clone
- Make sure the SSD was connected before running rpi-clone
- Check `lsblk` to confirm the SSD was detected
- On some setups you may need to update `/boot/firmware/config.txt` or run `sudo raspi-config` and set the boot order under **Advanced Options → Boot Order**

### Clone fails partway through
- Check the SSD has enough space: `lsblk -o NAME,SIZE`
- Try running with verbose output: `sudo rpi-clone sda -v`

### Docker containers not running after reboot
```bash
cd ~/homelab && docker compose up -d
```

### Tailscale not connected after reboot
```bash
sudo tailscale up
```

---

## Performance Comparison

After migrating you should notice:
- Faster container start times
- Faster Docker image pulls
- Faster Nextcloud file operations
- Lower risk of data corruption
- Better long-term reliability

For Ollama specifically, model load times improve significantly when running from NVMe vs SD card.
