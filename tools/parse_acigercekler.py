import os
import json
import re

BASE_DIR = 'C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu3/AciGercekler/AciGecrekler'

def decode_yaml_escapes(s):
    """Decode YAML string escapes character by character."""
    result = []
    i = 0
    while i < len(s):
        ch = s[i]
        if ch == chr(92) and i + 1 < len(s):
            nxt = s[i+1]
            if nxt == 'n':
                result.append('\n')
                i += 2
            elif nxt == 't':
                result.append('\t')
                i += 2
            elif nxt == '"':
                result.append('"')
                i += 2
            elif nxt == chr(92):
                result.append(chr(92))
                i += 2
            elif nxt == 'u' and i + 5 < len(s):
                hex_str = s[i+2:i+6]
                try:
                    result.append(chr(int(hex_str, 16)))
                    i += 6
                except ValueError:
                    result.append(ch)
                    i += 1
            elif nxt == 'x' and i + 3 < len(s):
                hex_str = s[i+2:i+4]
                try:
                    result.append(chr(int(hex_str, 16)))
                    i += 4
                except ValueError:
                    result.append(ch)
                    i += 1
            else:
                result.append(ch)
                i += 1
        else:
            result.append(ch)
            i += 1
    return ''.join(result)

def parse_asset_file(filepath):
    with open(filepath, 'rb') as f:
        content = f.read().decode('utf-8', errors='replace')

    lines = content.split('\n')

    aciklama_raw = []
    in_aciklama = False
    gerekli_lines = []
    in_gerekli = False

    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\r')
        stripped = line.strip()

        if stripped.startswith('aciklama:'):
            in_aciklama = True
            in_gerekli = False
            i += 1
            continue

        if stripped.startswith('aciklamaEng:') or stripped.startswith('aciklamaBalonuYok:'):
            in_aciklama = False

        if in_aciklama:
            if line.startswith('  - ') or (line.startswith('    ') and aciklama_raw):
                aciklama_raw.append(line)
                i += 1
                continue
            elif stripped == '' or not line.startswith(' '):
                in_aciklama = False

        if stripped.startswith('gerekliDegiskenler:') or stripped.startswith('gerekliDegisken:'):
            in_gerekli = True
            in_aciklama = False
            i += 1
            continue

        if in_gerekli:
            if line and not line.startswith(' ') and not line.startswith('\t'):
                in_gerekli = False
            else:
                gerekli_lines.append(stripped)

        i += 1

    # Parse aciklama - join continuation lines
    full_yaml_str = ''
    for line in aciklama_raw:
        if line.startswith('  - '):
            full_yaml_str = line[4:]  # remove '  - '
        elif line.startswith('    '):
            # Continuation: real newline + spaces = single space
            full_yaml_str += ' ' + line.strip()

    full_yaml_str = full_yaml_str.strip()
    if full_yaml_str.startswith('"') and full_yaml_str.endswith('"'):
        full_yaml_str = full_yaml_str[1:-1]

    decoded = decode_yaml_escapes(full_yaml_str)
    decoded = decoded.strip()

    # Parse gerekliDegiskenler - skip internal app state conditions (mod)
    kosullar = []
    j = 0
    while j < len(gerekli_lines):
        line = gerekli_lines[j]
        if line.startswith('- degiskenAdi:'):
            deg_adi = line.replace('- degiskenAdi:', '').strip()
            deg_deg = ''
            if j+1 < len(gerekli_lines) and 'degiskenDegeri:' in gerekli_lines[j+1]:
                deg_deg = gerekli_lines[j+1].replace('degiskenDegeri:', '').strip()
            # Only add user-profile conditions, skip internal app variables like 'mod'
            if deg_adi not in ('mod',):
                kosullar.append({'degisken': deg_adi, 'deger': deg_deg})
        j += 1

    return decoded, kosullar

# Process all 36 files
entries = []
for i in range(1, 37):
    filepath = os.path.join(BASE_DIR, f'AciGercek {i}.asset')
    text, kosullar = parse_asset_file(filepath)
    entry_id = f'ag{i:03d}'
    entries.append({
        'id': entry_id,
        'metin': text,
        'kosullar': kosullar
    })

print(f'Total entries from files: {len(entries)}')

