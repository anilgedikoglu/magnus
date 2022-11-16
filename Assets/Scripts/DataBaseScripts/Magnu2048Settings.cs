using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Magnu2048Settings : ScriptableObject
{
    public string genelMod;
    public string cikisModu;
    public string cikisVazgecmeModu;
    public string rekorGecildiModu;
    public string rekorGecilmediModu;
    public string Puan4Modu;
    public string Puan8Modu;
    public string Puan16Modu;
    public string Puan32odu;
    public string Puan64Modu;
    public string Puan128Modu;
    public string Puan256Modu;
    public string Puan512Modu;
    public string Puan1024Modu;
    public string Puan2048Modu;
    public string Puan5096Modu;
    public string PuanCokFazlaModu;
    public int sohbetEtmeSansi = 50;

    
    public bool IsMagnu2048Mod(string mod)
    {
        if (mod == genelMod || mod == Puan4Modu || mod == Puan8Modu || mod == Puan16Modu || mod == Puan32odu || mod == Puan64Modu || mod == Puan128Modu
            || mod == Puan256Modu || mod == Puan512Modu || mod == Puan1024Modu || mod == Puan2048Modu || mod == Puan5096Modu || mod == PuanCokFazlaModu
            || mod == cikisModu || mod == cikisVazgecmeModu)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
}
