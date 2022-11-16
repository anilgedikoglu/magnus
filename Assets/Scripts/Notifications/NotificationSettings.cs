using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NotificationSettings : ScriptableObject
{
    public List<MobileNotification> mobileNotifications = new();

    public TimeRange sabah = new();
    public TimeRange ogle = new();
    public TimeRange aksam = new();

    [System.Serializable]
    public class MobileNotification
    {
        public string name;

        public string title;
        public string subtitle;
        public string Body;

        public enum Category { yildaBirKez, tekrarlayan, neredesin, diger};
        public Category category;

        public enum NotificationType { sayac,haftalik, belirliTarih,  yillikTekrar, dogumGunu};
        public NotificationType tip;

        public int yil = System.DateTime.Now.Year;
        public int ay = System.DateTime.Now.Month;
        public int gun = 1;
        public float saat;

        public enum NotificationPushTime { sabah, ogle, aksam};
        public NotificationPushTime gonderilecegiZaman;

        public enum NotificationPlatform { farkEtmez,android=1, IOS=2};
        public NotificationPlatform platform;
    }

    [System.Serializable]
    public class TimeRange
    {
        public int startTime;
        public int endTime;
        
        public TimeRange()
        {
            startTime = 9;
            endTime = 12;
        }
    }
}
