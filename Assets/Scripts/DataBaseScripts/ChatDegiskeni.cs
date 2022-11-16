using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ChatDegiskeni
{
    [TextArea(2, 5)]
    public string degiskenAdi;
    [TextArea(2, 5)]
    public string degiskenDegeri;

    public enum OperatorEnum { esit = 0, esitDegil = 1, buyuk = 2, kucuk = 3, buyukEsit = 4, kucukEsit = 5 }
    public OperatorEnum kontrolOperatoru;

    public enum OperatorAyarlanacakEnum { esitlik = 0, toplama = 1, cikartma = 2, carpma = 3, bolme= 4 }
    public OperatorAyarlanacakEnum ayarlamaOperatoru;

    public ChatDegiskeni()
    {
        degiskenAdi = "";
        degiskenDegeri = "";
    }

    public ChatDegiskeni(string ad, string deger)
    {
        degiskenAdi = ad;
        degiskenDegeri = deger;
    }
}
