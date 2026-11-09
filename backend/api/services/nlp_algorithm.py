import os
import json
import re
import difflib
from django.conf import settings

# Load the local knowledge base
db_path = os.path.join(settings.BASE_DIR, 'data', 'ingredient_db.json')
try:
    with open(db_path, 'r', encoding='utf-8') as f:
        INGREDIENT_DB = json.load(f)
except Exception as e:
    print("Veritabanı yüklenemedi:", e)
    INGREDIENT_DB = {}

def normalize_text(text):
    text = text.lower()
    replacements = {
        'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
        'i̇': 'i', '\n': ' '
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text

def parse_ocr_text_algorithmic(text):
    """
    Kural tabanlı ve Bulanık Mantık (Fuzzy Logic) kullanan yerel NLP algoritması.
    Dış API kullanmaz, tamamen cihazda çalışır.
    """
    raw_text = normalize_text(text)
    
    # 1. Metni parçalara ayırma (Virgüllerden veya 've' bağlacından bölme)
    # OCR genellikle virgülleri nokta gibi görebilir, bu yüzden regex ile ayırıyoruz.
    tokens = re.split(r'[,.\n]+|\bve\b', raw_text)
    
    icerikler = []
    bulunan_alerjenler = set()
    risk_skoru = 100
    
    for token in tokens:
        token = token.strip()
        if len(token) < 3:
            continue
            
        # Miktar/Yüzde çıkarma (örn: %3 veya 5g)
        miktar_match = re.search(r'%(\d+[\.,]?\d*)', token) or re.search(r'(\d+[\.,]?\d*)\s*%', token)
        miktar_val = None
        if miktar_match:
            try:
                miktar_val = float(miktar_match.group(1).replace(',', '.'))
            except:
                pass
                
        # Sayıları ve sembolleri temizle, sadece kelime kalsın
        kelime = re.sub(r'[\d%.,()\[\]]', '', token).strip()
        if len(kelime) < 3:
            continue
            
        # 2. Bulanık Mantık (Fuzzy Matching) ile Veritabanı Eşleştirme
        # Veritabanındaki tüm anahtarları listele
        db_keys = list(INGREDIENT_DB.keys())
        
        # En yakın eşleşmeyi bul (Minimum %70 benzerlik)
        eslesmeler = difflib.get_close_matches(kelime, db_keys, n=1, cutoff=0.7)
        
        if eslesmeler:
            eslesen_anahtar = eslesmeler[0]
            db_bilgi = INGREDIENT_DB[eslesen_anahtar]
            
            # Eğer bu içerik daha önce eklenmemişse ekle
            if not any(i['isim'] == db_bilgi['isim'] for i in icerikler):
                icerikler.append({
                    "isim": db_bilgi["isim"],
                    "miktar": miktar_val,
                    "kategori": db_bilgi["kategori"],
                    "risk_seviyesi": db_bilgi["risk_seviyesi"]
                })
                
                # Alerjenleri topla
                for a in db_bilgi["alerjenler"]:
                    bulunan_alerjenler.add(a)
                    
                # Risk skorunu hesapla
                if db_bilgi["risk_seviyesi"] == "Yüksek":
                    risk_skoru -= 15
                elif db_bilgi["risk_seviyesi"] == "Orta":
                    risk_skoru -= 5
        else:
            # Eşleşmeyen kelimeleri "Bilinmeyen" veya "Diğer" olarak yakalayabiliriz.
            # Şimdilik temiz kelimeyi bilinmeyen olarak ekleyelim ama OCR çöpü olma ihtimaline karşı filtreleyebiliriz.
            if len(kelime.split()) <= 3: # Çok uzun saçma metinleri yoksay
                icerikler.append({
                    "isim": kelime.title(),
                    "miktar": miktar_val,
                    "kategori": "Bilinmeyen (Fuzzy)",
                    "risk_seviyesi": "Bilinmeyen"
                })
                
    # Güvenlik Sınırı
    risk_skoru = max(0, min(100, risk_skoru))
    
    yorum = "Genel olarak sağlıklı."
    if risk_skoru < 50:
        yorum = "Yüksek riskli katkı maddeleri içeriyor. Tüketimi sınırlandırılmalıdır."
    elif risk_skoru < 80:
        yorum = "Orta düzeyde riskli maddeler içeriyor."
        
    # Basit besin değeri tahmini (Normalde bu OCR'dan 'Enerji: 100kcal' regex ile çekilmeli)
    # Şimdilik demo amaçlı
    besinler = {}
    enerji_match = re.search(r'enerji.*?(\d+)', raw_text)
    seker_match = re.search(r'seker.*?(\d+)', raw_text)
    if enerji_match:
        besinler["Enerji (kcal)"] = enerji_match.group(1)
    if seker_match:
        besinler["Şeker (g)"] = seker_match.group(1)

    return {
        "icerikler": icerikler,
        "besinler": besinler,
        "alerjenler": list(bulunan_alerjenler),
        "saglik_puani": risk_skoru,
        "saglik_yorumu": yorum + " (Kural Tabanlı Algoritma)"
    }
