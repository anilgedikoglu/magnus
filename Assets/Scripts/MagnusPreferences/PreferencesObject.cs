using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Video;

[CreateAssetMenu(fileName = "Preferences", menuName = "Magnus/PreferencesObject")]
public class PreferencesObject : ScriptableObject
{
    public VideoClip[] editVideos, kahveFaliVideos;

    public Sprite defaultLoadingContent, defaultLoadingContent2;

    [HideInInspector] public string[] hosgeldinMesajlari;
    public string[] konuDegisButonuMetinleri;

    [Space(10)]
    public int minimumDogumYili;

    [Space(10)]
    [Range(1f,5f)]
    public float yazmaSuresiCarpani = 1;
    public bool yazmaSureleriniSifirla;

    public List<BugunGelenMod> gunlukModlar;

    public List<CounterMod> counterMods;

    public List<string> bookMods;

    [HideInInspector] public int magnuFlowEnerjiKazanmaSkoru;
    [HideInInspector] public int magnuDotsEnerjiKazanmaSkoru;
    [HideInInspector] public int magnu2048EnerjiKazanmaSkoru;
    [HideInInspector] public int magnukemEnerjiKazanmaSkoru;

    public GameScore magnuTris;
    public GameScore magnuDots;
    public GameScore magnuFlow;
    public GameScore magnuKem;
    public GameScore magnuMbers;

    public Sohbet enerjiKalmadi;
    public Sohbet enerjiKalmadiPlus;
    public Sohbet konsantrasyonKalmadi;

    public List<Sohbet> ilkGelisSonlari;

    public List<SpecialDate> ozelGunler;

    [HideInInspector] public string sonIcerikGuncellemeTarihi;

    [HideInInspector] public string wheelChartConentPhotoId;
    [HideInInspector] public string kullaniciPhotoId;

    public TMPro.TMP_SpriteAsset spriteAsset;

    [System.Serializable]
    public class CounterMod
    {
        [TextArea(2, 5)]
        public string mod;
        public List<string> yanModlar;
        public List<Counter> counters;

        [System.Serializable]
        public class Counter
        {
            public int value;
            public string basariModu;
        }
    }

    [System.Serializable]
    public class SpecialDate
    {
        public string gunAdi = "";
        public bool herYil = false;
        public bool dogumGunu = false;
        public int baslangicGunu = 1;
        public int baslangicAyi = 1;
        public int baslangicYili = 2020;
        public int bitiscGunu = 1;
        public int bitiscAyi = 1;
        public int bitisYili = 2020;

    }

    public int GetModCounter(string mod, int repetition)
    {
        int returnValue = -1;

        foreach(CounterMod counterMod in counterMods)
        {
            if (counterMod.mod == mod)
            {
                repetition = Mathf.Clamp(repetition, 0, counterMod.counters.Count - 1);
                returnValue = counterMod.counters[repetition].value;
                break;
            }
        }
        return returnValue;
    }

    public string GetModCounterMod(string mod, int repetition)
    {
        string returnValue = "";

        foreach (CounterMod counterMod in counterMods)
        {
            if (counterMod.mod == mod)
            {
                repetition = Mathf.Clamp(repetition, 0, counterMod.counters.Count - 1);
                returnValue = counterMod.counters[repetition].basariModu;
                break;
            }
        }
        return returnValue;
    }


    [System.Serializable]
    public class BugunGelenMod
    {
        public string mod;
        public int count;
        public int countPlus;
        public List<string> exceptedMods;
        public UIInformation uIInformation;
        public bool falHaklariMenusundeGoster;

        public BugunGelenMod()
        {
            mod = string.Empty;
            exceptedMods = new();
            count = 0;
            falHaklariMenusundeGoster = false;
        }

        public BugunGelenMod(string mod)
        {
            this.mod = mod;
            exceptedMods = new();
            count = 1;
            countPlus = 1;
            falHaklariMenusundeGoster = false;
        }

        public BugunGelenMod(string mod, int count, int countPlus)
        {
            this.mod = mod;
            this.count = count;
            this.countPlus = countPlus;
            exceptedMods = new();
            falHaklariMenusundeGoster = false;
        }

        [System.Serializable]
        public class UIInformation
        {
            public string title;
            public Sprite Icon;
        }
    }

    [System.Serializable]
    public class GameScore
    {
        public int baseScore;
        public int increaseAmount;

        public GameScore()
        {
            baseScore = 0;
            increaseAmount = 0;
        }
    }
}
