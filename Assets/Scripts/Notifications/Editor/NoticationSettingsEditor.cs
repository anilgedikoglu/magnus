using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.UIElements;

[CustomEditor(typeof(NotificationSettings))]
public class NoticationSettingsEditor : Editor
{
    NotificationSettings notificationSettings;
    GUIStyle h1, h2, h3, h4;

    public Texture2D logoSmall, logoLarge;

    private void OnEnable()
    {
        notificationSettings = (NotificationSettings)target;

        logoSmall = Resources.Load<Texture2D>("small");
        logoLarge = Resources.Load<Texture2D>("large");

        notificationSettings.sabah ??= new();
        notificationSettings.ogle ??= new();
        notificationSettings.aksam ??= new();
    }

    private void OnDisable()
    {
        EditorUtility.SetDirty(notificationSettings);
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        h1 = new GUIStyle("label");
        h1.fontSize = 16;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        h2 = new GUIStyle("label");
        h2.fontSize = 14;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        h3 = new GUIStyle("label");
        h3.fontSize = 12;
        h3.fontStyle = FontStyle.Bold;
        h3.wordWrap = true;

        h4 = new GUIStyle("label");
        h4.fontSize = 10;
        h4.fontStyle = FontStyle.Normal;
        h4.wordWrap = true;

        EditorGUILayout.HelpBox("Alt başlık sadece IOS platformunda gösterilir ve boş bırakılmaması gerekir!", MessageType.Warning);
        EditorGUILayout.HelpBox("İçerik bölümlerinin herhangi birisinin boş kalması durumunda platform bildirimi göstermemeyi seçebilir!", MessageType.Warning);

        GUILayout.Label("Zaman Aralıkları", h1);
        GUILayout.Label("Sabah", h2);
        GUILayout.Space(2);
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Başlangıç", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notificationSettings.sabah.startTime = EditorGUILayout.IntSlider(notificationSettings.sabah.startTime, 7, 13);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Bitiş", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notificationSettings.sabah.endTime = EditorGUILayout.IntSlider(notificationSettings.sabah.endTime, 7, 13);
        EditorGUILayout.EndHorizontal();

        GUILayout.Label("Öğle", h2);
        GUILayout.Space(2);
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Başlangıç", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notificationSettings.ogle.startTime = EditorGUILayout.IntSlider(notificationSettings.ogle.startTime, 10, 19);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Bitiş", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notificationSettings.ogle.endTime = EditorGUILayout.IntSlider(notificationSettings.ogle.endTime, 10, 19);
        EditorGUILayout.EndHorizontal();

        GUILayout.Label("Akşam", h2);
        GUILayout.Space(2);
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Başlangıç", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notificationSettings.aksam.startTime = EditorGUILayout.IntSlider(notificationSettings.aksam.startTime, 14, 23);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Bitiş", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notificationSettings.aksam.endTime = EditorGUILayout.IntSlider(notificationSettings.aksam.endTime, 14, 23);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.HelpBox("Zaman aralıklarında bitiş değerleri dahil değildir.", MessageType.Info);

        serializedObject.ApplyModifiedProperties();
        /*
        GUILayout.Space(10);
        GUILayout.Label("Sistem Bildirimleri", h1);

        GUILayout.Space(5);
        GUILayout.Label("Günlük Enerji", h2);
        GUILayout.Space(5);

        DrawNotification(notificationSettings.dailyEnergyNotification, false);

        GUILayout.Space(5);
        GUILayout.Label("Konsantrasyon Dolunca", h2);
        GUILayout.Space(5);

        DrawNotification(notificationSettings.konsantrasyonTimerNotification, false);

        GUILayout.Space(15);
        GUILayout.Label("Özel Bildirimler", h1);
        GUILayout.Space(10);

        int deletedId = -1;
        for (int i = 0; i < notificationSettings.mobileNotifications.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();

            EditorGUILayout.BeginVertical();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Bildirim Adı", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].name = GUILayout.TextArea(notificationSettings.mobileNotifications[i].name, GUILayout.Height(20), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Kategori", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].category = (NotificationSettings.MobileNotification.Category)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].category);
            EditorGUILayout.EndHorizontal();

            GUILayout.Space(10);

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Başlık", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].title = GUILayout.TextArea(notificationSettings.mobileNotifications[i].title, GUILayout.Height(30), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Alt başlık", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].subtitle = GUILayout.TextArea(notificationSettings.mobileNotifications[i].subtitle, GUILayout.Height(30), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Açıklama", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].Body = GUILayout.TextArea(notificationSettings.mobileNotifications[i].Body, GUILayout.Height(100), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Platform", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].platform = (NotificationSettings.MobileNotification.NotificationPlatform)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].platform);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Notification Türü", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notificationSettings.mobileNotifications[i].tip = (NotificationSettings.MobileNotification.NotificationType)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].tip);
            EditorGUILayout.EndHorizontal();

            if (notificationSettings.mobileNotifications[i].tip == NotificationSettings.MobileNotification.NotificationType.sayac)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Süre(saat)");
                notificationSettings.mobileNotifications[i].saat = EditorGUILayout.FloatField(notificationSettings.mobileNotifications[i].saat);
                EditorGUILayout.EndHorizontal();

                GUILayout.Label("Süre ekle");
                EditorGUILayout.BeginHorizontal();
                if (GUILayout.Button("1s"))
                {
                    EditorGUI.FocusTextInControl(null);
                    notificationSettings.mobileNotifications[i].saat += 1;
                }
                if (GUILayout.Button("5s"))
                {
                    EditorGUI.FocusTextInControl(null);
                    notificationSettings.mobileNotifications[i].saat += 1 * 5;
                }
                if (GUILayout.Button("1g"))
                {
                    EditorGUI.FocusTextInControl(null);
                    notificationSettings.mobileNotifications[i].saat += 1 * 24;
                }
                if (GUILayout.Button("5g"))
                {
                    EditorGUI.FocusTextInControl(null);
                    notificationSettings.mobileNotifications[i].saat += 1 * 24 * 5;
                }
                if (GUILayout.Button("1 hafta"))
                {
                    EditorGUI.FocusTextInControl(null);
                    notificationSettings.mobileNotifications[i].saat += 1 * 24 * 7;
                }
                if (GUILayout.Button("1 ay"))
                {
                    EditorGUI.FocusTextInControl(null);
                    notificationSettings.mobileNotifications[i].saat += 1 * 24 * 30;
                }
                EditorGUILayout.EndHorizontal();
            }
            else if (notificationSettings.mobileNotifications[i].tip == NotificationSettings.MobileNotification.NotificationType.belirliTarih)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
                notificationSettings.mobileNotifications[i].gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].gonderilecegiZaman);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Tarih(YYYY/AA/GG)");
                notificationSettings.mobileNotifications[i].yil = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].yil);
                notificationSettings.mobileNotifications[i].ay = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].ay);
                notificationSettings.mobileNotifications[i].gun = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].gun);
                EditorGUILayout.EndHorizontal();

                try
                {
                    System.DateTime tarihKontrol = new System.DateTime(notificationSettings.mobileNotifications[i].yil, notificationSettings.mobileNotifications[i].ay, notificationSettings.mobileNotifications[i].gun);
                }
                catch
                {
                    EditorGUILayout.HelpBox("Girilen yıl, ay ve gün değerleri gerçerk bir tarihi temsil etmemektedir!", MessageType.Error);
                }
            }
            else if (notificationSettings.mobileNotifications[i].tip == NotificationSettings.MobileNotification.NotificationType.yillikTekrar)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
                notificationSettings.mobileNotifications[i].gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].gonderilecegiZaman);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Tarih(AA/GG)");
                //notificationSettings.mobileNotifications[i].yil = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].yil);
                notificationSettings.mobileNotifications[i].ay = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].ay);
                notificationSettings.mobileNotifications[i].gun = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].gun);
                EditorGUILayout.EndHorizontal();

                try
                {
                    System.DateTime tarihKontrol = new System.DateTime(System.DateTime.Now.Year, notificationSettings.mobileNotifications[i].ay, notificationSettings.mobileNotifications[i].gun);
                }
                catch
                {
                    EditorGUILayout.HelpBox("Girilen yıl, ay ve gün değerleri gerçerk bir tarihi temsil etmemektedir!", MessageType.Error);
                }
            }
            else if (notificationSettings.mobileNotifications[i].tip == NotificationSettings.MobileNotification.NotificationType.dogumGunu)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
                notificationSettings.mobileNotifications[i].gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].gonderilecegiZaman);
                EditorGUILayout.EndHorizontal();

                //EditorGUILayout.BeginHorizontal();
                //GUILayout.Label("Tarih(AA/GG)");
                //notificationSettings.mobileNotifications[i].yil = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].yil);
                //notificationSettings.mobileNotifications[i].ay = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].ay);
                //notificationSettings.mobileNotifications[i].gun = EditorGUILayout.IntField(notificationSettings.mobileNotifications[i].gun);
                //EditorGUILayout.EndHorizontal();
            }
            else if (notificationSettings.mobileNotifications[i].tip == NotificationSettings.MobileNotification.NotificationType.haftalik)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
                notificationSettings.mobileNotifications[i].gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notificationSettings.mobileNotifications[i].gonderilecegiZaman);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                GUILayout.Label("Gün(1-7)");
                notificationSettings.mobileNotifications[i].gun = EditorGUILayout.IntSlider(notificationSettings.mobileNotifications[i].gun, 1, 7);

                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndVertical();

            if (GUILayout.Button("-", GUILayout.ExpandWidth(false)))
            {
                deletedId = i;
            }
            EditorGUILayout.EndHorizontal();
            GUILayout.Space(25);
        }

        if (deletedId != -1)
        {
            notificationSettings.mobileNotifications.RemoveAt(deletedId);
        }

        GUILayout.Space(10);
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("Notification ekle"))
        {
            notificationSettings.mobileNotifications.Add(new NotificationSettings.MobileNotification());
        }
        EditorGUILayout.EndHorizontal();*/
    }

