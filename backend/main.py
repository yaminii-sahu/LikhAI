import os
import time
import uuid
import shutil
import asyncio
from typing import Optional

# Disable oneDNN / MKL-DNN and PIR runtime issues on Windows CPU configurations BEFORE importing paddle
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["FLAGS_enable_mkldnn"] = "0"
os.environ["FLAGS_enable_pir_api"] = "0"
os.environ["PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT"] = "0"
os.environ["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"

from fastapi import FastAPI, UploadFile, File, Form, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.concurrency import run_in_threadpool

from app.preprocessor import validate_image_file, preprocess_handwriting_image
from app.ocr_engine import ocr_engine
from app.ai_cleaner import ai_cleaner

# --------------------------------------------------
# APP SETUP
# --------------------------------------------------

app = FastAPI(
    title="LIKH AI Backend",
    description="Handwriting OCR, Image Preprocessing & AI Text Digitization API",
    version="1.0.0"
)

# Upload directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")
os.makedirs(UPLOADS_DIR, exist_ok=True)

# Mount static files for image access
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

# --------------------------------------------------
# CORS CONFIGURATION
# --------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for local dev, Android emulator, physical devices, Web
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# --------------------------------------------------
# STARTUP EVENT: WARM UP OCR ENGINE
# --------------------------------------------------

@app.on_event("startup")
async def startup_event():
    """Warms up the PaddleOCR model during server startup so user requests never experience model loading lag."""
    print("\n[Startup] Initializing and warming up PaddleOCR handwriting model...")
    try:
        import numpy as np
        import cv2
        dummy = np.ones((64, 256, 3), dtype=np.uint8) * 255
        cv2.putText(dummy, "LikhAI", (10, 42), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 0), 2)
        dummy_path = os.path.join(UPLOADS_DIR, "_warmup.png")
        cv2.imwrite(dummy_path, dummy)

        # Run warm-up inference in background threadpool
        await run_in_threadpool(ocr_engine.ocr_en.predict, dummy_path)

        if os.path.exists(dummy_path):
            os.remove(dummy_path)
        print("[Startup] PaddleOCR warm-up completed successfully. Ready for inference!\n")
    except Exception as e:
        print(f"[Startup] Warm-up notice: {e}\n")

# --------------------------------------------------
# HEALTH & INFO ENDPOINTS
# --------------------------------------------------

@app.get("/")
def home():
    return {
        "status": "online",
        "app": "LIKH AI",
        "tagline": "Your handwriting. Digitized.",
        "version": "1.0.0",
        "supported_languages": ["en", "hi", "auto"]
    }

@app.get("/health")
def health():
    """Ultra-fast health check endpoint (< 2ms) without loading or running models."""
    return {
        "status": "healthy",
        "ocr_engine": "PaddleOCR PP-OCRv6",
        "supported_languages": ["English", "Hindi", "Auto-Detect"],
        "uploads_dir": os.path.exists(UPLOADS_DIR)
    }

# --------------------------------------------------
# PREPROCESS ENDPOINT
# --------------------------------------------------

