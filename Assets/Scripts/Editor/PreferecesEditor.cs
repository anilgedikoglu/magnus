using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.IO;
using System.Net;
using System;
using System.Text;
using UnityEditor.Callbacks;
using TMPro;

[CustomEditor(typeof(PreferencesObject)), CanEditMultipleObjects]
public class PreferecesEditor : Editor
{
    public string sohbetToFind;
    public UnityEngine.Object sohbetSearchResult;

    bool ozelGunSohbetOlusturDropDown;
    string ozelGunlerModu = "hoşgeldin";

    bool customContentPhotoIdsDropDown;

    int ayarlanacakOturumSayisi;

    //string degisecekMetin;

    void OnEnable()
    {
        
    }

    private void OnDisable()
    {
        if (target != null)
        {
            PreferencesObject targetObject = (PreferencesObject)target;
            EditorUtility.SetDirty(targetObject);
        }
    }

    public override void OnInspectorGUI()
    {
        PreferencesObject targetObject = (PreferencesObject)target;

        /*
        degisecekMetin = EditorGUILayout.TextArea(degisecekMetin);
        Sohbet[] sohbets1 = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/Astroloji/Uyum/UyumDosyalarEvli");
        Sohbet[] sohbets2 = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/Astroloji/Uyum/UyumDosyalariliskisivar");
        Sohbet[] sohbets3 = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/Astroloji/Uyum/UyumDosyalariliskisiyok");
        if (GUILayout.Button("MetinleriDegis"))
        {

            foreach (Sohbet sohbet in sohbets1)
            {
                //sohbet.aciklama[0] = sohbet.aciklama[0].Replace("\"", "\\" + "\"");
                sohbet.aciklama[0] = degisecekMetin.Replace("degisBunu", sohbet.aciklama[0]);

                EditorUtility.SetDirty(sohbet);
            }

            foreach (Sohbet sohbet in sohbets2)
            {
                //sohbet.aciklama[0] = sohbet.aciklama[0].Replace("\"", "\\" + "\"");
                sohbet.aciklama[0] = degisecekMetin.Replace("degisBunu", sohbet.aciklama[0]);

                EditorUtility.SetDirty(sohbet);
            }

            foreach (Sohbet sohbet in sohbets3)
            {
                //sohbet.aciklama[0] = sohbet.aciklama[0].Replace("\"", "\\" + "\"");
                sohbet.aciklama[0] = degisecekMetin.Replace("degisBunu", sohbet.aciklama[0]);

                EditorUtility.SetDirty(sohbet);
            }
        }*/

        #region junk
        //Asagikdaki kodlar tarot fotograflarina gore tarot sohbetlerinin ozel fonksiyon ve gereken degiskenlerini olusturan kodlardir. Ilerleyen zamanlarda
        //tarotSettingse customEditor yazilirsa oraya alinabilir.

        /*
         
                 if (GUILayout.Button("Degiskenleri esitle"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/FAL/WheelFal/1 Alev");

            for (int i = 0; i < tumSohbetler.Length; i++)
            {
                tumSohbetler[i].gerekenDegiskenler.Add(new ChatDegiskeni("mod", "wheelspin fal alev"));
                tumSohbetler[i].gerekenDegiskenler.Add(new ChatDegiskeni("wheel mod", "fal"));
                EditorUtility.SetDirty(tumSohbetler[i]);
            }
        }
        
        
                if (GUILayout.Button("Degiskenleri esitle"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/FAL/WheelFal/1 Alev");
            Sohbet[] tumSohbetler2 = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/FAL/WheelFal/2 Alev");

            for (int i = 0; i < tumSohbetler.Length; i++)
            {
                tumSohbetler[i].gerekenDegiskenler = tumSohbetler2[i].gerekenDegiskenler;
                EditorUtility.SetDirty(tumSohbetler[i]);
            }
        }

        
        if(GUILayout.Button("Tum sohbetlerin id sifirla"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani");

            foreach(Sohbet sohbet in tumSohbetler)
            {
                sohbet.idIndex = "-1";
                EditorUtility.SetDirty(sohbet);
            }
        }
        if (GUILayout.Button("Ayarla geçmiş"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/FAL/Tarot/TarGecmis");
            TarotSettings tarotSettings = Resources.Load<TarotSettings>("SohbetVeriTabani/tarotSettings");

            tarotSettings.tarotGecmisModlari = new List<TarotSettings.TarotCardMod>();
            foreach(Sohbet sohbet in tumSohbetler)
            {
                sohbet.ozelFonksiyon = "tarot geçmiş sohbeti başlat";
                sohbet.ayarlanacakDegiskenler = new List<ChatDegiskeni>();
                sohbet.gerekenDegiskenler = new List<ChatDegiskeni>() { new ChatDegiskeni("mod", "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower()) };
                sohbet.aciklamaBalonuYok = true;
                sohbet.sohbetBititmindeAnamenuyeDon = false;
                sohbet.anaMenuyeGitButonuOlustur= false;
                tarotSettings.tarotGecmisModlari.Add(new TarotSettings.TarotCardMod());
                tarotSettings.tarotGecmisModlari[tarotSettings.tarotGecmisModlari.Count - 1].mod = sohbet.gerekenDegiskenler[0].degiskenDegeri;
                EditorUtility.SetDirty(sohbet);
            }
            EditorUtility.SetDirty(tarotSettings);
        }

        if (GUILayout.Button("Ayarla şmidi"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/FAL/Tarot/TarSimdi");
            TarotSettings tarotSettings = Resources.Load<TarotSettings>("SohbetVeriTabani/tarotSettings");

            tarotSettings.tarotSimdiModlari = new List<TarotSettings.TarotCardMod>();
            foreach (Sohbet sohbet in tumSohbetler)
            {
                sohbet.ozelFonksiyon = "tarot şimdi sohbeti başlat";
                sohbet.ayarlanacakDegiskenler = new List<ChatDegiskeni>();
                sohbet.gerekenDegiskenler = new List<ChatDegiskeni>() { new ChatDegiskeni("mod", "tarot simdi " + sohbet.contentPhotoId.Replace("-", " ").ToLower()) };
                sohbet.aciklamaBalonuYok = true;
                sohbet.sohbetBititmindeAnamenuyeDon = false;
                sohbet.anaMenuyeGitButonuOlustur = false;
                tarotSettings.tarotSimdiModlari.Add(new TarotSettings.TarotCardMod());
                tarotSettings.tarotSimdiModlari[tarotSettings.tarotSimdiModlari.Count - 1].mod = sohbet.gerekenDegiskenler[0].degiskenDegeri;

                if (!("tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower()).Contains(" ters"))
                {
                    tarotSettings.tarotSimdiModlari[tarotSettings.tarotSimdiModlari.Count - 1].excludedMods = new List<string>() { "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower(), "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower() + " ters" };
                }
                else
                {
                    tarotSettings.tarotSimdiModlari[tarotSettings.tarotSimdiModlari.Count - 1].excludedMods = new List<string>() { "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower(), ("tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower()).Replace(" ters", "") };
                }
                EditorUtility.SetDirty(sohbet);
            }
            EditorUtility.SetDirty(tarotSettings);
        }

        if (GUILayout.Button("Ayarla gelecek"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani/Version1/FAL/Tarot/TarGelecek");
            TarotSettings tarotSettings = Resources.Load<TarotSettings>("SohbetVeriTabani/tarotSettings");

            tarotSettings.tarotGelecekModlari = new List<TarotSettings.TarotCardMod>();
            foreach (Sohbet sohbet in tumSohbetler)
            {
                sohbet.ozelFonksiyon = "tarot gelecek sohbeti başlat";
                sohbet.ayarlanacakDegiskenler = new List<ChatDegiskeni>();
                sohbet.gerekenDegiskenler = new List<ChatDegiskeni>() { new ChatDegiskeni("mod", "tarot gelecek " + sohbet.contentPhotoId.Replace("-", " ").ToLower()) };
                sohbet.aciklamaBalonuYok = true;
                sohbet.sohbetBititmindeAnamenuyeDon = false;
                sohbet.anaMenuyeGitButonuOlustur = false;
                tarotSettings.tarotGelecekModlari.Add(new TarotSettings.TarotCardMod());
                tarotSettings.tarotGelecekModlari[tarotSettings.tarotGelecekModlari.Count - 1].mod = sohbet.gerekenDegiskenler[0].degiskenDegeri;

                if (!("tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower()).Contains(" ters"))
                {
                    tarotSettings.tarotGelecekModlari[tarotSettings.tarotGelecekModlari.Count - 1].excludedMods = new List<string>() { "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower(), "tarot simdi " + sohbet.contentPhotoId.Replace("-", " ").ToLower(),
                        "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower() + " ters", "tarot simdi " + sohbet.contentPhotoId.Replace("-", " ").ToLower() + " ters" };
                }
                else
                {
                    tarotSettings.tarotGelecekModlari[tarotSettings.tarotGelecekModlari.Count - 1].excludedMods = new List<string>() { "tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower(), "tarot simdi " + sohbet.contentPhotoId.Replace("-", " ").ToLower(),
                        ("tarot gecmis " + sohbet.contentPhotoId.Replace("-", " ").ToLower()).Replace(" ters", ""), ("tarot simdi " + sohbet.contentPhotoId.Replace("-", " ").ToLower()).Replace(" ters", "") };
                }

                EditorUtility.SetDirty(sohbet);
            }
            EditorUtility.SetDirty(tarotSettings);
        }*/
        #endregion

        //Emoji düzenlemesi. buradan alıncak!
        /*
        if (GUILayout.Button("emoji ayarla"))
        {
            Debug.Log(targetObject.spriteAsset.spriteCharacterTable);
            foreach (TMP_SpriteCharacter sprite in targetObject.spriteAsset.spriteCharacterTable)
            {
                sprite.scale = 1.3f;
                sprite.glyph.metrics = new UnityEngine.TextCore.GlyphMetrics(sprite.glyph.metrics.width, sprite.glyph.metrics.height, 2, 46, sprite.glyph.metrics.width + 2);
            }

            EditorUtility.SetDirty(targetObject.spriteAsset);
        }*/

        //Barli sohbet kontrol.
        /*
        Sohbet[] sohbets = Resources.LoadAll<Sohbet>("SohbetVeriTabani");
        if (GUILayout.Button("Percentile bar tara"))
        {
            foreach (Sohbet sohbet in sohbets)
            {
                if (sohbet.aciklama != null)
                {
                    if (sohbet.aciklama.Count > 0)
                    {
                        if (sohbet.aciklama[0].Contains("{{barmenu}}"))
                        {
                            string[] words = sohbet.aciklama[0].Split(new string[] { "{{barmenu}}" }, System.StringSplitOptions.None);

                            var chatVariables = FindObjectOfType<ChatVariables>();
                            for (int i = 0; i < words.Length; i++)
                            {
                                if (!string.IsNullOrEmpty(words[i]))
                                {
                                    try
                                    {
                                        
                                        var deneme = Newtonsoft.Json.JsonConvert.DeserializeObject<PercentileManager.BarData>(chatVariables.OrtakButonlar(words[i]));
                                        Debug.Log($"{AssetDatabase.GetAssetPath(sohbet)} yolundaki" +
                                              $" {sohbet.name} icin basarili\n" + words[i]);
                                    }
                                    catch(Exception ex)
                                    {
                                        Debug.LogError($"{AssetDatabase.GetAssetPath(sohbet)} yolundaki" +
                                            $" {sohbet.name} icin data json formatina cevrilemedi+\n" + words[i] + "\n\n" + ex);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/

        EditorGUILayout.LabelField("Son İçerik Düzenleme Tarihi", targetObject.sonIcerikGuncellemeTarihi);
        if (GUILayout.Button("Son içerik düzenleme tarihini güncelle", GUILayout.Height(20)))
        {
            targetObject.sonIcerikGuncellemeTarihi = System.DateTime.Now.ToString();
            EditorUtility.SetDirty(targetObject);
        }

        EditorGUILayout.HelpBox("Son İçerik Düzenlemesi " + targetObject.sonIcerikGuncellemeTarihi + " tarihinde yapıldı.", MessageType.Warning);

        if (targetObject.hosgeldinMesajlari.Length <= 0)
        {
            EditorGUILayout.HelpBox("hosgeldinMesajlari degiskeni icin icerik olusturulmadi!", MessageType.Error);
        }

        if (targetObject.konuDegisButonuMetinleri.Length <= 0)
        {
            EditorGUILayout.HelpBox("konuDegisButonuMetinleri degiskeni icin icerik olusturulmadi!", MessageType.Error);
        }

        base.OnInspectorGUI();
        EditorGUILayout.HelpBox("Ozel gunler icin tanimlanan gunler yazilan gun adi ile degisken olarak tanimlanir. Eger bugunun tarihi bu araliktaysa degiskenin degeri 'evet' olarak esitlenir. Eger esitlik saglanmazsa 'hayır' olarak esitlenir.", MessageType.Info);
        ozelGunSohbetOlusturDropDown = EditorGUILayout.BeginFoldoutHeaderGroup(ozelGunSohbetOlusturDropDown, "Özel günler sohbet oluştur");

        if (ozelGunSohbetOlusturDropDown)
        {
            ozelGunlerModu = EditorGUILayout.TextField("mod", ozelGunlerModu);
            foreach (PreferencesObject.SpecialDate specialDate in targetObject.ozelGunler)
            {
                if (GUILayout.Button(specialDate.gunAdi + " için sohbet oluştur."))
                {
                    Sohbet sohbet = CreateInstance(typeof(Sohbet)) as Sohbet;
                    sohbet.oncelik = Sohbet.SohbetOnceligi.ilk_1;

                    sohbet.aciklama = new List<string> { "" };

                    sohbet.gerekliDegiskenler =new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[3]);

                    sohbet.gerekliDegiskenler[0] = new Sohbet.GerekenDegisken();
                    sohbet.gerekliDegiskenler[0].degiskenAdi = "mod";
                    sohbet.gerekliDegiskenler[0].degiskenDegeri = ozelGunlerModu;

                    sohbet.gerekliDegiskenler[1] = new Sohbet.GerekenDegisken();
                    sohbet.gerekliDegiskenler[1].degiskenAdi = specialDate.gunAdi;
                    sohbet.gerekliDegiskenler[1].degiskenDegeri = "evet";

                    sohbet.gerekliDegiskenler[2] = new Sohbet.GerekenDegisken();
                    sohbet.gerekliDegiskenler[2].degiskenAdi = "oturum sayisi";
                    sohbet.gerekliDegiskenler[2].degiskenDegeri = "1";

                    ProjectWindowUtil.CreateAsset(sohbet, specialDate.gunAdi.Replace(" ", "").Replace("ü","u").Replace("Ü", "U").Replace("ö", "o").Replace("Ö", "O").Replace("ş", "s").Replace("Ş", "S").Replace("ı", "i").Replace("İ", "ı").Replace("ğ", "g").Replace("Ğ", "G").Replace("ç", "c").Replace("Ç", "C") + ".asset");
                }
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();


        customContentPhotoIdsDropDown = EditorGUILayout.BeginFoldoutHeaderGroup(customContentPhotoIdsDropDown, "Özel tanımlı ContentPhoto Id'leri");
        if (customContentPhotoIdsDropDown)
        {
            targetObject.wheelChartConentPhotoId = EditorGUILayout.TextField("WheelChart Id", targetObject.wheelChartConentPhotoId);
            targetObject.kullaniciPhotoId = EditorGUILayout.TextField("Kullanıcı Fotoğrafı Id", targetObject.kullaniciPhotoId);
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(20);

        EditorGUILayout.LabelField("Oturum sayısını ayarla");

        if (EditorApplication.isPlaying)
        {

                EditorGUILayout.BeginHorizontal();
                ayarlanacakOturumSayisi = EditorGUILayout.IntField(ayarlanacakOturumSayisi);
                EditorGUILayout.HelpBox($"Ayarlama işleminden sonra uygulama tekrar başltılmalıdır.", MessageType.Warning);
                if (GUILayout.Button("Ayarla", GUILayout.Height(20)))
                {

                    FindObjectOfType<CurrentPlayerData>().LoadPlayerData();
                    //Ilk giriste oturum sayisini 1 artiracagi icin istedigimzi degerin bir eksigine esitliyoruz
                    if (ayarlanacakOturumSayisi <= 1)
                    {
                        FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList("sonOturumGunu", System.DateTime.Today.AddDays(-1).ToString());
                        ayarlanacakOturumSayisi = 1;
                    }
                    else
                        FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList("sonOturumGunu", System.DateTime.Today.ToString());

                    FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList("oturum sayisi", (ayarlanacakOturumSayisi - 1).ToString());

                EditorApplication.ExitPlaymode();
                }
                EditorGUILayout.EndHorizontal();

        }
        else
        {
            EditorGUILayout.HelpBox("Oturum sayısını ayarlayabilmek için uygulamayı başlatmanız gerekli!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();
            }
        }

        EditorGUILayout.Space(10);

        sohbetToFind = EditorGUILayout.TextField("Aranacak sohbet ID :",sohbetToFind, GUILayout.Height(25));
        sohbetSearchResult = EditorGUILayout.ObjectField("Sohbet :",sohbetSearchResult, typeof(Sohbet), true);
        if (GUILayout.Button("Sohbeti Bul", GUILayout.Width(200), GUILayout.Height(25)))
        {
            sohbetSearchResult = FindSohbet(sohbetToFind);
        }

        EditorGUILayout.Space(50);
        if (GUILayout.Button("Kullanıcı Verilerini Sıfırla", GUILayout.Width(200), GUILayout.Height(25)))
        {
            SaveData.DeleteSaveFile();
        }

        /*
        if(GUILayout.Button("Sohbet Id Sifilar"))
        {
            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani");
            List<int> kullanilanIdler = new List<int>();
            for (int i =0; i<tumSohbetler.Length; i++)
            {

                if (!kullanilanIdler.Contains(tumSohbetler[i].idIndex))
                {
                    if ((tumSohbetler[i].idIndex != -1 && tumSohbetler[i].idIndex != 0))
                        kullanilanIdler.Add(tumSohbetler[i].idIndex);
                }
                else
                {
                    tumSohbetler[i].idIndex = -1;
                }
            }

            Debug.Log(kullanilanIdler.Count);
            Debug.Log(tumSohbetler.Length);
        }*/
    }

    public static Sohbet FindSohbet(string id)
    {
        Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("");
        foreach (Sohbet element in tumSohbetler)
        {
            if (element.idIndex == id)
            {
                return element;
            }
        }
        return null;
    }


    //Acilista ve kod derlemelerinden sonra son icerik guncelleme tarihini verir.
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void OnBeforeSceneLoadRuntimeMethod()
    {
        string preferencesPath = "SohbetVeriTabani/Preferences";
        Debug.Log("Son içerik güncelleme tarihi: <color=cyan><b>" + Resources.Load<PreferencesObject>(preferencesPath).sonIcerikGuncellemeTarihi + "</b></color>");
    }

    [DidReloadScripts]
    public static void OnCompileScripts()
    {
        string preferencesPath = "SohbetVeriTabani/Preferences";
        Debug.LogWarning("Son içerik güncelleme tarihi: <color=cyan><b>" + Resources.Load<PreferencesObject>(preferencesPath).sonIcerikGuncellemeTarihi+ "</b></color>");
    }
}
