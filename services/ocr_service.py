import pytesseract
import cv2
import numpy as np
from config import TESSERACT_PATH

# Set the Tesseract path from config
pytesseract.pytesseract.tesseract_cmd = TESSERACT_PATH

def extract_text_from_image(image_path):
    """
    Converts image to text using Tesseract OCR.
    """
    try:
        # Load image via cv2
        img = cv2.imread(image_path)
        
        # 1. Grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # 2. Rescaling (2x upscale helps OCR read small fonts)
        gray = cv2.resize(gray, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
        
        # 3. Apply slight blur to remove noise (Gaussian)
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # 4. Adaptive thresholding to binarize image (helps remove shadows and watermarks)
        thresh = cv2.adaptiveThreshold(blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2)
        
        # Pass the preprocessed numpy array to pytesseract using PSM 6
        text = pytesseract.image_to_string(thresh, config='--psm 6')
        return text
    except Exception as e:
        print(f"OCR Error: {e}")
        return ""
