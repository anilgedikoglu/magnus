using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ZoomPanelData : ScriptableObject
{
    public SohbetInceleme.YildizTepki yildizTepkileri;
    public VideoText[] videoTexts;

    [System.Serializable]
    public class SohbetInceleme
    {
        [System.Serializable]
        public class YildizTepki
        {
            public List<string> yildiz1;
            public List<string> yildiz2;
            public List<string> yildiz3;
            public List<string> yildiz4;
            public List<string> yildiz5;
        }
    }

    [System.Serializable]
    public class VideoText
    {
        public Text[] texts;
        public string mod;

        [System.Serializable]
        public class Text
        {
            public string text;

            [Range(0.2f, 5f)]
            public float duration = 1f;
        }
    }

}
