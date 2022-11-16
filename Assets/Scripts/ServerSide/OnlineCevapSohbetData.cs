using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class OnlineCevapSohbetData
{
    public List<string> cevapVaryasyonlari;
    public string imageID;
    public string gifID;

    public CevapSohbet.contentPhotoLocation fotografKonum;

    public CevapSohbet.EnerjiKonsantrasyon gerekenEnerjiKons;
    public bool reklamGoster = false;

    public List<Sohbet.AyarlanacakDegisken> ayarlananDegiskenler;
    public List<Sohbet.GerekenDegisken> gerekliDegiskenler;

    public string ozelFonksiyon;

    public OnlineCevapSohbetData()
    {
        cevapVaryasyonlari = new List<string>();
        imageID = string.Empty;
        gifID = string.Empty;

        fotografKonum = new CevapSohbet.contentPhotoLocation();

        gerekenEnerjiKons = new CevapSohbet.EnerjiKonsantrasyon();
        reklamGoster = false;

        ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
        gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();

        ozelFonksiyon = string.Empty;
    }
}
