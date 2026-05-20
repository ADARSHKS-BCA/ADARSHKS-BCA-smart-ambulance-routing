import re

def extract_license_data(text):
    """
    Extracts license number and expiry date from OCR text.
    """
    # Tesseract often reads noisy text horribly (e.g., KAZI instead of KA21).
    # We will strip all non-alphanumerics, then search for 2 target state letters followed by 13 alphanumeric chars.
    clean_text = re.sub(r'[^a-zA-Z0-9]', '', text).upper()
    
    # Force the first two characters to be a valid Indian state code
    state_codes = r'(AP|AR|AS|BR|CG|GA|GJ|HR|HP|JH|KA|KL|MP|MH|MN|ML|MZ|NL|OD|PB|RJ|SK|TN|TS|TR|UP|UK|WB|AN|CH|DN|DD|DL|JK|LA|LD|PY)'
    matches = re.finditer(state_codes + r'([A-Z0-9]{13})', clean_text)
    
    license_number = ""
    for match in matches:
        state_code = match.group(1)
        digits_part = match.group(2)
        
        # Correct common OCR mistakes in the digits part
        replacements = {'O':'0', 'I':'1', 'L':'1', 'Z':'2', 'S':'5', 'B':'8', 'G':'6', 'Q':'0'}
        for letter, digit in replacements.items():
            digits_part = digits_part.replace(letter, digit)
            
        # Verify that after substitution, it is purely numbers! This prevents grabbing random words.
        if digits_part.isdigit():
            license_number = state_code + digits_part
            break
            
    # Extreme Fallback: If OCR completely destroyed the state code (e.g. DL14 became just 10420...), 
    # extract the first massive block of digits we can find (length 13 to 15) using the raw unstripped text
    # so we don't accidentally merge nearby numbers (like NOXSS3 merging into 104...)
    if not license_number:
        fallback_match = re.search(r'(?<!\d)(\d{13,15})(?!\d)', text)
        if fallback_match:
            license_number = fallback_match.group(1)
        
    # Detect expiry: looking for a 4-digit number that reasonably looks like a future year
    # We remove the \\b boundary because OCR often merges the slash (e.g. 21/10/2033 becomes 1072033)
    # Plus we apply the replacements mapping since '2030' often reads as 'Z030'
    scrubbed_text = text
    for letter, digit in {'O':'0', 'I':'1', 'L':'1', 'Z':'2', 'S':'5', 'B':'8', 'G':'6', 'Q':'0'}.items():
        scrubbed_text = scrubbed_text.replace(letter, digit)
        
    years = re.findall(r'(20[2-5][0-9])', scrubbed_text)
    expiry = str(max(int(y) for y in years)) if years else ""
    
    return {
        "license_number": license_number,
        "expiry": expiry
    }
