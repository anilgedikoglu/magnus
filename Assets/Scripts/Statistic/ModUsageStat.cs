using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModUsageStat : ScriptableObject
{
    public List<ModStat> mods;

    [System.Serializable]
    public class ModStat
    {
        public string mod;
        public string onlineKey;
        public string UITitle;
    }
}
