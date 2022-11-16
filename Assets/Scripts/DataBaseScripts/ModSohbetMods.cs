using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ModSohbetMods
{
    public string mod;
    public List<ModSohbetRepetitions> ModSohbetRepetitions;

    public ModSohbetMods()
    {
        mod = string.Empty;
        ModSohbetRepetitions = new List<ModSohbetRepetitions>();
    }

    public ModSohbetMods(string mod)
    {
        this.mod = mod;
        ModSohbetRepetitions = new List<ModSohbetRepetitions>();
    }
}