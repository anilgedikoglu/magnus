using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MagNukemSettings : ScriptableObject
{
    public string genelMod;
    public string cikisModu;
    public string enYuksekSkorGecildiModu;
    public string enYuksekSkorGecilmediModu;
    public string enYuksekSkorGecildiEnerjiModu;
    public string enYuksekSkorGecilmediEnerjiModu;
    public string isabetModu;
    public string iskaModu;
    public string sureModu;
    public string oldurmeModu;

    public int konusmaSansi = 10;

    public bool IsMagNukeMod(string mod)
    {
        bool returnValue = false;

        if (mod == genelMod || mod == isabetModu || mod == iskaModu || mod.Contains(sureModu) || mod == oldurmeModu)
        {
            returnValue = true;
        }

        return returnValue;
    }
}
