# Magnus App — Claude Proje Hafızası

## ⚠️⚠️⚠️ COLOR TAG RENDER KURALI — DEĞİŞMEZ ⚠️⚠️⚠️

Unity metinleri `<color=yellow>metin</color>` veya `<color=#RRGGBB>metin</color>` şeklinde renk tag'ları içerebilir.

### KURAL — İKİ FARKLI DAVRANIS:

| Yer | Davranış |
|---|---|
| **Inbox preview** (`previewText` getter) | Tag'ları **kaldır**, aralarındaki metni düz yaz |
| **Her yerde başka** (detay ekranı, fal ekranı, numeroloji, biyoritim, olumlama, astroloji…) | `RichTextParser.build()` kullan → renklendirme yap |

### Uygulama:

- `previewText` içinde: `text.replaceAll(RegExp(r'<color=[^>]+>|<\/color>', caseSensitive: false), '')`
- Tüm metin render noktalarında: `Text(...)` veya `SelectableText(...)` yerine `RichTextParser.build(metin, style: ...)` kullan
- `RichTextParser` → `lib/core/utils/rich_text_parser.dart`

### Yeni bir ekran/fal türü eklenirken:
1. Metin render eden `Text(...)` widget'larını `RichTextParser.build(...)` ile değiştir.
2. Inbox'a metin gönderirken ayrıca bir şey yapma — `previewText` getter zaten tag'ları temizliyor.

> **Bu kural her fal türüne, her içerik ekranına uygulanır. İstisna yoktur.**

---

## UI Standartları

### "Geri Git" Butonu

Uygulamada nerede "Geri Git" butonu varsa aşağıdaki standart uygulanır:

- **İkon:** `Icons.chevron_left_rounded`, `color: Colors.white`, `size: 20`
- **İkon ile metin arası boşluk:** `SizedBox(width: 2)`
- **Metin rengi:** `Colors.white`
- **Arka plan:** `Colors.white.withValues(alpha: 0.10)`
- **Border:** `Colors.white.withValues(alpha: 0.25)`
- **Border radius:** `BorderRadius.circular(14)` (tam genişlik buton için 23 de olabilir)

```dart
// Standart Geri Git butonu örneği (motivasyon ekranındaki)
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
    SizedBox(width: 2),
    Text('Geri Git', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
  ],
)
```

---

## Google Play Store — Release İmzalama Bilgileri

> AAB oluştururken bu bilgileri kullan. Bir daha sorma, burada yazıyor.

### Keystore Dosyası
- **Konum:** `C:\src\magnus_app\android\magnus_release.jks`
- **Alias:** `magnus`
- **Keystore şifresi:** `magnus2024!`
- **Key şifresi:** `magnus2024!`
- **Yapı:** RSA 2048-bit, 10000 gün geçerli, CN=Magnus App, C=TR

### key.properties (android/key.properties)
```
storePassword=magnus2024!
keyPassword=magnus2024!
keyAlias=magnus
storeFile=../magnus_release.jks
```

### Sertifika Parmak İzleri (Google Play onaylı upload key)
- **MD5:** `3C:34:77:E4:9A:0F:38:53:A3:C7:86:11:91:9E:51:DD`
- **SHA1:** `DA:88:8B:FE:35:22:B8:F9:4F:34:32:79:0D:11:F3:46:91:F8:BC:7E`

### AAB Oluşturma Komutu
```bash
cd C:\src\magnus_app
flutter build appbundle --release
```
Çıktı: `build\app\outputs\bundle\release\app-release.aab`

### Uygulama Bilgileri
- **Package:** `com.futurastic.Magnus`
- **Play Console:** com.futurastic.Magnus

---

## Unity .asset Dosyalarından İçerik Dönüştürme İş Akışı

Kullanıcı bir Unity `.asset` klasörü gösterip **"bu türün metinlerini dönüştür"** dediğinde aşağıdaki adımları eksiksiz uygula. Her seferinde anlatmasına gerek yok.

### Kaynak Yapısı
Unity `.asset` dosyaları YAML formatındadır. Türkçe içerik `aciklama:` alanında, İngilizcesi `aciklamaEng:` alanında bulunur. Sadece Türkçeyi al.

