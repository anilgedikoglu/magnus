using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class OzelFonksiyonManager : MonoBehaviour
{
    public List<OzelFonksiyon> ozelFonksiyonlar;

    ChatManager chatManager;

    #region OzelFonksiyonDegiskenleri

    public static string tarotMenuButonDegiskenleriAyarla = "tarot menü sohbet değişkenleri ayarla";

    #endregion

    // Start is called before the first frame update
    void Start()
    {
        chatManager = FindObjectOfType<ChatManager>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    [System.Serializable]
    public class OzelFonksiyon
    {
        public string isim;
        public UnityEvent fonksiyon;
    }

    public static void UygulamayiDegerlendir()
    {
        Application.OpenURL("https://play.google.com/store/apps/details?id=com.ardaBicen.AimTrainerMobile");
    }

    public static void UygulamayiKapat()
    {
        Application.Quit();
    }

    public static void IlkGelisTamam()
    {
        CurrentPlayerData playerDataManager = GameObject.Find("PlayerDatas").GetComponent<CurrentPlayerData>();
        playerDataManager.datas.dahaOnceGeldi = true;
        playerDataManager.SavePlayerData();
    }

    public static void BilgiEkraninaGit()
    {
        FindObjectOfType<CurrentPlayerData>().InboxOnlineUpdate(() =>
        {
            FindObjectOfType<WelcomeScreen>().SetActive(true, false);
            FindObjectOfType<ChatScreenActivity>().SetDeactive();
            FindObjectOfType<IntroManager>().SetEditWallpaperActive();
        });
    }

    public void FireWork()
    {
        Instantiate(chatManager.fireworkPrefab, chatManager.fireworkPivotTr);
    }

    public void TarotFaliAyarla()
    {
        chatManager.sohbet.aciklama = new List<string> { "" };

        foreach(Sohbet sohbet in chatManager.tarotSohbetleri)
        {
            chatManager.sohbet.aciklama[0] += sohbet.aciklama[0] + "\n\n";
        }
    }

    public void TarotMenuButonlarDegiskenleriAyarla(Sohbet sohbet)
    {
        foreach(CevapSohbet cevapSohbet in sohbet.cevaplar)
        {
            if (cevapSohbet.ayarlananDegiskenler != null)
            {
                foreach (Sohbet.AyarlanacakDegisken degisken in cevapSohbet.ayarlananDegiskenler)
                {
                    if (degisken.degiskenAdi == "tarot modu" && degisken.degiskenDegeri == "geçmiş")
                    {
                        cevapSohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("tarot modu", "geçmiş"));
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("mod", chatManager.tarotSettings.tarotGecmisModlari[Random.Range(0, chatManager.tarotSettings.tarotGecmisModlari.Count)].mod));
                        break;
                    }
                    else if (degisken.degiskenAdi == "tarot modu" && degisken.degiskenDegeri == "şimdi")
                    {
                        cevapSohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("tarot modu", "şimdi"));
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("mod", chatManager.tarotSettings.tarotSimdiModlari[Random.Range(0, chatManager.tarotSettings.tarotSimdiModlari.Count)].mod));
                        break;
                    }
                    else if (degisken.degiskenAdi == "tarot modu" && degisken.degiskenDegeri == "gelecek")
                    {
                        cevapSohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("tarot modu", "gelecek"));
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("mod", chatManager.tarotSettings.tarotGelecekModlari[Random.Range(0, chatManager.tarotSettings.tarotGelecekModlari.Count)].mod));
                        break;
                    }
                    else if (degisken.degiskenAdi == "tarot modu" && degisken.degiskenDegeri == "tümü")
                    {
                        cevapSohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("tarot modu", "tümü"));
                        string secilenMod = chatManager.tarotSettings.tarotGecmisModlari[Random.Range(0, chatManager.tarotSettings.tarotGecmisModlari.Count)].mod;
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("mod", secilenMod));
                        chatManager.tarotSettings.sonSecilenGecmisTarotKartiModu = secilenMod;
                        break;
                    }
                }
            }
        }
    }

    public void TarotGecmisBaslat()
    {
        if (chatManager.PlayerDataManager.GetChatVariableValue("tarot modu") == "geçmiş")
        {
            chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[1])
            {
                [0] = new Sohbet.AyarlanacakDegisken()
            };
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenAdi = "mod";
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenDegeri = chatManager.tarotSettings.tarotGecmisKartiSecModu;

            if (!string.IsNullOrEmpty(chatManager.sohbet.contentImage.imageId))
                chatManager.sohbet.contentImage.image =
                    FindObjectOfType<PhotoManager>().GetSprite(chatManager.sohbet.contentImage.imageId);

            chatManager.tarotSohbetleri = new List<Sohbet>
            {
                chatManager.sohbet
            };
        }
        else
        {
            chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[1])
            {
                [0] = new Sohbet.AyarlanacakDegisken()
            };
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenAdi = "mod";

            chatManager.tarotSettings.tarotSimdiModlari.Shuffle();
            foreach (TarotSettings.TarotCardMod tarotCardMod in chatManager.tarotSettings.tarotSimdiModlari)
            {
                if (!tarotCardMod.excludedMods.Contains(chatManager.tarotSettings.sonSecilenGecmisTarotKartiModu))
                {
                    chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken> { new Sohbet.AyarlanacakDegisken("mod", tarotCardMod.mod) };
                    chatManager.tarotSettings.sonSecilenSimdiTarotKartiModu = tarotCardMod.mod;
                    break;
                }
            }

            if (!string.IsNullOrEmpty(chatManager.sohbet.contentImage.imageId))
                chatManager.sohbet.contentImage.image =
                    FindObjectOfType<PhotoManager>().GetSprite(chatManager.sohbet.contentImage.imageId);

            chatManager.tarotSohbetleri = new List<Sohbet>
            {
                chatManager.sohbet
            };
        }
    }

    public void TarotSimdiBaslat()
    {
        
        if (chatManager.PlayerDataManager.GetChatVariableValue("tarot modu") == "şimdi")
        {
            chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[1])
            {
                [0] = new Sohbet.AyarlanacakDegisken()
            };
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenAdi = "mod";
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenDegeri = chatManager.tarotSettings.tarotSimdiKartiSecModu;

            if (!string.IsNullOrEmpty(chatManager.sohbet.contentImage.imageId))
                chatManager.sohbet.contentImage.image =
                    FindObjectOfType<PhotoManager>().GetSprite(chatManager.sohbet.contentImage.imageId);

            chatManager.tarotSohbetleri = new List<Sohbet>
            {
                chatManager.sohbet
            };
        }
        else
        {
            chatManager.tarotSettings.tarotGelecekModlari.Shuffle();
            foreach (TarotSettings.TarotCardMod tarotCardMod in chatManager.tarotSettings.tarotGelecekModlari)
            {
                if (!tarotCardMod.excludedMods.Contains(chatManager.tarotSettings.sonSecilenSimdiTarotKartiModu))
                {
                    chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken> {new Sohbet.AyarlanacakDegisken("mod", tarotCardMod.mod) };
                    break;
                }
            }

            if (!string.IsNullOrEmpty(chatManager.sohbet.contentImage.imageId))
                chatManager.sohbet.contentImage.image =
                    FindObjectOfType<PhotoManager>().GetSprite(chatManager.sohbet.contentImage.imageId);

            chatManager.tarotSohbetleri.Add(chatManager.sohbet);
        }
    }

    public void TarotGelecekBaslat()
    {
        if (chatManager.PlayerDataManager.GetChatVariableValue("tarot modu") == "gelecek")
        {
            chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[1])
            {
                [0] = new Sohbet.AyarlanacakDegisken()
            };
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenAdi = "mod";
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenDegeri = chatManager.tarotSettings.tarotGelecekKartiSecModu;

            if (!string.IsNullOrEmpty(chatManager.sohbet.contentImage.imageId))
                chatManager.sohbet.contentImage.image =
                    FindObjectOfType<PhotoManager>().GetSprite(chatManager.sohbet.contentImage.imageId);

            chatManager.tarotSohbetleri = new List<Sohbet>
            {
                chatManager.sohbet
            };
        }
        else
        {
            chatManager.sohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[1])
            {
                [0] = new Sohbet.AyarlanacakDegisken()
            };
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenAdi = "mod";
            chatManager.sohbet.ayarlananDegiskenler[0].degiskenDegeri = chatManager.tarotSettings.tarotTumuKartSecModu;

            if (!string.IsNullOrEmpty(chatManager.sohbet.contentImage.imageId))
                chatManager.sohbet.contentImage.image =
                    FindObjectOfType<PhotoManager>().GetSprite(chatManager.sohbet.contentImage.imageId);

            chatManager.tarotSohbetleri.Add(chatManager.sohbet);
        }
    }
}