    void DrawNotification(NotificationSettings.MobileNotification notification)
    {
        EditorGUILayout.BeginHorizontal();

        EditorGUILayout.BeginVertical();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Bildirim Adı", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.name = GUILayout.TextArea(notification.name, GUILayout.Height(20), GUILayout.ExpandHeight(true));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Kategori", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.category = (NotificationSettings.MobileNotification.Category)EditorGUILayout.EnumPopup(notification.category);
        EditorGUILayout.EndHorizontal();

        GUILayout.Space(10);

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Başlık", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.title = GUILayout.TextArea(notification.title, GUILayout.Height(30), GUILayout.ExpandHeight(true));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Alt başlık", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.subtitle = GUILayout.TextArea(notification.subtitle, GUILayout.Height(30), GUILayout.ExpandHeight(true));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Açıklama", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.Body = GUILayout.TextArea(notification.Body, GUILayout.Height(100), GUILayout.ExpandHeight(true));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Platform", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.platform = (NotificationSettings.MobileNotification.NotificationPlatform)EditorGUILayout.EnumPopup(notification.platform);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Notification Türü", GUILayout.Width(100), GUILayout.ExpandWidth(false));
        notification.tip = (NotificationSettings.MobileNotification.NotificationType)EditorGUILayout.EnumPopup(notification.tip);
        EditorGUILayout.EndHorizontal();

        if (notification.tip == NotificationSettings.MobileNotification.NotificationType.sayac)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Süre(saat)");
            notification.saat = EditorGUILayout.FloatField(notification.saat);
            EditorGUILayout.EndHorizontal();

            GUILayout.Label("Süre ekle");
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("1s"))
            {
                EditorGUI.FocusTextInControl(null);
                notification.saat += 1;
            }
            if (GUILayout.Button("5s"))
            {
                EditorGUI.FocusTextInControl(null);
                notification.saat += 1 * 5;
            }
            if (GUILayout.Button("1g"))
            {
                EditorGUI.FocusTextInControl(null);
                notification.saat += 1 * 24;
            }
            if (GUILayout.Button("5g"))
            {
                EditorGUI.FocusTextInControl(null);
                notification.saat += 1 * 24 * 5;
            }
            if (GUILayout.Button("1 hafta"))
            {
                EditorGUI.FocusTextInControl(null);
                notification.saat += 1 * 24 * 7;
            }
            if (GUILayout.Button("1 ay"))
            {
                EditorGUI.FocusTextInControl(null);
                notification.saat += 1 * 24 * 30;
            }
            EditorGUILayout.EndHorizontal();
        }
        else if (notification.tip == NotificationSettings.MobileNotification.NotificationType.belirliTarih)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notification.gonderilecegiZaman);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Tarih(YYYY/AA/GG)");
            notification.yil = EditorGUILayout.IntField(notification.yil);
            notification.ay = EditorGUILayout.IntField(notification.ay);
            notification.gun = EditorGUILayout.IntField(notification.gun);
            EditorGUILayout.EndHorizontal();

            try
            {
                System.DateTime tarihKontrol = new System.DateTime(notification.yil, notification.ay, notification.gun);
            }
            catch
            {
                EditorGUILayout.HelpBox("Girilen yıl, ay ve gün değerleri gerçerk bir tarihi temsil etmemektedir!", MessageType.Error);
            }
        }
        else if (notification.tip == NotificationSettings.MobileNotification.NotificationType.yillikTekrar)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notification.gonderilecegiZaman);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Tarih(AA/GG)");
            //notification.yil = EditorGUILayout.IntField(notification.yil);
            notification.ay = EditorGUILayout.IntField(notification.ay);
            notification.gun = EditorGUILayout.IntField(notification.gun);
            EditorGUILayout.EndHorizontal();

            try
            {
                System.DateTime tarihKontrol = new System.DateTime(System.DateTime.Now.Year, notification.ay, notification.gun);
            }
            catch
            {
                EditorGUILayout.HelpBox("Girilen yıl, ay ve gün değerleri gerçerk bir tarihi temsil etmemektedir!", MessageType.Error);
            }
        }
        else if (notification.tip == NotificationSettings.MobileNotification.NotificationType.dogumGunu)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notification.gonderilecegiZaman);
            EditorGUILayout.EndHorizontal();

            //EditorGUILayout.BeginHorizontal();
            //GUILayout.Label("Tarih(AA/GG)");
            //notification.yil = EditorGUILayout.IntField(notification.yil);
            //notification.ay = EditorGUILayout.IntField(notification.ay);
            //notification.gun = EditorGUILayout.IntField(notification.gun);
            //EditorGUILayout.EndHorizontal();
        }
        else if (notification.tip == NotificationSettings.MobileNotification.NotificationType.haftalik)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Zaman Dilimi", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.gonderilecegiZaman = (NotificationSettings.MobileNotification.NotificationPushTime)EditorGUILayout.EnumPopup(notification.gonderilecegiZaman);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Gün(1-7)");
            notification.gun = EditorGUILayout.IntSlider(notification.gun, 1, 7);

            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();
    }

    void DrawNotification(NotificationSettings.MobileNotification notification, bool editableTime)
    {
        if (editableTime)
        {
            DrawNotification(notification);
        }
        else
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Başlık", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.title = GUILayout.TextArea(notification.title, GUILayout.Height(30), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Alt başlık", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.subtitle = GUILayout.TextArea(notification.subtitle, GUILayout.Height(30), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Açıklama", GUILayout.Width(100), GUILayout.ExpandWidth(false));
            notification.Body = GUILayout.TextArea(notification.Body, GUILayout.Height(100), GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();
        }


    }
}
