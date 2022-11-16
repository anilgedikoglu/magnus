using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ModSohbet
{
    public List<Sohbet> sohbetler;
    public int repetition; 

    public ModSohbet()
    {
        sohbetler = new List<Sohbet>();
    }

    public ModSohbet(List<Sohbet> sohbets)
    {
        sohbetler = sohbets;
    }
}
