from .ocr_service import extract_text_from_image
from .nlp_algorithm import parse_ocr_text_algorithmic
from .barcode_service import get_product_by_barcode

def tahmini_icerik_tablosu(icerikler, toplam_miktar=100):
    if not icerikler:
        return []
    
    weights = [i.get("miktar") if i.get("miktar") is not None else 1 for i in icerikler]
    toplam_weight = sum(weights)
    if toplam_weight == 0: toplam_weight = 1
        
    miktarlar = [round(float(w) / float(toplam_weight) * toplam_miktar, 2) for w in weights]
    fark = round(toplam_miktar - sum(miktarlar), 2)
    if fark != 0 and len(miktarlar) > 0:
        miktarlar[0] += fark

    oranlar = [round(m / toplam_miktar * 100, 2) for m in miktarlar]
    
    sonuc = []
    for idx, icerik in enumerate(icerikler):
        sonuc.append({
            "bilesen": icerik.get("isim", "Bilinmeyen"),
            "miktar_g": miktarlar[idx],
            "oran_yuzde": oranlar[idx],
            "kategori": icerik.get("kategori", "-"),
            "risk_seviyesi": icerik.get("risk_seviyesi", "-")
        })
    return sonuc

def analyze_image(image_bytes):
    try:
        text = extract_text_from_image(image_bytes)
        if len(text) < 10:
            return {"error": "Resimden yeterince metin okunamadı. Lütfen net bir fotoğraf çekin."}
            
        # Dış API yerine kendi yazdığımız yerel NLP algoritması çağrılır
        result = parse_ocr_text_algorithmic(text)
        
        # Oranları 100g üzerinden normalize et
        result["icerikler_tablosu"] = tahmini_icerik_tablosu(result.get("icerikler", []))
        
        return {
            "source": "AI_OCR",
            "raw_text": text,
            "data": result
        }
    except Exception as e:
        return {"error": str(e)}

def analyze_barcode(barcode):
    try:
        product_data = get_product_by_barcode(barcode)
        if not product_data:
            return {"error": "Barkod veritabanında bulunamadı."}
            
        product_data["icerikler_tablosu"] = tahmini_icerik_tablosu(product_data.get("icerikler", []))
        
        return {
            "source": "BARCODE",
            "data": product_data
        }
    except Exception as e:
        return {"error": str(e)}
