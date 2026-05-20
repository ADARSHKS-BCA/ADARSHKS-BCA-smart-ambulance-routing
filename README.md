# License Verification Module

## Project Overview
A license verification module that extracts text from images (OCR), parses the license details, and validates the extracted values.

## Setup
```bash
pip install -r requirements.txt
```

## Run
```bash
python app.py
```

## API
`POST /api/verify-license`

## Request
Upload image file via a multipart/form-data request with the key `image`.

## Response
```json
{
  "license_number": "KA123456789",
  "expiry": "2028",
  "status": "VALID"
}
```
