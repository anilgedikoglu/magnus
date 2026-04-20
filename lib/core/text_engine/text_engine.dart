// ════════════════════════════════════════════════════════════════════════════
// MAGNUS — METİN MOTORU (FAL MOTORU)
// ════════════════════════════════════════════════════════════════════════════
//
// ⚠️  BU DOSYA HEM REFERANS DOKÜMANTASYON HEM DE YENIDEN KULLANILABİLİR
//     YARDIMCI SINIFTIR. YENİ BİR FAL TÜRÜ OLUŞTURURKEN MUTLAKA OKU.
//
// ─────────────────────────────────────────────────────────────────────────────
// KURAL 1 — KİŞİSELLEŞTİRME (Koşullu Filtreleme)
// ─────────────────────────────────────────────────────────────────────────────
//
//   Kullanıcıya gösterilecek metin havuzu, kişinin profiline göre filtrelenir.
//
//   • Her metnin `kosullar` listesi kontrol edilir.
//   • TÜM koşullar kullanıcı profiline uyuyorsa metin havuza girer.
//   • Tek bir koşul bile uymuyorsa o metin KESİNLİKLE gösterilmez.
//   • `kosullar: []` → koşulsuz, herkese gösterilebilir.
//
//   Desteklenen değişken adları (UserProfile alanlarıyla eşleşir):
//     cinsiyet, medeni_durum, meslek, yas, burc, iliski_durumu
//
// ─────────────────────────────────────────────────────────────────────────────
// KURAL 2 — TEKRAR GÖSTERİLMEME (No-Repeat Until Exhausted)
// ─────────────────────────────────────────────────────────────────────────────
//
//   ❌ YANLIŞ: Her açılışta list.shuffle(); list.first
//      → Aynı metin tekrar gelebilir. ASLA yapma.
//
//   ✅ DOĞRU: Kalıcı, karıştırılmış bir sıralama + cursor.
//
//   Bir metin gösterildikten sonra, O TÜR İÇİN UYGUN OLAN TÜM METİNLER
//   BİTENE KADAR BİR DAHA GÖSTERİLEMEZ. Havuz bitince yeniden karıştırılır.
//
//   SharedPreferences anahtarları:
//     `<tur>_siralama`  → List<String>  — karıştırılmış ID sırası
//     `<tur>_cursor`    → int           — sıralamada şu anki konum
//
//   Akış:
//     1. Kayıtlı sıralama yükle.
//     2. Sıralama geçersiz veya yoksa → yeni shuffle oluştur, cursor=0.
//     3. Cursor >= length → tüm metinler bitti, yeniden shuffle, cursor=0.
//     4. orderedIds[cursor] → gösterilecek metin.
//     5. cursor + 1 kaydet (bir sonraki açılış için).
//
// ─────────────────────────────────────────────────────────────────────────────
// KURAL 2b — ÜST ÜSTE AYNI METİN YASAĞI
// ─────────────────────────────────────────────────────────────────────────────
//
//   Havuz tükendiğinde yeniden karıştırılır (Kural 2). Ancak bu sıfırlama
//   anında son gösterilen metin, yeni döngünün BAŞINA gelebilir — bu durumda
//   kullanıcı üst üste iki kez aynı metni görür. Bu yasaktır.
//
//   ✅ DOĞRU uygulama:
//   Havuz sıfırlanırken son gösterilen ID "shown" listesinde tutulur
//   (veya cursor tabanlı sistemde shuffle'ın başına gelmemesi sağlanır).
//
//   shown listesi tabanlı ekranlarda (Motivasyon, Özlü Söz, Biyoritim):
//     if (kalan.isEmpty) {
//       final lastId = shown.isNotEmpty ? shown.last : null;
//       shown = lastId != null ? [lastId] : [];          // ← sadece son ID kalır
//       kalan = pool.where((e) => '${e.id}' != lastId).toList();
//       if (kalan.isEmpty) kalan = List.from(pool);      // tek metin varsa zorunlu tekrar
//     }
//
//   cursor tabanlı ekranlarda (Olumlama, TextEngine.resolveOrder):
//     Shuffle sonrası orderedIds.first == lastId olursa yeniden karıştır.
//
// ─────────────────────────────────────────────────────────────────────────────
// KURAL 3 — GÜNLÜK TUTARLILIK (varsa)
// ─────────────────────────────────────────────────────────────────────────────
//
//   Bazı fal türleri (Biyoritim, Doğum Haritası, Astroloji) aynı gün
//   aynı içeriği göstermelidir.
//
//   SharedPreferences anahtarı: `<tur>_last_date` (yyyy-MM-dd)
//   Aynı gün → cache'ten göster. Farklı gün → yeni seçim, tarihi güncelle.
//   Bu kural, Kural 2 ile birlikte kullanılabilir.
//
// ─────────────────────────────────────────────────────────────────────────────
// KURAL 4 — PLACEHOLDER ({{...}}) RENDER KURALLARI
// ─────────────────────────────────────────────────────────────────────────────
//
//   Her metin kullanıcıya gösterilmeden önce VariableReplacer.replace() ile
//   render edilir. ASLA ham metin direkt Text() widget'ına verilmez.
//
//   Tam placeholder listesi: lib/core/utils/variable_replacer.dart başındaki
//   yorum bloğuna bakılır. Burada sık karıştırılan / yeni eklenen kurallar:
//
//   Kullanıcı profili:
//     {{isim}}         → kullanıcının adı
//     {{yas}}          → yaş (sayı)
//     {{burc}}         → burç adı
//     {{cinsiyet}}     → 'erkek' / 'kadin' / 'lgbt'
//     {{medeni_durum}} → medeni durum
//     {{meslek}}       → meslek
//
//   Doğum tarihi (YENİ):
//     {{dogum gunu}}   → doğduğu gün   (sayı, örn. 14)
//     {{dogum ayi}}    → doğduğu ay    (sayı, örn. 10)
//     {{dogum yili}}   → doğduğu yıl   (sayı, örn. 1983)
//
//   Tarih / Zaman:
//     {{gun}}          → bugünün adı (Pazartesi vb.)
//     {{gun_0}}        → ayın kaçı (sayı)
//     {{gunsayi_0}}    → ayın kaçı (sayı); +N / -N ile offset eklenebilir
//                        Örn: bugün 17 → {{gunsayi_3}} = 20, {{gunsayi_-3}} = 14
//     {{ay}}           → ay adı
//     {{ay_0}}         → ay adı (alias)
//     {{ay_+N}}        → N ay sonraki ay adı
//     {{yil_0}}        → bu yıl (sayı, örn. 2026)
//                        Örn: {{yil_-1}} = 2025, {{yil_2}} = 2028
//     {{saat}}         → saat (HH:MM)
//
//   Render akışı (VariableReplacer.replace içindeki sıra önemlidir):
//     1. Ham metin temizliği (\U escape, tırnak artefaktları)
//     2. <sprite=N> → emoji
//     3. {{data, cinsiyet=..., X | ...}} koşullu metin
//     4. {{kelime, A|B|C}} rastgele seçim
//     5. {{ay_±N}} / {{gun_±N}} ay/gün adı offset
//     5b. {{gunsayi_N}} gün sayısı offset
//     5c. {{yil_N}} yıl offset
//     6. Sade değişken ikamesi (isim, yas, burc, dogum gunu, vb.)
//     7. {{sabit_sayi}} / {{sayi}} rastgele sayılar
//     8. {{rastgeleburc}}, {{burc_*}} catch-all, {{saniye}}
//
// ─────────────────────────────────────────────────────────────────────────────
// REFERANS İMPLEMENTASYON
// ─────────────────────────────────────────────────────────────────────────────
//
//   Tüm kuralları doğru uygulayan örnek:
//     lib/presentation/olumlama/olumlama_screen.dart → _loadData()
//
//   Bu dosyadaki TextEngine sınıfını kullanarak yeni fal türlerini daha kısa
//   kodla yazabilirsin. Bkz. TextEngine.resolveOrder() ve TextEngine.matches().
//
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_profile.dart';

