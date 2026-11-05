// lib/core/widgets/bar_minimize.dart
//
// Cam alt barın kaydırmayla küçülüp büyümesi (Anıl, 2026-11-05: "yukarı swipe ile
// küçülme, aşağı swipe ile büyüme, aynen böyle; belli bir swipe miktarı sonrası yavaşça").
// Değerler Anıl'ın Instagram (iOS 26) ekran kaydından kare kare ölçüldü (30/60 fps,
// içerik kayması kareler arası korelasyonla, bar boyutu kenar taramasıyla):
//   • Küçük ölçek 0.837 (yükseklik 145/173 px, genişlik 998/1192 px; merkez sabit).
//   • Büyüme (aşağı kaydırma): parmakla birlikte HEMEN hafif "sürünme" başlar (~60 pt'de
//     yolun %21'i), 60 pt'de bar kararını verir ve yayla tam boya oturur.
//   • Küçülme (yukarı kaydırma): ilk ~45 pt hiçbir şey olmaz (küçük oynamalar barı
//     kımıldatmaz), sonra sürünme, 72 pt'de karar + yayla küçülme.
//   • Yay: kütle 1, sertlik 250, sönüm 24 (ζ≈0.76, ~%2-4 taşma), başlangıç hızı 1/sn —
//     ölçülen geçiş eğrisine en küçük kareler uyumu (≈0.2 sn'de oturur).
// Ek kurallar (iOS davranışı): listenin en başında bar hep tam boy; sekme değişince tam
// boy; esneme (overscroll) bölgesindeki hareket sayılmaz; parmak bırakılınca yarım kalan
// sürünme geri döner.

import 'package:flutter/physics.dart';

/// Küçülmüş barın ölçeği.
const double kBarCompactScale = 0.837;

/// Küçülme/büyüme yayı (normalize ilerleme 0 = tam boy, 1 = küçük).
const SpringDescription kBarMinimizeSpring =
    SpringDescription(mass: 1, stiffness: 250, damping: 24);

/// Karar anındaki başlangıç hızı (ilerleme/sn), ölçümden.
const double kBarMinimizeKickVelocity = 1.0;

/// Kaydırma olaylarından barın küçülme durumunu üreten saf mantık (widget'sız, test edilir).
class BarMinimizeLogic {
  BarMinimizeLogic({
    required this.onCreep,
    required this.onCommit,
    required this.onRelease,
  });

  /// Küçülme yönünde ölü bölge (pt): bu kadar kaydırmadan önce bar kımıldamaz.
  static const double collapseDead = 45;

  /// Küçülme kararı (pt).
  static const double collapseSnap = 72;

  /// Büyüme kararı (pt). Büyümede ölü bölge yok.
  static const double expandSnap = 60;

  /// Karardan önceki sürünmenin en fazla ilerlemesi (yolun oranı).
  static const double creep = 0.21;

  /// Sürünme: ilerleme değerini doğrudan ayarla (0..1).
  final void Function(double progress) onCreep;

  /// Karar: yayla küçük (true) ya da tam boy (false) hâle geç.
  final void Function(bool compact) onCommit;

  /// Parmak bırakıldı / kaydırma bitti: yarım kalan sürünmeyi kararlı duruma döndür.
  final void Function(bool compact) onRelease;

  bool _compact = false;
  double _acc = 0;
  bool _creeping = false;

  /// Kararlı durum (sürünme hariç).
  bool get compact => _compact;

  /// Kaydırma farkı (pt): pozitif = içerik yukarı (parmak yukarı) → küçülme yönü.
  void add(double delta) {
    if (delta == 0) return;
    final towardCompact = delta > 0;
    if (towardCompact == _compact) {
      // Zaten o durumdayız: biriken ters yönlü yolu sıfırla, sürünme varsa geri al.
      _acc = 0;
      if (_creeping) {
        _creeping = false;
        onRelease(_compact);
      }
      return;
    }
    _acc += delta.abs();
    if (!_compact) {
      if (_acc >= collapseSnap) {
        _commit(true);
      } else if (_acc > collapseDead) {
        _creeping = true;
        onCreep(creep * (_acc - collapseDead) / (collapseSnap - collapseDead));
      }
    } else {
      if (_acc >= expandSnap) {
        _commit(false);
      } else {
        _creeping = true;
        onCreep(1 - creep * _acc / expandSnap);
      }
    }
  }

  /// Liste en başta (ya da sekme değişti): tam boy.
  void reset() {
    _acc = 0;
    if (_compact || _creeping) _commit(false);
  }

  /// Kaydırma bitti (parmak kalktı ve momentum durdu).
  void release() {
    _acc = 0;
    if (_creeping) {
      _creeping = false;
      onRelease(_compact);
    }
  }

  void _commit(bool compact) {
    _compact = compact;
    _acc = 0;
    _creeping = false;
    onCommit(compact);
  }
}
