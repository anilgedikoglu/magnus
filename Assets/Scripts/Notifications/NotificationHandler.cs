using System.Collections; using System.Collections.Generic; using UnityEngine;
using System;

#if UNITY_ANDROID using Unity.Notifications.Android;
#elif UNITY_IOS using Unity.Notifications.iOS;
#endif  public class NotificationHandler : MonoBehaviour {
    public NotificationSettings notificationSettings;      ChatVariables chatVariables;     CurrentPlayerData playerData;      private NotificationMessage konsantrasyonBildirim, enerjiBildirimi;      public List<NotificationMessage> notificationMessages;
    public List<NotificationMessage> notificationMessagesEnergy;
    public List<NotificationMessage> notificationMessagesKons;     List<DateTime> notificationRealDates = new List<DateTime>();      // Start is called before the first frame update     void Start()     {
        //Online
        Firebase.Messaging.FirebaseMessaging.TokenReceived += OnTokenReceived;
        Firebase.Messaging.FirebaseMessaging.MessageReceived += OnMessageReceived;

        //Local
        notificationMessages = new List<NotificationMessage>(Resources.LoadAll<NotificationMessage>($"{ModSohbetManagerData.localDatabaseName}/Notifications"));
        notificationMessagesEnergy = new List<NotificationMessage>(Resources.LoadAll<NotificationMessage>($"{ModSohbetManagerData.localDatabaseName}/NotificationsEnerjiKons/Enerji"));
        notificationMessagesKons = new List<NotificationMessage>(Resources.LoadAll<NotificationMessage>($"{ModSohbetManagerData.localDatabaseName}/NotificationsEnerjiKons/Kons"));

        notificationMessages.Shuffle();
        notificationMessagesEnergy.Shuffle();
        notificationMessagesKons.Shuffle();

        notificationRealDates = new List<DateTime>();

        chatVariables = FindObjectOfType<ChatVariables>();
        playerData = FindObjectOfType<CurrentPlayerData>();