> ⚠️ **KRİTİK: Tek dosyada birden fazla metin olabilir!**
> `aciklama:` alanı bir YAML **listesidir**. Bir `.asset` dosyasında birden fazla `- "..."` maddesi
> bulunabilir (bazı klasörlerde sıkça görülür: Motivasyon, OzluSoz, AstroTakvim, GunlukAstroloji…).
> Her `- "..."` maddesi **ayrı bir JSON girdisi** olmalı. Sadece ilk maddeyi almak metin kaybına neden olur.
> `element:` alanı da aynı şekilde liste olabilir — aynı kurala tabi.

### Dönüştürme Adımları

1. **Dosyaları listele** — `os.listdir()` kullan, `find` komutu Windows'ta çalışmaz.
2. **Windows yollarını kullan** — `/c/...` değil, `C:/...` formatında.
3. **Dosyaları `cat` ile oku** — `open(..., encoding='utf-8', errors='replace')` veya subprocess ile.
4. **`aciklama:` bloğunu parse et** — `aciklama:` ile `aciklamaEng:` arasındaki **tüm** YAML liste maddelerini al. Her `- "..."` ayrı bir girdidir.
5. **YAML escape'lerini çöz** (regex değil, karakter karakter döngü ile — Python 3.14'te `\u` regex'te hata verir):
   - `\uXXXX` → `chr(int(hex, 16))`
   - `\xXX` → `chr(int(hex, 16))`
   - `\n` → gerçek satır sonu
   - `\"` → `"`
6. **YAML satır devamlılığını birleştir** — gerçek newline + boşluklar = tek boşluk.
7. **Başlangıç/bitiş tırnaklarını kaldır.**
8. **`{{isim}}` placeholder'ını koru** — runtime'da kullanıcı adıyla değiştirilir.
9. **Temizle** — 3+ boş satırı 2'ye indir, baş/sondaki boşlukları at.
10. **`gerekliDegiskenler` bloğunu parse et ve kaydet** — bkz. "Koşullu Filtreleme" kuralı aşağıda.
11. **JSON'a kaydet** — `C:/src/magnus_app/assets/data/<tur_adi>.json` formatında, aşağıdaki yapıda.
12. **⚠️ ANLAM KONTROLÜ (KESİLMİŞ METİN) — ZORUNLU** — bkz. aşağıdaki bölüm.

### Koşullu Filtreleme (gerekliDegiskenler)

`.asset` dosyalarında `gerekliDegiskenler:` veya `gerekliDegisken:` bloğu olabilir. Örnek:

```yaml
gerekliDegiskenler:
- degiskenAdi: medeni_durum
  degiskenDegeri: evli
  kontrol: 0
- degiskenAdi: meslek
  degiskenDegeri: kamusektoru
  kontrol: 0
```

**Bu bloğu her dosyada mutlaka oku.** Varsa `kosullar` listesi olarak JSON'a ekle:

```json
{
  "id": 5,
  "metin": "...",
  "kosullar": [
    {"degisken": "medeni_durum", "deger": "evli"},
    {"degisken": "meslek", "deger": "kamusektoru"}
  ]
}
```

Koşul yoksa `"kosullar": []` yaz (boş liste).

**Flutter'da filtreleme kuralı:**
- Metin havuzu oluşturulurken her metnin `kosullar` listesi kontrol edilir.
- Tüm koşullar kullanıcı profiline uyuyorsa metin havuza girer, tek bir koşul bile uyuşmazsa havuz dışında kalır.
- Koşulsuz metinler (`kosullar: []`) her kullanıcıya gösterilebilir.
- Değişken adları UserProfile alanlarıyla eşleşir: `medeni_durum`, `meslek`, `cinsiyet`, `yas`, vb.

### Tekrar Gösterilmeme Kuralı

Bir metin kullanıcıya bir kere gösterildiyse, **tüm uygun metinler tükenene kadar tekrar gösterilmemeli.**

**Uygulama:**
- Gösterilen metin ID'leri `SharedPreferences`'a kaydedilir (anahtar: `<tur_adi>_gosterilen_idler`).
- Havuzdaki tüm ID'ler gösterildiyse liste sıfırlanır ve baştan başlanır.
- Her yeni metin gösteriminde ID kaydedilir.
- Sıfırlama sonrası yine shuffle ile karıştır.

**Flutter örnek mantığı:**
```dart
// Gösterilen ID'leri yükle
final gostrilen = prefs.getStringList('tur_gosterilen') ?? [];
// Uygun metinleri filtrele
final uygunlar = tumMetinler.where((m) => !gostrilen.contains('${m.id}')).toList();
// Hepsi bittiyse sıfırla
if (uygunlar.isEmpty) {
  await prefs.remove('tur_gosterilen');
  uygunlar = tumMetinler; // yeniden filtrele
}
// Karıştır ve ilkini al
uygunlar.shuffle();
final secilen = uygunlar.first;
// ID'yi kaydet
gostrilen.add('${secilen.id}');
await prefs.setStringList('tur_gosterilen', gostrilen);
```

