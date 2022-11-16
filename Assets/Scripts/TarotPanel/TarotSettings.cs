using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TarotSettings : ScriptableObject
{
    public string modTarotFaliOku;
    public string tarotGecmisKartiSecModu;
    public string tarotSimdiKartiSecModu;
    public string tarotGelecekKartiSecModu;
    public string tarotTumuKartSecModu;
    public List<TarotCardMod> tarotGecmisModlari;
    public List<TarotCardMod> tarotSimdiModlari;
    public List<TarotCardMod> tarotGelecekModlari;

    //Bu iki degisken ayni kartlarin iki kere gelmemesi icin kontrol amacli hafizada tutulur.
    [HideInInspector] public string sonSecilenGecmisTarotKartiModu;
    [HideInInspector] public string sonSecilenSimdiTarotKartiModu;

    [HideInInspector] public string creatorWindowVazgecmeTepkisi = "Vazgeçtim";
    [HideInInspector] public string creatorWindowSohbetAciklama = "Sohbet açıklaması";
    public bool IsTarotCardPickerMod(string mod)
    {
        bool value = false;

        if (mod == tarotGecmisKartiSecModu || mod == tarotSimdiKartiSecModu || mod == tarotGelecekKartiSecModu || mod == tarotTumuKartSecModu)
        {
            value = true;
        }
        else 
        {
            foreach(TarotCardMod cardMod in tarotGecmisModlari)
            {
                if (mod == cardMod.mod + " tepki")
                {
                    value = true;
                    break;
                }
            }

            foreach (TarotCardMod cardMod in tarotSimdiModlari)
            {
                if (mod == cardMod.mod + " tepki")
                {
                    value = true;
                    break;
                }
            }

            foreach (TarotCardMod cardMod in tarotGelecekModlari)
            {
                if (mod == cardMod.mod + " tepki")
                {
                    value = true;
                    break;
                }
            }
        }

        return value;
    }

    public bool IsTarotGecmisMod(string mod)
    {
        /*
        if (tarotGecmisModlari.Exists(x => x.mod.Equals(mod)))
        {
            return true;
        }
        else
        {
            return false;
        }*/

        return true;
    }

    [System.Serializable]
    public class TarotCardMod
    {
        public string mod;
        public List<string> excludedMods;

        public TarotCardMod()
        {
            mod = "";
            excludedMods = new List<string>();
        }
    }
}
