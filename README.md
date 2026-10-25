# Kokoro TTS Deployment Automation Script<sup>®</sup>

This script can be used to create packages to be deployed into airgapped nodes. Modified to work for both x86_64 and Armv8.2-A ISA ([Broadcom BCM2712](https://github.com/raspberrypi/documentation/blob/master/documentation/asciidoc/computers/processors/bcm2712.adoc)) CPUs. The script can deploy the TTS engine with a fully featured front end on the host device or create packages which can be later deployed to isolated machines.

> [!CAUTION]
> * This script is designed to work with Debian<sup>®</sup> Linux only (you are welcomed to try on other `apt` based distributions).
> * Packages cannot be transferred between different CPU ISAs.
> * As for Arm support this script has been fully verified to work on the Raspberry Pi<sup>®</sup> 5 16G variant with a NVMe SSD as the main storage device.

<p align="center">
  <img src="https://raw.githubusercontent.com/SadBIOS/Kokoro-TTS-Airgapped/refs/heads/main/home_page.png" alt="How I Look Mate?" width="90%">
</p>

## Setting up Kokoro-TTS

> [!WARNING]
> Running commands/scripts from random people is a bad idea. With that being said,
> 
> HERE WE GO!

> [!NOTE]
> Every reference of `Node A` will mean the online/staging machine and `Node B` will be the offline/airgapped deployment machine.

### Download Create Offline Packages in `Node A`
On an internet connected machine run the following series of commands after downloading, extracting the repo and making the scripts executable with `chmod +x -v *.sh`
```bash
./setup.sh --build-offline-archive
```
The resulting archive will be around `12GB` transfer the root directory to the `$HOME` of `Node B` and continue with the next section (or you can install the package on the current host).

### Deploy Kokoro TTS on `Node B`
After copying all the data from `Node A` run the following and final command (you might need to run `chmod +x -v *.sh` again to make the scripts executable).
```bash
./setup.sh --deploy
```
Now navigate to the `IP:8080` of `Node B` and use it to your hearts content!

---

> [!CAUTION]
> In order to install this package on a Raspberry Pi one must follow the steps before running the commands described in the previous section.

<details>
<summary>Setting up the Raspberry Pi and installing essential packages</summary>

### 1. Force boot to *USB-MSD* overriding the interal boot drive
Set boot mode to usb (this is required if only a previous install exists on the same boot device).

```bash
sudo rpi-eeprom-config --edit
```
Change
```php
BOOT_ORDER=0xf146 
```
To
```php
BOOT_ORDER=0xf4
```
> [!NOTE]
> 6 = NVMe  
> 4 = USB  
> 1 = SD card  
> f = restart boot order loop

> [!TIP]
> ### In case Step 1 fails
> If the existing OS on the NVMe overrides USB-MSD even after updating the EEPROM:
>
> ```bash
> sudo dd if=/dev/zero of=/dev/nvme0n1 bs=64 status=progress
> ```
---
### 2. Bypass the current limit enforced by 3<sup>rd</sup> party adapters
There is a 5V 5A requirement enforced by the system. I have verified that the whole module (including the NVMe Hat) does not consume nearly that amount of power. Most normal usb adapters cap out at 3 amps at the 5V rail (I know it's not a rail rather a voltage level negotiated between the power supply and the device but I digress). Thus the official adapters have a special handshake that they do with the Renesas **DA9091** *“Gilmour”* PMIC.
```bash
sudo rpi-eeprom-config --edit
```
add this to the bottom of the document
```bash
PSU_MAX_CURRENT=5000
```
check if it working (expected output is ```throttled=0x0```)
```txt
vcgencmd get_throttled
```
---
### 3. Fan speed and optimizing thermals
Edit the following with superuser permissions (I am using the micro text editor, because I don't hate myself and I have nothing to prove).
```bash
sudo micro /boot/firmware/config.txt
```
add this at the end
```bash
dtparam=fan_temp1=45000
dtparam=fan_temp1_hyst=5000
dtparam=fan_speed1=127
```
> [!NOTE]
> Here temperature is in **millidegrees** *(1000 millidegrees = 1°C)*
> * ***fan_temp1*** is the first thermal zone (it continues as 2, 3, 4 and so on to build up a fan curve)
> * ***fan_temp1_hyst*** is the temperature hysteresis of the first thermal zone (to prevent rapid cycling as it **bang-bang** control)
> * ***fan_speed1*** is the first speed position in the **8-bit PWM (0~255)** controller it can also be stacked to form a temperature curve
---
### 4. Set usb max current ```not required for this```
Edit the following with superuser permissions (I am using the micro text editor. Again, I don't hate myself and I have nothing to prove).
```bash
sudo micro /boot/firmware/config.txt
```
Add this at the end
```bash
usb_max_current_enable=1
```
Check if it working (expected output is usb_max_current_enable=1)
```txt
vcgencmd get_config usb_max_current_enable
```
---
### 5. Speed boost for the PCIe Bus ```not required for µSD boot```
Check current bus speed
```bash
sudo lspci -vvv -s 0001:01:00.0 | grep -i Lnk
```
> [!NOTE]
>The following means it is running at PCIe Gen 2.0 x1 speeds
>* **LnkSta: Speed 5GT/s**
>
>While this means it is running at PCIe Gen 3.0 x1 speeds
>* **LnkSta: Speed 8GT/s**

Edit with superuser permissions (obviously **\*sign\*** with micro)
```bash
sudo micro /boot/firmware/config.txt
```
Add the following at the end
```bash
dtparam=pciex1_gen=3
```
---
### 6. Disable bluetooth and WiFi ```this is strictly not necessary```
Edit with superuser permissions (ykw I'm not saying this anymore)
```bash
sudo bash /boot/firmware/config.txt
```
Add the following at the end
```bash
dtoverlay=disable-wifi
dtoverlay=disable-bt
```
----
## Install os to NVMe
### 1. Cleanup packages
```bash
sudo apt autoremove
```
### 2. Verify boot drive
It should show ```/dev/sda2``` as it is currently USB-MSD. Use ```findmnt /``` to check the mount point.

### 3. Wipe NVMe drive
My case it's ```/dev/nvme0n1```
```bash
sudo wipefs -a /dev/nvme0n1
```
### 3. Wipe disk partitioning metadata
```bash
sudo sgdisk --zap-all /dev/nvme0n1
```
### 3. Clone os from USB-MSD to NVMe
```bash
sudo dd if=/dev/sda of=/dev/nvme0n1 bs=64M status=progress conv=fsync
```
### 4. Write all pending cache data to disk
```bash
sync
```
### 5. Finally set boot order to NVMe
```bash
sudo rpi-eeprom-config --edit
```
Set order to
```bash
BOOT_ORDER=0xf146 
```
</details>

---
## Local API Test
```bash
curl -X POST http://127.0.0.1:8000/v1/audio/speech \
  -H "Content-Type: application/json" \
  -o test.wav \
  -d '{
    "model": "kokoro",
    "voice": "jf_alpha",
    "input": "フレンチ・リック・クリークは、かつてこのモールがあった場所を流れており、そこには野生動物を引き寄せる泉があり、ネイティブ・アメリカンにとって重要な狩猟地でした。これらの泉は、18世紀にこの地域にやってきた最初のヨーロッパ人探検家や入植者によって後に利用されました。この場所は近くのカンバーランド川からの洪水に見舞われやすく、1830年代にドイツ移民が到着するまで定住することはありませんでした。ナッシュビルが恒久的な州都になると、州議事堂は敷地の南側の丘の上に建設されました。フレンチ・リック・クリークはゴミや未処理の下水で汚染され、後に水路化されてレンガ造りの下水道トンネルに埋められました。この地域は20世紀初頭に荒廃し、1949年の住宅法によって資金提供された大規模な都市再開発プロジェクトの一環として、敷地内および周辺の多くの建造物がその後取り壊されました。",
    "response_format": "wav"
  }'
```
---
## Remote API Test (Microsoft Windows<sup>®</sup> CMD)
```ruby
curl -X POST http://<IP_ADDR>:8000/v1/audio/speech -H "Content-Type: application/json" -o test.wav -d "{\"model\":\"kokoro\",\"voice\":\"jf_alpha\",\"input\":\"フレンチ・リック・クリークは、かつてこのモールがあった場所を流れており、そこには野生動物を引き寄せる泉があり、ネイティブ・アメリカンにとって重要な狩猟地でした。これらの泉は、18世紀にこの地域にやってきた最初のヨーロッパ人探検家や入植者によって後に利用されました。この場所は近くのカンバーランド 川からの洪水に見舞われやすく、1830年代にドイツ移民が到着するまで定住することはありませんでした。ナッシュビルが恒久的な州都になると、州議事堂は敷地の南側の丘の上に建設されました。フレンチ・リック・クリークはゴミや未処理の下水で汚染され、 後に水路化されてレンガ造りの下水道トンネルに埋められました。この地域は20世紀初頭に荒廃し、1949年の住宅法によって資金提供された大規模な都市再開発プロジェクトの一環として、敷地内および周辺の多くの建造物がその後取り壊されました。\",\"response_format\":\"wav\"}"
```