### Flutter Entegrasyonu

- `pubspec.yaml`'da `assets/data/` zaten tanımlı → yeni JSON otomatik dahil olur.
- İlgili screen'de `rootBundle.loadString('assets/data/<tur_adi>.json')` ile yükle.
- Koşul filtrelemesi + tekrar gösterilmeme mantığı her tür için uygulanır.
- Kodun başına kaynak klasörü belirten yorum ekle.

### JSON Çıktı Yapısı (Tam Format)

```json
{
  "motivasyonlar": [
    {
      "id": 1,
      "metin": "Metin buraya...",
      "kosullar": []
    },
    {
      "id": 7,
      "metin": "Sadece evlilere gösterilecek metin...",
      "kosullar": [
        {"degisken": "medeni_durum", "deger": "evli"}
      ]
    }
  ]
}
```

### Referans Örnek: Motivasyon

- **Kaynak:** `C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\Motivasyon\Motivasyonlar\`
- **Çıktı:** `C:/src/magnus_app/assets/data/motivasyonlar.json`
- **Flutter:** `motivation_screen.dart` → `_loadData()` metodu
- **JSON yapısı:** `{"motivasyonlar": [{"id": 1, "metin": "...", "kosullar": []}, ...]}`
- **80 dosya** dönüştürüldü. (Not: Bu dönüşümde `kosullar` henüz eklenmedi, bir sonraki güncellemede eklenecek.)

### ⚠️ Anlam Kontrolü — Kesilmiş Metin Yasağı

Her dönüşümden sonra üretilen her metni anlam bütünlüğü açısından doğrula.

**Kural:** Bir metin nokta (`.`), ünlem (`!`), soru işareti (`?`), üç nokta (`…` veya `...`) veya tırnak kapanışı (`"`) dışında bir karakterle bitiyorsa **metin kesilmiş demektir** — bu JSON'a giremez.

**Kesilme nedenleri ve çözümleri:**

