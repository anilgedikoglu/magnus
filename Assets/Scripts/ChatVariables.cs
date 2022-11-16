using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Globalization;
using System.Text;
using System.Linq;

public class ChatVariables : MonoBehaviour
{
    public ChatManager chatManager;
    public CurrentPlayerData PlayerDataManager;
    public PreferencesObject preferencesObject;
    public DefaultVariables defaultVariables;

    void Start()
    {

    }

    void Update()
    {
        
    }

    public string OrtakButonlar(string text)
    {
        text = ChangeTheVariablesInText(text);
        text = IsimeEkEkle(text);//
        text = IsimeEkEkleSin(text);//
        text = IsimeEkEkleDin(text);//
        text = IsimdekiHarfSayisi(text);//
        text = IsimeEkEkleDen(text);//
        text = IsimeEkEkleDe(text);//
        text = IsimeEkEkleI(text);//
        text = IsimeEkEkleE(text);//
        text = BurcaEkEkleLuk(text);//

        text = EnerjiMiktari(text);
        text = KonsantrasyonMiktari(text);

        text = SehreEkEkleE(text);//
        text = SehreEkEkleDen(text);//
        text = SehreEkEkleIn(text);//
        text = SehreEkEkleDe(text);//
        text = SehreEkEkleI(text);//
        text = SehreEkEkleLi(text);//
        text = DogumSehrineEkEkleE(text);//
        text = DogumSehrineEkEkleDen(text);//
        text = DogumSehrineEkEkleIn(text);//
        text = DogumSehrineEkEkleDe(text);//
        text = DogumSehrineEkEkleI(text);//
        text = DogumSehrineEkEkleLi(text);//

        text = SaatKac(text);//
        text = SaatKacV2(text);//

        text = TamSaat(text);//
        text = TamSaatV2(text);//

        text = RastgeleButonlar(text);//
        text = RastgeleButonlarSabit(text);

        text = SaatKacYazi(text);//
        text = SaatKacYaziV2(text);//

        text = SaateGoreKelimeGrubuSec(text);

        text = IsimeHanimBeyEkle(text);//
        text = IsimeHanimBeyEkleV2(text);//

        text = HarfSec(text);//
        
        text = SabitHarfSec(text);//
        text = SabitHarfSecV2(text);//
        text = SabitHarfSecV3(text);//

        text = KelimeGrubuSec(text);
        text = SabitKelimeGrubuSec(text);
        text = GecenSimdikiGelecekAy(text);//
        text = Sayi(text);//

        text = SabitSayi(text);//
        text = SabitSayiV2(text);//
        text = SabitSayiV3(text);//

        text = XGundurHayatta(text);//

        text = AySec(text);//
        text = AySecV2(text);//

        text = YilSec(text);//
        text = YilSecV2(text);//

        text = GunSec(text);//
        text = GunSecV2(text);//

        text = GunSecSayi(text);//
        text = GunSecSayiV2(text);//
        text = GunSecSayiV3(text);//
        text = GunSecSayiV4(text);//

        text = AySecSayi(text);//
        text = AySecSayiV2(text);//

        text = DogumAyi(text);//
        text = DogumAyiV2(text);//
        text = DogumAyiV3(text);//
        text = DogumAyiV4(text);//

        text = DogumAyiYaziyla(text);//
        text = DogumAyiYaziylaV2(text);//
        text = DogumAyiYaziylaV3(text);//
        text = DogumAyiYaziylaV4(text);//

        text = DogumGunu(text);//
        text = DogumGunuV2(text);//
        text = DogumGunuV3(text);//
        text = DogumGunuV4(text);//

        text = DogumGunuYaziyla(text);//
        text = DogumGunuYaziylaV2(text);//
        text = DogumGunuYaziylaV3(text);//
        text = DogumGunuYaziylaV4(text);//

        text = DogumYili(text);//
        text = DogumYiliV2(text);//
        text = DogumYiliV3(text);//
        text = DogumYiliV4(text);//

        text = MevsimSec(text);//
        text = MevsimSecV2(text);//

        text = YasSec(text);//
        text = YasSecV2(text);//

        text = DatayaGoreKelimeGrubuSec(text);//
        text = AltSatiraGec(text);//
        text = IsimHarfleri(text);//
        text = SoyIsimHarfleri(text);//

        text = RastgeleBurc(text);//
        text = RastgeleBurcV2(text);//

        text = GetRenderedText(text);//

        text = IfadeSayi(text);
        text = RuhSayi(text);
        text = SessizBenlikSayi(text);
        text = YasamYoluSayi(text);
        text = OlgunlukSayi(text);
        text = DogumYiliSayi(text);
        text = KarmikBorcSayi(text);

        //Diger fonksiyonlar metni degistirecegi icin bu fonkiyon digerlerinden sonra calismak zorunda!
        text = BuyukHarfKontrol(text);

        return text;
    }

    #region NUMEROLOJI

    public string IfadeSayi(string text)
    {
        if (!(text.Contains("{{ifadesayisi}}") ||
            text.Contains("{{ifadesayisibugun}}") ||
            text.Contains("{{ifadesayisiyil}}")))
            return text;

        if (text.Contains("{{ifadesayisibugun}}"))
            text = text.Replace("{{ifadesayisibugun}}", TextNumeroljiBugunDegeri(GetFullName()).ToString());

        if (text.Contains("{{ifadesayisiyil}}"))
            text = text.Replace("{{ifadesayisiyil}}", TextNumeroljiYilDegeri(GetFullName()).ToString());

        if (text.Contains("{{ifadesayisi}}"))
            text = text.Replace("{{ifadesayisi}}", TextNumeroljiDegeri(GetFullName()).ToString());

        return text;
    }

    public string RuhSayi(string text)
    {
        if (!(text.Contains("{{ruhsayisi}}") ||
            text.Contains("{{ruhsayisibugun}}") ||
            text.Contains("{{ruhsayisiyil}}")))
            return text;

        if (text.Contains("{{ruhsayisibugun}}"))
            text = text.Replace("{{ruhsayisibugun}}", TextNumeroljiBugunDegeri(GetFullName(), true).ToString());

        if (text.Contains("{{ruhsayisiyil}}"))
            text = text.Replace("{{ruhsayisiyil}}", TextNumeroljiYilDegeri(GetFullName(), true).ToString());

        if (text.Contains("{{ruhsayisi}}"))
            text = text.Replace("{{ruhsayisi}}", TextNumeroljiDegeri(GetFullName(), true).ToString());

        return text;
    }

    public string SessizBenlikSayi(string text)
    {
        if (!(text.Contains("{{sessizbenliksayisi}}") ||
            text.Contains("{{sessizbenliksayisibugun}}") ||
            text.Contains("{{sessizbenliksayisiyil}}")))
            return text;

        if (text.Contains("{{sessizbenliksayisibugun}}"))
            text = text.Replace("{{sessizbenliksayisibugun}}", TextNumeroljiBugunDegeri(GetFullName(), false).ToString());

        if (text.Contains("{{sessizbenliksayisiyil}}"))
            text = text.Replace("{{sessizbenliksayisiyil}}", TextNumeroljiYilDegeri(GetFullName(), false).ToString());

        if (text.Contains("{{sessizbenliksayisi}}"))
            text = text.Replace("{{sessizbenliksayisi}}", TextNumeroljiDegeri(GetFullName(), false).ToString());

        return text;
    }

