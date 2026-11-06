import 'dart:math';

/// No-repeat seçim sonucu: seçilen öğe + kalıcılaştırılması gereken yeni
/// "gösterilen id" listesi.
class NoRepeatPick<T> {
  final T selected;

  /// Çağrı sonrası prefs'e yazılması gereken güncel "gösterilen" listesi.
  final List<String> shown;

  const NoRepeatPick(this.selected, this.shown);
}

/// CLAUDE.md "⚠️ NO-REPEAT KURALI → Doğru Yöntem" uygulaması.
///
/// Bir metin bir kez gösterildikten sonra, UYGUN tüm diğer metinler bitene
/// kadar tekrar gösterilmez. Havuz tükendiğinde liste sıfırlanır — fakat
/// **en son gösterilen id korunur** ki sıfırlama anında aynı metin üst üste
/// gelmesin ("Yasak Yöntem = shuffle + first" değil).
///
/// * [pool]  → kullanıcıya uygun TÜM adaylar (koşul filtresi uygulanmış;
///   shown DIŞLANMAMIŞ ham havuz).
/// * [shown] → daha önce gösterilen id'ler. Bu liste DEĞİŞTİRİLMEZ; güncel
///   kopya [NoRepeatPick.shown] olarak döner ve çağıran onu kalıcılaştırır.
/// * [idOf]  → bir öğenin stabil string id'si.
/// * [rng]   → test için enjekte edilebilir; verilmezse `Random()`.
///
/// [pool] boşsa `null` döner (seçilecek bir şey yok).
NoRepeatPick<T>? pickNoRepeat<T>({
  required List<T> pool,
  required List<String> shown,
  required String Function(T) idOf,
  Random? rng,
}) {
  if (pool.isEmpty) return null;
  final r = rng ?? Random();

  var eligible = pool.where((e) => !shown.contains(idOf(e))).toList();
  var newShown = List<String>.from(shown);

  if (eligible.isEmpty) {
    // Havuz bitti → üst üste aynı metin yasağını koruyarak sıfırla.
    final lastId = newShown.isNotEmpty ? newShown.last : null;
    newShown = lastId != null ? [lastId] : <String>[];
    eligible = pool.where((e) => idOf(e) != lastId).toList();
    // Havuzda tek metin varsa zorunlu tekrar.
    if (eligible.isEmpty) eligible = List<T>.from(pool);
  }

  eligible.shuffle(r);
  final selected = eligible.first;
  newShown.add(idOf(selected));
  return NoRepeatPick<T>(selected, newShown);
}