| Belirti | Olası Neden | Çözüm |
|---|---|---|
| Metin `\` ile bitiyor | Regex escape'li tırnağı (`\"`) string sonu sanıyor | Regex'i `(?:[^"\\]\|\\.)*` şeklinde yaz |
| Metin yarım kelimeyle bitiyor | YAML satır devamlılığı (`\n + boşluk`) birleştirilmemiş | Adım 6'yı uygula |
| Metin çok kısa (< 40 karakter) | Yanlış YAML bloğu parse edildi | `aciklama:` bloğunu kontrol et |
| Metin `{{` ile bitiyor | Placeholder ortasında kesilmiş | Kaynak dosyada placeholder'ı bütün oku |

**Parse sonrası zorunlu kontrol (Python):**

```python
BITIŞ_NOKTALARI = {'.', '!', '?', '…', '"', "'", ')'}
sorunlu = []
for id_, metin in tum_metinler:
    son_char = metin.rstrip()[-1] if metin.rstrip() else ''
    if son_char not in BITIŞ_NOKTALARI:
        sorunlu.append((id_, metin[-120:]))  # son 120 karakter

if sorunlu:
    print(f"UYARI: {len(sorunlu)} kesilmiş metin!")
    for id_, parca in sorunlu:
        print(f"  [{id_}] ...{parca!r}")
    # → Kaynağa dön, regex veya parse mantığını düzelt, tekrar çalıştır
```

Sorunlu metin varsa **JSON'a yazmadan önce** kaynağa dön ve sorunu çöz. "Zaten anlamlı görünüyor" gerekçesiyle geçme.

### Dikkat Edilecekler

- **Tek `.asset` dosyasında birden fazla metin olabilir** — `aciklama:` ve `element:` YAML liste alanlarıdır; her `- "..."` maddesi ayrı JSON girdisi olmalı. Bu durum şu klasörlerde tespit edildi: `Motivasyon`, `Ozlusoz`, `AstroTakvim`, `GunlukAstroloji`, `Biyoritim`, `CanliSohbet`, `JaponFali`, `KaderKitabi`.
- Python 3.14'te `re.sub(r'\uXXXX', ...)` sözdizimi **hata verir** → karakter döngüsü kullan.
- Windows'ta `subprocess.run(['find', ...])` Windows'un kendi `find`'ını çağırır → `os.listdir()` kullan.
- Terminal encoding bozuk görünse bile JSON UTF-8 doğruysa sorun yok; `'rb'` modunda byte kontrolü yap.

---

## Full-Screen Arka Plan Ekranları — Standart Şablon

Olumlama, AstroTakvim, Astroloji, Settings gibi tam ekran görselli ekranlar bu şablonu kullanır.

### main.dart (bir kez kurulur)
```dart
await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: Colors.transparent,  // şeffaf nav bar
  systemNavigationBarDividerColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarIconBrightness: Brightness.light,
));
```

### Scaffold yapısı (her full-screen ekranda)
```dart
return Scaffold(
  backgroundColor: Colors.black,   // nav bar arkası siyah (görsel ile uyumlu)
  extendBody: true,                 // body, sistem nav bar arkasına uzanır
  body: Stack(
    fit: StackFit.expand,           // tüm çocuklar tam ekranı kaplar
    children: [
      // 1) Arka plan görseli — tam ekran
      Image.asset(
        'assets/images/xxx_bg.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050010)),
      ),
      // 2) Koyu overlay (görseli bozmadan metin okunurluğu sağlar)
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x99000000), // üst %60
              Color(0x44000000), // orta %27
              Color(0x99000000), // alt %60
            ],
          ),
        ),
      ),
      // 3) İçerik — SafeArea ile sistem çubuklarının üzerinde konumlanır
      SafeArea(
        child: Column(children: [...]),
      ),
    ],
  ),
);
```

### Kurallar
- `extendBody: true` → görselin sistem nav bar (alt gesture çubuğu) arkasına uzanmasını sağlar.
- `SafeArea` → içerik (başlık, butonlar) sistem çubuklarıyla örtüşmez.
- `filterQuality: FilterQuality.high` → görsel upscaling'de kalite kaybı önlenir.
- Overlay opacity: üst/alt `0x99` (%60), orta `0x44` (%27). Daha az karartma görseli daha net gösterir.
- `backgroundColor: Colors.black` → `edgeToEdge` modda transparent nav bar arkasını doldurur.

---

## Nefes Alan Işık Halo Animasyonu (Glow Breathing)

Kullanıcı **"nefes alıp verme"**, **"hale"**, **"glow"** veya **"ışık çerçeve"** dediğinde bu kalıbı uygula.

### Nasıl Çalışır
- `AnimationController` (2800ms) + `repeat(reverse: true)` + `CurvedAnimation(Curves.easeInOut)`
- `AnimatedBuilder` içinde `Container` decoration her frame'de güncellenir
- Görsel `ClipRRect` ile rounded; glow dıştaki `Container` boxShadow + border'dan geliyor

### Hazır Kod Kalıbı

```dart
// State sınıfında — birden fazla controller varsa TickerProviderStateMixin kullan:
// with TickerProviderStateMixin
late AnimationController _glowCtrl;
late Animation<double> _glowAnim;

// initState:
_glowCtrl = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2800),
)..repeat(reverse: true);
_glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

// dispose:
_glowCtrl.dispose();

