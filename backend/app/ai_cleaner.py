import os
import re
import json
import unicodedata
from typing import Dict, Any, Optional
import requests

PROMPT_TEMPLATE = """You are an expert Handwriting OCR Correction Engine for LIKH AI ("Your handwriting. Digitized.").
Your job is to clean up raw OCR-extracted text from real-world handwritten notes, notebook pages, and documents.

CRITICAL RULES:
1. Correct obvious spelling, punctuation, and handwriting letter-substitution errors (e.g., "Machlne Learnlng ls a fleld of Al" -> "Machine Learning is a field of AI.").
2. Fix missing or irregular spacing, punctuation, and handwriting contraction errors (e.g., "Donit" -> "Don't", "if your the" -> "if you're the").
3. PRESERVE casing and formatting: do NOT arbitrarily capitalize words mid-sentence. Preserve quote line breaks, headings, bullet points, numbers, dates, abbreviations, and math formulas.
4. STRICT PRESERVATION OF HINDI & HINGLISH:
   - NEVER translate Hindi (Devanagari script) into English.
   - NEVER translate Hinglish (Hindi written in Latin script, e.g. "Aaj hum Machine Learning padhenge") into English.
   - Preserve mixed English + Hindi verbatim.
5. ZERO HALLUCINATION POLICY:
   - NEVER invent facts, missing sentences, or words to "fill in the blanks".
   - If a word or stroke is genuinely illegible or ambiguous, write "[unclear]" instead of guessing.
6. Return ONLY the clean, corrected text without any preamble, chatter, or quotes.

RAW OCR TEXT:
{raw_text}
"""

