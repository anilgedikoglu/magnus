# Magnus App — Claude Proje Hafızası

## ⚠️⚠️⚠️ PARALEL İNGİLİZCE KURALI — İSTİSNASIZ ⚠️⚠️⚠️

Herhangi bir metin, ekran veya içerik düzeltildiğinde / güncellendiğinde / eklendiğinde, **İngilizcesi de her zaman paralel olarak düzeltilir / güncellenir / eklenir.** Bu kural hiçbir istisna kabul etmez. Türkçe güncelleme → İngilizce güncelleme zorunludur.

---

## 🚀 YENİ SESSION BAŞLARKEN — İLK İŞ

Yeni bir session açıldığında, kullanıcı herhangi bir şey demeden önce:

1. `git log --oneline -20` ile son 20 commit'i gör
2. `git status` ile bekleyen değişiklik var mı kontrol et
3. Bu CLAUDE.md'yi baştan sona oku

Bunu yapmadan hiçbir işe başlama.

## 📋 FAL TÜRLERİ — DAVRANIŞ KURALLARI (DEĞİŞTİRME)

Her fal türünün metin seçim davranışı aşağıdaki tabloda tanımlıdır.
**Yeni geliştirme yaparken bu tabloyu kontrol et. Kural değişmedikçe dokunma.**

| Fal Türü | Günlük Tutarlılık | No-Repeat | Günlük Limit |
|---|---|---|---|
| **Günlük Astroloji** | ✅ Evet — gün boyunca aynı 10 metin (bölüm başına 1) | ✅ Evet | ❌ Yok |
| **Biyoritim** | ✅ Evet — aynı gün aynı metin | ✅ Evet | ❌ Yok |
| **Doğum Haritası** | ✅ Evet — aynı gün aynı metin | ✅ Evet | ❌ Yok |
| **AstroTakvim** | ✅ Evet — seçilen gün + sekmeye göre deterministik (index mod) | ❌ Yok | ❌ Yok |
| **Motivasyon** | ❌ Yok — her açılışta bir sonraki metin | ✅ Evet | ❌ Yok |
| **Olumlama** | ❌ Yok — her açılışta bir sonraki metin | ✅ Evet | ❌ Yok |
| **Özlü Sözler** | ❌ Yok — her açılışta bir sonraki metin | ✅ Evet | ❌ Yok |
| **Acı Gerçekler** | ❌ Yok — her açılışta bir sonraki metin | ✅ Evet | ❌ Yok |
| **Kader Kitabı** | ❌ Yok — her açılışta bir sonraki metin | ✅ Evet | ❌ Yok |
| **Kahve Falı** | — (AI üretimi) | — | ✅ Günde 1 |
| **Tarot** | — (AI üretimi) | — | ✅ Günde 1 |
| **Durugörü** | — (AI üretimi) | — | ✅ Günde 1 |
| **Dert Ortağı** | — (AI üretimi) | — | ✅ Günde 1 |
| **I-Ching** | ❌ Yok | ✅ Evet | ✅ Günde 1 |
| **Japon Falı** | ❌ Yok | ✅ Evet | ✅ Günde 1 |
| **El Falı** | — (AI üretimi) | — | ✅ Günde 1 |
| **Yüz Falı** | — (AI üretimi) | — | ✅ Günde 1 |

---

## ⚠️⚠️⚠️ NO-REPEAT KURALI — TÜM FAL TÜRLERİ İÇİN ZORUNLU ⚠️⚠️⚠️

> Bu kural istisnasız her fal türüne uygulanır. "Shuffle + first" yöntemi YASAKTIR.

### Kural

Bir metin kullanıcıya **bir kez gösterildikten sonra**, o kullanıcıya **gösterilebilecek tüm diğer uygun metinler bitene kadar** bir daha gösterilemez.

**"Uygun metin" tanımı:** Kullanıcının `kosullar` filtresinden geçen metinler.
- Kullanıcı evliyse → sadece `medeni_durum=evli` veya koşulsuz metinler havuza girer.
- Kamu sektörüyse → sadece `meslek=kamusektoru` veya koşulsuz metinler havuza girer.
- Tüm koşulları karşılayan metinler tükenmeden, önceden gösterilmiş bir metin tekrar seçilemez.

### Yasak Yöntem ❌

```dart
// BU YANLIŞ — her açılışta aynı metin gelebilir:
list.shuffle();
return list.first;
```

### Doğru Yöntem ✅

```dart
final shownKey = '<tur>_gosterilen';
final shown = prefs.getStringList(shownKey) ?? [];

// Gösterilmemiş uygun metinleri filtrele
var available = pool.where((e) => !shown.contains('${e.id}')).toList();

// Hepsi bitti → üst üste yasağını koruyarak sıfırla
if (available.isEmpty) {
  final lastId = shown.isNotEmpty ? shown.last : null;
  final resetShown = lastId != null ? [lastId] : <String>[];
  await prefs.setStringList(shownKey, resetShown);
  available = pool.where((e) => e.id.toString() != lastId).toList();
  if (available.isEmpty) available = List.from(pool); // tek metin varsa zorunlu tekrar
}

available.shuffle();
final pick = available.first;

// Seçimi kaydet
final updatedShown = prefs.getStringList(shownKey) ?? [];
updatedShown.add('${pick.id}');
await prefs.setStringList(shownKey, updatedShown);
```

### Günlük Tutarlılık İstisnası

Günlük tutarlılık gereken türlerde (Astroloji, Biyoritim, Doğum Haritası) **aynı gün no-repeat seçimi yapılmaz** — o gün için kaydedilmiş metin doğrudan gösterilir. No-repeat seçimi sadece **yeni bir gün** açıldığında tetiklenir.

```dart
final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
final savedDate = prefs.getString('<tur>_tarih');
final savedId   = prefs.getInt('<tur>_bugun_id');

if (savedDate == todayStr && savedId != null) {
  // Aynı gün → cache'ten yükle, no-repeat çalıştırma
  pick = pool.firstWhere((e) => e.id == savedId, orElse: () => pool.first);
} else {
  // Yeni gün → yukarıdaki no-repeat mantığını çalıştır, sonra tarih+id kaydet
  await prefs.setString('<tur>_tarih', todayStr);
  await prefs.setInt('<tur>_bugun_id', pick.id);
}
```

---

### Günlük Tutarlılık Uygulama Şablonu (özet)