// Widget:
AnimatedBuilder(
  animation: _glowAnim,
  builder: (context, child) {
    final t = _glowAnim.value; // 0.0 (sönük) → 1.0 (parlak)
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF55FF).withValues(alpha: 0.25 + t * 0.55),
          width: 1.5,
        ),
        boxShadow: [
          // İç halka — yoğun, dar
          BoxShadow(
            color: const Color(0xFFFF55FF).withValues(alpha: 0.20 + t * 0.45),
            blurRadius: 6 + t * 14,
            spreadRadius: t * 3,
          ),
          // Dış halo — geniş, yumuşak
          BoxShadow(
            color: const Color(0xFF9B00D3).withValues(alpha: 0.10 + t * 0.30),
            blurRadius: 18 + t * 28,
            spreadRadius: t * 6,
          ),
        ],
      ),
      child: child,
    );
  },
  child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: /* görsel veya widget buraya */,
  ),
),
```

### Referans
- **İlk uygulama:** `faloya_screen.dart` → `_buildGlowImage()` metodu
- **Renk paleti:** `0xFFFF55FF` (pembe/mor iç) + `0xFF9B00D3` (koyu mor dış)
- Farklı renk istenirse sadece iki `Color(...)` değerini değiştir, geri kalan aynı kalır.

---

## Ana Menü 1. Sohbet Balonu

`home_screen.dart` → `_anaMenu1SohbetBalonu()` metodu.
Her app açılışında 6 selamlama arasından biri random gelir.
Selamlamalar: "Hoş geldin X!", "Merhaba, seni görmek güzel X!", "Ne iyi ettin de geldin X!", "Hoş geldin, safalar getirdin X!", "Seni burada görmek güzel X.", "X merhaba! Nasılsın? Dilerim iyisindir. 😊"

---

## Alt Nav Buton Boyutları (home_screen.dart `_buildBottomBar`)

**Kural:** Sayfa konumuna göre büyüyen buton:
- **1. sayfa** (showPrev=false, showNext=true): Sonraki = `2×navW+8` (büyük), diğerleri `navW`
- **2. sayfa** (showPrev=true, showNext=true): hepsi `navW`
- **3. sayfa** (showPrev=true, showNext=false): Önceki = `2×navW+8` (büyük), diğerleri `navW`

`navW = (constraints.maxWidth - 3×8) / 4`

Önceki ve Sonraki için `ClipRect + AnimatedContainer` pattern (width 0→navW→2×navW+8 animasyonu).
Bilgi butonu: `SizedBox(width: navW)` — sabit.
Inbox: `AnimatedContainer(width: navW)` — sabit genişlik.

---

## GunlukAstroloji JSON Yapısı

**Kaynak:** `C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\GunlukAstroloji\GunlukAstro\`
**Çıktı:** `assets/data/gunlukastroloji.json`
**Script:** `scripts/convert_gunlukastroloji.py`

JSON yapısı **bölüm anahtarlıdır** — her klasör bir bölüm anahtarı olur:
```json
{
  "giris": [...],
  "astroyorum": [...],
  "astrogununsozu": [...],
  "astrogununayeti": [...],
  "astrogununhadisi": [...],
  "astroeglencelibilgi": [...],
  "astrokesif": [...],
  "astrogununismi": [...],
  "astrogununyemegi": [...],
  "astroveda": [...]
}
```

`astroloji_screen.dart` → `_sections` listesi bu anahtarlarla eşleşir. Her bölüm için `SharedPreferences`'ta ayrı tekrar-gösterilmeme takibi (`astroloji_<key>_gosterilen`).

**Kritik:** `decode_escapes` sonrası `re.sub(r'\n', ' ', t)` — YAML satır kırıkları boşluğa çevrilmeli, aksi hâlde Flutter'da metinler yanlış satır sonlarıyla render edilir.

---

## Rüya Yorumu Ekranı (ruya_yorumu_screen.dart)

**Arka plan:** `assets/images/dream_bg.png` (Stack içinde full-screen Image + overlay)
- `build()` → Stack[Image, Container(gradient overlay), SafeArea(Column(...))]
- `_buildSecim()` ayrı metot — Column döner, Scaffold değil
- Alttaki buton: kelime seçilmemişse "< Geri Git" (`context.pop()`), seçilince "Yorumla" (`_tamam`)
- Arama kutusu `fillColor: 0x800D0A1E` (%50 transparan), kelime listesi item `color: 0x800D0A1E`

**Kritik:** `build()` kapanışı `],),),],),);` şeklinde Stack+SafeArea+Column'u kapatır.
`_buildSecim()` kendi `],);` ile biter — karıştırma!

---

## Numeroloji Ekranı (numeroloji_screen.dart)

**Arka plan:** `assets/images/numeroloji_bg.png` (Positioned.fill Image)

---

## Aşk Uyumu Çark Ekranı (askuyumu_screen.dart)

**Çark bölümü** (`build()` metodu içi, `_AskUyumuWheelState`):
- Snap offset: `_kSnapOffset = pi/12`, başlangıç: `_wheelAngle = pi + pi/12`
- Snap formülü: `((_wheelAngle - _kSnapOffset) / (pi/6)).round() * (pi/6) + _kSnapOffset`
- İndeks (CCW burç yönü): `((6 - ((_wheelAngle - _kSnapOffset) / (pi/6)).round()) % 12 + 12) % 12`
- Sarı segment glow: `_SegmentGlowPainter` → `IgnorePointer` ile sarılı (dokunuşu engellemez)
- Alt Geri Git butonu: `Column` içinde `Expanded` dışında, `padding: fromLTRB(20,0,20,20)`
