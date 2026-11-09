from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from .models import UserProfile, ScanHistory
from .services.analysis_service import analyze_image, analyze_barcode
import json

class RegisterAPI(APIView):
    def post(self, request):
        try:
            username = request.data.get('username')
            password = request.data.get('password')
            allergies = request.data.get('allergies', '')
            diseases = request.data.get('diseases', '')
            
            if not username or not password:
                return Response({'durum': 'hata', 'mesaj': 'Kullanıcı adı ve şifre zorunlu!'}, status=400)
                
            if len(password) < 4:
                return Response({'durum': 'hata', 'mesaj': 'Şifre çok kısa. Lütfen daha uzun bir şifre girin.'}, status=400)
                
            if User.objects.filter(username=username).exists():
                return Response({'durum': 'hata', 'mesaj': 'Bu kullanıcı adı zaten alınmış.'}, status=400)
                
            user = User.objects.create_user(username=username, password=password)
            UserProfile.objects.create(user=user, allergies=allergies, diseases=diseases)
            
            return Response({'durum': 'basarili', 'user_id': user.id})
        except Exception as e:
            return Response({'durum': 'hata', 'mesaj': f'Kayıt olurken hata oluştu: {str(e)}'}, status=500)

class LoginAPI(APIView):
    def post(self, request):
        try:
            username = request.data.get('username')
            password = request.data.get('password')
            user = authenticate(username=username, password=password)
            
            if user is not None:
                profile = UserProfile.objects.filter(user=user).first()
                allergies = profile.allergies if profile else ""
                diseases = profile.diseases if profile else ""
                return Response({
                    'durum': 'basarili', 
                    'user_id': user.id,
                    'username': user.username,
                    'allergies': allergies,
                    'diseases': diseases
                })
            else:
                return Response({'durum': 'hata', 'mesaj': 'Geçersiz kullanıcı adı veya şifre!'}, status=401)
        except Exception as e:
            return Response({'durum': 'hata', 'mesaj': f'Giriş yaparken hata: {str(e)}'}, status=500)

class ProfileAPI(APIView):
    def get(self, request, user_id):
        try:
            profile = UserProfile.objects.get(user_id=user_id)
            return Response({
                'durum': 'basarili', 
                'allergies': profile.allergies,
                'diseases': profile.diseases
            })
        except:
            return Response({'durum': 'hata', 'mesaj': 'Kullanıcı bulunamadı.'}, status=404)
            
    def post(self, request, user_id):
        try:
            profile, created = UserProfile.objects.get_or_create(user_id=user_id)
            profile.allergies = request.data.get('allergies', profile.allergies)
            profile.diseases = request.data.get('diseases', profile.diseases)
            profile.save()
            return Response({'durum': 'basarili', 'mesaj': 'Profil güncellendi.'})
        except:
            return Response({'durum': 'hata', 'mesaj': 'Kullanıcı bulunamadı.'}, status=404)

class HistoryAPI(APIView):
    def get(self, request, user_id):
        history = ScanHistory.objects.filter(user_id=user_id).order_by('-date_scanned')
        data = []
        for h in history:
            data.append({
                'id': h.id,
                'date': h.date_scanned.strftime('%Y-%m-%d %H:%M'),
                'product_name': h.product_name,
                'health_score': h.health_score,
                'allergens_found': h.allergens_found,
                'is_safe': h.is_safe
            })
        return Response({'durum': 'basarili', 'history': data})

import os
import json
from django.conf import settings

