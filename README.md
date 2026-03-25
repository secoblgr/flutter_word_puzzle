# Word Puzzle - Kelime Bulmaca Oyunu

Harfleri karistirarak verilen ipucuna gore dogru kelimeyi bulmaya dayali, cok oyunculu ve cok dilli bir mobil kelime bulmaca oyunu.

Flutter + Firebase ile gelistirilmis, Clean Architecture prensiplerine uygun, production-ready bir uygulama.

---

## Ekran Goruntuleri

> Ekran goruntulerinizi `screenshots/` klasorune ekleyin ve asagidaki yollari guncelleyin.

| Giris Ekrani | Ana Sayfa | Kategori Secimi |
|:---:|:---:|:---:|
| ![Giris](screenshots/login.png) | ![Ana Sayfa](screenshots/home.png) | ![Kategori](screenshots/categories.png) |

| Oyun Ekrani | Sonuc Ekrani | Siralama |
|:---:|:---:|:---:|
| ![Oyun](screenshots/game.png) | ![Sonuc](screenshots/result.png) | ![Siralama](screenshots/leaderboard.png) |

| Arkadaslar | Duello Odasi | Profil |
|:---:|:---:|:---:|
| ![Arkadaslar](screenshots/friends.png) | ![Duello](screenshots/duel_room.png) | ![Profil](screenshots/profile.png) |

---

## Ozellikler

### Oyun Mekanikleri
- Karistirilan harflerden dogru kelimeyi bulma
- 10 zorluk seviyesi (3 harften 12+ harfe kadar)
- Seviye bazli ilerleme sistemi (Level 1-100)
- Zamanlayici tabanli puanlama (hizli cevap = daha cok puan)
- Her oyun icin 3 ipucu hakki (ilk dogru harfi yerlestirir)
- Cozulen kelimeler tekrar cikmaz
- Dogru/yanlis cevap ses efektleri
- Kategori bazli bagimsiz level ilerlemesi

### Kategoriler (10 Adet)
| Kategori | EN | TR |
|----------|----|----|
| Hayvanlar | 300 kelime | 300 kelime |
| Meslekler | 300 kelime | 300 kelime |
| Yiyecekler | 300 kelime | 300 kelime |
| Doga | 300 kelime | 300 kelime |
| Sporlar | 300 kelime | 300 kelime |
| Teknoloji | 300 kelime | 300 kelime |
| Muzik | 300 kelime | 300 kelime |
| Cografya | 300 kelime | 300 kelime |
| Bilim | 300 kelime | 300 kelime |
| Tarih | 300 kelime | 300 kelime |

**Toplam: 6.000 kelime** (3.000 EN + 3.000 TR)

### Cok Dilli Destek
- Ingilizce ve Turkce tam destek (189 cevirilmis metin)
- Ana sayfadan tek tusla dil degistirme
- Secilen dil tum sayfalara ve kelime bankalarina yansir
- Dil tercihi cihazda kalici olarak saklanir

### Kimlik Dogrulama
- Google ile giris (OAuth)
- Misafir (Guest) girisi - benzersiz Guest_XXXX isimlendirmesi
- Misafir hesabi cihaza bagli kalici oturum
- Misafir hesabini Google ile baglama destegi

### Profil Sistemi
- Kullanici adi degistirme
- Profil fotografi yukleme (Firebase Storage)
- Kamera ve galeri destegi
- 12 farkli emoji avatar secenegi
- Profil bilgileri liderlik tablosu ve arkadaslarda gosterilir

### Gunluk Gorevler ve Seri Sistemi
- **Hizli Tur** - 3 oyun tamamla → +50 XP
- **Duello Kazan** - 1 duello kazan → +80 XP
- **Arkadas Ekle** - 1 arkadas ekle → +30 XP
- Gunluk seri takibi (ardisik gunlerde oynama)
- XP ilerleme cubugu (1000 XP = 1 seviye)
- Her gun otomatik sifirlama

### Arkadas Sistemi
- 6 haneli benzersiz arkadas kodu
- Kod ile arkadas arama ve istek gonderme
- Istek kabul/reddetme mekanizmasi
- Real-time Firestore dinleyicileri ile anlik guncelleme
- Arkadasi kaydirarak silme (swipe-to-remove)
- Arkadas kartindan tek tusa duello daveti

