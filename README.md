# wsh-rtl-sdr

RTL-SDR wiki and code snippets

## Table of contents

- [wsh-rtl-sdr](#wsh-rtl-sdr)
  - [Table of contents](#table-of-contents)
  - [NooElec NESDR v5 kit quick overview](#nooelec-nesdr-v5-kit-quick-overview)
    - [Comes with 3 antennas](#comes-with-3-antennas)
    - [Most relevant specifications](#most-relevant-specifications)
  - [GSM (2G) - IMSI catcher](#gsm-2g---imsi-catcher)
    - [Prerequisites](#prerequisites)
    - [Steps](#steps)
    - [Links](#links)
  - [FM](#fm)
    - [Prerequisites](#prerequisites-1)
    - [Steps](#steps-1)
    - [Links](#links-1)
  - [TETRA (EU emergency band)](#tetra-eu-emergency-band)
    - [Prerequisites](#prerequisites-2)
    - [Steps](#steps-2)
    - [Links](#links-2)
  - [ADS-B (aircraft)](#ads-b-aircraft)
    - [Prerequisites](#prerequisites-3)
    - [Steps](#steps-3)
    - [Links](#links-3)
  - [AIS (ship location)](#ais-ship-location)
    - [Prerequisites](#prerequisites-4)
    - [Steps](#steps-4)
    - [Links](#links-4)
  - [433 IOT](#433-iot)
    - [Prerequisites](#prerequisites-5)
    - [Steps](#steps-5)
    - [Links](#links-5)
  - [AMS (power meter OTA/IOT/mesh)](#ams-power-meter-otaiotmesh)
    - [Prerequisites](#prerequisites-6)
    - [Steps](#steps-6)
    - [Links](#links-6)
  - [Generic links](#generic-links)

## NooElec NESDR v5 kit quick overview

### Comes with 3 antennas

- Telescopic antenna mast (variable frequency)
- 433MHz (ISM) antenna mast (fixed frequency)
- UHF antenna mast (fixed frequency)

### Most relevant specifications

- 0.5 PPM
- Max 3.2MSPS sample rate
- 0 - 49.6dB tuner gain
- 100 KHz to 25 MHz direct sampling tuning range
- 25 MHz - 1750 MHz quadrature sampling tuning range
- Operation supply current typical 300 mA, max 330 mA

## GSM (2G) - IMSI catcher

### Prerequisites

```bash
apt install gr-gsm kalibrate-rtl
```

### Steps

```bash
# Scan the "GSM900" band (aka P-GSM), alternatively "GSM-R" for railroad, "EGSM", or "DSC" (aka DCS) 1800 MHz. (The latter is out of range for the NESDR and most RTL-SDR devices.)
kal -s GSM900 -g 49.6

# Look for the strongest channel and use that as a parameter in the following command, note that -s 3.2M is also used to specify the highest available sample rate
grgsm_livemon -f 945.4M -g 49.6 -s 3.2M

# There is a grgsm_livemon_headless version but it's bugged in my kali install, livemon expects an X output and VNC is useful in this regard
# grgsm_livemon* will also send data to localhost on the lo interface, which various scripts/apps can use simultaneously, e.g.:

# Interactive inspection via wireshark in X
sudo wireshark -k -f udp -Y gsmtap -i lo

# Via the dedsecimsi tool, IMSI catcher
python tools/dedsecimsi/imsi.py

# SMS catcher (probably not going to see anything these days)
python tools/dedsecimsi/sms.py

# TODO: write an alternative implementation that translates MCC/MNC and displays network information (telenor station name etc)

```

### Links

- [GSM-R usage in Norway](https://no.wikipedia.org/wiki/GSM-R)
- [GSM usage in Norway](https://no.wikipedia.org/wiki/GSM)

## FM

### Prerequisites

```bash
apt install rtl-sdr
```

### Steps

To create a remote RTL connection via TCP, to get more up to date or device specific support you may want to find a fork of the librtlsdr repo and build it yourself:

```bash
rtl_tcp -a 10.20.30.40
```

Then connect to it via [HDSDR](https://www.hdsdr.de/) (windows) or a similar client

### Links

- [librtlsdr dev branch](https://github.com/librtlsdr/librtlsdr/tree/development)
- [librtlsdr fork](https://github.com/hayguen/librtlsdr/tree/development)

## TETRA (EU emergency band)

### Prerequisites

(Windows)
- SDR#
- TETRA Demodulator
- TETRA Network Monitor

(Linux)
- TETRA-kit

### Steps

First set up rtl_tcp if working remotely

```bash
rtl_tcp -a 10.20.30.40
```

Install TETRA plugins in SDR# plugins folder and add them, search for relevant channels in the spectrum used in your area (380-400 MHz in Norway)
Set radio type NFM and bandwidth 25.000, once a channel is selected the TETRA demodulator will show MCC, MNC++ check the net info window for further details on the cell properties.
You can also verify that you have found a TETRA channel with [audio samples](https://www.sigidwiki.com/wiki/Terrestrial_Trunked_Radio_(TETRA))

### Links

- [SDR#](https://airspy.com/download/)
- [tetra-kit](https://gitlab.com/larryth/tetra-kit)
- [TETRA wikipedia](https://en.wikipedia.org/wiki/Terrestrial_Trunked_Radio)
- [TETRA references](https://wiki.radioreference.com/index.php/TETRA)

## ADS-B (aircraft)

### Prerequisites

Either the distro dump1090, or the maintained FA version which can be found as a submodule under tools

```bash
# For dump1090
apt install TODO

# For dump978
apt install soapysdr-module-rtlsdr libsoapysdr-dev

```

### Steps

```bash
# As root, so either prepend sudo or run the following in a root shell

# Configure lighttpd to use dump1090-skyaware
cp tools/dump1090/debian/lighttpd/{88-dump1090-fa-statcache.conf,89-skyaware.conf} /etc/lighttpd/conf-available
pushd /etc/lighttpd/conf-enabled
ln -s ../conf-available/88-dump1090-fa-statcache.conf
ln -s ../conf-available/89-skyaware.conf
# if you have an older version of dump1090 via os packages you'll also want to unlink it:
# rm 89-dump1090.conf
popd

mkdir -p /usr/share/skyaware/html/
mkdir -p /run/dump1090-fa/
mkdir -p /run/skyaware978/
cp -r tools/dump1090/public_html/* /usr/share/skyaware/html/

systemctl restart lighttpd.service

pushd tools/dump1090
make
# Use --write-json if you want to use the web interface, --interactive for an updated list in the current console session or --net if you want to use ./view1090 to get an interactive output in another console session
./dump1090 --write-json /run/dump1090-fa/ --interactive
popd

# For 978 - which seems to not be in use in EU/Norway at this time
pushd tools/dump978
make
./dump978-fa --sdr driver=rtlsdr --format CS8 --raw-port 30978 --json-port 30979
./skyaware978 --connect localhost:30978 --reconnect-interval 30 --history-count 120 --history-interval 30 --json-dir /run/skyaware978/
popd
```

### Links

- [ADS info](http://www.ads-b.com/faq-9.htm)
- [Flightaware dump1090 ADS-B/ES](https://github.com/flightaware/dump1090)
- [Flightaware dump978 UAT](https://github.com/flightaware/dump978)

## AIS (ship location)

### Prerequisites

```bash
# Use rtl_ais submodule in tools folder
pushd tools/rtl_ais/
make
popd

flatpak install --user https://flathub.org/repo/appstream/org.opencpn.OpenCPN.flatpakref
```

### Steps

```bash
pushd tools/rtl_ais/
./rtl_ais -n -T
popd

# Start OpenCPN in another terminal with X available
flatpak run org.opencpn.OpenCPN

# Add local connection TCP host 127.0.0.1 and port 11010
# Update map data to get better resolution
```

### Links

- [RTL SDR AIS blobpost](https://www.klofas.com/blog/2021/ais-decoding-with-rtl-sdr-dongle/)
- [rtl-ais repo](https://github.com/dgiardini/rtl-ais)
- [OpenCPN download page](https://opencpn.org/OpenCPN/info/downloadopencpn.html)

## 433 IOT

### Prerequisites

```bash
# Fetch slightly outdated version via OS
apt install rtl-433

# Or github
cd tools/rtl_433
mkdir build && cd build && cmake ..
```

### Steps

```bash
# From path
rtl_433

# Running directly from tools folder after building
tools/rtl_433/build/src/rtl_433
```

### Links

- [RTL 433 github repo](https://github.com/merbanan/rtl_433)

## AMS (power meter OTA/IOT/mesh)

### Prerequisites

```bash
todo
```

### Steps

```bash
todo
```

### Links

- [RTL AMR github repo](https://github.com/bemasher/rtlamr)
- [NKOM AMS info](https://www.nkom.no/fysiske-nett-og-infrastruktur/elektromagnetisk-straling/_/attachment/download/e2080144-5414-455b-8c8e-add667c6ac5a:ce2b3f4e8b5973662d20692f3d04cb55ebc060d3/Avanserte%20m%C3%A5le-%20og%20styringssystemer%20-%20m%C3%A5ling%20av%20eksponering%20og%20sendetid.pdf)

## Generic links

- [Kali linux SDR guide](https://www.kalilinux.in/2021/11/begineers-guide-of-rtl-sdr.html)
- [NooElec NESDR v5 from Amazon](https://www.amazon.com/NooElec-NESDR-Smart-Bundle-R820T2-Based/dp/B01GDN1T4S)
- [NooElec NESDR v5 datasheet](https://www.nooelec.com/store/downloads/dl/file/id/111/product/342/nesdr_smart_rtl_sdr_v5_datasheet_revision_1.pdf)
- [Multipurpose dipole antenna kit](https://www.amazon.com/RTL-SDR-Blog-Multipurpose-Dipole-Antenna/dp/B075445JDF)
- [Custom/DIY antenna](https://www.rtl-sdr.com/tag/antenna/)
- [Reddit RTLSDR wiki](https://old.reddit.com/r/RTLSDR/wiki/index)
- [Interesting NG RTL-SDR LimeSDR, also comparison of HackRF, RTL-SDR and others](https://www.crowdsupply.com/lime-micro/limesdr)
- [RTL SDR custom drivers for HDSDR](https://github.com/hayguen?tab=repositories)
- [Osmocom RTL-SDR wiki](https://osmocom.org/projects/rtl-sdr/wiki/Rtl-sdr)
- [RTLSDR scanner - automatic frequency strength mapping](https://www.rtl-sdr.com/tag/rtlsdr-scanner/)
- [Web SDR](http://websdr.org/)
- [APRS satellite map](https://aprs.fi)
- [Signal identification guide](https://www.sigidwiki.com/wiki/Signal_Identification_Guide)
- [(Unofficial list of) Frequency usage in Norway](https://frekvenser.no/index.php)
- [Sending on the FM band with older RPI](https://medium.com/poka-techblog/a-newbies-guide-to-software-defined-radios-on-kali-linux-part-3-using-a-raspberrypi-as-a-85a336a5c62d)
