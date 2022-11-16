using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[CreateAssetMenu(menuName ="VeriTabani", fileName ="BilgiEkraniSettings")]
public class BilgiEkraniSettings : ScriptableObject
{
    public KarsilamaMesaji karsilamaMesaji;

    [TextArea(2, 5)]
    public string[] onlineFalAciklama;
    [TextArea(2, 5)]
    public string[] onlineFalBasariliAciklama;
    [TextArea(2, 5)]
    public string[] onlineFalBasarisizAciklama;

    [TextArea(2, 5)]
    public string[] dertlesAciklama;
    [TextArea(2, 5)] 
    public string[] dertlesBasariliAciklama;
    [TextArea(2, 5)] 
    public string[] dertlesBasarisizAciklama;

    [TextArea(2, 5)]
    public string[] onlineRuyaAciklama;
    [TextArea(2, 5)] 
    public string[] onlineRuyaBasariliAciklama;
    [TextArea(2, 5)] 
    public string[] onlineRuyaBasarisizAciklama;

    public Inbox inbox;

    public HizliFalOyun hizliFalOyun;

    public AciklamaPopUpData aciklamaPopUp;

    public BilgiEkraniUyari genelUyari;
    public BilgiEkraniUyari dogumSaatiUyari;
    public BilgiEkraniUyari dogumYeriUyari;
    public BilgiEkraniUyari cinsiyetUyari;
    public BilgiEkraniUyari meslekUyari;
    public BilgiEkraniUyari medeniDurumUyari;
    public BilgiEkraniUyari dogumAyiUyari;
    public BilgiEkraniUyari dogumGunuUyari;
    public BilgiEkraniUyari dogumYiliUyari;
    public BilgiEkraniUyari yasKucukUyari;
    public BilgiEkraniUyari soyisimUyari;
    public BilgiEkraniUyari isimUyari;
    public BilgiEkraniUyari hesapBaglamaUyari;
    public BilgiEkraniUyari profilFotografiBoyutUyari;
    public BilgiEkraniUyari profilFotografiDosyaTipiUyari;

    [TextArea(1, 5)]
    public string verileriSifirlaEkranBaslik;
    [TextArea(1, 5)]
    public string verileriSifirlaAciklama;
    [TextArea(1, 5)]
    public string hesabiSilAciklama;
    [TextArea(1, 5)]
    public string hesabiSilDeaktifAciklama;

    [System.Serializable]
    public class BilgiEkraniUyari
    {
        [TextArea(1, 5)]
        public string title;
        [TextArea(1,5)]
        public string description;

        public BilgiEkraniUyari()
        {
            title = "";
            description = "";
        }

        public BilgiEkraniUyari(string title, string description)
        {
            this.title = title;
            this.description = description;
        }
    }

    [System.Serializable]
    public class KarsilamaMesaji
    {
        [TextArea(1, 5)]
        public List<string> karsilamaMesajlari;

        [TextArea(1, 5)]
        public List<string> duzenlemeMesajlari;

        [TextArea(1, 5)]
        public List<string> gelenKutusuMesajlari;

        [TextArea(1, 5)]
        public List<string> falHaklariMesajlari;
    }

    [System.Serializable]
    public class Inbox
    {
        public EmptyExplanation emptyExplanation;
        public InboxElement defaultElement;
        public List<InboxElement> inboxElements;

        [System.Serializable]
        public class InboxElement
        {
            public string mod;
            public string title;
            public Sprite icon;
            public Sprite flare;
            public Vector2 delay;
            public string notReadyText;
            public int priority;
            public bool deletable = true;
            public bool showAd = true;
        }

        [System.Serializable]
        public class EmptyExplanation
        {
            [TextArea(1, 2)]
            public string title;

            [TextArea(2, 5)]
            public string descreption;
        }
    }

    [System.Serializable]
    public class HizliFalOyun
    {
        public Element defaultElement;
        public Gradient fallarTextBack;
        public Color fallarColor;
        public List<Element> fallar;
        public Gradient oyunlarTextBack;
        public Color oyunlarColor;
        public List<Element> oyunlar;
        public Gradient motivasyonTextBack;
        public Color motivasyonColor;
        public List<Element> motivasyon;
        public Gradient astrolojiTextBack;
        public Color astrolojiColor;
        public List<Element> astroloji;

        [System.Serializable]
        public class Element
        {
            public string title;
            public string sanaOzelTitle;
            public string mod;
            public Sprite icon;
            public Sprite iconDeactive;
            public int energy;
            public int kons;
            public bool showAd;

            [Range(1, 10)]
            public int falDegeri = 1;
            public bool plus;

            public int indexOffset;

            public bool reklamGoster;

            public Element()
            {
                falDegeri = 1;
                plus = false;
                indexOffset = 0;
                kons = 0;
                energy = 0;
                showAd = false;
            }
        }
    }

    [System.Serializable]
    public class AciklamaPopUpData
    {
        public Aciklama[] dogumTarihi;

        public Aciklama[] cinsiyet;

        public Aciklama[] medeniDurum;

        public Aciklama[] meslek;

        public Aciklama[] dogumSaati;

        public Aciklama[] dogumYeri;

        public Aciklama[] burc;

        public Aciklama[] gezegen;

        public Aciklama[] yukselen;

        public Aciklama[] ayburcu;

        public AciklamaPopUpData()
        {
            dogumTarihi = new Aciklama[0];
            cinsiyet = new Aciklama[0];
            medeniDurum = new Aciklama[0];
            meslek = new Aciklama[0];
            dogumSaati = new Aciklama[0];
            dogumYeri = new Aciklama[0];
            burc = new Aciklama[0];
            gezegen = new Aciklama[0];
            yukselen = new Aciklama[0];
            ayburcu = new Aciklama[0];
        }

        [System.Serializable]
        public class Aciklama
        {
            [TextArea(2, 5)]
            public List<string> text;

            public Sohbet.GerekenDegisken degisken;

            public Aciklama()
            {
                text = new List<string>();
                degisken = new Sohbet.GerekenDegisken();
            }
        }
    }
}