@app.post("/preprocess")
async def preprocess_endpoint(
    request: Request,
    file: UploadFile = File(...)
):
    start_time = time.time()
    file_id = uuid.uuid4().hex
    raw_ext = os.path.splitext(file.filename or ".jpg")[1].lower() or ".jpg"
    orig_filename = f"orig_{file_id}{raw_ext}"
    proc_filename = f"proc_{file_id}.png"

    orig_path = os.path.join(UPLOADS_DIR, orig_filename)
    proc_path = os.path.join(UPLOADS_DIR, proc_filename)

    try:
        # Non-blocking file save
        def _save_file():
            with open(orig_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
        await run_in_threadpool(_save_file)

        is_valid, error_msg = await run_in_threadpool(validate_image_file, orig_path)
        if not is_valid:
            if os.path.exists(orig_path):
                os.remove(orig_path)
            return {
                "success": False,
                "error": error_msg or "Invalid image file."
            }

        prep_result = await run_in_threadpool(
            preprocess_handwriting_image,
            input_path=orig_path,
            output_path=proc_path,
            enhance_contrast=True,
            denoise=True,
            binarize=False,
            deskew=True
        )

        base_url = str(request.base_url).rstrip("/")
        return {
            "success": True,
            "original_image_url": f"{base_url}/uploads/{orig_filename}",
            "processed_image_url": f"{base_url}/uploads/{proc_filename}",
            "operations": prep_result.get("operations", []),
            "dimensions": prep_result.get("processed_dimensions", {}),
            "processing_time": round(time.time() - start_time, 2)
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Preprocessing failed: {str(e)}"
        }

# --------------------------------------------------
# MAIN PROCESS ENDPOINT (NON-BLOCKING + BENCHMARKS)
# --------------------------------------------------

@app.post("/process")
async def process_document(
    request: Request,
    file: UploadFile = File(...),
    language: Optional[str] = Form("auto"),
    title: Optional[str] = Form(None),
    preprocess: Optional[bool] = Form(True)
):
    start_total_time = time.time()
    file_id = uuid.uuid4().hex
    raw_ext = os.path.splitext(file.filename or ".jpg")[1].lower() or ".jpg"
    orig_filename = f"orig_{file_id}{raw_ext}"
    proc_filename = f"proc_{file_id}.png"

    orig_path = os.path.join(UPLOADS_DIR, orig_filename)
    proc_path = os.path.join(UPLOADS_DIR, proc_filename)

    try:
        # 1. Non-blocking file save in threadpool
        save_start = time.time()
        def _save_file():
            with open(orig_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
        await run_in_threadpool(_save_file)
        save_time = time.time() - save_start

        file_size_kb = os.path.getsize(orig_path) / 1024.0

        print(f"[LIKH OCR] Backend received image: {file.filename} ({file_size_kb:.1f} KB) in {save_time:.3f}s")

        # 2. Validate image file (size, format, integrity)
        is_valid, error_msg = await run_in_threadpool(validate_image_file, orig_path)
        if not is_valid:
            if os.path.exists(orig_path):
                os.remove(orig_path)
            return {
                "success": False,
                "error": error_msg or "Invalid image format or unreadable file.",
                "raw_text": "",
                "cleaned_text": "",
                "confidence": 0.0,
                "cleanup_applied": False
            }

        # 3. Preprocess image in threadpool
        prep_time = 0.0
        ocr_input_path = orig_path
        fallback_path = None
        applied_ops = []
        quality_info = {}
        all_warnings = []

        if preprocess:
            print("[LIKH OCR] Image preprocessing started")
            prep_start = time.time()
            try:
                prep_result = await asyncio.wait_for(
                    run_in_threadpool(
                        preprocess_handwriting_image,
                        input_path=orig_path,
                        output_path=proc_path,
                        enhance_contrast=True,
                        denoise=True,
                        binarize=False,
                        deskew=True,
                        attenuate_lines=False,
                        remove_shadows=True
                    ),
                    timeout=20.0
                )
                ocr_input_path = proc_path
                fallback_path = prep_result.get("binary_path")
                applied_ops = prep_result.get("operations", [])
                quality_info = prep_result.get("quality_analysis", {})
                if quality_info and "warnings" in quality_info:
                    all_warnings.extend(quality_info["warnings"])
            except asyncio.TimeoutError:
                print("[LIKH OCR] Image preprocessing timed out; falling back to original image.")
                all_warnings.append("Image preprocessing was skipped to speed up response.")
                ocr_input_path = orig_path
            except Exception as pe:
                print(f"[LIKH OCR] Preprocessing skipped due to error: {pe}")
                ocr_input_path = orig_path
            prep_time = time.time() - prep_start
            print(f"[LIKH OCR] Image preprocessing completed in {prep_time:.2f}s")

        # 4. Handwriting OCR in threadpool (generous 70-second stage timeout)
        print("[LIKH OCR] OCR started")
        ocr_start = time.time()
        lang_choice = (language or "auto").strip().lower()
        try:
            ocr_result = await asyncio.wait_for(
                run_in_threadpool(
                    ocr_engine.extract_text,
                    image_path=ocr_input_path,
                    fallback_image_path=fallback_path,
                    lang=lang_choice
                ),
                timeout=70.0
            )
        except asyncio.TimeoutError:
            print("[LIKH OCR] OCR timed out after 70s")
            return {
                "success": False,
                "stage": "ocr",
                "error": "OCR_TIMEOUT",
                "message": "Handwriting recognition took longer than expected. Please try with a clearer or smaller image.",
                "raw_text": "",
                "cleaned_text": "",
                "confidence": 0.0,
                "cleanup_applied": False
            }
        ocr_time = time.time() - ocr_start
        print(f"[LIKH OCR] OCR completed in {ocr_time:.2f}s ({len(ocr_result.get('lines', []))} lines)")

        raw_text = ocr_result.get("raw_text", "").strip()
        confidence = ocr_result.get("confidence", 0.0)
        detected_lang = ocr_result.get("language", "en")
        low_conf_segments = ocr_result.get("low_confidence_segments", [])
        regions = ocr_result.get("regions", [])
        passes_done = ocr_result.get("passes_performed", 1)

        # 5. If OCR returned empty text, return gracefully
        if not raw_text:
            total_time = round(time.time() - start_total_time, 2)
            print(f"[LIKH OCR] Response sent (no text detected, total time: {total_time:.2f}s)")
            return {
                "success": True,
                "raw_text": "",
                "cleaned_text": "",
                "language": detected_lang,
                "confidence": 0.0,
                "processing_time": total_time,
                "warnings": ["No handwriting detected in the image."] + all_warnings,
                "original_image_url": f"{str(request.base_url).rstrip('/')}/uploads/{orig_filename}",
                "processed_image_url": f"{str(request.base_url).rstrip('/')}/uploads/{proc_filename}" if os.path.exists(proc_path) else None,
                "low_confidence_segments": [],
                "quality_score": quality_info.get("quality_score", 0.5),
                "cleanup_applied": False
            }

        # 6. AI Text Cleanup in threadpool with strict non-blocking timeout & raw fallback
        print("[LIKH OCR] Text cleanup started")
        cleanup_start = time.time()
        cleanup_applied = False
        cleanup_method = "none"
        cleaned_text = raw_text

        try:
            cleanup_res = await asyncio.wait_for(
                run_in_threadpool(
                    ai_cleaner.clean_text,
                    raw_text,
                    language=detected_lang
                ),
                timeout=8.0
            )
            cleaned_text = cleanup_res.get("cleaned_text", raw_text)
            cleanup_method = cleanup_res.get("method", "heuristic_nlp")
            cleanup_applied = True
            if cleanup_res.get("warnings"):
                all_warnings.extend(cleanup_res["warnings"])
        except asyncio.TimeoutError:
            print("[LIKH OCR] AI text cleanup timed out (8s limit); returning raw OCR text safely")
            cleaned_text = raw_text
            cleanup_method = "raw_fallback"
            all_warnings.append("AI text cleanup was skipped to ensure fast response.")
        except Exception as ce:
            print(f"[LIKH OCR] AI text cleanup skipped due to error: {ce}; returning raw OCR text")
            cleaned_text = raw_text
            cleanup_method = "raw_fallback"

        cleanup_time = time.time() - cleanup_start
        print(f"[LIKH OCR] Text cleanup completed in {cleanup_time:.2f}s (Method: {cleanup_method})")

        total_time = round(time.time() - start_total_time, 2)
        base_url = str(request.base_url).rstrip("/")
        print(f"[LIKH OCR] Response sent (total server time: {total_time:.2f}s)")

        # 7. Print Development Benchmark Log
        print("\n================ [LIKH AI OCR BENCHMARK] ================")
        print(f" File Name:        {file.filename} ({file_size_kb:.1f} KB)")
        print(f" Disk Save:        {save_time:.2f}s")
        print(f" Preprocessing:    {prep_time:.2f}s")
        print(f" OCR Recognition:  {ocr_time:.2f}s ({len(ocr_result.get('lines', []))} lines)")
        print(f" AI Text Cleanup:  {cleanup_time:.2f}s (Method: {cleanup_method})")
        print(f" Total Server Time: {total_time:.2f}s")
        print("=========================================================\n")

        return {
            "success": True,
            "title": title or file.filename or "Handwritten Document",
            "raw_text": raw_text,
            "cleaned_text": cleaned_text,
            "language": detected_lang,
            "confidence": confidence,
            "processing_time": total_time,
            "warnings": all_warnings,
            "preprocessing_applied": applied_ops,
            "cleanup_method": cleanup_method,
            "cleanup_applied": cleanup_applied,
            "passes_performed": passes_done,
            "quality_score": quality_info.get("quality_score", 1.0),
            "low_confidence_segments": low_conf_segments,
            "regions": regions,
            "original_image_url": f"{base_url}/uploads/{orig_filename}",
            "processed_image_url": f"{base_url}/uploads/{proc_filename}" if os.path.exists(proc_path) else None
        }

    except Exception as e:
        return {
            "success": False,
            "error": f"Internal processing error: {str(e)}",
            "raw_text": "",
            "cleaned_text": "",
            "confidence": 0.0
        }

# --------------------------------------------------
# AUTHENTICATION ENDPOINTS
# --------------------------------------------------

import json
import hashlib
from pydantic import BaseModel

USERS_FILE = os.path.join(BASE_DIR, "users.json")

def _hash_password(pw: str) -> str:
    return hashlib.sha256(pw.encode('utf-8')).hexdigest()

def _load_users():
    if not os.path.exists(USERS_FILE):
        default_users = {
            "demo@likhai.com": {
                "id": "usr_demo",
                "name": "Demo User",
                "email": "demo@likhai.com",
                "password_hash": _hash_password("likhai123"),
                "created_at": "2026-01-01T00:00:00.000000"
            }
        }
        with open(USERS_FILE, "w") as f:
            json.dump(default_users, f, indent=2)
        return default_users
    try:
        with open(USERS_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {}

def _save_users(users_dict):
    with open(USERS_FILE, "w") as f:
        json.dump(users_dict, f, indent=2)

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

@app.post("/auth/register")
def register(req: RegisterRequest):
    email = req.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Invalid email address.")
    if len(req.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters.")
    
    users = _load_users()
    if email in users:
        raise HTTPException(status_code=400, detail="Email is already registered.")
    
    user_id = f"usr_{uuid.uuid4().hex[:10]}"
    new_user = {
        "id": user_id,
        "name": req.name.strip() or "LIKH AI User",
        "email": email,
        "password_hash": _hash_password(req.password),
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ")
    }
    users[email] = new_user
    _save_users(users)
    
    token = f"tok_{uuid.uuid4().hex}"
    return {
        "success": True,
        "token": token,
        "user": {
            "id": new_user["id"],
            "name": new_user["name"],
            "email": new_user["email"],
            "createdAt": new_user["created_at"]
        }
    }

@app.post("/auth/login")
def login(req: LoginRequest):
    email = req.email.strip().lower()
    users = _load_users()
    
    user = users.get(email)
    if not user or user.get("password_hash") != _hash_password(req.password):
        raise HTTPException(status_code=401, detail="Invalid email or password.")
    
    token = f"tok_{uuid.uuid4().hex}"
    return {
        "success": True,
        "token": token,
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "createdAt": user.get("created_at")
        }
    }

@app.get("/auth/demo")
def get_demo_account():
    _load_users()
    return {
        "email": "demo@likhai.com",
        "password": "likhai123",
        "name": "Demo User"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)