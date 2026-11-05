// "Kısmetim Kim?" sonuç açıklamaları (2026-11-05, Anıl: "hep eşin de gelse alttaki açıklama
// değişsin; birbirinizi çok seviyorsunuz, muhabbetiniz kalıcı… motive edici onlarca laftan biri").
//
// Seçim: kullanıcının çizelge tohumu + yıl → art arda yıllarda FARKLI cümle, liste uzunluğu kadar
// yıl boyunca tekrar yok (adım 7, liste uzunluklarıyla aralarında asal). Aynı yıl hep aynı cümle
// (kader tutarlılığı). TR ve EN listeleri aynı sırada ve aynı uzunlukta OLMALI (test: kismet_lines_test).
class KismetLines {
  KismetLines._();

  static const _step = 7;

  static String spouse(int seed, int year, bool en) => _pick(en ? spouseEn : spouseTr, seed, year);
  static String partner(int seed, int year, bool en) => _pick(en ? partnerEn : partnerTr, seed, year);
  static String gap(int seed, int year, bool en) => _pick(en ? gapEn : gapTr, seed, year);

  static String _pick(List<String> l, int seed, int year) {
    final n = l.length;
    final i = ((seed.abs() % n) + year * _step) % n;
    return l[i];
  }

  // ── Eşin ────────────────────────────────────────────────────────────────
  static const spouseTr = <String>[
    'Bağınız yıllar içinde güçlenerek sürüyor.',
    'Birbirinize olan sevginiz zamanla daha da derinleşiyor.',
    'Aranızdaki muhabbet kalıcı görünüyor.',
    'Aynı yöne bakmayı sürdürüyorsunuz; bu yıl bunu daha çok hissedeceksin.',
    'Küçük kırgınlıklar çabuk geçiyor, geriye sıcaklık kalıyor.',
    'Evinizde bu yıl kahkaha eksik olmayacak gibi.',
    'Birbirinizi ilk günkü gibi şaşırtmaya devam ediyorsunuz.',
    'Zor bir dönemde birbirinize daha sıkı tutunacaksınız.',
    'Ortak bir hayaliniz bu yıl bir adım daha yaklaşıyor.',
    'Eşinin sana duyduğu güven, en büyük dayanağın olmaya devam ediyor.',
    'Sessiz anlarınız bile birbirinize iyi geliyor.',
    'Birlikte yeni bir alışkanlık edinecek, ona çok bağlanacaksınız.',
    'Bu yıl birbirinizi yeniden keşfettiğiniz anlar çoğalıyor.',
    'Sevginiz gösterişsiz ama sapasağlam.',
    'Birlikte gülmeyi unutmadığınız sürece hiçbir fırtına sizi yıkamaz.',
    'Eşinle kurduğun bağ, çevrene de güç veriyor.',
    'Yolculukların, sofraların ve sohbetlerin tadı bu yıl bambaşka.',
    'Birbirinize söylemediğiniz bir teşekkür bu yıl dile geliyor.',
    'Aranızdaki uyum, başkalarının imrendiği türden.',
    'Kalpleriniz hâlâ aynı ritimde atıyor.',
    'Uzun yolunuzun en güzel kısmı henüz önünüzde görünüyor.',
    'Paylaştığınız her yük hafifliyor, her sevinç büyüyor.',
    'Eşinin elini tuttuğunda dünya biraz daha sakin.',
    'Bu yıl birlikte vereceğiniz bir karar ikinizi de mutlu edecek.',
    'Muhabbetiniz kalıcı; sohbetleriniz hiç bitmeyecek gibi.',
    'Birbirinize gösterdiğiniz sabır bu yıl meyvesini veriyor.',
    'Aranızdaki dostluk, aşkınızın en sağlam temeli.',
    'Bu yıl beklenmedik bir sürpriz ikinizi de çok güldürecek.',
    'Yıllar geçtikçe birbirinize daha çok benziyorsunuz.',
    'Eşinin desteği, bu yıl atacağın cesur adımın arkasında olacak.',
    'Evinizin enerjisi huzurlu ve sıcak görünüyor.',
    'Birlikte kurduğunuz düzen sağlam; keyfini çıkarın.',
    'Sevginizi artık gözlerinizle de konuşuyorsunuz.',
    'Birlikte biriktirdiğiniz anılar bu yıl yenileriyle çoğalıyor.',
    'Bağınız bir çınar gibi: kökleri derin, gölgesi geniş.',
    'Bu yıl birbirinize ayırdığınız zaman çok kıymetli olacak.',
    'Birbirinizin en iyi hâlini ortaya çıkarmaya devam ediyorsunuz.',
    'Anlaşmazlıklarınız bile sizi birbirinize yaklaştırıyor.',
    'Bu yıl ikinizin de yüzünü güldürecek güzel bir haber var.',
    'Kader sizi bir kez buluşturdu; şimdi de yan yana tutuyor.',
  ];
  static const spouseEn = <String>[
    'Your bond keeps growing stronger over the years.',
    'Your love for each other deepens with time.',
    'The warmth between you looks here to stay.',
    'You keep looking in the same direction; this year you will feel it even more.',
    'Small hurts pass quickly, and only warmth remains.',
    'Your home will not be short of laughter this year.',
    'You keep surprising each other just like on the first day.',
    'In a hard season you will hold on to each other even tighter.',
    'A dream you share comes one step closer this year.',
    "Your spouse's trust in you remains your greatest support.",
    'Even your quiet moments do you both good.',
    'You will pick up a new habit together and grow very fond of it.',
    'This year brings more moments of rediscovering each other.',
    'Your love is unpretentious but rock solid.',
    'As long as you keep laughing together, no storm can break you.',
    'The bond you share with your spouse gives strength to those around you too.',
    'Your trips, your meals and your conversations taste different this year.',
    'An unspoken thank-you finally finds its words this year.',
    'The harmony between you is the kind others envy.',
    'Your hearts still beat to the same rhythm.',
    'The most beautiful part of your long road still seems to lie ahead.',
    'Every burden you share gets lighter, every joy grows bigger.',
    "When you hold your spouse's hand, the world feels a little calmer.",
    'A decision you make together this year will make you both happy.',
    'Your bond is lasting; your talks seem like they will never end.',
    'The patience you show each other bears fruit this year.',
    'The friendship between you is the firmest foundation of your love.',
    'An unexpected surprise will make you both laugh a lot this year.',
    'The years make you more and more alike.',
    "Your spouse's support will stand behind a brave step you take this year.",
    'The energy of your home looks peaceful and warm.',
    'The life you built together is steady; enjoy it.',
    'You now speak your love with your eyes as well.',
    'The memories you have gathered together multiply with new ones this year.',
    'Your bond is like an old plane tree: deep roots, wide shade.',
    'The time you set aside for each other this year will be precious.',
    'You keep bringing out the best in each other.',
    'Even your disagreements bring you closer.',
    'This year holds good news that will make you both smile.',
    'Fate brought you together once, and now it keeps you side by side.',
  ];

