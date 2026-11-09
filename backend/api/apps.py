from flask import Flask, request, jsonify
import cv2
import pytesseract
import numpy as np
import requests
import re

app = Flask(__name__)

# ============ SENİN YAZDIĞIN GÖRÜNTÜ İŞLEME FONKSİYONLARI ===========

def fix_rotation(image):
    try:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        coords = np.column_stack(np.where(gray > 0))
        # Eğer görüntü simsiyahsa hata vermesin
        if coords.size == 0:
            return image
        
        angle = cv2.minAreaRect(coords)[-1]
        if angle < -45:
            angle = -(90 + angle)
        else:
            angle = -angle
        
        (h, w) = image.shape[:2]
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, angle, 1.0)
        rotated = cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
        return rotated
    except:
        return image

def enhance_image(img):
    try:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # Gürültü temizleme (Senin ayarların: h=25)
        gray = cv2.fastNlMeansDenoising(gray, h=25)
        
        # Kontrast Artırma (CLAHE)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        gray = clahe.apply(gray)
        
        # Keskinleştirme
        kernel_sharp = np.array([[-1, -1, -1], [-1, 9, -1], [-1, -1, -1]])
        gray = cv2.filter2D(gray, -1, kernel_sharp)
        
        # Gamma Düzeltme
        gamma = 1.4
        invGamma = 1.0 / gamma
        table = np.array([((i / 255.0) ** invGamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
        gray = cv2.LUT(gray, table)
        
        # Adaptive Threshold
        thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 10)
        
        # Gürültü temizliği (Morphology)
        kernel = np.ones((1, 1), np.uint8)
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)
        
        return thresh
    except:
        return img

def normalize_turkish_chars(text):
    replacements = {
        "ı":"i", "İ":"I", "ğ":"g", "Ğ":"G", "ş":"s", "Ş":"S",
        "ö":"o", "Ö":"O", "ç":"c", "Ç":"C", "ü":"u", "Ü":"U"
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text

# ============ VERİ AYIKLAMA (REGEX) ============

def parse_data_from_text(text):
    # Satır satır ayır
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    
    # Sonuç sözlüğü
    data = {
        'enerji': '-', 'protein': '-', 'yag': '-', 
        'karbonhidrat': '-', 'seker': '-', 'tuz': '-',
        'icerik': 'İçerik metni tespit edilemedi.'
    }

    # 1. İçindekiler Kısmını Bulma (Senin mantığın)
    icerik_baslangici = None
    for i, line in enumerate(lines):
        line_lower = line.lower()
        if any(word in line_lower for word in ["icindekiler", "ingredients", "content"]):
            icerik_baslangici = i
            break
        elif any(word in line_lower for word in ["seker", "sut", "milk", "yag", "cocoa", "tozu"]):
             if icerik_baslangici is None: icerik_baslangici = i

    if icerik_baslangici is not None:
        # Sonraki 10 satırı birleştirip içerik yapıyoruz
        data['icerik'] = " ".join(lines[icerik_baslangici:icerik_baslangici+10])

    # 2. Besin Değerlerini Bulma (Regex)
    for line in lines:
        # Örn: "Protein 10g" veya "Enerji 500 kcal"
        if re.search(r"[\d,.]+\s*(kcal|kj|g|mg|µg)", line.lower()):
            match = re.match(r"([A-Za-z\s]+)[:\-]?\s*([\d,.]+)\s*(kcal|kj|g|mg|µg)?", line.strip())
            if match:
                isim = match.group(1).strip().lower()
                deger = match.group(2).replace(",", ".")
                birim = match.group(3) if match.group(3) else ""
                
                full_deger = f"{deger} {birim}"

                if "enerji" in isim or "energy" in isim: data['enerji'] = full_deger
                elif "protein" in isim: data['protein'] = full_deger
                elif "yag" in isim or "fat" in isim: data['yag'] = full_deger
                elif "karbon" in isim or "carb" in isim: data['karbonhidrat'] = full_deger
                elif "seker" in isim or "sugar" in isim: data['seker'] = full_deger
                elif "tuz" in isim or "salt" in isim: data['tuz'] = full_deger

    return data

# ============ API ENDPOINTLERİ ============

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'Dosya yok'}), 400
    
    try:
        # 1. Fotoğrafı al
        file = request.files['file']
        file_bytes = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        # 2. SENİN GÖRÜNTÜ İŞLEME FONKSİYONLARINI ÇAĞIR
        img = fix_rotation(img)
        processed_img = enhance_image(img)

        # 3. OCR (Okuma)
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(processed_img, lang='tur+eng', config=custom_config)
        text_norm = normalize_turkish_chars(text)
        
        print(f"--- OKUNAN METİN ---\n{text_norm}\n--------------------")

        # 4. Verileri Ayıkla
        result = parse_data_from_text(text_norm)
        result['isim'] = "OCR Taraması"
        result['marka'] = "-"
        result['veri_kaynagi'] = "OCR"

        return jsonify(result)
    
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/barcode', methods=['POST'])
def get_product_by_barcode():
    data = request.json
    barkod = data.get('barcode')
    
    if not barkod:
        return jsonify({'error': 'Barkod yok'}), 400

    url = f"https://world.openfoodfacts.org/api/v0/product/{barkod}.json"
    try:
        response = requests.get(url, timeout=10)
        product_data = response.json()

        if product_data.get('status') == 1:
            product = product_data['product']
            nutriments = product.get('nutriments', {})
            
            result = {
                'isim': product.get('product_name', 'Bilinmeyen Ürün'),
                'marka': product.get('brands', 'Bilinmiyor'),
                'icerik': product.get('ingredients_text_tr', product.get('ingredients_text', 'Bilgi yok')),
                'enerji': f"{nutriments.get('energy-kcal_100g', 0)} kcal",
                'protein': f"{nutriments.get('proteins_100g', 0)} g",
                'yag': f"{nutriments.get('fat_100g', 0)} g",
                'karbonhidrat': f"{nutriments.get('carbohydrates_100g', 0)} g",
                'seker': f"{nutriments.get('sugars_100g', 0)} g",
                'tuz': f"{nutriments.get('salt_100g', 0)} g",
                'veri_kaynagi': "Barkod"
            }
            return jsonify(result)
        else:
            return jsonify({'error': 'Ürün bulunamadı'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)