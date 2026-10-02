# LIKH AI

**Your handwriting. Digitized.**

LIKH AI is an AI-powered handwriting digitization application that converts handwritten notes into clean, editable digital text and formatted PDFs. It bridges the physical-digital divide by combining high-precision computer vision preprocessing, state-of-the-art OCR models, and intelligent language model post-processing.

---

## Features

- **Handwriting Digitization:** Convert messy, cursive, or print handwriting into clean digital text.
- **Camera & Image Import:** Capture notes directly via camera or import photos/scans from gallery.
- **Advanced Preprocessing Pipeline:** Automatic grayscale conversion, CLAHE adaptive contrast enhancement, bilateral noise filtering, and deskewing.
- **State-of-the-Art OCR:** Powered by PaddleOCR (PP-OCRv6) with high-accuracy character recognition.
- **AI-Assisted Text Cleanup:** Contextual grammar, punctuation, and handwriting artifact correction via Google Gemini API, Ollama (local LLM), or built-in offline NLP heuristics.
- **Rich In-App Text Editor:** Live editing, word and character counts, copy to clipboard, and instant document renaming.
- **PDF Generation & Export:** Export digitized notes into professional PDF documents with customizable layouts.
- **Offline Document Storage:** Local document history, search, and management using encrypted on-device storage.
- **Adaptive Light & Dark Branding:** Official LIKH AI brand system with dedicated Light Mode and Dark Mode visual themes.
- **Cross-Platform Responsive UI:** Optimized layouts for mobile phones, tablets, and desktop displays.
- **Multilingual Support:** English and Hindi handwriting recognition.

---

## Tech Stack

- **Frontend:**
  - **Flutter & Dart:** Cross-platform UI toolkit.
  - **Provider:** State management.
  - **SharedPreferences:** Local persistent storage for documents and preferences.
  - **PDF & Printing:** Native PDF generation and print dispatching.
  - **Image Picker:** Camera and gallery integration.
- **Backend:**
  - **FastAPI (Python 3.10+):** Asynchronous, high-performance REST API.
  - **PaddleOCR (PP-OCRv6):** Multilingual handwriting recognition engine.
  - **OpenCV & Pillow:** Computer vision algorithms for image enhancement and binarization.
  - **Google Gemini API / Ollama:** Optional LLM post-processing for contextual corrections.
  - **Uvicorn:** ASGI production web server.

---

## Project Structure

```text
likh_ai/
├── lib/                         # Flutter client source code
│   ├── core/                    # Core configuration, constants, and themes
│   │   ├── constants/           # App colors, styles, and typography
│   │   └── theme/               # Light and Dark theme definitions
│   ├── models/                  # Data models (Document, OCR Response, etc.)
│   ├── providers/               # Application state providers
│   ├── screens/                 # UI screens (Home, Capture, Processing, Editor, Settings)
│   ├── services/                # API client, PDF generation, and local storage services
│   └── widgets/                 # Reusable UI widgets and official LIKH AI brand logo system
├── assets/                      # Application assets
│   └── branding/                # Official LIKH AI vector logos and mark assets
├── backend/                     # FastAPI handwriting OCR service
│   ├── app/
│   │   ├── ai_cleaner.py        # Gemini, Ollama, and offline NLP text post-processors
│   │   ├── ocr_engine.py        # PaddleOCR pipeline manager and inference engine
│   │   └── preprocessor.py      # OpenCV contrast, noise removal, and deskewing
│   ├── main.py                  # FastAPI application entrypoint and routes
│   └── requirements.txt         # Python backend dependencies
├── test/                        # Flutter unit and widget test suites
├── android/                     # Android native platform code and manifest
├── ios/                         # iOS native platform code
└── web/                         # Web configuration and assets
```

---

## Setup & Getting Started

### Prerequisites

- **Flutter SDK:** version 3.24 or higher ([flutter.dev](https://flutter.dev))
- **Python:** version 3.10 to 3.13 ([python.org](https://python.org))
- **Git**

---

### 1. Backend Setup (FastAPI)

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate a Python virtual environment:
   * **Windows (PowerShell):**
     ```powershell
     python -m venv venv
     .\venv\Scripts\Activate.ps1
     ```
   * **macOS / Linux:**
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

3. Install required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables (Optional):
   Copy `.env.example` to `.env` in the project root:
   ```bash
   cp ../.env.example ../.env
   ```
   * Set `GEMINI_API_KEY` to enable Google Gemini cloud text correction.
   * If not set, LIKH AI automatically falls back to local Ollama or high-speed offline heuristic NLP.

5. Start the backend server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
   The backend API will be available at `http://127.0.0.1:8000` (API docs at `http://127.0.0.1:8000/docs`).

---

### 2. Frontend Setup (Flutter)

1. From the project root, install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run static analysis to verify code health:
   ```bash
   flutter analyze
   ```

3. Run the test suite:
   ```bash
   flutter test
   ```

4. Launch the application:
   * **Windows Desktop / Chrome Web:**
     ```bash
     flutter run
     ```
   * **Android Emulator / Device:**
     ```bash
     flutter run
     ```

---

## Backend Configuration

The Flutter app automatically discovers the local backend on startup. You can also explicitly configure the backend URL:

### Method A: Compile-Time Configuration (`dart-define`)

When launching or building the Flutter app, pass the `BACKEND_URL`:

```bash
# Local development on Windows / macOS / Web:
flutter run --dart-define=BACKEND_URL=http://127.0.0.1:8000

# Android Emulator (10.0.2.2 maps to host machine):
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000

# Physical Device on local Wi-Fi:
flutter run --dart-define=BACKEND_URL=http://192.168.1.100:8000
```

### Method B: In-App Settings

You can also change the backend server IP directly inside the app:
1. Open LIKH AI and go to the **Profile / Settings** screen.
2. Enter your server's IP address and port.
3. Tap **Save & Test Connection**.

---

## Development & Contribution

1. Ensure all code passes static analysis:
   ```bash
   flutter analyze
   ```
2. Run automated tests before committing:
   ```bash
   flutter test
   ```
3. Follow effective Dart formatting:
   ```bash
   dart format .
   ```

---

## License

This project is licensed under the MIT License. See `LICENSE` for details.
