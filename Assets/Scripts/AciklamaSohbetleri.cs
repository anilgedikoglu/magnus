using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Magnus
{
    [System.Serializable]
    public class AciklamaSohbetleri
    {
        public Sohbet sohbet;
        public string mod;

        public AciklamaSohbetleri(string mod)
        {
            this.mod = mod;
            sohbet = ScriptableObject.CreateInstance("Sohbet") as Sohbet;
        }
    }
}