using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MagnusWordDatabase : ScriptableObject
{
    public wordData[] words;

    public string wordGameMod;
    public string wordGameTrueMod;

    [System.Serializable]
    public class wordData
    {
        public string word;
        public string[] tipMods;
    }
}
