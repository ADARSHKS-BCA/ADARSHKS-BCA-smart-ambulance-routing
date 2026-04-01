"""
OpenAI service — handles Whisper transcription and GPT translation.
Optimized for low latency with async calls.
"""

import logging
import time
from openai import AsyncOpenAI
from ..config import settings

logger = logging.getLogger(__name__)

client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)


async def transcribe_audio(file_bytes: bytes, filename: str) -> str:
    """
    Send audio to OpenAI Whisper API for transcription.
    Returns the transcribed text in the original language.
    """
    start = time.perf_counter()
    logger.info(f"Transcribing audio: {filename} ({len(file_bytes)} bytes)")

    response = await client.audio.transcriptions.create(
        model="gpt-4o-transcribe",
        file=(filename, file_bytes),
        response_format="text",
    )

    elapsed = time.perf_counter() - start
    logger.info(f"Transcription completed in {elapsed:.2f}s: {response[:80]}...")
    return response.strip()


async def translate_to_english(text: str) -> str:
    """
    Send transcribed text to GPT for translation to English.
    If text is already English, it returns it cleaned up.
    """
    if not text:
        return ""

    start = time.perf_counter()
    logger.info(f"Translating text ({len(text)} chars)")

    response = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": (
                    "You are a precise medical translator. "
                    "Translate the following text to English. "
                    "If the text is already in English, return it as-is with minor grammar fixes. "
                    "Preserve all medical terminology accurately. "
                    "Output ONLY the translated text, nothing else."
                ),
            },
            {"role": "user", "content": text},
        ],
        temperature=0.1,
        max_tokens=1024,
    )

    translated = response.choices[0].message.content.strip()
    elapsed = time.perf_counter() - start
    logger.info(f"Translation completed in {elapsed:.2f}s")
    return translated


async def transcribe_and_translate(
    file_bytes: bytes, filename: str
) -> dict[str, str]:
    """
    Full pipeline: transcribe audio → translate to English.
    Returns { "original": ..., "translated": ... }
    """
    total_start = time.perf_counter()

    # Step 1: Transcribe
    original = await transcribe_audio(file_bytes, filename)

    # Step 2: Translate
    translated = await translate_to_english(original)

    total_elapsed = time.perf_counter() - total_start
    logger.info(f"Full pipeline completed in {total_elapsed:.2f}s")

    return {"original": original, "translated": translated}