#if UNITY_IOS         StartCoroutine(RequestIOSNotificationAuthorization()); #endif     } 
    public void OnTokenReceived(object sender, Firebase.Messaging.TokenReceivedEventArgs token)
    {
        UnityEngine.Debug.Log("Received Registration Token: " + token.Token);
    }

    public void OnMessageReceived(object sender, Firebase.Messaging.MessageReceivedEventArgs e)
    {
        UnityEngine.Debug.Log("Received a new message from: " + e.Message.From);
    }      private void OnApplicationFocus(bool focus)
    {
#if !UNITY_EDITOR
        if (focus)
        {
            //DeleteAllNotifications();
        }
        else
        {
            DeleteAllNotifications();
            CreateAndriodNotificationChannel();
            SendNotification();
            SendDailyEnergyNotification();
            SendFalHazirNotification();
        }
#endif
    }

    private void OnApplicationQuit()
    {
#if !UNITY_EDITOR
        /*
        DeleteAllNotifications();
        CreateAndriodNotificationChannel();
        SendNotification();
        SendDailyEnergyNotification();
        SendFalHazirNotification();
        */
#endif 
    }

    // Update is called once per frame
    void Update()     {      }      void DeleteAllNotifications()     {  
#if UNITY_ANDROID         //Android         AndroidNotificationCenter.CancelAllNotifications(); 
#elif UNITY_IOS         //IOS         iOSNotificationCenter.RemoveAllScheduledNotifications();         iOSNotificationCenter.RemoveAllDeliveredNotifications(); 
#endif     }      void CreateAndriodNotificationChannel()     {

#if UNITY_ANDROID         //Android         var channel = new AndroidNotificationChannel()         {             Id = "magnusNots",             Name = "Default Channel",             Importance = Importance.Default,             Description = "Generic notifications",         };         AndroidNotificationCenter.RegisterNotificationChannel(channel);
#endif
    }      void SendNotification()     {
        int notificationCount = 0;
         for (int i = 0; i < notificationMessages.Count; i++)
        {
            NotificationMessage mobileNotification = notificationMessages[i];

            bool isCompatible = true;

            foreach (Sohbet.GerekenDegisken degisken in mobileNotification.gerekliDegiskenler)
            {
                if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                {
                    if (degisken.degiskenDegeri != playerData.GetChatVariableValue(degisken.degiskenAdi))
                    {
                        Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                        isCompatible = false;
                        break;
                    }
                }
                else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                {
                    if (degisken.degiskenDegeri == playerData.GetChatVariableValue(degisken.degiskenAdi))
                    {
                        Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                        isCompatible = false;
                        break;
                    }
                }
                else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                {
                    int currentValue;
                    int savedValue;

                    int.TryParse(degisken.degiskenDegeri, out currentValue);
                    int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                    if (!(savedValue >  currentValue))
                    {
                        Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                        isCompatible = false;
                        break;
                    }
                }
                else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                {
                    int currentValue;
                    int savedValue;

                    int.TryParse(degisken.degiskenDegeri, out currentValue);
                    int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                    if (!(savedValue >= currentValue))
                    {
                        Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                        isCompatible = false;
                        break;
                    }
                }
                else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                {
                    int currentValue;
                    int savedValue;

                    int.TryParse(degisken.degiskenDegeri, out currentValue);
                    int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                    if (!(savedValue < currentValue))
                    {
                        Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                        isCompatible = false;
                        break;
                    }
                }
                else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                {
                    int currentValue;
                    int savedValue;

                    int.TryParse(degisken.degiskenDegeri, out currentValue);
                    int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                    if (!(savedValue <= currentValue))
                    {
                        Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                        isCompatible = false;
                        break;
                    }
                }
            }

            if (isCompatible)
            {
#if UNITY_ANDROID
                //Sayac
                if (notificationCount < 15)
                {
                    if (mobileNotification.tip == NotificationMessage.NotificationType.sayac)
                    {
                        if (mobileNotification.platform == NotificationMessage.NotificationPlatform.android
                            || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            DateTime realDate = DateTime.Today.AddHours(mobileNotification.saat);

                            if (!notificationRealDates.Contains(realDate))
                            {
                                notificationRealDates.Add(realDate);

                                notificationCount += 1;
                                var notificationAndoid = new AndroidNotification();
                                notificationAndoid.Title = chatVariables.OrtakButonlar(mobileNotification.title);
                                notificationAndoid.Text = chatVariables.OrtakButonlar(mobileNotification.Body);

                                notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                                notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                                notificationAndoid.FireTime = System.DateTime.Now.AddHours(mobileNotification.saat);

                                notificationAndoid.SmallIcon = "logo_small";
                                notificationAndoid.LargeIcon = "logo_large";
                                notificationAndoid.Style = NotificationStyle.BigTextStyle;

                                if (notificationAndoid.FireTime.Hour > 8 && notificationAndoid.FireTime.Hour < 22)
                                {
                                    Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                    AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                                }
                                else
                                {
                                    if (notificationAndoid.FireTime.Hour < 24 && notificationAndoid.FireTime.Hour > 22)
                                        notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month, notificationAndoid.FireTime.Day + 1, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);
                                    else
                                        notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month, notificationAndoid.FireTime.Day, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);

                                    Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                    AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                                }
                            }
                        }
                    }
                }

                //BelirliTarih
                if (mobileNotification.tip == NotificationMessage.NotificationType.belirliTarih)
                {
                    if (notificationCount < 15)
                    {
                        DateTime fireTime;
                        if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                        {
                            fireTime = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                        }
                        else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                        {
                            fireTime = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                        }
                        else
                        {
                            fireTime = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                        }

                        double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                        if (dayDifference <= 7 && dayDifference > 0)
                        {

                            if (mobileNotification.platform == NotificationMessage.NotificationPlatform.android
                                || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                            {
                                DateTime realDate = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, 0, 0, 0);

                                if (!notificationRealDates.Contains(realDate))
                                {
                                    notificationRealDates.Add(realDate);

                                    notificationCount += 1;
                                    var notificationAndoid = new AndroidNotification();
                                    notificationAndoid.Title = chatVariables.OrtakButonlar(mobileNotification.title);
                                    notificationAndoid.Text = chatVariables.OrtakButonlar(mobileNotification.Body);

                                    notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                                    notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                                    notificationAndoid.FireTime = System.DateTime.Now.AddMinutes((fireTime - System.DateTime.Now).TotalMinutes);

                                    notificationAndoid.SmallIcon = "logo_small";
                                    notificationAndoid.LargeIcon = "logo_large";
                                    notificationAndoid.Style = NotificationStyle.BigTextStyle;

                                    Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                    AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                                }
                            }
                        }
                    }
                }

                //BelirliTarihTekrar
                if (mobileNotification.tip == NotificationMessage.NotificationType.yillikTekrar)
                {
                    if (notificationCount < 15)
                    {
                        DateTime fireTime;
                        if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                        {
                            fireTime = new DateTime(System.DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                        }
                        else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                        {
                            fireTime = new DateTime(System.DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                        }
                        else
                        {
                            fireTime = new DateTime(System.DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                        }

                        double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                        if (dayDifference <= 7 && dayDifference > 0)
                        {
                            DateTime realDate = new DateTime(System.DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, 0, 0, 0);

                            if (!notificationRealDates.Contains(realDate))
                            {
                                notificationRealDates.Add(realDate);

                                if (mobileNotification.platform == NotificationMessage.NotificationPlatform.android
                                || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                                {
                                    notificationCount += 1;
                                    var notificationAndoid = new AndroidNotification();
                                    notificationAndoid.Title = chatVariables.OrtakButonlar(mobileNotification.title);
                                    notificationAndoid.Text = chatVariables.OrtakButonlar(mobileNotification.Body);

                                    notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                                    notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                                    notificationAndoid.FireTime = System.DateTime.Now.AddMinutes((fireTime - System.DateTime.Now).TotalMinutes);

                                    notificationAndoid.SmallIcon = "logo_small";
                                    notificationAndoid.LargeIcon = "logo_large";
                                    notificationAndoid.Style = NotificationStyle.BigTextStyle;

                                    Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                    AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                                }
                            }
                        }
                    }
                }

                //DogumYili
                if (mobileNotification.tip == NotificationMessage.NotificationType.yillikTekrar)
                {
                    if (notificationCount < 15)
                    {
                        int day;
                        int month;
                        int year;

                        int.TryParse(playerData.GetChatVariableValue("dogum gunu"), out day);
                        int.TryParse(playerData.GetChatVariableValue("dogum ayi"), out month);
                        int.TryParse(playerData.GetChatVariableValue("dogum yili"), out year);

                        DateTime fireTime;
                        if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                        {
                            try
                            {
                                fireTime = new DateTime(year, month, day, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                            }
                            catch
                            {
                                fireTime = new DateTime(System.DateTime.Now.Year, 12, 30, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                            }
                        }
                        else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                        {
                            try
                            {
                                fireTime = new DateTime(year, month, day, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                            }
                            catch
                            {
                                fireTime = new DateTime(System.DateTime.Now.Year, 12, 30, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                            }
                        }
                        else
                        {
                            try
                            {
                                fireTime = new DateTime(year, month, day, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                            }
                            catch
                            {
                                fireTime = new DateTime(System.DateTime.Now.Year, 12, 30, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                            }
                        }

                        double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                        if (dayDifference <= 7 && dayDifference > 0)
                        {

                            if (mobileNotification.platform == NotificationMessage.NotificationPlatform.android
                                || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                            {
                                DateTime realDate = new DateTime(year, month, day, 0, 0, 0);

                                if (!notificationRealDates.Contains(realDate))
                                {
                                    notificationRealDates.Add(realDate);


                                    notificationCount += 1;
                                    var notificationAndoid = new AndroidNotification();
                                    notificationAndoid.Title = chatVariables.OrtakButonlar(mobileNotification.title);
                                    notificationAndoid.Text = chatVariables.OrtakButonlar(mobileNotification.Body);

                                    notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                                    notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                                    notificationAndoid.FireTime = System.DateTime.Now.AddMinutes((fireTime - System.DateTime.Now).TotalMinutes);

                                    notificationAndoid.SmallIcon = "logo_small";
                                    notificationAndoid.LargeIcon = "logo_large";
                                    notificationAndoid.Style = NotificationStyle.BigTextStyle;

                                    Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                    AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                                }
                            }
                        }
                    }
                }

                //Haftalık
                if (mobileNotification.tip == NotificationMessage.NotificationType.haftalik)
                {
                    if (notificationCount < 15)
                    {
                        DateTime fireTime;

                        int dayOfWeek = ((int)DateTime.Now.DayOfWeek) != 0 ? ((int)DateTime.Now.DayOfWeek) : 7;
                        int difference = (mobileNotification.gun - dayOfWeek) >= 0 ? mobileNotification.gun - dayOfWeek : mobileNotification.gun - dayOfWeek + 7;
                        fireTime = DateTime.Now.AddDays(difference);

                        if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                        {
                            int fireTimeHour = UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime);
                            fireTime = fireTime.AddHours(fireTimeHour - fireTime.Hour);
                        }
                        else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                        {
                            int fireTimeHour = UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime);
                            fireTime = fireTime.AddHours(fireTimeHour - fireTime.Hour);
                        }
                        else
                        {
                            int fireTimeHour = UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime);
                            fireTime = fireTime.AddHours(fireTimeHour - fireTime.Hour);
                        }
                        double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                        if (dayDifference <= 7 && dayDifference > 0)
                        {

                            if (mobileNotification.platform == NotificationMessage.NotificationPlatform.android
                                || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                            {
                                DateTime realDate = DateTime.Today.AddDays(difference);

                                if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                                {
                                    realDate = realDate.AddHours(3);
                                }
                                else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                                {
                                    realDate = realDate.AddHours(2);
                                }
                                else
                                {
                                    realDate = realDate.AddHours(1);
                                }

                                if (!notificationRealDates.Contains(realDate))
                                {
                                    notificationRealDates.Add(realDate);

                                    notificationCount += 1;
                                    var notificationAndoid = new AndroidNotification();
                                    notificationAndoid.Title = chatVariables.OrtakButonlar(mobileNotification.title);
                                    notificationAndoid.Text = chatVariables.OrtakButonlar(mobileNotification.Body);

                                    notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                                    notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                                    notificationAndoid.FireTime = System.DateTime.Now.AddMinutes((fireTime - System.DateTime.Now).TotalMinutes);

                                    notificationAndoid.SmallIcon = "logo_small";
                                    notificationAndoid.LargeIcon = "logo_large";
                                    notificationAndoid.Style = NotificationStyle.BigTextStyle;

                                    Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                    AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                                }
                                else
                                {
                                    Debug.Log("Aynı tarihe kurulu baika bir push olduğu için yoksayıldı");
                                }
                            }
                        }
                    }
                }



#elif UNITY_IOS
                //IOS

                                //Sayac
                if (notificationCount < 15)
                {
                    if (mobileNotification.tip == NotificationMessage.NotificationType.sayac)
                    {
                        if (mobileNotification.platform == NotificationMessage.NotificationPlatform.IOS
                    || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            DateTime realDate = DateTime.Today.AddHours(mobileNotification.saat);

                            if (!notificationRealDates.Contains(realDate))
                            {
                                notificationRealDates.Add(realDate);

                                DateTime fireTime = DateTime.Now.AddHours(konsantrasyonBildirim.saat);

                                if (!(fireTime.Hour > 8 && fireTime.Hour < 22))
                                {
                                    if (fireTime.Hour < 24 && fireTime.Hour > 22)
                                        fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day + 1, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
                                    else
                                        fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
                                }

                                var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                                {
                                    TimeInterval = (DateTime.Now.AddHours(mobileNotification.saat) - DateTime.Now),
                                    Repeats = false
                                };

                                var notificationIOS = new iOSNotification()
                                {
                                    // You can specify a custom identifier which can be used to manage the notification later.
                                    // If you don't provide one, a unique string will be generated automatically.
                                    Title = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.title)),
                                    Body = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.Body)),
                                    Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.subtitle)),
                                    ShowInForeground = true,
                                    ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                                    CategoryIdentifier = "category_a",
                                    ThreadIdentifier = "thread1",
                                    Trigger = timeTrigger,
                                };

                                Debug.Log(timeTrigger.TimeInterval);
                                Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));

                                if (timeTrigger.TimeInterval.Minutes > 0)
                                {
                                    notificationCount += 1;
                                    iOSNotificationCenter.ScheduleNotification(notificationIOS);
                                }
                                else
                                {
                                    Debug.Log("Notification kurulamadı. Time interval 0dan kucuk");
                                }
                            }
                        }
                    }
                }

                //Haftalik
                if (notificationCount < 15)
                {
                    if (mobileNotification.tip == NotificationMessage.NotificationType.haftalik)
                    {
                        if (mobileNotification.platform == NotificationMessage.NotificationPlatform.IOS
                    || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            DateTime fireTime;

                            int dayOfWeek = ((int)DateTime.Now.DayOfWeek) != 0 ? ((int)DateTime.Now.DayOfWeek) : 7;
                            int difference = (mobileNotification.gun - dayOfWeek) >= 0 ? mobileNotification.gun - dayOfWeek : mobileNotification.gun - dayOfWeek + 7;
                            fireTime = DateTime.Now.AddDays(difference);

                            if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                            {
                                int fireTimeHour = UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime);
                                fireTime = fireTime.AddHours(fireTimeHour - fireTime.Hour);
                            }
                            else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                            {
                                int fireTimeHour = UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime);
                                fireTime = fireTime.AddHours(fireTimeHour - fireTime.Hour);
                            }
                            else
                            {
                                int fireTimeHour = UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime);
                                fireTime = fireTime.AddHours(fireTimeHour - fireTime.Hour);
                            }

                            if ((fireTime - DateTime.Now).TotalHours > 0)
                            {
                                var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                                {
                                    TimeInterval = new TimeSpan((int)(fireTime - DateTime.Now).TotalHours, 0, 0),
                                    Repeats = false
                                };

                                double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                                if (dayDifference <= 7 && dayDifference > 0)
                                {
                                    DateTime realDate = DateTime.Today.AddDays(difference);

                                    if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                                    {
                                        realDate = realDate.AddHours(3);
                                    }
                                    else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                                    {
                                        realDate = realDate.AddHours(2);
                                    }
                                    else
                                    {
                                        realDate = realDate.AddHours(1);
                                    }

                                    if (!notificationRealDates.Contains(realDate))
                                    {
                                        notificationRealDates.Add(realDate);

                                        var notificationIOS = new iOSNotification()
                                        {
                                            // You can specify a custom identifier which can be used to manage the notification later.
                                            // If you don't provide one, a unique string will be generated automatically.
                                            Title = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.title)),
                                            Body = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.Body)),
                                            Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.subtitle)),
                                            ShowInForeground = true,
                                            ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                                            CategoryIdentifier = "category_a",
                                            ThreadIdentifier = "thread1",
                                            Trigger = timeTrigger,
                                        };
                                        Debug.Log(timeTrigger.TimeInterval);
                                        Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));

                                        notificationCount += 1;
                                        iOSNotificationCenter.ScheduleNotification(notificationIOS);
                                    }
                                }
                            }
                        }
                    }
                }

                //BelirliTarih
                if (notificationCount < 15)
                {
                    if (mobileNotification.tip == NotificationMessage.NotificationType.belirliTarih)
                    {
                        if (mobileNotification.platform == NotificationMessage.NotificationPlatform.IOS
                    || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            DateTime fireTime;
                            if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                            {
                                fireTime = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                            }
                            else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                            {
                                fireTime = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                            }
                            else
                            {
                                fireTime = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                            }

                            if ((fireTime - DateTime.Now).TotalHours > 0)
                            {
                                var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                                {
                                    TimeInterval = new TimeSpan((int)(fireTime - DateTime.Now).TotalHours, 0, 0),
                                    Repeats = false
                                };

                                double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                                if (dayDifference <= 7 && dayDifference > 0)
                                {
                                    DateTime realDate = new DateTime(mobileNotification.yil, mobileNotification.ay, mobileNotification.gun, 0, 0, 0);

                                    if (!notificationRealDates.Contains(realDate))
                                    {
                                        notificationRealDates.Add(realDate);
                                        var notificationIOS = new iOSNotification()
                                        {
                                            // You can specify a custom identifier which can be used to manage the notification later.
                                            // If you don't provide one, a unique string will be generated automatically.
                                            Title = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.title)),
                                            Body = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.Body)),
                                            Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.subtitle)),
                                            ShowInForeground = true,
                                            ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                                            CategoryIdentifier = "category_a",
                                            ThreadIdentifier = "thread1",
                                            Trigger = timeTrigger,
                                        };
                                        Debug.Log(timeTrigger.TimeInterval);
                                        Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));

                                        notificationCount += 1;
                                        iOSNotificationCenter.ScheduleNotification(notificationIOS);
                                    }
                                }
                            }
                        }
                    }
                }

                //BelirliTarihHerYil
                if (notificationCount < 15)
                {
                    if (mobileNotification.tip == NotificationMessage.NotificationType.yillikTekrar)
                    {
                        if (mobileNotification.platform == NotificationMessage.NotificationPlatform.IOS
                    || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            DateTime fireTime;
                            if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                            {
                                fireTime = new DateTime(DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                            }
                            else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                            {
                                fireTime = new DateTime(DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                            }
                            else
                            {
                                fireTime = new DateTime(DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                            }

                            if ((fireTime - DateTime.Now).TotalHours > 0)
                            {
                                var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                                {
                                    TimeInterval = new TimeSpan((int)(fireTime - DateTime.Now).TotalHours, 0, 0),
                                    Repeats = false
                                };

                                double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                                if (dayDifference <= 7 && dayDifference > 0)
                                {
                                    DateTime realDate = new DateTime(System.DateTime.Now.Year, mobileNotification.ay, mobileNotification.gun, 0, 0, 0);

                                    if (!notificationRealDates.Contains(realDate))
                                    {
                                        notificationRealDates.Add(realDate);
                                        var notificationIOS = new iOSNotification()
                                        {
                                            // You can specify a custom identifier which can be used to manage the notification later.
                                            // If you don't provide one, a unique string will be generated automatically.
                                            Title = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.title)),
                                            Body = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.Body)),
                                            Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.subtitle)),
                                            ShowInForeground = true,
                                            ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                                            CategoryIdentifier = "category_a",
                                            ThreadIdentifier = "thread1",
                                            Trigger = timeTrigger,
                                        };
                                        Debug.Log(timeTrigger.TimeInterval);
                                        Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));

                                        if (timeTrigger.TimeInterval.Minutes > 0)
                                        {
                                            notificationCount += 1;
                                            iOSNotificationCenter.ScheduleNotification(notificationIOS);
                                        }
                                        else
                                        {
                                            Debug.Log("Notification kurulamadı. Time interval 0dan kucuk");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                //DogumYili
                if (notificationCount < 15)
                {
                    if (mobileNotification.tip == NotificationMessage.NotificationType.belirliTarih)
                    {
                        if (mobileNotification.platform == NotificationMessage.NotificationPlatform.IOS
                    || mobileNotification.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            int day;
                            int month;
                            int year;

                            int.TryParse(playerData.GetChatVariableValue("dogum gunu"), out day);
                            int.TryParse(playerData.GetChatVariableValue("dogum ayi"), out month);
                            int.TryParse(playerData.GetChatVariableValue("dogum yili"), out year);

                            DateTime fireTime;
                            if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.aksam)
                            {
                                try
                                {
                                    fireTime = new DateTime(DateTime.Now.Year, month, day, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                                }
                                catch
                                {
                                    fireTime = new DateTime(System.DateTime.Now.Year, 12, 30, UnityEngine.Random.Range(notificationSettings.aksam.startTime, notificationSettings.aksam.endTime), 0, 0);
                                }
                            }
                            else if (mobileNotification.gonderilecegiZaman == NotificationMessage.NotificationPushTime.ogle)
                            {
                                try
                                {
                                    fireTime = new DateTime(DateTime.Now.Year, month, day, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                                }
                                catch
                                {
                                    fireTime = new DateTime(System.DateTime.Now.Year, 12, 30, UnityEngine.Random.Range(notificationSettings.ogle.startTime, notificationSettings.ogle.endTime), 0, 0);
                                }
                            }
                            else
                            {
                                try
                                {
                                    fireTime = new DateTime(DateTime.Now.Year, month, day, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                                }
                                catch
                                {
                                    fireTime = new DateTime(System.DateTime.Now.Year, 12, 30, UnityEngine.Random.Range(notificationSettings.sabah.startTime, notificationSettings.sabah.endTime), 0, 0);
                                }
                            }

                            if ((fireTime - DateTime.Now).TotalHours > 0)
                            {

                                var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                                {
                                    TimeInterval = new TimeSpan((int)(fireTime - DateTime.Now).TotalHours, 0, 0),
                                    Repeats = false
                                };

                                double dayDifference = (fireTime - System.DateTime.Now).TotalDays;
                                if (dayDifference <= 7 && dayDifference > 0)
                                {
                                    DateTime realDate = new DateTime(year, month, day, 0, 0, 0);

                                    if (!notificationRealDates.Contains(realDate))
                                    {
                                        notificationRealDates.Add(realDate);
                                        var notificationIOS = new iOSNotification()
                                        {
                                            // You can specify a custom identifier which can be used to manage the notification later.
                                            // If you don't provide one, a unique string will be generated automatically.
                                            Title = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.title)),
                                            Body = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.Body)),
                                            Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(mobileNotification.subtitle)),
                                            ShowInForeground = true,
                                            ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                                            CategoryIdentifier = "category_a",
                                            ThreadIdentifier = "thread1",
                                            Trigger = timeTrigger,
                                        };
                                        Debug.Log(timeTrigger.TimeInterval);
                                        Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));

                                        if (timeTrigger.TimeInterval.Minutes > 0)
                                        {
                                            notificationCount += 1;
                                            iOSNotificationCenter.ScheduleNotification(notificationIOS);
                                        }
                                        else
                                        {
                                            Debug.Log("Notification kurulamadı. Time interval 0dan kucuk");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
#endif
            }
        }

        notificationRealDates = new List<DateTime>();
    }

    void SenTimerNotifications()
    {
        if (playerData.GetChatVariableValue("enerji bildirimleri") != "kapalı")
        {
            if (notificationMessagesKons.Count > 0)
            {
                int maxKons = TimerItemManager.GetMaxTimerKonsantrasyon();

                if (maxKons - playerData.datas.konsantrasyon > 0)
                {
                    PlayerData.Date lastKonsantrasyonGivenTimeString = playerData.datas.lastFreekonsantrasyon;
                    DateTime lastKonsantrasyonGivenTime = Magnus.Time.DateTimeOperations.ToDateTime(lastKonsantrasyonGivenTimeString);

                    notificationMessagesKons.Shuffle();
                    foreach (NotificationMessage notificationMessage in notificationMessagesKons)
                    {
                        bool isCompatible = true;
                        foreach (Sohbet.GerekenDegisken degisken in notificationMessage.gerekliDegiskenler)
                        {
                            if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                            {
                                if (degisken.degiskenDegeri != playerData.GetChatVariableValue(degisken.degiskenAdi))
                                {
                                    Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                    isCompatible = false;
                                    break;
                                }
                            }
                            else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                            {
                                if (degisken.degiskenDegeri == playerData.GetChatVariableValue(degisken.degiskenAdi))
                                {
                                    Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                    isCompatible = false;
                                    break;
                                }
                            }
                            else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                            {
                                int currentValue;
                                int savedValue;

                                int.TryParse(degisken.degiskenDegeri, out currentValue);
                                int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                                if (!(savedValue > currentValue))
                                {
                                    Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                    isCompatible = false;
                                    break;
                                }
                            }
                            else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                            {
                                int currentValue;
                                int savedValue;

                                int.TryParse(degisken.degiskenDegeri, out currentValue);
                                int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                                if (!(savedValue >= currentValue))
                                {
                                    Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                    isCompatible = false;
                                    break;
                                }
                            }
                            else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                            {
                                int currentValue;
                                int savedValue;

                                int.TryParse(degisken.degiskenDegeri, out currentValue);
                                int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                                if (!(savedValue < currentValue))
                                {
                                    Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                    isCompatible = false;
                                    break;
                                }
                            }
                            else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                            {
                                int currentValue;
                                int savedValue;

                                int.TryParse(degisken.degiskenDegeri, out currentValue);
                                int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                                if (!(savedValue <= currentValue))
                                {
                                    Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                    isCompatible = false;
                                    break;
                                }
                            }
                        }

                        if (isCompatible)
                        {
                            konsantrasyonBildirim = notificationMessage;
                            break;
                        }
                    }

                    if (konsantrasyonBildirim == null)
                        return;

                    konsantrasyonBildirim.saat = (float)(System.DateTime.Now.AddSeconds((maxKons - playerData.datas.konsantrasyon) * TimerItemManager.GetMaxTimerKonsantrasyonDuration() * 60f) - DateTime.Now).TotalHours;

                    if (konsantrasyonBildirim.saat <= 0)
                    {
                        konsantrasyonBildirim.saat = 0.15f;
                    }

                    konsantrasyonBildirim.platform = NotificationMessage.NotificationPlatform.farkEtmez;
                    konsantrasyonBildirim.tip = NotificationMessage.NotificationType.sayac;

                    Debug.Log(konsantrasyonBildirim.Body);
                    Debug.Log(lastKonsantrasyonGivenTime.AddSeconds((maxKons - playerData.datas.konsantrasyon) * TimerItemManager.GetMaxTimerKonsantrasyonDuration() * 60f));
                    Debug.Log($"Konsantrasyon bildirimi {konsantrasyonBildirim.saat} saat sonra gösterilecek!");

#if UNITY_ANDROID
                    //Android
                    if (konsantrasyonBildirim.tip == NotificationMessage.NotificationType.sayac)
                    {
                        if (konsantrasyonBildirim.platform == NotificationMessage.NotificationPlatform.android
                            || konsantrasyonBildirim.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            var notificationAndoid = new AndroidNotification();
                            notificationAndoid.Title = chatVariables.OrtakButonlar(konsantrasyonBildirim.title);
                            notificationAndoid.Text = chatVariables.OrtakButonlar(konsantrasyonBildirim.Body);

                            notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                            notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                            notificationAndoid.FireTime = System.DateTime.Now.AddHours(konsantrasyonBildirim.saat);

                            notificationAndoid.SmallIcon = "logo_small";
                            notificationAndoid.LargeIcon = "logo_large";
                            notificationAndoid.Style = NotificationStyle.BigTextStyle;

                            if (notificationAndoid.FireTime.Hour > 8 && notificationAndoid.FireTime.Hour < 22)
                            {
                                Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                            }
                            else
                            {
                                if (notificationAndoid.FireTime.Hour < 24 && notificationAndoid.FireTime.Hour > 22)
                                    notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month, notificationAndoid.FireTime.Day + 1, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);
                                else
                                    notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month, notificationAndoid.FireTime.Day, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);

                                Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                                AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                            }
                        }
                    }
#elif UNITY_IOS
                    //Konsantrasyon
                    if (konsantrasyonBildirim.tip == NotificationMessage.NotificationType.sayac)
                    {
                        if (konsantrasyonBildirim.platform == NotificationMessage.NotificationPlatform.IOS
                    || konsantrasyonBildirim.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                        {
                            DateTime fireTime = DateTime.Now.AddHours(konsantrasyonBildirim.saat);

                            if (!(fireTime.Hour > 8 && fireTime.Hour < 22))
                            {
                                if (fireTime.Hour < 24 && fireTime.Hour > 22)
                                    fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day + 1, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
                                else
                                    fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
                            }

                            var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                            {
                                TimeInterval = (fireTime - DateTime.Now),
                                Repeats = false
                            };

                            var notificationIOS = new iOSNotification()
                            {
                                // You can specify a custom identifier which can be used to manage the notification later.
                                // If you don't provide one, a unique string will be generated automatically.
                                Title = ChangeEmoji(chatVariables.OrtakButonlar(konsantrasyonBildirim.title)),
                                Body = ChangeEmoji(chatVariables.OrtakButonlar(konsantrasyonBildirim.Body)),
                                Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(konsantrasyonBildirim.subtitle)),
                                ShowInForeground = true,
                                ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                                CategoryIdentifier = "category_a",
                                ThreadIdentifier = "thread1",
                                Trigger = timeTrigger,
                            };

                            Debug.Log(timeTrigger.TimeInterval);
                            Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));
                            Debug.Log(timeTrigger.TimeInterval.Minutes);

                            if (timeTrigger.TimeInterval.Minutes > 0)
                            {
                                iOSNotificationCenter.ScheduleNotification(notificationIOS);
                            }
                            else
                            {
                                Debug.Log("Notification kurulamadı. Time interval 0dan kucuk");
                            }
                        }
                    }
#endif
                }
            }
        }
    }

    void SendDailyEnergyNotification()
    {
        if (playerData.GetChatVariableValue("enerji bildirimleri") != "kapalı")
        {
            if (notificationMessagesEnergy.Count > 0)
            {
                PlayerData.Date lastKonsantrasyonGivenTimeString = playerData.datas.lastFreekonsantrasyon;
                DateTime lastKonsantrasyonGivenTime = Magnus.Time.DateTimeOperations.ToDateTime(lastKonsantrasyonGivenTimeString);

                notificationMessagesEnergy.Shuffle();
                foreach (NotificationMessage notificationMessage in notificationMessagesEnergy)
                {
                    bool isCompatible = true;
                    foreach (Sohbet.GerekenDegisken degisken in notificationMessage.gerekliDegiskenler)
                    {
                        if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                        {
                            if (degisken.degiskenDegeri != playerData.GetChatVariableValue(degisken.degiskenAdi))
                            {
                                Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                isCompatible = false;
                                break;
                            }
                        }
                        else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                        {
                            if (degisken.degiskenDegeri == playerData.GetChatVariableValue(degisken.degiskenAdi))
                            {
                                Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                isCompatible = false;
                                break;
                            }
                        }
                        else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                        {
                            int currentValue;
                            int savedValue;

                            int.TryParse(degisken.degiskenDegeri, out currentValue);
                            int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                            if (!(savedValue > currentValue))
                            {
                                Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                isCompatible = false;
                                break;
                            }
                        }
                        else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                        {
                            int currentValue;
                            int savedValue;

                            int.TryParse(degisken.degiskenDegeri, out currentValue);
                            int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                            if (!(savedValue >= currentValue))
                            {
                                Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                isCompatible = false;
                                break;
                            }
                        }
                        else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                        {
                            int currentValue;
                            int savedValue;

                            int.TryParse(degisken.degiskenDegeri, out currentValue);
                            int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                            if (!(savedValue < currentValue))
                            {
                                Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                isCompatible = false;
                                break;
                            }
                        }
                        else if (degisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                        {
                            int currentValue;
                            int savedValue;

                            int.TryParse(degisken.degiskenDegeri, out currentValue);
                            int.TryParse(playerData.GetChatVariableValue(degisken.degiskenAdi), out savedValue);

                            if (!(savedValue <= currentValue))
                            {
                                Debug.Log("Değişkenler uymadığı için yoksayıldı Değişken adı: " + degisken.degiskenAdi + " Değişken değeri: " + degisken.degiskenDegeri);
                                isCompatible = false;
                                break;
                            }
                        }
                    }

                    if (isCompatible)
                    {
                        enerjiBildirimi = notificationMessage;
                        break;
                    }
                }

                if (enerjiBildirimi == null)
                    return;

                enerjiBildirimi.saat = (float)(new DateTime(DateTime.Now.AddDays(1).Year, DateTime.Now.AddDays(1).Month, DateTime.Now.AddDays(1).Day, UnityEngine.Random.Range(9, 13), UnityEngine.Random.Range(1, 50), 0) - DateTime.Now).TotalHours;
                enerjiBildirimi.platform = NotificationMessage.NotificationPlatform.farkEtmez;
                enerjiBildirimi.tip = NotificationMessage.NotificationType.sayac;

                Debug.Log($"Enerji bildirimi {enerjiBildirimi.saat} saat sonra gösterilecek!");

#if UNITY_ANDROID
                //Android
                if (enerjiBildirimi.tip == NotificationMessage.NotificationType.sayac)
                {
                    if (enerjiBildirimi.platform == NotificationMessage.NotificationPlatform.android
                        || enerjiBildirimi.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                    {
                        var notificationAndoid = new AndroidNotification();
                        notificationAndoid.Title = chatVariables.OrtakButonlar(enerjiBildirimi.title);
                        notificationAndoid.Text = chatVariables.OrtakButonlar(enerjiBildirimi.Body);

                        notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
                        notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

                        notificationAndoid.FireTime = System.DateTime.Now.AddHours(enerjiBildirimi.saat);

                        notificationAndoid.SmallIcon = "logo_small";
                        notificationAndoid.LargeIcon = "logo_large";
                        notificationAndoid.Style = NotificationStyle.BigTextStyle;

                        if (notificationAndoid.FireTime.Hour > 8 && notificationAndoid.FireTime.Hour < 22)
                        {
                            Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                            AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                        }
                        else
                        {
                            if (notificationAndoid.FireTime.Hour < 24 && notificationAndoid.FireTime.Hour > 22)
                                notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month, notificationAndoid.FireTime.Day + 1, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);
                            else
                                notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month, notificationAndoid.FireTime.Day, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);

                            Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
                            AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
                        }
                    }
                }
#elif UNITY_IOS
                //Enerji
                if (enerjiBildirimi.tip == NotificationMessage.NotificationType.sayac)
                {
                    if (enerjiBildirimi.platform == NotificationMessage.NotificationPlatform.IOS
                || enerjiBildirimi.platform == NotificationMessage.NotificationPlatform.farkEtmez)
                    {
                        DateTime fireTime = DateTime.Now.AddHours(enerjiBildirimi.saat);

                        if (!(fireTime.Hour > 8 && fireTime.Hour < 22))
                        {
                            if (fireTime.Hour < 24 && fireTime.Hour > 22)
                                fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day + 1, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
                            else
                                fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
                        }

                        var timeTrigger = new iOSNotificationTimeIntervalTrigger()
                        {
                            TimeInterval = (DateTime.Now.AddHours(enerjiBildirimi.saat) - DateTime.Now),
                            Repeats = false
                        };

                        var notificationIOS = new iOSNotification()
                        {
                            // You can specify a custom identifier which can be used to manage the notification later.
                            // If you don't provide one, a unique string will be generated automatically.
                            Title = ChangeEmoji(chatVariables.OrtakButonlar(enerjiBildirimi.title)),
                            Body = ChangeEmoji(chatVariables.OrtakButonlar(enerjiBildirimi.Body)),
                            Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(enerjiBildirimi.subtitle)),
                            ShowInForeground = true,
                            ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
                            CategoryIdentifier = "category_a",
                            ThreadIdentifier = "thread1",
                            Trigger = timeTrigger,
                        };

                        Debug.Log(timeTrigger.TimeInterval);
                        Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));
                        if (timeTrigger.TimeInterval.Minutes > 0)
                        {
                            iOSNotificationCenter.ScheduleNotification(notificationIOS);
                        }
                        else
                        {
                            Debug.Log("Notification kurulamadı. Time interval 0dan kucuk");
                        }
                    }
                }
