# RFID Access Control System

An end-to-end IoT access control system built with Arduino firmware, a Rust/Axum backend, and a Flutter dashboard. RFID cards are scanned at the hardware level, access decisions are made in real time, and every event is logged to a database and streamed live to the frontend.

---

## System Architecture

```
┌─────────────────────────────────┐
│           Arduino Uno R3        │
│                                 │
│  RC522 (RFID) ──► Access Logic  │
│  LCD1602       ◄── Status Msg   │
│  Servo Motor   ◄── Lock Control │
│  Buzzer        ◄── Audio Alert  │
│                                 │
│  Serial Output ──► /dev/ttyACM0 │
└────────────────┬────────────────┘
                 │ Serial (9600 baud)
                 ▼
┌─────────────────────────────────┐
│       Rust / Axum Backend       │
│                                 │
│  Serial Reader (blocking thread)│
│  SQLite (access_log table)      │
│  SSE endpoint  ──► live stream  │
│  GET /log      ──► JSON history │
└────────────────┬────────────────┘
                 │ HTTP + SSE
                 ▼
┌─────────────────────────────────┐
│       Flutter Dashboard         │
│                                 │
│  SSE client  ◄── live updates   │
│  DataTable   ──► access log     │
└─────────────────────────────────┘
```

---

## Hardware Components
<img width="1215" height="796" alt="image" src="https://github.com/user-attachments/assets/c1918764-f0dc-4336-a130-99772a13e0b6" />

| Component | Role |
|---|---|
| Arduino Uno R3 | Microcontroller |
| RC522 RFID Module | Card/tag reading via SPI |
| LCD1602 (16x2) | Status display |
| Potentiometer | LCD contrast control |
| Servo Motor SG90 | Lock simulation |
| Active Buzzer | Audio feedback |

### Wiring

| RC522 Pin | Arduino Pin |
|---|---|
| SDA | D10 |
| SCK | D13 |
| MOSI | D11 |
| MISO | D12 |
| RST | D9 |
| VCC | **5V** (not 3.3V — most clones require 5V) |
| GND | GND |

> **Note:** Despite the label on most RC522 clone modules, powering from 5V is required. Powering from 3.3V causes intermittent communication failures.

---

## Project Structure

```
rfid-access-control/
├── firmware/
│   └── security_system.ino        # Arduino sketch
│   └── access.cpp                 # Determine access control
│   └── SessionState.cpp           # Keep track of the state of all the components
├── backend/
│   ├── src/
│   │   └── main.rs         # Axum server
│   │   └── db.rs           # Serial reader and port connection
│   │   └── hardware.rs     # SQL connectin and quries
│   ├── Cargo.toml
│   └── access.db           # SQLite database
└── frontend/
    └── lib/
        └── main.dart       # Flutter dashboard
```

---

## Backend

Built with **Rust**, using:
- [`axum`](https://github.com/tokio-rs/axum) — async HTTP framework
- [`sqlx`](https://github.com/launchbadge/sqlx) — async SQLite (swappable to Postgres by changing connection string and feature flag)
- [`serialport`](https://github.com/serialport/serialport-rs) — serial communication with Arduino
- [`tokio`](https://tokio.rs/) — async runtime
- [`chrono`](https://github.com/chronotope/chrono) — timestamps

### Serial message format

The Arduino sends newline-terminated strings in the following format:

```
CARD_ACCEPT - 04:A3:21:FF
CARD_DECLINE - 01:B2:33:AA
```

### API Endpoints

| Method | Route | Description |
|---|---|---|
| `GET` | `/` | Returns full access log as JSON array |
| `GET` | `/sse` | SSE stream, pushes new events as they arrive |

### Running the backend

```bash
cd backend
cargo run
```

The server listens on `http://0.0.0.0:3000`. The SQLite database is created automatically on first run.

---

## Firmware

Written in C++ for the Arduino platform. Dependencies:

- `MFRC522` by miguelbalboa
- `LiquidCrystal` (built-in)
- `Servo` (built-in)

### Access logic

Authorized UIDs are stored as an array in the sketch. On scan:
- **Authorized card** → servo opens lock, LCD shows "Access Granted", and sounds: *beep boop*
- **Unknown card** → servo closes lock, LCD shows "Access Denied", and sounds: *boop beep*
- Event is sent over Serial to the backend in `STATUS - UID` format

---

## Frontend

Built with **Flutter**. Connects to the backend SSE stream for live updates and displays the access log in a sortable data table.

```bash
cd frontend
flutter run
```

### Demo
![low_size](https://github.com/user-attachments/assets/081dbc42-ebd2-47cc-8484-dc58fa2f6b22)

