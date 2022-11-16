using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[SerializeField]
public class MagnuTrisSettings : ScriptableObject
{
    public string genelMod;
    public string cikisModu;
    public string enYuksekSkorGecildiModu;
    public string enYuksekSkorGecilmediModu;
    public string yokEdilenSatir1;
    public string yokEdilenSatir2;
    public string yokEdilenSatir3;
    public string yokEdilenSatir4;
    public string yokEdilenSatirFazla;
    public string bombaYerlestirme;
    public string oyunSonuMesajiDegiskenAdi;
    public string oyunSonuMesajiHamleKalmadi;
    public string oyunSonuMesajiBombaPatladi;
    public string oyunSonuMesajiSureDoldu;
    public string[] sekiller;

    public bool IsMagnuTrisMod(string mod)
    {
        bool returnValue = false;

        if (mod == genelMod || mod == yokEdilenSatir1 || mod == yokEdilenSatir2 || mod == yokEdilenSatir3 || mod == yokEdilenSatir4 || mod == yokEdilenSatirFazla || mod == bombaYerlestirme)
        {
            returnValue = true;
        }
        else
        {
            returnValue = false;

            foreach(string sekilModu in sekiller)
            {
                if (mod == sekilModu)
                {
                    returnValue = true;
                    break;
                }
            }
        }

        return returnValue;
    }
}