#endif
            }
        }
    }

    /// <summary>
    /// Bu fonksiyon falin hazir bildirimlerini kurar.
    /// </summary>
    void SendFalHazirNotification()
    {
        try //Eger app initiliaze edilmeden kapatilirsa bildirim kurulmaya calisilir.
        {   //Bu durumda hata olmasin diye try catch yapilir.
            var dene = playerData.localPlayerDatas.renderedTexts[0];
        }
        catch
        {
            return;
        }
        var son5Metin = playerData.localPlayerDatas.renderedTexts.Find(x => x.name.Equals("son5Metin"));
        RenderedText.Text minDelayText = null;
        int seconds = 0;
        if (son5Metin != null)
        {
            foreach (RenderedText.Text text in son5Metin.renderedTexts)
            {
                if (text.uIInformation.showTimeStamp > 0 &&
                    text.uIInformation.showTimeStamp > Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now))
                {
                    if (minDelayText != null)
                    {
                        if (minDelayText.uIInformation.showTimeStamp > text.uIInformation.showTimeStamp)
                            minDelayText = text;
                    }
                    else
                    {
                        minDelayText = text;
                    }
                }
            }

            if (minDelayText != null)
            {
                seconds = (int)(minDelayText.uIInformation.showTimeStamp - Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now));

                if (seconds <= 0)
                {
                    return;
                }
            }
            else
            {
                return;
            }
        }
        else
        {
            return;
        }

        string falBaslik = minDelayText.uIInformation.title + " hazır!";
        string falBody = minDelayText.uIInformation.title + " analizini tamamladım {{isim}}";