    public string YasamYoluSayi(string text)
    {
        if (!(text.Contains("{{yasamyolusayisi}}") ||
            text.Contains("{{yasamyolusayisibugun}}") ||
            text.Contains("{{yasamyolusayisiyil}}")))
            return text;

        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out int dogumYili);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out int dogumAyi);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out int dogumGunu);

        int value = SumDigitsAll(
             SumDigitsAll(dogumYili)
             + SumDigitsAll(dogumAyi)
             + SumDigitsAll(dogumGunu));

        int valueBugun = SumDigitsAll(
            SumDigitsAll(dogumYili)
            + SumDigitsAll(dogumAyi)
            + SumDigitsAll(dogumGunu) +
            SumDigitsAll(System.DateTime.Now.Year)
            + SumDigitsAll(System.DateTime.Now.Month)
            + SumDigitsAll(System.DateTime.Now.Day));

        int valueYil = SumDigitsAll(
            SumDigitsAll(dogumYili)
            + SumDigitsAll(dogumAyi)
            + SumDigitsAll(dogumGunu) +
            SumDigitsAll(System.DateTime.Now.Year));

        if (text.Contains("{{yasamyolusayisibugun}}"))
            text = text.Replace("{{yasamyolusayisibugun}}", valueBugun.ToString());

        if (text.Contains("{{yasamyolusayisiyil}}"))
            text = text.Replace("{{yasamyolusayisiyil}}", valueYil.ToString());

        if (text.Contains("{{yasamyolusayisi}}"))
            text = text.Replace("{{yasamyolusayisi}}", value.ToString());

        return text;
    }

    public string OlgunlukSayi(string text)
    {
        if (!(text.Contains("{{olgunluksayisi}}") || 
            text.Contains("{{olgunluksayisibugun}}") ||
            text.Contains("{{olgunluksayisiyil}}")))
            return text;

        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out int dogumYili);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out int dogumAyi);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out int dogumGunu);

        int value = SumDigitsAll(
             SumDigitsAll(dogumYili)
             + SumDigitsAll(dogumAyi)
             + SumDigitsAll(dogumGunu));

        int valueBugun = SumDigitsAll(
            SumDigitsAll(dogumYili)
            + SumDigitsAll(dogumAyi)
            + SumDigitsAll(dogumGunu) +
            SumDigitsAll(System.DateTime.Now.Year)
            + SumDigitsAll(System.DateTime.Now.Month)
            + SumDigitsAll(System.DateTime.Now.Day));

        int valueYil = SumDigitsAll(
            SumDigitsAll(dogumYili)
            + SumDigitsAll(dogumAyi)
            + SumDigitsAll(dogumGunu) +
            SumDigitsAll(System.DateTime.Now.Year));

        if (text.Contains("{{olgunluksayisibugun}}"))
            text = text.Replace("{{olgunluksayisibugun}}", SumDigitsAll(valueBugun + TextNumeroljiBugunDegeri(GetFullName())).ToString());

        if (text.Contains("{{olgunluksayisiyil}}"))
            text = text.Replace("{{olgunluksayisiyil}}", SumDigitsAll(valueYil + TextNumeroljiYilDegeri(GetFullName())).ToString());

        if (text.Contains("{{olgunluksayisi}}"))
            text = text.Replace("{{olgunluksayisi}}", SumDigitsAll(value + TextNumeroljiDegeri(GetFullName())).ToString());

        return text;
    }

    public string DogumYiliSayi(string text)
    {
        if (!(text.Contains("{{dogumgunusayisi}}") ||
    text.Contains("{{dogumgunusayisibugun}}") ||
    text.Contains("{{dogumgunusayisiyil}}")))
            return text;

        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out int dogumYili);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out int dogumAyi);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out int dogumGunu);

        int value = SumDigitsAll(
             SumDigitsAll(dogumYili)
             + SumDigitsAll(dogumAyi)
             + SumDigitsAll(dogumGunu));

        int valueBugun = SumDigitsAll(
    SumDigitsAll(dogumYili)
    + SumDigitsAll(dogumAyi)
    + SumDigitsAll(dogumGunu) +
    SumDigitsAll(System.DateTime.Now.Year)
    + SumDigitsAll(System.DateTime.Now.Month)
    + SumDigitsAll(System.DateTime.Now.Day));

        int valueYil = SumDigitsAll(
            SumDigitsAll(dogumYili)
            + SumDigitsAll(dogumAyi)
            + SumDigitsAll(dogumGunu) +
            SumDigitsAll(System.DateTime.Now.Year));

        if (text.Contains("{{dogumgunusayisi}}"))
            text = text.Replace("{{dogumgunusayisi}}", value.ToString());

        if (text.Contains("{{dogumgunusayisibugun}}"))
            text = text.Replace("{{dogumgunusayisibugun}}", valueBugun.ToString());

        if (text.Contains("{{dogumgunusayisiyil}}"))
            text = text.Replace("{{dogumgunusayisiyil}}", valueYil.ToString());

        return text;
    }

    public string KarmikBorcSayi(string text)
    {
        if (!(text.Contains("{{karmikborcsayisi}}") ||
text.Contains("{{karmikborcsayisibugun}}") ||
text.Contains("{{karmikborcsayisiyil}}")))
            return text;

        if (text.Contains("{{karmikborcsayisi}}"))
            text = text.Replace("{{karmikborcsayisi}}", SumDigitsAll(125 - NumerolojiDegeriHesaplaOlmayan(GetFullName())).ToString());

        if (text.Contains("{{karmikborcsayisibugun}}"))
            text = text.Replace("{{karmikborcsayisibugun}}", (
    + SumDigitsAll(SumDigitsAll(125 - NumerolojiDegeriHesaplaOlmayan(GetFullName()))+
    SumDigitsAll(System.DateTime.Now.Day)+
        SumDigitsAll(System.DateTime.Now.Month)+
            SumDigitsAll(System.DateTime.Now.Year)
    )).ToString());

        if (text.Contains("{{karmikborcsayisiyil}}"))
            text = text.Replace("{{karmikborcsayisiyil}}", SumDigitsAll(
            SumDigitsAll(125 - NumerolojiDegeriHesaplaOlmayan(GetFullName())) + SumDigitsAll(System.DateTime.Now.Year)).ToString());

        return text;
    }

    public int TextNumeroljiDegeri(string textValue)
    {
        int value = NumerolojiDegeriHesapla(textValue);

        return SumDigitsAll(value);
    }

    public int TextNumeroljiDegeri(string textValue, bool sesli)
    {
        int value = NumerolojiDegeriHesapla(textValue, sesli);

        return SumDigitsAll(value);
    }

    public int TextNumeroljiBugunDegeri(string textValue)
    {
        int value = NumerolojiDegeriHesapla(textValue);

        return SumDigitsAll(SumDigitsAll(value) +
            SumDigitsAll(System.DateTime.Now.Year)
            + SumDigitsAll(System.DateTime.Now.Month)
            + SumDigitsAll(System.DateTime.Now.Day));
    }

    public int TextNumeroljiBugunDegeri(string textValue, bool sesli)
    {
        int value = NumerolojiDegeriHesapla(textValue, sesli);

        return SumDigitsAll(SumDigitsAll(value) +
            SumDigitsAll(System.DateTime.Now.Year)
            + SumDigitsAll(System.DateTime.Now.Month)
            + SumDigitsAll(System.DateTime.Now.Day));
    }

    public int TextNumeroljiYilDegeri(string textValue)
    {
        int value = NumerolojiDegeriHesapla(textValue);

        return SumDigitsAll(SumDigitsAll(value) +
            SumDigitsAll(System.DateTime.Now.Year));
    }

    public int TextNumeroljiYilDegeri(string textValue, bool sesli)
    {
        int value = NumerolojiDegeriHesapla(textValue, sesli);

        return SumDigitsAll(SumDigitsAll(value) +
            SumDigitsAll(System.DateTime.Now.Year));
    }

    private int NumerolojiDegeriHesapla(string textValue)
    {
        int value = 0;
        char[] isim = (textValue).ToUpper(new CultureInfo("tr-TR")).ToCharArray();
        foreach (char harf in isim)
            value += GetCharValue(harf);

        return value;
    }

    private int NumerolojiDegeriHesaplaOlmayan(string textValue)
    {
        int value = 0;
        char[] isim = (textValue).ToUpper(new CultureInfo("tr-TR")).ToCharArray();
        foreach (char harf in isim)
            value += GetCharValueOlmayan(harf);

        return value;
    }

    private int NumerolojiDegeriHesapla(string textValue, bool sesli)
    {
        int value = 0;
        char[] isim = (textValue).ToUpper(new CultureInfo("tr-TR")).ToCharArray();
        foreach (char harf in isim)
            value += sesli ? GetCharValueSesli(harf) : GetCharValueSessiz(harf);

        return value;
    }

    private int GetCharValue(char harf)
    {
        char[] values1 = new char[] { 'A', 'J', 'S', 'Ş' };//4
        char[] values2 = new char[] { 'B', 'K', 'T' };//6
        char[] values3 = new char[] { 'C', 'Ç', 'L', 'U', 'Ü' };//15
        char[] values4 = new char[] { 'D', 'M', 'V' };//12
        char[] values5 = new char[] { 'E', 'N', 'W' };//15
        char[] values6 = new char[] { 'F', 'O', 'Ö', 'X' };//24
        char[] values7 = new char[] { 'G', 'Ğ', 'P', 'Y' };//28
        char[] values8 = new char[] { 'H', 'Q', 'Z' };//24
        char[] values9 = new char[] { 'I', 'İ', 'R' };//27

        if (Array.Find(values1, x => x.Equals(harf)) == harf)
        {
            return 1;
        }
        else if (Array.Find(values2, x => x.Equals(harf)) == harf)
        {
            return 2;
        }
        else if (Array.Find(values3, x => x.Equals(harf)) == harf)
        {
            return 3;
        }
        else if (Array.Find(values4, x => x.Equals(harf)) == harf)
        {
            return 4;
        }
        else if (Array.Find(values5, x => x.Equals(harf)) == harf)
        {
            return 5;
        }
        else if (Array.Find(values6, x => x.Equals(harf)) == harf)
        {
            return 6;
        }
        else if (Array.Find(values7, x => x.Equals(harf)) == harf)
        {
            return 7;
        }
        else if (Array.Find(values8, x => x.Equals(harf)) == harf)
        {
            return 8;
        }
        else if (Array.Find(values9, x => x.Equals(harf)) == harf)
        {
            return 9;
        }
        else
        {
            return 0;
        }
    }

    private int GetCharValueOlmayan(char harf)
    {
        List<char> values1 = new List<char>() { 'A', 'J', 'S', 'Ş' };//4
        values1 = RemoveIsimHarfleri(values1);

        List<char> values2 = new List<char>() { 'B', 'K', 'T' };//6
        values2 = RemoveIsimHarfleri(values2);

        List<char> values3 = new List<char>() { 'C', 'Ç', 'L', 'U', 'Ü' };//15
        values3 = RemoveIsimHarfleri(values3);

        List<char> values4 = new List<char>() { 'D', 'M', 'V' };//12
        values4 = RemoveIsimHarfleri(values4);

        List<char> values5 = new List<char>() { 'E', 'N', 'W' };//15
        values5 = RemoveIsimHarfleri(values5);

        List<char> values6 = new List<char>() { 'F', 'O', 'Ö', 'X' };//24
        values6 = RemoveIsimHarfleri(values6);

        List<char> values7 = new List<char>() { 'G', 'Ğ', 'P', 'Y' };//28
        values7 = RemoveIsimHarfleri(values7);

        List<char> values8 = new List<char>() { 'H', 'Q', 'Z' };//24
        values8 = RemoveIsimHarfleri(values8);

        List<char> values9 = new List<char>() { 'I', 'İ', 'R' };//27
        values9 = RemoveIsimHarfleri(values9);

        if (values1.Find(x => x.Equals(harf)) == harf)
        {
            return 1;
        }
        else if (values2.Find(x => x.Equals(harf)) == harf)
        {
            return 2;
        }
        else if (values3.Find(x => x.Equals(harf)) == harf)
        {
            return 3;
        }
        else if (values4.Find(x => x.Equals(harf)) == harf)
        {
            return 4;
        }
        else if (values5.Find(x => x.Equals(harf)) == harf)
        {
            return 5;
        }
        else if (values6.Find(x => x.Equals(harf)) == harf)
        {
            return 6;
        }
        else if (values7.Find(x => x.Equals(harf)) == harf)
        {
            return 7;
        }
        else if (values8.Find(x => x.Equals(harf)) == harf)
        {
            return 8;
        }
        else if (values9.Find(x => x.Equals(harf)) == harf)
        {
            return 9;
        }
        else
        {
            return 0;
        }
    }

    private List<char> RemoveIsimHarfleri(List<char> liste)
    {
        foreach(char harf in GetFullName().ToUpper())
        {
            if (liste.Contains(harf))
                liste.Remove(harf);
        }

        return liste;
    }

    private int GetCharValueSesli(char harf)
    {
        char[] values1 = new char[] { 'A'};
        char[] values2 = new char[] { };
        char[] values3 = new char[] { 'U', 'Ü' };
        char[] values4 = new char[] { };
        char[] values5 = new char[] { 'E'};
        char[] values6 = new char[] { 'O', 'Ö'};
        char[] values7 = new char[] { };
        char[] values8 = new char[] { };
        char[] values9 = new char[] { 'I', 'İ'};

        if (Array.Find(values1, x => x.Equals(harf)) == harf)
        {
            return 1;
        }
        else if (Array.Find(values2, x => x.Equals(harf)) == harf)
        {
            return 2;
        }
        else if (Array.Find(values3, x => x.Equals(harf)) == harf)
        {
            return 3;
        }
        else if (Array.Find(values4, x => x.Equals(harf)) == harf)
        {
            return 4;
        }
        else if (Array.Find(values5, x => x.Equals(harf)) == harf)
        {
            return 5;
        }
        else if (Array.Find(values6, x => x.Equals(harf)) == harf)
        {
            return 6;
        }
        else if (Array.Find(values7, x => x.Equals(harf)) == harf)
        {
            return 7;
        }
        else if (Array.Find(values8, x => x.Equals(harf)) == harf)
        {
            return 8;
        }
        else if (Array.Find(values9, x => x.Equals(harf)) == harf)
        {
            return 9;
        }
        else
        {
            return 0;
        }
    }

    private int GetCharValueSessiz(char harf)
    {
        char[] values1 = new char[] { 'J', 'S', 'Ş' };
        char[] values2 = new char[] { 'B', 'K', 'T' };
        char[] values3 = new char[] { 'C', 'Ç', 'L'};
        char[] values4 = new char[] { 'D', 'M', 'V' };
        char[] values5 = new char[] { 'E', 'N', 'W' };
        char[] values6 = new char[] { 'F', 'X' };
        char[] values7 = new char[] { 'G', 'Ğ', 'P', 'Y' };
        char[] values8 = new char[] { 'H', 'Q', 'Z' };
        char[] values9 = new char[] { 'R' };

        if (Array.Find(values1, x => x.Equals(harf)) == harf)
        {
            return 1;
        }
        else if (Array.Find(values2, x => x.Equals(harf)) == harf)
        {
            return 2;
        }
        else if (Array.Find(values3, x => x.Equals(harf)) == harf)
        {
            return 3;
        }
        else if (Array.Find(values4, x => x.Equals(harf)) == harf)
        {
            return 4;
        }
        else if (Array.Find(values5, x => x.Equals(harf)) == harf)
        {
            return 5;
        }
        else if (Array.Find(values6, x => x.Equals(harf)) == harf)
        {
            return 6;
        }
        else if (Array.Find(values7, x => x.Equals(harf)) == harf)
        {
            return 7;
        }
        else if (Array.Find(values8, x => x.Equals(harf)) == harf)
        {
            return 8;
        }
        else if (Array.Find(values9, x => x.Equals(harf)) == harf)
        {
            return 9;
        }
        else
        {
            return 0;
        }
    }

    private int SumDigist(int value)
    {
        int sum = 0;
        while (value != 0)
        {
            sum += value % 10;
            value /= 10;
        }

        return sum;
    }

    private int SumDigitsAll(int value)
    {
        int sum = SumDigist(value);

        while (Math.Floor(Math.Log10(sum) + 1) > 1)
        {
            sum = SumDigist(sum);
        }

        return sum;
    }

    private string GetFullName()
    {
        return (PlayerDataManager.GetChatVariableValue("isim") +
            PlayerDataManager.GetChatVariableValue("soyisim"));
    }

    #endregion

    public string BuyukHarfKontrol(string text)
    {
        char[] textChar = text.ToCharArray();

        text = "";
        for (int i = 0; i < textChar.Length; i++)
        {
            if (i > 0 && i < textChar.Length - 2)
            {
                if ((textChar[i].ToString() == ".") || (textChar[i].ToString() == "?") || (textChar[i].ToString() == "!") || (textChar[i].ToString() == ">"))
                {
                    if (textChar[i + 1].ToString() == " ")
                    {
                        text += textChar[i].ToString() + textChar[i + 1].ToString() + textChar[i + 2].ToString().ToUpper();
                        i += 2;
                    }
                    else
                    {
                        text += textChar[i].ToString() + textChar[i + 1].ToString();
                        i += 1;
                    }
                }
                else if (textChar[i - 1].ToString() == "\n")
                {
                    text += textChar[i].ToString().ToUpper();
                    //i += 1;
                }
                else
                {
                    text += textChar[i].ToString();
                }
            }
            else if ((i == 0))
            {
                text += textChar[i].ToString().ToUpper();
            }
            else
            {
                text += textChar[i].ToString();
            }
        }

        return text;
    }

    public string ChangeTheVariablesInText(string text)
    {
        int kullaniciDogumGunu=-1;
        int kullaniciDogumAyi=-1;
        int kullaniciDogumYili=-1;

        if (PlayerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum gunu")))
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);

        if (PlayerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum ayi")))
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);

        if (PlayerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum yili")))
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

        if (kullaniciDogumGunu <= 0)
            kullaniciDogumGunu = 1;

        if (kullaniciDogumAyi <= 0)
            kullaniciDogumAyi = 1;

        if (kullaniciDogumYili <= 0)
            kullaniciDogumYili = 1950;

        //isim degiskeni her zaman ilk harfler buyuk olacagi icin onceden kontrol edilir.
        if (text.Contains("{{isim}}"))
        {
            text = text.Replace("{{isim}}", PlayerDataManager.GetChatVariableValue("isim", true));
        }

        if (text.Contains("{{soyisim}}"))
        {
            text = text.Replace("{{soyisim}}", PlayerDataManager.GetChatVariableValue("soyisim", true));
        }

        if (text.Contains("{{dogumgunu}}"))
        {
            text = text.Replace("{{dogumgunu}}", PlayerDataManager.GetChatVariableValue("dogum gunu"));
        }

        if (text.Contains("{{dogumayi}}"))
        {
            text = text.Replace("{{dogumayi}}", PlayerDataManager.GetChatVariableValue("dogum ayi"));
        }

        if (text.Contains("{{dogumyili}}"))
        {
            text = text.Replace("{{dogumyili}}", PlayerDataManager.GetChatVariableValue("dogum yili"));
        }

        if (text.Contains("{{dogum ayi yazi}}"))
        {
            text = text.Replace("{{dogum ayi yazi}}", SayiyiAyaCevir(kullaniciDogumAyi));
        }

        if (text.Contains("{{dogum gunu yazi}}"))
        {
            DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
            tarih = tarih.AddDays(0);
            var culture = new CultureInfo("tr-TR");
            var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);

            text = text.Replace("{{dogum gunu yazi}}", gunCeviri.ToString());
        }

        for (int i = 0; i < PlayerDataManager.datas.chatDegiskenleri.Count; i++)
        {

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_ilkharfbuyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_ilkharfbuyuk}}", PlayerDataManager.GetChatVariableValue(PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi, true));
            }

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_ilkHarfBuyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_ilkHarfBuyuk}}", PlayerDataManager.GetChatVariableValue(PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi, true));
            }

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_buyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_buyuk}}", PlayerDataManager.datas.chatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_Buyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_Buyuk}}", PlayerDataManager.datas.chatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_buyukharf}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_buyukharf}}", PlayerDataManager.datas.chatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_BuyukHarf}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "_BuyukHarf}}", PlayerDataManager.datas.chatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.datas.chatDegiskenleri[i].degiskenAdi + "}}", PlayerDataManager.datas.chatDegiskenleri[i].degiskenDegeri.ToLower());
            }
        }

        for (int i = 0; i < PlayerDataManager.yerelChatDegiskenleri.Count; i++)
        {

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_ilkharfbuyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_ilkharfbuyuk}}", PlayerDataManager.GetChatVariableValue(PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi, true));
            }

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_ilkHarfBuyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_ilkHarfBuyuk}}", PlayerDataManager.GetChatVariableValue(PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi, true));
            }

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_buyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_buyuk}}", PlayerDataManager.yerelChatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_Buyuk}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_Buyuk}}", PlayerDataManager.yerelChatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_buyukharf}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_buyukharf}}", PlayerDataManager.yerelChatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_BuyukHarf}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "_BuyukHarf}}", PlayerDataManager.yerelChatDegiskenleri[i].degiskenDegeri.ToUpper());
            }

            if (text.Contains("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "}}"))
            {
                text = text.Replace("{{" + PlayerDataManager.yerelChatDegiskenleri[i].degiskenAdi + "}}", PlayerDataManager.yerelChatDegiskenleri[i].degiskenDegeri.ToLower());
            }
        }

        for (int i = 0; i < defaultVariables.degiskenler.Count; i++)
        {
            if (text.Contains("{{" + defaultVariables.degiskenler[i].degiskenAdi + "}}"))
            {
                text = text.Replace("{{" + defaultVariables.degiskenler[i].degiskenAdi + "}}", defaultVariables.degiskenler[i].degiskenDegeri.ToLower());
            }
        }

        return text;
    }

    public string Sayi(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{sayi".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{sayi", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{sayi"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;
                    int firstCommaIndex = 0;
                    int secondCommaIndex = 0;
                    int lastNumberIndex = 0;

                    string degiskenTamHali = "";

                    int firstNumber = 0;
                    int secondNumber = 0;

                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {
                                                if (textChar[a].ToString() == "," || textChar[a].ToString() == "_")
                                                {
                                                    if (firstCommaIndex == 0)
                                                    {
                                                        firstCommaIndex = a;
                                                    }
                                                    else
                                                    {
                                                        secondCommaIndex = a;
                                                    }
                                                }

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    lastNumberIndex = a - 2;
                                                    completed = true;

                                                    string firstNumberString = "";
                                                    for (int b = firstCommaIndex + 1; b < secondCommaIndex; b++)
                                                    {
                                                        firstNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(firstNumberString, out firstNumber);

                                                    string secondNumberString = "";
                                                    for (int b = secondCommaIndex + 1; b < lastNumberIndex + 1; b++)
                                                    {
                                                        secondNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(secondNumberString, out secondNumber);

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    //Sayi butonunda sınırlar dahildir
                                                    int secilenSayi = UnityEngine.Random.Range(firstNumber, secondNumber + 1);

                                                    text = ReplaceOneTime(degiskenTamHali, secilenSayi.ToString(), text);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }

    public string SabitSayi(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{sabit_sayi".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{sabit_sayi", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{sabit_sayi"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;
                    int firstCommaIndex = 0;
                    int secondCommaIndex = 0;
                    int lastNumberIndex = 0;

                    string degiskenTamHali = "";
                    string degiskenTamHali2 = "";

                    int firstNumber = 0;
                    int secondNumber = 0;

                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {
                                                int tryParse = 5;
                                                if (textChar[a].ToString() == "," || (textChar[a].ToString() == "_" && int.TryParse(textChar[a + 1].ToString(), out tryParse)))
                                                {
                                                    if (firstCommaIndex == 0)
                                                    {
                                                        firstCommaIndex = a;
                                                    }
                                                    else
                                                    {
                                                        secondCommaIndex = a;
                                                    }
                                                }

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    lastNumberIndex = a - 2;
                                                    completed = true;

                                                    string firstNumberString = "";
                                                    for (int b = firstCommaIndex + 1; b < secondCommaIndex; b++)
                                                    {
                                                        firstNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(firstNumberString, out firstNumber);

                                                    string secondNumberString = "";
                                                    for (int b = secondCommaIndex + 1; b < lastNumberIndex + 1; b++)
                                                    {
                                                        secondNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(secondNumberString, out secondNumber);

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        if (b != firstCommaIndex)
                                                        {
                                                            degiskenTamHali += textChar[b].ToString();
                                                            degiskenTamHali2 += textChar[b].ToString();
                                                        }
                                                        else
                                                        {
                                                            if (textChar[b] == ',')
                                                            {
                                                                degiskenTamHali += textChar[b].ToString();
                                                                degiskenTamHali2 += '_'.ToString();
                                                            }
                                                            else
                                                            {
                                                                degiskenTamHali += textChar[b].ToString();
                                                                degiskenTamHali2 += ','.ToString();
                                                            }
                                                        }
                                                    }

                                                    int secilenSayi = UnityEngine.Random.Range(firstNumber, secondNumber + 1);

                                                    text = text.Replace(degiskenTamHali, secilenSayi.ToString());
                                                    text = text.Replace(degiskenTamHali2, secilenSayi.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string SabitSayiV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{sabit sayi".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{sabit sayi", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{sabit sayi"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;
                    int firstCommaIndex = 0;
                    int secondCommaIndex = 0;
                    int lastNumberIndex = 0;

                    string degiskenTamHali = "";
                    string degiskenTamHali2 = "";

                    int firstNumber = 0;
                    int secondNumber = 0;

                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {
                                                int tryParse = 5;
                                                if (textChar[a].ToString() == "," || (textChar[a].ToString() == "_" && int.TryParse(textChar[a + 1].ToString(), out tryParse)))
                                                {
                                                    if (firstCommaIndex == 0)
                                                    {
                                                        firstCommaIndex = a;
                                                    }
                                                    else
                                                    {
                                                        secondCommaIndex = a;
                                                    }
                                                }

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    lastNumberIndex = a - 2;
                                                    completed = true;

                                                    string firstNumberString = "";
                                                    for (int b = firstCommaIndex + 1; b < secondCommaIndex; b++)
                                                    {
                                                        firstNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(firstNumberString, out firstNumber);

                                                    string secondNumberString = "";
                                                    for (int b = secondCommaIndex + 1; b < lastNumberIndex + 1; b++)
                                                    {
                                                        secondNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(secondNumberString, out secondNumber);

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        if (b != firstCommaIndex)
                                                        {
                                                            degiskenTamHali += textChar[b].ToString();
                                                            degiskenTamHali2 += textChar[b].ToString();
                                                        }
                                                        else
                                                        {
                                                            if (textChar[b] == ',')
                                                            {
                                                                degiskenTamHali += textChar[b].ToString();
                                                                degiskenTamHali2 += '_'.ToString();
                                                            }
                                                            else
                                                            {
                                                                degiskenTamHali += textChar[b].ToString();
                                                                degiskenTamHali2 += ','.ToString();
                                                            }
                                                        }
                                                    }

                                                    int secilenSayi = UnityEngine.Random.Range(firstNumber, secondNumber + 1);

                                                    text = text.Replace(degiskenTamHali, secilenSayi.ToString());
                                                    text = text.Replace(degiskenTamHali2, secilenSayi.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string SabitSayiV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{sabitsayi".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{sabitsayi", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{sabitsayi"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;
                    int firstCommaIndex = 0;
                    int secondCommaIndex = 0;
                    int lastNumberIndex = 0;

                    string degiskenTamHali = "";
                    string degiskenTamHali2 = "";

                    int firstNumber = 0;
                    int secondNumber = 0;

                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {
                                                int tryParse = 5;
                                                if (textChar[a].ToString() == "," || (textChar[a].ToString() == "_" && int.TryParse(textChar[a + 1].ToString(), out tryParse)))
                                                {
                                                    if (firstCommaIndex == 0)
                                                    {
                                                        firstCommaIndex = a;
                                                    }
                                                    else
                                                    {
                                                        secondCommaIndex = a;
                                                    }
                                                }

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    lastNumberIndex = a - 2;
                                                    completed = true;

                                                    string firstNumberString = "";
                                                    for (int b = firstCommaIndex + 1; b < secondCommaIndex; b++)
                                                    {
                                                        firstNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(firstNumberString, out firstNumber);

                                                    string secondNumberString = "";
                                                    for (int b = secondCommaIndex + 1; b < lastNumberIndex + 1; b++)
                                                    {
                                                        secondNumberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(secondNumberString, out secondNumber);

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        if (b != firstCommaIndex)
                                                        {
                                                            degiskenTamHali += textChar[b].ToString();
                                                            degiskenTamHali2 += textChar[b].ToString();
                                                        }
                                                        else
                                                        {
                                                            if (textChar[b] == ',')
                                                            {
                                                                degiskenTamHali += textChar[b].ToString();
                                                                degiskenTamHali2 += '_'.ToString();
                                                            }
                                                            else
                                                            {
                                                                degiskenTamHali += textChar[b].ToString();
                                                                degiskenTamHali2 += ','.ToString();
                                                            }
                                                        }
                                                    }

                                                    int secilenSayi = UnityEngine.Random.Range(firstNumber, secondNumber + 1);

                                                    text = text.Replace(degiskenTamHali, secilenSayi.ToString());
                                                    text = text.Replace(degiskenTamHali2, secilenSayi.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    

    public string AySec(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{ay_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{ay_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{ay_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;
                    
                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var ayCeviri = culture.DateTimeFormat.GetMonthName(tarih.Month);
                                                    ay = ayCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string AySecV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{ay,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{ay,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{ay,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var ayCeviri = culture.DateTimeFormat.GetMonthName(tarih.Month);
                                                    ay = ayCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string GunSec(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{gun_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{gun_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{gun_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddDays(gunSayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);
                                                    gun = gunCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string GunSecV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{gun,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{gun,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{gun,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddDays(gunSayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);
                                                    gun = gunCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string YilSec(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{yil_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{yil_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{yil_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yil = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out yil);

                                                    yil = System.DateTime.Now.Year + yil;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yil.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string YilSecV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{yil,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{yil,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{yil,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yil = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out yil);

                                                    yil = System.DateTime.Now.Year + yil;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    Debug.Log(degiskenTamHali);
                                                    text = text.Replace(degiskenTamHali, yil.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string AySecSayi(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{aysayi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{aysayi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{aysayi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string AySecSayiV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{aysayi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{aysayi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{aysayi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string GunSecSayi(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{gunsayi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{gunsayi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{gunsayi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    gun = ((int)tarih.Day).ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string GunSecSayiV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{gun sayi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{gun sayi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{gun sayi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    gun = ((int)tarih.Day).ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string GunSecSayiV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{gunsayi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{gunsayi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{gunsayi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    gun = ((int)tarih.Day).ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string GunSecSayiV4(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{gun sayi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{gun sayi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{gun sayi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    gun = ((int)tarih.Day).ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string DogumAyiYaziyla(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum ayi yazi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum ayi yazi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum ayi yazi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = SayiyiAyaCevir(tarih.Month);

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumAyiYaziylaV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumayiyazi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumayiyazi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumayiyazi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumAyiYaziylaV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum ayi yazi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum ayi yazi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum ayi yazi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumAyiYaziylaV4(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumayiyazi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumayiyazi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumayiyazi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string DogumGunuYaziyla(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum gunu yazi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum gunu yazi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum gunu yazi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);
                                                    gun = gunCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumGunuYaziylaV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumgunuyazi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumgunuyazi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumgunuyazi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);
                                                    gun = gunCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumGunuYaziylaV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum gunu yazi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum gunu yazi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum gunu yazi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);
                                                    gun = gunCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumGunuYaziylaV4(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumgunuyazi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumgunuyazi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumgunuyazi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var gunCeviri = culture.DateTimeFormat.GetDayName(tarih.DayOfWeek);
                                                    gun = gunCeviri.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string DogumYili(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum yili_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum yili_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum yili_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yil = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out yil);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    yil = kullaniciDogumYili + yil;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yil.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumYiliV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumyili_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumyili_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumyili_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yil = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out yil);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    yil = kullaniciDogumYili + yil;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yil.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumYiliV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum yili,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum yili,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum yili,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yil = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out yil);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    yil = kullaniciDogumYili + yil;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yil.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumYiliV4(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumyili,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumyili,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumyili,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yil = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out yil);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    yil = kullaniciDogumYili + yil;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yil.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string DogumAyi(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum ayi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum ayi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum ayi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumAyiV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumayi_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumayi_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumayi_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumAyiV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum ayi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum ayi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum ayi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumAyiV4(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumayi,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumayi,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumayi,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddMonths(aySayisi);
                                                    ay = tarih.Month.ToString();

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, ay);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string DogumGunu(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum gunu_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum gunu_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum gunu_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    if ((int)tarih.DayOfWeek != 0)
                                                    {
                                                        gun = ((int)tarih.DayOfWeek).ToString();
                                                    }
                                                    else
                                                    {
                                                        gun = (7).ToString();
                                                    }

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumGunuV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumgunu_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumgunu_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumgunu_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    if ((int)tarih.DayOfWeek != 0)
                                                    {
                                                        gun = ((int)tarih.DayOfWeek).ToString();
                                                    }
                                                    else
                                                    {
                                                        gun = (7).ToString();
                                                    }

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumGunuV3(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogum gunu,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogum gunu,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogum gunu,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    if ((int)tarih.DayOfWeek != 0)
                                                    {
                                                        gun = ((int)tarih.DayOfWeek).ToString();
                                                    }
                                                    else
                                                    {
                                                        gun = (7).ToString();
                                                    }

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string DogumGunuV4(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{dogumgunu,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{dogumgunu,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{dogumgunu,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int gunSayisi = 0;
                    string gun = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out gunSayisi);

                                                    int kullaniciDogumGunu;
                                                    int kullaniciDogumAyi;
                                                    int kullaniciDogumYili;

                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out kullaniciDogumYili);

                                                    if (kullaniciDogumGunu <= 0)
                                                        kullaniciDogumGunu = 1;

                                                    if (kullaniciDogumAyi <= 0)
                                                        kullaniciDogumAyi = 1;

                                                    if (kullaniciDogumYili <= 0)
                                                        kullaniciDogumYili = 1950;

                                                    DateTime tarih = new DateTime(kullaniciDogumYili, kullaniciDogumAyi, kullaniciDogumGunu);
                                                    tarih = tarih.AddDays(gunSayisi);

                                                    if ((int)tarih.DayOfWeek != 0)
                                                    {
                                                        gun = ((int)tarih.DayOfWeek).ToString();
                                                    }
                                                    else
                                                    {
                                                        gun = (7).ToString();
                                                    }

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, gun);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string GecenSimdikiGelecekAy(string text)
    {
        int simdikiAy = System.DateTime.Now.Month;
        int gecenAy = simdikiAy - 1;
        int gelecekAy = simdikiAy + 1;

        if (gecenAy <= 0)
            gecenAy = 12;

        if (gelecekAy > 12)
            gelecekAy = 1;

        if (text.Contains("{{simdiki_ay}}"))
        {
            text = text.Replace("{{simdiki_ay}}", SayiyiAyaCevir(simdikiAy));
        }
        if (text.Contains("{{simdiki ay}}"))
        {
            text = text.Replace("{{simdiki ay}}", SayiyiAyaCevir(simdikiAy));
        }


        if (text.Contains("{{gecen_ay}}"))
        {
            text = text.Replace("{{gecen_ay}}", SayiyiAyaCevir(gecenAy));
        }
        if (text.Contains("{{gecen ay}}"))
        {
            text = text.Replace("{{gecen ay}}", SayiyiAyaCevir(gecenAy));
        }


        if (text.Contains("{{gelecek_ay}}"))
        {
            text = text.Replace("{{gelecek_ay}}", SayiyiAyaCevir(gelecekAy));
        }
        if (text.Contains("{{gelecek ay}}"))
        {
            text = text.Replace("{{gelecek ay}}", SayiyiAyaCevir(gelecekAy));
        }

        return text;
    }


    public string MevsimSec(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{mevsim_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{mevsim_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{mevsim_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";
                    string mevsim = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddMonths(aySayisi * 3);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var ayCeviri = culture.DateTimeFormat.GetMonthName(tarih.Month);
                                                    ay = ayCeviri.ToString();

                                                    if (i == 0)
                                                    {
                                                        mevsim = AyiMevsimeCevir(ay, "firstLetter");
                                                    }
                                                    else 
                                                    {
                                                        mevsim = AyiMevsimeCevir(ay, "lower");
                                                    }

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = ReplaceOneTime(degiskenTamHali, mevsim, text);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string MevsimSecV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{mevsim,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{mevsim,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{mevsim,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int aySayisi = 0;
                    string ay = "";
                    string mevsim = "";

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;

                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }
                                                    int.TryParse(numberString, out aySayisi);

                                                    DateTime tarih = DateTime.Now;
                                                    tarih = tarih.AddMonths(aySayisi * 3);
                                                    var culture = new CultureInfo("tr-TR");
                                                    var ayCeviri = culture.DateTimeFormat.GetMonthName(tarih.Month);
                                                    ay = ayCeviri.ToString();

                                                    if (i == 0)
                                                    {
                                                        mevsim = AyiMevsimeCevir(ay, "firstLetter");
                                                    }
                                                    else
                                                    {
                                                        mevsim = AyiMevsimeCevir(ay, "lower");
                                                    }

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = ReplaceOneTime(degiskenTamHali, mevsim, text);
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string YasSec(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{yas_".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{yas_", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{yas_"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yasFark = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }

                                                    int.TryParse(numberString, out yasFark);
                                                    int yas = 0;
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("yas"), out yas);

                                                    yas = yas + yasFark;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yas.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }
    public string YasSecV2(string text)
    {
        char[] textChar = text.ToCharArray();
        char[] valueChar = "{{yas,".ToCharArray();

        int metindekiDegiskenSayisi = GetWordCountInString("{{yas,", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            bool completed = false;

            if (text.Contains("{{yas,"))
            {
                for (int i = 0; i < textChar.Length; i++)
                {
                    int endIndex = 0;

                    int yasFark = 0;

                    string degiskenTamHali = "";


                    if (!completed)
                    {
                        if (textChar[i] == valueChar[0])
                        {
                            for (int u = 0; u < valueChar.Length; u++)
                            {
                                if (textChar[i + u] == valueChar[0 + u])
                                {
                                    if (u == valueChar.Length - 1)
                                    {
                                        for (int a = i; a < textChar.Length; a++)
                                        {
                                            if (a != 0)
                                            {

                                                if (textChar[a].ToString() == "}" && textChar[a - 1].ToString() == "}")
                                                {
                                                    endIndex = a;
                                                    completed = true;

                                                    string numberString = "";
                                                    for (int b = u + i + 1; b < a - 1; b++)
                                                    {
                                                        numberString += textChar[b].ToString();
                                                    }

                                                    int.TryParse(numberString, out yasFark);
                                                    int yas = 0;
                                                    int.TryParse(PlayerDataManager.GetChatVariableValue("yas"), out yas);

                                                    yas = yas + yasFark;

                                                    for (int b = i; b < endIndex + 1; b++)
                                                    {
                                                        degiskenTamHali += textChar[b].ToString();
                                                    }

                                                    text = text.Replace(degiskenTamHali, yas.ToString());
                                                    textChar = text.ToCharArray();

                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == textChar.Length - 1)
                                                    {
                                                        completed = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return text;
    }


    public string RastgeleBurc(string text)
    {
        if (text.Contains("{{rastgeleburc}}"))
        {
            int kullaniciDogumGunu = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);

            int kullaniciDogumAyi = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);

            string kullaniciBurcu = Burc.BurcHesapla(kullaniciDogumGunu, kullaniciDogumAyi);

            List<string> burclar = Burc.TumBurclarListe();

            for (int i = 0; i < burclar.Count; i++)
            {
                if (kullaniciBurcu == burclar[i])
                {
                    burclar.RemoveAt(i);
                }
            }

            string secilenBurc = burclar[UnityEngine.Random.Range(0, burclar.Count)];

            // copy the string as UTF-8 bytes.
            byte[] utf8Bytes = Encoding.UTF8.GetBytes(secilenBurc);

            secilenBurc =  Encoding.UTF8.GetString(utf8Bytes, 0, utf8Bytes.Length);

            text = text.Replace("{{rastgeleburc}}", secilenBurc);
        }
        return text;
    }

    public string RastgeleBurcV2(string text)
    {
        if (text.Contains("{{rastgele burc}}"))
        {
            int kullaniciDogumGunu = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);

            int kullaniciDogumAyi = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);

            string kullaniciBurcu = Burc.BurcHesapla(kullaniciDogumGunu, kullaniciDogumAyi);

            List<string> burclar = Burc.TumBurclarListe();

            for (int i = 0; i < burclar.Count; i++)
            {
                if (kullaniciBurcu == burclar[i])
                {
                    burclar.RemoveAt(i);
                }
            }

            string secilenBurc = burclar[UnityEngine.Random.Range(0, burclar.Count)];

            // copy the string as UTF-8 bytes.
            byte[] utf8Bytes = Encoding.UTF8.GetBytes(secilenBurc);

            secilenBurc = Encoding.UTF8.GetString(utf8Bytes, 0, utf8Bytes.Length);

            text = text.Replace("{{rastgele burc}}", secilenBurc);
        }
        return text;
    }

    public bool CheckForceMultipleLine(string text)
    {
        if (text.Contains("{{altsatir}}") || text.Contains("{{alt satir}}") || text.Contains("\n"))
        {
            return true;
        }
        else 
        {
            return false;
        }
    }

    public string AltSatiraGec(string text)
    {
        if (text.Contains("{{altsatir}}"))
        {
            text = text.Replace("{{altsatir}}", "\n\n");
        }

        if (text.Contains("{{alt satir}}"))
        {
            text = text.Replace("{{alt satir}}", "\n\n");
        }

        return text;
    }

    public string IsimHarfleri(string text)
    {
        char[] isimChar = PlayerDataManager.GetChatVariableValue("isim").ToUpper().ToCharArray();

        if (isimChar.Length > 0)
        {
            if (text.Contains("{{isimilk}}"))
            {
                if (isimChar[0].ToString() != " ")
                {
                    text = text.Replace("{{isimilk}}", isimChar[0].ToString());
                }
                else 
                {
                    text = text.Replace("{{isimilk}}", isimChar[1].ToString());
                }
            }
            if (text.Contains("{{isim ilk}}"))
            {
                if (isimChar[0].ToString() != " ")
                {
                    text = text.Replace("{{isim ilk}}", isimChar[0].ToString());
                }
                else
                {
                    text = text.Replace("{{isim ilk}}", isimChar[1].ToString());
                }
            }


            if (text.Contains("{{isimson}}"))
            {
                if (isimChar[isimChar.Length - 1].ToString() != " ")
                {
                    text = text.Replace("{{isimson}}", isimChar[isimChar.Length - 1].ToString());
                }
                else 
                {
                    text = text.Replace("{{isimson}}", isimChar[isimChar.Length - 2].ToString());
                }

            }
            if (text.Contains("{{isim son}}"))
            {
                if (isimChar[isimChar.Length - 1].ToString() != " ")
                {
                    text = text.Replace("{{isim son}}", isimChar[isimChar.Length - 1].ToString());
                }
                else
                {
                    text = text.Replace("{{isim son}}", isimChar[isimChar.Length - 2].ToString());
                }

            }
        }

        if (isimChar.Length > 1)
        {
            if (text.Contains("{{isimiki}}"))
            {
                if (isimChar[1].ToString() != " ")
                {
                    text = text.Replace("{{isimiki}}", isimChar[1].ToString());
                }
                else 
                {
                    text = text.Replace("{{isimiki}}", isimChar[2].ToString());
                }
            }
            if (text.Contains("{{isim iki}}"))
            {
                if (isimChar[1].ToString() != " ")
                {
                    text = text.Replace("{{isim iki}}", isimChar[1].ToString());
                }
                else
                {
                    text = text.Replace("{{isim iki}}", isimChar[2].ToString());
                }
            }
        }

        return text;
    }

    public string SoyIsimHarfleri(string text)
    {
        char[] isimChar = PlayerDataManager.GetChatVariableValue("soyisim").ToUpper().ToCharArray();

        if (isimChar.Length > 0)
        {
            if (text.Contains("{{soyisimilk}}"))
            {
                if (isimChar[0].ToString() != " ")
                {
                    text = text.Replace("{{soyisimilk}}", isimChar[0].ToString());
                }
                else
                {
                    text = text.Replace("{{soyisimilk}}", isimChar[1].ToString());
                }
            }
            if (text.Contains("{{soyisim ilk}}"))
            {
                if (isimChar[0].ToString() != " ")
                {
                    text = text.Replace("{{soyisim ilk}}", isimChar[0].ToString());
                }
                else
                {
                    text = text.Replace("{{soyisim ilk}}", isimChar[1].ToString());
                }
            }


            if (text.Contains("{{soyisimson}}"))
            {
                if (isimChar[isimChar.Length - 1].ToString() != " ")
                {
                    text = text.Replace("{{soyisimson}}", isimChar[isimChar.Length - 1].ToString());
                }
                else
                {
                    text = text.Replace("{{soyisimson}}", isimChar[isimChar.Length - 2].ToString());
                }
            }
            if (text.Contains("{{soyisim son}}"))
            {
                if (isimChar[isimChar.Length - 1].ToString() != " ")
                {
                    text = text.Replace("{{soyisim son}}", isimChar[isimChar.Length - 1].ToString());
                }
                else
                {
                    text = text.Replace("{{soyisim son}}", isimChar[isimChar.Length - 2].ToString());
                }
            }
        }

        if (isimChar.Length > 1)
        {
            if (text.Contains("{{soyisimiki}}"))
            {
                if (isimChar[1].ToString() != " ")
                {
                    text = text.Replace("{{soyisimiki}}", isimChar[1].ToString());
                }
                else
                {
                    text = text.Replace("{{soyisimiki}}", isimChar[2].ToString());
                }
            }
            if (text.Contains("{{soyisim iki}}"))
            {
                if (isimChar[1].ToString() != " ")
                {
                    text = text.Replace("{{soyisim iki}}", isimChar[1].ToString());
                }
                else
                {
                    text = text.Replace("{{soyisim iki}}", isimChar[2].ToString());
                }
            }
        }

        return text;
    }

    public string IsimeEkEkle (string text)
    {
        if (text.Contains("{{isimcigim}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{isimcigim}}", isim + "cığım");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{isimcigim}}", isim + "cuğum");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{isimcigim}}", isim + "cigim");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{isimcigim}}", isim + "cüğüm");
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isimcigim}}"))
            {
                text = text.Replace("{{isimcigim}}", isim + "ciğim");
            }
        }

        return text;
    }

    //Yeniler

    public string XGundurHayatta(string text)
    {
        if (text.Contains("{{xgundur}}"))
        {
            int dogumYili = 0;
            int dogumAyi = 1;
            int dogumGunu = 1;

            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out dogumYili);
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out dogumAyi);
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out dogumGunu);

            Debug.Log(dogumYili);
            Debug.Log(dogumAyi);
            Debug.Log(dogumGunu);

            DateTime birthDate = new DateTime(dogumYili, dogumAyi, dogumGunu);

            double totalDayDifference = (DateTime.Today - birthDate).TotalDays;

            if (totalDayDifference < 0)
                totalDayDifference = 0;

            text = text.Replace("{{xgundur}}", totalDayDifference.ToString());
        }

        if (text.Contains("{{x gundur}}"))
        {
            int dogumYili = 0;
            int dogumAyi = 1;
            int dogumGunu = 1;

            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out dogumYili);
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out dogumAyi);
            int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out dogumGunu);

            DateTime birthDate = new DateTime(dogumYili, dogumAyi, dogumGunu);

            double totalDayDifference = (DateTime.Today - birthDate).TotalDays;

            if (totalDayDifference < 0)
                totalDayDifference = 0;

            text = text.Replace("{{x gundur}}", totalDayDifference.ToString());
        }
        return text;
    }

    public string IsimeEkEkleSin(string text)
    {
        if (text.Contains("{{isimsin}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{isimsin}}", isim + "'sın");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{isimsin}}", isim + "'sun");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{isimsin}}", isim + "'sin");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{isimsin}}", isim + "'sün");
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isimsin}}"))
            {
                text = text.Replace("{{isimsin}}", isim + "sin");
            }
        }

        return text;
    }

    public string IsimeEkEkleDin(string text)
    {
        if (text.Contains("{{isimdin}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{isimdin}}", isim + "'ydın");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isimdin}}", isim + "'ydun");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{isimdin}}", isim + "'ydin");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isimdin}}", isim + "'ydün");
                                }
                            }
                            else
                            {
                                if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    for (int s = 0; s < harflerFstk.Length; s++)
                                    {
                                        if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'tın");
                                            break;
                                        }
                                        else if (s == harflerFstk.Length - 1)
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'dın");
                                        }
                                    }
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    for (int s = 0; s < harflerFstk.Length; s++)
                                    {
                                        if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'tun");
                                            break;
                                        }
                                        else if (s == harflerFstk.Length - 1)
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'dun");
                                        }
                                    }
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    for (int s = 0; s < harflerFstk.Length; s++)
                                    {
                                        if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'tin");
                                            break;
                                        }
                                        else if (s == harflerFstk.Length - 1)
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'din");
                                        }
                                    }
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    for (int s = 0; s < harflerFstk.Length; s++)
                                    {
                                        if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'tün");
                                            break;
                                        }
                                        else if (s == harflerFstk.Length - 1)
                                        {
                                            text = text.Replace("{{isimdin}}", isim + "'dün");
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isimdin}}"))
            {
                text = text.Replace("{{isimdin}}", isim + "'din");
            }
        }

        return text;
    }

    public string IsimeEkEkleDe(string text)
    {
        if (text.Contains("{{isimde}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'ta");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'da");
                                    }
                                }
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'ta");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'da");
                                    }
                                }
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'te");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'de");
                                    }
                                }
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'te");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimde}}", isim + "'de");
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isimde}}"))
            {
                text = text.Replace("{{isimde}}", isim + "'de");
            }
        }

        return text;
    }

    public string IsimeEkEkleDen(string text)
    {
        if (text.Contains("{{isimden}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'tan");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'dan");
                                    }
                                }
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'tan");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'dan");
                                    }
                                }
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'ten");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'den");
                                    }
                                }
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (isimChar[isimChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'ten");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{isimden}}", isim + "'den");
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isimden}}"))
            {
                text = text.Replace("{{isimden}}", isim + "'den");
            }
        }

        return text;
    }

    public string IsimeEkEkleI(string text)
    {
        if (text.Contains("{{isimi}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'yı");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'yu");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'yi");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'yü");
                                }
                            }
                            else
                            {
                                if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'ı");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'u");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'i");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isimi}}", isim + "'ü");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isimi}}"))
            {
                text = text.Replace("{{isimi}}", isim + "'i");
            }
        }

        return text;
    }

    public string IsimeEkEkleE(string text)
    {
        if (text.Contains("{{isime}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'ya");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'ya");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'ye");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'ye");
                                }
                            }
                            else
                            {
                                if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'a");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'a");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'e");
                                }
                                else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{isime}}", isim + "'e");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{isime}}"))
            {
                text = text.Replace("{{isime}}", isim + "'e");
            }
        }

        return text;
    }

    //Mevcut Şehir
    public string SehreEkEkleE(string text)
    {
        if (text.Contains("{{kullanici sehrine}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("kullanici sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'ya");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'ya");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'ye");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'ye");
                                }
                            }
                            else
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'a");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'a");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'e");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrine}}", sehir + "'e");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{kullanici sehrine}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{kullanici sehrine}}"))
            {
                text = text.Replace("{{kullanici sehrine}}", sehir + "'e");
            }
        }

        return text;
    }

    public string SehreEkEkleDe(string text)
    {
        if (text.Contains("{{kullanici sehrinde}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("kullanici sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'ta");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'da");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'ta");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'da");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'te");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'de");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'te");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinde}}", sehir + "'de");
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{kullanici sehrinden}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{kullanici sehrinde}}"))
            {
                text = text.Replace("{{kullanici sehrinde}}", sehir + "'de");
            }
        }

        return text;
    }

    public string SehreEkEkleDen(string text)
    {
        if (text.Contains("{{kullanici sehrinden}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("kullanici sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'tan");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'dan");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'tan");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'dan");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'ten");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'den");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'ten");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{kullanici sehrinden}}", sehir + "'den");
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{kullanici sehrinden}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{kullanici sehrinden}}"))
            {
                text = text.Replace("{{kullanici sehrinden}}", sehir + "'den");
            }
        }

        return text;
    }

    public string SehreEkEkleI(string text)
    {
        if (text.Contains("{{kullanici sehrini}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("kullanici sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'yı");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'yu");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'yi");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'yü");
                                }
                            }
                            else
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'ı");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'u");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'i");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrini}}", sehir + "'ü");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{kullanici sehrini}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{kullanici sehrini}}"))
            {
                text = text.Replace("{{kullanici sehrini}}", sehir + "'i");
            }
        }
        return text;
    }

    public string SehreEkEkleIn(string text)
    {
        if (text.Contains("{{kullanici sehrinin}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("kullanici sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'nın");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'nun");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'nin");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'nün");
                                }
                            }
                            else
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'ın");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'un");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'in");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{kullanici sehrinin}}", sehir + "'ün");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{kullanici sehrine}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{kullanici sehrine}}"))
            {
                text = text.Replace("{{kullanici sehrine}}", sehir + "'in");
            }
        }

        return text;
    }

    public string SehreEkEkleLi(string text)
    {
        if (text.Contains("{{kullanici sehrili}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("kullanici sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{kullanici sehrili}}", sehir + "lı");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{kullanici sehrili}}", sehir + "lu");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{kullanici sehrili}}", sehir + "li");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{kullanici sehrili}}", sehir + "lü");
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{kullanici sehrili}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{kullanici sehrili}}"))
            {
                text = text.Replace("{{kullanici sehrili}}", sehir + "li");
            }
        }

        return text;
    }

    //Doğum Şehri
    public string DogumSehrineEkEkleE(string text)
    {
        if (text.Contains("{{dogum sehrine}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'ya");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'ya");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'ye");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'ye");
                                }
                            }
                            else
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'a");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'a");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'e");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrine}}", sehir + "'e");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{dogum sehrine}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{dogum sehrine}}"))
            {
                text = text.Replace("{{dogum sehrine}}", sehir + "'e");
            }
        }

        return text;
    }

    public string DogumSehrineEkEkleDe(string text)
    {
        if (text.Contains("{{dogum sehrinde}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'ta");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'da");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'ta");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'da");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'te");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'de");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'te");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinde}}", sehir + "'de");
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{dogum sehrinden}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{dogum sehrinde}}"))
            {
                text = text.Replace("{{dogum sehrinde}}", sehir + "'de");
            }
        }

        return text;
    }

    public string DogumSehrineEkEkleDen(string text)
    {
        if (text.Contains("{{dogum sehrinden}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'tan");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'dan");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'tan");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'dan");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'ten");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'den");
                                    }
                                }
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                for (int s = 0; s < harflerFstk.Length; s++)
                                {
                                    if (sehirChar[sehirChar.Length - 1] == harflerFstk[s])
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'ten");
                                        break;
                                    }
                                    else if (s == harflerFstk.Length - 1)
                                    {
                                        text = text.Replace("{{dogum sehrinden}}", sehir + "'den");
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{dogum sehrinden}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{dogum sehrinden}}"))
            {
                text = text.Replace("{{dogum sehrinden}}", sehir + "'den");
            }
        }

        return text;
    }

    public string DogumSehrineEkEkleI(string text)
    {
        char[] kalinDarUnluler = { 'a', 'ı', };
        char[] kalinYuvarlakUnluler = { 'o', 'u' };
        char[] inceDarUnluler = { 'e', 'i' };
        char[] inceYuvarlakUnluler = { 'ö', 'ü' };
        char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
        char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
        string sehir = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
        char[] sehirChar = sehir.ToCharArray();

        for (int u = 0; u < sehirChar.Length; u++)
        {
            for (int a = 0; a < sesliHarfler.Length; a++)
            {
                if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                {
                    for (int b = 0; b < kalinDarUnluler.Length; b++)
                    {
                        if (u == 0)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'yı");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'yu");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'yi");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'yü");
                            }
                        }
                        else
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'ı");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'u");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'i");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrini}}", sehir + "'ü");
                            }
                        }
                    }
                    break;
                }
            }
        }

        //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
        //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{dogum sehrini}} gorunmesi sorun olacagi icin boyle yapilir.
        if (text.Contains("{{dogum sehrini}}"))
        {
            text = text.Replace("{{dogum sehrini}}", sehir + "'i");
        }

        return text;
    }

    public string DogumSehrineEkEkleIn(string text)
    {
        if (text.Contains("{{dogum sehrinin}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (u == 0)
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'nın");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'nun");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'nin");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'nün");
                                }
                            }
                            else
                            {
                                if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'ın");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'un");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'in");
                                }
                                else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                                {
                                    text = text.Replace("{{dogum sehrinin}}", sehir + "'ün");
                                }
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{dogum sehrine}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{dogum sehrine}}"))
            {
                text = text.Replace("{{dogum sehrine}}", sehir + "'in");
            }
        }

        return text;
    }

    public string DogumSehrineEkEkleLi(string text)
    {
        if (text.Contains("{{dogum sehrili}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            char[] harflerFstk = { 'f', 's', 't', 'k', 'ç', 'ş', 'h', 'p' };
            string sehir = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
            char[] sehirChar = sehir.ToCharArray();

            for (int u = 0; u < sehirChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (sehirChar[sehirChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (sehirChar[sehirChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrili}}", sehir + "lı");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrili}}", sehir + "lu");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrili}}", sehir + "li");
                            }
                            else if (sehirChar[sehirChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{dogum sehrili}}", sehir + "lü");
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{dogum sehrili}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{dogum sehrili}}"))
            {
                text = text.Replace("{{dogum sehrili}}", sehir + "li");
            }
        }

        return text;
    }

    public string BurcaEkEkleLuk(string text)
    {
        if (text.Contains("{{burclugunu}}"))
        {
            char[] kalinDarUnluler = { 'a', 'ı', };
            char[] kalinYuvarlakUnluler = { 'o', 'u' };
            char[] inceDarUnluler = { 'e', 'i' };
            char[] inceYuvarlakUnluler = { 'ö', 'ü' };
            char[] sesliHarfler = { 'a', 'ı', 'o', 'u', 'e', 'i', 'ö', 'ü' };
            string isim = PlayerDataManager.GetChatVariableValue("burc");
            char[] isimChar = isim.ToCharArray();

            for (int u = 0; u < isimChar.Length; u++)
            {
                for (int a = 0; a < sesliHarfler.Length; a++)
                {
                    if (isimChar[isimChar.Length - 1 - u] == sesliHarfler[a])
                    {
                        for (int b = 0; b < kalinDarUnluler.Length; b++)
                        {
                            if (isimChar[isimChar.Length - 1 - u] == kalinDarUnluler[b])
                            {
                                text = text.Replace("{{burclugunu}}", isim + "lığını");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == kalinYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{burclugunu}}", isim + "luğunu");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceDarUnluler[b])
                            {
                                text = text.Replace("{{burclugunu}}", isim + "liğini");
                            }
                            else if (isimChar[isimChar.Length - 1 - u] == inceYuvarlakUnluler[b])
                            {
                                text = text.Replace("{{burclugunu}}", isim + "lüğünü");
                            }
                        }
                        break;
                    }
                }
            }

            //eger hala {{isimcigim}} iceriyorsa. Bu sadece isim yalnizca sessiz harfetn olusursa gecerli olur.
            //Normal isimlerde bu onemli degildi. Ama eger kullanici yanlislikla sadece sessiz harfler kullanarak isim yazarsa {{isimcigim}} gorunmesi sorun olacagi icin boyle yapilir.
            if (text.Contains("{{burclugunu}}"))
            {
                text = text.Replace("{{burclugunu}}", isim + "liğini");
            }
        }

        return text;
    }

    public string SaatKac(string text)
    {
        int saat = System.DateTime.Now.Hour;
        string saatString = System.DateTime.Now.Hour.ToString();

        if (saat <= 9)
        {
            saatString = "0" + saatString;
        }

        if (text.Contains("{{saat kac}}"))
        {
            text = text.Replace("{{saat kac}}", saatString.ToString());
        }

        return text;
    }
    public string SaatKacV2(string text)
    {
        int saat = System.DateTime.Now.Hour;
        string saatString = System.DateTime.Now.Hour.ToString();

        if (saat <= 9)
        {
            saatString = "0" + saatString;
        }

        if (text.Contains("{{saatkac}}"))
        {
            text = text.Replace("{{saatkac}}", saatString.ToString());
        }

        return text;
    }

    public string SaatKacYazi(string text)
    {
        int saat = System.DateTime.Now.Hour;

        if (text.Contains("{{saat kac yazi}}"))
        {
            text = text.Replace("{{saat kac yazi}}", SaatiYaziyaCevir(saat));
        }

        return text;
    }
    public string SaatKacYaziV2(string text)
    {
        int saat = System.DateTime.Now.Hour;

        if (text.Contains("{{saatkacyazi}}"))
        {
            text = text.Replace("{{saatkacyazi}}", SaatiYaziyaCevir(saat));
        }

        return text;
    }

    public string TamSaat(string text)
    {
        int saat = System.DateTime.Now.Hour;
        string saatString = System.DateTime.Now.Hour.ToString();

        int dakika = System.DateTime.Now.Minute;
        string dakikaString = System.DateTime.Now.Minute.ToString();

        if (saat <= 9)
        {
            saatString = "0" + saatString;
        }

        if (dakika <= 9)
        {
            dakikaString = "0" + dakikaString;
        }

        if (text.Contains("{{tam saat}}"))
        {
            text = text.Replace("{{tam saat}}", saatString + ":" + dakikaString);
        }

        return text;
    }
    public string TamSaatV2(string text)
    {
        int saat = System.DateTime.Now.Hour;
        string saatString = System.DateTime.Now.Hour.ToString();

        int dakika = System.DateTime.Now.Minute;
        string dakikaString = System.DateTime.Now.Minute.ToString();

        if (saat <= 9)
        {
            saatString = "0" + saatString;
        }

        if (dakika <= 9)
        {
            dakikaString = "0" + dakikaString;
        }

        if (text.Contains("{{tamsaat}}"))
        {
            text = text.Replace("{{tamsaat}}", saatString + ":" + dakikaString);
        }

        return text;
    }

    public string RastgeleButonlar(string text)
    {
        foreach(DefaultVariables.RandomButton buton in defaultVariables.randomButtonlar )
        {
            while(text.Contains("{{" + buton.butonAdi + "}}"))
            {
                text = ReplaceOneTime("{{" + buton.butonAdi + "}}", buton.butonIcerigi[UnityEngine.Random.Range(0, buton.butonIcerigi.Count)], text);
            }
        }
        return text;
    }

    public string RastgeleButonlarSabit(string text)
    {
        foreach (DefaultVariables.RandomButton buton in defaultVariables.randomButtonlar)
        {
            if (text.Contains("{{sabit_" + buton.butonAdi + "}}"))
            {
                text = text.Replace("{{sabit_" + buton.butonAdi + "}}", buton.butonIcerigi[UnityEngine.Random.Range(0, buton.butonIcerigi.Count)]);
            }
        }
        return text;
    }

    public string IsimdekiHarfSayisi(string text)
    {
        string isim = PlayerDataManager.GetChatVariableValue("isim");
        char[] isimChar = isim.ToCharArray();

        char[] sesliHarfler = { 'a', 'e', 'ı', 'i', 'o', 'ö', 'u', 'ü' };
        char[] sessizHarfler = { 'b', 'c', 'ç', 'd', 'f', 'g', 'ğ', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'r', 's', 'ş', 't', 'v', 'y', 'z', 'q', 'w', 'x' };

        int sayi = 0;

        if (text.Contains("{{isim harf}}"))
        {
            sayi = isimChar.Length;
            text = text.Replace("{{isim harf}}", sayi.ToString());
        }
        if (text.Contains("{{isimharf}}"))
        {
            sayi = isimChar.Length;
            text = text.Replace("{{isimharf}}", sayi.ToString());
        }

        if (text.Contains("{{isim sesli harf}}"))
        {
            sayi = 0;
            foreach (char harf in sesliHarfler)
            {
                foreach (char isimHarf in isimChar)
                {
                    if (isimHarf == harf)
                    {
                        sayi += 1;
                    }
                }
            }
            text = text.Replace("{{isim sesli harf}}", sayi.ToString());
        }
        if (text.Contains("{{isimsesliharf}}"))
        {
            sayi = 0;
            foreach (char harf in sesliHarfler)
            {
                foreach (char isimHarf in isimChar)
                {
                    if (isimHarf == harf)
                    {
                        sayi += 1;
                    }
                }
            }
            text = text.Replace("{{isimsesliharf}}", sayi.ToString());
        }

        if (text.Contains("{{isim sessiz harf}}"))
        {
            sayi = 0;
            foreach (char harf in sessizHarfler)
            {
                foreach (char isimHarf in isimChar)
                {
                    if (isimHarf == harf)
                    {
                        sayi += 1;
                    }
                }
            }
            text = text.Replace("{{isim sessiz harf}}", sayi.ToString());
        }
        if (text.Contains("{{isimsessizharf}}"))
        {
            sayi = 0;
            foreach (char harf in sessizHarfler)
            {
                foreach (char isimHarf in isimChar)
                {
                    if (isimHarf == harf)
                    {
                        sayi += 1;
                    }
                }
            }
            text = text.Replace("{{isimsessizharf}}", sayi.ToString());
        }

        return text;
    }
    //******
    public string EnerjiMiktari(string text)
    {
        if (text.Contains("{{enerji}}"))
        {
            string energy = PlayerDataManager.datas.energy.ToString();

            text = text.Replace("{{enerji}}", energy);
        }
        return text;
    }

    public string KonsantrasyonMiktari(string text)
    {
        if (text.Contains("{{kons}}"))
        {
            string konsantrasyon = PlayerDataManager.datas.konsantrasyon.ToString();

            text = text.Replace("{{kons}}", konsantrasyon);
        }
        return text;
    }

    public string IsimeHanimBeyEkle(string text)
    {
        if (text.Contains("{{isim hanim/bey}}"))
        {
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            string cinsiyet = PlayerDataManager.GetChatVariableValue("cinsiyet");

            if (cinsiyet == "erkek")
            {
                text = text.Replace("{{isim hanim/bey}}", isim + " " + "Bey");
            }
            else if (cinsiyet == "kadın")
            {
                text = text.Replace("{{isim hanim/bey}}", isim + " " + "Hanım");
            }
            else
            {
                text = text.Replace("{{isim hanim/bey}}", isim);
            }
        }
        return text;
    }
    public string IsimeHanimBeyEkleV2(string text)
    {
        if (text.Contains("{{isimhanim/bey}}"))
        {
            string isim = PlayerDataManager.GetChatVariableValue("isim", true);
            string cinsiyet = PlayerDataManager.GetChatVariableValue("cinsiyet");

            if (cinsiyet == "erkek")
            {
                text = text.Replace("{{isimhanim/bey}}", isim + " " + "Bey");
            }
            else if (cinsiyet == "kadın")
            {
                text = text.Replace("{{isimhanim/bey}}", isim + " " + "Hanım");
            }
            else
            {
                text = text.Replace("{{isimhanim/bey}}", isim);
            }
        }

        return text;
    }

    public string KelimeGrubuSec(string text)
    {
        int metindekiDegiskenSayisi = GetWordCountInString("{{kelime, ", text);

        for (int z = 0; z < metindekiDegiskenSayisi+1; z++)
        {
            if (text.Contains("{{kelime, "))
            {
                char[] textChar = text.ToCharArray();
                char[] keyChar = "{{kelime, ".ToCharArray();

                string finalText = "";
                List<string> finalTexts = new List<string>();

                bool completed = false;

                for (int i = 0; i < textChar.Length; i++)
                {
                    if (!completed)
                    {
                        if (textChar[i] == keyChar[0])
                        {
                            for (int u = 0; u < keyChar.Length; u++)
                            {
                                if (textChar[i + u] == keyChar[0 + u])
                                {
                                    if (u == keyChar.Length - 1)
                                    {
                                        completed = true;

                                        List<int> cumleNoktlari = new List<int>();

                                        cumleNoktlari.Add(i + u + 1);

                                        for (int a = i + u + 1; a < textChar.Length; a++)
                                        {
                                            if (a + 1 <= textChar.Length - 2)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() + textChar[a + 2].ToString() == " | ")
                                                {
                                                    cumleNoktlari.Add(a + 2);
                                                }
                                            }

                                            if (a + 1 <= textChar.Length - 1)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() == "}}")
                                                {
                                                    cumleNoktlari.Add(a + 1);
                                                    break;
                                                }
                                            }
                                        }

                                        for (int a = 0; a < i; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        for (int a = 0; a < cumleNoktlari.Count; a++)
                                        {
                                            if (a != cumleNoktlari.Count - 1)
                                            {
                                                //ilk kelime icin bunu yap
                                                if (a == 0)
                                                {
                                                    finalTexts.Add("");

                                                    for (int b = cumleNoktlari[a]; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        finalTexts[a] += textChar[b].ToString();
                                                    }
                                                }
                                                else // fakat ikinci kelimeden itibaren diger kelimenin son noktasindan bir fazla ila baslamamiz gerektigi icin bu sekilde devam eder
                                                {
                                                    finalTexts.Add("");

                                                    for (int b = cumleNoktlari[a] + 1; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        finalTexts[a] += textChar[b].ToString();
                                                    }
                                                }
                                            }
                                        }

                                        int x = UnityEngine.Random.Range(0, finalTexts.Count);

                                        finalTexts[x] = finalTexts[x].Replace(" | ", "");
                                        finalTexts[x] = finalTexts[x].Replace("}}", "");

                                        finalText += finalTexts[x];

                                        for (int a = cumleNoktlari[cumleNoktlari.Count - 1] + 1; a < textChar.Length; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        text = finalText;

                                        break;
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }
        return text;
    }

    public string SabitKelimeGrubuSec(string text)
    {
        int metindekiDegiskenSayisi = GetWordCountInString("{{sabitkelime, ", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            if (text.Contains("{{sabitkelime, "))
            {
                char[] textChar = text.ToCharArray();
                char[] keyChar = "{{sabitkelime, ".ToCharArray();

                string finalText = "";
                List<string> finalTexts = new List<string>();

                bool completed = false;

                for (int i = 0; i < textChar.Length; i++)
                {
                    if (!completed)
                    {
                        if (textChar[i] == keyChar[0])
                        {
                            for (int u = 0; u < keyChar.Length; u++)
                            {
                                if (textChar[i + u] == keyChar[0 + u])
                                {
                                    if (u == keyChar.Length - 1)
                                    {
                                        completed = true;

                                        List<int> cumleNoktlari = new List<int>();

                                        cumleNoktlari.Add(i + u + 1);

                                        for (int a = i + u + 1; a < textChar.Length; a++)
                                        {
                                            if (a + 1 <= textChar.Length - 2)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() + textChar[a + 2].ToString() == " | ")
                                                {
                                                    cumleNoktlari.Add(a + 2);
                                                }
                                            }

                                            if (a + 1 <= textChar.Length - 1)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() == "}}")
                                                {
                                                    cumleNoktlari.Add(a + 1);
                                                    break;
                                                }
                                            }
                                        }

                                        for (int a = 0; a < i; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        for (int a = 0; a < cumleNoktlari.Count; a++)
                                        {
                                            if (a != cumleNoktlari.Count - 1)
                                            {
                                                //ilk kelime icin bunu yap
                                                if (a == 0)
                                                {
                                                    finalTexts.Add("");

                                                    for (int b = cumleNoktlari[a]; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        finalTexts[a] += textChar[b].ToString();
                                                    }
                                                }
                                                else // fakat ikinci kelimeden itibaren diger kelimenin son noktasindan bir fazla ila baslamamiz gerektigi icin bu sekilde devam eder
                                                {
                                                    finalTexts.Add("");

                                                    for (int b = cumleNoktlari[a] + 1; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        finalTexts[a] += textChar[b].ToString();
                                                    }
                                                }
                                            }
                                        }

                                        int x = UnityEngine.Random.Range(0, finalTexts.Count);

                                        finalTexts[x] = finalTexts[x].Replace(" | ", "");
                                        finalTexts[x] = finalTexts[x].Replace("}}", "");

                                        finalText += finalTexts[x];

                                        string buttonString = "";

                                        for (int a = i; a < cumleNoktlari[cumleNoktlari.Count - 1] + 1; a++)
                                        {
                                            buttonString += textChar[a].ToString();
                                        }
                           

                                        for (int a = cumleNoktlari[cumleNoktlari.Count - 1] + 1; a < textChar.Length; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        finalText = finalText.Replace(buttonString, finalTexts[x]);

                                        text = finalText;

                                        break;
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }
        return text;
    }

    public string SaateGoreKelimeGrubuSec(string text)
    {
        int metindekiDegiskenSayisi = GetWordCountInString("{{saat, ", text);

        for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
        {
            if (text.Contains("{{saat, "))
            {
                char[] textChar = text.ToCharArray();
                char[] keyChar = "{{saat, ".ToCharArray();

                string finalText = "";
                List<string> finalTexts = new List<string>();

                bool completed = false;

                for (int i = 0; i < textChar.Length; i++)
                {
                    if (!completed)
                    {
                        if (textChar[i] == keyChar[0])
                        {
                            for (int u = 0; u < keyChar.Length; u++)
                            {
                                if (textChar[i + u] == keyChar[0 + u])
                                {
                                    if (u == keyChar.Length - 1)
                                    {
                                        completed = true;

                                        List<int> cumleNoktlari = new List<int>();

                                        cumleNoktlari.Add(i + u + 1);

                                        for (int a = i + u + 1; a < textChar.Length; a++)
                                        {
                                            if (a + 1 <= textChar.Length - 2)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() + textChar[a + 2].ToString() == " | ")
                                                {
                                                    cumleNoktlari.Add(a + 2);
                                                }
                                            }

                                            if (a + 1 <= textChar.Length - 1)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() == "}}")
                                                {
                                                    cumleNoktlari.Add(a + 1);
                                                    break;
                                                }
                                            }
                                        }

                                        for (int a = 0; a < i; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        for (int a = 0; a < cumleNoktlari.Count; a++)
                                        {
                                            if (a != cumleNoktlari.Count - 1)
                                            {
                                                //ilk kelime icin bunu yap
                                                if (a == 0)
                                                {
                                                    finalTexts.Add("");

                                                    for (int b = cumleNoktlari[a]; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        finalTexts[a] += textChar[b].ToString();
                                                    }
                                                }
                                                else // fakat ikinci kelimeden itibaren diger kelimenin son noktasindan bir fazla ila baslamamiz gerektigi icin bu sekilde devam eder
                                                {
                                                    finalTexts.Add("");

                                                    for (int b = cumleNoktlari[a] + 1; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        finalTexts[a] += textChar[b].ToString();
                                                    }
                                                }
                                            }
                                        }

                                        //Kelime degiskeninden farkli olarak burada random degil saate gore secim yapilyor.

                                        int saat = DateTime.Now.Hour;
                                        int x = 0;

                                        if (saat >= 6 && saat < 11)
                                        {
                                            x = 0;
                                        }
                                        else if (saat >= 11 && saat < 14)
                                        {
                                            x = 1;
                                        }
                                        else if (saat >= 14 && saat < 18)
                                        {
                                            x = 2;
                                        }
                                        else if (saat >= 18 && saat < 20)
                                        {
                                            x = 3;
                                        }
                                        else if (saat >= 20 && saat <= 24 || (saat >= 0 && saat < 6))
                                        {
                                            x = 4;
                                        }

                                        finalTexts[x] = finalTexts[x].Replace(" | ", "");
                                        finalTexts[x] = finalTexts[x].Replace("}}", "");

                                        finalText += finalTexts[x];

                                        for (int a = cumleNoktlari[cumleNoktlari.Count - 1] + 1; a < textChar.Length; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        text = finalText;

                                        break;
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }
        return text;
    }

    public string DatayaGoreKelimeGrubuSec(string text)
    {
        if (text.Contains("{{data, "))
        {
            int metindekiDegiskenSayisi = GetWordCountInString("{{data, ", text);

            for (int z = 0; z < metindekiDegiskenSayisi + 1; z++)
            {
                char[] textChar = text.ToCharArray();
                char[] keyChar = "{{data, ".ToCharArray();

                string finalText = "";
                List<string> finalTexts = new List<string>();
                List<string> finalTextVariablesString = new List<string>();
                List<DataDegiskeni> finalTextVariables = new List<DataDegiskeni>();
                string defaultText = "";

                bool completed = false;

                for (int i = 0; i < textChar.Length; i++)
                {
                    if (!completed)
                    {
                        if (textChar[i] == keyChar[0])
                        {
                            for (int u = 0; u < keyChar.Length; u++)
                            {
                                if (textChar[i + u] == keyChar[0 + u])
                                {
                                    if (u == keyChar.Length - 1)
                                    {
                                        completed = true;

                                        List<int> cumleNoktlari = new List<int>();

                                        cumleNoktlari.Add(i + u + 1);

                                        for (int a = i + u + 1; a < textChar.Length; a++)
                                        {
                                            if (a + 1 <= textChar.Length - 2)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() + textChar[a + 2].ToString() == " | ")
                                                {
                                                    cumleNoktlari.Add(a + 2);
                                                }
                                            }

                                            if (a + 1 <= textChar.Length - 1)
                                            {
                                                if (textChar[a].ToString() + textChar[a + 1].ToString() == "}}")
                                                {
                                                    cumleNoktlari.Add(a + 1);
                                                    break;
                                                }
                                            }
                                        }

                                        for (int a = 0; a < i; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        for (int a = 0; a < cumleNoktlari.Count; a++)
                                        {
                                            if (a != cumleNoktlari.Count - 1)
                                            {
                                                //ilk kelime icin bunu yap
                                                if (a == 0)
                                                {
                                                    int variableCommaPosition = 0;
                                                    bool writeVirableName = true;

                                                    finalTexts.Add("");
                                                    finalTextVariablesString.Add("");
                                                    finalTextVariables.Add(new DataDegiskeni());
                               

                                                    for (int b = cumleNoktlari[a]; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        if (variableCommaPosition == 0)
                                                        {
                                                            if (textChar[b].ToString() != "+")
                                                            {
                                                                if (textChar[b].ToString() == ",")
                                                                {
                                                                    variableCommaPosition = b;
                                                                }
                                                                else
                                                                {
                                                                    if (textChar[b].ToString() != "=" && textChar[b].ToString() != "<" && textChar[b].ToString() != ">" && textChar[b].ToString() != "!")
                                                                    {
                                                                        if (writeVirableName)
                                                                        {
                                                                            finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].degiskenAdi += textChar[b].ToString();
                                                                        }
                                                                        else
                                                                        {
                                                                            finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].degiskenDegeri += textChar[b].ToString();
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        if (writeVirableName)
                                                                        {
                                                                            if (textChar[b].ToString() == "!" && textChar[b + 1].ToString() == "=")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.esitDegil;
                                                                            }
                                                                            else if (textChar[b].ToString() == ">" && textChar[b + 1].ToString() == "=")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.buyukEsit;
                                                                            }
                                                                            else if (textChar[b].ToString() == "<" && textChar[b + 1].ToString() == "=")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.kucukEsit;
                                                                            }
                                                                            else if (textChar[b].ToString() == ">")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.buyuk;
                                                                            }
                                                                            else if (textChar[b].ToString() == "<")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.kucuk;
                                                                            }
                                                                            else
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.esit;
                                                                            }
                                                                        }

                                                                        writeVirableName = false;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                finalTextVariables[a].degisken.Add(new ChatDegiskeni());
                                                                writeVirableName = true;
                                                            }
                                                        }
                                                        else
                                                        {
                                                            if (b > variableCommaPosition + 1)
                                                            {
                                                                finalTexts[a] += textChar[b].ToString();
                                                            }
                                                        }

    
                                                    }

                                                    //Default texte degisken yoktur. O yuzden textin tamami degisken adi olarak algilanir. Eger degisken adi var degeri yoksa bu sadece default texte olabilir. Bu durumda default deger alinir.
                                                    if (string.IsNullOrEmpty(finalTextVariables[a].degisken[0].degiskenDegeri))
                                                    {
                                                        defaultText = finalTextVariables[a].degisken[0].degiskenAdi;
                                                        finalTextVariablesString.RemoveAt(finalTextVariablesString.Count - 1);
                                                        finalTexts.RemoveAt(finalTexts.Count - 1);
                                                        finalTextVariables.RemoveAt(finalTextVariables.Count - 1);
                                                    }
                                                }
                                                else // fakat ikinci kelimeden itibaren diger kelimenin son noktasindan bir fazla ila baslamamiz gerektigi icin bu sekilde devam eder
                                                {
                                                    int variableCommaPosition = 0;
                                                    bool writeVirableName = true;

                                                    finalTexts.Add("");
                                                    finalTextVariablesString.Add("");
                                                    finalTextVariables.Add(new DataDegiskeni());

                                                    for (int b = cumleNoktlari[a] + 1; b < cumleNoktlari[a + 1] + 1; b++)
                                                    {
                                                        if (variableCommaPosition == 0)
                                                        {
                                                            if (textChar[b].ToString() != "+")
                                                            {
                                                                if (textChar[b].ToString() == ",")
                                                                {
                                                                    variableCommaPosition = b;
                                                                }
                                                                else
                                                                {
                                                                    if (textChar[b].ToString() != "=" && textChar[b].ToString() != "<" && textChar[b].ToString() != ">" && textChar[b].ToString() != "!")
                                                                    {
                                                                        if (writeVirableName)
                                                                        {
                                                                            finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].degiskenAdi += textChar[b].ToString();
                                                                        }
                                                                        else
                                                                        {
                                                                            finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].degiskenDegeri += textChar[b].ToString();
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        if (writeVirableName)
                                                                        {
                                                                            if (textChar[b].ToString() == "!" && textChar[b + 1].ToString() == "=")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.esitDegil;
                                                                            }
                                                                            else if (textChar[b].ToString() == ">" && textChar[b + 1].ToString() == "=")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.buyukEsit;
                                                                            }
                                                                            else if (textChar[b].ToString() == "<" && textChar[b + 1].ToString() == "=")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.kucukEsit;
                                                                            }
                                                                            else if (textChar[b].ToString() == ">")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.buyuk;
                                                                            }
                                                                            else if (textChar[b].ToString() == "<")
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.kucuk;
                                                                            }
                                                                            else
                                                                            {
                                                                                finalTextVariables[a].degisken[finalTextVariables[a].degisken.Count - 1].kontrolOperatoru = ChatDegiskeni.OperatorEnum.esit;
                                                                            }
                                                                        }

                                                                        writeVirableName = false;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                finalTextVariables[a].degisken.Add(new ChatDegiskeni());
                                                                writeVirableName = true;
                                                            }
                                                        }
                                                        else
                                                        {
                                                            if (b > variableCommaPosition + 1)
                                                            {
                                                                finalTexts[a] += textChar[b].ToString();
                                                            }
                                                        }



                                                    }

                                                    //Default texte degisken yoktur. O yuzden textin tamami degisken adi olarak algilanir. Eger degisken adi var degeri yoksa bu sadece default texte olabilir. Bu durumda default deger alinir.
                                                    if (string.IsNullOrEmpty(finalTextVariables[a].degisken[0].degiskenDegeri))
                                                    {
                                                        defaultText = finalTextVariables[a].degisken[0].degiskenAdi;
                                                        finalTextVariablesString.RemoveAt(finalTextVariablesString.Count - 1);
                                                        finalTexts.RemoveAt(finalTexts.Count - 1);
                                                        finalTextVariables.RemoveAt(finalTextVariables.Count - 1);
                                                    }
                                                }
                                            }
                                        }

                                        int totalCompatibleSentenes = 0;
                                        for (int q = 0; q < finalTextVariablesString.Count; q++)
                                        {
                                            //Saat ve yas degiskenlerinin diger degiskenlerden ayrilmasi ve ozel degiskenlere atanmasi
                                            #region yasSaatGunFarkiDegiskenleriAyarlama
                                            List<ChatDegiskeni> secilenSohbetDegiskenleri = new List<ChatDegiskeni>();

                                            ChatDegiskeni yasMaxDegiskeni = new ChatDegiskeni();
                                            ChatDegiskeni yasMinDegiskeni = new ChatDegiskeni();

                                            ChatDegiskeni saatMaxDegiskeni = new ChatDegiskeni();
                                            ChatDegiskeni saatMinDegiskeni = new ChatDegiskeni();

                                            ChatDegiskeni gunFarkiMaxDegiskeni = new ChatDegiskeni();
                                            ChatDegiskeni gunFarkiMinDegiskeni = new ChatDegiskeni();

                                            foreach (ChatDegiskeni element in finalTextVariables[q].degisken)
                                            {
                                                if (element.degiskenAdi != "yasmin")
                                                {
                                                    if (element.degiskenAdi != "yasmax")
                                                    {
                                                        if (element.degiskenAdi != "saatmin")
                                                        {
                                                            if (element.degiskenAdi != "saatmax")
                                                            {
                                                                if (element.degiskenAdi != "gunmin")
                                                                {
                                                                    if (element.degiskenAdi != "gunmax")
                                                                    {
                                                                        secilenSohbetDegiskenleri.Add(element);
                                                                    }
                                                                    else
                                                                    {
                                                                        gunFarkiMaxDegiskeni = element;
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    gunFarkiMinDegiskeni = element;
                                                                }
                                                            }
                                                            else
                                                            {
                                                                saatMaxDegiskeni = element;
                                                            }
                                                        }
                                                        else
                                                        {
                                                            saatMinDegiskeni = element;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        yasMaxDegiskeni = element;
                                                    }
                                                }
                                                else
                                                {
                                                    yasMinDegiskeni = element;
                                                }
                                            }

                                            int gerekenDegiskenlerLength = secilenSohbetDegiskenleri.Count;

                                            //Yas
                                            int yas = 0;
                                            int.TryParse(PlayerDataManager.GetChatVariableValue("yas"), out yas);

                                            int yasMin = 0;
                                            int yasMax = 100;
                                            int.TryParse(yasMinDegiskeni.degiskenDegeri, out yasMin);
                                            int.TryParse(yasMaxDegiskeni.degiskenDegeri, out yasMax);

                                            if (yasMax == 0)
                                                yasMax = 1000;

                                            bool yasAraligiCheck = false;

                                            if (yas >= yasMin && yas < yasMax)
                                            {
                                                yasAraligiCheck = true;
                                            }

                                            //Gun farki
                                            int gunFarki = 0;
                                            int.TryParse(PlayerDataManager.GetChatVariableValue("gun farki"), out gunFarki);//Bu degisken welcomeScreen classinda kaydedilir!

                                            int gunFarkiMin = 0;
                                            int gunFarkiMax = 100;
                                            int.TryParse(gunFarkiMinDegiskeni.degiskenDegeri, out gunFarkiMin);
                                            int.TryParse(gunFarkiMaxDegiskeni.degiskenDegeri, out gunFarkiMax);

                                            if (gunFarkiMax == 0)
                                                gunFarkiMax = 1000;

                                            bool gunFarkiAraligiCheck = false;

                                            if (gunFarki >= gunFarkiMin && gunFarki < gunFarkiMax)
                                            {
                                                gunFarkiAraligiCheck = true;
                                            }

                                            //Saat
                                            int saat = System.DateTime.Now.TimeOfDay.Hours;

                                            int saatMin = 0;
                                            int saatMax = 100;
                                            int.TryParse(saatMinDegiskeni.degiskenDegeri, out saatMin);
                                            int.TryParse(saatMaxDegiskeni.degiskenDegeri, out saatMax);

                                            if (saatMax == 0)
                                                saatMax = 1000;

                                            bool saatAraligiCheck = false;

                                            if (saat >= saatMin && saat < saatMax)
                                            {
                                                saatAraligiCheck = true;
                                            }
                                            #endregion

                                            if (gunFarkiAraligiCheck)
                                            {
                                                if (yasAraligiCheck)
                                                {
                                                    if (saatAraligiCheck)
                                                    {
                                                        if (secilenSohbetDegiskenleri.Count > 0)
                                                        {
                                                            for (int b = 0; b < secilenSohbetDegiskenleri.Count; b++)
                                                            {
                                                                if (PlayerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals(secilenSohbetDegiskenleri[b].degiskenAdi)) 
                                                                    || PlayerDataManager.yerelChatDegiskenleri.Exists(x => x.degiskenAdi.Equals(secilenSohbetDegiskenleri[b].degiskenAdi)))
                                                                {
                                                                    if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.esit)
                                                                    {
                                                                        if (secilenSohbetDegiskenleri[b].degiskenDegeri == PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[b].degiskenAdi))
                                                                        {
                                                                            if (b == finalTextVariables[q].degisken.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText;
                                                                                Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }

                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.esitDegil)
                                                                    {
                                                                        if (secilenSohbetDegiskenleri[b].degiskenDegeri != PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[b].degiskenAdi))
                                                                        {
                                                                            if (b == finalTextVariables[q].degisken.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText;
                                                                                Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyukEsit)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[b].degiskenAdi, true), out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 >= value2)
                                                                        {
                                                                            if (b == finalTextVariables[q].degisken.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucukEsit)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[b].degiskenAdi, true), out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 <= value2)
                                                                        {
                                                                            if (b == finalTextVariables[q].degisken.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyuk)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[b].degiskenAdi, true), out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 > value2)
                                                                        {
                                                                            if (b == finalTextVariables[q].degisken.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucuk)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[b].degiskenAdi, true), out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 < value2)
                                                                        {
                                                                            if (b == finalTextVariables[q].degisken.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    //eger bu bir degiskenin degil bir buton fonksiyonunun degeri sorgulaniyorsa
                                                                    string deger = OrtakButonlar("{{" + secilenSohbetDegiskenleri[b].degiskenAdi + "}}").ToLower();
                                                                    if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.esit)
                                                                    {
                                                                        if (secilenSohbetDegiskenleri[b].degiskenDegeri == deger)
                                                                        {
                                                                            if (b == secilenSohbetDegiskenleri.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.esitDegil)
                                                                    {
                                                                        if (secilenSohbetDegiskenleri[b].degiskenDegeri != deger)
                                                                        {
                                                                            if (b == secilenSohbetDegiskenleri.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyukEsit)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(deger, out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 >= value2)
                                                                        {
                                                                            if (b == secilenSohbetDegiskenleri.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucukEsit)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(deger, out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 <= value2)
                                                                        {
                                                                            if (b == secilenSohbetDegiskenleri.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyuk)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(deger, out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 > value2)
                                                                        {
                                                                            if (b == secilenSohbetDegiskenleri.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                    else if (secilenSohbetDegiskenleri[b].kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucuk)
                                                                    {
                                                                        int value1 = 0;
                                                                        int value2 = 0;

                                                                        int.TryParse(deger, out value1);
                                                                        int.TryParse(secilenSohbetDegiskenleri[b].degiskenDegeri, out value2);

                                                                        if (value1 < value2)
                                                                        {
                                                                            if (b == secilenSohbetDegiskenleri.Count - 1)
                                                                            {
                                                                                finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                                                finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                                                if (totalCompatibleSentenes != 0)
                                                                                    finalText += " ";

                                                                                finalText += finalTexts[q];
                                                                                totalCompatibleSentenes += 1;
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            if (q == finalTexts.Count - 1)
                                                                            {
                                                                                defaultText = defaultText.Replace("}}", "");
                                                                                defaultText = defaultText.Replace(" | ", "");
                                                                                finalText += defaultText; Debug.Log(secilenSohbetDegiskenleri[b].degiskenAdi);
                                                                            }
                                                                            break;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        else
                                                        {
                                                            finalTexts[q] = finalTexts[q].Replace(" | ", "");
                                                            finalTexts[q] = finalTexts[q].Replace("}}", "");

                                                            if (totalCompatibleSentenes != 0)
                                                                finalText += " ";

                                                            finalText += finalTexts[q];
                                                            totalCompatibleSentenes += 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        for (int a = cumleNoktlari[cumleNoktlari.Count - 1] + 1; a < textChar.Length; a++)
                                        {
                                            finalText += textChar[a].ToString();
                                        }

                                        text = finalText;

                                        break;
                                    }
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }
        return text;
    }

    public string GetRenderedText(string text)
    {
        string conteiningText = "";
        string key = "{{hafiza, ";

        if (text.Contains(key))
        {
            //{{hafiza, mod=yeni}}"
            int metindekiDegiskenSayisi = GetWordCountInString(key, text);
            Debug.Log(metindekiDegiskenSayisi);
            for (int i = 0; i < metindekiDegiskenSayisi; i++)
            {
                int startIndex = 0;
                int commaIndex = 0;
                int equalSignIndex = 0;
                int endIndex = 0;

                startIndex = text.IndexOf(key);
                commaIndex = startIndex + key.Length - 2;

                for (int u = commaIndex + 1; u < text.Length; u++)
                {
                    if (text[u] == '=')
                    {
                        equalSignIndex = u;
                        break;
                    }
                }

                for (int u = equalSignIndex; u < text.Length; u++)
                {
                    if (text[u - 1] == '}' && text[u] == '}')
                    {
                        endIndex = u - 1;
                        break;
                    }
                }

                string modAdi = text.Substring(commaIndex + 2, equalSignIndex - commaIndex - 2);
                string metinNumarasi = text.Substring(equalSignIndex + 1, endIndex - equalSignIndex - 1);

                conteiningText = key + $"{modAdi}=" + $"{metinNumarasi}" + "}}";


                string defaultDeger = "";
                int modIndex = defaultVariables.modaGoreHafizaMetniBulunamadiAciklama.FindIndex(x => x.mod.Equals(modAdi));
                if (modIndex >= 0)
                {
                    defaultDeger = defaultVariables.modaGoreHafizaMetniBulunamadiAciklama[modIndex].standartAciklama;
                }
                else
                {
                    defaultDeger = defaultVariables.defaultHafizaMetniBulunamadiAciklama;
                }

                if (PlayerDataManager.localPlayerDatas.renderedTexts != null)
                {
                    if (PlayerDataManager.localPlayerDatas.renderedTexts.Count > 0)
                    {
                        for (int u = 0; u < PlayerDataManager.localPlayerDatas.renderedTexts.Count; u++)
                        {
                            if (PlayerDataManager.localPlayerDatas.renderedTexts[u].name == modAdi)
                            {
                                if (metinNumarasi == "yeni")
                                {
                                    text = text.Replace(conteiningText, PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts.Count - 1].text);
                                    return text;
                                }
                                else if (metinNumarasi == "eski")
                                {
                                    text = text.Replace(conteiningText, PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[0].text);
                                    return text;
                                }
                                else
                                {
                                    int.TryParse(metinNumarasi, out int metinNumarasiInt);
                                    metinNumarasiInt--;
                                    if (metinNumarasiInt < 10)
                                    {
                                        try
                                        {
                                            text = text.Replace(conteiningText, PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[metinNumarasiInt].text);
                                            return text;
                                        }
                                        catch
                                        {
                                            text = text.Replace(conteiningText, defaultDeger);
                                            return text;
                                        }
                                    }

                                    text = text.Replace(conteiningText, defaultDeger);
                                    return text;
                                }
                            }
                            else if (u == PlayerDataManager.localPlayerDatas.renderedTexts.Count - 1)
                            {
                                text = text.Replace(conteiningText, defaultDeger);
                            }
                        }
                    }
                    else
                    {
                        text = text.Replace(conteiningText, defaultDeger);
                    }
                }
                else
                {
                    text = text.Replace(conteiningText, defaultDeger);
                }
            }
        }
        return text;
    }

    public string GetRenderedTextSpriteId(string text)
    {
        string conteiningText = "";
        string key = "{{hafiza, ";

        if (text.Contains(key))
        {
            //{{hafiza, mod=yeni}}"
            int metindekiDegiskenSayisi = GetWordCountInString(key, text);
            for (int i = 0; i < metindekiDegiskenSayisi; i++)
            {
                int startIndex = 0;
                int commaIndex = 0;
                int equalSignIndex = 0;
                int endIndex = 0;

                startIndex = text.IndexOf(key);
                commaIndex = startIndex + key.Length - 2;

                for (int u = commaIndex + 1; u < text.Length; u++)
                {
                    if (text[u] == '=')
                    {
                        equalSignIndex = u;
                        break;
                    }
                }

                for (int u = equalSignIndex; u < text.Length; u++)
                {
                    if (text[u - 1] == '}' && text[u] == '}')
                    {
                        endIndex = u - 1;
                        break;
                    }
                }

                string modAdi = text.Substring(commaIndex + 2, equalSignIndex - commaIndex - 2);
                string metinNumarasi = text.Substring(equalSignIndex + 1, endIndex - equalSignIndex - 1);

                conteiningText = key + $"{modAdi}=" + $"{metinNumarasi}" + "}}";

                string defaultDeger = "";

                if (PlayerDataManager.localPlayerDatas.renderedTexts != null)
                {
                    if (PlayerDataManager.localPlayerDatas.renderedTexts.Count > 0)
                    {
                        for (int u = 0; u < PlayerDataManager.localPlayerDatas.renderedTexts.Count; u++)
                        {
                            if (PlayerDataManager.localPlayerDatas.renderedTexts[u].name == modAdi)
                            {
                                if (metinNumarasi == "yeni")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts.Count - 1].photoId;
                                else if (metinNumarasi == "eski")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[0].photoId;
                                else if (metinNumarasi == "1")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[0].photoId;
                                else if (metinNumarasi == "2")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[1].photoId;
                                else if (metinNumarasi == "3")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[2].photoId;
                                else if (metinNumarasi == "4")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[3].photoId;
                                else if (metinNumarasi == "5")
                                    text = PlayerDataManager.localPlayerDatas.renderedTexts[u].renderedTexts[4].photoId;
                                else
                                    text = text.Replace(conteiningText, defaultDeger);
                                break;
                            }
                            else if (u == PlayerDataManager.localPlayerDatas.renderedTexts.Count - 1)
                            {
                                text = text.Replace(conteiningText, defaultDeger);
                            }
                        }
                    }
                    else
                    {
                        text = text.Replace(conteiningText, defaultDeger);
                    }
                }
                else
                {
                    text = text.Replace(conteiningText, defaultDeger);
                }
            }
        }
        return text;
    }

    public bool IfTextContainsRenderedTextKey(string text)
    {
        string key = "{{hafiza, ";

        if (text.Contains(key))
        {
            return true;
        }
        else
        {
            return false;
        }
     
    }
    public string NewBubble(string text, int index)
    {
        int firsLetterIndex = 0;
        int lastLetterIndex = -1;

        int currentIndex = 0;

        for (int i = 0; i < text.Length; i++)
        {
            if (text[i] == '|')
            {
                int startPosition = lastLetterIndex + 1;
                firsLetterIndex = i;
                for (int y = firsLetterIndex + 1; y < text.Length; y++)
                {
                    if (text[y] == '|')
                    {

                        if (y - firsLetterIndex <= 4)
                        {
                            string numberString = string.Empty;

                            for (int a = firsLetterIndex + 1; a < y; a++)
                            {
                                numberString += text[a];
                            }

                            string numberStringModifed = numberString.Replace("s", string.Empty);
                            if ((!numberStringModifed.Contains(" ") && numberStringModifed.Any(x => char.IsDigit(x)))
                                || string.IsNullOrWhiteSpace(numberStringModifed))
                            {
                                lastLetterIndex = y;

                                if (currentIndex == index)
                                {
                                    string returnText = string.Empty;

                                    //Eger yanlislikla asagi satira basildiysa
                                    if (text[startPosition] != '\n' && text[startPosition] != '\r')
                                        returnText += text[startPosition];

                                    for (int a = startPosition + 1; a < firsLetterIndex; a++)
                                    {
                                        returnText += text[a];
                                    }

                                    return returnText;
                                }
                                else
                                {
                                    currentIndex++;
                                    i = y;
                                }
                            }
                            else
                            {
                                i = y - 1;
                            }
                        }
                        else
                        {
                            i = y - 1;
                        }

                        break;
                    }
                }
            }

            if (i == text.Length - 1)
            {
                string returnText = string.Empty;

                //Check for first index
                int a = lastLetterIndex + 1;
                if (text[a] != '\n' && text[a] != '\r')
                    returnText += text[a];

                for (++a ; a < text.Length - 1; a++)
                {
                    returnText += text[a];
                }

                //Check for last index
                if (text[text.Length - 1] != '\n' && text[text.Length - 1] != '\r')
                    returnText += text[text.Length - 1];

                return returnText;
            }
        }

        return text;
    }

    public int GetNewBubbleDelayCount(string text, int index)
    {
        int delay = 0;

        int firsLetterIndex = 0;
        int lastLetterIndex = 0;

        int currentIndex = 0;

        for(int i = 0; i<text.Length; i++)
        {
            if (text[i] == '|')
            {
                firsLetterIndex = i;
                for (int y = firsLetterIndex + 1; y < text.Length; y++)
                {
                    if (text[y] == '|')
                    {
                        if (y - firsLetterIndex <= 4)
                        {
                            string numberString = string.Empty;

                            for (int a = firsLetterIndex + 1; a < y; a++)
                            {
                                numberString += text[a];
                            }

                            string numberStringModifed = numberString.Replace("s", string.Empty);
                            if ((!numberStringModifed.Contains(" ") && numberStringModifed.Any(x => char.IsDigit(x)))
                                || string.IsNullOrWhiteSpace(numberStringModifed))
                            {
                                lastLetterIndex = y;
                                if (currentIndex == index)
                                {
                                    int.TryParse(numberStringModifed, out delay);

                                    i = text.Length;
                                }
                                else
                                {
                                    currentIndex++;
                                    i = y;
                                }
                            }
                            else
                            {
                                i = y - 1;
                            }
                        }
                        else
                        {
                            i = y - 1;
                        }

                        break;
                    }
                }
            }
        }

        return delay;
    }

    public int GetBubbleCount(string text)
    {
        int count = 1;

        int firsLetterIndex;
        int lastLetterIndex = 0;

        for (int i = 0; i < text.Length; i++)
        {
            if (text[i] == '|')
            {
                firsLetterIndex = i;
                for (int y = firsLetterIndex + 1; y < text.Length; y++)
                {
                    if (text[y] == '|')
                    {
                        if (y - firsLetterIndex <= 4)
                        {
                            string numberString = string.Empty;

                            for(int a  = firsLetterIndex+1; a<y; a++)
                            {
                                numberString += text[a];
                            }

                            string numberStringModifed = numberString.Replace("s", string.Empty);
                            if ((!numberStringModifed.Contains(" ") && numberStringModifed.Any(x => char.IsDigit(x)))
                                || string.IsNullOrWhiteSpace(numberStringModifed))
                            {
                                lastLetterIndex = y;
                                i = y;
                                count++;
                            }
                            else
                            {
                                i = y - 1;
                            }
                        }
                        else
                        {
                            i = y - 1;
                        }

                        break;
                    }
                }
            }
        }

        return count;
    }

    public bool IsBubbleSlint(string text)
    {
        int firsLetterIndex = 0;
        int lastLetterIndex = 0;

        for (int i = 0; i < text.Length; i++)
        {
            if (text[i] == '|')
            {
                firsLetterIndex = i;
                for (int y = firsLetterIndex + 1; y < text.Length; y++)
                {
                    if (text[y] == '|')
                    {
                        if (y - firsLetterIndex <= 4)
                        {
                            string numberString = string.Empty;

                            for (int a = firsLetterIndex + 1; a < y; a++)
                            {
                                numberString += text[a];
                            }

                            string numberStringModifed = numberString.Replace("s", string.Empty);
                            if ((!numberStringModifed.Contains(" ") && numberStringModifed.Any(x => char.IsDigit(x)))
                                || string.IsNullOrWhiteSpace(numberStringModifed))
                            {
                                lastLetterIndex = y;

                                if (numberString.Contains('s'))
                                    return true;
                            }
                            else
                            {
                                i = y - 1;
                            }
                        }
                        else
                        {
                            i = y - 1;
                        }

                        break;
                    }
                }
            }
        }

        return false;
    }

    //c g I J o s u A E I O U
    //Yukaridaki harfler haric tum harflerden birsini rastgele basar. Birden fazla kullanildigi durumlarda hep ayni harfi basar.
    public string SabitHarfSec(string text)
    {
        List<string> harfler = new List<string>();
        harfler = AddToList(harfler, "b", "c", "d", "f", "g", "h", "k", "l", "m", "n", "p", "r", "s", "ş", "t", "v", "y", "z");

        int index = UnityEngine.Random.Range(0, harfler.Count);

        text = text.Replace("{{sabit_harf}}", harfler[index].ToString().ToUpper());

        return text;
    }
    public string SabitHarfSecV2(string text)
    {
        List<string> harfler = new List<string>();
        harfler = AddToList(harfler, "b", "c", "d", "f", "g", "h", "k", "l", "m", "n", "p", "r", "s", "ş", "t", "v", "y", "z");

        int index = UnityEngine.Random.Range(0, harfler.Count);

        text = text.Replace("{{sabit harf}}", harfler[index].ToString().ToUpper());

        return text;
    }
    public string SabitHarfSecV3(string text)
    {
        List<string> harfler = new List<string>();
        harfler = AddToList(harfler, "b", "c", "d", "f", "g", "h", "k", "l", "m", "n", "p", "r", "s", "ş", "t", "v", "y", "z");

        int index = UnityEngine.Random.Range(0, harfler.Count);

        text = text.Replace("{{sabitharf}}", harfler[index].ToString().ToUpper());

        return text;
    }

    //c g I J o s u A E I O U
    //Yukaridaki harfler haric tum harflerden birsini rastgele basar.
    public string HarfSec(string text)
    {
        List<string> harfler = new List<string>();
        harfler = AddToList(harfler, "b", "c", "d", "f", "g", "h", "k", "l", "m", "n", "p", "r", "s", "ş", "t", "v", "y", "z");

        while (text.Contains("{{harf}}"))
        {
            if (harfler.Count > 0)
            {
                int index = UnityEngine.Random.Range(0, harfler.Count);
                text = ReplaceOneTime("{{harf}}", harfler[index].ToString().ToUpper(), text);
                harfler.RemoveAt(index);
            }
            else 
            {
                while (text.Contains("{{harf}}"))
                {
                    text = ReplaceOneTime("{{harf}}", "", text);
                }
                break;
            }
        }
        return text;
    }

    string ReplaceOneTime(string oldValue, string newValue, string text) 
    {
        string finalText = text;
        
        char[] textChar = text.ToCharArray();
        char[] oldValueChar = oldValue.ToCharArray();

        bool completed = false;

        for (int i = 0; i < textChar.Length; i++)
        {
            if (!completed)
            {
                if (textChar[i] == oldValueChar[0])
                {
                    for (int u = 0; u < oldValueChar.Length; u++)
                    {
                        if (textChar[i + u] == oldValueChar[0 + u])
                        {
                            if (u == oldValueChar.Length - 1)
                            {
                                completed = true;

                                finalText = "";
                                for (int a = 0; a < i; a++)
                                {
                                    finalText += textChar[a].ToString();
                                }

                                finalText += newValue;

                                for (int a = i + u + 1; a < textChar.Length; a++)
                                {
                                    finalText += textChar[a].ToString();
                                }
                            }
                        }
                        else
                        {
                            break;
                        }
                    }
                }
            }
            else
            {
                break;
            }
        }

        return finalText;
    }

    List<string> AddToList(List<string> list, params string[] addingElements)
    {
        for (int i = 0; i < addingElements.Length; i++)
        {
            list.Add(addingElements[i]);
        }

        return list;
    }

    int GetWordCountInString(string word, string text) 
    {
        int count = 0;

        char[] wordArray = word.ToCharArray();
        char[] textArray = text.ToCharArray();

        for(int i = 0; i < textArray.Length; i++) 
        {
            if (textArray[i] == wordArray[0])
            {
                for (int u = 0; u < textArray.Length; u++)
                {
                    if (textArray[i + u] == wordArray[0 + u])
                    {
                        if (u == wordArray.Length - 1)
                        {
                            count++;
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }

        return count;
    }

    string SaatiYaziyaCevir(int saat)
    {
        string returnValue = "";

        if (saat == 0)
        {
            returnValue = "on iki"; 
        }
        else if (saat == 1)
        {
            returnValue = "bir";
        }
        else if (saat == 2)
        {
            returnValue = "iki";
        }
        else if (saat == 3)
        {
            returnValue = "üç";
        }
        else if (saat == 4)
        {
            returnValue = "dört";
        }
        else if (saat == 5)
        {
            returnValue = "beş";
        }
        else if (saat == 6)
        {
            returnValue = "altı";
        }
        else if (saat == 7)
        {
            returnValue = "yedi";
        }
        else if (saat == 8)
        {
            returnValue = "sekiz";
        }
        else if (saat == 9)
        {
            returnValue = "dokuz";
        }
        else if (saat == 10)
        {
            returnValue = "on";
        }
        else if (saat == 11)
        {
            returnValue = "on bir";
        }
        else if (saat == 12)
        {
            returnValue = "on iki";
        }
        else if (saat == 13)
        {
            returnValue = "bir";
        }
        else if (saat == 14)
        {
            returnValue = "iki";
        }
        else if (saat == 15)
        {
            returnValue = "üç";
        }
        else if (saat == 16)
        {
            returnValue = "dört";
        }
        else if (saat == 17)
        {
            returnValue = "beş";
        }
        else if (saat == 18)
        {
            returnValue = "altı";
        }
        else if (saat == 19)
        {
            returnValue = "yedi";
        }
        else if (saat == 20)
        {
            returnValue = "sekiz";
        }
        else if (saat == 21)
        {
            returnValue = "dokuz";
        }
        else if (saat == 22)
        {
            returnValue = "on";
        }
        else if (saat == 23)
        {
            returnValue = "on bir";
        }

        return returnValue;
    }

    public string SayiyiAyaCevir(int sayi)
    {
        string value = "";

        switch (sayi)
        {
            case 1:
                value = "Ocak";
                break;
            case 2:
                value = "Şubat";
                break;
            case 3:
                value = "Mart";
                break;
            case 4:
                value = "Nisan";
                break;
            case 5:
                value = "Mayıs";
                break;
            case 6:
                value = "Haziran";
                break;
            case 7:
                value = "Temmuz";
                break;
            case 8:
                value = "Ağustos";
                break;
            case 9:
                value = "Eylül";
                break;
            case 10:
                value = "Ekim";
                break;
            case 11:
                value = "Kasım";
                break;
            case 12:
                value = "Aralık";
                break;
            default:
                value = " ";
                break;
        }

        return value;
    }

    public static int AyiSayiyaCevir(string ay)
    {
        ay = ay.ToLower();

        switch (ay)
        {
            case "ocak":
                return 1;
            case "şubat":
                return 2;
            case "mart":
                return 3;
            case "nisan":
                return 4;
            case "mayıs":
                return 5;
            case "haziran":
                return 6;
            case "temmuz":
                return 7;
            case "ağustos":
                return 8;
            case "eylül":
                return 9;
            case "ekim":
                return 10;
            case "kasım":
                return 11;
            case "aralık":
                return 12;
            default:
                return 1;
        }
    }

    public string AyiMevsimeCevir(string ay, string mod)
    {
        string value = "";
        ay = ay.ToLower();


        switch (ay)
        {
            case "ocak":
                value = "kış";
                break;
            case "şubat":
                value = "kış";
                break;
            case "mart":
                value = "ilkbahar";
                break;
            case "nisan":
                value = "ilkbahar";
                break;
            case "mayıs":
                value = "ilkbahar";
                break;
            case "haziran":
                value = "yaz";
                break;
            case "temmuz":
                value = "yaz";
                break;
            case "ağustos":
                value = "yaz";
                break;
            case "eylül":
                value = "sonbahar";
                break;
            case "ekim":
                value = "sonbahar";
                break;
            case "kasım":
                value = "sonbahar";
                break;
            case "aralık":
                value = "kış";
                break;
            default:
                value = " ";
                break;
        }

        //zaten cikti kucuk harf oldugu icin eger mod lower ise atla.
        if (mod != "lower")
        {
            //upper ise buyuk harf yap.
            if (mod == "upper")
            {
                value = value.ToUpper();
            }
            else //Diger tum durumlarda ilk harfi buyuk yaz.
            {
                char[] valueChar = value.ToCharArray();
                value = "";

                for (int i = 0; i < valueChar.Length; i++)
                {
                    if (i == 0)
                    {
                        value += valueChar[i].ToString().ToUpper();
                    }
                    else 
                    {
                        value += valueChar[i].ToString();
                    }
                }
            }
        }


        return value;
    }
}

public class DataDegiskeni
{
    public List<ChatDegiskeni> degisken;
    
    public DataDegiskeni()
    {
        degisken = new List<ChatDegiskeni>();
        degisken.Add(new ChatDegiskeni());
    }
}
