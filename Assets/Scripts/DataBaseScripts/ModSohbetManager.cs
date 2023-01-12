using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Threading.Tasks;
using UnityEngine;

public class ModSohbetManager : MonoBehaviour
{
    public static ModSohbetManager Instance { get; private set; }

    public ChatManager chatManager;
    public CurrentPlayerData playerData;

    public int maxVariableCount = 100;

    public List<ModSohbetMods> mods;

    [HideInInspector] public OnlineSohbetData[] onlineSohbetler;

    public ModSohbetManagerData modSohbetManagerData;

    [HideInInspector] public Sohbet[] onlineSohbetCache;

    internal int onlineCheckPerFrame = 20;

    private void Awake()
    {
        Instance = this;

#if UNITY_EDITOR
        mods = modSohbetManagerData.GetMods();
#else
        mods = modSohbetManagerData.mods;
#endif
    }

    void Start()
    {

    }

    void Update()
    {
        
    }

    public List<Sohbet> ChooseSohbetList() 
    {
        List<Sohbet> sohbetList;
        sohbetList = new List<Sohbet>();

        int i = mods.FindIndex(x => x.mod.Equals(playerData.GetChatVariableValue("mod")));

        if (i >= 0)
        {
            if (mods[i].ModSohbetRepetitions[0].modSohbetler[mods[i].ModSohbetRepetitions[0].modSohbetler.Count - 1].sohbetler.Count > 0)
            {
                sohbetList = new List<Sohbet>(mods[i].ModSohbetRepetitions[0].modSohbetler[mods[i].ModSohbetRepetitions[0].modSohbetler.Count - 1].sohbetler);
            }
            else
            {
                while (mods[i].ModSohbetRepetitions[0].modSohbetler[mods[i].ModSohbetRepetitions[0].modSohbetler.Count - 1].sohbetler.Count == 0)
                {
                    mods[i].ModSohbetRepetitions[0].modSohbetler.RemoveAt(mods[i].ModSohbetRepetitions[0].modSohbetler.Count - 1);
                    if (mods[i].ModSohbetRepetitions[0].modSohbetler.Count <= 0)
                        break;
                }
                if (mods[i].ModSohbetRepetitions[0].modSohbetler.Count == 0)
                {
                    mods[i].ModSohbetRepetitions.RemoveAt(0);
                }
                sohbetList = new List<Sohbet>(mods[i].ModSohbetRepetitions[0].modSohbetler[mods[i].ModSohbetRepetitions[0].modSohbetler.Count - 1].sohbetler);
                //MoveForwardChoosenSohbet(0);
                //sohbetList = ChooseSohbetList();
            }
        }

        return sohbetList;
    }

    public int TotalSohbetElementCount() 
    {
        int returnValue = 0;

        int i = mods.FindIndex(x => x.mod.Equals(playerData.GetChatVariableValue("mod")));
        if (i >= 0)
        {
            if (mods[i].ModSohbetRepetitions.Count == 1)
            {
                foreach (ModSohbet modSohbet in  mods[i].ModSohbetRepetitions[0].modSohbetler)
                {
                    if (modSohbet.sohbetler != null)
                    {
                        if (modSohbet.sohbetler.Count > 0)
                        {
                            returnValue += 1;
                        }
                    }
                }
                //returnValue = mods[i].ModSohbetRepetitions[0].modSohbetler.Count;
            }
            else if (mods[i].ModSohbetRepetitions.Count == 2)
            {
                foreach (ModSohbet modSohbet in mods[i].ModSohbetRepetitions[0].modSohbetler)
                {
                    if (modSohbet.sohbetler != null)
                    {
                        if (modSohbet.sohbetler.Count > 0)
                        {
                            returnValue += 1;
                        }
                    }
                }

                foreach (ModSohbet modSohbet in mods[i].ModSohbetRepetitions[1].modSohbetler)
                {
                    if (modSohbet.sohbetler != null)
                    {
                        if (modSohbet.sohbetler.Count > 0)
                        {
                            returnValue += 1;
                        }
                    }
                }
            }
        }

        return returnValue * 2;
    }

