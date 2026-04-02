"""
Transcription route — POST /transcribe endpoint.
"""

import logging
import time
from fastapi import APIRouter, UploadFile, File, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from ..config import settings
from ..services.whisper_service import transcribe_audio
from ..utils.validation import validate_audio_file
from ..utils.cache import get_cached_result, set_cached_result

logger = logging.getLogger(__name__)

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


@router.post("/transcribe")
@limiter.limit(settings.RATE_LIMIT)
async def transcribe(request: Request, file: UploadFile = File(...)):
    """
    Accept an audio file and transcribe it completely locally using Whisper.

    Returns:
        {
            "original": "transcribed text in source language",
            "translated": "translated English text",
            "latency_ms": 2345
        }
        
    Note: Both 'original' and 'translated' will be the exact same text,
          due to OpenAI GPT APIs being unused for translation.
    """
    start = time.perf_counter()
    
    try:
        # Step 1: Validate file
        file_bytes = await validate_audio_file(file)
        filename = file.filename or "audio.webm"

        # Step 2: Check cache
        cached = get_cached_result(file_bytes)
        if cached:
            elapsed_ms = int((time.perf_counter() - start) * 1000)
            return {**cached, "latency_ms": elapsed_ms, "cached": True}

        # Step 3: Run local whisper 
        text_result = await transcribe_audio(file_bytes, filename)
        
        # Format the result without translation
        result = {
            "original": text_result,
            "translated": text_result, # Sending the same string as requested
        }

        # Step 4: Cache the result
        set_cached_result(file_bytes, result)

        elapsed_ms = int((time.perf_counter() - start) * 1000)
        logger.info(f"Request completed in {elapsed_ms}ms")

        return {**result, "latency_ms": elapsed_ms, "cached": False}
        
    except Exception as e:
        # Step 5: Catch all errors and return JSON nicely, NO server crashes
        logger.error(f"Failed to process audio: {e}", exc_info=True)
        return {
            "success": False,
            "error": str(e)
        }
