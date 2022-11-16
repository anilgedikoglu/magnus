using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[SerializeField]
[CreateAssetMenu(fileName = "Sohbet", menuName = "Veri Tabani/Sohbet Havuzu Olustur")]
public class Sohbet : ScriptableObject
{
    [HideInInspector] public string idIndex = "-1";

    public enum SohbetOnceligi { normal = 0, ilk_1 = 1, ilk_2 = 3 ,son = 2,};
    public SohbetOnceligi oncelik = new SohbetOnceligi();

    public ContentImage contentImage;
    public Ad reklam;

    [HideInInspector] public Sprite contentPhoto;
    [HideInInspector] public string contentPhotoId = "";
    [HideInInspector] public string gifId;

    public enum contentPhotoLocation { ayriBalondaBasta= 0, ayriBalondaSonda = 1, balonIcindeBasta = 2, balonIcindeSonda = 3};
    public contentPhotoLocation fotografKonum = new contentPhotoLocation();
    public string ozelFonksiyon;

    [Header("Genel")]
    [Tooltip("Açıklamalar yapayzekanın yazacağı baloncuklardır. Her farkli varyasyon icin yeni bir aciklama ekleyebilirisiniz. Bunlar temelinde ayni şeyi ifade etmelidir.")]
    [TextArea(10, 20)]
    public List<string> aciklama;
    public bool aciklamaBalonuYok;

    public List<string> birlestirilecekModlar = new List<string>();

    //KALDIRILDI
    [Tooltip("Bu değişken sadece bu takip sohbet son takip sohbetse ve herhangi bir seçenek tanımlanmadıysa, yani bir sohbetten çıkış mesajı ise, takip sohbet metninin gösterilme şansını" +
    " belirtir.")]
    [HideInInspector] public int gostermeSansi = 100;

    [Tooltip("Cevaplar kullanıcının karşısına gelecek tüm cevap butonlarını temsil eder. Kaç farklı cevap oluşturursanız o kadar buton gelir. Cevaplar cevap varyasyonlarından farklıdır.")]
    public List<CevapSohbet> cevaplar;
    public bool tepkiBalonuYok;

    public enum typeOfAnswerBubble { altAlta = 0, yanYana = 1 }
    public typeOfAnswerBubble balonTipi = new typeOfAnswerBubble();

    public List<AyarlanacakDegisken> ayarlananDegiskenler;
    public List<GerekenDegisken> gerekliDegiskenler;

    public List<Sprite> sohbetArkaplani;
    public int arkaplanDelay;

    [TextArea(2,2)]
    public string yokSayDegiskeni = "";
    public Sohbet yokSayilmaSohbeti = null;

    [Space(20)]
    public int sayac = 0;
    public bool sayaSonuAnaMenuyeGit = false;
    public string sayacModu = "";
    public Sohbet sayacSohbeti = null;
    public enum sayacTipiEnum { gorunmez = 0, textEkranda = 1, bar = 2, barVeEkrandaText = 4, balonIciGolge = 3}
    public sayacTipiEnum sayacTipi = new sayacTipiEnum();

    public enum sohbetTekrarlama { surekli = 0, sonrakiAcilista = 1, sonrakiGun = 2, unutunca = 3, tekSefer = 4 }
    public sohbetTekrarlama tekrarlama= new sohbetTekrarlama();

    [Space(20)]
    public string sohbetBitimModu = "";
    public bool sohbetBititmindeAnamenuyeDon = true;
    public bool anaMenuyeGitButonuOlustur = true;

    public int sohbetEnerjisi = 0;
    public int sohbetKonsantrasyonu = 0;

    public Scratch kazima;
    [HideInInspector] public enum KazimaModuEnum { kapali = 0, panel = 1, quiz = 2 }
    [HideInInspector] public KazimaModuEnum kazimaTipi = new KazimaModuEnum();
    [HideInInspector] public Sprite kazimaFotografi;
    [HideInInspector] public string kazimaFotografiId;
    [HideInInspector] public int kazimaOrani = 50;
    [HideInInspector] public int kazimaSonuBekleme = 2;
    [HideInInspector] public string kazimaModu;
    [HideInInspector] public Sohbet kazimaSohbeti;

    public bool otomatikOdak;
    public bool metniKaydet;

    [HideInInspector]public PreferencesObject preferencesObject;

    public Sohbet()
    {
        idIndex = "-1";
        oncelik = new SohbetOnceligi();
        contentImage = new ContentImage();
        reklam = new Ad();
        fotografKonum = new contentPhotoLocation();
        aciklama = new List<string>() { string.Empty };
        birlestirilecekModlar = new List<string>();
        cevaplar = new List<CevapSohbet>();
        balonTipi = new typeOfAnswerBubble();
        ayarlananDegiskenler = new List<AyarlanacakDegisken>();
        gerekliDegiskenler = new List<GerekenDegisken>();
        sohbetArkaplani = new List<Sprite>();
        sayacTipi = new sayacTipiEnum();
        tekrarlama = new sohbetTekrarlama();
        kazima = new Scratch();
        kazimaTipi = new KazimaModuEnum();
    }

