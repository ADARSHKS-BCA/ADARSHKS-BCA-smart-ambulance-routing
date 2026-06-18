import logging
import time
import os
import tempfile
import asyncio
from faster_whisper import WhisperModel
from ..config import settings

logger = logging.getLogger(__name__)

# ─── Model Configuration ───
# Global singleton to hold the Whisper model in memory.
_model = None

# Use the 'small' model for good multilingual accuracy.
# Model sizes: tiny < base < small < medium < large-v3
# 'small' is the best balance of accuracy vs. speed on CPU.
MODEL_SIZE = "small"

# compute_type="int8" uses 8-bit integer quantization for maximum CPU speed.
# This makes inference ~2x faster with negligible accuracy loss.
COMPUTE_TYPE = "int8"

# ─── Supported Languages ───
# Whisper uses ISO 639-1 codes internally
SUPPORTED_LANGUAGES = {
    "hi": "Hindi",
    "kn": "Kannada",
    "es": "Spanish",
    "en": "English",
    "ta": "Tamil",
    "te": "Telugu",
    "ml": "Malayalam",
    "fr": "French",
    "de": "German",
    "ar": "Arabic",
    "zh": "Chinese",
    "ja": "Japanese",
    "ko": "Korean",
    "pt": "Portuguese",
    "ru": "Russian",
    "ur": "Urdu",
    "mr": "Marathi",
    "bn": "Bengali",
    "gu": "Gujarati",
}


def get_model():
    """Load the Faster-Whisper model (singleton). Called once at startup."""
    global _model
    if _model is None:
        logger.info(f"Loading Faster-Whisper model ('{MODEL_SIZE}', compute={COMPUTE_TYPE}). Please wait... ⏳")
        start = time.perf_counter()
        _model = WhisperModel(
            MODEL_SIZE,
            device="cpu",
            compute_type=COMPUTE_TYPE,
            cpu_threads=8,          # Use 8 of your 10 cores
            num_workers=2,          # Parallel workers for decoding
        )
        elapsed = time.perf_counter() - start
        logger.info(f"Faster-Whisper model '{MODEL_SIZE}' loaded in {elapsed:.2f}s ✅")
    return _model


def _transcribe_sync(file_path: str) -> dict:
    """
    Synchronous function that runs faster-whisper transcription.
    Two-pass approach:
      Pass 1: Transcribe in the original language
      Pass 2: Translate to English (skipped if already English)
    """
    start = time.perf_counter()
    model = get_model()

    # ── Pass 1: Transcribe in original language ──
    segments_iter, info = model.transcribe(
        file_path,
        task="transcribe",
        beam_size=5,              # beam_size=5 = much better accuracy (was 1)
        vad_filter=True,          # Voice Activity Detection — skip silence
        vad_parameters=dict(
            min_silence_duration_ms=300,
        ),
        language_detection_threshold=0.5,  # Only accept language if >50% confident
        language_detection_segments=3,     # Use 3 segments for detection (more reliable)
        initial_prompt="Emergency medical situation. Ambulance, hospital, patient, injury, accident, bleeding, pain, heart attack.",
    )
    # Collect all segment texts
    original_text = " ".join(seg.text.strip() for seg in segments_iter).strip()

    detected_lang_code = info.language
    detected_lang_prob = info.language_probability
    detected_lang_name = SUPPORTED_LANGUAGES.get(detected_lang_code, detected_lang_code.capitalize())
    logger.info(f"Detected language: {detected_lang_name} ({detected_lang_code}) — confidence: {detected_lang_prob:.0%}")
    logger.info(f"[PASS 1 - ORIGINAL] {original_text}")

    # ── Pass 2: Translate to English ──
    if detected_lang_code == "en":
        translated_text = original_text
        logger.info("Audio is English — skipping translation pass.")
    else:
        translate_segments, _ = model.transcribe(
            file_path,
            task="translate",           # Whisper's built-in translate-to-English
            language=detected_lang_code, # Explicitly set the source language
            beam_size=5,                # Better accuracy for translation too
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=300,
            ),
        )
        translated_text = " ".join(seg.text.strip() for seg in translate_segments).strip()
        logger.info(f"[PASS 2 - TRANSLATED] {translated_text}")
        logger.info(f"Translation from {detected_lang_name} to English completed.")

    elapsed = time.perf_counter() - start
    logger.info(f"Faster-Whisper processing completed in {elapsed:.2f}s ⚡")
    return {
        "original": original_text,
        "translated": translated_text,
        "detected_language": detected_lang_code,
        "detected_language_name": detected_lang_name,
    }


async def transcribe_audio(file_bytes: bytes, filename: str) -> dict:
    """
    Saves the file safely, runs transcription in a threadpool so it
    doesn't block other requests, and cleans up the file.
    Returns a dict with 'original', 'translated', 'detected_language', 'detected_language_name'.
    """
    # 1. Save bytes to a temporary file
    fd, tmp_path = tempfile.mkstemp(suffix=".webm")
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(file_bytes)

        logger.info(f"Audio saved to temp file: {tmp_path} ({len(file_bytes)} bytes)")

        # 2. Run Faster-Whisper on a separate thread to prevent blocking FastAPI
        result = await asyncio.to_thread(_transcribe_sync, tmp_path)

        return result

    finally:
        # 3. Clean up the temp file
        try:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
                logger.info("Temporary audio file cleaned up.")
        except Exception as e:
            logger.error(f"Failed to clean up temp file {tmp_path}: {e}")
