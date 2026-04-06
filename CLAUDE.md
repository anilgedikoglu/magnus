# Magnus App — Claude Proje Hafızası

## Unity .asset Dosyalarından İçerik Dönüştürme İş Akışı

Kullanıcı bir Unity `.asset` klasörü gösterip **"bu türün metinlerini dönüştür"** dediğinde aşağıdaki adımları eksiksiz uygula. Her seferinde anlatmasına gerek yok.

### Kaynak Yapısı
Unity `.asset` dosyaları YAML formatındadır. Türkçe içerik `aciklama:` alanında, İngilizcesi `aciklamaEng:` alanında bulunur. Sadece Türkçeyi al.

### Dönüştürme Adımları

1. **Dosyaları listele** — `os.listdir()` kullan, `find` komutu Windows'ta çalışmaz.
2. **Windows yollarını kullan** — `/c/...` değil, `C:/...` formatında.
3. **Dosyaları `cat` ile oku** — `open(..., encoding='utf-8', errors='replace')` veya subprocess ile.
4. **`aciklama:` bloğunu parse et** — `aciklama:` ile `aciklamaEng:` arasındaki YAML liste öğesini al.
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

### Dikkat Edilecekler

- Python 3.14'te `re.sub(r'\uXXXX', ...)` sözdizimi **hata verir** → karakter döngüsü kullan.
- Windows'ta `subprocess.run(['find', ...])` Windows'un kendi `find`'ını çağırır → `os.listdir()` kullan.
- Terminal encoding bozuk görünse bile JSON UTF-8 doğruysa sorun yok; `'rb'` modunda byte kontrolü yap.

---

## Ana Menü 1. Sohbet Balonu

`home_screen.dart` → `_anaMenu1SohbetBalonu()` metodu.
Her app açılışında 6 selamlama arasından biri random gelir.
Selamlamalar: "Hoş geldin X!", "Merhaba, seni görmek güzel X!", "Ne iyi ettin de geldin X!", "Hoş geldin, safalar getirdin X!", "Seni burada görmek güzel X.", "X merhaba! Nasılsın? Dilerim iyisindir. 😊"
