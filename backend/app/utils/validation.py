"""
Utility functions for file validation and processing.
"""

import logging
import os
from fastapi import UploadFile, HTTPException
from ..config import settings

logger = logging.getLogger(__name__)


async def validate_audio_file(file: UploadFile) -> bytes:
    """
    Validate uploaded audio file:
    - Check file extension against allowed list
    - Check file size against max limit
    - Read and return file bytes

    Raises HTTPException on validation failure.
    """
    # Check filename exists
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided.")

    # Check extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported file type: '{ext}'. "
                f"Allowed: {', '.join(settings.ALLOWED_EXTENSIONS)}"
            ),
        )

    # Read file content
    content = await file.read()

    # Check size
    if len(content) > settings.max_file_size_bytes:
        raise HTTPException(
            status_code=413,
            detail=(
                f"File too large: {len(content) / (1024*1024):.1f} MB. "
                f"Maximum allowed: {settings.MAX_FILE_SIZE_MB} MB."
            ),
        )

    if len(content) == 0:
        raise HTTPException(status_code=400, detail="Empty audio file.")

    logger.info(
        f"Audio file validated: {file.filename} "
        f"({len(content)} bytes, type: {ext})"
    )
    return content
