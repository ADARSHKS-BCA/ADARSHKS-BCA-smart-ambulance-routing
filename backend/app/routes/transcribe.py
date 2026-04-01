"""
Transcription route — POST /transcribe endpoint.
"""

import logging
import time
from fastapi import APIRouter, UploadFile, File, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from ..config import settings
from ..services.openai_service import transcribe_and_translate
from ..utils.validation import validate_audio_file
from ..utils.cache import get_cached_result, set_cached_result

logger = logging.getLogger(__name__)

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


@router.post("/transcribe")
@limiter.limit(settings.RATE_LIMIT)
async def transcribe(request: Request, file: UploadFile = File(...)):
    """
    Accept an audio file, transcribe it using Whisper,
    then translate the result to English using GPT.

    Returns:
        {
            "original": "transcribed text in source language",
            "translated": "translated English text",
            "latency_ms": 2345
        }
    """
    start = time.perf_counter()

    # Step 1: Validate file
    file_bytes = await validate_audio_file(file)
    filename = file.filename or "audio.wav"

    # Step 2: Check cache
    cached = get_cached_result(file_bytes)
    if cached:
        elapsed_ms = int((time.perf_counter() - start) * 1000)
        return {**cached, "latency_ms": elapsed_ms, "cached": True}

    # Step 3: Transcribe + translate
    result = await transcribe_and_translate(file_bytes, filename)

    # Step 4: Cache the result
    set_cached_result(file_bytes, result)

    elapsed_ms = int((time.perf_counter() - start) * 1000)
    logger.info(f"Request completed in {elapsed_ms}ms")

    return {**result, "latency_ms": elapsed_ms, "cached": False}
