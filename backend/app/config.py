"""
Configuration module — loads environment variables with defaults.
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "info")
    RATE_LIMIT: str = os.getenv("RATE_LIMIT", "30/minute")
    MAX_FILE_SIZE_MB: int = int(os.getenv("MAX_FILE_SIZE_MB", "25"))
    ALLOWED_EXTENSIONS: list[str] = os.getenv(
        "ALLOWED_EXTENSIONS",
        ".wav,.mp3,.m4a,.webm,.ogg,.flac,.mp4,.mpeg,.mpga",
    ).split(",")

    @property
    def max_file_size_bytes(self) -> int:
        return self.MAX_FILE_SIZE_MB * 1024 * 1024


settings = Settings()
