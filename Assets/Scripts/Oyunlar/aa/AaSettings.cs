using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AaSettings : ScriptableObject
{
    public GameObject prefab;
    public string mod;

    public string basariModu;
    public int basariModuSayisi = 10;
    public string basariModuMax;

    public string basarisizlikModu;
    public string cikisModu;
    public string oyunSonuModu;

    public bool GetGameMode(string mod)
    {
        return (mod == this.mod || mod.Contains(basariModu) || mod == basariModuMax || mod == basarisizlikModu);
    }

}