# 36 original additional "aci gercek" texts in Turkish
additional_texts = [
    "Bir insan seni ne kadar severse sevsin, sana verebileceklerinin bir sınırı vardır. İnsan kendi eksiklerini başkasına veremez. O yüzden sevgiden beklentini ihtiyatlı tut; hiçbir ilişki seni tamamlayamaz, yalnızca tamamlanmış biri seni daha da güçlü kılabilir.",
    "Özür dilemek kolaydır. Asıl zor olan, aynı hatayı bir daha yapmamaktır. Birçok insan özür diler, ağlar, yemin eder ve sonra tam olarak aynı şeyi yeniden yapar. Özür, değişmenin başlangıcı değil; zaman kazanmanın bir yoludur çoğu zaman.",
    "Herkes seni anlıyormuş gibi dinler, aslında sırasını bekler. Gerçek dinleyici bulmak, iyi bir ayna bulmak kadar nadir bir şeydir. İnsanların büyük çoğunluğu seni değil, sende kendilerini görür.",
    "Zaman her şeyi iyileştirmez; zaman sadece alıştırır. Bazı yaralar iz bırakır ve o izler silinmez, yalnızca normalleşir. 'Geçer' demek yerine 'taşınabilir hale gelir' demek daha dürüst olurdu.",
    "Başkalarının sana kötü davranmasına izin verdiğin sürece, kötü davranılmaya devam edileceksin. Sınır koymak bencillik değil, saygının şartıdır. Sınır koymayı öğrenmek, en geç öğrenilen ama en çok ihtiyaç duyulan beceridir.",
    "Mutluluk bir varış noktası değil; anlık, geçici ve kırılgandır. Onu tutmaya çalışmak, suyu avuçlamaya benzer. Mutluluğu aramayı bırakıp hayatın içindeki küçük anlara bakabilmek, çok daha gerçekçi bir hedef.",
    "Sevgini ispat etmek zorunda bırakıldığın her ilişki, seni tüketerek sürer. Gerçek bağ, sürekli sınav gerektirmez. İspatlaması gereken sevgi, zaten çoktan sorgulanmış demektir.",
    "Çoğu insan değişmek istemez, sadece durumun değişmesini ister. Asıl sorunun kendisinde olduğunu kabul etmek, hayattaki en büyük cesaret gerektirir. Değişim acıtır; bu yüzden insanların büyük çoğunluğu onu erteleyerek yaşar.",
    "Birisi sana 'seni anlayan tek benim' diyorsa, büyük ihtimalle seni izole etmeye çalışıyor. Gerçekten anlayan biri, başkalarının da seni anlamasını ister. Anlayışı tekel yapan biri, özünde seni hapsetmeye çalışır.",
    "Geçmişte yaptığın her şey, o an için en iyisini yapmaya çalıştığının kanıtıdır. Kendine karşı acımasız olmak kolaydır; hata yapan birine acıma duymak ise çoğunlukla kendine aittir. Geçmişine yargıç olmak, zaten olmadığın biri gibi davranmaktır.",
    "Bir gün 'keşke' demeyeceğin bir hayat kurmak istiyorsan, bugün rahatsız edici olan şeyleri seçmeye başlamalısın. Konfor, büyümenin en sinsi düşmanıdır. Kolaydaki konaklamak, gizli bir vazgeçiştir.",
    "İnsanlar seni önemsediklerinde zaman bulurlar. 'Vaktim yoktu' sıklıkla 'önceliğim değildin' demektir. Bunu kabul etmek acıtır ama bu gerçeği görememek daha da acı verir.",
    "Kendini sevmediğin sürece, başkasının seni sevmesi sana yetmez. Dışarıdan gelen sevgi, içerideki boşluğu doldurmaz. Aksine, o boşluğu daha da hissettiren bir ayna haline gelir.",
    "Başkalarını suçlamak kolaydır, çünkü sorumluluk almak ağırdır. Ama her şey başkasının suçuysa, sen hiçbir şeyi değiştiremezsin. Kontrolü başkasına bıraktığın anda, özgürlüğünü de bırakmış olursun.",
    "Bazı kapılar kapanır ve bir daha açılmaz. Bunu kabul edemeyenler, kapalı kapıların önünde yıllarca bekler. Gitmesi gereken bir şeyi tutmaya çalışmak, gelecek olana kapıları kapatmaktır.",
    "Sevgi kaybı, bazen insanın kaybettiği şeyin gerçek değerini ilk kez görmesiyle yaşanır. Elinde tuttuğun şeyin kıymetini kaybedince anlamak, insan fıtratının en acı çelişkisidir.",
    "Herkes kendini ortalamadan iyi sanır. Kötü şoförler bile iyi şoför olduğunu düşünür. Bu yanılsama, kendini geliştirmenin önündeki en büyük engeli oluşturur; çünkü iyileştirilmesi gerektiğini görmezsiniz.",
    "Güvenilir biri olmak, güvensiz bir dünyada pahalı bir tercih haline gelir. Dürüstlüğün bedeli ödenmeye devam eder. Yine de bedelini ödemek, o bedelten kaçmaktan daha az ağırdır.",
    "Çocukken hayal ettiğin yetişkin hayatı yaşamıyorsun; çünkü o hayal hiçbir zaman gerçek değildi. Hayal kırıklığı, beklentilerin gerçeklikle buluştuğu noktada doğar. Beklentiyi küçültmek ise pes etmek değil, olgunlaşmaktır.",
    "Hiçbir başarı, yanlış nedenden elde edilmişse içini doldurmaz. Para, statü, onay... Bunların hepsi dışarıdan gelir ve dışarıdan gelen hiçbir şey içerideki susuzluğu kalıcı olarak gidermez.",
    "İnsanların büyük çoğunluğu özgür olduğunu sanır; oysa alışkanlıkların, korkuların ve başkalarının beklentilerinin kölesidir. Özgürlük bir durum değil, sürekli verilen bir mücadeledir.",
    "Hayatta en zor olanlardan biri, birini sevmeye devam etmek ama onunla olmamak gerektiğini bilmektir. Sevgi, beraberliği her zaman meşru kılmaz. Bazen en sevecen şey, bırakmaktır.",
    "Başarılı olmak için çok çalışmak gerekmez; doğru şeyleri yapmak gerekir. Çok çalışmak ama yanlış yönde koşmak, yalnızca daha hızlı yanlış yere ulaşmaktır. Emek, strateji olmadan çoğu zaman boşa akar.",
    "İnsanlar seni en çok savunmasız olduğun anlarda terk eder. Bu bir kötülük değil, insanın güçsüzlükle yüzleşmekten duyduğu rahatsızlığın bir yansımasıdır. Yine de o anda acısı aynıdır.",
    "Sevilmek için kendinden vazgeçen biri, vazgeçtiği kadar sevilir. Geriye kalan sen değil, başkası için şekillenmiş bir kopyasındır. Sahici olmayan bağlar, rüzgarda tutuşan ateş gibidir.",
    "Birisini kaybettiğinde yas tutmak için yetersiz bir zaman dilimi yoktur. Toplum senden hızlı iyileşmeni bekler; çünkü senin yasın onları rahatsız eder. Ama iyileşmek, sırada senin zamanın geldiğinde olur.",
    "Her şeyin bir nedeni vardır demek, acıyı anlamlı kılmanın bir yoludur. Bazen ise bir neden yoktur; sadece kötü şeyler olur. Anlam bulmak teselli eder, ama anlam olmadığında da devam etmek gerekir.",
    "Kendi hikâyenin kahramanı olmak için başkasını kötü adam yapmak zorunda değilsin. İnsanlar sadece kendi bakış açılarından hareket eder; bu onları kötü yapmaz, sadece farklı kılar.",
    "Birinin seni yeterince sevip sevmediğini, sana ne söylediğinden değil ne yaptığından anlarsın. Kelimeler ucuzdur; eylemler ise gerçeği söyler. İnsanlar önceliklerine zaman ayırır.",
    "Yaşlandıkça anlarsın ki çevren daralır, ama derinleşir. Kalabalık arkadaş grupları yerini bir iki güvenilir insana bırakır. Bu bir kayıp değil, netleşmedir; ama netleşmenin bedeli yalnızlık hissidir.",
    "Gerçeği söyleyen insan sevilmez, ama zamanla sayılır. Yalancı dost her kapıda bulunur; dürüst biri ise nadir ve çoğunlukla acıtandır. Acı bir gerçek, tatlı bir yalanın uzun vadeli değerinden çok daha ağır basar.",
    "Kendini başkalarıyla kıyaslamak kaçınılmazdır, ama bu kıyaslama hep aleyhine çalışır. Başkasının en parlak anını kendi en karanlık anınla karşılaştırırsın. Bu mücadeleyi kimse kazanamaz.",
    "Bir ilişkideki güven bir kez kırıldığında, geriye kalan her şey onun gölgesinde yaşar. Güven tamir edilebilir, ama hiçbir zaman eskisi gibi olmaz; çatlak hep orada durur, görünmese bile.",
    "Seçimlerinden kaçınmak da bir seçimdir. Karar vermemek, kendi başına bir karardır. Ve bu kararın da sonuçları olur; sadece onları seçmemiş gibi yaşamanı sağlayacak kadar gecikmeli.",
    "En yalnız hissedilen an, kalabalık içinde kimsenin seni gerçekten tanımadığını fark ettiğin andır. Yüzeysel bağlantılar, sayıca ne kadar çok olursa olsun, yalnızlığın üzerine bir örtü çeker ama altını doldurmaz.",
    "Hayatın en büyük ironisi: en çok değiştirmek istediğin şeyler genellikle en az değiştirebildiğin şeylerdir. Kontrol edemediğin şeylere harcanan enerji, kontrol edebileceklerinden çalar."
]

# Add additional entries
for i, text in enumerate(additional_texts):
    entry_id = f'ag{37+i:03d}'
    entries.append({
        'id': entry_id,
        'metin': text,
        'kosullar': []
    })

print(f'Total entries with additional: {len(entries)}')

# Save to JSON
output = {'acigercekler': entries}
out_path = 'C:/src/magnus_app/assets/data/acigercekler.json'
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)
print(f'Saved to {out_path} ({len(entries)} entries total)')