    private void OnValidate()
    {
#if UNITY_EDITOR

        contentImage.gifId = GetGifIdFromUrl(contentImage.gifId);
        kazimaFotografiId = GetGifIdFromUrl(kazimaFotografiId);

        foreach(CevapSohbet cevapSohbet in cevaplar)
        {
            cevapSohbet.contentImage.gifId = GetGifIdFromUrl(cevapSohbet.contentImage.gifId);
        }
#endif
    }
    
    string GetGifIdFromUrl(string url)
    {
        string gifId = url;

        if (!string.IsNullOrEmpty(url))
        {
            char[] urlCharArray = url.ToCharArray();
            string startKeyWord = "embed/";
            int startIndex = url.IndexOf("embed/");
            int IdLength = 40;

            if (urlCharArray.Length > startIndex + IdLength + startKeyWord.Length)
            {
                gifId = "";
                for (int i = startIndex + startKeyWord.Length; i < startIndex + IdLength + startKeyWord.Length; i++)
                {
                    if (char.IsLetter(urlCharArray[i]) || char.IsNumber(urlCharArray[i]))
                        gifId += urlCharArray[i].ToString();
                    else
                        break;
                }
            }
        }
        return gifId;
    }

    public bool IsPhotographMode()
    {
        bool returnValue = false;

        foreach(CevapSohbet element in cevaplar)
        {
            if(element.ozelFonksiyon=="fotoğraf çek")
            {
                returnValue = true;
                break;
            }
        }

        return returnValue;
    }

    public bool IsFilePickerMode()
    {
        bool returnValue = false;

        foreach (CevapSohbet element in cevaplar)
        {
            if (element.ozelFonksiyon == "fotoğraf seç kahve" || element.ozelFonksiyon == "online fotoğraf seç kahve" || element.ozelFonksiyon == "fotoğraf seç yüz" || element.ozelFonksiyon == "fotoğraf seç el")
            {
                returnValue = true;
                break;
            }
        }

        return returnValue;
    }

    public string GetSohbetId()
    {
        string returnValue = idIndex.ToString();

        return returnValue;
    }

    [System.Serializable]
    public class AyarlanacakDegisken
    {
        public string degiskenAdi;
        public string degiskenDegeri;
        public enum Islem
        {
            esitleme,
            toplama,
            cikartma,
            carpma,
            bolme
        }
        public Islem islem;

        public AyarlanacakDegisken()
        {
            this.degiskenAdi = string.Empty;
            this.degiskenDegeri = string.Empty;
            this.islem = new Islem();
        }

        public AyarlanacakDegisken(string degiskenAdi, string degiskenDegeri)
        {
            this.degiskenAdi = degiskenAdi;
            this.degiskenDegeri = degiskenDegeri;
            this.islem = new Islem();
        }

        public AyarlanacakDegisken(string degiskenAdi, string degiskenDegeri, Islem islem)
        {
            this.degiskenAdi = degiskenAdi;
            this.degiskenDegeri = degiskenDegeri;
            this.islem = islem;
        }
    }

    [System.Serializable]
    public class GerekenDegisken
    {
        public string degiskenAdi;
        public string degiskenDegeri;
        public enum Kontrol 
        { 
            esit = 0,
            esitDegil = 1, 
            buyuk = 2,
            kucuk = 3,
            buyukEsit = 4, 
            kucukEsit = 5 
        }
        public Kontrol kontrol;

        public GerekenDegisken()
        {
            this.degiskenAdi = string.Empty;
            this.degiskenDegeri = string.Empty;
            this.kontrol = new Kontrol();
        }

        public GerekenDegisken(string degiskenAdi, string degiskenDegeri)
        {
            this.degiskenAdi = degiskenAdi;
            this.degiskenDegeri = degiskenDegeri;
            this.kontrol = new Kontrol();
        }

        public GerekenDegisken(string degiskenAdi, string degiskenDegeri, Kontrol islem)
        {
            this.degiskenAdi = degiskenAdi;
            this.degiskenDegeri = degiskenDegeri;
            this.kontrol = islem;
        }
    }

    [System.Serializable]
    public class ContentImage
    {
        public string imageId;
        public string gifId;
        public Sprite image;
    }

    [System.Serializable]
    public class Ad
    {
        public enum Type
        {
            yok,
            rewarded,
            interstatial
        }
        public Type type;

        public enum Placement
        {
            sohbettenOnce,
            sohbettenSonra
        }
        public Placement placement;

        public AdManager.RewardItem odul;

        public Ad()
        {
            type = 0;
            placement = 0;
            odul = new AdManager.RewardItem();
        }
    }

    [System.Serializable]
    public class Scratch
    {
        public enum KazimaModuEnum { kapali = 0, panel = 1, quiz = 2 }
        public KazimaModuEnum kazimaTipi = new KazimaModuEnum();
        public Sprite image;
        public string imageId;
        public string gifId;
        public int kazimaOrani = 50;
        public int kazimaSonuBekleme = 2;
        public string kazimaModu;
        public Sohbet kazimaSohbeti;
    }
}
