# 🥗 NutritionalContentProject (Akıllı Besin ve Alerjen Analiz Sistemi)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Django](https://img.shields.io/badge/Django-092E20?style=for-the-badge&logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Google Gemini AI](https://img.shields.io/badge/Google%20Gemini%20AI-8E75C2?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)
[![EasyOCR](https://img.shields.io/badge/EasyOCR-FF6F00?style=for-the-badge&logo=opencv&logoColor=white)](https://github.com/JaidedAI/EasyOCR)

> Yapay zekâ ve optik karakter tanıma (OCR) destekli akıllı besin içeriği ve alerjen tespit platformu.

---

## 📱 Proje Hakkında

**NutritionalContentProject**, kullanıcıların paketli gıda etiketlerini telefon kameralarıyla taratarak veya barkodunu okutarak içeriğindeki alerjenleri, zararlı katkı maddelerini ve besin değerlerini anında analiz etmelerini sağlayan tam kapsamlı bir mobil sağlık asistanıdır.

Kullanıcının sağlık profiline (Çölyak, Diyabet, Laktoz İntoleransı, Hipertansiyon vb.) göre özel risk değerlendirmesi yapar ve **Google Gemini Yapay Zekâsı** ile içerik metinlerini ayrıştırarak kişiselleştirilmiş tüketim tavsiyeleri sunar.

---

## ✨ Temel Özellikler

- 📷 **OCR ile İçerik Analizi:** Paketli gıdaların içindekiler kısmının fotoğrafını çekerek metinleri optik karakter tanıma ile otomatik okuma.
- 🔍 **Barkod Okuma & Veritabanı Sorgulama:** Barkod taraması ile OpenFoodFacts ve yerel ürün veritabanından anında besin profili getirme.
- 🤖 **Gemini AI Destekli NLP:** İçerik listesindeki bileşenleri akıllıca ayrıştırma, oran tahminleme ve risk sınıflandırması.
- ⚠️ **Kişiselleştirilmiş Alerjen & Hastalık Uyarıları:** Kullanıcının profiline göre "Güvenli", "Dikkat" veya "Riskli" durumlarının anlık tespiti.
- 📊 **Besin Değerleri ve Günlük Takip:** Tüketilen gıdaların kalori, protein, karbonhidrat ve yağ değerlerini kaydetme.
- 📅 **Rutin & Takvim Entegrasyonu:** Beslenme alışkanlıklarını gün gün izleme ve favori ürünleri saklama.

---

## 🏗️ Proje Mimarisi

```text
NutritionalContentProject/
├── mobile/                     # Flutter Mobil Uygulama (iOS & Android)
│   ├── lib/
│   │   ├── screens/            # Uygulama ekranları (Home, Result, Quiz, Profile vb.)
│   │   ├── services/           # REST API servis entegrasyonu
│   │   ├── widgets/            # Yeniden kullanılabilir UI bileşenleri
│   │   └── theme/              # Tasarım sistemi ve tema ayarları
│   └── pubspec.yaml            # Mobil bağımlılıklar
│
├── backend/                    # Django REST API & Yapay Zekâ Motoru
│   ├── api/
│   │   ├── services/           # OCR, Barkod, Gemini AI, NLP ve Tolerans servisleri
│   │   ├── models.py           # Kullanıcı profilleri, hastalık ve besin modelleri
│   │   └── views.py            # API endpoint'leri (/upload/, /profile/ vb.)
│   ├── data/                   # Alerjen ve içerik referans veri setleri
│   └── manage.py
│
├── README.md                   # Proje dokümantasyonu
└── .gitignore                  # Git yapılandırma dosyası
```

---

## 🚀 Kurulum ve Çalıştırma

### 1. Depoyu Klonlayın
```bash
git clone https://github.com/iamsevval/NutritionalContentProject.git
cd NutritionalContentProject
```

---

### 2. Backend (Django) Kurulumu

```bash
cd backend

# Sanal ortam oluşturun ve aktif edin
python3 -m venv venv
source venv/bin/activate  # Windows için: venv\Scripts\activate

# Gerekli bağımlılıkları yükleyin
pip install django djangorestframework google-generativeai easyocr opencv-python pillow requests

# Veritabanı migrasyonlarını uygulayın
python manage.py migrate

# Gemini API anahtarınızı tanımlayın
export GEMINI_API_KEY="your-gemini-api-key"

# Sunucuyu başlatın
python manage.py runserver 0.0.0.0:8000
```

---

### 3. Mobile (Flutter) Kurulumu

```bash
cd ../mobile

# Paketleri yükleyin
flutter pub get

# Uygulamayı emülatörde veya gerçek cihazda başlatın
flutter run
```

> **Not:** Android emülatör üzerinde test yaparken `10.0.2.2:8000` adresi bilgisayarınızın yerel sunucusuna bağlanır. Gerçek cihazda test için bilgisayarınızın yerel IP adresini veya `ngrok` tünelini kullanabilirsiniz.

---

## 🛠️ Kullanılan Teknolojiler

| Katman | Teknoloji / Kütüphane | Kullanım Amacı |
| :--- | :--- | :--- |
| **Mobil UI** | Flutter, Dart | Çapraz platform (iOS & Android) kullanıcı arayüzü |
| **Backend API** | Django, Django REST Framework | RESTful servisler, veri yönetimi ve iş mantığı |
| **Yapay Zekâ** | Google Gemini Generative AI | Akıllı içerik ayrıştırma, semantik risk analizi |
| **Görüntü İşleme** | EasyOCR, OpenCV | Paket üzerinden optik metin tanıma (OCR) |
| **Harici API** | OpenFoodFacts API | Barkod üzerinden küresel gıda veritabanı sorgulama |

---

## 👥 Proje Ekibi & Katkıda Bulunanlar

- **Şevval Arslan** ([@iamsevval](https://github.com/iamsevval))
- Ortak Geliştirici Ekip Arkadaşı

---

## 📄 Lisans
Bu proje geliştirme aşamasındadır. Tüm hakları saklıdır.
