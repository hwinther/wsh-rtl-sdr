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
# Scan the GSM band, looking for the strongest sender
kal -s GSM900


```

## FM

## ADS-B (aircraft)

## AIS (ship location)

## 433 IOT

## AMS (power meter OTA/IOT/mesh)

## Sources

- [Kali linux SDR guide](https://www.kalilinux.in/2021/11/begineers-guide-of-rtl-sdr.html)
- [NooElec NESDR v5 from Amazon](https://www.amazon.com/NooElec-NESDR-Smart-Bundle-R820T2-Based/dp/B01GDN1T4S)
- [NooElec NESDR v5 datasheet](https://www.nooelec.com/store/downloads/dl/file/id/111/product/342/nesdr_smart_rtl_sdr_v5_datasheet_revision_1.pdf)
- [Multipurpose dipole antenna kit](https://www.amazon.com/RTL-SDR-Blog-Multipurpose-Dipole-Antenna/dp/B075445JDF)
- [Custom/DIY antenna](https://www.rtl-sdr.com/tag/antenna/)
- [Reddit RTLSDR wiki](https://old.reddit.com/r/RTLSDR/wiki/index)
- [Interesting NG RTL-SDR LimeSDR, also comparison of HackRF, RTL-SDR and others](https://www.crowdsupply.com/lime-micro/limesdr)