#if UNITY_ANDROID
        //Android
        var notificationAndoid = new AndroidNotification();
        notificationAndoid.Title = chatVariables.OrtakButonlar(falBaslik);
        notificationAndoid.Text = chatVariables.OrtakButonlar(falBody);

        notificationAndoid.Title = ChangeEmoji(notificationAndoid.Title);
        notificationAndoid.Text = ChangeEmoji(notificationAndoid.Text);

        notificationAndoid.FireTime = System.DateTime.Now.AddSeconds(seconds);

        notificationAndoid.SmallIcon = "logo_small";
        notificationAndoid.LargeIcon = "logo_large";
        notificationAndoid.Style = NotificationStyle.BigTextStyle;

        if (notificationAndoid.FireTime.Hour > 8 && notificationAndoid.FireTime.Hour < 22)
        {
            Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
            AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
        }
        else
        {
            if (notificationAndoid.FireTime.Hour < 24 && notificationAndoid.FireTime.Hour > 22)
                notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month,
                    notificationAndoid.FireTime.Day + 1, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);
            else
                notificationAndoid.FireTime = new DateTime(notificationAndoid.FireTime.Year, notificationAndoid.FireTime.Month,
                    notificationAndoid.FireTime.Day, UnityEngine.Random.Range(9, 12), notificationAndoid.FireTime.Minute, notificationAndoid.FireTime.Second);

            Debug.Log("Bir bildirim: " + notificationAndoid.FireTime + "tarihi icin ayarlandi\n\n" + notificationAndoid.Text);
            AndroidNotificationCenter.SendNotification(notificationAndoid, "magnusNots");
        }
