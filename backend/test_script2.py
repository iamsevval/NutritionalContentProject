import os
import sys
import django
import json
from dotenv import load_dotenv

load_dotenv() # Load from .env

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from api.services.analysis_service import analyze_image, analyze_barcode

images_dir = "/Users/sevvalarslan/projects/BesinIcerikProjesi/images"

print("=== OCR TEST (ocr_test.jpeg) ===")
with open(os.path.join(images_dir, "ocr_test.jpeg"), 'rb') as f:
    res = analyze_image(f.read())
    if "error" in res:
        print("OCR ERROR:", res["error"])
    else:
        print("Saglik Puani:", res["data"].get("saglik_puani"))
        print("Alerjenler:", res["data"].get("alerjenler"))
        print("Icerikler:", res["data"].get("icerikler_tablosu")[:2])

print("\n=== BARKOD TEST (Known product: 8690526011414) ===")
bres = analyze_barcode("8690526011414")
if "error" in bres:
    print("Barkod Error:", bres["error"])
else:
    print("Bulunan Urun:", bres["data"].get("name"))
    print("Alerjenler:", bres["data"].get("alerjenler"))

