from datetime import datetime
import re

def validate_license(license_data):
    """
    Applies rules such as expiry check and format check.
    """
    license_number = license_data.get("license_number", "")
    expiry = license_data.get("expiry", "")
    
    # Check format exactly matches either the true pattern or a fallback pure-digit extraction
    if not (re.fullmatch(r'[A-Z]{2}\d{13}', license_number) or re.fullmatch(r'\d{13,15}', license_number)):
        return "INVALID_FORMAT"
        
    # Check expiry format
    if not expiry or not expiry.isdigit():
        return "VALID_MISSING_EXPIRY"
        
    # Check expiry year against current year
    current_year = datetime.now().year
    if int(expiry) < current_year:
        return "EXPIRED"
        
    return "VALID"
