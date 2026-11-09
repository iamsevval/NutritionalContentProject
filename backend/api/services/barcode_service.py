import requests
from .ai_service import get_product_info_from_ai_by_barcode

def get_product_by_barcode(barcode):
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    headers = {"User-Agent": "BesinIcerikProjesiApp/1.0 (Contact: user@example.com)"}
    try:
        response = requests.get(url, headers=headers, timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == 1:
                product = data["product"]
                return parse_openfoodfacts_data(product)
    except Exception as e:
        print("OpenFoodFacts hatası:", e)
        
    # Eğer API'de bulunamadıysa AI (Web Scraping Simülasyonu) ile internetten araştır
    ai_result = get_product_info_from_ai_by_barcode(barcode)
    if ai_result:
        return ai_result
        
    return None

def parse_openfoodfacts_data(product):
    
    icerik_text = product.get("ingredients_text", "")
    icerikler_raw = [x.strip() for x in icerik_text.split(",") if x.strip()]
    icerikler = [{"isim": x, "miktar": None} for x in icerikler_raw]
    
    nutriments = product.get("nutriments", {})
    
    # Basit oran tahmini (AI yoksa)
    for i in icerikler:
        isim = i["isim"].lower()
        if "şeker" in isim or "sugar" in isim:
            i["miktar"] = nutriments.get("sugars_100g", 0)
        elif "yağı" in isim or "cocoa fat" in isim or "fat" in isim:
            i["miktar"] = nutriments.get("fat_100g", 0)
        elif "kakao" in isim or "protein" in isim:
            i["miktar"] = nutriments.get("proteins_100g", 0)
        else:
            i["miktar"] = 1
            
    # Alerjenler
    allergens = product.get("allergens_tags", [])
    allergens = [a.replace("en:", "").replace("tr:", "").capitalize() for a in allergens]
    if not allergens:
        allergens = ["Bilinmiyor"]
    
    # Sağlık Skoru (Nutriscore)
    nutriscore = product.get("nutriscore_grade", "bilinmiyor").upper()
    
    # Puan hesabı
    score_map = {"A": 90, "B": 75, "C": 50, "D": 35, "E": 20}
    saglik_puani = score_map.get(nutriscore, 50)
    
    return {
        "icerikler": icerikler,
        "besinler": nutriments,
        "alerjenler": allergens,
        "saglik_puani": saglik_puani,
        "saglik_yorumu": f"OpenFoodFacts Nutriscore Sınıfı: {nutriscore}"
    }
