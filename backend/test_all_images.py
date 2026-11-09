import os
import sys
import django
import glob

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from api.services.ocr_service import extract_text_from_image

images_dir = "/Users/sevvalarslan/projects/BesinIcerikProjesi/images"
image_files = glob.glob(os.path.join(images_dir, "*.jpeg")) + glob.glob(os.path.join(images_dir, "*.png"))

print("=== STARTING FULL OCR AND BARCODE TEST ===")

for img_path in sorted(image_files):
    filename = os.path.basename(img_path)
    print(f"\n--- Processing {filename} ---")
    try:
        with open(img_path, 'rb') as f:
            text = extract_text_from_image(f.read())
            print("Extracted Text Length:", len(text))
            
            # Print first 500 chars to see ingredients
            preview = text.replace('\n', ' ')
            if len(preview) > 500:
                 print("Text Snippet:", preview[:500] + "...")
            else:
                 print("Text Snippet:", preview)
                 
            # If it's barkod, find numbers
            if "barkod" in filename.lower():
                digits = ''.join(filter(str.isdigit, text))
                print("Found Digits (Barcode):", digits)
    except Exception as e:
        print("Error processing", filename, ":", e)

