// lib/presentation/ruya/ruya_yorumu_screen.dart
// Rüya Yorumu ekranı — 100 sembol seçimi + yorum gösterimi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/variable_replacer.dart';
import '../../core/widgets/elegant_hourglass.dart';
import '../../data/models/inbox_item.dart';
import '../../data/providers.dart';

// ── Sembol verisi ──────────────────────────────────────────────────────────────
class _Sembol {
  final String kelime;
  final String kelimeEn;
  final String yorum;
  final String yorumEn;
  const _Sembol(this.kelime, this.yorum, [this.kelimeEn = '', this.yorumEn = '']);
  String kelimeFor(bool isEn) => (isEn && kelimeEn.isNotEmpty) ? kelimeEn : kelime;
  String yorumFor(bool isEn) => (isEn && yorumEn.isNotEmpty) ? yorumEn : yorum;
}

const List<_Sembol> _semboller = [
  _Sembol('Altın',
      'Altın rüyada değer, başarı ve içsel zenginliği simgeler. Altın buluyorsan, çabanın karşılığını görmek ve takdir edilmek üzere olduğunun müjdesini taşır. Altınını kaybediyorsan, maddi ya da duygusal bir kayıp endişesi seni meşgul ediyor. Bu rüya, gerçek değerin maddi şeylerde değil, sende olduğunu hatırlatıyor.',
      'Gold',
      'Gold in a dream symbolizes value, success and inner wealth. If you find gold, it heralds that you are about to see the reward of your effort and be appreciated. If you lose your gold, a worry of material or emotional loss occupies you. This dream reminds you that true worth lies not in material things, but within you.'),
  _Sembol('Araba',
      'Rüyanda araba görmek, hayatında kontrolü ele almak istediğinin işareti. Direksiyonda sen mi yoksa başkası mı oturuyordu, bu sorunun yanıtı sana çok şey söyler. Arabanın hızı ve yönü, hedeflerine ne kadar emin adımlarla yürüdüğünü yansıtıyor. Yakın zamanda önemli bir karar seni bekliyor.',
      'Car',
      'Seeing a car in your dream is a sign that you want to take control of your life. Who was behind the wheel — you or someone else — the answer to that question tells you a lot. The speed and direction of the car reflect how confidently you walk toward your goals. An important decision awaits you soon.'),
  _Sembol('Arı',
      'Arılar rüyada çalışkanlığın ve toplumla uyumun habercisidir. Eğer arı seni sokuyorsa, çevrendekilerin sözlerinin sana beklediğinden fazla dokunduğunu gösterir. Kovan gördüysen, bir ekiple büyük bir başarıya imza atacaksın. Arılar uçuşuyorsa, enerjin ve motivasyonun zirvede.',
      'Bee',
      'Bees in a dream are heralds of diligence and harmony with society. If a bee stings you, it shows that the words of those around you affect you more than you expected. If you saw a hive, you will achieve great success with a team. If the bees are flying about, your energy and motivation are at their peak.'),
  _Sembol('Aslan',
      'Aslan, içindeki güç ve liderlik isteğinin simgesidir. Rüyanda sana saldırıyorsa, hayatında seni tehdit eden bir güçten çekiniyor olabilirsin. Ama aslanı evcilleştirdiğini gördüysen, büyük engellerin üstesinden gelme vakti gelmiş demektir. Bu rüya, cesaretini toplamanı söylüyor.',
      'Lion',
      'The lion is the symbol of the strength and desire for leadership within you. If it attacks you in your dream, you may be wary of a force threatening you in your life. But if you saw yourself taming the lion, it means the time has come to overcome great obstacles. This dream tells you to gather your courage.'),
  _Sembol('At',
      'At rüyada güç, özgürlük ve hayatının hızını simgeler. Hızla koşan bir ata biniyorsan, hedeflerine doğru büyük bir enerji ve kararlılıkla ilerliyorsun. Atı zapt etmekte zorlanıyorsan, hayatındaki bazı güçlü enerjileri ya da içgüdüleri kontrol etmekte güçlük çekiyorsun. Özgürce koşan bir at ise kısıtlamalardan kurtulma ve özgürlüğe kavuşma arzusunu yansıtır.',
      'Horse',
      'A horse in a dream symbolizes power, freedom and the pace of your life. If you ride a galloping horse, you advance toward your goals with great energy and determination. If you struggle to rein it in, you are having difficulty controlling some powerful energies or instincts in your life. A freely running horse reflects the desire to break free of restrictions and attain freedom.'),
  _Sembol('Ateş',
      'Ateş rüyada iki yüzü olan güçlü bir semboldür — hem yıkımı hem de yenilenmeyi temsil eder. Eğer ateş kontrolsüzce yayılıyorsa, içindeki bastırılmış öfke ya da tutku serbest kalmak istiyor. Nazikçe yanan bir ateş gördüysen, ilham ve yaratıcılık dönemine giriyorsun. Ateşin başında ısınmak ise sıcaklık ve güvenlik arayışını simgeler.',
      'Fire',
      'Fire is a powerful two-faced symbol in a dream — it represents both destruction and renewal. If the fire spreads uncontrollably, suppressed anger or passion within you wants to be released. If you saw a gently burning fire, you are entering a period of inspiration and creativity. Warming yourself by a fire symbolizes a search for warmth and security.'),
  _Sembol('Ay',
      'Ay, rüyada bilinçaltı ve sezginin yansımasıdır. Dolunay görmek, duygusal yoğunluğun doruk noktasında olduğunu; hilal ise yeni bir başlangıcın eşiğinde durduğunu gösterir. Ayın denize ya da göle yansıması, iç dünyanın dış dünyayla bütünleşmesinin işaretidir. Sezgilerine kulak ver, sana doğru yolu gösterecekler.',
      'Moon',
      'The Moon is the reflection of the subconscious and intuition in a dream. Seeing a full moon shows that your emotional intensity is at its peak; a crescent shows you stand at the threshold of a new beginning. The moon reflected on a sea or lake is a sign of your inner world merging with the outer world. Listen to your intuition — it will show you the right path.'),
  _Sembol('Ayna',
      'Rüyada ayna, gerçek benliğinle yüzleşmenin zamanı geldiğini söyler. Yansımanın senden farklı göründüğünü fark ettiysen, kendini olduğundan farklı gösterdiğini ya da birinin seni yanlış tanımladığını hissediyorsun. Kırık ayna, kimlik konusundaki belirsizliklerin işareti. Aynada gülümsediğini gördüysen, öz sevgin ve kabul gelişiyor.',
      'Mirror',
      'A mirror in a dream says it is time to face your true self. If you noticed your reflection looking different from you, you feel that you present yourself differently than you are, or that someone has misjudged you. A broken mirror is a sign of uncertainty about identity. If you saw yourself smiling in the mirror, your self-love and acceptance are growing.'),
  _Sembol('Bahçe',
      'Bahçe rüyada beslenme, büyüme ve özenle yetiştirilen şeyleri simgeler. Çiçekli ve verimli bir bahçe, ilişkilerinin ve projelerinin güzel meyveler verdiğinin işaretidir. Bakımsız ve solmuş bir bahçe, ihmal ettiğin ilişkiler ya da hayallerin sana hatırlatılmasıdır. Bahçede ekip biçiyorsan, sabırla emek verdiğin şeylerin zamanı gelince büyüyeceğine dair güçlü bir inanç var içinde.',
      'Garden',
      'A garden in a dream symbolizes nourishment, growth and the things you cultivate with care. A flowering, fertile garden is a sign that your relationships and projects are bearing beautiful fruit. A neglected, withered garden is a reminder of relationships or dreams you have neglected. If you are sowing and tending in the garden, there is a strong belief within you that the things you patiently work for will grow when their time comes.'),
  _Sembol('Balık',
      'Balık rüyada bereket, şans ve bilinçaltının derinliklerini temsil eder. Berrak suda yüzen balıklar, maddi ve duygusal refahın kapıda olduğunu müjdeler. Ölü ya da hasta balıklar, bir projenin ya da ilişkinin enerji kaybettiğini gösterir. Balık tutmak ise sabırsızlıkla beklediğin bir haberin yakında geleceğini işaret eder.',
      'Fish',
      'A fish in a dream represents abundance, luck and the depths of the subconscious. Fish swimming in clear water herald that material and emotional prosperity is at the door. Dead or sick fish show that a project or relationship is losing energy. Catching fish signals that news you have been impatiently awaiting will arrive soon.'),
  _Sembol('Bebek',
      'Bebek rüyada yeni başlangıçların ve saf umutların simgesidir. Ağlayan bir bebek gördüysen, içinde karşılanmayı bekleyen duygusal ihtiyaçlar var. Gülen bir bebek ise hayatına girecek neşe ve yenilenmeyi müjdeler. Bir bebeğe baktığını gördüysen, sorumluluk almaya hazır olduğunu bilinçaltın sana söylüyor.',
      'Baby',
      'A baby in a dream is the symbol of new beginnings and pure hopes. If you saw a crying baby, there are emotional needs within you waiting to be met. A laughing baby heralds the joy and renewal about to enter your life. If you saw yourself caring for a baby, your subconscious is telling you that you are ready to take on responsibility.'),
  _Sembol('Bıçak',
      'Bıçak rüyada keskin kararlar, ayrılıklar ya da gizli korkuların sembolüdür. Bıçak taşıyorsan, kendini korumak için sınırlar çizmek istiyorsun. Bıçakla yaralanırsan, birinin sözleri ya da eylemleri seni derinden etkiliyor demektir. Bıçağı bileyliyorsan, bir sorunu çözmeye kararlı olduğunun işareti.',
      'Knife',
      'A knife in a dream is the symbol of sharp decisions, separations or hidden fears. If you are carrying a knife, you want to draw boundaries to protect yourself. If you are wounded by a knife, it means someone\'s words or actions are affecting you deeply. If you are sharpening the knife, it is a sign that you are determined to solve a problem.'),
  _Sembol('Böcek',
      'Böcekler rüyada genellikle küçük ama rahatsız edici kaygıları simgeler. Üstüne böcek üşüşüyorsa, hayatında seni kemiren ufak sorunlar birikerek büyüyor. Tek bir böcek görüyorsan, dikkatini gerektiren önemsiz sandığın bir detay var. Böcekleri eziyorsan, bu endişelerin üstesinden gelme gücüne sahipsin.',
      'Insect',
      'Insects in a dream usually symbolize small but irritating worries. If insects are swarming over you, the little problems gnawing at you in life are accumulating and growing. If you see a single insect, there is a detail you thought trivial that requires your attention. If you are crushing the insects, you have the power to overcome these worries.'),
  _Sembol('Bulut',
      'Bulutlar rüyada zihnindeki belirsizliğin yansımasıdır. Koyu ve fırtınalı bulutlar, yaklaşan zorlukları haber verir; ama her fırtınanın ardından güneş çıktığını unutma. Beyaz ve pamuk gibi bulutlar, huzur ve özgürlük hissini simgeler. Bulutların arasından parlayan ışık, karanlık bir dönemin sona erdiğine işaret eder.',
      'Cloud',
      'Clouds in a dream are the reflection of the uncertainty in your mind. Dark and stormy clouds foretell approaching difficulties; but remember that the sun comes out after every storm. White, cotton-like clouds symbolize a feeling of peace and freedom. Light shining through the clouds signals that a dark period is coming to an end.'),
  _Sembol('Cenaze',
      'Cenaze rüyada ölümü değil, bir dönemin kapandığını ve yenisinin başladığını simgeler. Kimin cenazesini gördüğün önemli — eğer kendi cenazendeysen, büyük bir dönüşüm geçiriyorsun. Ağlayanların çokluğu, bıraktığın iz hakkında düşündüğünü gösterir. Bu rüya seni geçmişi bırakmaya ve yeni bir sayfa açmaya davet ediyor.',
      'Funeral',
      'A funeral in a dream symbolizes not death, but the closing of one chapter and the start of another. Whose funeral you saw matters — if it is your own funeral, you are going through a great transformation. The number of mourners shows that you are thinking about the mark you leave behind. This dream invites you to let go of the past and turn a new page.'),
  _Sembol('Cin',
      'Rüyada cin görülmesi, bastırılmış duyguların ya da bilinmeyen korkuların yüzeye çıkışının işareti. Eğer cin seni korkutuyorsa, hayatında kontrol edemediğini hissettiğin bir durum var. Ama cinin sana yardım ettiğini gördüysen, beklenmedik yerden destek alacaksın. Bu rüya, karanlığı kabul etmek ve onunla yüzleşmek için bir davettir.',
      'Genie',
      'Seeing a genie in a dream is a sign of suppressed emotions or unknown fears surfacing. If the genie frightens you, there is a situation in your life you feel you cannot control. But if you saw the genie helping you, you will receive support from an unexpected source. This dream is an invitation to accept the darkness and face it.'),
  _Sembol('Çanta',
      'Çanta rüyada taşıdığın sorumlulukları ve sırları temsil eder. Ağır bir çanta taşıyorsan, üstüne aldığın yükler seni bunaltıyor. Çantanın içini arıyorsan, kendini kayıp hissediyorsun ya da kaybettiğini düşündüğün bir şeyi arıyorsun. Boş bir çanta görüyorsan, yeni başlangıçlar için hazır olduğunu bilinçaltın söylüyor.',
      'Bag',
      'A bag in a dream represents the responsibilities and secrets you carry. If you are carrying a heavy bag, the burdens you have taken on are overwhelming you. If you are searching inside the bag, you feel lost or are looking for something you think you have lost. If you see an empty bag, your subconscious is telling you that you are ready for new beginnings.'),
  _Sembol('Çiçek',
      'Çiçekler rüyada sevgi, güzellik ve büyümenin sembolüdür. Açan çiçekler, ilişkilerinde ya da kişisel gelişiminde güzel bir dönemin habercisi. Solmuş çiçekler ise treni kaçırma korkusunu ya da ihmal edilen bağlantıları simgeler. Birinden çiçek alıyorsan, takdir görme ve sevilme ihtiyacın ön plana çıkıyor.',
      'Flower',
      'Flowers in a dream are the symbol of love, beauty and growth. Blooming flowers herald a beautiful period in your relationships or personal development. Withered flowers symbolize the fear of missing the boat or neglected connections. If you receive flowers from someone, your need to be appreciated and loved comes to the fore.'),
  _Sembol('Çocuk',
      'Çocuk rüyada masumiyetin, kayıp oyun havasının ve iç çocuğunun sesidir. Mutlu oynayan bir çocuk, yaratıcılık ve özgürlük özlemini yansıtır. Ağlayan ya da kayıp bir çocuk görüyorsan, ihmal ettiğini hissettiğin bir ihtiyaç ya da hayal var. Bu rüya, sana kendine karşı daha nazik olmayı hatırlatıyor.',
      'Child',
      'A child in a dream is the voice of innocence, lost playfulness and your inner child. A happily playing child reflects a longing for creativity and freedom. If you see a crying or lost child, there is a need or dream you feel you have neglected. This dream reminds you to be gentler with yourself.'),
  _Sembol('Çöl',
      'Çöl rüyada yalnızlığı, kayıp hissi ya da arayış içinde olduğunu gösterir. Uçsuz bucaksız kumlar, sınırlarını zorlayan büyük bir deneyimin önünde durduğunu simgeler. Çölde suya ulaşıyorsan, uzun bir mücadelenin sonunda ödüllendirileceksin. Çölde yolunu buluyorsan, içgüdülerine güvenme vakti gelmiş.',
      'Desert',
      'A desert in a dream shows loneliness, a feeling of loss or that you are in search of something. The endless sands symbolize that you stand before a great experience that pushes your limits. If you reach water in the desert, you will be rewarded at the end of a long struggle. If you find your way in the desert, the time has come to trust your instincts.'),
  _Sembol('Dağ',
      'Dağ rüyada önündeki engellerle hedeflerinin büyüklüğünü simgeler. Dağa tırmanıyorsan, hedeflerine ulaşmak için çaba sarf ettiğini ve kararlı olduğunu gösterir. Zirveye ulaştıysan, büyük bir başarının eşiğindesin. Dağın tepesinde duruyorsan, büyük bir bakış açısı kazanma ve geniş bir perspektiften bakma zamanı geldi.',
      'Mountain',
      'A mountain in a dream symbolizes both the obstacles before you and the magnitude of your goals. If you are climbing the mountain, it shows you are making an effort and are determined to reach your goals. If you have reached the summit, you are on the verge of a great success. If you are standing on the mountaintop, the time has come to gain a broad perspective and look from a wider viewpoint.'),
  _Sembol('Deniz',
      'Deniz rüyada duygularının derinliğini ve bilinçaltının enginliğini temsil eder. Sakin ve berrak bir deniz, iç huzurunun güçlü olduğunu gösterir. Dalgalı ve fırtınalı bir deniz, duygusal karmaşa içinde olduğunu simgeler. Denizde yüzüyorsan, duygularınla barışık olduğun ya da olmak istediğin dönemdesin.',
      'Sea',
      'The sea in a dream represents the depth of your emotions and the vastness of your subconscious. A calm and clear sea shows that your inner peace is strong. A wavy and stormy sea symbolizes that you are in emotional turmoil. If you are swimming in the sea, you are in a period where you are at peace with your emotions, or wish to be.'),
  _Sembol('Deve',
      'Deve rüyada sabır, dayanıklılık ve uzun zorlu yolculuklara hazır olma işaretidir. Deve üzerinde yolculuk yapıyorsan, sabır gerektiren uzun soluklu bir süreçtesin ve doğru yoldasın. Deve su içiyorsa, duygusal ya da fiziksel olarak güç topladığın bir dönemdesin. Bu rüya sana, her zor sürecin sonunda bereketli bir vaha olduğunu hatırlatıyor.',
      'Camel',
      'A camel in a dream is a sign of patience, endurance and readiness for long, difficult journeys. If you are traveling on a camel, you are in a long-lasting process that requires patience, and you are on the right path. If the camel is drinking water, you are in a period of gathering strength emotionally or physically. This dream reminds you that at the end of every hard process there is a bountiful oasis.'),
  _Sembol('Diş',
      'Diş rüyada özgüven, görünüş kaygısı ve sözlerin gücünü simgeler. Diş dökülmesi rüyaların en yaygınlarından biridir ve genellikle kayıp korkusunu ya da değersizleşme endişesini yansıtır. Dişlerini fırçalıyorsan, temizlenme ve yeniden başlama isteği içindesin. Parlak dişler görüyorsan, özgüvenin ve karizmanın fark edildiğinin işaretidir.',
      'Tooth',
      'A tooth in a dream symbolizes self-confidence, concern about appearance and the power of words. Losing teeth is one of the most common dreams and usually reflects the fear of loss or the worry of becoming worthless. If you are brushing your teeth, you are in a state of wanting to cleanse and start anew. If you see bright teeth, it is a sign that your confidence and charisma are being noticed.'),
  _Sembol('Düşme',
      'Düşme rüyası, kontrolü yitirme korkusunun ya da güvenli zemini kaybetme hissinin yansımasıdır. Çok sık görülür çünkü stres altında olduğumuzda bilinçaltı bu şekilde uyarır. Düşerken birinin seni tutmasını gördüysen, hayatında seni destekleyen güçlü bağlar var. Düşüp kalkabiliyorsan, yeniden ayağa kalkma gücüne sahip olduğunun müjdesidir.',
      'Falling',
      'A falling dream is the reflection of the fear of losing control or the feeling of losing safe ground. It is very common, because when we are under stress the subconscious warns us this way. If you saw someone catch you while falling, there are strong bonds supporting you in your life. If you can fall and get back up, it heralds that you have the strength to rise again.'),
  _Sembol('Ejderha',
      'Ejderha rüyada hem korku hem de güç kaynağı olan bir enerjiyi simgeler. Seni kovalayan bir ejderha, hayatında karşı koymakta zorlandığın büyük bir güç ya da kişi var demektir. Ama ejderhayı kontrol altına alıyorsan ya da onunla uçuyorsan, muazzam bir güce sahip olduğunu ve bunu kullanabileceğini keşfediyorsun. Bu rüya, korkunla yüzleşmeye hazır olduğunun işareti.',
      'Dragon',
      'A dragon in a dream symbolizes an energy that is a source of both fear and power. A dragon chasing you means there is a great force or person in your life that you struggle to resist. But if you are taming the dragon or flying with it, you are discovering that you possess immense power and can use it. This dream is a sign that you are ready to face your fear.'),
  _Sembol('Ekmek',
      'Ekmek rüyada temel ihtiyaçları, güveni ve paylaşımı simgeler. Taze ekmek görüyorsan, maddi ve duygusal olarak bolluk dönemine giriyorsun. Bayat ya da küflü ekmek, ihmal ettiğin beslenme ihtiyaçlarına dikkat et mesajı taşır. Başkalarıyla ekmek paylaşıyorsan, cömertliğin ve bağlantılarının güçlendiğinin işareti.',
      'Bread',
      'Bread in a dream symbolizes basic needs, security and sharing. If you see fresh bread, you are entering a period of material and emotional abundance. Stale or moldy bread carries the message to pay attention to the nourishment needs you have neglected. If you are sharing bread with others, it is a sign that your generosity and connections are strengthening.'),
  _Sembol('El',
      'Eller rüyada ilişkiler, yardım ve etki gücünü temsil eder. Uzatılan bir el gördüysen, yakında ihtiyacın olduğunda biri sana destek çıkacak. Kirli ya da yaralı eller, içinde taşıdığın suçluluk ya da yorgunluğun ifadesidir. Güçlü ellerin içinde olduğunu hissediyorsan, güvende ve korunduğunu hissediyorsun demektir.',
      'Hand',
      'Hands in a dream represent relationships, help and the power of influence. If you saw an outstretched hand, someone will support you soon when you are in need. Dirty or wounded hands are the expression of guilt or exhaustion you carry within. If you feel you are within strong hands, it means you feel safe and protected.'),
  _Sembol('Ev',
      'Ev rüyada kendin ve iç dünyanın simgesidir — her oda, ruhunun farklı bir yönünü yansıtır. Güzel ve düzenli bir ev iç huzurunu; dağınık ve bakımsız bir ev zihinsel karmaşanı gösterir. Yabancı odalara giriyorsan, henüz keşfetmediğin potansiyeller seni bekliyor. Evin çöküşünü gördüysen, eski inançlarını terk etme ve yeniden inşa etme vakti gelmiş.',
      'House',
      'A house in a dream is the symbol of yourself and your inner world — each room reflects a different aspect of your soul. A beautiful, orderly house shows inner peace; a messy, neglected house shows mental clutter. If you are entering unfamiliar rooms, potentials you have not yet discovered await you. If you saw the house collapse, the time has come to abandon your old beliefs and rebuild.'),
  _Sembol('Fare',
      'Fare rüyada küçük kaygıların ve sinsi sorunların sembolüdür. Birçok fare görüyorsan, hayatında görmezden gelmek istediğin ama birikerek büyüyen sorunlar var. Tek bir fare ise dikkatini çeken ufak ama önemli bir ayrıntıya işaret eder. Fareyi yakalıyorsan, uzun süredir uğraştığın bir sorunu çözüme kavuşturacaksın.',
      'Mouse',
      'A mouse in a dream is the symbol of small worries and insidious problems. If you see many mice, there are problems in your life you want to ignore but which accumulate and grow. A single mouse points to a small but important detail catching your attention. If you catch the mouse, you will resolve a problem you have been dealing with for a long time.'),
  _Sembol('Fener',
      'Fener rüyada karanlıkta rehberlik eden bilgeliği ve sezgiyi simgeler. Elinde fener taşıyorsan, doğru yolda olduğunu ve içgüdülerine güvenerek ilerleyebileceğini gösterir. Fenerin söndüğünü gördüysen, yolunu kaybetme ya da yalnız kalma endişesi içindesin. Uzakta yanan bir fener ümidi ve yaklaşmakta olan iyiyi müjdeler.',
      'Lantern',
      'A lantern in a dream symbolizes the wisdom and intuition that guide in the dark. If you are carrying a lantern, it shows you are on the right path and can advance by trusting your instincts. If you saw the lantern go out, you are anxious about losing your way or being left alone. A lantern burning in the distance heralds hope and approaching good.'),
  _Sembol('Fırtına',
      'Fırtına rüyada bastırılmış duyguların ve yaklaşan değişimin simgesidir. Fırtınanın ortasındaysan, zorlayıcı bir dönemin tam içindesin ama bunu atlatabalirsin. Fırtınayı uzaktan seyrediyorsan, başkalarının kaosu seni etkiliyor ama sen güvendesin. Fırtınanın dindiğini gördüysen, en zor dönem geride kalıyor ve netlik geliyor.',
      'Storm',
      'A storm in a dream is the symbol of suppressed emotions and approaching change. If you are in the middle of the storm, you are right inside a challenging period but you can get through it. If you are watching the storm from afar, the chaos of others is affecting you but you are safe. If you saw the storm subside, the hardest period is being left behind and clarity is coming.'),
  _Sembol('Fil',
      'Fil rüyada bellek, bilgelik ve büyük engelleri aşma gücünü simgeler. Sakin bir fil görüyorsan, güçlü ve bilge bir rehberin ya da koruyanın varlığı seni destekliyor. Fille konuşuyorsan, aklını ve sezgini birlikte kullanman gerektiğinin işareti. Bir fil seni korkutuyorsa, hayatında görmezden gelmekte zorlandığın ama ele alman gereken büyük bir mesele var.',
      'Elephant',
      'An elephant in a dream symbolizes memory, wisdom and the power to overcome great obstacles. If you see a calm elephant, the presence of a strong and wise guide or protector is supporting you. If you are talking with the elephant, it is a sign that you must use your mind and intuition together. If an elephant frightens you, there is a big issue in your life you struggle to ignore but must address.'),
  _Sembol('Gece',
      'Gece rüyada bilinçaltının derinliklerini, sırları ve bilinmeyeni simgeler. Karanlık bir gecede yürüyorsan, belirsizlikle yüz yüzesin ve rehberlik ihtiyacı duyuyorsun. Yıldızlı bir gece ise içindeki karanlıkta bile ümit ve güzellik bulabildiğinin işareti. Şafak söküyorsa, uzun bir belirsizlik dönemi sona eriyor.',
      'Night',
      'Night in a dream symbolizes the depths of the subconscious, secrets and the unknown. If you are walking on a dark night, you are face to face with uncertainty and feel the need for guidance. A starry night is a sign that you can find hope and beauty even in your inner darkness. If dawn is breaking, a long period of uncertainty is coming to an end.'),
  _Sembol('Gemi',
      'Gemi rüyada hayat yolculuğunu ve duygusal seyri simgeler. Büyük ve sağlam bir gemi, güçlü temeller ve güvenli bir yolculuğa işaret eder. Batan bir gemi, büyük bir projenin ya da ilişkinin sona erme korkusunu yansıtır. Yeni bir limana yanaşıyorsan, farklı bir hayat evresine girişin habercisidir.',
      'Ship',
      'A ship in a dream symbolizes the journey of life and the emotional voyage. A large, sturdy ship points to strong foundations and a safe journey. A sinking ship reflects the fear of a major project or relationship coming to an end. If you are docking at a new harbor, it heralds your entry into a different phase of life.'),
  _Sembol('Gökyüzü',
      'Gökyüzü rüyada özgürlük, hayaller ve olasılıkların sınırsızlığını temsil eder. Açık ve mavi bir gökyüzü, zihinsel netlik ve iyimserliğin simgesidir. Bulutlu ya da karanlık bir gökyüzü, üzerinden atamadığın bir yükün işareti. Gökyüzüne uçuyorsan, sınırlarını aşmaya hazır olduğunu ve özgürlüğü hak ettiğini bilinçaltın söylüyor.',
      'Sky',
      'The sky in a dream represents freedom, dreams and the boundlessness of possibilities. A clear, blue sky is the symbol of mental clarity and optimism. A cloudy or dark sky is the sign of a burden you cannot shake off. If you are flying into the sky, your subconscious is telling you that you are ready to surpass your limits and deserve freedom.'),
  _Sembol('Göl',
      'Göl rüyada sakin ama derin duyguları ve gizli güzellikleri simgeler. Berrak bir gölde yüzüyorsan, duygularınla barışıksın ve içsel huzura ulaşmak üzeresin. Bulanık bir göl, gerçeği görmekte zorlandığını ya da duygusal karmaşa içinde olduğunu gösterir. Gölün dibine dalıyorsan, bilinçaltındaki derin bir gerçeği keşfetmeye hazırsın.',
      'Lake',
      'A lake in a dream symbolizes calm but deep emotions and hidden beauties. If you are swimming in a clear lake, you are at peace with your emotions and about to reach inner peace. A murky lake shows that you struggle to see the truth or are in emotional turmoil. If you are diving to the bottom of the lake, you are ready to discover a deep truth in your subconscious.'),
  _Sembol('Gölge',
      'Gölge rüyada gizlenen ya da kabul edilmek istenmeyen yönlerini simgeler. Kendi gölgeni kovalıyorsan, kendinden kaçtığının ve kabullenilmesi gereken bir gerçekle yüzleşmen gerektiğinin işareti. Gölgeni kaybediyorsan, kimlik bunalımı ve yön arayışı içindesin. Gölgenle dans ediyorsan, karanlık yönlerinle barışmayı öğreniyorsun.',
      'Shadow',
      'A shadow in a dream symbolizes the aspects of you that are hidden or unwanted. If you are chasing your own shadow, it is a sign that you are running from yourself and must face a truth that needs to be accepted. If you are losing your shadow, you are in an identity crisis and a search for direction. If you are dancing with your shadow, you are learning to make peace with your dark sides.'),
  _Sembol('Gül',
      'Gül rüyada aşk, güzellik ve tutkunun en güçlü sembolüdür. Kırmızı gül görüyorsan, yakın dönemde yoğun bir duygusal deneyim yaşayacaksın. Dikenler seni batırıyorsa, sevginin acısını ya da aşkın bedelini ödemeye hazır olman gerekiyor. Solmuş güller, özlemini duyduğun bir şeyin ya da birinin artık geride kaldığını simgeler.',
      'Rose',
      'A rose in a dream is the most powerful symbol of love, beauty and passion. If you see a red rose, you will experience an intense emotional experience soon. If the thorns prick you, you must be ready to pay the pain of love or the price of passion. Withered roses symbolize that something or someone you long for is now left behind.'),
  _Sembol('Güneş',
      'Güneş rüyada yaşam enerjisi, umut ve aydınlanmanın en güçlü simgesidir. Parlayan güneş altında sıcaklık hissediyorsan, hayatında enerji ve coşkunun doruğa çıkacağı bir dönem başlıyor. Güneşin tutulduğunu ya da söndüğünü görüyorsan, içinde bulunduğun bir süreç sana kısıtlayıcı ve karanlık geliyor. Güneş doğarken izliyorsan, uzun bir bekleyişin ardından yeni bir başlangıcın kapıyı çaldığını bilinçaltın müjdeliyor.',
      'Sun',
      'The sun in a dream is the most powerful symbol of life energy, hope and enlightenment. If you feel warmth under a shining sun, a period is beginning in which your energy and enthusiasm will peak. If you see the sun eclipsed or extinguished, a process you are in feels restrictive and dark to you. If you are watching the sun rise, your subconscious heralds that after a long wait, a new beginning is knocking at your door.'),
  _Sembol('Hastane',
      'Hastane rüyada iyileşme, kırılganlık ve bakıma muhtaç hissetmeyi simgeler. Hasta olarak hastanedeysen, duygusal ya da fiziksel olarak kendine daha çok özen göstermen gerekiyor. Başkasını ziyaret ediyorsan, çevrendeki birine destek olmaya hazır olduğunun işareti. İyi bir tedaviden çıkıyorsan, uzun süredir çektiğin bir şeyin sonuna yaklaşıyorsun.',
      'Hospital',
      'A hospital in a dream symbolizes healing, fragility and feeling in need of care. If you are in the hospital as a patient, you need to take better care of yourself emotionally or physically. If you are visiting someone, it is a sign that you are ready to support someone around you. If you are leaving after a good treatment, you are nearing the end of something you have long suffered from.'),
  _Sembol('Hayvan',
      'Rüyada genel olarak vahşi ya da evcil hayvan görmek, içgüdülerinin ve doğal enerjinin mesajını taşır. Evcil ve sevimli bir hayvan, sıcaklık ve bağlılık ihtiyacını simgeler. Vahşi bir hayvan saldırıyorsa, bastırılmış öfke ya da kontrol edilmesi gereken güçlü bir duygu var. Hayvana bakıyorsan, koruyucu ve şefkatli yönün ön plana çıkıyor.',
      'Animal',
      'Seeing a wild or domestic animal in a dream generally carries the message of your instincts and natural energy. A tame, lovable animal symbolizes the need for warmth and attachment. If a wild animal attacks, there is suppressed anger or a powerful emotion that needs to be controlled. If you are caring for the animal, your protective and compassionate side comes to the fore.'),
  _Sembol('Hırsız',
      'Hırsız rüyada kayıp korkusunu ve güvensizlik hissini simgeler. Senden bir şey çalınıyorsa, enerjini, zamanını ya da değer verdiğin bir şeyi kaybetmekten korkuyorsun. Hırsızı yakalıyorsan, hayatındaki dengesizliği fark ettin ve müdahale etme gücüne sahipsin. Bu rüya, neyin senden alındığını ya da kimin senden aldığını sorgulamana davet eder.',
      'Thief',
      'A thief in a dream symbolizes the fear of loss and a feeling of insecurity. If something is being stolen from you, you fear losing your energy, time or something you value. If you catch the thief, you have realized the imbalance in your life and have the power to intervene. This dream invites you to question what is being taken from you, or who is taking it.'),
  _Sembol('İnsan',
      'Rüyada tanımadığın bir insanı görmek, bilinçaltının sana bir mesaj gönderdiğinin işareti. Bu insan bazen içindeki farklı bir yönünü ya da başka bir bakış açısını temsil eder. Eğer bu kişi seni korkutuyorsa, hayatında yabancı ya da anlaşılmaz bulduğun bir şey var. Gülen ve sıcak bir yabancı ise yeni bağlantılar ve sürpriz destekler müjdeler.',
      'Person',
      'Seeing a stranger in a dream is a sign that your subconscious is sending you a message. This person sometimes represents a different aspect of you or another point of view. If this person frightens you, there is something in your life you find strange or incomprehensible. A smiling, warm stranger heralds new connections and surprise support.'),
  _Sembol('İp',
      'İp rüyada bağlar, kısıtlamalar ve bağlantıları simgeler. Sıkıca bağlıysan, özgür hissetmediğin ya da sınırlandırıldığını düşündüğün bir ilişki ya da durum var. İpi çözüyorsan, bir kısıtlamadan kurtulma yolundasın. Birini iple tutuyorsan ya da seni tutuyorlarsa, güçlü ama zorlu bir bağın içindesin.',
      'Rope',
      'A rope in a dream symbolizes bonds, restrictions and connections. If you are tightly bound, there is a relationship or situation in which you do not feel free or feel limited. If you are untying the rope, you are on your way to freeing yourself from a restriction. If you are holding someone with a rope or they are holding you, you are in a strong but difficult bond.'),
  _Sembol('Kan',
      'Kan rüyada hayat enerjisi, güç ve bazen derin duygusal acıyı simgeler. Kendi kanını görüyorsan, büyük bir fedakarlık yaptığını ya da yapacağını gösterir. Başkasının kanı ise yakınındaki biri için endişelendiğini yansıtır. Kan duruyorsa ya da yara iyileşiyorsa, zor bir süreç kapanıyor ve iyileşme başlıyor.',
      'Blood',
      'Blood in a dream symbolizes life energy, strength and sometimes deep emotional pain. If you see your own blood, it shows you have made or will make a great sacrifice. Someone else\'s blood reflects that you are worried about a loved one. If the blood stops or the wound is healing, a difficult process is closing and recovery is beginning.'),
  _Sembol('Kapı',
      'Kapı rüyada fırsatlar, seçimler ve geçişleri simgeler. Açık bir kapı, hayatında yeni olanakların kapıldığını gösterir — sadece geçmek cesaretini toplamalısın. Kapalı bir kapı, henüz hazır olmadığın ya da izin verilmediğin bir alanı simgeler. Kapıyı çalıyorsan, bir kapının açılmasını istiyorsun ama sabırsız davranıyorsun.',
      'Door',
      'A door in a dream symbolizes opportunities, choices and transitions. An open door shows that new possibilities beckon in your life — you just need to gather the courage to walk through. A closed door symbolizes an area you are not yet ready for or not allowed into. If you are knocking on the door, you want a door to open but you are being impatient.'),
  _Sembol('Kar',
      'Kar rüyada temizlik, sessizlik ve yeni başlangıçları temsil eder. Bembeyaz kar üzerinde yürümek, temiz bir sayfa açmaya hazır olduğunun işareti. Karda kayıp kalmak, soğukluk ya da duygusal mesafe hissini simgeler. Karın erimesi ise uzun süre donuk kalan bir durumun çözüme kavuşacağının müjdesidir.',
      'Snow',
      'Snow in a dream represents purity, silence and new beginnings. Walking on pure white snow is a sign that you are ready to turn a clean page. Getting lost in the snow symbolizes a feeling of coldness or emotional distance. Melting snow heralds that a situation frozen for a long time will be resolved.'),
  _Sembol('Karanlık',
      'Karanlık rüyada bilinmeyenin korkusu ve bilinçaltının derinliklerini temsil eder. Karanlıkta yürüyorsan, belirsizliğin içinde yolunu bulmaya çalışıyorsun. Bir ışık arıyorsan, netlik ve rehberlik ihtiyacın çok güçlü. Karanlıkta rahat hissediyorsan, içsel bilgeliğinle barışıktın ve kendi yolunu bulmakta yeteneklisin.',
      'Darkness',
      'Darkness in a dream represents the fear of the unknown and the depths of the subconscious. If you are walking in the dark, you are trying to find your way through uncertainty. If you are searching for a light, your need for clarity and guidance is very strong. If you feel comfortable in the dark, you are at peace with your inner wisdom and skilled at finding your own way.'),
  _Sembol('Kedi',
      'Kedi rüyada bağımsızlık, sezgi ve gizemi simgeler. Sana dokunan sevimli bir kedi, ilişkilerinde sıcaklık ve yakınlık ihtiyacını yansıtır. Saldırgan ya da korkutucu bir kedi, hayatında güvenmekte zorlandığın, ikiyüzlü davrandığını düşündüğün biri olabilir. Kedi sesini duyuyorsan, bilinçaltı mesajlarına daha dikkatli kulak ver.',
      'Cat',
      'A cat in a dream symbolizes independence, intuition and mystery. A lovable cat touching you reflects the need for warmth and closeness in your relationships. An aggressive or frightening cat may be someone in your life you struggle to trust, whom you think is two-faced. If you hear a cat\'s sound, listen more carefully to your subconscious messages.'),
  _Sembol('Kelebek',
      'Kelebek rüyada dönüşümün, özgürlüğün ve ruhun hafifliğinin en güzel simgesidir. Etrafında uçuşan kelebekler, hayatındaki güzelliği ve geçiciği görme çağrısıdır. Tırtıldan kelebeğe dönüşümü izliyorsan, sen de büyük bir değişim geçiriyorsun. Kelebeği yakalamaya çalışıyorsan, güzelliği ve mutluluğu daha az arama, onların sana gelmesine izin ver.',
      'Butterfly',
      'A butterfly in a dream is the most beautiful symbol of transformation, freedom and the lightness of the soul. Butterflies fluttering around you are a call to see the beauty and transience in your life. If you are watching the transformation from caterpillar to butterfly, you too are going through a great change. If you are trying to catch the butterfly, seek beauty and happiness less, and let them come to you.'),
  _Sembol('Kitap',
      'Kitap rüyada bilgi, sırlar ve öğrenme yolculuğunu simgeler. Bir kitap okuyorsan, içinde bulunduğun süreçten derin dersler çıkarmakta olduğunu gösterir. Kitabı açamıyorsan ya da sayfalar boşsa, erişmek istediğin bilgiye henüz ulaşamama hissi içindesin. Sana bir kitap veriliyorsa, hayatındaki birinin sana çok değerli bir şey öğretmek üzere olduğunun işareti.',
      'Book',
      'A book in a dream symbolizes knowledge, secrets and the journey of learning. If you are reading a book, it shows you are drawing deep lessons from the process you are in. If you cannot open the book or the pages are blank, you feel unable to reach the knowledge you want. If a book is given to you, it is a sign that someone in your life is about to teach you something very valuable.'),
  _Sembol('Köpek',
      'Köpek rüyada sadakat, arkadaşlık ve güvenilir bağları simgeler. Sevecen bir köpek görüyorsan, hayatında sana koşulsuz destek veren biri var ya da böyle birini arıyorsun. Saldırgan bir köpek, güvendiğin birine dair endişe ya da ihanetle ilgili bir uyarıdır. Kayıp bir köpeği arıyorsan, bir dostluğun ya da bağlılığın kaybından duyduğun üzüntüyü simgeler.',
      'Dog',
      'A dog in a dream symbolizes loyalty, friendship and trustworthy bonds. If you see an affectionate dog, there is someone in your life who gives you unconditional support, or you are seeking such a person. An aggressive dog is a warning about worry or betrayal regarding someone you trust. If you are searching for a lost dog, it symbolizes the sorrow you feel from the loss of a friendship or attachment.'),
  _Sembol('Köprü',
      'Köprü rüyada bir dönemden diğerine geçişi ve iki dünya arasındaki bağı temsil eder. Köprüyü geçiyorsan, hayatının yeni bir evresine adım atmak üzeresin. Köprü yıkılıyorsa, geri dönüşü olmayan bir karar vermek zorunda olduğunu bilinçaltın söylüyor. Köprüde duraksıyorsan, önemli bir seçimin eşiğindesin ve daha fazla zaman gerekiyor.',
      'Bridge',
      'A bridge in a dream represents the passage from one period to another and the bond between two worlds. If you are crossing the bridge, you are about to step into a new phase of your life. If the bridge is collapsing, your subconscious is telling you that you must make an irreversible decision. If you are pausing on the bridge, you are at the threshold of an important choice and need more time.'),
  _Sembol('Kurt',
      'Kurt rüyada içgüdü, sürü dinamiği ve bilinmezin korkusunu simgeler. Yalnız bir kurt görüyorsan, bağımsız ve güçlü yönünün öne çıktığı ya da yalnız kalma korkusunu yaşadığın bir dönemdesin. Sürüyle birlikte koşan kurtlar, grup aidiyeti ve ortak hedeflerin önemini ön plana çıkarır. Kurt sana saldırıyorsa, hayatındaki vahşi ve kontrol edilmesi gereken bir güçle yüzleşme vakti gelmiş.',
      'Wolf',
      'A wolf in a dream symbolizes instinct, pack dynamics and the fear of the unknown. If you see a lone wolf, you are in a period where your independent and strong side comes forward, or where you experience the fear of being alone. Wolves running together as a pack bring the importance of group belonging and shared goals to the fore. If a wolf attacks you, the time has come to face a wild force in your life that needs to be controlled.'),
  _Sembol('Kuş',
      'Kuş rüyada özgürlük, umut ve ruhani yükselişi simgeler. Uçan kuşlar, hayallerini ve umutlarını simgeler — ne kadar yüksek uçuyorlarsa o kadar yüksek hedeflerin var. Ölü bir kuş, umutların ya da planların sekteye uğramasını simgeler. Kuş cıvıltısı duyuyorsan, hayatına yeni bir neşe kaynağı girecek.'),
  _Sembol('Kuyu',
      'Kuyu rüyada bilinçaltının derinliklerine ve gizli gerçeklere açılan bir penceredir. Kuyuya bakıyorsan, içinde yanıt aradığın derin sorular var. Kuyuya düşüyorsan, kontrolün dışındaki duygulara ya da durumun içine sürükleniyorsun. Kuyudan su çıkarıyorsan, bilinçaltından değerli içgörüler ve bilgelik çekip çıkarıyorsun.'),
  _Sembol('Lamba',
      'Lamba rüyada bilgi, anlayış ve karanlıkta rehberliği simgeler. Yanan bir lamba, seni içinde bulunduğun belirsizlikten kurtaracak bir anlayışın yaklaştığını gösterir. Sönen bir lamba, motivasyon ya da netlik kaybını simgeler. Lambayı sen yakıyorsan, kendi içsel bilgeliğine güvenmeye başlıyorsun.'),
  _Sembol('Mağara',
      'Mağara rüyada içe çekilme, korunma ve bilinçaltının sırlarını simgeler. Mağaraya giriyorsan, yalnızlık ve sessizliğe ihtiyaç duyduğun, kendine dönmek istediğin bir dönemdesin. Mağaranın içinde kayıpsan, öz keşif yolculuğunun ortasındasın. Mağaradan çıkıyorsan, uzun bir içe dönme döneminin ardından dünyayla yeniden bağ kurmaya hazırsın.'),
  _Sembol('Mektup',
      'Mektup rüyada iletişim, beklenen haberler ve söylenmemiş sözleri simgeler. Mektup alıyorsan, uzun süredir beklediğin bir haber ya da cevap yakın. Mektup yazmak ama gönderememek, içinde tuttuğun duygular ya da sözler için bir çıkış yolu aradığını gösterir. Açılmamış bir mektup ise hayatında henüz kabul etmediğin ya da yüzleşmediğin bir gerçeğe işaret eder.'),
  _Sembol('Melek',
      'Melek rüyada ilahi rehberlik, koruma ve sevginin simgesidir. Melek seninle konuşuyorsa, bilinçaltının sana önemli bir mesaj iletmek istediğini gösterir — bu mesajı hatırlamaya çalış. Seni koruyan bir melek görüyorsan, güvende olduğunu ve görünmez desteklerin olduğunu hissediyorsun. Bu rüya, pes etmemen gerektiğinin güçlü bir işareti.'),
  _Sembol('Merdiven',
      'Merdiven rüyada ilerleme, yükselme ya da alçalma sürecinin simgesidir. Merdivenlerden çıkıyorsan, hedeflerine adım adım yaklaşıyorsun ve yönün doğru. İniyorsan, geri adım atman ya da mütevazı olman gereken bir ders var. Merdivenin kırık ya da kaygan olması, yolculuğunda engeller ve dikkat gerektiren noktalar olduğunu hatırlatır.'),
  _Sembol('Mezar',
      'Mezar rüyada kapanan dönemleri, geçmişi bırakmayı ve anıları simgeler. Kendi mezarını görüyorsan, eski bir versiyonunun artık geride kaldığını; büyük bir dönüşüm geçirdiğini gösterir. Tanıdık birinin mezarında duruyorsan, o kişiyle bitmemiş işlerin ya da söylenmemiş sözlerin var. Bu rüya, yas tutmana ve bırakmana izin veriyor.'),
  _Sembol('Mum',
      'Mum rüyada umut, anma ve karanlıkta titreyen güçlü ışığı simgeler. Yanan bir mum görüyorsan, içinde taşıdığın umut ve inancın seni yönlendirdiğini gösterir. Mumu sen yakıyorsan, karanlık bir dönemde bile ilerleme kararlılığına sahipsin. Mum sönüyorsa, bir şeyin ya da birinin artık hayatında yer tutamayacağını kabullenmek için içsel bir süreç başlıyor.'),
  _Sembol('Müzik',
      'Müzik rüyada duygusal uyumu, yaratıcılığı ve iletişimi simgeler. Güzel müzik duyuyorsan, iç dünyanın zenginleştiğini ve bir harmoni arayışında olduğunu gösterir. Kulağını tırmalayan sesler, çevrendeki bir uyumsuzluğa dikkat etmen gerektiğini söyler. Sen müzik yapıyorsan, ifade etmek istediğin ve dışa vurmayı beklediğin güçlü duygular var.'),
  _Sembol('Nazar',
      'Nazar rüyada kıskançlık, kötü niyet ve dışarıdan gelen olumsuz enerjileri simgeler. Nazar değdiğini hissediyorsan, başkalarının bakışları ya da düşünceleri seni fazlasıyla etkiliyor. Nazarlık takıyorsan ya da sana veriliyorsa, korunma ihtiyacı ve güvende olma arzusu içindesin. Bu rüya, enerji sınırlarını güçlendirmen gerektiğini hatırlatıyor.'),
  _Sembol('Nehir',
      'Nehir rüyada zamanın akışını, değişimi ve hayatın doğal seyrini simgeler. Sakin ve berrak bir nehir, hayatının rahat bir ritme oturduğunu gösterir. Çalkantılı ve çamurlu bir nehir, kontrolünü yitirme ve değişime direniş hissini simgeler. Nehri geçiyorsan, önemli bir karar ya da geçiş sürecindeki kararlılığını gösterir.'),
  _Sembol('Nişan',
      'Nişan rüyada bağlılık, söz ve iki kişinin ya da fikrin birleşmesini simgeler. Nişanlanıyorsan, ilişkinde ya da hayatında bir taahhüt aşamasına hazır olduğunun işareti. Nişanın bozulduğunu görüyorsan, bir taahhüt ya da söz hakkında endişe ve kararsızlık içindesin. Bu rüya, kalbindeki gerçek bağlılığı sorgulamana davet ediyor.'),
  _Sembol('Okul',
      'Okul rüyada öğrenme, sınav kaygısı ve geçmişteki anıların yansımasıdır. Sınav için hazırlıksız hissediyorsan, hayatında bir duruma hazır olmadığını ya da değerlendirilme korkusu taşıdığını gösterir. Eski okulunu görüyorsan, geçmişten bir dersi ya da kişiyi hatırlaman gerekiyor. Öğretmen olarak ders veriyorsan, paylaşmak istediğin değerli bilgi ve deneyimlerin var.'),
  _Sembol('Orman',
      'Orman rüyada bilinçaltının karmaşık labirenti ve içindeki vahşi doğayı simgeler. Kayboluyorsan, hayatında yönünü kaybetmiş ve rehberliğe muhtaç hissediyorsun. Ormanda rahatça yürüyorsan, karmaşıklıkla barışıksın ve kendi güçlü sezgilerine güveniyorsun. Ormandan çıkıyorsan, kafanda ya da hayatındaki karmaşanın bir netliğe kavuşacağını müjdeler.'),
  _Sembol('Oyun',
      'Rüyada oyun oynamak, hayatın eğlenceli yönlerine duyduğun özlemi ve özgür ruhunu simgeler. Çocukluk oyunları görüyorsan, kaygısız ve yaratıcı bir dönemi özlüyorsun. Yarışma ya da kaybetme korkusu içeren bir oyun, gerçek hayatta başarma ve değerini kanıtlama baskısını yansıtır. Oyunun keyfini çıkarıyorsan, hayatındaki hafifliği ve neşeyi daha çok beslemeni söylüyor.'),
  _Sembol('Ölüm',
      'Rüyada ölüm görmek, gerçek bir ölümü değil büyük bir dönüşümü müjdeler. Kendi ölümünü görüyorsan, eski alışkanlıkların, inançlarının ya da hayat döneminin kapanmakta olduğunu simgeler. Sevdiğin birinin ölümünü görüyorsan, bu kişiyle ilişkinde ya da o kişiyi temsil eden bir yanda büyük bir değişim var. Bu rüya, bırakma ve yeniden doğma sürecinin habercisidir.'),
  _Sembol('Öpücük',
      'Öpücük rüyada sevgi, onay ve bağlanma isteğini simgeler. Sevdiğinden öpücük alıyorsan, bu ilişkide sevgi ve onay ihtiyacın var ya da karşılıklı sevginin tescillenmesini diliyorsun. Yabancıdan öpücük alıyorsan, hayatına beklenmedik bir sevgi ya da onay gelecek. Birini öpüyorsan, ilişkilerinde daha açık ve ifade edici olmak istiyorsun.'),
  _Sembol('Para',
      'Para rüyada güç, değer ve güvenlik ihtiyacını simgeler. Para buluyorsan, beklenmedik fırsatlar ve maddi ya da duygusal kazanımlar kapıda. Para kaybediyorsan, güvensizlik hissi ve kaybetme korkusu içindesin. Birlerine para veriyorsan, cömertliğin mi yoksa kullanılma korkun mu daha baskın, bunu düşünme zamanı.'),
  _Sembol('Pencere',
      'Pencere rüyada dış dünyaya bakış açını ve gelecek olanaklarını simgeler. Açık bir pencereden uzağa bakıyorsan, yeni fırsatlar ve özgürlük seni çağırıyor. Kırık ya da kapalı pencere, kendini sınırladığını ya da hayatın güzelliklerine kapalı kaldığını gösterir. Bir pencereden içeriye bakıyorsan, başkalarının hayatını gözlemlemek yerine kendi hayatına odaklanma vakti.'),
  _Sembol('Rüzgar',
      'Rüzgar rüyada değişim, özgürlük ve görünmez güçleri simgeler. Sert bir fırtına rüzgarı, kontrolün dışındaki büyük değişimleri haber verir. Hafif ve tatlı bir esinti ise içinde bulunduğun sürecin doğal ve güzel olduğunu söyler. Rüzgarın seni taşıdığını hissediyorsan, akışa bırakma zamanı — direnme ve olayların seni yönlendirmesine izin ver.'),
  _Sembol('Saç',
      'Saç rüyada güç, kimlik ve toplumsal imajı simgeler. Uzun ve güzel saçlar, özgüven ve cazibeyi; dökülen saçlar ise kimlik kaygısı ya da kontrolünü yitirme hissini yansıtır. Saçını kesiyorsan, eski bir şeyi bırakmaya ve yenilenmek istediğine hazır olduğuna işaret eder. Saçın karışık ve düzensizse, zihinsel ve duygusal yorgunluk birikmekte.'),
  _Sembol('Sarmaşık',
      'Sarmaşık rüyada hem güzelliği hem de boğucu bağımlılığı simgeler. Seni saran sarmaşıklar, bağımlılık yaratan ya da seni kısıtlayan ilişkileri temsil eder. Sarmaşığı koparıyorsan, sağlıksız bir bağdan kurtulma cesaretini toplamakta olduğunu gösterir. Bir duvarı süsleyen sarmaşık, eskiye duyulan bağlılık ve köklerin gücünü simgeler.'),
  _Sembol('Savaş',
      'Savaş rüyada iç çatışma, dışsal mücadele ve direniş gerektiren durumları simgeler. Savaşın içindeysen, hayatında büyük bir güçle ya da kendi içindeki çelişkiyle mücadele ediyorsun. Savaşı uzaktan izliyorsan, başkalarının çatışması seni de etkiliyor ama sen doğrudan içinde değilsin. Zafer kazanıyorsan, uzun süredir devam eden bir mücadelede galip gelme yakın.'),
  _Sembol('Sel',
      'Sel rüyada kontrolsüz duyguların taşması ve üstesinden gelmenin zor olduğu durumları simgeler. Selin içinde sürükleniyorsan, duygular ya da olaylar seni boğuyor ve yön bulamıyorsun. Yüksek bir yerde sel baskınından kaçıyorsan, güvenli bir mesafe koyma içgüdüsün çalışıyor. Sel çekildikten sonra yıkımı görüyorsan, bir temizlenme ve yeniden inşa sürecinin başladığını simgeler.'),
  _Sembol('Su',
      'Su rüyada duygusal dünyayı ve hayatın akışını simgeleyen en temel unsurlardan biridir. Berrak ve tatlı su içmek, enerji, iyileşme ve berraklığı müjdeler. Kirli ya da acı su, duygusal zehirlenmeden arınma ihtiyacını gösterir. Suyun üzerinde yürüyorsan, duyguların üzerinde kontrol ve güç sahibi olmak istiyorsun.'),
  _Sembol('Şehir',
      'Şehir rüyada sosyal yaşamı, kalabalığı ve dış dünyanın karmaşasını simgeler. Tanıdık ama değişmiş bir şehir, beklentilerle gerçeklik arasındaki farkı yansıtır. Kaybolduğun büyük bir şehir, toplumsal baskı ve aitlik arayışını gösterir. Güzel ve aydınlık bir şehir ise sosyal bağlantılarında verimli ve neşeli bir dönemin habercisidir.'),
  _Sembol('Şelale',
      'Şelale rüyada özgürce akan duygular, temizlenme ve yenilenmeyi simgeler. Şelale altında durmak, derin bir arınma ve yenilenme ihtiyacını gösterir. Uzaktan şelaleyi izlemek, güzelliği ve özgürlüğü istiyorsun ama henüz ulaşamıyorsun. Şelale suyunda yüzmek, duygusal dürüstlük ve kendinle barışık olma sürecindeki güçlü bir adımdır.'),
  _Sembol('Şimşek',
      'Şimşek rüyada ani aydınlanma, öngörülemeyen değişim ve güçlü enerjinin işareti. Şimşekten korkuyorsan, hayatındaki ani değişimler seni tedirgin ediyor. Ama şimşeği izleyip büyüleniyorsan, yaratıcı güç ve içgörü momentlerin artıyor. Şimşeğin seni aydınlattığını hissediyorsan, uzun süredir yanıt aradığın bir sorunun cevabı parlayacak.'),
  _Sembol('Taş',
      'Taş rüyada dayanıklılık, ağırlık ya da hareketsizliği simgeler. Ağır bir taş taşıyorsan, içinden atamadığın bir yük ya da sorumluluk omuzlarında. Taşa dönüştüğünü hissediyorsan, duygusal olarak donuklaştığını ya da hayatında çok katı olmaya başladığını gösterir. Güzel bir taş buluyorsan, hayatının zorluklarından çıkardığın değerli dersler ve güç var.'),
  _Sembol('Tren',
      'Tren rüyada hayatın ritmi, hedefe yönelik ilerleme ve kaçırılan fırsatları simgeler. Treni kaçırıyorsan, bir fırsatı gözden kaçırma ya da geç kalma endişesi içindesin. Trenin içindeysen ve hızla gidiyorsan, hayatın güçlü bir ivme kazandı ve olaylar seni sürüklüyor. Treni seyrediyorsan, başkalarının ilerlediğini ama senin duraksadığını hissediyorsun.'),
  _Sembol('Tünel',
      'Tünel rüyada karanlık bir dönemden geçişi ve ışığa ulaşma umudunu simgeler. Tünelin içinde yürüyorsan, zorlu bir sürecin tam ortasındasın ama sonunda ışık var. Tünelin sonundaki ışığı görüyorsan, yakında mevcut zorluklardan çıkış kapısına ulaşacaksın. Tünelde kayboluyorsan, belirsizlik ve çıkış yolu bulamama hissi çok baskın.'),
  _Sembol('Uçmak',
      'Uçmak rüyada özgürlük, sınırları aşma ve olasılıkların sonsuzluğunu simgeleyen en güzel deneyimlerden biridir. Kollarınla uçuyorsan, hiç kimseden yardım almadan kendi gücünle yükseleceğini gösterir. Uçarken korkuyorsan, özgürlük ve yükselme arzun var ama bir şeyler seni geri tutuyor. Uçarken alçalıyorsan, motivasyon ya da özgüven kaybı yaşıyorsun — ama yeniden uçabilirsin.'),
  _Sembol('Uçurum',
      'Uçurum rüyada büyük riskler, sınırlar ve sonsuz olasılıkların kenarında durmayı simgeler. Uçurumun kenarında duruyorsan, büyük bir karar ya da risk eşiğindesin. Uçuruma atlıyorsan, sonucu belirsiz ama dönüşüm getirecek büyük bir adımı atmaya hazırsın. Uçuruma düşüyorsan, kontrolünü yitirme korkusu ve ayaklarının altındaki zeminin sarsılması hissini simgeler.'),
  _Sembol('Üzüm',
      'Üzüm rüyada bereket, keyif ve emeklerinin meyvelerini toplama zamanını simgeler. Taze ve olgun üzüm toplamak, uzun çabanın karşılığını görmek üzere olduğunun müjdesidir. Koruk üzüm ise henüz olgunlaşmamış bir projenin ya da ilişkinin erken sonuçlanmasına dair uyarıdır. Üzüm yiyorsan, hayatın küçük zevklerini takdir etme ve şimdinin tadını çıkarma zamanı.'),
  _Sembol('Volkan',
      'Volkan rüyada uzun süredir bastırılan duyguların ve enerjinin patlamaya hazır olduğunu simgeler. Volkan patlarken izliyorsan, çevrende ya da içinde büyük ve kontrol edilemez bir güç devrede. Lavların sana doğru aktığını görüyorsan, başkalarının öfkesi ya da tutkusu seni tehdit ediyor. Volkanın zirvesinde duruyorsan, büyük bir güç ve enerji kaynağının tam üstündesin.'),
  _Sembol('Yıldız',
      'Yıldız rüyada umut, ilham ve büyük hayaller kurmayı simgeler. Parlayan yıldızlar, içindeki potansiyeli ve yaşam enerjisini temsil eder. Kayan yıldız görüp dilek diliyorsan, bilinçaltın sana hayallerine inanmayı hatırlatıyor. Yıldızların söndüğünü görüyorsan, bir ideal ya da hayalin gerçekçi olmadığını kabullenme sürecindeyken gösterir.'),
  _Sembol('Yılan',
      'Yılan rüyada dönüşüm, iyileşme ve bilinçaltının güçlü mesajlarından biridir. Sana saldıran bir yılan, hayatındaki manipülatif ya da zehirli bir ilişkiyi ya da korkuyu temsil eder. Barışık ya da zararsız bir yılan görüyorsan, büyük bir dönüşüm ve yenilenme sürecinin başındası. Yılan derisini değiştiriyorsa, senin de eski kalıplarından soyunup yenilenmekte olduğunu simgeler.'),
  _Sembol('Yolculuk',
      'Yolculuk rüyada hayat sürecini ve hedeflerine giden yoldaki adımlarını simgeler. Uzun bir yolda yürüyorsan, büyük bir amaca adım adım yürüdüğünü ve sürecin kendisinin değerli olduğunu gösterir. Yolunu kaybediyorsan, hayatında yön belirlemekte zorlandığın, kafanın karıştığı bir dönemdesin. Yolculuğun sonuna ulaşıyorsan, önemli bir döngüyü tamamlamak üzeresin.'),
  _Sembol('Yük',
      'Yük rüyada taşıdığın sorumlulukları, stresin ve başkasından aldığın ya da üstüne aldığın ağırlıkları simgeler. Çok ağır bir yük taşıyorsan, üstüne yığılan sorumluluklar seni eziyor. Yükü bırakıyorsan, uzun süredir taşıdığın bir sorumluluğu ya da kaygıyı bırakmaya hazır olduğunu gösterir. Yükü taşımana yardım eden biri varsa, hayatında gerçek destek ve dayanışma mevcut.'),
  _Sembol('Yüz',
      'Yüz rüyada kimlik, başkalarıyla ilişki ve toplumsal maske takmayı simgeler. Tanıdık bir yüz görüyorsan, o kişiyle bilinçaltında devam eden güçlü bir bağ ya da çözülmemiş duygular var. Yüzünün değiştiğini görüyorsan, kim olduğun ya da nasıl göründüğün konusunda derin bir sorgulamadasın. Güzel ve parlak bir yüz görmek ise öz saygı ve sevginin artmakta olduğunun habercisidir.'),
  _Sembol('Yüzmek',
      'Yüzmek rüyada duygularla başa çıkma ve hayatın içinde kendini taşıma becerisini simgeler. Berrak suda kolayca yüzüyorsan, duygusal açıdan sağlıklı ve özgürsün. Boğuluyorsan ya da yorgunluktan batıyorsan, duygusal yük ve stres seni bunaltıyor, yardım alma zamanı. Derin suda yüzüyorsan, karmaşık duygularla cesurca yüzleşiyorsun.'),
  _Sembol('Zincir',
      'Zincir rüyada kısıtlama, bağımlılık ve özgürlüğün önündeki engelleri simgeler. Zincire bağlıysan, bir ilişki, alışkanlık ya da durumun seni sınırladığını hissediyorsun. Zinciri kırıyorsan, uzun süre boyunca seni tutan bir şeyden kurtuluşun yakın olduğunun işareti. Başkasını zincirliyorsan, kontrol etme ya da tutma ihtiyacı üzerine dürüstçe düşünme vakti.'),
  _Sembol('Zombi',
      'Zombi rüyada duygusal uyuşukluk, mekanik yaşama ve hayatta olup olmadığını sorgulamayı simgeler. Zombilerden kaçıyorsan, bilinçsizce sürüklenen kalabalığın seni etkilemesinden ya da içine çekmesinden korkuyorsun. Kendinin zombi olduğunu hissediyorsan, hayatına gerçek anlam ve coşku katma vakti geldi. Bu rüya, sana "gerçekten yaşıyor musun?" sorusunu sormaktadır.'),
];

