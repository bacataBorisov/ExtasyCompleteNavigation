# Hardware Setup & NMEA Protocol

Technical details about the boat's instrument chain and the NMEA 0183 protocol as it applies to Extasy.

---

## Boat Instrument Chain

```
B&G Instruments (Triton 2 era)
    │
    ▼
B&G → NMEA 0183 Converter (eBay)
    │
    ▼
Level Shifter → Raspberry Pi (192.168.8.1)
    │
    ▼
WiFi Network "Extasy" (password: 123456789)
    │
    ▼
UDP Broadcast on port 4950
    │
    ▼
iOS App (CocoaAsyncSocket listener)
```

### Instruments on Board

| Instrument | Status | Notes |
|------------|--------|-------|
| Wind sensor (anemometer) | Working | Alternates TRUE/APPARENT every second string |
| Magnetic compass | Working | Was flashing between 220° and 0° periodically (needs real-conditions testing) |
| Depth sounder | Working | No temperature sensor data (MTW returns empty) |
| Speed log | Repaired | Cables were rusty, fixed by Ivan |
| GPS (integrated B&G) | Not working | Cables were cut. Using external GPS instead |
| External GPS | Working | Provides GGA, GLL, RMC. Does not output VTG |
| Sea water temperature | Not working | Possibly connected to depth meter, needs inspection |
| Autopilot | Not accessible | Uses FASTNET protocol (B&G proprietary), cannot communicate |

### Known Hardware Issues
- Level shifter cables were swapped initially — caused read failures
- WiFi broadcast from RPi was intermittent during early tests
- Speed log distance may need recalibration after cable repair
- GPS cables need permanent repair (were cut)

---

## Network Configuration

| Parameter | Value |
|-----------|-------|
| WiFi SSID | `Extasy` |
| WiFi Password | `123456789` |
| RPi IP Address | `192.168.8.1` |
| UDP Port | `4950` |
| Protocol | NMEA 0183 (ASCII over UDP) |
| Baud Rate | Standard (4800) — NMEA 0183HS uses 38400 for AIS |

### Troubleshooting
- **No data?** Check IP addresses first before anything else
- **Socket crashes?** CocoaAsyncSocket needs proper setup — crashes silently if misconfigured. Always close socket before reuse
- **Simulator issues?** Close socket on one instance before opening on another (simulator vs device)

---

## NMEA 0183 Protocol Reference

### Sentence Format

```
$ttsss,d1,d2,...*xx\r\n
```

| Part | Description |
|------|-------------|
| `$` | Start delimiter (always `$` for standard sentences, `!` for encapsulation) |
| `tt` | Talker ID — 2 characters identifying the instrument type |
| `sss` | Sentence format — 3 characters identifying the data type |
| `,d1,d2,...` | Comma-separated data fields |
| `*xx` | Checksum — XOR of all ASCII bytes between `$` and `*` (exclusive) |
| `\r\n` | Carriage return + line feed (0x0D 0x0A) |

### Talker IDs Used

| ID | Instrument |
|----|------------|
| `II` | Integrated Instrumentation (B&G system) |
| `GP` | GPS receiver |

### Checksum Calculation
- Bitwise XOR of all ASCII characters between `$` and `*` (not inclusive)
- Format as 2-digit uppercase hex: `String(format: "%02X", xorValue)`
- The `%02X` format is critical for single-digit results (e.g., `0A` not `A`)

### Sentences Handled by This App

**From Integrated Instruments (II):**

| Sentence | Data | Fields |
|----------|------|--------|
| DPT | Depth below transducer | depth, offset |
| HDG | Magnetic heading | heading, deviation, variation |
| MTW | Sea water temperature | temperature, unit (C) |
| MWV | Wind speed and angle | angle, reference (R/T), speed, unit, status |
| VHW | Water speed and heading | heading(T), heading(M), speed(kn), speed(km/h) |
| VLW | Distance travelled | total, since reset |

**From GPS (GP):**

| Sentence | Data | Fields |
|----------|------|--------|
| GGA | GPS fix | time, lat, lon, quality, satellites, HDOP, altitude |
| GLL | Geographic position | lat, lon, time, status |
| RMC | Recommended minimum | time, status, lat, lon, SOG, COG, date, variation |
| GSA | DOP and satellites | mode, fix type, satellite IDs, PDOP, HDOP, VDOP |
| GSV | Satellites in view | total messages, satellites, elevation, azimuth, SNR |

**Received but not processed:**

| Sentence | Data | Reason |
|----------|------|--------|
| RMB | Recommended navigation | Active when autopilot is on. Could compare with internal calculations |
| VTG | Track and ground speed | May not exist on this hardware. Active with autopilot |

### Important Protocol Notes

- We are a **listener only** — never transmit to devices
- `!` delimiter (encapsulation sentences) is not used
- Query sentences (`$ttllQ,sss`) are not used
- Proprietary sentences (`$P...`) are not used but may be added in future
- NMEA 2000 requires different hardware and software (Actisense NGW-1 Gateway for conversion)
- All connections should use twisted pair with shield connected at talker end only

### MWV Wind Sensor Behavior
The wind sensor alternates between TRUE and APPARENT wind on consecutive strings:
- Even strings: Apparent wind (reference = `R`)
- Odd strings: True wind (reference = `T`)

This means true wind can be read directly from the sensor rather than calculated, though the option for calculation should remain available.

### Coordinate Format
- NMEA sends: `DDMM.MMM` (latitude) and `DDDMM.MMM` (longitude)
- iOS `CLLocation` needs: decimal degrees
- Conversion: `degrees + (minutes / 60)`, negated for S/W directions

---

## Future Hardware Considerations

- **NMEA 2000**: Would require different converter and separate software module
- **AIS**: Uses NMEA-0183HS at 38400 baud with `!` delimiter
- **Autopilot integration**: Not possible without FASTNET protocol documentation from B&G
- **eINK display**: Tested but refresh rate too low for real-time navigation
- **iPad**: Preferred platform for visibility. Must test under direct sunlight
- Recommended: buy iPad with protective case and suitable mount/charger for the boat
