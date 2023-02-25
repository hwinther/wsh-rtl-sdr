# wsh-rtl-sdr
RTL-SDR wiki and code snippets

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
grgsm_livemon -f 945.4M -g 49.g -s 3.2M

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

## ADS-B (aircraft)

## AIS (ship location)

## 433 IOT

## AMS (power meter OTA/IOT/mesh)

## Generic links

- [Kali linux SDR guide](https://www.kalilinux.in/2021/11/begineers-guide-of-rtl-sdr.html)
- [NooElec NESDR v5 from Amazon](https://www.amazon.com/NooElec-NESDR-Smart-Bundle-R820T2-Based/dp/B01GDN1T4S)
- [NooElec NESDR v5 datasheet](https://www.nooelec.com/store/downloads/dl/file/id/111/product/342/nesdr_smart_rtl_sdr_v5_datasheet_revision_1.pdf)
- [Multipurpose dipole antenna kit](https://www.amazon.com/RTL-SDR-Blog-Multipurpose-Dipole-Antenna/dp/B075445JDF)
- [Custom/DIY antenna](https://www.rtl-sdr.com/tag/antenna/)
- [Reddit RTLSDR wiki](https://old.reddit.com/r/RTLSDR/wiki/index)
- [Interesting NG RTL-SDR LimeSDR, also comparison of HackRF, RTL-SDR and others](https://www.crowdsupply.com/lime-micro/limesdr)
