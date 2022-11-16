using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Notification", menuName = "Veri Tabani/Notification")]
public class NotificationMessage : ScriptableObject
{
    [TextArea(1, 5)]
    public string title = "Magnus";
    [TextArea(2,5)]
    public string subtitle = string.Empty;
    [TextArea(2, 5)]
    public string Body = string.Empty;

    public enum NotificationType { sayac, haftalik, belirliTarih, yillikTekrar, dogumGunu };
    public NotificationType tip = NotificationType.belirliTarih;

    public int yil = System.DateTime.Now.Year;
    public int ay = System.DateTime.Now.Month;
    public int gun = 1;
    public float saat = 1;

    public enum NotificationPushTime { sabah, ogle, aksam };
    public NotificationPushTime gonderilecegiZaman = NotificationPushTime.sabah;

    public enum NotificationPlatform { farkEtmez, android = 1, IOS = 2 };
    public NotificationPlatform platform = NotificationPlatform.farkEtmez;

    public List<Sohbet.GerekenDegisken> gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();
}
