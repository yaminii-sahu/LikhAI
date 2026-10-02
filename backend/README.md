# LIKH AI - Backend Service

AI-powered handwriting OCR preprocessing, recognition, and text digitization engine.

Tagline: **“Your handwriting. Digitized.”**

---

## Architecture

```text
Flutter Client
      │
      ▼
FastAPI Backend (port 8000)
      │
      ├── 1. Validation (File format, size, readable)
      ├── 2. Image Preprocessing (OpenCV: CLAHE contrast, bilateral denoising, deskewing, aspect-ratio scaling)
      ├── 3. Handwriting OCR (PaddleOCR PP-OCRv6)
      └── 4. AI Cleanup Layer (Gemini API / Ollama / Offline Heuristic NLP)
      │
      ▼
Structured JSON Response
```

---

## Quickstart

### 1. Set Up Virtual Environment

```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Run Backend Server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Server will be accessible at:
- **Local Machine / Flutter Windows / Web:** `http://127.0.0.1:8000`
- **Android Emulator:** `http://10.0.2.2:8000`
- **Network / Real Devices:** `http://<your-lan-ip>:8000`

---

## API Endpoints

### `GET /`
Basic system info and tagline.

### `GET /health`
Health check status and supported languages (`en`, `hi`, `auto`).

### `POST /preprocess`
Preprocesses an uploaded image (grayscale, CLAHE contrast, denoising, deskewing) without OCR.

### `POST /process`
Full digitization pipeline.

**Multipart Form Parameters:**
- `file`: The image file (JPG, PNG, WebP).
- `language`: Target language (`en`, `hi`, or `auto`).
- `title`: Optional document title.
- `preprocess`: Boolean (`true`/`false`).

**Response JSON Example:**
```json
{
  "success": true,
  "title": "Meeting Notes",
  "raw_text": "Meeting at 10 AM...",
  "cleaned_text": "Meeting at 10:00 AM...",
  "language": "en",
  "confidence": 0.98,
  "processing_time": 1.25,
  "warnings": [],
  "original_image_url": "http://127.0.0.1:8000/uploads/orig_xxx.png",
  "processed_image_url": "http://127.0.0.1:8000/uploads/proc_xxx.png"
}
```

---

## Optional Environment Variables

- `GEMINI_API_KEY`: Google Gemini API key for cloud LLM text cleanup.
- `OLLAMA_URL`: Local Ollama URL (default: `http://127.0.0.1:11434`).
- `OLLAMA_MODEL`: Ollama model name (default: `qwen2.5:0.5b`).