class PopularProductsAPI(APIView):
    def get(self, request):
        user_id = request.query_params.get('user_id')
        
        # Yerel Veriseti (Dataset) dosyasını okuma
        dataset_path = os.path.join(settings.BASE_DIR, 'data', 'products_dataset.json')
        products = []
        try:
            with open(dataset_path, 'r', encoding='utf-8') as f:
                products = json.load(f)
        except Exception as e:
            products = []

        filtered_products = []

        if user_id:
            try:
                user = User.objects.get(id=user_id)
                profile = UserProfile.objects.get(user=user)
                # Virgülle ayrılmış etiketleri listeye çevir ve küçük harf yap
                base_user_tags = [normalize_turkish(a.strip()) for a in (profile.allergies or "").split(",") if a.strip()]
                
                # Çapraz bulaşma genişletmesi
                user_tags = set(base_user_tags)
                for ut in base_user_tags:
                    for main_allergen, sub_items in CROSS_CONTAMINATION_MAP.items():
                        if main_allergen in ut or ut in main_allergen:
                            user_tags.add(main_allergen)
                            for sub in sub_items:
                                user_tags.add(sub)
                
                for p in products:
                    found_allergens = p["data"].get("alerjenler", [])
                    matched = []
                    
                    # Alerjen listesinde kontrol
                    for fa in found_allergens:
                        for ut in user_tags:
                            if ut in fa.lower() or fa.lower() in ut:
                                if fa not in matched:
                                    matched.append(fa)
                    
                    # İçindekiler Tablosunda detaylı kontrol
                    icerikler_tablosu = p["data"].get("icerikler_tablosu", [])
                    for icerik in icerikler_tablosu:
                        bilesen = icerik.get("bilesen", "").lower()
                        for ut in user_tags:
                            if ut in bilesen:
                                if bilesen.title() not in matched:
                                    matched.append(bilesen.title())
                                    
                    p["data"]["hayati_uyari"] = matched if len(matched) > 0 else []
                    p["data"]["is_safe"] = len(matched) == 0
                    
                    # Diyet filtresi (Eğer kullanıcı Vegan ise vs. ek kurallar konabilir, şimdilik sadece is_safe olanları filtreliyoruz)
                    # Kullanıcının anket sonucuna göre sadece ona UYGUN / GÜVENLİ olanları göster
                    if p["data"]["is_safe"]:
                        filtered_products.append(p)
                        
            except Exception as e:
                filtered_products = products
        else:
            # Kullanıcı girişi yoksa hepsini göster
            for p in products:
                p["data"]["hayati_uyari"] = []
                p["data"]["is_safe"] = True
            filtered_products = products
                
        return Response({'durum': 'basarili', 'products': filtered_products})

