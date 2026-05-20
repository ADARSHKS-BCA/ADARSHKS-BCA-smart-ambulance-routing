# Architecture Overview

## Flow Diagram
1. **Request**: Client uploads an image (`app.py`).
2. **Storage**: Image is temporarily saved to `uploads/`.
3. **OCR**: `ocr_service.py` extracts text from the image.
4. **Extraction**: `extraction.py` parses text to extract `license_number` and `expiry`.
5. **Validation**: `validation.py` checks if the license is valid based on set rules.
6. **Data Storage**: `database.py` optionally saves the verification result.
7. **Response**: Application returns a JSON response to the client.

## Module Breakdown
- **app**: Main entry point to define routing.
- **services**: Logic handling specific workflows (OCR, text splitting, rules validation).
- **models**: Abstracted database queries and schema definitions.
- **tests**: Coverage tests ensuring application stability.
