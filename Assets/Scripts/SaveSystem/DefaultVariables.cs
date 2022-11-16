using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DefaultVariables : ScriptableObject
{
    public List<DefaultChatDegiskeni> degiskenler;
    public List<DefaultRenderedText> modaGoreHafizaMetniBulunamadiAciklama;
    public string defaultHafizaMetniBulunamadiAciklama;

    public List<RandomButton> randomButtonlar;

    [System.Serializable]
    public class DefaultChatDegiskeni
    {
        [TextArea(2, 5)]
        public string degiskenAdi;
        [TextArea(2, 5)]
        public string degiskenDegeri;
        public enum ResetType { ifNotDefined, everyLaunch, daily}
        public ResetType resetType;

        public DefaultChatDegiskeni()
        {
            degiskenAdi = "";
            degiskenDegeri = "";
            resetType = ResetType.ifNotDefined;
        }
    }

    [System.Serializable]
    public class DefaultRenderedText
    {
        [TextArea(2, 5)]
        public string mod;
        [TextArea(2, 5)]
        public string standartAciklama;

        public DefaultRenderedText()
        {
            mod = "";
            standartAciklama = "";
        }
    }

    [System.Serializable]
    public class RandomButton
    {
        [TextArea(2, 5)]
        public string butonAdi;
        [TextArea(2, 5)]
        public List<string> butonIcerigi;
    }
}