  // ── Şu anki partnerin ─────────────────────────────────────────────────
  static const partnerTr = <String>[
    'Aranızdaki çekim güçlü; bu bağın ciddileşme ihtimali yüksek.',
    'Birbirinizi her geçen gün daha iyi tanıyorsunuz.',
    'Bu ilişki sana kendinle ilgili güzel şeyler öğretecek.',
    'Ortak gülüşleriniz bu yılın en güzel anıları olacak.',
    'Aranızdaki güven yavaş ama sağlam adımlarla büyüyor.',
    'Bu yıl birlikte yapacağınız bir plan sizi çok yakınlaştıracak.',
    'Kalbin bu kişiyle huzur buluyor gibi görünüyor.',
    'Küçük jestler bu yıl büyük anlamlar taşıyacak.',
    'Bu bağ, sabır gösterdikçe derinleşecek.',
    'Birbirinize iyi geldiğiniz çevrenizden de belli oluyor.',
    'Bu yıl ilişkinizde güzel bir dönüm noktası görünüyor.',
    'Aranızdaki sohbet hiç bitmeyecek gibi akıp gidiyor.',
    'Bu kişinin yanında daha cesur ve daha özgür hissediyorsun.',
    'Ortak hayaller kurmaya başladığınız bir yıl.',
    'Duygularınızı açıkça konuştukça bağınız güçleniyor.',
    'Bu ilişki sana beklemediğin bir mutluluk getiriyor.',
    'Birlikte geçirdiğiniz sakin akşamlar çok kıymetli olacak.',
    'Kader bu yıl sizi birbirinize biraz daha yaklaştırıyor.',
    'Aranızdaki uyum zamanla daha da belirginleşiyor.',
    'Bu bağın geleceği umut verici görünüyor.',
  ];
  static const partnerEn = <String>[
    'The pull between you is strong; this bond may well become serious.',
    'You get to know each other better every day.',
    'This relationship will teach you beautiful things about yourself.',
    'The laughs you share will be the best memories of this year.',
    'The trust between you grows with slow but steady steps.',
    'A plan you make together this year will bring you much closer.',
    'Your heart seems to find peace with this person.',
    'Small gestures will carry big meanings this year.',
    'This bond will deepen the more patient you are.',
    'Even the people around you can see how good you are for each other.',
    'A lovely turning point appears in your relationship this year.',
    'Your conversations flow as if they will never end.',
    'Next to this person you feel braver and freer.',
    'This is the year you start dreaming together.',
    'Your bond grows stronger the more openly you share your feelings.',
    'This relationship brings you a happiness you did not expect.',
    'The quiet evenings you spend together will be precious.',
    'This year fate brings you a little closer to each other.',
    'The harmony between you becomes clearer with time.',
    'The future of this bond looks hopeful.',
  ];