def normalize_turkish(text):
    if not text: return ""
    replacements = {
        'ç': 'c', 'Ç': 'c',
        'ğ': 'g', 'Ğ': 'g',
        'ı': 'i', 'I': 'i', 'İ': 'i',
        'ö': 'o', 'Ö': 'o',
        'ş': 's', 'Ş': 's',
        'ü': 'u', 'Ü': 'u',
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.lower()

CROSS_CONTAMINATION_MAP = {
    "sut": ["peynir alti suyu", "kazein", "laktoz", "krema", "tereyagi", "sut tozu", "kazeinat", "peynir", "yogurt"],
    "gluten": ["bugday", "arpa", "cavdar", "yulaf", "malt", "nisasta", "galeta", "kepek", "bulgur", "irmik"],
    "soya": ["soya lesitini", "soya fasulyesi", "edamame", "soya sosu", "tofu"],
    "yumurta": ["albumin", "globulin", "livetin", "lizozim", "mayonez", "ovalbumin", "ovomusin"],
    "yer fistigi": ["fistik ezmesi", "fistik yagi", "yer fistigi", "arachis", "fistik"],
    "findik": ["findik puresi", "findik yagi", "ceviz", "badem", "kaju", "antep fistigi", "macadamia"]
}

# Tıbbi Hastalık - Tolerans Veritabanı
DISEASE_DB_PATH = os.path.join(settings.BASE_DIR, 'data', 'disease_tolerance_db.json')
try:
    with open(DISEASE_DB_PATH, 'r', encoding='utf-8') as f:
        DISEASE_DB = json.load(f)
except Exception as e:
    DISEASE_DB = {}

def check_safety_and_save(user_id, data):
    if not user_id: return
    try:
        user = User.objects.get(id=user_id)
        profile = UserProfile.objects.get(user=user)
        base_user_allergies = [normalize_turkish(a.strip()) for a in (profile.allergies or "").split(",") if a.strip()]
        
        # Kullanıcının alerjilerini çapraz bulaşma / gizli isimlerle genişlet (Gelişmiş Alerjen Taraması)
        extended_allergies = set(base_user_allergies)
        for ua in base_user_allergies:
            for main_allergen, sub_items in CROSS_CONTAMINATION_MAP.items():
                if main_allergen in ua or ua in main_allergen:
                    extended_allergies.add(main_allergen)
                    for sub in sub_items:
                        extended_allergies.add(sub)
        
        found_allergens = data.get("data", {}).get("alerjenler", [])
        matched = []
        for fa in found_allergens:
            nfa = normalize_turkish(fa)
            for ua in extended_allergies:
                if ua in nfa or nfa in ua:
                    if fa not in matched:
                        matched.append(fa)
                        
        icerikler_tablosu = data.get("data", {}).get("icerikler_tablosu", [])
        for icerik in icerikler_tablosu:
            raw_bilesen = icerik.get("bilesen", "")
            nbilesen = normalize_turkish(raw_bilesen)
            for ua in extended_allergies:
                if ua in nbilesen:
                    if raw_bilesen.title() not in matched:
                        matched.append(raw_bilesen.title() + " (Alerjen Uyarı)")

        # --- 2. Tıbbi Kural Motoru (Medical Tolerance Engine) ---
        user_diseases = profile.get_disease_list()
        besinler = data.get("data", {}).get("besinler", {})
        
        for ud in user_diseases:
            # Hastalık DB'de varsa kuralları işlet
            if ud in DISEASE_DB:
                disease_rules = DISEASE_DB[ud]
                yasakli = disease_rules.get("kesinlikle_yasakli", [])
                sinirlar = disease_rules.get("tolerans_siniri", {})
                uyari = disease_rules.get("uyari_mesaji", f"{ud} hastaları için riskli ürün.")
                
                # Yasaklı İçerik Kontrolü
                for icerik in icerikler_tablosu:
                    bilesen_adi = normalize_turkish(icerik.get("bilesen", ""))
                    for y in yasakli:
                        if normalize_turkish(y) in bilesen_adi:
                            uyari_metni = f"{ud} Uyarısı: Kesinlikle yasaklı madde ({icerik.get('bilesen')}) içeriyor! {uyari}"
                            if uyari_metni not in matched:
                                matched.append(uyari_metni)
                                
                # Tolerans/Sınır Kontrolü (Besin Değerleri)
                for besin_adi, besin_degeri in besinler.items():
                    for sinir_adi, sinir_degeri in sinirlar.items():
                        # Sınır adını besin adında ara (Örn: Sınır "Şeker", Besin "Şeker (g)")
                        if normalize_turkish(sinir_adi.split()[0]) in normalize_turkish(besin_adi):
                            try:
                                val = float(str(besin_degeri).replace(',', '.'))
                                if val > sinir_degeri:
                                    uyari_metni = f"{ud} Uyarısı: Tolerans sınırı aşıldı! (Maksimum {sinir_degeri}g olmalı, üründe {val}g var). {uyari}"
                                    if uyari_metni not in matched:
                                        matched.append(uyari_metni)
                            except:
                                pass

        is_safe = len(matched) == 0
        data["data"]["hayati_uyari"] = matched if len(matched) > 0 else []
        data["data"]["is_safe"] = is_safe
        
        # Save history
        product_name = "Bilinmeyen Ürün"
        if data.get("data", {}).get("icerikler"):
            product_name = data["data"]["icerikler"][0].get("isim", "Bilinmeyen")
            
        ScanHistory.objects.create(
            user=user,
            product_name=product_name,
            health_score=str(data.get("data", {}).get("saglik_puani", "")),
            allergens_found=",".join(found_allergens),
            is_safe=is_safe
        )
    except Exception as e:
        print("History save error:", e)

class GoruntuIslemeAPI(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        if 'file' not in request.data:
            return Response({'durum': 'hata', 'mesaj': 'Dosya bulunamadı!'}, status=400)

        file_obj = request.data['file']
        user_id = request.data.get('user_id')
        
        try:
            image_bytes = file_obj.read()
            analiz_sonucu = analyze_image(image_bytes)
            
            if "error" in analiz_sonucu:
                return Response({'durum': 'hata', 'mesaj': analiz_sonucu["error"]}, status=400)
            
            check_safety_and_save(user_id, analiz_sonucu)    
            return Response({'durum': 'basarili', 'veri': analiz_sonucu})
        except Exception as e:
            return Response({'durum': 'hata', 'mesaj': str(e)}, status=500)

class BarkodAPI(APIView):
    def post(self, request, *args, **kwargs):
        barkod = request.data.get('barcode')
        user_id = request.data.get('user_id')
        
        if not barkod:
            return Response({'durum': 'hata', 'mesaj': 'Barkod numarası eksik!'}, status=400)
            
        try:
            analiz_sonucu = analyze_barcode(barkod)
            if "error" in analiz_sonucu:
                return Response({'durum': 'hata', 'mesaj': analiz_sonucu["error"]}, status=404)
            
            check_safety_and_save(user_id, analiz_sonucu)    
            return Response({'durum': 'basarili', 'veri': analiz_sonucu})
        except Exception as e:
            return Response({'durum': 'hata', 'mesaj': str(e)}, status=500)