```dart
final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
final savedDate = prefs.getString('<tur>_tarih');
final savedId   = prefs.getInt('<tur>_bugun_id');

if (savedDate == todayStr && savedId != null) {
  pick = pool.firstWhere((e) => e.id == savedId, orElse: () => pool.first);
} else {
  // no-repeat mantığıyla seç...
  await prefs.setString('<tur>_tarih', todayStr);
  await prefs.setInt('<tur>_bugun_id', pick.id);
}
```

---

## ⚠️⚠️⚠️ JSON VERİ TEMİZLİĞİ — DÖNÜŞÜM VE RENDER KURALLARI ⚠️⚠️⚠️

Unity `.asset` dosyalarından JSON'a dönüştürme ve Flutter render sürecinde aşağıdaki temizlik kuralları **istisnasız** uygulanır.

### Dönüşüm Sırasında Temizle

| Sorun | Belirti | Çözüm |
|---|---|---|
| Emoji Unicode escape | `U0001F642`, `U0001F60B` gibi literal metin | `chr(int('1' + son4hex, 16))` ile gerçek karaktere çevir |
| ETX kontrol karakteri | Görünmez `\x03` gömülü metin | Strip et (`metin.replace('\x03', '')`) |
| Çift-escape Türkçe | `\\xE7`, `\\xF6` gibi (kadın→kad\xEFn) | Decode et (`bytes.fromhex(xx).decode('latin-1')`) |
| YAML satır kırıkları | Satır sonu + 4 boşluk = devam satırı | Birleştir: `\n + spaces → ' '` |
| Başlangıç/bitiş tırnak | `"metin"` → tırnakları soy | Strip et |

### Her Dönüşüm Sonrası Zorunlu Doğrulama

```python
# 1) Kesilmiş metin kontrolü
BITIS = {'.', '!', '?', '…', '"', "'", ')'}
for id_, metin in entries:
    if metin.rstrip()[-1] not in BITIS:
        print(f'UYARI [{id_}] kesilmiş: ...{metin[-80:]!r}')

# 2) Kalan ham escape kontrolü
import re
ham = re.compile(r'U0001[0-9A-Fa-f]{4}')
if ham.search(metin):
    print(f'UYARI [{id_}] ham emoji kodu kaldı')
```

### Flutter Render Sırasında Temizle

Metinler ekrana gelirken uygulanacak kurallar için bkz. → COLOR TAG RENDER KURALI bölümü.

`RichTextParser.build()` aynı zamanda şunları da temizler:
- `<sprite=N>` tag'ları (Unity sprite referansları — Flutter'da anlamsız)
- `<b>`, `</b>`, `<i>`, `</i>` bilinmeyen tag'lar

---

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

## Ana Menü 1. Sohbet Balonu — Karşılama Sistemi

`home_screen.dart` → `_loadSelamlama()` async metodu (didChangeDependencies içinden çağrılır).

**JSON:** `assets/data/karsilamalar.json`
- `ozel_gunler` (29 giriş): ay/gün eşleşince o gün boyunca aynı metin. `ay=0,gun=0` = kullanıcı doğum günü.
- `karsilamalar` (459 giriş): her app açılışında rastgele 1 metin (%90 ihtimalle).
- `biliyormuydun` (33 giriş): her app açılışında rastgele 1 metin (%10 ihtimalle).

**Öncelik:** özel gün > random (karsilamalar/biliyormuydun)
**No-repeat uygulanmaz** — tamamen random, her açılışta yeni.
**VariableReplacer.replace()** ile `{{isim}}` gibi placeholder'lar doldurulur.

**Marquee animasyonu:** `_TypewriterChatBubble(enableMarquee: true)` — ilk balona uygulanır.
- Typewriter tamamlanınca `TextPainter` ile overflow ölçülür.
- Overflow varsa `AnimationController` + `Transform.translate` ile sağdan sola kaydırma loop'u başlar.
- Hız: overflow px / 55 px/s (min 3 saniye).
- Döngü sonu: 700ms bekleme → başa dön.

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

## Doğum Haritası — JSON Yapısı (dogumharitasi_screen.dart)

**Kaynak:** `C:\Users\AG\Desktop\Magnus\Assets\Resources\OnlineSohbetVeriTabani\Astroloji\DogumHaritasi`
**JSON:** `assets/data/dogumharitasi.json`
**Script:** `C:\temp\convert_dogumharitasi_final.js`

JSON yapısı bölüm tabanlıdır (2026-06-10 tam yeniden yazıldı):
```json
{
  "ana":   {"metin": "...", "metin_en": "..."},
  "ilk":   {"metin": "...", "metin_en": "..."},
  "son":   {"metin": "...", "metin_en": "..."},
  "son1":  {"metin": "...", "metin_en": "..."},
  "bolum1": [{"id": 1, "metin": "...", "metin_en": "...", "kosullar": []}, ...],  // 31 metin
  "bolum2": [...],  // 30 metin
  "bolum3": [...],  // 33 metin
}
```

Her açılışta `ana` + bolum1'den 1 + bolum2'den 1 + bolum3'ten 1 + `son1` birleştirilerek gösterilir.
Günlük tutarlılık: `dh_last_date` + `dh_bugun_id1/2/3` ile sağlanır.
No-repeat: `dh_gosterilen_1/2/3` ayrı prefs anahtarları.

**Layout:** `Column` — üst (wheel chart, sabit) + `Expanded(SingleChildScrollView(metin kutusu))` + Geri Git (altta sabit, tüm partisyonlarda aynı yerde)

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
- **Highlight çark:** `assets/images/burclar_wheel_highlight.png` (kaynak: `C:\Magnus\Assets\Images\burclarWheelHiglight512.png`)
  - Normal çarkın üstüne, aynı `_wheelAngle` ile döner
  - `_TopSegmentClipper` (dosya sonunda) sabit `pi/2 - pi/12 … pi/2 + pi/12` aralığını (alt imleç konumu) açık bırakır
  - Seçili burcun sembolü ışık yanıyor efekti verir — index hesabı gerekmez

---

## Kahve Falı — JSON Anahtar Eşlemesi (fortune_service.dart)

`_initKahve()` metodu JSON'u yüklerken `decoded[_kahveJsonKeys[bolum]!]` kullanır.
`_kahveJsonKeys` map'i:
```dart
static const _kahveJsonKeys = {
  'kahve_akarsilama': 'karsilamalar',
  'kahve_giris':      'girisler',
  'kahve_baglama':    'baglamalar',
  'kahve_gelisme':    'gelismeler',
  'kahve_sonuc':      'sonuclar',
  'kahve_ugurlama':   'ugurlamalar',
};
```
**Kritik:** `decoded[bolum]` değil `decoded[_kahveJsonKeys[bolum]!]` — aksi hâlde null cast hatası `.catchError` tarafından yutulur ve inbox'a hiçbir şey düşmez.

