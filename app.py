from flask import Flask, request, jsonify
from flask_cors import CORS
from config import UPLOAD_FOLDER
import os

from services.ocr_service import extract_text_from_image
from services.extraction import extract_license_data
from services.validation import validate_license
from models.database import save_result

app = Flask(__name__)
CORS(app)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure upload directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/api/verify-license', methods=['POST'])
def verify_license():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
    file.save(filepath)
    
    try:
        # Process the image workflow
        text = extract_text_from_image(filepath)
        data = extract_license_data(text)
        status = validate_license(data)
        
        # Complete full response structure
        data["status"] = status
        
        # Persist entry
        save_result(data)
        
        return jsonify(data)
    finally:
        # Delete file after text is extracted to clear out uploads folder
        if os.path.exists(filepath):
            os.remove(filepath)

if __name__ == '__main__':
    app.run(debug=True)