/// Metin motorunun çözdüğü sıralama sonucu.
class TextEngineOrder {
  /// Uygun metin ID'lerinin karıştırılmış sırası.
  final List<int> orderedIds;

  /// Bu açılışta gösterilecek metnin sıradaki indeksi.
  final int cursor;

  const TextEngineOrder({required this.orderedIds, required this.cursor});

  /// Bu açılışta gösterilecek metin ID'si.
  int get currentId => orderedIds[cursor % orderedIds.length];
}

/// Magnus Metin Motoru — koşullu filtreleme + no-repeat sıralama.
///
/// Kullanım:
/// ```dart
/// final prefs  = await SharedPreferences.getInstance();
/// final order  = await TextEngine.resolveOrder(
///   turAdi:   'motivasyon',
///   uygunIds: uygunListe.map((e) => e.id).toSet(),
///   prefs:    prefs,
/// );
/// // order.currentId → gösterilecek metin ID'si
/// // order.orderedIds → tüm sıralama (← → navigasyon için)
/// // order.cursor     → bu açılışın başlangıç indeksi
/// ```
class TextEngine {
  TextEngine._();

  // ─── Koşul eşleştirme ────────────────────────────────────────────────────

  /// Bir metnin `kosullar` listesinin kullanıcı profiline uyup uymadığını
  /// döner. Tüm koşullar uyuyorsa `true`, tek bir koşul uymazsa `false`.
  static bool matches(
    List<Map<String, String>> kosullar,
    UserProfile profile,
  ) {
    if (kosullar.isEmpty) return true;
    for (final k in kosullar) {
      final beklenen = k['deger'] ?? '';
      final gercek   = _profileValue(k['degisken'] ?? '', profile);
      if (gercek != beklenen) return false;
    }
    return true;
  }