### 1v1 Duello Sistemi
- Arkadaslara duello daveti gonderme
- Hangi sayfada olursa olsun popup bildirim ile davet alma
- Kabul/red mekanizmasi
- Ayni kelime seti uzerinde yarisma (Firestore senkronizasyonu)
- Kolaydan zora dogru kelime siralama (3-4-5-6-7-8 harf)
- Real-time puan takibi
- Her iki oyuncu bitirince sonuc karsilastirmasi
- Duello icinde 3 ipucu hakki
- Duellodan cikis onay diyalogu

### Siralama (Leaderboard)
- Global siralama - puana gore
- Ilk 3 icin ozel podium tasarimi
- Profil fotografi, seviye ve puan gosterimi

### Ses Efektleri
| Ses | Dosya | Tetiklenme |
|-----|-------|-----------|
| Dogru cevap | `correct.wav` | Oyun + Duello |
| Yanlis cevap | `wrong.wav` | Oyun + Duello |
| Ipucu | `hint.wav` | Ipucu kullanildiginda |
| Seviye gecme | `level_up.wav` | Level tamamlandiginda |
| Sure uyarisi | `timer_warning.wav` | Son 10 saniyede |

### Push Bildirimler (FCM)
- Duello daveti geldiginde push bildirim
- Arkadaslik istegi geldiginde push bildirim
- Duello kabul/red bildirimler
- Uygulama kapali olsa bile bildirimler gelir
- Firebase Cloud Functions ile otomatik tetikleme

---

## Teknik Mimari

### Clean Architecture

```
lib/
├── core/                          # Paylasilan altyapi
│   ├── error/                     # Failure ve Exception siniflari
│   ├── router/                    # GoRouter yapilandirmasi (11 route)
│   ├── theme/                     # Karanlik tema (Material 3 + Poppins)
│   ├── usecases/                  # Base UseCase arayuzu
│   ├── utils/                     # Yardimci siniflar
│   │   ├── app_strings.dart       # 189 cevirilmis metin (EN/TR)
│   │   ├── app_language.dart      # Dil yonetimi (Provider)
│   │   ├── sound_manager.dart     # Ses efektleri (Singleton)
│   │   ├── notification_manager.dart  # FCM + yerel bildirimler
│   │   ├── daily_quest_manager.dart   # Gunluk gorevler + seri
│   │   ├── responsive.dart        # Responsive tasarim
│   │   ├── constants.dart         # Uygulama sabitleri
│   │   └── score_calculator.dart  # Puanlama mantigi
│   └── widgets/                   # DuelInviteListener (global)
│
├── features/                      # Ozellik modulleri
│   ├── auth/                      # Kimlik dogrulama + Profil
│   │   ├── data/                  # DataSource, Model, Repository Impl
│   │   ├── domain/                # Entity, Repository Contract, UseCase
│   │   └── presentation/         # BLoC, Sayfa, Widget
│   │
│   ├── game/                      # Kelime bulmaca oyunu
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       ├── word_bank/     # 10 EN kategori (300 kelime/kategori)
│   │   │       └── word_bank_tr/  # 10 TR kategori (300 kelime/kategori)
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── duel/                      # 1v1 duello sistemi
│   ├── friends/                   # Arkadas yonetimi
│   ├── leaderboard/               # Global siralama
│   └── home/                      # Ana ekran + Gunluk Gorevler
│
├── injection/                     # Dependency Injection (get_it)
├── main.dart                      # Uygulama girisi + Firebase init
└── firebase_options.dart          # Firebase yapilandirmasi

functions/                         # Firebase Cloud Functions
├── index.js                       # 4 Firestore trigger fonksiyonu
└── package.json                   # Node.js 20 bagimliliklari
```

### Katmanlar

| Katman | Sorumluluk | Icerik |
|--------|-----------|--------|
| **Domain** | Is mantigi | Entity, Repository (abstract), UseCase |
| **Data** | Dis veri | DataSource, Model, Repository (impl) |
| **Presentation** | Kullanici arayuzu | BLoC, Page, Widget |

### State Management: BLoC Pattern

