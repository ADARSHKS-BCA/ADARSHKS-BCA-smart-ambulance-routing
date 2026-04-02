# Smart Ambulance Routing — Emergency Coordination App

A Flutter mobile application for real-time emergency ambulance coordination with multilingual voice translation. Built with a premium UI design system derived from Google Stitch, this app provides a seamless voice-driven workflow for paramedics to coordinate patient transport to nearby hospitals.

---

## Features

### Emergency Workflow (UI Prototype)
- **Start Emergency** — Pulsating red button with unit status
- **Voice Input** — Animated mic with ripple effects and transcription
- **Patient Summary** — AI-generated assessment with vitals grid
- **Hospital Selection** — Sorted by ETA with bed availability
- **Navigation** — Turn-by-turn instructions with ETA overlay
- **Live Tracking** — Real-time countdown and trip progress

### Voice Translation (Full Stack)
- **Record audio** in any language using device microphone
- **Transcribe** using OpenAI Whisper (`gpt-4o-transcribe`)
- **Translate** to English using GPT-4o-mini
- **Display** original + translated text with latency metrics
- **States**: Idle → Recording → Processing → Result / Error

---

## Architecture

```
emergency_app/
├── lib/                          # Flutter Frontend
│   ├── main.dart
│   ├── theme/
│   │   └── app_theme.dart            # Design tokens (colors, spacing, shadows)
│   ├── services/
│   │   └── translation_api_service.dart  # HTTP client for backend
│   ├── widgets/
│   │   ├── widgets.dart              # Barrel export
│   │   ├── buttons.dart              # PrimaryButton, SecondaryButton, GhostButton
│   │   ├── cards.dart                # StatusCard, InfoTile
│   │   ├── hospital_card.dart        # HospitalCard
│   │   └── map_placeholder.dart      # Static map with route
│   └── screens/
│       ├── screens.dart              # Barrel export
│       ├── start_emergency_screen.dart
│       ├── voice_input_screen.dart
│       ├── voice_translation_screen.dart  # NEW — full-stack translation
│       ├── patient_summary_screen.dart
│       ├── hospital_selection_screen.dart
│       ├── navigation_screen.dart
│       └── live_tracking_screen.dart
│
├── backend/                      # Python FastAPI Backend
│   ├── run.py                        # Entry point (uvicorn)
│   ├── requirements.txt
│   ├── .env.example                  # Config template
│   └── app/
│       ├── main.py                   # FastAPI app factory
│       ├── config.py                 # Settings from .env
│       ├── routes/
│       │   └── transcribe.py         # POST /transcribe endpoint
│       ├── services/
│       │   └── openai_service.py     # Whisper + GPT async calls
│       └── utils/
│           ├── validation.py         # File type/size validation
│           └── cache.py              # In-memory TTL cache
│
└── test/
    └── widget_test.dart
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.35+)
- [Python](https://www.python.org/downloads/) (3.11+)
- [OpenAI API Key](https://platform.openai.com/api-keys)
- Chrome browser (for web) or Android device/emulator

### 1. Backend Setup

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Configure API key
cp .env.example .env
# Edit .env and set your OPENAI_API_KEY

# Start server
python run.py
```

Server runs at `http://localhost:8000`  
Swagger docs at `http://localhost:8000/docs`

### 2. Flutter Setup

```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Or run on Android
flutter run -d android
```

---

## API Reference

### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "service": "voice-translation-api",
  "version": "1.0.0"
}
```

### `POST /transcribe`
Upload an audio file for transcription and translation.

**Request:** `multipart/form-data` with `file` field  
**Supported formats:** `.wav`, `.mp3`, `.m4a`, `.webm`, `.ogg`, `.flac`  
**Max size:** 25 MB

**Response:**
```json
{
  "original": "Transcribed text in original language",
  "translated": "English translation of the text",
  "latency_ms": 2345,
  "cached": false
}
```

**Error codes:**
| Code | Meaning |
|------|---------|
| 400 | Invalid file type or empty file |
| 413 | File too large (>25 MB) |
| 429 | Rate limited (30 req/min) |
| 500 | Server error |

---

## Design System

Based on the **"Clinical Sanctuary"** theme from Google Stitch.

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#2563EB` | Actions, navigation |
| Background | `#F8FAFC` | App background |
| Critical Red | `#DC2626` | Emergency states |
| Success Green | `#16A34A` | Ready / available |
| Warning | `#F59E0B` | Caution indicators |
| Font | Inter | All typography |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.35+ / Dart |
| Backend | Python / FastAPI |
| Transcription | OpenAI Whisper (`gpt-4o-transcribe`) |
| Translation | OpenAI GPT-4o-mini |
| Caching | In-memory TTL (cachetools) |
| Rate Limiting | slowapi |

---

## Backend Features

- **Async processing** — All OpenAI calls use `AsyncOpenAI` for non-blocking I/O
- **Caching** — SHA-256 content hash with 10-min TTL cache for repeated inputs
- **Rate limiting** — 30 requests/minute per IP (configurable)
- **File validation** — Type, size, and emptiness checks before processing
- **Latency tracking** — Response includes `latency_ms` and `X-Process-Time-Ms` header
- **Structured logging** — Timestamped logs with module context
- **CORS** — Enabled for Flutter web/mobile clients
- **Error handling** — Global exception handler with typed error responses

---

## Author

**Adarsh KS** — BCA Student

## License

This project is for educational purposes.