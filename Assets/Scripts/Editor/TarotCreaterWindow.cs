using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class TarotCreaterWindow : EditorWindow
{
    Vector2 scroll;

    public enum TarotKartiTuru 
    {
        adalet,
        araba,
        asaaltilisi,
        asaasi,
        asabeslisi,
        asadokuzlusu,
        asadortlusu,
        asaikilisi,
        asakrali,
        asakralicesi,
        asaonlusu,
        asaprensi,
        asasekizlisi,
        asasovalyesi,
        asauclusu,
        asayedilisi,
        asiklar,
        asilanadam,
        ay,
        aziz,
        Azize,
        BudalaDeli,
        Buyucu,
        denge,
        dunya,
        guc,
        gunes,
        imparator,
        imparatorice,
        kadercarki,
        kilicaltilisi,
        kilicasi,
        kilicbeslisi,
        kilicdokuzlusu,
        kilicdortlusu,
        kilicikilisi,
        kilickrali,
        kilickralicesi,
        kiliconlusu,
        kilicprensi,
        kilicsekizlisi,
        kilicsovalyesi,
        kilicuclusu,
        kilicyedilisi,
        kupaaltilisi,
        kupaasi,
        kupabeslisi,
        kupadokuzlusu,
        kupadortlusu,
        kupaikilisi,
        kupakrali,
        kupakralicesi,
        kupaonlusu,
        kupaprensi,
        kupasekizlisi,
        kupasovalyesi,
        kupauclusu,
        kupayedilisi,
        mahkeme,
        munzevi,
        olum,
        seytan,
        tilsimaltilisi,
        tilsimasi,
        tilsimbeslisi,
        tilsimdokuzlusu,
        tilsimdortlusu,
        tilsimikilisi,
        tilsimkrali,
        tilsimkralicesi,
        tilsimonlusu,
        tilsimprensi,
        tilsimsekizlisi,
        tilsimsovalyesi,
        tilsimuclusu,
        tilsimyedilisi,
        yikilankule,
        yildiz,
    }
    TarotKartiTuru tarotKartiTuru;

    public enum TarotFalTipi
    {
        gecmis,
        simdi,
        gelecek,
    }
    TarotFalTipi tarotFalTipi;

    public enum TarotSohbetiOlusturmaTuru
    {
        fal,
        tepki,
    }
    TarotSohbetiOlusturmaTuru tarotSohbetiOlusturmaTuru;

    public enum TarotKartYonu
    {
        duz,
        ters,
    }
    TarotKartYonu tarotKartYonu;

    PhotoSettings photoSettings;
    TarotSettings tarotSettings;

    [MenuItem("Magnus/Olusturucular/Tarot sohbeti oluşturucu")]
    public static void ShowWindow()
    {
        TarotCreaterWindow window = (TarotCreaterWindow)EditorWindow.GetWindow(typeof(TarotCreaterWindow));
    }

    private void OnEnable()
    {
        photoSettings = Resources.Load<PhotoSettings>("SohbetVeriTabani/LocalPhotoSettings");
        tarotSettings = Resources.Load<TarotSettings>("SohbetVeriTabani/TarotSettings");
    }

    private void OnGUI()
    {
        scroll = EditorGUILayout.BeginScrollView(scroll);

        EditorGUILayout.BeginHorizontal();
        tarotKartiTuru = (TarotKartiTuru)EditorGUILayout.EnumPopup(tarotKartiTuru);
        tarotKartYonu = (TarotKartYonu)EditorGUILayout.EnumPopup(tarotKartYonu);
        tarotFalTipi = (TarotFalTipi)EditorGUILayout.EnumPopup(tarotFalTipi);
        tarotSohbetiOlusturmaTuru = (TarotSohbetiOlusturmaTuru)EditorGUILayout.EnumPopup(tarotSohbetiOlusturmaTuru);
        EditorGUILayout.EndHorizontal();

        tarotSettings.creatorWindowSohbetAciklama = EditorGUILayout.TextArea(tarotSettings.creatorWindowSohbetAciklama, EditorStyles.textArea, GUILayout.Height(200), GUILayout.ExpandHeight(true));
        tarotSettings.creatorWindowVazgecmeTepkisi = EditorGUILayout.TextField("Tarottan çık tepki", tarotSettings.creatorWindowVazgecmeTepkisi);



        if(GUILayout.Button("Sohbeti olustur"))
        {
            if (tarotSohbetiOlusturmaTuru == TarotSohbetiOlusturmaTuru.fal)
            {
                Sohbet sohbet = ScriptableObject.CreateInstance<Sohbet>();

                string tersDuzEk = "";
                if (tarotKartYonu != TarotKartYonu.ters)
                {
                    sohbet.name = SetFirstLetterUpper(GetTarotCardName(tarotKartiTuru.ToString())).Replace(" ", "");
                }
                else
                {
                    tersDuzEk = " ters";
                    sohbet.name = "Ters" + SetFirstLetterUpper(GetTarotCardName(tarotKartiTuru.ToString())).Replace(" ", "");
                }
  
                foreach (PhotoSettings.LocalSprite sprite in photoSettings.localSprites)
                {
                    if (sprite.sprite.name.Replace("-", " ").ToLower() == GetTarotCardName(tarotKartiTuru.ToString()))
                    {
                        sohbet.contentImage.image = sprite.sprite;
                        break;
                    }
                }

                sohbet.aciklama = new List<string>() { tarotSettings.creatorWindowSohbetAciklama };

                if (tarotFalTipi == TarotFalTipi.gecmis)
                {
                    sohbet.ozelFonksiyon = "tarot geçmiş sohbeti başlat";
                    sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>() { new Sohbet.GerekenDegisken("mod", "tarot gecmis " + sohbet.contentImage.image.name.Replace("-", " ").ToLower() + tersDuzEk) };
                }
                else if (tarotFalTipi == TarotFalTipi.simdi)
                {
                    sohbet.ozelFonksiyon = "tarot şimdi sohbeti başlat";
                    sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>() { new Sohbet.GerekenDegisken("mod", "tarot simdi " + sohbet.contentImage.image.name.Replace("-", " ").ToLower() + tersDuzEk) };
                }
                else if (tarotFalTipi == TarotFalTipi.gelecek)
                {
                    sohbet.ozelFonksiyon = "tarot gelecek sohbeti başlat";
                    sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>() { new Sohbet.GerekenDegisken("mod", "tarot gelecek " + sohbet.contentImage.image.name.Replace("-", " ").ToLower() + tersDuzEk) };
                }

                sohbet.aciklamaBalonuYok = true;
                sohbet.sohbetBititmindeAnamenuyeDon = false;
                sohbet.anaMenuyeGitButonuOlustur = false;
                ProjectWindowUtil.CreateAsset(sohbet, sohbet.name + ".asset");
            }
            else if (tarotSohbetiOlusturmaTuru == TarotSohbetiOlusturmaTuru.tepki)
            {
                Sohbet sohbet = ScriptableObject.CreateInstance<Sohbet>();

                string tersDuzEk = "";
                if (tarotKartYonu != TarotKartYonu.ters)
                {
                    sohbet.name = SetFirstLetterUpper(GetTarotCardName(tarotKartiTuru.ToString())).Replace(" ", "");
                }
                else
                {
                    tersDuzEk = " ters";
                    sohbet.name = "Ters" + SetFirstLetterUpper(GetTarotCardName(tarotKartiTuru.ToString())).Replace(" ", "");
                }

                sohbet.aciklama = new List<string>() { tarotSettings.creatorWindowSohbetAciklama };

                string sohbetAdi = "";
                foreach (PhotoSettings.LocalSprite sprite in photoSettings.localSprites)
                {
                    if (sprite.sprite.name.Replace("-", " ").ToLower() == GetTarotCardName(tarotKartiTuru.ToString()))
                    {
                        sohbetAdi = sprite.sprite.name.Replace("-", " ").ToLower() + tersDuzEk;
                        break;
                    }
                }

                if (tarotFalTipi == TarotFalTipi.gecmis)
                {
                    sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>() { new Sohbet.GerekenDegisken("mod", "tarot gecmis " + sohbetAdi + " tepki") };
                }
                else if (tarotFalTipi == TarotFalTipi.simdi)
                {
                    sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>() { new Sohbet.GerekenDegisken("mod", "tarot simdi " + sohbetAdi + " tepki") };
                }
                else if (tarotFalTipi == TarotFalTipi.gelecek)
                {
                    sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>() { new Sohbet.GerekenDegisken("mod", "tarot gelecek " + sohbetAdi + " tepki") };
                }

                sohbet.cevaplar = new List<CevapSohbet>() { new CevapSohbet() };
                sohbet.cevaplar[0].cevapVaryasyonlari = new List<string>() { tarotSettings.creatorWindowVazgecmeTepkisi };
                sohbet.cevaplar[0].ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>() { new Sohbet.AyarlanacakDegisken("mod", "tarot vazgecme") };

                sohbet.sohbetBititmindeAnamenuyeDon = false;
                sohbet.anaMenuyeGitButonuOlustur = false;

                ProjectWindowUtil.CreateAsset(sohbet, sohbet.name + "Tepki.asset");
            }
        }

        EditorGUILayout.EndScrollView();
    }

    string GetTarotCardName(string value)
    {
        List<char> valueCharList = new List<char>(value.ToCharArray());
        List<string> parts = new List<string>() { "" };

        for (int i = 0; i < valueCharList.Count; i++)
        {
            if (!char.IsLower(valueCharList[i]))
            {
                if (i != 0)
                    parts.Add("");
                parts[parts.Count - 1] += valueCharList[i];
            }
            else
            {
                parts[parts.Count - 1] += valueCharList[i];
            }
        }

        string returnValue = "";
        for (int i = 0; i < parts.Count; i++)
        {
            if (i == 0)
                returnValue += parts[i];
            else
                returnValue += " " + parts[i];
        }
        Debug.Log(parts.Count);
        return returnValue.ToLower();
    }

    string SetFirstLetterUpper(string value)
    {
        List<char> valueCharList = new List<char>(value.ToCharArray());
        string returnValue = "";
        for (int i = 0; i < valueCharList.Count; i++)
        {
            if (i == 0)
            {
                returnValue += valueCharList[i].ToString().ToUpper();
            }
            else
            {
                returnValue += valueCharList[i].ToString();
            }
        }

        return returnValue;
    }
}