---

## Kahve Falı — Gönderiliyor Ekranı (coffee_screen.dart)

`_sendFortune()` artık `showDialog` (tam ekran overlay) kullanmıyor.
`_sending` bool state ile fincanın **altında** inline gösterim:
- `setState(() => _sending = true)` → 4s bekle → `context.go('/home')`
- `_buildSendingIndicator()` metodu: kum saati + "Falın gönderiliyor..." fincan/foto altına render edilir
- `_SendingOverlay` sınıfı dosyada kalmaya devam ediyor ama artık çağrılmıyor (silinebilir)

---

## Admin Bypass — Onboarding (chat_screen.dart)

İsim alanına `godag` yazılınca onboarding atlanır, admin profili otomatik doldurulur:
- İsim: Anıl, Soyisim: Gedikoğlu, Doğum: 1983-10-14, Şehir: Ankara, Burç: Terazi
- Meslek: kamusektoru, Medeni: evli, Saat: 13:30
- `_adminBypass()` → `userProfileProvider.notifier.save(adminProfile)` → `context.go('/home')`

---

## UserProfile — lastName Alanı (user_profile.dart + user_profile.g.dart)

`@HiveField(15) String? lastName` eklendi.
`toVariableMap()` → `'soyisim': lastName ?? ''`
`user_profile.g.dart` elle güncellendi: `read` + `write` metodlarında field 15 mevcut.
**Not:** `.g.dart` kod üretimi çalıştırılmadı, manuel güncellendi — build_runner çalıştırılırsa field sayısı kontrol edilmeli.

---

## Chat Ekranı AppBar — Kelebek Logo (chat_screen.dart)

AppBar'da "MAGNUS" yazısı kaldırıldı, yerine:
```dart
title: ClipOval(child: Image.asset('assets/images/magnusappicon_splash.png', height: 40, width: 40, fit: BoxFit.cover))
centerTitle: true
```
Kaynak görsel: `C:\Magnus\Assets\Images\magnusappicon_splash.png` (renkli kelebek, siyah arka plan)

---

## Renkli Magnus Yazı Logosu

Kaynak: `C:\Magnus\Assets\Images\magnusYaziLogorenkli.png`
Flutter asset: `assets/images/magnusYaziLogoRenkli.PNG`
Kullanıcı "renkli magnus yazı görseli koy" dediğinde bu asset kullanılır.

---

## Hazırlanma Baloncukları — Rainbow Gradient (home_screen.dart)

`_ArcProgressPainter` → `gradientColors` parametresi eklendi.
`_FortuneCircleBadge`'de `isLocked` ise `_ArcProgressPainter._rainbow` geçilir:
- Renk sırası: mavi→cyan→yeşil→sarı→turuncu→kırmızı→mor→kırmızı→turuncu→sarı→yeşil→cyan→mavi (palindrom)
- `SweepGradient` başlangıç: `pi/2 - segAngle/2` (alt)
- `isReady` ise solid yeşil (`0xFF44FF88`)

---

## Durugörü Arka Planı (durugoru_screen.dart)

`assets/images/durugoru_bg.png` (kaynak: `C:\Magnus\Assets\Images\splashbackground.png`)
Önceki: `assets/images/falbg/durugoru.png`

---

## Olumlama — RichTextParser (olumlama_screen.dart)

`Text(metin)` yerine `RichTextParser.build(metin, style: ...)` kullanılıyor.
`RichTextParser` artık `<b>`, `</b>`, `<i>`, `</i>` tag'larını da temizliyor (`_stripUnknownTags`).

---

## AstroTakvim Transit Sekmesi Arka Planı

`assets/images/astrotakvim/transit_bg.jpg` (kaynak: `C:\Users\AG\Desktop\ASMdesktop\bg\Galaxy Papers\gp.jpg`)
`_TabConfig` transit için `bgImage: 'assets/images/astrotakvim/transit_bg.jpg'`, alignment center.

---

## ElegantHourglass — Özel Kum Saati Widget'ı

**Dosya:** `lib/core/widgets/elegant_hourglass.dart`

Tüm `⏳`/`⌛` emoji'ler ve `Icons.hourglass_*` ikonları bu widget'larla değiştirildi.

### Widget Sınıfları

| Sınıf | Kullanım Yeri | Parametreler |
|---|---|---|
| `ElegantHourglass` | Genel — kum akış animasyonu | `size`, `color`, `animate` |
| `PulsingHourglass` | coffee_screen, single_tarot_screen | `size`, `color` |
| `SpinningHourglass` | numeroloji_screen | `size`, `color` |
| `FlipHourglass` | Yedek (şu an kullanılmıyor) | `size`, `color`, `flipInterval` |

### Hangi Ekranlarda Kullanılıyor

- `ruya_yorumu_screen.dart` → `ElegantHourglass(size: 56, color: Colors.white)`
- `iching_screen.dart` → `ElegantHourglass(size: 56, color: Color(0xFFD4AF37))`
- `yuz_fali_foto_screen.dart` → `ElegantHourglass(size: 56, color: Colors.white)`
- `parmak_surtme_screen.dart` → `ElegantHourglass(size: 36, color: Color(0xFFFF55FF))`
- `faloya_screen.dart` → `ElegantHourglass(size: 52, color: Colors.white)`
- `maganda_screen.dart` → `ElegantHourglass(size: 52, color: Colors.white)`
- `acigercekler_screen.dart` → `ElegantHourglass(size: 72, color: Color(0xFFCC44FF))`
- `dertortagi_screen.dart` → `ElegantHourglass(size: 72, color: Color(0xFFBB88FF))`
- `durugoru_screen.dart` → `ElegantHourglass(size: 72, color: Colors.white)`
- `askuyumu_screen.dart` → `ElegantHourglass(size: 56, color: Color(0xFFFF4466))`
- `kadercarki_screen.dart` → `ElegantHourglass(size: 52, color: Color(0xFF4DBBCC))`
- `coffee_screen.dart` → `PulsingHourglass(size: 48, color: Color(0xFFB8E0FF))`
- `single_tarot_screen.dart` → `PulsingHourglass(size: 34, color: Color(0xFFB8E0FF))`
- `numeroloji_screen.dart` → `SpinningHourglass(size: 64, color: Color(0xFFBBAAFF))`
- `settings_screen.dart` → `ElegantHourglass(size: 20, color: Color(0xFF00CCFF))` (reset butonu)