#elif UNITY_IOS
        DateTime fireTime = DateTime.Now.AddSeconds(seconds);

        if (!(fireTime.Hour > 8 && fireTime.Hour < 22))
        {
            if (fireTime.Hour < 24 && fireTime.Hour > 22)
                fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day + 1, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
            else
                fireTime = new DateTime(fireTime.Year, fireTime.Month, fireTime.Day, UnityEngine.Random.Range(9, 12), fireTime.Minute, fireTime.Second);
        }

        var timeTrigger = new iOSNotificationTimeIntervalTrigger()
        {
            TimeInterval = (DateTime.Now.AddSeconds(seconds) - DateTime.Now),
            Repeats = false
        };

        var notificationIOS = new iOSNotification()
        {
            // You can specify a custom identifier which can be used to manage the notification later.
            // If you don't provide one, a unique string will be generated automatically.
            Title = ChangeEmoji(chatVariables.OrtakButonlar(falBaslik)),
            Body = ChangeEmoji(chatVariables.OrtakButonlar(falBody)),
            Subtitle = ChangeEmoji(chatVariables.OrtakButonlar(String.Empty)),
            ShowInForeground = true,
            ForegroundPresentationOption = (PresentationOption.Alert | PresentationOption.Badge | PresentationOption.Sound),
            CategoryIdentifier = "category_a",
            ThreadIdentifier = "thread1",
            Trigger = timeTrigger,
        };

        Debug.Log(timeTrigger.TimeInterval);
        Debug.Log(DateTime.Now.Add(timeTrigger.TimeInterval));
        if (timeTrigger.TimeInterval.Minutes > 0)
        {
            iOSNotificationCenter.ScheduleNotification(notificationIOS);
        }
        else
        {
            Debug.Log("Notification kurulamadı. Time interval 0dan kucuk");
        }
