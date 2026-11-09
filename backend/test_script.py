import os
import sys
import django
import json

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from api.services.analysis_service import analyze_image, analyze_barcode
from api.services.ocr_service import extract_text_from_image

images_dir = "/Users/sevvalarslan/projects/BesinIcerikProjesi/images"

print("=== OCR TEST (ocr_test.jpeg) ===")
with open(os.path.join(images_dir, "ocr_test.jpeg"), 'rb') as f:
    res = analyze_image(f.read())
    if "error" in res:
        print("OCR ERROR:", res["error"])
    else:
        print("Saglik Puani:", res["data"].get("saglik_puani"))
        print("Alerjenler:", res["data"].get("alerjenler"))
        print("Icerikler (Ilk 3):", res["data"].get("icerikler")[:3] if res["data"].get("icerikler") else [])

print("\n=== BARKOD GORSELI TEST (barkod.png) ===")
with open(os.path.join(images_dir, "barkod.png"), 'rb') as f:
    text = extract_text_from_image(f.read())
    print("Gorselden Cikan Yazi:", text.strip().replace('\n', ' '))
    # Assuming text contains digits
    digits = ''.join(filter(str.isdigit, text))
    print("Bulunan Rakamlar:", digits)
    if len(digits) > 8:
        print("Barkodla Arama Yapiliyor...")
        bres = analyze_barcode(digits)
        if "error" in bres:
             print("Barkod Error:", bres["error"])
        else:
             print("Bulunan Urun:", bres["data"].get("name"))
             print("Alerjenler:", bres["data"].get("alerjenler"))