```
Event (Kullanici eylemi) → BLoC (Is mantigi) → State (UI guncelleme)
```

**5 BLoC:**
| BLoC | Gorev |
|------|-------|
| `AuthBloc` | Kimlik dogrulama + profil guncelleme |
| `GameBloc` | Oyun oturumu yonetimi |
| `LeaderboardBloc` | Siralama verileri |
| `FriendsBloc` | Arkadas listesi, istekler, arama |
| `DuelBloc` | Duello oturumlari, davetler, skor |

### Hata Yonetimi

`Either<Failure, Success>` (dartz paketi) ile fonksiyonel hata yonetimi:

```dart
// Domain katmaninda
Future<Either<Failure, UserEntity>> signInWithGoogle();

// Presentation katmaninda
state is AuthError → hata mesaji goster
state is AuthAuthenticated → ana sayfaya yonlendir
```

**Failure Turleri:** `ServerFailure`, `AuthFailure`, `GameFailure`, `DuelFailure`, `CacheFailure`

---

## Firebase Entegrasyonu

### Kullanilan Servisler

| Servis | Kullanim |
|--------|---------|
| **Firebase Auth** | Google OAuth + Anonim giris |
| **Cloud Firestore** | Kullanici verileri, skorlar, duellolar, arkadasliklar |
| **Firebase Storage** | Profil fotograflari |
| **Firebase Messaging** | FCM push bildirimler |
| **Cloud Functions** | Bildirim trigger fonksiyonlari |

### Firestore Koleksiyonlari

| Koleksiyon | Amac |
|-----------|------|
| `users` | Kullanici profilleri, skorlar, seviyeler, arkadaslar, FCM token |
| `scores` | Skor gecmisi |
| `duels` | Duello odalari ve sonuclari |
| `friend_requests` | Arkadaslik istekleri |
| `duel_invites` | Duello davetleri |

### Cloud Functions (4 Adet)

| Fonksiyon | Tetikleyici | Bildirim |
|-----------|------------|----------|
| `onDuelInviteCreated` | Duello daveti olusturulunca | "X seni duelloya davet etti! ⚔️" |
| `onFriendRequestCreated` | Arkadaslik istegi gonderilince | "X arkadasin olmak istiyor! 👥" |
| `onDuelInviteAccepted` | Duello kabul edilince | "X duelloyu kabul etti! ⚔️" |
| `onDuelInviteRejected` | Duello reddedilince | "X duelloyu reddetti 😔" |

### Real-Time Ozellikler
- `watchDuel(duelId)` - Duello icerisinde anlik skor guncellemesi
- `watchPendingDuelInvites(userId)` - Duello daveti bildirimleri
- `user.friends` dinleyicisi - Arkadas listesi degisiklikleri
- `friend_requests` dinleyicisi - Gelen arkadaslik istekleri

---

## Puanlama Sistemi

```
Puan = (100 + ZamanBonusu) x ZorlukCarpani
```

| Parametre | Deger |
|-----------|-------|
| Temel Puan | 100 |
| Zaman Bonusu | `kalanSaniye x 2` (max 200) |
| Kolay Carpan (Lv 1-30) | 1.0x |
| Orta Carpan (Lv 31-60) | 1.5x |
| Zor Carpan (Lv 61+) | 2.0x |

### Zamanlayici
- Seviye basi: **120 saniye**
- Dogru cevap bonusu: **+8 saniye**
- Duello suresi: **300 saniye** (5 dakika)

### XP Sistemi
| Kaynak | XP |
|--------|-----|
| Gunluk Gorev: Hizli Tur (3 oyun) | +50 XP |
| Gunluk Gorev: Duello Kazan | +80 XP |
| Gunluk Gorev: Arkadas Ekle | +30 XP |
| 1 Seviye = 1000 XP | |

---

## Kullanilan Paketler

