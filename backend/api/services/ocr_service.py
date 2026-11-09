import cv2
import easyocr
import numpy as np

def fix_rotation(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    coords = np.column_stack(np.where(gray > 0))
    if len(coords) == 0:
        return image
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
    (h, w) = image.shape[:2]
    M = cv2.getRotationMatrix2D((w // 2, h // 2), angle, 1.0)
    rotated = cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    return rotated

def extract_text_from_image(image_bytes):
    # 1. Byte verisini resme çevir
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        raise ValueError("Resim okunamadı.")
        
    img = fix_rotation(img)
    
    # --- Görüntü Ön İşleme (Image Preprocessing) ---
    # 1. Gri tonlamaya çevir
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 2. Kontrastı artırmak için CLAHE uygula
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    contrast_enhanced = clahe.apply(gray)
    
    # 3. Gürültüyü azalt (Denoising)
    denoised = cv2.bilateralFilter(contrast_enhanced, 9, 75, 75)
    
    processed_img = denoised
    
    # 2. EasyOCR ile oku
    reader = easyocr.Reader(['tr', 'en'], gpu=False)
    results = reader.readtext(processed_img, detail=0, paragraph=True)
    text = " ".join(results)
    
    return text