  static String _profileValue(String degisken, UserProfile profile) {
    switch (degisken) {
      case 'cinsiyet':      return profile.gender;
      case 'medeni_durum':  return profile.maritalStatus;
      case 'meslek':        return profile.job;
      case 'burc':          return profile.zodiacSign ?? '';
      case 'iliski_durumu':
        const varOlanlar = {
          'iliski_var', 'evli', 'nisanli', 'flort', 'karisik', 'ayri_yasiyor'
        };
        return varOlanlar.contains(profile.maritalStatus) ? 'var' : 'yok';
      default: return '';
    }
  }

  // ─── No-repeat sıralama ──────────────────────────────────────────────────

  /// Verilen `turAdi` için karıştırılmış sıralama + cursor hesaplar.
  ///
  /// - Kaydedilmiş geçerli bir sıralama varsa yükler.
  /// - Cursor sona ulaşmışsa (tüm metinler bitti) yeniden karıştırır.
  /// - Sıralama veya cursor geçersizse sıfırdan oluşturur.
  /// - Bir sonraki açılış için cursor'ı kaydeder.
  ///
  /// [turAdi]   : SharedPreferences anahtar öneki, örn. `'motivasyon'`
  /// [uygunIds] : Bu kullanıcıya uygun metin ID'lerinin kümesi
  /// [prefs]    : Çağıran tarafından açılmış SharedPreferences örneği
  static Future<TextEngineOrder> resolveOrder({
    required String turAdi,
    required Set<int> uygunIds,
    required SharedPreferences prefs,
    Random? rng,
  }) async {
    final r          = rng ?? Random();
    final keyOrder   = '${turAdi}_siralama';
    final keyCursor  = '${turAdi}_cursor';
    final savedOrder = prefs.getStringList(keyOrder);

    List<int> orderedIds;
    int cursor;

    final orderValid = savedOrder != null &&
        savedOrder.length == uygunIds.length &&
        savedOrder.map(int.parse).toSet().containsAll(uygunIds);

    if (orderValid) {
      orderedIds = savedOrder.map(int.parse).toList();
      cursor     = prefs.getInt(keyCursor) ?? 0;

      if (cursor >= orderedIds.length) {
        // Tüm metinler gösterildi → yeniden karıştır
        // Üst üste aynı metin yasağı: son gösterilen ID sıfırlama sonrası ilk sıraya gelemez.
        final lastId = orderedIds.isNotEmpty ? orderedIds[orderedIds.length - 1] : null;
        do { orderedIds.shuffle(r); }
        while (lastId != null && orderedIds.length > 1 && orderedIds.first == lastId);
        cursor = 0;
        await prefs.setStringList(
            keyOrder, orderedIds.map((e) => '$e').toList());
      }
    } else {
      // İlk çalıştırma veya uygun liste değişti → sıfırdan karıştır
      orderedIds = uygunIds.toList()..shuffle(r);
      cursor     = 0;
      await prefs.setStringList(
          keyOrder, orderedIds.map((e) => '$e').toList());
    }

    // Bir sonraki açılış için cursor'ı ilerlet
    await prefs.setInt(keyCursor, cursor + 1);

    return TextEngineOrder(orderedIds: orderedIds, cursor: cursor);
  }
}
