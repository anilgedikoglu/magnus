using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DegiskeneGoreSohbetOlusturucuData : ScriptableObject
{
    public List<Degisken> degiskenler;

    public List<Degisken> onTanimliDegiskenler;

    public List<Data> datas;

    public int menuState;

    [System.Serializable]
    public  class Data
    {
        [TextArea(2,5)]
        public string sohbetAdi;
        [TextArea(10, 20)]
        public string aciklama;
        public List<Sohbet.GerekenDegisken> gerekenDegiskenler;
    }

    [System.Serializable]
    public class Degisken
    {
        public string degiskenAdi;
        public List<string> degiskenDegerleri;

        public Degisken()
        {
            degiskenAdi = "değişken adı";
            degiskenDegerleri = new List<string>() { "değer 1", "değer 2" };
        }

        public Degisken Clone()
        {
            Degisken degisken = new Degisken();

            degisken.degiskenAdi = this.degiskenAdi;
            degisken.degiskenDegerleri = new List<string>(degiskenDegerleri);

            return degisken;
        }
    }
}