// ── Ekran adımları ────────────────────────────────────────────────────────────
enum _RYAdim { secim, analiz }

class RuyaYorumuScreen extends ConsumerStatefulWidget {
  const RuyaYorumuScreen({super.key});

  @override
  ConsumerState<RuyaYorumuScreen> createState() => _RuyaYorumuScreenState();
}

class _RuyaYorumuScreenState extends ConsumerState<RuyaYorumuScreen> {
  _RYAdim  _adim        = _RYAdim.secim;
  _Sembol? _secili;
  String   _arama       = '';

  final _aramaCtrl = TextEditingController();

  static const _uuid = Uuid();

  List<_Sembol> get _filtrelenmis {
    if (_arama.isEmpty) return _semboller;
    final q = _arama.toLowerCase();
    return _semboller
        .where((s) =>
            s.kelime.toLowerCase().contains(q) ||
            s.kelimeEn.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _tamam() async {
    if (_secili == null) return;
    setState(() => _adim = _RYAdim.analiz);

    final sembol  = _secili!;
    final isEn    = ref.read(localeProvider) == 'en';
    final profile = ref.read(userProfileProvider);
    final vars    = profile.toVariableMap();
    final metin   = VariableReplacer.replace(sembol.yorumFor(isEn), vars);

    // Inbox'a 4 dakika kilitli kaydet
    final now     = DateTime.now();
    final unlock  = now.add(const Duration(minutes: 4));
    final item = InboxItem(
      id: _uuid.v4(),
      title: ref.read(l10nProvider).dreamInboxTitle(sembol.kelimeFor(isEn)),
      text: metin,
      date: now.toIso8601String(),
      fortuneTypeKey: 'dream',
      unlockAt: unlock.toIso8601String(),
    );
    await ref.read(inboxProvider.notifier).addItem(item);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    ref.read(ruyaSentProvider.notifier).state = true;
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/dream_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF060912)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x44000000),
                  Color(0x99000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    ref.watch(l10nProvider).dreamTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: switch (_adim) {
                _RYAdim.secim  => _buildSecim(),
                _RYAdim.analiz => _buildAnaliz(),
              },
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Durum: secim ─────────────────────────────────────────────────────────
  Widget _buildSecim() {
    final s = ref.watch(l10nProvider);
    final profile = ref.read(userProfileProvider);
    final isim = profile.name.isNotEmpty ? profile.name : (s.isEn ? 'you' : 'sen');
    final liste = _filtrelenmis;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Text(
            s.dreamWhatDidYouSee(isim),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD8C4FF),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        // ── Arama kutusu ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _aramaCtrl,
            onChanged: (v) => setState(() => _arama = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFF8B5CF6),
            decoration: InputDecoration(
              hintText: s.searchHint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.45), size: 20),
              suffixIcon: _arama.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _aramaCtrl.clear();
                        setState(() => _arama = '');
                      },
                      child: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.45), size: 18),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0x800D0A1E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── Sembol listesi ─────────────────────────────────────────────────
        Expanded(
          child: liste.isEmpty
              ? Center(
                  child: Text(
                    s.noResults,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liste.length,
                  itemBuilder: (ctx, i) {
                    final sembol = liste[i];
                    final secili = _secili == sembol;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _secili = secili ? null : sembol),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: secili
                              ? const Color(0xFF6D28D9).withValues(alpha: 0.35)
                              : const Color(0x800D0A1E),
                          border: Border.all(
                            color: secili
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withValues(alpha: 0.08),
                            width: secili ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sembol.kelimeFor(s.isEn),
                                style: TextStyle(
                                  color: secili
                                      ? const Color(0xFFDDD6FE)
                                      : Colors.white.withValues(alpha: 0.85),
                                  fontSize: 15,
                                  fontWeight: secili
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (secili)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF8B5CF6), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // ── Geri Git / Yorumla butonu ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: GestureDetector(
            onTap: _secili != null ? _tamam : () => context.pop(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                gradient: _secili != null
                    ? const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)])
                    : null,
                color: _secili == null
                    ? Colors.white.withValues(alpha: 0.10)
                    : null,
                border: Border.all(
                  color: _secili == null
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Center(
                child: _secili != null
                    ? Text(
                        ref.read(l10nProvider).interpret,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 2),
                          Text(
                            ref.read(l10nProvider).backButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Durum: analiz ─────────────────────────────────────────────────────────
  Widget _buildAnaliz() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          ref.read(l10nProvider).dreamEvaluating,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 32),
        const ElegantHourglass(size: 56, color: Colors.white),
      ],
    );
  }

}