**Not:** `yana_screen.dart`'taki `⏳` kasıtlı bırakıldı — matrix rain efektinin karakter setinin parçası.

---

## I-Ching — Inbox Akışı (iching_screen.dart)

**Ekran akışı:** I-Ching menü butonu → `iching_screen.dart` → 5s bekleme + `ElegantHourglass` → inbox'a item eklenir → `ichingSentProvider = true` → `context.go('/home')`

**Inbox item:**
- `fortuneTypeKey: 'iching'`
- `unlockAt: now + 2 dakika`
- No-repeat key: `iching_gosterilen`
- JSON: `assets/data/iching.json`

**Provider:** `ichingSentProvider` (StateProvider<bool>) → home_screen `_checkIchingSent()` metodunu tetikler.

**Inbox detay:** `inbox_detail_screen.dart` → `_buildIChingContent()` → koyu kutu, altın border, ☯ dekorasyon.

---

## Inbox İkon Eşlemesi

Tüm inbox ikonları `assets/images/inbox_icons/` altında:

| FortuneType | Hazır (renkli) | Kilitli (siyahbeyaz) |
|---|---|---|
| coffee | kahve.png | kahve2.png |
| tarot | tarot.png | tarot2.png |
| astrology | astroloji.png | astroloji2.png |
| motivation | motivasyon.png | motivasyon2.png |
| dream | ruya.png | ruya2.png |
| general | cark.png | cark2.png |
| birthChart | dogum.png | dogum2.png |
| numeroloji | numeroloji.png | numeroloji2.png |
| durugoru | durugoru.png | durugoru2.png |
| elfali | elfali.png | elfali2.png |
| iching | iching.png (= niyet.png) | iching2.png (= ichingikon2.png) |

