using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModSohbetManagerData : ScriptableObject
{
    [HideInInspector] public List<ModSohbetMods> mods;
    [HideInInspector] public Sohbet[] tumSohbetler;
    [HideInInspector] public Sohbet[] tumOnlineSohbetler;
    [HideInInspector] public bool useOnlineSohbetCacheOnEditor;

    public const string localDatabaseName = "YerelDOSYALAR";
    public const string onlineDatabaseName = "OnlineDOSYALAR";

    public int maxVariableCount = 100;

    public void InitializeMods()
    {
#if UNITY_EDITOR
        tumSohbetler = Resources.LoadAll<Sohbet>(localDatabaseName);

        tumOnlineSohbetler = Resources.LoadAll<Sohbet>(onlineDatabaseName);

        OnlineSohbetData[] onlineSohbetDatas = new OnlineSohbetData[tumOnlineSohbetler.Length];

        for(int i = 0; i < tumOnlineSohbetler.Length; i++)
        {
            onlineSohbetDatas[i] = new OnlineSohbetData();
            onlineSohbetDatas[i].ID = tumOnlineSohbetler[i].GetSohbetId();

            onlineSohbetDatas[i].oncelik = tumOnlineSohbetler[i].oncelik;

            if (!string.IsNullOrEmpty(tumOnlineSohbetler[i].contentImage.imageId))
            {
                onlineSohbetDatas[i].imageID = tumOnlineSohbetler[i].contentImage.imageId;
            }
            else
            {
                if (tumOnlineSohbetler[i].contentImage.image!=null)
                {
                    onlineSohbetDatas[i].imageID = tumOnlineSohbetler[i].contentImage.image.name;
                }
            }
         
            onlineSohbetDatas[i].gifID = tumOnlineSohbetler[i].contentImage.gifId;

            onlineSohbetDatas[i].reklam = tumOnlineSohbetler[i].reklam;

            onlineSohbetDatas[i].fotografKonum = tumOnlineSohbetler[i].fotografKonum;

            onlineSohbetDatas[i].ozelFonksiyon = tumOnlineSohbetler[i].ozelFonksiyon;

            onlineSohbetDatas[i].aciklamalar = tumOnlineSohbetler[i].aciklama;
            onlineSohbetDatas[i].aciklamaBalonuYok = tumOnlineSohbetler[i].aciklamaBalonuYok;
            onlineSohbetDatas[i].yeniFocusPaneliKullan = tumOnlineSohbetler[i].yeniFocusPaneliKullan;

            onlineSohbetDatas[i].parlamaRengi = tumOnlineSohbetler[i].parlamaRengi;
            onlineSohbetDatas[i].parlamaSuresi = tumOnlineSohbetler[i].parlamaSuresi;

            onlineSohbetDatas[i].birlestirilecekModlar = tumOnlineSohbetler[i].birlestirilecekModlar;

            onlineSohbetDatas[i].cevaplar = new List<OnlineCevapSohbetData>();
            foreach(CevapSohbet cevapSohbet in tumOnlineSohbetler[i].cevaplar)
            {
                OnlineCevapSohbetData onlineCevapSohbetData = new OnlineCevapSohbetData();
                onlineCevapSohbetData.cevapVaryasyonlari = cevapSohbet.cevapVaryasyonlari;
   
                if (!string.IsNullOrEmpty(cevapSohbet.contentImage.imageId))
                {
                    onlineCevapSohbetData.imageID = cevapSohbet.contentImage.imageId;
                }
                else
                {
                    if (cevapSohbet.contentImage.image != null)
                    {
                        onlineCevapSohbetData.imageID = cevapSohbet.contentImage.image.name;
                    }
                }

                onlineCevapSohbetData.gifID = cevapSohbet.contentImage.gifId;

                onlineCevapSohbetData.fotografKonum = cevapSohbet.fotografKonum;

                onlineCevapSohbetData.gerekenEnerjiKons = cevapSohbet.gerekenEnerjiKons;

                onlineCevapSohbetData.reklamGoster = cevapSohbet.reklamGoster;

                if (cevapSohbet.sonrakiSohbetHavuzu != null)
                    onlineCevapSohbetData.sonrakiSohbetID = cevapSohbet.sonrakiSohbetHavuzu.GetSohbetId();
                else
                    onlineCevapSohbetData.sonrakiSohbetID = string.Empty;

       onlineCevapSohbetData.ayarlananDegiskenler = cevapSohbet.ayarlananDegiskenler;
                onlineCevapSohbetData.gerekliDegiskenler = cevapSohbet.gerekliDegiskenler;

                onlineCevapSohbetData.ozelFonksiyon = cevapSohbet.ozelFonksiyon;

                onlineSohbetDatas[i].cevaplar.Add(onlineCevapSohbetData);
            }

            onlineSohbetDatas[i].tepkiBalonuYok = tumOnlineSohbetler[i].tepkiBalonuYok;

            onlineSohbetDatas[i].balonTipi = tumOnlineSohbetler[i].balonTipi;

            onlineSohbetDatas[i].ayarlananDegiskenler = tumOnlineSohbetler[i].ayarlananDegiskenler;
            onlineSohbetDatas[i].gerekliDegiskenler = tumOnlineSohbetler[i].gerekliDegiskenler;

            onlineSohbetDatas[i].sayac = tumOnlineSohbetler[i].sayac;
            onlineSohbetDatas[i].sayaSonuAnaMenuyeGit = tumOnlineSohbetler[i].sayaSonuAnaMenuyeGit;
            onlineSohbetDatas[i].sayacModu = tumOnlineSohbetler[i].sayacModu;

            if (tumOnlineSohbetler[i].sayacSohbeti != null)
                onlineSohbetDatas[i].sayacSohbetiID = tumOnlineSohbetler[i].sayacSohbeti.GetSohbetId();
            else
                onlineSohbetDatas[i].sayacSohbetiID = string.Empty;

            onlineSohbetDatas[i].sayacTipi = tumOnlineSohbetler[i].sayacTipi;

            onlineSohbetDatas[i].tekrarlama = tumOnlineSohbetler[i].tekrarlama;

            onlineSohbetDatas[i].sohbetBitimModu = tumOnlineSohbetler[i].sohbetBitimModu;
            onlineSohbetDatas[i].sohbetBititmindeAnamenuyeDon = tumOnlineSohbetler[i].sohbetBititmindeAnamenuyeDon;
            onlineSohbetDatas[i].anaMenuyeGitButonuOlustur = tumOnlineSohbetler[i].anaMenuyeGitButonuOlustur;

            onlineSohbetDatas[i].sohbetEnerjisi = tumOnlineSohbetler[i].sohbetEnerjisi;
            onlineSohbetDatas[i].sohbetKonsantrasyonu = tumOnlineSohbetler[i].sohbetKonsantrasyonu;

            onlineSohbetDatas[i].otomatikOdak = tumOnlineSohbetler[i].otomatikOdak;
            onlineSohbetDatas[i].metniKaydet = tumOnlineSohbetler[i].metniKaydet;
        }

        mods = new();
        mods = AddMods(mods, tumSohbetler);

        SaveData.SaveOnlineSohbets(onlineSohbetDatas);
#endif
    }

    public List<ModSohbetMods> AddMods(List<ModSohbetMods> mods, Sohbet[] tumSohbetler)
    {
        for (int i = 0; i < tumSohbetler.Length; i++)
        {
            #region junk
            /*
            tumSohbetler[i].gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();
            foreach (ChatDegiskeni degisken in tumSohbetler[i].gerekenDegiskenler)
            {
                if(degisken.kontrolOperatoru== ChatDegiskeni.OperatorEnum.esit)
                {
                    tumSohbetler[i].gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.esit));
                }
                else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.esitDegil)
                {
                    tumSohbetler[i].gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.esitDegil));
                }
                else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyuk)
                {
                    tumSohbetler[i].gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.buyuk));
                }
                else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyukEsit)
                {
                    tumSohbetler[i].gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.buyukEsit));
                }
                else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucuk)
                {
                    tumSohbetler[i].gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.kucuk));
                }
                else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucukEsit)
                {
                    tumSohbetler[i].gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.kucukEsit));
                }
            }

            tumSohbetler[i].ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
            foreach (ChatDegiskeni degisken in tumSohbetler[i].ayarlanacakDegiskenler)
            {
                if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.esitlik)
                {
                    tumSohbetler[i].ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.esitleme));
                }
                else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.toplama)
                {
                    tumSohbetler[i].ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.toplama));
                }
                else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.cikartma)
                {
                    tumSohbetler[i].ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.cikartma));
                }
                else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.carpma)
                {
                    tumSohbetler[i].ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.carpma));
                }
                else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.bolme)
                {
                    tumSohbetler[i].ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.bolme));
                }
            }

            foreach (CevapSohbet cevapSohbet in tumSohbetler[i].cevaplar)
            {
                cevapSohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();
                foreach (ChatDegiskeni degisken in cevapSohbet.secenekDegiskenleri)
                {
                    if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.esit)
                    {
                        cevapSohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.esit));
                    }
                    else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.esitDegil)
                    {
                        cevapSohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.esitDegil));
                    }
                    else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyuk)
                    {
                        cevapSohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.buyuk));
                    }
                    else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.buyukEsit)
                    {
                        cevapSohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.buyukEsit));
                    }
                    else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucuk)
                    {
                        cevapSohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.kucuk));
                    }
                    else if (degisken.kontrolOperatoru == ChatDegiskeni.OperatorEnum.kucukEsit)
                    {
                        cevapSohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.GerekenDegisken.Kontrol.kucukEsit));
                    }
                }
            }

            foreach (CevapSohbet cevapSohbet in tumSohbetler[i].cevaplar)
            {
                cevapSohbet.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
                foreach (ChatDegiskeni degisken in cevapSohbet.ayarlanacakDegiskenler)
                {
                    if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.esitlik)
                    {
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.esitleme));
                    }
                    else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.toplama)
                    {
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.toplama));
                    }
                    else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.cikartma)
                    {
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.cikartma));
                    }
                    else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.carpma)
                    {
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.carpma));
                    }
                    else if (degisken.ayarlamaOperatoru == ChatDegiskeni.OperatorAyarlanacakEnum.bolme)
                    {
                        cevapSohbet.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken(degisken.degiskenAdi, degisken.degiskenDegeri, Sohbet.AyarlanacakDegisken.Islem.bolme));
                    }
                }
            }

            UnityEditor.EditorUtility.SetDirty(tumSohbetler[i]);*/
            #endregion

            if (tumSohbetler[i] != null)
            {
#if UNITY_EDITOR
                for (int u = 0; u < tumSohbetler[i].aciklama.Count; u++)
                {
                    if (tumSohbetler[i].aciklama[u].Contains("\r"))
                    {
                        tumSohbetler[i].aciklama[u] = tumSohbetler[i].aciklama[u].Replace("\r", string.Empty);
                        Debug.LogWarning(tumSohbetler[i].name + " sohbeti \\r sembolü içeriyor. Bu sohbet düzeltildi!");
                        UnityEditor.EditorUtility.SetDirty(tumSohbetler[i]);
                    }
                }

                if (tumSohbetler[i].GetSohbetId().ToCharArray().Length < 24)
                {
                    tumSohbetler[i].idIndex = CreateID();

                    UnityEditor.EditorUtility.SetDirty(tumSohbetler[i]);
                }
                else
                {
                    foreach (Sohbet sohbet in tumSohbetler)
                    {
                        if (sohbet != null)
                        {
                            if (sohbet != tumSohbetler[i])
                            {
                                if (sohbet.GetSohbetId() == tumSohbetler[i].GetSohbetId())
                                {
                                    Debug.Log("Veritabanında aynı id'ye sahip sohbetler var. Lütfen bu id'ye sahip sohbetleri gözden geçirin. Çakışan Id: " +
                                        sohbet.GetSohbetId() + " Çakışan ilk sohbet: " + sohbet.name + " Çakışan ikinci sohbet: " + tumSohbetler[i].name +
                                        $" {UnityEditor.AssetDatabase.GetAssetPath(sohbet)} \n {UnityEditor.AssetDatabase.GetAssetPath(tumSohbetler[i])}");
                                }
                            }
                        }
                    }
                }
#endif
                if (tumSohbetler[i].gerekliDegiskenler != null)
                {
                    for (int u = 0; u < tumSohbetler[i].gerekliDegiskenler.Count; u++)
                    {
                        if (tumSohbetler[i].gerekliDegiskenler[u].degiskenAdi == "mod")
                        {
                            if (mods.Count > 0)
                            {
                                for (int a = 0; a < mods.Count; a++)
                                {
                                    if (a != mods.Count - 1)
                                    {
                                        if (mods[a].mod == tumSohbetler[i].gerekliDegiskenler[u].degiskenDegeri)
                                        {
                                            int oncelikIndex = 0;

                                            if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.normal)
                                            {
                                                oncelikIndex = tumSohbetler[i].gerekliDegiskenler.Count;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.son)
                                            {
                                                oncelikIndex = 0;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_2)
                                            {
                                                oncelikIndex = maxVariableCount + tumSohbetler[i].gerekliDegiskenler.Count;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_1)
                                            {
                                                oncelikIndex = maxVariableCount * 2 + tumSohbetler[i].gerekliDegiskenler.Count;
                                            }

                                            for (int b = mods[a].ModSohbetRepetitions[0].modSohbetler.Count; b < oncelikIndex + 1; b++)
                                            {
                                                ModSohbet eklenecekSohbet = new ModSohbet();
                                                eklenecekSohbet.sohbetler = new List<Sohbet>();
                                                mods[a].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                            }

                                            /*
                                            ModSohbet eklenecekSohbet = new ModSohbet();
                                            eklenecekSohbet.sohbetler[tumSohbetler[i].gerekliDegiskenler.Count - 1].Add(tumSohbetler[i]);
                                            eklenecekSohbet.repetition = 0;

                                            mods[a].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                            */

                                            mods[a].ModSohbetRepetitions[0].modSohbetler[oncelikIndex].sohbetler.Add(tumSohbetler[i]);

                                            break;
                                        }
                                    }
                                    else
                                    {
                                        if (mods[a].mod == tumSohbetler[i].gerekliDegiskenler[u].degiskenDegeri)
                                        {
                                            int oncelikIndex = 0;

                                            if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.normal)
                                            {
                                                oncelikIndex = tumSohbetler[i].gerekliDegiskenler.Count;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.son)
                                            {
                                                oncelikIndex = 0;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_2)
                                            {
                                                oncelikIndex = maxVariableCount + tumSohbetler[i].gerekliDegiskenler.Count;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_1)
                                            {
                                                oncelikIndex = maxVariableCount * 2 + tumSohbetler[i].gerekliDegiskenler.Count;
                                            }

                                            for (int b = mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler.Count; b < oncelikIndex + 1; b++)
                                            {
                                                ModSohbet eklenecekSohbet = new ModSohbet();
                                                eklenecekSohbet.sohbetler = new List<Sohbet>();
                                                mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                            }
                                            /*
                                            ModSohbet eklenecekSohbet = new ModSohbet();
                                            eklenecekSohbet.sohbetler[tumSohbetler[i].gerekliDegiskenler.Count - 1].Add(tumSohbetler[i]);
                                            eklenecekSohbet.repetition = 0;

                                            mods[a].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                            */

                                            mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler[oncelikIndex].sohbetler.Add(tumSohbetler[i]);
                                            break;
                                        }
                                        else
                                        {
                                            ModSohbetMods eklenecekMod = new ModSohbetMods();
                                            eklenecekMod.mod = tumSohbetler[i].gerekliDegiskenler[u].degiskenDegeri;
                                            eklenecekMod.ModSohbetRepetitions = new List<ModSohbetRepetitions>();
                                            eklenecekMod.ModSohbetRepetitions.Add(new ModSohbetRepetitions());
                                            eklenecekMod.ModSohbetRepetitions[0].modSohbetler = new List<ModSohbet>();
                                            mods.Add(eklenecekMod);

                                            int oncelikIndex = 0;

                                            if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.normal)
                                            {
                                                oncelikIndex = tumSohbetler[i].gerekliDegiskenler.Count;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.son)
                                            {
                                                oncelikIndex = 0;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_2)
                                            {
                                                oncelikIndex = maxVariableCount + tumSohbetler[i].gerekliDegiskenler.Count;
                                            }
                                            else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_1)
                                            {
                                                oncelikIndex = maxVariableCount * 2 + tumSohbetler[i].gerekliDegiskenler.Count;
                                            }

                                            for (int b = mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler.Count; b < oncelikIndex + 1; b++)
                                            {
                                                ModSohbet eklenecekSohbet = new ModSohbet();
                                                eklenecekSohbet.sohbetler = new List<Sohbet>();
                                                mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                            }
                                            /*
                                            ModSohbet eklenecekSohbet = new ModSohbet();
                                            eklenecekSohbet.sohbetler[tumSohbetler[i].gerekliDegiskenler.Count - 1].Add(tumSohbetler[i]);
                                            eklenecekSohbet.repetition = 0;

                                            mods[a].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                            */

                                            mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler[oncelikIndex].sohbetler.Add(tumSohbetler[i]);
                                            break;
                                        }
                                    }
                                }
                            }
                            else
                            {
                                ModSohbetMods eklenecekMod = new ModSohbetMods();
                                eklenecekMod.mod = tumSohbetler[i].gerekliDegiskenler[u].degiskenDegeri;
                                eklenecekMod.ModSohbetRepetitions = new List<ModSohbetRepetitions>();
                                eklenecekMod.ModSohbetRepetitions.Add(new ModSohbetRepetitions());
                                eklenecekMod.ModSohbetRepetitions[0].modSohbetler = new List<ModSohbet>();
                                mods.Add(eklenecekMod);

                                int oncelikIndex = 0;

                                if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.normal)
                                {
                                    oncelikIndex = tumSohbetler[i].gerekliDegiskenler.Count;
                                }
                                else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.son)
                                {
                                    oncelikIndex = 0;
                                }
                                else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_2)
                                {
                                    oncelikIndex = maxVariableCount + tumSohbetler[i].gerekliDegiskenler.Count;
                                }
                                else if (tumSohbetler[i].oncelik == Sohbet.SohbetOnceligi.ilk_1)
                                {
                                    oncelikIndex = maxVariableCount * 2 + tumSohbetler[i].gerekliDegiskenler.Count;
                                }

                                for (int b = mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler.Count; b < oncelikIndex + 1; b++)
                                {
                                    ModSohbet eklenecekSohbet = new ModSohbet();
                                    eklenecekSohbet.sohbetler = new List<Sohbet>();
                                    mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                }

                                /*
                                ModSohbet eklenecekSohbet = new ModSohbet();
                                eklenecekSohbet.sohbetler[tumSohbetler[i].gerekliDegiskenler.Count - 1].Add(tumSohbetler[i]);
                                eklenecekSohbet.repetition = 0;

                                mods[a].ModSohbetRepetitions[0].modSohbetler.Add(eklenecekSohbet);
                                */

                                mods[mods.Count - 1].ModSohbetRepetitions[0].modSohbetler[oncelikIndex].sohbetler.Add(tumSohbetler[i]);
                            }
                        }
                    }
                }
                else
                {
                    tumSohbetler[i].gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();



                    Debug.Log("Gereken değişkenleri null olan sohbetler düzeltildi. Bu bir sorun değil.");
                }
            }
        }

        return mods;
    }

    public string CreateID()
    {
        string id = string.Empty;

        for (int indexCount = 0; indexCount < 12; indexCount++)
        {
            if (indexCount == 0)
            {
                id += System.DateTime.Now.Year.ToString() + System.DateTime.Now.Month.ToString() +
                    System.DateTime.Now.Day.ToString() + System.DateTime.Now.Minute.ToString() + System.DateTime.Now.Second.ToString() + "AA";
            }
            else
            {
                id += Random.Range(0, 10).ToString();
            }
        }

        return id;
    }

    public List<ModSohbetMods> GetMods()
    {
        List<ModSohbetMods> returnValue = new List<ModSohbetMods>();

        foreach (ModSohbetMods modSohbetMod in mods)
        {
            returnValue.Add(new ModSohbetMods(modSohbetMod.mod));
            foreach (ModSohbetRepetitions modSohbetRepetition in modSohbetMod.ModSohbetRepetitions)
            {
                returnValue[returnValue.Count - 1].ModSohbetRepetitions.Add(new ModSohbetRepetitions());
                foreach (ModSohbet modSohbet in modSohbetRepetition.modSohbetler)
                {
                    returnValue[returnValue.Count - 1].ModSohbetRepetitions[returnValue[returnValue.Count - 1].ModSohbetRepetitions.Count - 1].modSohbetler.Add(new ModSohbet(new List<Sohbet>(modSohbet.sohbetler)));
                }
            }
        }

        return returnValue;
    }
}