    public int TekrarDegiskenleriniSifirla()
    {
        int b = mods.FindIndex(x => x.mod.Equals(playerData.GetChatVariableValue("mod")));

        int returnValue = 0;

        if (b >= 0)
        {
            if (mods[b].mod == playerData.GetChatVariableValue("mod").ToLower())
            {
                for (int i = 0; i < mods[b].ModSohbetRepetitions.Count; i++)
                {
                    for (int u = 0; u < mods[b].ModSohbetRepetitions[i].modSohbetler.Count; u++)
                    {
                        for (int a = 0; a < mods[b].ModSohbetRepetitions[i].modSohbetler[u].sohbetler.Count; a++)
                        {
                            Sohbet sohbet = mods[b].ModSohbetRepetitions[i].modSohbetler[u].sohbetler[a];
                            if (playerData.localPlayerDatas.dahaOnceGelenSohbetler.Contains(sohbet.GetSohbetId()))
                            {
                                playerData.localPlayerDatas.dahaOnceGelenSohbetler.Remove(sohbet.GetSohbetId());
                            }
                        }
                    }
                }
            }
        }

        return returnValue + 1;
    }

    public void MoveForwardChoosenSohbet(int position)
    {
        int a = mods.FindIndex(x => x.mod.Equals(playerData.GetChatVariableValue("mod")));

        if (a >= 0)
        {
            if (mods[a].mod == playerData.GetChatVariableValue("mod"))
            {

                int modSohbetIndex = mods[a].ModSohbetRepetitions[0].modSohbetler.Count - 1;
                if (position < mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler.Count)
                {
                    int degiskenSayisi = 0;

                    if (mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].oncelik == Sohbet.SohbetOnceligi.normal)
                    {
                        degiskenSayisi = mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].gerekliDegiskenler.Count;
                    }
                    else if (mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].oncelik == Sohbet.SohbetOnceligi.son)
                    {
                        degiskenSayisi = 0 + mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].gerekliDegiskenler.Count;
                    }
                    else if (mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].oncelik == Sohbet.SohbetOnceligi.ilk_2)
                    {
                        degiskenSayisi = maxVariableCount + mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].gerekliDegiskenler.Count;
                    }
                    else if (mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].oncelik == Sohbet.SohbetOnceligi.ilk_1)
                    {
                        degiskenSayisi = maxVariableCount * 2 + mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position].gerekliDegiskenler.Count;
                    }

                    if (mods[a].ModSohbetRepetitions.Count == 2)
                    {
                        for (int i = mods[a].ModSohbetRepetitions[1].modSohbetler.Count; i < degiskenSayisi + 1; i++)
                        {
                            mods[a].ModSohbetRepetitions[1].modSohbetler.Add(new ModSohbet());
                        }

                        mods[a].ModSohbetRepetitions[1].modSohbetler[degiskenSayisi].sohbetler.Add(mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position]);
                        mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler.RemoveAt(position);
                    }
                    else
                    {
                        mods[a].ModSohbetRepetitions.Add(new ModSohbetRepetitions());
                        
                        for (int i = mods[a].ModSohbetRepetitions[1].modSohbetler.Count; i < degiskenSayisi + 1; i++)
                        {
                            mods[a].ModSohbetRepetitions[1].modSohbetler.Add(new ModSohbet());
                        }

                        mods[a].ModSohbetRepetitions[1].modSohbetler[degiskenSayisi].sohbetler.Add(mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler[position]);
                        mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler.RemoveAt(position);

                    }

                    if (mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler.Count <= 0)
                    {
                        chatManager.modListSohbetCount -= 1;
                    }
                }
                else
                {
                    // Debug.Log("posittion degeri olmasi gerekenden buyuk. Deger: " + position.ToString() + "/" + mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler.Count.ToString());
                }

                if (mods[a].ModSohbetRepetitions[0].modSohbetler[modSohbetIndex].sohbetler.Count == 0)
                {
                    mods[a].ModSohbetRepetitions[0].modSohbetler.RemoveAt(modSohbetIndex);
                }
                if (mods[a].ModSohbetRepetitions[0].modSohbetler.Count == 0)
                {
                    mods[a].ModSohbetRepetitions.RemoveAt(0);
                    //TekrarDegiskenleriniSifirla();
                }
            }
        }


        /*
        if (position < mods[lastChoosenList].ModSohbetRepetitions[0].modSohbetler.Count)
        {
            if (mods[lastChoosenList].ModSohbetRepetitions.Count <= 1 || mods[lastChoosenList].ModSohbetRepetitions[0].modSohbetler.Count == 1)
            {
                mods[lastChoosenList].ModSohbetRepetitions.Add(new ModSohbetRepetitions());
            }

            foreach (ModSohbetRepetitions element in mods[lastChoosenList].ModSohbetRepetitions)
            {
                if (element.modSohbetler == null)
                {
                    element.modSohbetler = new List<ModSohbet>();
                }
            }

            if (mods[lastChoosenList].ModSohbetRepetitions.Count == 3)
            {
                mods[lastChoosenList].ModSohbetRepetitions[2].modSohbetler[0].sohbetler.Add(mods[lastChoosenList].ModSohbetRepetitions[0].modSohbetler[0].sohbetler[position]);
            }
            else
            {
                mods[lastChoosenList].ModSohbetRepetitions[1].modSohbetler[0].sohbetler.Add(mods[lastChoosenList].ModSohbetRepetitions[0].modSohbetler[0].sohbetler[position]);
            }

            mods[lastChoosenList].ModSohbetRepetitions[0].modSohbetler[0].sohbetler.RemoveAt(position);

            if (mods[lastChoosenList].ModSohbetRepetitions[0].modSohbetler[0].sohbetler.Count == 0)
            {
                mods[lastChoosenList].ModSohbetRepetitions.RemoveAt(0);
            }
        }*/
    }

    public void CombineSohbetCategory()
    {
        int a = mods.FindIndex(x => x.mod.Equals(playerData.GetChatVariableValue("mod")));

        if (a>= 0)
        {
            if (mods[a].mod == playerData.GetChatVariableValue("mod").ToLower())
            {
                Debug.Log("dedaedae");
                for (int i = 1; i < mods[a].ModSohbetRepetitions.Count; i++)
                {
                    for (int u = 0; u < mods[a].ModSohbetRepetitions[i].modSohbetler.Count; u++)
                    {
                        mods[a].ModSohbetRepetitions[0].modSohbetler.Add(mods[a].ModSohbetRepetitions[i].modSohbetler[u]);
                    }

                    mods[a].ModSohbetRepetitions[i].modSohbetler = new List<ModSohbet>();
                }

                while (mods[a].ModSohbetRepetitions.Count > 2)
                {
                    mods[a].ModSohbetRepetitions.RemoveAt(mods[a].ModSohbetRepetitions.Count - 1);
                }
            }
        }
    }

    internal IEnumerator OnlineFallariYukle()
    {
        onlineSohbetler = SaveData.LoadOnlineSohbets();

        int count = 0;
        onlineSohbetCache = new Sohbet[onlineSohbetler.Length];
        for(int i = 0; i<onlineSohbetler.Length; i++)
        {
            Sohbet sohbet = ScriptableObject.CreateInstance<Sohbet>();

            sohbet.idIndex = onlineSohbetler[i].ID;

            sohbet.oncelik = onlineSohbetler[i].oncelik;

            sohbet.contentImage = new Sohbet.ContentImage();
            sohbet.contentImage.imageId = onlineSohbetler[i].imageID;
            sohbet.contentImage.gifId = onlineSohbetler[i].gifID;

            sohbet.reklam = onlineSohbetler[i].reklam;

            sohbet.fotografKonum = onlineSohbetler[i].fotografKonum;

            sohbet.ozelFonksiyon = onlineSohbetler[i].ozelFonksiyon;

            sohbet.aciklama = onlineSohbetler[i].aciklamalar;
            sohbet.aciklamaBalonuYok = onlineSohbetler[i].aciklamaBalonuYok;
            sohbet.yeniFocusPaneliKullan = onlineSohbetler[i].yeniFocusPaneliKullan;

            sohbet.parlamaRengi = onlineSohbetler[i].parlamaRengi;
            sohbet.parlamaSuresi = onlineSohbetler[i].parlamaSuresi;

            sohbet.birlestirilecekModlar = onlineSohbetler[i].birlestirilecekModlar;

            sohbet.cevaplar = new List<CevapSohbet>();
            foreach(OnlineCevapSohbetData onlineCevapSohbetData in onlineSohbetler[i].cevaplar)
            {
                CevapSohbet cevapSohbet = new CevapSohbet();
                cevapSohbet.cevapVaryasyonlari = onlineCevapSohbetData.cevapVaryasyonlari;

                cevapSohbet.contentImage = new Sohbet.ContentImage();
                cevapSohbet.contentImage.imageId = onlineCevapSohbetData.imageID;
                cevapSohbet.contentImage.gifId = onlineCevapSohbetData.gifID;

                cevapSohbet.fotografKonum = onlineCevapSohbetData.fotografKonum;

                cevapSohbet.gerekenEnerjiKons = onlineCevapSohbetData.gerekenEnerjiKons;
                cevapSohbet.reklamGoster = onlineCevapSohbetData.reklamGoster;

                cevapSohbet.sonrakiSohbetID = onlineCevapSohbetData.sonrakiSohbetID;

                cevapSohbet.ayarlananDegiskenler = onlineCevapSohbetData.ayarlananDegiskenler;
                cevapSohbet.gerekliDegiskenler = onlineCevapSohbetData.gerekliDegiskenler;

                cevapSohbet.ozelFonksiyon = onlineCevapSohbetData.ozelFonksiyon;
                sohbet.cevaplar.Add(cevapSohbet);
            }

            sohbet.tepkiBalonuYok = onlineSohbetler[i].tepkiBalonuYok;

            sohbet.balonTipi = onlineSohbetler[i].balonTipi;

            sohbet.ayarlananDegiskenler = onlineSohbetler[i].ayarlananDegiskenler;
            sohbet.gerekliDegiskenler = onlineSohbetler[i].gerekliDegiskenler;

            sohbet.sayac = onlineSohbetler[i].sayac;
            sohbet.sayaSonuAnaMenuyeGit = onlineSohbetler[i].sayaSonuAnaMenuyeGit;
            sohbet.sayacModu = onlineSohbetler[i].sayacModu;
            sohbet.sayacSohbetiID = onlineSohbetler[i].sayacSohbetiID;

            sohbet.sayacTipi = onlineSohbetler[i].sayacTipi;

            sohbet.tekrarlama = onlineSohbetler[i].tekrarlama;

            sohbet.sohbetBitimModu = onlineSohbetler[i].sohbetBitimModu;
            sohbet.sohbetBititmindeAnamenuyeDon = onlineSohbetler[i].sohbetBititmindeAnamenuyeDon;
            sohbet.anaMenuyeGitButonuOlustur = onlineSohbetler[i].anaMenuyeGitButonuOlustur;

            sohbet.sohbetEnerjisi = onlineSohbetler[i].sohbetEnerjisi;
            sohbet.sohbetKonsantrasyonu = onlineSohbetler[i].sohbetKonsantrasyonu;

            sohbet.kazima.imageId = onlineSohbetler[i].kazima.imageId;
            sohbet.kazima.gifId = onlineSohbetler[i].kazima.gifId;
            sohbet.kazima.kazimaTipi = onlineSohbetler[i].kazima.kazimaTipi;
            sohbet.kazima.kazimaOrani = onlineSohbetler[i].kazima.kazimaOrani;
            sohbet.kazima.kazimaSonuBekleme = onlineSohbetler[i].kazima.kazimaSonuBekleme;
            sohbet.kazima.kazimaModu = onlineSohbetler[i].kazima.kazimaModu;

            sohbet.otomatikOdak = onlineSohbetler[i].otomatikOdak;
            sohbet.metniKaydet = onlineSohbetler[i].metniKaydet;

            onlineSohbetCache[i] = sohbet;

            count++;

            if (count > onlineCheckPerFrame)
            {
                yield return new WaitForEndOfFrame();
                count = 0;
            }
        }

        var modSohbetManager = FindObjectOfType<ModSohbetManager>();

        modSohbetManager.mods = modSohbetManager.modSohbetManagerData.AddMods(modSohbetManager.mods, onlineSohbetCache);

        playerData.onlineDatabaseLoadEvent.Invoke();
        Debug.Log("<color=green><b>Online fallari olusturma islemi tamamlandi!</b></color>");
    }

    internal void OnlineFallariYukle(Sohbet[] cahche)
    {
        onlineSohbetCache = cahche;

        var modSohbetManager = FindObjectOfType<ModSohbetManager>();

        modSohbetManager.mods = modSohbetManager.modSohbetManagerData.AddMods(modSohbetManager.mods, onlineSohbetCache);

        playerData.onlineDatabaseLoadEvent.Invoke();
        Debug.Log("<color=yellow><b>Online fallar yerel cache dosyasindan basari ile yuklandi!</b></color>");
    }

    public static T DeepCopy<T>(T other)
    {
        using (MemoryStream ms = new MemoryStream())
        {
            BinaryFormatter formatter = new BinaryFormatter();
            formatter.Serialize(ms, other);
            ms.Position = 0;
            return (T)formatter.Deserialize(ms);
        }
    }
}