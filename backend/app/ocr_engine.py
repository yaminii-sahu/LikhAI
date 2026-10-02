import os
import re
from typing import Dict, Any, List, Optional

# Disable oneDNN and PIR runtime issues on Windows CPU configurations BEFORE importing paddle
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["FLAGS_enable_mkldnn"] = "0"
os.environ["FLAGS_enable_pir_api"] = "0"
os.environ["PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT"] = "0"
os.environ["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"

import paddle
try:
    paddle.set_flags({"FLAGS_use_mkldnn": False})
except Exception:
    pass

from paddleocr import PaddleOCR

class OCREngine:
    def __init__(self):
        print("[OCREngine] Initializing PaddleOCR...")
        self.ocr_en = PaddleOCR(
            lang="en",
            use_doc_orientation_classify=False,
            use_doc_unwarping=False,
            use_textline_orientation=False,
        )
        self.ocr_hi = None
        print("[OCREngine] PaddleOCR initialized successfully.")

    def _get_ocr_for_lang(self, lang: str):
        if lang == "hi":
            if self.ocr_hi is None:
                try:
                    print("[OCREngine] Loading Hindi PaddleOCR engine...")
                    self.ocr_hi = PaddleOCR(
                        lang="hi",
                        use_doc_orientation_classify=False,
                        use_doc_unwarping=False,
                        use_textline_orientation=False,
                    )
                except Exception as e:
                    print(f"[OCREngine] Warning: Could not initialize Hindi engine ({e}), falling back to English.")
                    return self.ocr_en
            return self.ocr_hi
        return self.ocr_en

    def detect_script(self, text: str) -> str:
        """Detect whether text is predominantly Devanagari (Hindi) or Latin (English)."""
        devanagari_chars = len(re.findall(r'[\u0900-\u097F]', text))
        latin_chars = len(re.findall(r'[a-zA-Z]', text))
        if devanagari_chars > latin_chars:
            return "hi"
        return "en"

    def _calibrate_confidence(self, lines: List[Dict[str, Any]], raw_scores: List[float]) -> float:
        """
        Calibrates the raw deep learning confidence score into an honest, realistic score.
        Penalizes:
        - Score dispersion across lines.
        - OCR character substitution artifacts and non-words (e.g. digit-in-word, missing contractions).
        - Extremely short lines with questionable certainty.
        """
        if not raw_scores:
            return 0.0

        base_score = float(sum(raw_scores) / len(raw_scores))
        min_score = min(raw_scores)
        dispersion_penalty = (base_score - min_score) * 0.30

        total_words = 0
        suspicious_words = 0
        for l in lines:
            words = l["text"].split()
            total_words += len(words)
            for w in words:
                w_clean = re.sub(r"[^a-zA-Z0-9]", "", w)
                if not w_clean:
                    continue
                # Digits inside words (e.g. Th1s, requ1red)
                if re.search(r"[a-zA-Z]\d|\d[a-zA-Z]", w_clean):
                    suspicious_words += 1
                # Classic handwriting contraction errors
                elif re.search(r"(?i)\b(donit|donif|wonit|canit|doesnit|doesnlt|didnit|isnit|wasnit)\b", w_clean):
                    suspicious_words += 1
                # Consonant clusters with no vowels in Latin text
                elif len(w_clean) > 3 and not any(v in w_clean.lower() for v in "aeiouy\u0900-\u097F"):
                    suspicious_words += 1

        word_penalty = 0.0
        if total_words > 0:
            word_penalty = min(0.18, (suspicious_words / total_words) * 0.35)

        calibrated = base_score - dispersion_penalty - word_penalty
        return round(max(0.15, min(0.96, calibrated)), 3)

    def _run_single_pass(self, image_path: str, engine) -> Dict[str, Any]:
        """Runs PaddleOCR on a single image and extracts parsed line entries."""
        target_path = image_path
        cleanup_temp = False
        try:
            import cv2
            img_probe = cv2.imread(image_path)
            if img_probe is not None:
                h, w = img_probe.shape[:2]
                max_dim = max(h, w)
                if max_dim > 1536:
                    scale = 1440.0 / max_dim
                    scaled_img = cv2.resize(img_probe, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)
                    target_path = f"{os.path.splitext(image_path)[0]}_paddlescale.png"
                    cv2.imwrite(target_path, scaled_img)
                    cleanup_temp = True
        except Exception:
            target_path = image_path

        try:
            results = engine.predict(target_path)
        except Exception as e:
            if engine != self.ocr_en:
                print(f"[OCREngine] Fallback to primary engine due to error: {e}")
                results = self.ocr_en.predict(target_path)
            else:
                raise e
        finally:
            if cleanup_temp and os.path.exists(target_path):
                try:
                    os.remove(target_path)
                except Exception:
                    pass

        lines = []
        scores = []

        for item in results:
            data = item.json if hasattr(item, "json") else item
            if isinstance(data, dict) and "res" in data:
                data = data["res"]

            rec_texts = data.get("rec_texts", []) if isinstance(data, dict) else []
            rec_scores = data.get("rec_scores", []) if isinstance(data, dict) else []
            rec_boxes = data.get("rec_boxes", []) if isinstance(data, dict) else []

            for i in range(len(rec_texts)):
                text = str(rec_texts[i]).strip()
                if not text:
                    continue
                score = float(rec_scores[i]) if i < len(rec_scores) else 0.85
                box = rec_boxes[i] if i < len(rec_boxes) else None
                
                y_pos = 0.0
                box_h = 20.0
                if box is not None and len(box) >= 4:
                    y_pos = (box[1] + box[3]) / 2.0
                    box_h = abs(box[3] - box[1])

                lines.append({
                    "text": text,
                    "confidence": round(score, 3),
                    "box": box,
                    "y": y_pos,
                    "height": box_h
                })
                scores.append(score)

        # Sort lines top-to-bottom
        lines.sort(key=lambda item: item["y"])
        calibrated_confidence = self._calibrate_confidence(lines, scores)

        return {
            "lines": lines,
            "confidence": calibrated_confidence,
            "raw_scores": scores,
            "raw_text": "\n".join([l["text"] for l in lines]).strip()
        }

    def _segment_regions(self, lines: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Segments lines into logical document blocks (headings, lists, equations, paragraphs)."""
        if not lines:
            return []

        avg_height = sum(l["height"] for l in lines) / len(lines) if lines else 20.0
        regions = []

        for line in lines:
            text = line["text"]
            is_bullet = bool(re.match(r"^[-*•]\s+|\d+[.)]\s+", text))
            is_equation = bool(re.search(r"[=+\-*/^]{2,}|\b(sin|cos|tan|log|lim)\b", text))
            is_heading = (line["height"] > avg_height * 1.3 and len(text) < 55) or (text.isupper() and len(text) < 40)

            region_type = "paragraph"
            if is_heading:
                region_type = "heading"
            elif is_bullet:
                region_type = "bullet_list"
            elif is_equation:
                region_type = "equation"

            regions.append({
                "type": region_type,
                "text": text,
                "confidence": line["confidence"],
                "box": line.get("box")
            })

        return regions

    def extract_text(
        self,
        image_path: str,
        fallback_image_path: Optional[str] = None,
        lang: str = "auto"
    ) -> Dict[str, Any]:
        """
        Executes Handwriting OCR with single-pass priority and fallback only if zero lines found.
        """
        target_lang = "hi" if lang == "hi" else "en"
        engine = self._get_ocr_for_lang(target_lang)

        # Pass 1: Primary enhanced representation
        pass1 = self._run_single_pass(image_path, engine)
        chosen_pass = 1
        passes_performed = 1
        final_result = pass1

        # Only evaluate fallback Pass 2 if Pass 1 detected literally 0 lines of text
        need_fallback = len(pass1["lines"]) == 0

        if need_fallback and fallback_image_path and os.path.exists(fallback_image_path):
            try:
                pass2 = self._run_single_pass(fallback_image_path, engine)
                passes_performed = 2
                if len(pass2["lines"]) > 0:
                    final_result = pass2
                    chosen_pass = 2
            except Exception as e:
                print(f"[OCREngine] Pass 2 failed with exception: {e}")

        lines = final_result["lines"]
        raw_text = final_result["raw_text"]
        confidence = final_result["confidence"]

        # Extract uncertain words (< 0.70 confidence or suspicious token) for UI review
        low_confidence_segments = []
        for l in lines:
            words = l["text"].split()
            for w in words:
                w_clean = re.sub(r"[^a-zA-Z0-9]", "", w)
                if not w_clean:
                    continue
                is_suspicious = bool(
                    re.search(r"[a-zA-Z]\d|\d[a-zA-Z]", w_clean) or
                    re.search(r"(?i)\b(donit|donif|wonit|canit|doesnit|doesnlt|didnit)\b", w_clean) or
                    (len(w_clean) > 3 and not any(v in w_clean.lower() for v in "aeiouy\u0900-\u097F"))
                )
                if l["confidence"] < 0.70 or is_suspicious:
                    low_confidence_segments.append({
                        "text": w,
                        "confidence": l["confidence"],
                        "box": l.get("box")
                    })

        detected_lang = self.detect_script(raw_text) if lang == "auto" else lang
        regions = self._segment_regions(lines)

        return {
            "raw_text": raw_text,
            "confidence": confidence,
            "lines": lines,
            "regions": regions,
            "low_confidence_segments": low_confidence_segments,
            "language": detected_lang,
            "line_count": len(lines),
            "passes_performed": passes_performed,
            "chosen_pass": chosen_pass
        }

ocr_engine = OCREngine()