#endif
    }

#if UNITY_IOS
    IEnumerator RequestIOSNotificationAuthorization()     {
        var authorizationOption = AuthorizationOption.Alert | AuthorizationOption.Badge | AuthorizationOption.Sound;         using (var req = new AuthorizationRequest(authorizationOption, true))         {             while (!req.IsFinished)             {                 yield return null;             };              string res = "\n RequestAuthorization:";             res += "\n finished: " + req.IsFinished;             res += "\n granted :  " + req.Granted;             res += "\n error:  " + req.Error;             res += "\n deviceToken:  " + req.DeviceToken;             Debug.Log(res);

            DeleteAllNotifications();
            SendNotification();         }     } 
#endif 
    public string ChangeEmoji(string text)
    {
        for (int i = 0; i < 85 + 1; i++)
        {
            text = text.Replace($"<sprite={i}>", $"{GetEmoji(i)}");
        }
        return text;
    }      public string GetEmoji(int index)
    {
        switch (index)
        {
            case 0:
                return "🙂";
            case 1:
                return "😆";
            case 2:
                return "😇";
            case 3:
                return "😃";
            case 4:
                return "😬";
            case 5:
                return "😄";
            case 6:
                return "😅";
            case 7:
                return "😉";
            case 8:
                return "😃";
            case 9:
                return "😁";
            case 10:
                return "😊";
            case 11:
                return "😂";
            case 12:
                return "😌";
            case 13:
                return "😍";
            case 14:
                return "😗";
            case 15:
                return "😙";
            case 16:
                return "😚";
            case 17:
                return "🤓";
            case 18:
                return "😜";
            case 19:
                return "😘";
            case 20:
                return "😝";
            case 21:
                return "😛";
            case 22:
                return "🤑";
            case 23:
                return "😎";
            case 24:
                return "😟";
            case 25:
                return "😠";
            case 26:
                return "😔";
            case 27:
                return "😐";
            case 28:
                return "🙄";
            case 29:
                return "😲";
            case 30:
                return "😔";
            case 31:
                return "😡";
            case 32:
                return "😕";
            case 33:
                return "😒";
            case 34:
                return "🤔";
            case 35:
                return "😑";
            case 36:
                return "😧";
            case 37:
                return "😨";
            case 38:
                return "😯";
            case 39:
                return "😦";
            case 40:
                return "😖";
            case 41:
                return "😫";
            case 42:
                return "😮";
            case 43:
                return "😰";
            case 44:
                return "😥";
            case 45:
                return "😩";
            case 46:
                return "😤";
            case 47:
                return "😱";
            case 48:
                return "😵";
            case 49:
                return "😵";
            case 50:
                return "🤕";
            case 51:
                return "😴";
            case 52:
                return "💤";
            case 53:
                return "🤐";
            case 54:
                return "🤒";
            case 55:
                return "👿";
            case 56:
                return "😭";
            case 57:
                return "💩";
            case 58:
                return "😈";
            case 59:
                return "😷";
            case 60:
                return "👻";
            case 61:
                return "🤖";
            case 62:
                return "😺";
            case 63:
                return "😽";
            case 64:
                return "👽";
            case 65:
                return "😸";
            case 66:
                return "😻";
            case 67:
                return "😼";
            case 68:
                return "😿";
            case 69:
                return "🙀";
            case 70:
                return "😹";
            case 71:
                return "😼";
            case 72:
                return "✋";
            case 73:
                return "👊";
            case 74:
                return "💪";
            case 75:
                return "👍";
            case 76:
                return "✊";
            case 77:
                return "✌";
            case 78:
                return "👌";
            case 79:
                return "🙏";
            case 80:
                return "☝️";
            case 81:
                return "☝️";
            case 82:
                return "👇";
            case 83:
                return "👈";
            case 84:
                return "😋";
            case 85:
                return "🧐";
            default:
                return "🙂";
        }
    } } 