| Paket | Versiyon | Amac |
|-------|---------|------|
| `flutter_bloc` | 9.1.0 | State management (BLoC) |
| `get_it` | 8.0.3 | Dependency Injection |
| `go_router` | 14.8.1 | Deklaratif routing |
| `firebase_core` | 3.12.1 | Firebase cekirdek |
| `firebase_auth` | 5.5.2 | Kimlik dogrulama |
| `cloud_firestore` | 5.6.6 | Veritabani |
| `firebase_storage` | 12.4.4 | Dosya depolama |
| `firebase_messaging` | 15.2.4 | Push bildirimler |
| `google_sign_in` | 6.2.2 | Google OAuth |
| `image_picker` | 1.1.2 | Kamera/galeri erisimi |
| `audioplayers` | 6.1.0 | Ses efektleri |
| `flutter_local_notifications` | 18.0.1 | Yerel bildirimler |
| `dartz` | 0.10.1 | Fonksiyonel hata yonetimi (Either) |
| `equatable` | 2.0.7 | Deger esitligi |
| `flutter_animate` | 4.5.2 | Animasyonlar |
| `google_fonts` | 6.2.1 | Poppins yazi tipi |
| `shimmer` | 3.0.0 | Yukleme animasyonu |
| `lottie` | 3.3.1 | Lottie animasyonlari |
| `provider` | 6.1.5 | Dil yonetimi state |
| `shared_preferences` | 2.5.4 | Yerel veri saklama |
| `uuid` | 4.5.1 | Benzersiz ID uretimi |

---

## Tema ve Tasarim

- **Karanlik tema** (Material 3)
- **Yazi tipi:** Google Fonts Poppins
- **Responsive tasarim:** Mobil, Tablet ve Web uyumlu

| Renk | Hex | Kullanim |
|------|-----|---------|
| Primary | `#6C63FF` | Ana renk (mor) |
| Secondary | `#03DAC6` | Ikincil (turkuaz) |
| Background | `#0D0D1A` | Arka plan |
| Surface | `#1A1A2E` | Kart yuzey |
| Success | `#4CAF50` | Dogru cevap |
| Error | `#CF6679` | Yanlis cevap |
| Warning | `#FF9800` | Uyari (timer) |

### Responsive Breakpoint'ler
| Cihaz | Genislik |
|-------|---------|
| Mobil | < 600px |
| Tablet | 600-1024px |
| Masaustu | > 1024px |

---

## Kurulum

### Gereksinimler
- Flutter SDK 3.x+
- Dart SDK 3.x+
- Firebase projesi (Auth + Firestore + Storage + Messaging + Functions)
- Node.js 20+ (Cloud Functions icin)
- Android Studio / VS Code

### Adimlar

```bash
# 1. Projeyi klonlayin
git clone <repo-url>
cd Puzzle

# 2. Bagimliliklari yukleyin
flutter pub get

# 3. Firebase yapilandirmasi
# firebase_options.dart dosyasi zaten mevcut
# Firestore rules'lari Firebase Console'dan ayarlayin

# 4. Cloud Functions deploy
cd functions
npm install
cd ..
firebase deploy --only functions --project <project-id>

# 5. Uygulamayi calistirin
flutter run

# 6. Web icin
flutter run -d chrome

# 7. APK olusturma
flutter build apk --release
```

### Firebase Guvenlik Kurallari

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['friends']);
    }
    match /words/{wordId} {
      allow read: if request.auth != null;
    }
    match /scores/{scoreId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /duels/{duelId} {
      allow read, write: if request.auth != null;
    }
    match /friend_requests/{requestId} {
      allow read, write: if request.auth != null;
    }
    match /duel_invites/{inviteId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Proje Metrikleri

| Metrik | Deger |
|--------|-------|
| Toplam Dart dosyasi | 104 |
| Ozellik modulu | 6 (auth, game, duel, friends, leaderboard, home) |
| BLoC sayisi | 5 |
| Kelime kategorisi | 10 (her dil icin) |
| Kategori basina kelime | 300 |
| Toplam kelime | 6.000 (3.000 EN + 3.000 TR) |
| Firestore koleksiyonu | 5 |
| Cloud Functions | 4 |
| Ses efekti | 5 |
| Cevirilmis metin | 189 |
| Desteklenen dil | 2 (EN, TR) |
| Desteklenen platform | Android, iOS, Web, Windows, macOS |
| Sayfa (Route) sayisi | 11 |

---

## Lisans

Izinsiz dagitim ve ticari kullanim yasaktir.
