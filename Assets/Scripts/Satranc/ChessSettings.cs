using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ChessSettings : ScriptableObject
{
    public string genelSatrancModu;
    public string kazanmaModu;
    public string terkEtmeModu;
    public string kaybetmeModu;
    public string berabereModu;
    public string tasOynanamazModu;
    public string hareketDegerlendirmeModu;
    public string kendiHareketiniDegerlendirmeModu;
    public string checkKullaniciModu;
    public string checkMagnusModu;
    public string castlingModu;
    public string kullaniciPiyonYediModu;
    public string kullaniciKaleYediModu;
    public string kullaniciFilYediModu;
    public string kullaniciAtYediModu;
    public string kullaniciSahYediModu;
    public string kullaniciVezirYediModu;
    public string magnusPiyonYediModu;
    public string magnusKaleYediModu;
    public string magnusFilYediModu;
    public string magnusAtYediModu;
    public string magnusSahYediModu;
    public string magnusVezirYediModu;
    public int hareketDegerlendirmeSansi;
    public int kendiHareketiniDegerlendirmeSansi;

    public bool IsChessMod(string mod)
    {
        if (mod == genelSatrancModu || mod == terkEtmeModu || mod == kazanmaModu || mod == kaybetmeModu || mod == berabereModu || mod == tasOynanamazModu || mod == hareketDegerlendirmeModu || mod == kendiHareketiniDegerlendirmeModu || mod == checkKullaniciModu ||
            mod == checkMagnusModu || mod == castlingModu || mod == kullaniciPiyonYediModu || mod == kullaniciKaleYediModu || mod == kullaniciFilYediModu || mod == kullaniciAtYediModu
            || mod == kullaniciSahYediModu || mod == kullaniciVezirYediModu || mod == magnusPiyonYediModu || mod == magnusKaleYediModu || mod == magnusFilYediModu || mod == magnusAtYediModu || mod == magnusSahYediModu || mod == magnusVezirYediModu)
        {
            return true;
        }
        else return false;
    }
}