Kaynak: `C:\src\magnus_app\assets\images\Yeniikonlar\` (renkli) ve `Yeniikonlar\siyahbeyaz\` (siyahbeyaz).

---

## Kader Kitabı Mistik Animasyon (kaderkitabi_screen.dart)

- **Arka plan zoom:** `Transform.scale(scale: 1.2)` ile ortalı zoom
- **Mistik animasyon:** `_mistikCtrl` 10s loop, `TweenSequence` ile `_darkOverlay`:
  - 0-3s: kapkara (opacity 1.0)
  - 3-6s: logaritmik açılış (`_SlowRevealCurve`) → opacity 0.0
  - 6-7s: tam görünür
  - 7-10s: logaritmik kapanış (`_FastCoverCurve`) → opacity 1.0
- **`|| ` temizleme:** `.replaceAll(RegExp(r'\s*\|\|\s*'), ' ').trim()`
- **Geri Git butonu** altta

---

## Rüya Yorumu Inbox Detayı (inbox_detail_screen.dart)

`FortuneType.dream` → `_buildDreamContent(context)`:
- Üstte `assets/images/ruyaozel.png` logosu (ortalı)
- Metni mor çerçeveli kutu içinde `RichTextParser.build()`
- Alt footer: `magnusYaziLogoRenkli.PNG` (height: 110)
- En altta `_buildBackButton(context)` ("< Geri Git")

---

## Hazırlanma Çemberi Gradyan (home_screen.dart)

`_ArcProgressPainter._rainbow` — 20 renk durağı, neon paleti:
`Koyu Mavi(#1A47FF) → Camgöbeği(#00E5FF) → Mor(#8A2EFF) → Pembe(#FF2EC7) → Kırmızı(#FF3B30) → Sarımsı Beyaz(#FFF2A6) → Camgöbeği(#00E5FF)` ve devamı.
`isReady` ise solid yeşil `0xFF44FF88`.

---

## Japon Falı (japonfali_screen.dart)

**Kaynak:** `C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu2\JaponFali\Metinler` — 27 .asset dosyası
**JSON:** `assets/data/japonfali.json` → `{"japonfali": [{"id": 1, "metin": "...", "kosullar": []}, ...]}`
**Arka plan:** `assets/images/falbg/omikujibg.png`
**Ekran akışı:** 5s kum saati + "Japon Falı çalışılıyor..." → inbox (unlockAt +2 dak) → `japonFaliSentProvider = true` → `context.go('/home')`
**Home balon:** "Japon Falın değerlendiriliyor..." (kırmızı #CC2244 tema)
**Günlük limit pref anahtarı:** `japonfali_bugun_tarih`
**No-repeat pref anahtarı:** `japonfali_gosterilen`
**Provider:** `japonFaliSentProvider` (StateProvider<bool>) — `providers.dart`
**Route:** `/japonfali` — `app.dart`
**Inbox ikon:** `assets/images/inbox_icons/japonfali.png` / `japonfali2.png`
**Logo:** `assets/images/japonfalilogo.png`
**Renk paleti:** `Color(0xFFFF4466)` (kırmızı/pembe)
**Günlük limit:** `_onDailyFalTap('japonfali', '/japonfali')` — home_screen'de `_remainingCredits['japonfali']`
**Inbox detay:** `_buildJaponFaliContent(context)` — kırmızı border kutu, `⛩` dekorasyon

---

## I-Ching — Günlük Limit Sistemi (home_screen.dart)

I-Ching de Japon Falı gibi günde 1 haktır. `_onDailyFalTap('iching', '/iching')` ile tetiklenir.
Günlük limit pref anahtarı: `iching_bugun_tarih` (eskiden yoktu, bu session eklendi).
`_checkIchingSent()` artık `iching_bugun_tarih` de set ediyor.
Badge: `_remainingCredits['iching'] ?? 1` — 0 ise tıklamada uyarı balonu gösterir.

---

## Kehanet Menüsü — Kahinlere Sor İkonu (kehanet_menu_screen.dart)

`Kahinlere Sor` menü öğesi ikonu: `assets/images/menu/digerfalcilar.png`
Kaynak: `C:\src\magnus_app\assets\images\Yeniikonlar\digerfalcilar.png`

---

## Inbox İkon Eşlemesi (güncellenmiş)

| FortuneType | Hazır (renkli) | Kilitli (siyahbeyaz) |
|---|---|---|
| japonfali | japonfali.png | japonfali2.png |
| iching | iching.png (= niyet.png) | iching2.png (= ichingikon2.png) |

---

## Ana Menü Karşılama Balonu — Yeni Sistem (home_screen.dart)

`_loadSelamlama()` tam yeniden yazıldı. Öncelik sırası:
1. **İlk kez açılış** → `ilk_giris_yapildi` prefs anahtarı `false` ise → `karsilamalar.json` → `ilk_giris` sabit metni: `"Ve işte karşındayım! Hoş geldin {{isim}}."`
2. **Özel gün** → `ozel_gunler` listesinden ay/gün eşleşmesi (sadece günün ilk açılışında)
3. **Gün içi ziyaret sayısına göre havuz** → `karsilama_tarih` + `karsilama_sayi` prefs ile o gün kaçıncı açılış olduğu hesaplanır; `ziyaret` alanı (1–6) JSON'da her metinde var

**JSON yapısı** (`assets/data/karsilamalar.json`):
- `ilk_giris`: string — ilk açılış metni
- `ozel_gunler`: list — `{ay, gun, metin}` nesneleri (ay=0,gun=0 = doğum günü)
- `karsilamalar`: list — `{id, metin, ziyaret}` nesneleri
  - ziyaret=1: ID 1–152 (genel/ilk geliş)
  - ziyaret=2: ID 153–216 ("bugün ikinci kez" üslubu)
  - ziyaret=3: ID 217–254 ("üçüncü kez" üslubu)
  - ziyaret=4: ID 255–286 ("dördüncü kez")
  - ziyaret=5: ID 287–308 ("beşinci kez")
  - ziyaret=6: ID 309–459 (genel tekrar + 6/7/8/9. kez)
- `biliyormuydun`: list — `{id, metin}` nesneleri (%10 ihtimalle, sadece ilk ziyarette)

**No-repeat:** Her havuz için ayrı prefs anahtarı `karsilama_gosterilen_<ziyaretKey>` — `_noRepeatSec()` helper metodu.

**Pref anahtarları:**
- `ilk_giris_yapildi` (bool)
- `karsilama_tarih` (string YYYY-MM-DD)
- `karsilama_sayi` (int — günlük açılış sayısı)
- `karsilama_gosterilen_1..6` (List<String> — ID'ler)
- `karsilama_gosterilen_biliyormuydun` (List<String>)

---

## Marquee Animasyonu — Seamless Loop (_TypewriterChatBubble)

`_maybeStartMarquee()` artık seamless loop kullanıyor:
- `loopContent = text + gap(10 boşluk) + text`
- `_marqueeCtrl!.repeat()` ile 0→1→0→1 sürekli loop
- `cycleW = textW + gapW` kadar offset — tam bir döngü sonunda metin başa döner, "tak" efekti yok
- Tetikleme koşulu: `textW >= _bubbleInnerWidth - 8` (8px TextPainter/render farkı toleransı)
- Typewriter offset: `max(0.0, typedW - _bubbleInnerWidth + 4)` (+4px buffer)
- `didUpdateWidget`: `old.text.isEmpty` ise typewriter yeniden başlatılır (JSON yüklenmeden önce boş string gelince typewriter erken tamamlanmasın diye)

---

## Asset Optimizasyonu — AAB 248 MB → 109 MB (v10.6.0+202)

**Tarih:** 2026-05-04  
**Yedek klasör:** `asset_optimization_backup/` (proje kökünde, git'te, 226 MB)

**Yapılanlar:**
- 430 kullanılmayan dosya `asset_optimization_backup/`'a taşındı (Yeniikonlar Unity mirror klasörü dahil)
- 76 görsel optimize edildi: arka planlar max 1920px, UI görseller max 1440px, JPG/JPEG kalite 92
- EXIF metadata temizlendi
- Launcher icon, splash, adaptive icon dokunulmadı

**Kritik dosyalar (dokunulmaması gerekenler):**
- `android/app/src/main/res/` — launcher ikonlar
- `assets/images/magnusappicon_splash.png`
- `assets/images/magnusYaziLogoRenkli.PNG`
- `assets/images/inbox_icons/` — tüm dosyalar (dinamik yükleme)

**Sonuç:**
| | Önce | Sonra |
|---|---|---|
| Toplam asset | 341 MB | 165 MB |
| Sadece görseller | 227 MB | 51 MB |
| AAB boyutu | 248 MB | 109 MB |

---

## Yana Kehanet Ekranı (yana_screen.dart)

**Kaynak:**
- `C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Kehanet\Yana\Kehanetler\BanaDair\` — 68 entry
- `C:\Magnus\Assets\Resources\Editor\OnlineDOSYALAR\AnaMenu1\Kehanet\Yana\Kehanetler\YasamaDair\` — 110 entry
- **Dönüşüm scripti:** `C:\temp\convert_yana.py`

**JSON:** `assets/data/yana.json`
```json
{
  "bana_dair": [{"id": 1, "tur": "bana", "metin": "...", "kosullar": []}, ...],
  "yasama_dair": [{"id": 1, "tur": "yasama", "metin": "...", "kosullar": []}, ...]
}
```

**Koşul sistemi:**
- `mod: kehanetbana` / `mod: kehanetyas̈ama` — kategori tanımlayıcı, **kosullar'a eklenmez** (JSON'da atlanır)
- `cinsiyet` → profile.gender eşleşmesi ('kadın'→'kadin', 'erkek'→'erkek')
- `medeni_durum` → profile.maritalStatus eşleşmesi (normalize edilmiş)
- `yasmax: N` → profile.age <= N
- `yasmin: N` → profile.age >= N
- `meslek` → profile.job eşleşmesi

**OR/AND mantığı:** Aynı `degisken` için birden fazla `deger` varsa **OR** (biri eşleşse yeter). Farklı `degisken` grupları arasında **AND** (hepsi geçmeli).

**Akış:** secim → gorselKayiyor (görsel tepeye kayar) → odaklanma (5.5s + ElegantHourglass) → yagmur (karakterler düşer) → icerik (üst yarı görsel / alt yarı metin)

**Pref anahtarları:** `yana_bana_gosterilen`, `yana_yasama_gosterilen`

**Renk paleti:** `Color(0xFF9B00D3)` / `Color(0xFFFF55FF)` (mor/pembe)

---

## JSON Veri Temizliği — Geçmişte Yapılan Düzeltmeler

**2026-05-05 session'unda keşfedilen ve düzeltilen sorunlar:**

| Dosya | Sorun | Adet |
|---|---|---|
| `kahve_akarsilama/baglama/gelisme/giris/sonuc/ugurlama.json` | `U0001FXXX` ham emoji kodu | 643 |
| `tarot_texts.json` | `\x03` ETX kontrol karakteri | 3 metinde |
| `kadercarki_renk.json` | `\x03` ETX kontrol karakteri | 2 karakter |
| `biyoritim.json` | Çift-escape Türkçe (`\xE7` vb.) | 76 değer |

**Bu tür hatalar yeni dönüşüm yapılırken de kontrol edilmeli** — bkz. → JSON VERİ TEMİZLİĞİ bölümü.

---

## ⚠️⚠️⚠️ Android — namespace vs applicationId KURALI (KRİTİK) ⚠️⚠️⚠️

Bu iki alan **farklı şeylerdir** ve farklı olmak **zorundadır**. Karıştırma, uygulama Play Store'da çöker.

| Alan | Değer | Değiştirme |
|---|---|---|
| `namespace` | `com.magnus.magnus_app` | **ASLA değiştirme** |
| `applicationId` | `com.futurastic.Magnus` | **ASLA değiştirme** |

### Neden Farklılar?

- **`namespace`** → `MainActivity.kt`'nin `package` satırıyla eşleşmeli (`com.magnus.magnus_app`). Bu, `R.java` ve `BuildConfig`'in üretildiği pakettir. Değiştirirsen `ClassNotFoundException: com.futurastic.magnus.MainActivity` hatası alırsın.
- **`applicationId`** → Play Store'daki paket adı. Google Play'de bu ID altında yayınlanıyor (`com.futurastic.Magnus`).

### Geçmişte Yapılan Hata (2026-05-10)

`namespace = "com.futurastic.magnus"` yazıldı → Play Store'da `ClassNotFoundException` crash → anında revert edildi.
**Bir daha ASLA `namespace` değiştirme.**

---

## Google Play — Upgrade Compatibility (Kamera Sorunu)

**Sorun:** Play Console'da "Bu sürüm, mevcut kullanıcıların yeni eklenen uygulama paketlerine geçmelerine izin vermediği için kullanıma sunulamaz" hatası.

**Kök neden:** `CAMERA` iznini manifest'e eklemek, Android'in örtük `uses-feature` kuralını tetikler: `CAMERA` izni → `android.hardware.camera required=true` → kamerasız cihazlar (bazı tabletler, Chromebook'lar) bu APK'yı alamaz → upgrade engellenir.

**Çözüm:** `AndroidManifest.xml`'e explicit `required="false"` override eklendi:
```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```
Bu satırlar **silinmemeli** — kamerasız cihazlara güncelleme gidebilmesi için zorunlu.

---

## El Falı / Yüz Falı — Inbox Akışı (2026-05-10)

Her iki fal da analiz sonucunu **direkt ekranda göstermez**; inbox'a düşürür ve ana menüye döner.

**El Falı (`el_fali_screen.dart`):**
- Analiz tamamlanınca → `InboxItem` oluştur (unlockAt: +6 dakika) → inbox'a ekle
- `ref.read(elFaliSentProvider.notifier).state = true` → `context.go('/home')`
- Home'da `_checkElFaliSent()` tetiklenir → "El falın analiz ediliyor..." balonu gösterilir

**Yüz Falı (`yuz_fali_foto_screen.dart`):**
- Analiz tamamlanınca → `InboxItem` oluştur (`fortuneTypeKey: 'yuzfali'`, unlockAt: +6 dakika) → inbox'a ekle
- `ref.read(yuzFaliSentProvider.notifier).state = true` → `context.go('/home')`
- Home'da `_checkYuzFaliSent()` tetiklenir → "Yüz falın analiz ediliyor..." balonu gösterilir

**FortuneType.yuzfali:**
- `inbox_item.dart`'a `yuzfali` enum değeri eklendi
- `home_screen.dart` `_iconAsset()`: elfali ikonlarını paylaşır
- `inbox_item_card.dart` `_iconAsset()` + `_FallbackIcon`: yuzfali case eklendi
- `inbox_detail_screen.dart`: `falbg/yuzfalibg.png` arka planı

**Provider'lar (`providers.dart`):**
```dart
final elFaliSentProvider = StateProvider<bool>((ref) => false);
final yuzFaliSentProvider = StateProvider<bool>((ref) => false);
```

---

## Rewarded Reklam — Sadece Okunmamış İtemler (inbox_screen.dart)

**Kural (2026-05-10'dan itibaren):** Rewarded reklam sadece **yeni ve okunmamış** inbox itemleri açılırken gösterilir. Zaten okunmuş iteme tıklanırsa reklam atlanır, direkt detay ekranı açılır.

```dart
void _openDetail(BuildContext context, WidgetRef ref, InboxItem item) {
  if (!item.isRead) {
    AdService.instance.showRewarded(
      onRewarded: () => _navigateToDetail(context, ref, item),
      onFailed:   () => _navigateToDetail(context, ref, item),
    );
  } else {
    _navigateToDetail(context, ref, item);
  }
}
```

---

## Sürüm Geçmişi (Android Play Store + iOS App Store)

| versionCode | versionName | Platform | Tarih | Notlar |
|---|---|---|---|---|
| 200 | 10.4.0 | Android | — | Son kabul edilen sürüm (Play Console'da) |
| 201–211 | 10.5.x | Android | 2026-05-03–04 | Asset optimizasyon, çeşitli düzeltmeler |
| 212 | 10.6.0 | Android | 2026-05-04 | Japon Falı eklendi |
| 213 | 10.6.0 | Android | — | Play Console'da reddedildi (upgrade compat.) |
| 214 | 10.6.0 | Android | — | Atlandı |
| 215 | 10.6.0 | Android | 2026-05-10 | Kamera fix, namespace revert |
| 216 | 10.6.0 | Android | 2026-05-10 | CLAUDE.md notları, son commit |
| 220 | 10.6.0 | iOS | 2026-06-08 | İlk iOS build — NSMicrophoneUsageDescription eksikti |
| 221 | 10.6.0 | iOS | 2026-06-08 | Microphone fix — encryption compliance sorunu |
| 222 | 10.6.0 | iOS | 2026-06-08 | TestFlight'a ulaştı — GADApplicationIdentifier eksikti, crash |
| 223 | 10.6.0 | iOS | 2026-06-08 | GADApplicationIdentifier eklendi, TestFlight'ta çalışıyor |
| 224–227 | 10.6.0 | iOS+Android | 2026-06-09 | Rewarded ads (6 ekran), Yana screen fix, Doğum Haritası fix, Niyet Geri Git |
| 228 | 10.6.0 | iOS | 2026-06-09 | ATT + PrivacyInfo.xcprivacy + eğlence beyanı — App Store'a yüklendi (229 için atlandı) |
| 229 | 10.6.0 | iOS | 2026-06-09 | Version bump (228 zaten yüklüydü) |
| 230 | 10.6.0 | iOS | 2026-06-09 | NSUserTrackingUsageDescription + ATT kaldırıldı → App Review'a gönderildi ✅ |
| 233 | 10.6.0 | iOS+Android | 2026-06-10 | Doğum Haritası (4 bölüm), Admin panel, Arc gradient 12'den başlıyor, Placeholder %15 opacity, Fal konu ikonları |

**⚠️ Versiyon artışı kuralı: Her build'de +3 artır (çakışma önlemek için)**
**Bir sonraki iOS build: versionCode 236**
**Bir sonraki Android build: versionCode 236**

---

## iOS / Google Play — Yasal URL'ler

| Sayfa | URL |
|---|---|
| Privacy Policy | `https://futurastictech.github.io/magnus/privacy-policy.html` |
| Delete Account | `https://futurastictech.github.io/magnus/delete-account.html` |
| Support URL | `https://futurastictech.github.io/magnus/support.html` |
| Marketing URL | `https://futurastictech.github.io/magnus/` |

Kaynak repo: `https://github.com/futurastictech/futurastictech.github.io` → `magnus/` klasörü
Tüm sayfalar TR/EN dil seçimi içeriyor (tarayıcı diline göre otomatik).
**NOT:** `anilgedikoglu.github.io/magnus/` adresindeki eski sayfalar artık kullanılmıyor.

---

## iOS App Store — Teknik Yapılandırma

### Bundle ID
- **iOS Bundle ID:** `com.futurastic.Magnus` (Android applicationId ile aynı)
- **Android namespace:** `com.magnus.magnus_app` (farklı — DOKUNMA)

### Signing (Manuel)
- **Team ID:** `SN5Y726ZKF`
- **Distribution cert:** Apple Distribution: FUTURASTIC... (Jun 2026–Jun 2027)
- **Provisioning Profile:** Magnus App Store Profile (UUID: 068091fb-8ada-45bb-b14d-ea3d7f01ebfc)
- **P12:** `C:\src\magnus_app\ios_certs\ios_distribution.p12` (şifre: `Magnus2026iOS`)
- **P12 formatı:** legacy PBE-SHA1-3DES (macOS Keychain uyumlu — OpenSSL 3 default PBES2 değil)

### Codemagic
- **Workflow:** `ios-release` (codemagic.yaml)
- **Flutter:** 3.29.2 (pinli)
- **Instance:** mac_mini_m2
- **Env groups:** `ios_signing`, `app_secrets`, `app_store_connect`
- **Env variables (app level):**
  - `ios_signing`: IOS_CERTIFICATE, IOS_CERTIFICATE_PASSWORD, IOS_PROVISIONING_PROFILE
  - `app_secrets`: ANTHROPIC_API_KEY
  - `app_store_connect`: APP_STORE_CONNECT_KEY_IDENTIFIER (G796KF2KD3), APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_PRIVATE_KEY

### AdMob iOS App ID
- `GADApplicationIdentifier` = `ca-app-pub-6470338276121414~5546686598`
- Info.plist'te tanımlı — eksik olursa uygulama açılışta crash verir

### Info.plist Zorunlu Anahtarlar
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-6470338276121414~5546686598</string>
<key>NSMicrophoneUsageDescription</key>
<string>Uygulama ses özellikleri için mikrofon erişimi gerektirebilir.</string>
<key>NSCameraUsageDescription</key>
<string>Kahve falı için fincanının fotoğrafını çekmek amacıyla kameraya erişim gerekiyor.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Kahve falı için galerinizden fotoğraf seçmek amacıyla erişim gerekiyor.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Fal fotoğraflarınızı kaydetmek için galerinize erişim gerekiyor.</string>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

> ⚠️ `NSUserTrackingUsageDescription` **EKLEME** — App Store App Privacy uyumsuzluğu yaratır.
> ATT (App Tracking Transparency) paketi de kullanılmıyor. AdMob non-personalized reklamlarla çalışır.

### iOS Signing Dosyaları (LOCAL — git'e commit edilmez)
`C:\src\magnus_app\ios_certs\`
- `ios_distribution.key` — private key
- `ios_distribution.csr` — CSR
- `distribution.cer` — Apple'dan indirilen sertifika
- `ios_distribution.p12` — Codemagic'e yüklenen P12
- `Magnus_App_Store_Profile.mobileprovision` — provisioning profile
- `IOS_CERTIFICATE.b64.txt` — P12 base64
- `IOS_PROVISIONING_PROFILE.b64.txt` — profile base64
- `APP_STORE_CONNECT_PRIVATE_KEY.txt` — .p8 içeriği
- `AuthKey_G796KF2KD3.p8` kopyası masaüstünde

### App Store Connect
- **App Apple ID:** 1612979368
- **App Store Connect API Key ID:** G796KF2KD3
- **Issuer ID:** 8c4687a8-9df9-4d95-8516-3fa3b7576e44

**Bir sonraki build: versionCode 236**

### PrivacyInfo.xcprivacy
`ios/Runner/PrivacyInfo.xcprivacy` mevcut — Apple'ın zorunlu kıldığı privacy manifest.
- `NSPrivacyTracking: false`
- API'lar: UserDefaults (CA92.1), FileTimestamp (C617.1), SystemBootTime (35F9.1), DiskSpace (E174.1)
- `project.pbxproj`'ta Resources build fazına ekli (UUID: `B0A1C0DE0000000000000001`)

---

## 2026-06-09 Session — Rewarded Ads + iOS App Store Yayın

### Rewarded Ad Entegrasyonu (6 ekran)

`AdService.instance.showRewarded(onRewarded: fn, onFailed: fn)` — her iki callback da içeriğe devam eder.

| Ekran | Tetikleyici |
|---|---|
| `faloya_screen.dart` | 3s beklemeden sonra, metin gelmeden önce |
| `maganda_screen.dart` | 3s beklemeden sonra, cevap gelmeden önce |
| `tamua_screen.dart` | "Geçirdim Hazırım" butonuna basınca |
| `yana_screen.dart` | Bana Dair / Yaşama Dair seçimine basınca |
| `kahinler_menu_screen.dart` | Kahin (Derun/Uraz/Likia/Khallesi/Yousuf) seçimine basınca |
| `niyet_screen.dart` | İlk kazıma hareketi başladığında (sadece bir kez) |
| `kadercarki_screen.dart` | Çark dönüp durduktan sonra |

### Yana Screen Düzeltmeleri (yana_screen.dart)

- `icerik` state'ine geçişte görsel kayması düzeltildi → tüm state'ler tek Stack/LayoutBuilder altında
- Görsel `Alignment(0, -0.82)` konumunda tüm state'lerde sabit
- Metin kutusu görsel ve Geri Git butonu arasında dikey ortalandı
- **Yukarıdan aşağı akan yazı → aşağıdan yukarı yerleşen yazı** animasyonuna çevrildi
  - Her kelime `easeOutCubic` + staggered delay (maxDelay=0.65)
  - `Transform.translate(offset: Offset(0, (1.0 - eased) * 38))` ile yukarı yükselir

### Niyet Ekranı (niyet_screen.dart)

- Pembe "Kapat" butonu → standart "< Geri Git" butonuyla değiştirildi
- İlk parmak hareketi rewarded ad tetikler; dönüşte kazıma devam eder

### Doğum Haritası Fix (dogumharitasi_screen.dart)

- JSON yapısı: tek `dogumharitasi` flat listesi (198 giriş) — bölüm bazlı yapı değil
- `_loading` spinner'ı hiç kapanmıyordu → `_loadData()` yeniden yazıldı
- Pref anahtarları: `dh_gosterilen`, `dh_last_date`, `dh_bugun_id`

### Ana Menü 3. Sayfa Boş Kutucuklar (home_screen.dart)

- `credits < 0` olan menü kartlarının ortasına `'Yakında...'` metni eklendi
- fontSize: 10, color: white54

### Variable Replacer Fix (variable_replacer.dart)

- `{{ay_N}}` ve `{{gun_N}}` regex: `[+-]` → `[+-]?` (opsiyonel işaret)
- 402 metin, 21 JSON dosyasını etkiliyor

### iOS App Store — ATT Kaldırma (2026-06-09)

App Store "App Privacy" uyumsuzluğu: `NSUserTrackingUsageDescription` var ama privacy labels'ta tracking işaretli değildi.
**Çözüm:** ATT tamamen kaldırıldı.
- `NSUserTrackingUsageDescription` Info.plist'ten silindi
- `app_tracking_transparency` paketi pubspec.yaml'dan kaldırıldı  
- `main.dart`'tan ATT kod bloğu temizlendi
- AdMob non-personalized reklamlarla çalışmaya devam eder
- **BİR DAHA EKLEME** — her seferinde App Privacy uyumsuzluğu çıkar

### iOS App Store — İlk Yayın Süreci (2026-06-09)

- Build 230 → App Review'a gönderildi ✅
- App Store Connect URL: `https://appstoreconnect.apple.com/apps/1612979368`
- Mevcut yayında: **10.3**
- Review'daki: **10.6.0 (230)**

---

## 2026-06-10 Session — Doğum Haritası, Admin Panel, UI Düzeltmeleri

### Doğum Haritası Tam Yeniden Yazım (dogumharitasi_screen.dart)

- Eski: tek flat liste (198 giriş), 1 rastgele metin
- Yeni: 4 bölüm (ana + bolum1 + bolum2 + bolum3 + son1) birleştirilerek gösterilir
- JSON: bölüm tabanlı yapı — bkz. "Doğum Haritası — JSON Yapısı" bölümü
- Layout: üst görsel sabit + `Expanded(SingleChildScrollView)` + Geri Git altta sabit

### Admin Panel (settings_screen.dart → `_showAdminPanel()`)

- Reset butonu: tek "Günlük Hakları Sıfırla" butonu (önceden fal adları tek tek yazıyordu)
- Reset edilen key'ler: motivasyon, olumlama, ozlusoz, tarot, kahve, astroloji, kaderkitabi, dertortagi, acigercekler, durugoru, iching, japonfali, kadercarki, askuyumu + numeroloji cache
- **Reklamlar switch'i:** `AdService.instance.adsDisabled` toggle — `admin_ads_disabled` prefs'e kaydedilir
- **godag girişinde:** reklamlar otomatik kapatılır (`AdService.instance.setAdsDisabled(true)`)
- **main.dart'ta:** uygulama açılışında `admin_ads_disabled` prefs okunur, `AdService` güncellenir

### Açık Rıza Metni (settings_screen.dart)

- `futuristicapps1@gmail.com` adresi hem Türkçe hem İngilizce metinden kaldırıldı

### Arc Gradient 12'den Başlıyor (home_screen.dart `_ArcProgressPainter`)

- **Eski:** sarı renk saat 3 yönünde başlıyordu (`gradStart = startAngle - π`)
- **Yeni:** sarı renk saat 12 yönünde başlar (`gradStart = startAngle = -π/2`)
- **Renk paleti (9 durak):** Sarı(#FFE800) → Sarı-Turuncu → Turuncu → Turuncu-Kırmızı → Kırmızı → Kırmızı-Pembe → Pembe → Pembe-Mor → Mor(#8A2EFF)
- `innerSize`: `size - 10` → `size - 6` (ikon çember içini tam doldurur)

### Placeholder (Yakında) Menü İkonları (home_screen.dart)

- `credits == -1` olan yer tutucu kartlar: `Opacity(opacity: 0.15)` ile sarıldı
- Arkaplan hafifçe gözükür, aktif ikonlardan belirgin biçimde ayrışır

### 3. Sayfa Menü Düzeni (home_screen.dart `_page3Items()`)

- Doğum Haritası sağdaki boş slota taşındı
- Rüya Yorumu ile Doğum Haritası arasına boş slot eklendi
- Sıra: I-Ching | Aşk Uyumu | Kader Çarkı / Rüya Yorumu | [boş] | Doğum Haritası / [boş] | [boş] | [boş]

### Fal Konu Seçimi İkonları (coffee_screen.dart `_buildKonuSecim()`)

- Emoji yerine PNG ikonlar: `assets/images/fal_konu/` klasörü
  - `fgenel.png` → Genel
  - `fask.png` → Aşk
  - `fkariyer.png` → Kariyer
  - `fsaglik.png` → Sağlık
- Kutular kare (`childAspectRatio: 0.85`, `Expanded` ile)
- İkon kutu **içinde**, etiket kutu **altında** (14px beyaz)
- pubspec.yaml: `assets/images/fal_konu/` eklendi

### Versiyon Artış Kuralı (YENİ)

**Her build'de versionCode +3 artır** (çakışma önlemek için).
Eski kural: +1 artırıyordu — kaldırıldı.
