using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class OnlineSohbetData
{
    [HideInInspector] public string ID;

    public Sohbet.SohbetOnceligi oncelik = new Sohbet.SohbetOnceligi();

    public string imageID = string.Empty;
    public string gifID = string.Empty;

    public Sohbet.Ad reklam = new Sohbet.Ad();

    public Sohbet.contentPhotoLocation fotografKonum = Sohbet.contentPhotoLocation.ayriBalondaBasta;

    public string ozelFonksiyon;

    [TextArea(5, 10)]
    public List<string> aciklamalar = new();
    public bool aciklamaBalonuYok = false;
    public bool yeniFocusPaneliKullan = false;
    public Sohbet.GlowEffectColor parlamaRengi = Sohbet.GlowEffectColor.yok;
    public float parlamaSuresi = 0;

    public List<string> birlestirilecekModlar = new List<string>();

    public List<OnlineCevapSohbetData> cevaplar = new List<OnlineCevapSohbetData>();

    public bool tepkiBalonuYok = false;

    public Sohbet.typeOfAnswerBubble balonTipi = new Sohbet.typeOfAnswerBubble();

    public List<Sohbet.AyarlanacakDegisken> ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
    public List<Sohbet.GerekenDegisken> gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();

    public int sayac = 0;
    public bool sayaSonuAnaMenuyeGit = false;
    public string sayacModu = "";
    [HideInInspector] public string sayacSohbetiID;

    public Sohbet.sayacTipiEnum sayacTipi = new Sohbet.sayacTipiEnum();

    public Sohbet.sohbetTekrarlama tekrarlama = new Sohbet.sohbetTekrarlama();

    public string sohbetBitimModu = string.Empty;
    public bool sohbetBititmindeAnamenuyeDon = true;
    public bool anaMenuyeGitButonuOlustur = true;

    public int sohbetEnerjisi = 0;
    public int sohbetKonsantrasyonu = 0;

    public Scratch kazima;

    public bool otomatikOdak = false;
    public bool metniKaydet = false;

    public OnlineSohbetData()
    {
        oncelik = new Sohbet.SohbetOnceligi();
        this.aciklamalar = new List<string>();
        aciklamaBalonuYok = false;
        yeniFocusPaneliKullan = false;

        birlestirilecekModlar = new List<string>();

        cevaplar = new List<OnlineCevapSohbetData>();

        tepkiBalonuYok = false;

        balonTipi = new Sohbet.typeOfAnswerBubble();

        parlamaSuresi = 0;

        gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();
        ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();

        imageID = string.Empty;
        gifID = string.Empty;

        reklam = new Sohbet.Ad();

        fotografKonum = Sohbet.contentPhotoLocation.ayriBalondaBasta;

        sayac = 0;
        sayaSonuAnaMenuyeGit = false;
        sayacModu = string.Empty;

        sayacTipi = new Sohbet.sayacTipiEnum();

        tekrarlama = new Sohbet.sohbetTekrarlama();

        sohbetBitimModu = string.Empty;
        sohbetBititmindeAnamenuyeDon = true;
        anaMenuyeGitButonuOlustur = true;

        sohbetEnerjisi = 0;
        sohbetKonsantrasyonu = 0;

        kazima = new();

        otomatikOdak = false;
        metniKaydet = false;
    }

    [System.Serializable]
    public class Scratch
    {
        public Sohbet.Scratch.KazimaModuEnum kazimaTipi = new Sohbet.Scratch.KazimaModuEnum();
        public string imageId;
        public string gifId;
        public int kazimaOrani = 50;
        public int kazimaSonuBekleme = 2;
        public string kazimaModu;
    }
}
