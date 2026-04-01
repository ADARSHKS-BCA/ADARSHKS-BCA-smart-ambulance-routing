"""
FastAPI application factory — assembles routes, middleware, and error handlers.
"""

import logging
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from .config import settings
from .routes.transcribe import router as transcribe_router, limiter

# ─── Logging setup ───
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s │ %(levelname)-7s │ %(name)s │ %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown events."""
    logger.info("─" * 50)
    logger.info("🚀 Voice Translation API starting...")
    logger.info(f"   Rate limit: {settings.RATE_LIMIT}")
    logger.info(f"   Max file size: {settings.MAX_FILE_SIZE_MB} MB")
    logger.info(f"   Allowed types: {settings.ALLOWED_EXTENSIONS}")

    if not settings.OPENAI_API_KEY or settings.OPENAI_API_KEY.startswith("sk-your"):
        logger.warning("⚠️  OPENAI_API_KEY not set! API calls will fail.")
    else:
        logger.info("   OpenAI key: ✓ configured")

    logger.info("─" * 50)
    yield
    logger.info("Voice Translation API shutting down.")


def create_app() -> FastAPI:
    app = FastAPI(
        title="Voice Translation API",
        description="Multilingual voice-to-English translation using OpenAI Whisper + GPT",
        version="1.0.0",
        lifespan=lifespan,
    )

    # ─── CORS (allow Flutter web/mobile) ───
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ─── Rate limiter ───
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # ─── Request timing middleware ───
    @app.middleware("http")
    async def add_timing_header(request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        elapsed = time.perf_counter() - start
        response.headers["X-Process-Time-Ms"] = str(int(elapsed * 1000))
        return response

    # ─── Global error handler ───
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "detail": "Internal server error. Please try again.",
                "error_type": type(exc).__name__,
            },
        )

    # ─── Health check ───
    @app.get("/health")
    async def health():
        return {
            "status": "ok",
            "service": "voice-translation-api",
            "version": "1.0.0",
        }

    # ─── Routes ───
    app.include_router(transcribe_router, tags=["Transcription"])

    return app


app = create_app()
