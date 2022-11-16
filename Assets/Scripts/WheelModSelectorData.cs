using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WheelModSelectorData : ScriptableObject
{
    public List<WheelData> datas;

    [System.Serializable]
    public class WheelData
    {
        public Type type;
        public Sprite wheelPhoto;
        public Sprite wheelPhotoHiglLight;

        public Item[] items;

        public string wheelModu;
        public bool showAd;

        public enum Type
        {
            wheel,
            horizontal
        }

        [System.Serializable]
        public class Item
        {
            public string baslik;
            public Sprite fotograf;

            public string ayarlananMod;
            public ChatDegiskeni ayarlananDegiskenler;
        }
    }
}
