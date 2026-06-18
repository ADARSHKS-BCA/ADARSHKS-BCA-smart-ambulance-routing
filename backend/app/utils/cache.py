"""
Cache utility — simple in-memory TTL cache for repeated transcriptions.
Uses a hash of the audio bytes as the cache key.
"""

import hashlib
import logging
from cachetools import TTLCache

logger = logging.getLogger(__name__)

# Cache up to 100 results, expire after 10 minutes
_cache: TTLCache = TTLCache(maxsize=100, ttl=600)


def get_cache_key(file_bytes: bytes) -> str:
    """Generate a SHA-256 hash of the audio content."""
    return hashlib.sha256(file_bytes).hexdigest()


def get_cached_result(file_bytes: bytes) -> dict | None:
    """Check if we have a cached result for this audio."""
    key = get_cache_key(file_bytes)
    result = _cache.get(key)
    if result:
        logger.info(f"Cache HIT for key {key[:16]}...")
    return result


def set_cached_result(file_bytes: bytes, result: dict) -> None:
    """Store a result in the cache."""
    key = get_cache_key(file_bytes)
    _cache[key] = result
    logger.info(f"Cache SET for key {key[:16]}...")
