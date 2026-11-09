import os
import sys
import django

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from api.services.ocr_service import extract_text_from_image

images_dir = "/Users/sevvalarslan/projects/BesinIcerikProjesi/images"

try:
    with open(os.path.join(images_dir, "ocr_test.jpeg"), 'rb') as f:
        text = extract_text_from_image(f.read())
        print("EXTRACTION SUCCESS. TEXT LENGTH:", len(text))
        print("FIRST 100 CHARS:", text[:100].replace("\n", " "))
except Exception as e:
    print("ERROR:", e)

