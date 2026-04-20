// Pythagorean numeroloji sayı hesaplayıcı
// Kullanım: NumerologiHesap.hesapla(profile)
// Döner: NumerologiSayilar (7 alan, her biri 1-9)

import '../../data/models/user_profile.dart';

class NumerologiSayilar {
  final int ifade;        // İfade/İsim sayısı (tüm harfler)
  final int ruh;          // Ruh/Kalp sayısı (sesli harfler)
  final int yasamYolu;    // Yaşam yolu sayısı (doğum tarihi)
  final int sessizBenlik; // Sessiz benlik sayısı (sessiz harfler)
  final int olgunluk;     // Olgunluk sayısı (ifade + yaşam yolu)
  final int dogumGunu;    // Doğum günü sayısı
  final int karmikBorc;   // Karmik borç sayısı

  const NumerologiSayilar({
    required this.ifade,
    required this.ruh,
    required this.yasamYolu,
    required this.sessizBenlik,
    required this.olgunluk,
    required this.dogumGunu,
    required this.karmikBorc,
  });
}

class NumerologiHesap {
  // Pythagorean harf → sayı tablosu (Türkçe harfler dahil)
  static const Map<String, int> _tablo = {
    'a': 1, 'b': 2, 'c': 3, 'ç': 3, 'd': 4, 'e': 5, 'f': 6,
    'g': 7, 'ğ': 7, 'h': 8, 'ı': 9, 'i': 9, 'j': 1, 'k': 2,
    'l': 3, 'm': 4, 'n': 5, 'o': 6, 'ö': 6, 'p': 7, 'r': 9,
    's': 1, 'ş': 1, 't': 2, 'u': 3, 'ü': 3, 'v': 4, 'y': 7, 'z': 8,
  };

  static const _sesliHarfler = {'a', 'e', 'ı', 'i', 'o', 'ö', 'u', 'ü'};

  // Tek basamağa indir (1-9), 11 ve 22 master sayıları koru ama
  // klasörler 1-9 olduğundan basit indirgeme yeterli
  static int _indirge(int n) {
    while (n > 9) {
      n = n.toString().split('').fold(0, (s, c) => s + (int.tryParse(c) ?? 0));
    }
    return n == 0 ? 1 : n;
  }

  static int _isimSayisi(String isim, {bool sadeceSesli = false, bool sadeceSessiz = false}) {
    int toplam = 0;
    for (final ch in isim.toLowerCase().split('')) {
      final sesli = _sesliHarfler.contains(ch);
      if (sadeceSesli && !sesli) continue;
      if (sadeceSessiz && sesli) continue;
      toplam += _tablo[ch] ?? 0;
    }
    return toplam;
  }

  /// "Bugüne dair" için günlük kişisel sayı (değişir her gün).
  /// = yaşam yolu + ay + gün, indirgenmiş.
  static int bugunSayisi(UserProfile profile) {
    final now = DateTime.now();
    final yolu = hesapla(profile).yasamYolu;
    return _indirge(yolu + now.month + now.day);
  }

  /// "Bu yıla dair" için yıllık kişisel sayı (yıl boyunca sabit).
  /// = yaşam yolu + mevcut yıl rakamları, indirgenmiş.
  static int yilSayisi(UserProfile profile) {
    final now = DateTime.now();
    final yolu = hesapla(profile).yasamYolu;
    final yilRakamlari = now.year.toString().split('').fold(0, (s, c) => s + (int.tryParse(c) ?? 0));
    return _indirge(yolu + yilRakamlari);
  }

  static NumerologiSayilar hesapla(UserProfile profile) {
    // İsim bazlı sayılar
    final temizIsim = profile.name.replaceAll(RegExp(r'[^a-zA-ZğüşıöçĞÜŞİÖÇ]'), '');
    final ifadeToplam    = _isimSayisi(temizIsim);
    final ruhToplam      = _isimSayisi(temizIsim, sadeceSesli: true);
    final sessizToplam   = _isimSayisi(temizIsim, sadeceSessiz: true);

    final ifade    = ifadeToplam > 0 ? _indirge(ifadeToplam) : 1;
    final ruh      = ruhToplam > 0   ? _indirge(ruhToplam)   : 1;
    final sessiz   = sessizToplam > 0 ? _indirge(sessizToplam) : 1;

    // Doğum tarihi bazlı sayılar
    int yasamYolu = 1;
    int dogumGunu = 1;
    if (profile.birthDate != null && profile.birthDate!.isNotEmpty) {
      final parts = profile.birthDate!.split('-');
      if (parts.length == 3) {
        final yil = parts[0];
        final ay  = parts[1];
        final gun = parts[2];
        final tumRakamlar = '$yil$ay$gun';
        yasamYolu = _indirge(tumRakamlar.split('').fold(0, (s, c) => s + (int.tryParse(c) ?? 0)));
        final gunSayisi = int.tryParse(gun) ?? 1;
        dogumGunu = _indirge(gunSayisi);
      }
    }

    final olgunluk  = _indirge(ifade + yasamYolu);
    // Karmik borç: sessiz benlik + doğum günü (yaygın bir yaklaşım)
    final karmikBorc = _indirge(sessiz + dogumGunu);

    return NumerologiSayilar(
      ifade:        ifade,
      ruh:          ruh,
      yasamYolu:    yasamYolu,
      sessizBenlik: sessiz,
      olgunluk:     olgunluk,
      dogumGunu:    dogumGunu,
      karmikBorc:   karmikBorc,
    );
  }
}
