using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class RenderedText
{
    public string name;
    public List<Text> renderedTexts;

    public RenderedText(string name, string mod, string renderedText, string photoId, string ID, Text.UIInformation uIInformation)
    {
        this.name = name;
        this.renderedTexts = new List<Text>();
        this.renderedTexts.Add(new Text(mod, renderedText, photoId, ID, uIInformation));
    }

    public RenderedText(string name, string mod, string renderedText, string photoId, string ID, bool isOpened,Text.UIInformation uIInformation)
    {
        this.name = name;
        this.renderedTexts = new List<Text>();
        this.renderedTexts.Add(new Text(mod, renderedText, photoId, ID, isOpened,uIInformation));
    }

    public RenderedText(string name)
    {
        this.name = name;
        this.renderedTexts = new List<Text>();
    }

    public RenderedText()
    {
        this.name = "";
        this.renderedTexts = new List<Text>();
    }

    [System.Serializable]
    public class Text
    {
        public string mod;
        public string date;
        public string text;
        public string photoId;
        public string ID;
        public bool isOpened;
        public int priority;
        public UIInformation uIInformation;

        public Text()
        {
            mod = string.Empty;
            text = string.Empty;
            photoId = string.Empty;
            this.date = System.DateTime.Now.ToString();
            this.ID = string.Empty;
            this.isOpened = false;
            this.uIInformation = new();
            priority = 0;
        }

        public Text(string mod, string text)
        {
            this.mod = mod;
            this.text = text;
            photoId = string.Empty;
            this.date = System.DateTime.Now.ToString();
            this.ID = string.Empty;
            this.uIInformation = new();
        }

        public Text(string mod, string text, string photoId, string ID, UIInformation uIInformation)
        {
            this.mod = mod;
            this.text = text;
            this.photoId = photoId;
            this.date = System.DateTime.Now.ToString();
            this.ID = ID;
            isOpened = false;
            this.uIInformation = uIInformation;
        }

        public Text(string mod, string text, string photoId, string ID, bool isOpened, UIInformation uIInformation)
        {
            this.mod = mod;
            this.text = text;
            this.photoId = photoId;
            this.date = System.DateTime.Now.ToString();
            this.ID = ID;
            this.isOpened = isOpened;
            this.uIInformation = uIInformation;
        }

        [System.Serializable]
        public class UIInformation
        {
            public string title;
            public string onlinePhotoID;
            public long showTimeStamp;
            public long firstTimeStamp;

            public UIInformation()
            {
                title = string.Empty;
                onlinePhotoID = string.Empty;
            }

            public UIInformation(string title, long showTimeStamp)
            {
                this.title = title;
                this.showTimeStamp = showTimeStamp;
                firstTimeStamp = Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now);
            }

            public UIInformation(string title, string onlinePhotoID)
            {
                this.title = title;
                this.onlinePhotoID = onlinePhotoID;
                firstTimeStamp = 0;
                showTimeStamp = 0;
            }
        }
    }
}
