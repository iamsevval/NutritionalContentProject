import os
import sys
import django

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile
from api.views import check_safety_and_save
from api.services.analysis_service import analyze_barcode

print("=== BARKOD ÜZERİNDEN GÜVENLİK TESTİ ===")

# Test kullanıcısı oluştur (Alerjileri: Fındık, Süt)
user, created = User.objects.get_or_create(username="test_user_barcode")
profile, _ = UserProfile.objects.get_or_create(user=user)
profile.allergies = "fındık, süt, gluten"
profile.save()
print(f"Kullanıcı Alerjileri: {profile.allergies}\n")

# 1. Test: Nutella Barkodu (3017620422003)
print("1. ÜRÜN: NUTELLA (Barkod: 3017620422003)")
result_nutella = analyze_barcode("3017620422003")
if "error" not in result_nutella:
    check_safety_and_save(user.id, result_nutella)
    print("İçerikler:", [i.get("isim") for i in result_nutella["data"]["icerikler"]][:5], "...")
    print("Hayati Uyarılar:", result_nutella["data"].get("hayati_uyari"))
    print("Güvenli mi?:", result_nutella["data"].get("is_safe"))
else:
    print("Hata:", result_nutella["error"])

print("-" * 30)

# 2. Test: Coca Cola Barkodu (5449000131805)
print("2. ÜRÜN: COCA COLA (Barkod: 5449000131805)")
result_cola = analyze_barcode("5449000131805")
if "error" not in result_cola:
    check_safety_and_save(user.id, result_cola)
    print("İçerikler:", [i.get("isim") for i in result_cola["data"]["icerikler"]][:5], "...")
    print("Hayati Uyarılar:", result_cola["data"].get("hayati_uyari"))
    print("Güvenli mi?:", result_cola["data"].get("is_safe"))
else:
    print("Hata:", result_cola["error"])