class AICleaner:
    def __init__(self):
        self.gemini_api_key = os.environ.get("GEMINI_API_KEY", "").strip()
        self.ollama_url = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434").strip()
        self.ollama_model = os.environ.get("OLLAMA_MODEL", "qwen2.5:0.5b").strip()

        # Common handwriting OCR word confusions
        self.common_ocr_word_map = {
            "machlne": "machine",
            "learnlng": "learning",
            "fleld": "field",
            "durlng": "during",
            "requ1red": "required",
            "definltion": "definition",
            "functl0n": "function",
            "algorlthm": "algorithm",
            "artlflclal": "artificial",
            "1ntelllgence": "intelligence",
            "experlment": "experiment",
            "solutlon": "solution",
            "condltion": "condition",
            "operatlon": "operation",
            "slmple": "simple",
            "dlfferent": "different",
            "poss1ble": "possible",
            "lmportant": "important",
        }

    def clean_text(self, raw_text: str, language: str = "en") -> Dict[str, Any]:
        """
        Cleans OCR text using a multi-tiered approach:
        1. Gemini API (if GEMINI_API_KEY available)
        2. Ollama (if local Ollama server running)
        3. Built-in Rule-Based & Heuristic NLP Cleaner (deterministic offline fallback)
        """
        if not raw_text or not raw_text.strip():
            return {
                "cleaned_text": "",
                "method": "empty",
                "warnings": []
            }

        warnings = []

        # 1. Try Gemini API if key is present
        api_key = os.environ.get("GEMINI_API_KEY", self.gemini_api_key).strip()
        if api_key:
            try:
                gemini_text = self._call_gemini(raw_text, api_key, language)
                if gemini_text:
                    return {
                        "cleaned_text": gemini_text,
                        "method": "gemini_api",
                        "warnings": warnings
                    }
            except Exception as e:
                warnings.append(f"Gemini API cleanup unavailable: {str(e)}")

        # 2. Try Ollama if running
        try:
            ollama_text = self._call_ollama(raw_text)
            if ollama_text:
                return {
                    "cleaned_text": ollama_text,
                    "method": "ollama",
                    "warnings": warnings
                }
        except Exception:
            pass

        # 3. Fallback to robust offline heuristic NLP cleaner
        cleaned = self._heuristic_cleanup(raw_text, language)
        return {
            "cleaned_text": cleaned,
            "method": "heuristic_nlp",
            "warnings": warnings
        }

    def _call_gemini(self, raw_text: str, api_key: str, language: str) -> Optional[str]:
        """Calls Google Gemini API for fast, high-quality handwriting cleanup."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
        prompt = PROMPT_TEMPLATE.format(raw_text=raw_text)
        payload = {
            "contents": [
                {
                    "parts": [{"text": prompt}]
                }
            ],
            "generationConfig": {
                "temperature": 0.15,
                "maxOutputTokens": 4096
            }
        }
        res = requests.post(url, json=payload, timeout=25)
        if res.status_code == 200:
            data = res.json()
            candidates = data.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                if parts and "text" in parts[0]:
                    return parts[0]["text"].strip()
        return None

    def _call_ollama(self, raw_text: str) -> Optional[str]:
        """Calls local Ollama server if available."""
        prompt = PROMPT_TEMPLATE.format(raw_text=raw_text)
        res = requests.post(
            f"{self.ollama_url}/api/generate",
            json={
                "model": self.ollama_model,
                "prompt": prompt,
                "stream": False
            },
            timeout=10
        )
        if res.status_code == 200:
            data = res.json()
            resp = data.get("response", "").strip()
            if resp:
                return resp
        return None

    def _heuristic_cleanup(self, raw_text: str, language: str) -> str:
        """
        Rule-based NLP and regex OCR corrector.
        Preserves original wording and line structure.
        Fixes handwriting contraction misreads (Donit -> Don't, if your the -> if you're the),
        punctuation, spacing, and digit-letter confusions without hallucinating.
        Supports Hindi & Hinglish preservation and math formulas.
        """
        # Unicode normalization (NFC)
        text = unicodedata.normalize("NFC", raw_text)

        lines = text.split("\n")
        processed_lines = []
        prev_ended_with_sentence_terminator = True

        for idx, line in enumerate(lines):
            line_str = line.strip()
            if not line_str:
                processed_lines.append("")
                prev_ended_with_sentence_terminator = True
                continue

            # Check if this line is a list item or heading or math
            is_bullet = bool(re.match(r"^[-*•]\s+|\d+[.)]\s+", line_str))
            is_equation = bool(re.search(r"[=+\-*/^]{2,}|\b(sin|cos|tan|log|lim)\b", line_str))
            
            # 1. Normalize spaces
            line_str = re.sub(r"[ \t]+", " ", line_str)

            # 2. Fix spacing around punctuation: space before punctuation -> no space
            line_str = re.sub(r"\s+([,.:;?!])", r"\1", line_str)

            # 3. Add space after punctuation if missing (e.g. "word,next" -> "word, next")
            line_str = re.sub(r"([,;:])([A-Za-z0-9\u0900-\u097F])", r"\1 \2", line_str)
            line_str = re.sub(r"([.?!])([A-Za-z\u0900-\u097F])", r"\1 \2", line_str)

            # 4. Hindi punctuation (Purna Viram) spacing
            line_str = re.sub(r"\s*([।॥])\s*", r"\1 ", line_str).strip()

            # 5. English & Latin handwriting OCR corrections (skip for math/code)
            if not is_equation:
                # Common handwriting contraction misreads
                line_str = re.sub(r"\bDon['`]?[itf]\b", "Don't", line_str)
                line_str = re.sub(r"\bdon['`]?[itf]\b", "don't", line_str)
                line_str = re.sub(r"^only one\b", "Only one", line_str)
                line_str = re.sub(r"\bWon['`]?[itf]\b", "Won't", line_str)
                line_str = re.sub(r"\bwon['`]?[itf]\b", "won't", line_str)
                line_str = re.sub(r"\bCan['`]?[itf]\b", "Can't", line_str)
                line_str = re.sub(r"\bcan['`]?[itf]\b", "can't", line_str)
                line_str = re.sub(r"\bIsnit\b", "Isn't", line_str)
                line_str = re.sub(r"\bisnit\b", "isn't", line_str)
                line_str = re.sub(r"\bWasnit\b", "Wasn't", line_str)
                line_str = re.sub(r"\bwasnit\b", "wasn't", line_str)
                line_str = re.sub(r"\bDoesnit\b", "Doesn't", line_str)
                line_str = re.sub(r"\bdoesnit\b", "doesn't", line_str)
                line_str = re.sub(r"\bDoesnlt\b", "Doesn't", line_str)
                line_str = re.sub(r"\bdoesnlt\b", "doesn't", line_str)
                line_str = re.sub(r"\bDidnit\b", "Didn't", line_str)
                line_str = re.sub(r"\bdidnit\b", "didn't", line_str)
                line_str = re.sub(r"\bHasnit\b", "Hasn't", line_str)
                line_str = re.sub(r"\bhasnit\b", "hasn't", line_str)
                line_str = re.sub(r"\bHavenit\b", "Haven't", line_str)
                line_str = re.sub(r"\bhavenit\b", "haven't", line_str)
                line_str = re.sub(r"\bWouldnit\b", "Wouldn't", line_str)
                line_str = re.sub(r"\bwouldnit\b", "wouldn't", line_str)
                line_str = re.sub(r"\bCouldnit\b", "Couldn't", line_str)
                line_str = re.sub(r"\bcouldnit\b", "couldn't", line_str)
                line_str = re.sub(r"\bShouldnit\b", "Shouldn't", line_str)
                line_str = re.sub(r"\bshouldnit\b", "shouldn't", line_str)
                line_str = re.sub(r"\bArenit\b", "Aren't", line_str)
                line_str = re.sub(r"\barenit\b", "aren't", line_str)

                # Missing apostrophes in common contractions
                line_str = re.sub(r"\byoure\b", "you're", line_str)
                line_str = re.sub(r"\bYoure\b", "You're", line_str)
                line_str = re.sub(r"\btheyre\b", "they're", line_str)
                line_str = re.sub(r"\bTheyre\b", "They're", line_str)
                line_str = re.sub(r"\bIm\b", "I'm", line_str)
                line_str = re.sub(r"\bIve\b", "I've", line_str)
                line_str = re.sub(r"\bthats\b", "that's", line_str)
                line_str = re.sub(r"\bThats\b", "That's", line_str)
                line_str = re.sub(r"\bwhats\b", "what's", line_str)
                line_str = re.sub(r"\bWhats\b", "What's", line_str)

                # Contextual your vs you're
                line_str = re.sub(
                    r"\b(if|when|as|since)\s+your\s+(the|a|an|only|one|not|so|very|too)\b",
                    r"\1 you're \2",
                    line_str,
                    flags=re.IGNORECASE
                )
                line_str = re.sub(
                    r"\byour\s+(the|a|an|going|doing|being|looking|feeling|making|laughing|running|walking|welcome|right|wrong|late|early|ready|here|there|not|so|very|too|only|always)\b",
                    r"you're \1",
                    line_str
                )
                line_str = re.sub(
                    r"\bYour\s+(the|a|an|going|doing|being|looking|feeling|making|laughing|running|walking|welcome|right|wrong|late|early|ready|here|there|not|so|very|too|only|always)\b",
                    r"You're \1",
                    line_str
                )

                # Standalone lowercase 'i' -> 'I'
                line_str = re.sub(r"\bi\b", "I", line_str)
                # Standalone 'ls' -> 'is'
                line_str = re.sub(r"\bls\b", "is", line_str)
                line_str = re.sub(r"\bLs\b", "Is", line_str)
                # Standalone 'lt' -> 'it'
                line_str = re.sub(r"\blt\b", "it", line_str)
                line_str = re.sub(r"\bLt\b", "It", line_str)
                # Standalone 'ln' -> 'in'
                line_str = re.sub(r"\bln\b", "in", line_str)
                line_str = re.sub(r"\bLn\b", "In", line_str)
                # Standalone 'of Al' -> 'of AI'
                line_str = re.sub(r"\bof Al\b", "of AI", line_str)
                line_str = re.sub(r"\bfield of Al\b", "field of AI", line_str)

                # Fix common OCR digit-letter mistakes in words: e.g. "Th1s" -> "This", "n0te" -> "note"
                line_str = re.sub(r"\b([a-zA-Z]+)0([a-zA-Z]+)\b", r"\g<1>o\g<2>", line_str)
                line_str = re.sub(r"\b0([a-zA-Z]{2,})\b", r"O\1", line_str)
                line_str = re.sub(r"\b([a-zA-Z]+)1([a-zA-Z]+)\b", r"\g<1>l\g<2>", line_str)
                line_str = re.sub(r"\b1([a-zA-Z]{3,})\b", r"I\1", line_str)
                
                # Fix double-v to w
                line_str = re.sub(r"\bvv([a-z]+)\b", r"w\1", line_str)

                # Fix handwriting word confusion dictionary
                words = line_str.split(" ")
                corrected_words = []
                for w in words:
                    match = re.match(r"^([a-zA-Z]+)([,.:;?!]*)$", w)
                    if match:
                        core, punct = match.group(1), match.group(2)
                        core_lower = core.lower()
                        if core_lower in self.common_ocr_word_map:
                            replacement = self.common_ocr_word_map[core_lower]
                            if core.istitle():
                                replacement = replacement.capitalize()
                            elif core.isupper():
                                replacement = replacement.upper()
                            corrected_words.append(replacement + punct)
                            continue
                    corrected_words.append(w)
                line_str = " ".join(corrected_words)

                # CRITICAL CASING FIX:
                # Only capitalize start of line if previous line ended with a sentence terminator (. ? !)
                # or this is the start of the document.
                # If this line is a continuation (prev line ended without terminator or with comma),
                # PRESERVE writer's lowercase casing (e.g., "to laugh, Even", "if you're the").
                if not is_bullet and len(line_str) > 0 and line_str[0].isalpha():
                    if prev_ended_with_sentence_terminator and idx == 0:
                        line_str = line_str[0].upper() + line_str[1:]

            # 6. Fix multiple consecutive punctuation (e.g. ",," -> ",", ".." -> ".")
            line_str = re.sub(r",+", ",", line_str)
            line_str = re.sub(r"\?+", "?", line_str)
            line_str = re.sub(r"!+", "!", line_str)

            # Update sentence terminator state
            prev_ended_with_sentence_terminator = bool(re.search(r"[.?!]\s*$", line_str))

            processed_lines.append(line_str)

        # For handwritten notes, quotes, or poems, preserve line breaks faithfully
        # If all lines are relatively short (< 55 chars), maintain line breaks as written.
        max_line_len = max([len(l) for l in processed_lines if l] + [0])
        if max_line_len < 65:
            cleaned_text = "\n".join(processed_lines).strip()
        else:
            # Paragraph merging for long running prose
            result_paragraphs = []
            current_para = []
            for line in processed_lines:
                if not line:
                    if current_para:
                        result_paragraphs.append(" ".join(current_para))
                        current_para = []
                    result_paragraphs.append("")
                    continue

                is_bullet = bool(re.match(r"^[-*•]\s+|\d+[.)]\s+", line))
                is_key_value = bool(re.match(r"^[A-Za-z0-9\s_-]+:\s*", line))
                is_short_header = len(line) < 45 and not line.endswith(",")
                is_math = bool(re.search(r"[=+\-*/^]{2,}", line))

                if is_bullet or is_key_value or is_short_header or is_math:
                    if current_para:
                        result_paragraphs.append(" ".join(current_para))
                        current_para = []
                    result_paragraphs.append(line)
                else:
                    current_para.append(line)

            if current_para:
                result_paragraphs.append(" ".join(current_para))
            cleaned_text = "\n".join(result_paragraphs).strip()

        cleaned_text = re.sub(r"\n{3,}", "\n\n", cleaned_text)
        return cleaned_text if cleaned_text else text

ai_cleaner = AICleaner()