  // ── Yeni tanışma yok ────────────────────────────────────────────────────
  static const gapTr = <String>[
    'Kendine ayırdığın bu dönem, bir sonraki kısmetine hazırlık gibi.',
    'Bu yıl kalbini dinlendir; doğru kişi zamanını bekliyor.',
    'Kendini keşfettiğin bu yıl, seni bambaşka birine hazırlıyor.',
    'Yalnızlık değil, özgürlük yılı: tadını çıkar.',
    'Dostlukların bu yıl sana aşk kadar iyi gelecek.',
    'Enerjini kendine yatırdığın bir yıl; karşılığı büyük olacak.',
    'Kısmet acele etmiyor; sen de etme.',
    'Bu yıl yeni hobiler, yeni yerler ve yeni bir sen var.',
    'Kalbin dinlenirken hayallerin büyüyor.',
    'Doğru zamanda doğru kapı açılacak; bu yıl hazırlanma vakti.',
    'Kendine iyi bakmanın en güzel yılı olabilir.',
    'Bu sessizlik, ileride gelecek güzel bir sesin habercisi.',
    'Bu yıl başkasını değil, kendini tanıma yılı.',
    'İçindeki ışık parladıkça seni bulacak kişi de yaklaşıyor.',
    'Kendinle barışık olduğun bu dönem, sonraki aşkını güçlendirecek.',
  ];
  static const gapEn = <String>[
    'This time for yourself is like preparation for your next destiny.',
    'Let your heart rest this year; the right person is waiting for the right time.',
    'This year of self-discovery is preparing you for someone very different.',
    'Not a year of loneliness but of freedom: enjoy it.',
    'Your friendships will do you as much good as love this year.',
    'A year of investing in yourself; the reward will be big.',
    'Destiny is in no hurry, and neither should you be.',
    'This year brings new hobbies, new places and a new you.',
    'While your heart rests, your dreams grow.',
    'The right door will open at the right time; this year is for getting ready.',
    'This could be the best year for taking care of yourself.',
    'This silence heralds a beautiful voice yet to come.',
    'This is a year to get to know yourself rather than someone else.',
    'The brighter your inner light shines, the closer the one who will find you comes.',
    'Being at peace with yourself now will strengthen your next love.',
  ];
}
