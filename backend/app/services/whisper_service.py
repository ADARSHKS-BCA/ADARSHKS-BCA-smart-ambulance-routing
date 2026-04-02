import logging
import time
import os
import tempfile
import asyncio
import whisper
from ..config import settings

logger = logging.getLogger(__name__)

# Global singleton to hold the Whisper model in memory.
# It is loaded asynchronously during app startup to avoid blocking the main thread.
_model = None

def get_model():
    global _model
    if _model is None:
        logger.info(f"Loading Whisper model ('base'). This takes a few seconds... ⏳")
        start = time.perf_counter()
        _model = whisper.load_model("base")
        elapsed = time.perf_counter() - start
        logger.info(f"Whisper model loaded into memory in {elapsed:.2f}s ✅")
    return _model

def _transcribe_sync(file_path: str) -> str:
    """
    Synchronous blocking function that runs whisper transcription.
    """
    start = time.perf_counter()
    model = get_model()
    
    # We use task='translate' since we want to automatically translate to English
    result = model.transcribe(file_path, task="translate")
    text = result.get("text", "").strip()
    
    elapsed = time.perf_counter() - start
    logger.info(f"Local Whisper transcription completed in {elapsed:.2f}s")
    return text

async def transcribe_audio(file_bytes: bytes, filename: str) -> str:
    """
    Saves the file safely, runs the transcription model in a threadpool so it 
    doesn't block other requests, and cleans up the file.
    """
    # 1. Save bytes to a temporary file
    fd, tmp_path = tempfile.mkstemp(suffix=".webm")
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(file_bytes)
        
        logger.info(f"Audio saved to temp file: {tmp_path} ({len(file_bytes)} bytes)")
        
        # 2. Run Whisper on a separate thread to prevent blocking FastAPI
        transcribed_text = await asyncio.to_thread(_transcribe_sync, tmp_path)
        
        return transcribed_text
    
    finally:
        # 3. Clean up the temp file
        try:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
                logger.info("Temporary audio file cleaned up.")
        except Exception as e:
            logger.error(f"Failed to clean up temp file {tmp_path}: {e}")
