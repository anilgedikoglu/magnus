using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Newtonsoft.Json;
using System.IO;
using System.Text;
using Firebase.Database;
using Firebase.Extensions;
using System.Linq;
using System;

public class InAppReviewEditor : EditorWindow
{
    public AuthenticationManager authenticationManager;
    public RealtimeDatabaseManager realtimeDatabaseManager;
    List<Inceleme> sohbetIncelemeleri;

    List<Inceleme> avaliableSohbetIncelemeleri;
    private InAppReview.SohbetInceleme secilenSohbet;
    private string state;

    private string filtre;
    private Sohbet[] mevcutSohbetler;

    private CurrentPlayerData.AdminAnswer adminYaniti;
    private bool adminYanitlayabilir;

    private const int maxElementCount = 10;
    private int currentPage;

    private Texture2D starSprite;

    Vector2 scroll;

    private AdminMessageHistory.Data currentData;
    private AdminMessageHistory.Data[] adminDatas;

    private bool showRewiewsWithComment = false;

    [MenuItem("Magnus/Istatistikler/Sohbet Incelemeleri")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(InAppReviewEditor));
    }

    public void OnEnable()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();

        sohbetIncelemeleri = null;
        avaliableSohbetIncelemeleri = null;
        state = "reviewPage";
        filtre = string.Empty;
        mevcutSohbetler = null;

        adminYaniti = new CurrentPlayerData.AdminAnswer();

        adminDatas = new AdminMessageHistory.Data[0];

        starSprite = Resources.Load<Texture2D>("General/Icon_Star2");
    }

    void OnGUI()
    {
        EditorStyles.textArea.wordWrap = true;

        scroll = EditorGUILayout.BeginScrollView(scroll);
        if (!EditorApplication.isPlaying)
        {
            EditorGUILayout.HelpBox("Bu paneli kullanabilmek için uygulamayı başlatmalı ve giriş yapmalısınız!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();
            }
        }
        else
        {
            if (state == "reviewPage" || state == "reviewPageSohbeteOzel")
            {
                EditorGUILayout.BeginHorizontal();
                if (GUILayout.Button("Bugün"))
                {
                    DownloadReviewList(1);
                }
                if (GUILayout.Button("Son 3 gün"))
                {
                    DownloadReviewList(3);
                }
                if (GUILayout.Button("Son 1 hafta"))
                {
                    DownloadReviewList(7);
                }
                if (GUILayout.Button("Son 1 ay"))
                {
                    DownloadReviewList(30);
                }
                EditorGUILayout.EndHorizontal();

                if (avaliableSohbetIncelemeleri != null)
                {
                    DrawReviewPage();
                }
            }
            else if (state == "inspect" || state == "inspectSohbeteOzel")
            {
                DrawInspectPage(secilenSohbet);
            }
            else if (state == "drawMessage")
            {
                DrawMessage();
            }
        }
        EditorGUILayout.EndScrollView();
    }

    private void DrawReviewPage()
    {
        var h1 = new GUIStyle("label");
        h1.fontSize = 50;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        var h2 = new GUIStyle("label");
        h2.fontSize = 15;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        var smallBold = new GUIStyle("label");
        smallBold.fontSize = 10;
        smallBold.fontStyle = FontStyle.Bold;
        //smallBold.alignment = TextAnchor.UpperCenter;

        float totalStar = 0;
        int reviewWith1Star = 0;
        int reviewWith2Star = 0;
        int reviewWith3Star = 0;
        int reviewWith4Star = 0;
        int reviewWith5Star = 0;
        foreach (Inceleme sohbetInceleme in avaliableSohbetIncelemeleri)
        {
            totalStar += sohbetInceleme.inceleme.yildiz;

            switch (sohbetInceleme.inceleme.yildiz)
            {
                case 1:
                    reviewWith1Star++;
                    break;
                case 2:
                    reviewWith2Star++;
                    break;
                case 3:
                    reviewWith3Star++;
                    break;
                case 4:
                    reviewWith4Star++;
                    break;
                case 5:
                    reviewWith5Star++;
                    break;
            }
        }

        EditorGUILayout.BeginHorizontal();
        if (!string.IsNullOrEmpty(filtre))
        {
            EditorGUILayout.LabelField("Filtre: ", GUILayout.Width(45));
            EditorGUILayout.LabelField(filtre, h2);
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField(Math.Round((totalStar / avaliableSohbetIncelemeleri.Count), 1).ToString(), h1);

        EditorGUILayout.Space(5);

        EditorGUILayout.BeginVertical();

        EditorGUILayout.Space(5);
        //Başında sayı olan line
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("5", smallBold, GUILayout.Height(15));
        EditorGUILayout.BeginVertical();
        EditorGUILayout.Space(5, false);
        EditorGUILayout.BeginHorizontal();
        float ratio = (float)reviewWith5Star / avaliableSohbetIncelemeleri.Count;
        float offset = DrawLine(2, ratio * 2f, Color.white);
        DrawLineWithOffset(2, offset, 2f - ratio * 2f);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();
        //Line sonu

        //Başında sayı olan line
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("4", smallBold, GUILayout.Height(15));
        EditorGUILayout.BeginVertical();
        EditorGUILayout.Space(5, false);
        EditorGUILayout.BeginHorizontal();
        ratio = (float)reviewWith4Star / avaliableSohbetIncelemeleri.Count;
        offset = DrawLine(2, ratio * 2f, Color.white);
        DrawLineWithOffset(2, offset, 2f - ratio * 2f);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();
        //Line sonu

        //Başında sayı olan line
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("3", smallBold, GUILayout.Height(15));
        EditorGUILayout.BeginVertical();
        EditorGUILayout.Space(5, false);
        EditorGUILayout.BeginHorizontal();
        ratio = (float)reviewWith3Star / avaliableSohbetIncelemeleri.Count;
        offset = DrawLine(2, ratio * 2f, Color.white);
        DrawLineWithOffset(2, offset, 2f - ratio * 2f);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();
        //Line sonu

        //Başında sayı olan line
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("2", smallBold, GUILayout.Height(15));
        EditorGUILayout.BeginVertical();
        EditorGUILayout.Space(5, false);
        EditorGUILayout.BeginHorizontal();
        ratio = (float)reviewWith2Star / avaliableSohbetIncelemeleri.Count;
        offset = DrawLine(2, ratio * 2f, Color.white);
        DrawLineWithOffset(2, offset, 2f - ratio * 2f);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();
        //Line sonu

        //Başında sayı olan line
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("1", smallBold, GUILayout.Height(15));
        EditorGUILayout.BeginVertical();
        EditorGUILayout.Space(5, false);
        EditorGUILayout.BeginHorizontal();
        ratio = (float)reviewWith1Star / avaliableSohbetIncelemeleri.Count;
        offset = DrawLine(2, ratio * 2f, Color.white);
        DrawLineWithOffset(2, offset, 2f - ratio * 2f);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();
        //Line sonu

        EditorGUILayout.EndVertical();

        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("Tümü"))
        {
            avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(sohbetIncelemeleri);
        }
        if (GUILayout.Button("1 Yıldız"))
        {
            avaliableSohbetIncelemeleri = new();
            foreach (Inceleme sohbetInceleme in sohbetIncelemeleri)
            {
                if(sohbetInceleme.inceleme.yildiz == 1)
                {
                    avaliableSohbetIncelemeleri.Add(sohbetInceleme);
                }
            }
            avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(avaliableSohbetIncelemeleri);
        }
        if (GUILayout.Button("2 Yıldız"))
        {
            avaliableSohbetIncelemeleri = new();
            foreach (Inceleme sohbetInceleme in sohbetIncelemeleri)
            {
                if (sohbetInceleme.inceleme.yildiz == 2)
                {
                    avaliableSohbetIncelemeleri.Add(sohbetInceleme);
                }
            }
            avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(avaliableSohbetIncelemeleri);
        }
        if (GUILayout.Button("3 Yıldız"))
        {
            avaliableSohbetIncelemeleri = new();
            foreach (Inceleme sohbetInceleme in sohbetIncelemeleri)
            {
                if (sohbetInceleme.inceleme.yildiz == 3)
                {
                    avaliableSohbetIncelemeleri.Add(sohbetInceleme);
                }
            }
            avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(avaliableSohbetIncelemeleri);
        }
        if (GUILayout.Button("4 Yıldız"))
        {
            avaliableSohbetIncelemeleri = new();
            foreach (Inceleme sohbetInceleme in sohbetIncelemeleri)
            {
                if (sohbetInceleme.inceleme.yildiz == 4)
                {
                    avaliableSohbetIncelemeleri.Add(sohbetInceleme);
                }
            }
            avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(avaliableSohbetIncelemeleri);
        }
        if (GUILayout.Button("5 Yıldız"))
        {
            avaliableSohbetIncelemeleri = new();
            foreach (Inceleme sohbetInceleme in sohbetIncelemeleri)
            {
                if (sohbetInceleme.inceleme.yildiz == 5)
                {
                    avaliableSohbetIncelemeleri.Add(sohbetInceleme);
                }
            }
            avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(avaliableSohbetIncelemeleri);
        }
        EditorGUILayout.EndHorizontal();

        showRewiewsWithComment = EditorGUILayout.Toggle("Sadece yorum içerenler", showRewiewsWithComment);

        EditorGUILayout.Space(20);
        for (int i = currentPage * maxElementCount; i < Math.Clamp(currentPage * maxElementCount + maxElementCount, 0, avaliableSohbetIncelemeleri.Count); i++)
        {
            if (!string.IsNullOrEmpty(avaliableSohbetIncelemeleri[i].inceleme.inceleme) || !showRewiewsWithComment)
                DrawReview(avaliableSohbetIncelemeleri[i]);
        }

        if (avaliableSohbetIncelemeleri.Count > maxElementCount)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(0, true);
            if (GUILayout.Button("Önceki"))
            {
                currentPage--;
            }
            EditorGUILayout.LabelField($"{currentPage + 1}/{GetMaxPageCount() + 1}", GUILayout.Width(45));
            if (GUILayout.Button("Sonraki"))
            {
                currentPage++;
                Mathf.Clamp(currentPage, 0, GetMaxPageCount());
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(20);
        }
    }

    private void DrawReview(Inceleme inceleme)
    {
        var h1 = new GUIStyle("label");
        h1.fontSize = 16;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        var h2 = new GUIStyle("label");
        h2.fontSize = 14;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        var h3 = new GUIStyle("label");
        h3.fontSize = 12;
        h3.fontStyle = FontStyle.Bold;
        h3.wordWrap = true;

        var h4 = new GUIStyle("label");
        h4.fontSize = 10;
        h4.fontStyle = FontStyle.Normal;
        h4.wordWrap = true;

        var reviewFont = new GUIStyle("label");
        reviewFont.fontSize = 12;
        reviewFont.fontStyle = FontStyle.Italic;
        reviewFont.wordWrap = true;

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField(Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(inceleme.inceleme.unixTimeStamp).ToString());

        if (state != "reviewPageSohbeteOzel")
        {
            if (GUILayout.Button("Sil", GUILayout.Width(40)))
            {
                FirebaseDatabase.DefaultInstance
                  .GetReference("SohbetIncelemeleri/TariheGore/" + $"{inceleme.onlineKey}/" + inceleme.inceleme.incelemeID).SetValueAsync(null);

                sohbetIncelemeleri.Remove(inceleme);
                avaliableSohbetIncelemeleri.Remove(inceleme);
            }
        }
        for (int i = 0; i < inceleme.inceleme.yildiz; i++)
        GUILayout.Label(starSprite, GUILayout.Width(32), GUILayout.Height(32));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.LabelField(inceleme.inceleme.userName, h1);
        EditorGUILayout.LabelField(GetPartOfString(inceleme.inceleme.inceleme, 200), h2);
        GUILayout.Space(5);
        EditorGUILayout.LabelField(GetPartOfString(inceleme.inceleme.sohbetMetni, 200), reviewFont);


        if (GUILayout.Button("İncele"))
        {
            mevcutSohbetler = null;
            secilenSohbet = inceleme.inceleme;
            if (state != "reviewPageSohbeteOzel")
                state = "inspect";
            else
                state = "inspectSohbeteOzel";

            adminYanitlayabilir = true;
            adminYaniti.answer = string.Empty;

            FirebaseDatabase.DefaultInstance.GetReference("AdminMessageHistory").Child(inceleme.inceleme.userID).
    GetValueAsync().ContinueWithOnMainThread(task =>
    {
        if (task.IsFaulted || task.IsCanceled)
        {
            Debug.LogError(task.Exception.ToString());
            return;
        }

        DataSnapshot[] childs = task.Result.Children.ToArray();
        adminDatas = new AdminMessageHistory.Data[childs.Length];

        for (int i = 0; i < childs.Length; i++)
        {
            adminDatas[i] = JsonConvert.DeserializeObject
                    <AdminMessageHistory.Data>(childs[i].GetRawJsonValue());


        }

        adminDatas = adminDatas.OrderByDescending(item => item.timeStamp).ToArray();

        Repaint();
    });
        }
        /*
        EditorGUILayout.LabelField(sohbetInceleme.userID);
        EditorGUILayout.LabelField(sohbetInceleme.sohbetID);
        EditorGUILayout.LabelField(sohbetInceleme.sohbetMetni);
        */

        GUILayout.Space(10);
        DrawLine(1);
    }

    private void DrawInspectPage(InAppReview.SohbetInceleme sohbetInceleme)
    {
        var h1 = new GUIStyle("label");
        h1.fontSize = 16;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        var h2 = new GUIStyle("label");
        h2.fontSize = 14;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        var h3 = new GUIStyle("label");
        h3.fontSize = 12;
        h3.fontStyle = FontStyle.Bold;
        h3.wordWrap = true;

        var h4 = new GUIStyle("label");
        h4.fontSize = 10;
        h4.fontStyle = FontStyle.Normal;
        h4.wordWrap = true;

        var userFont = new GUIStyle("label");
        userFont.fontSize = 12;
        userFont.fontStyle = FontStyle.Italic;
        userFont.wordWrap = true;

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("x", GUILayout.Width(20)))
        {
 
            if (state != "inspectSohbeteOzel")
            {
                state = "reviewPage";
            }
            else
            {
                state = "reviewPageSohbeteOzel";
            }
        }
        EditorGUILayout.Space(0, true);
        if (GUILayout.Button("Bu sohbetteki tüm incelemeleri listele", GUILayout.Width(250)))
        {
            if (state != "inspectSohbeteOzel")
            {
                DownloadReviewList(sohbetInceleme.sohbetID);
            }
            else
            {
                state = "reviewPageSohbeteOzel";//Eğer zaten sohbete özel tüm datayı indirdiysek aynı işlemi yapmak yerine
                                                //bir önceki sayfaya atıyoruz. Bu datayı tekrar indirmeyi önlüyor.
            }
        }
        EditorGUILayout.EndHorizontal();

        GUILayout.Space(10);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField(Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(sohbetInceleme.unixTimeStamp).ToString());
        for (int i = 0; i < sohbetInceleme.yildiz; i++)
            GUILayout.Label(starSprite, GUILayout.Width(32), GUILayout.Height(32));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.LabelField(sohbetInceleme.inceleme, userFont);
        GUILayout.Space(5);
        EditorGUILayout.LabelField(sohbetInceleme.sohbetMetni, h2);

        GUILayout.Space(10);
        EditorGUILayout.LabelField("Kullanıcı Adı: ", sohbetInceleme.userName, h2);
        EditorGUILayout.LabelField("Platform: ", sohbetInceleme.platform);
        
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Sohbet ID: ", sohbetInceleme.sohbetID);
        if (mevcutSohbetler == null)
        {
            if (GUILayout.Button("Sohbeti Aç", GUILayout.Width(100)))
            {
                string iDOld = sohbetInceleme.sohbetID;
                string iD = string.Empty;
                for(int i = 0; i < iDOld.Length; i++)
                {
                    if (i == 0|| i==iDOld.Length-1)
                    {
                        if (iDOld[i] != '-')
                        {
                            iD += iDOld[i];
                        }
                    }
                    else
                    {
                        iD += iDOld[i];
                    }
                }
                var iDs = iD.Split("|");

                if (iDs.Length <= 1)
                {
                    iDs = iD.Split("-");
                }

                mevcutSohbetler = new Sohbet[iDs.Length];
                for (int i = 0; i < mevcutSohbetler.Length; i++)
                {
                    mevcutSohbetler[i] = PreferecesEditor.FindSohbet(iDs[i]);
                }
            }
        }
        else
        {
            EditorGUILayout.BeginVertical();
            foreach (Sohbet sohbet in mevcutSohbetler)
            {
                EditorGUILayout.ObjectField(sohbet, typeof(Sohbet), false);
            }
            EditorGUILayout.EndVertical();
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("User ID: ", sohbetInceleme.userID);
        if (GUILayout.Button("Kopyala", GUILayout.Width(100)))
        {
            GUIUtility.systemCopyBuffer = sohbetInceleme.userID;
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.LabelField("App Version: ", sohbetInceleme.appVersion);

        if (adminYanitlayabilir)
        {
            adminYaniti.answer = EditorGUILayout.TextArea(adminYaniti.answer, EditorStyles.textArea, GUILayout.Height(200));

            if (GUILayout.Button("Cevap Ver"))
            {
                adminYaniti.id = sohbetInceleme.incelemeID;
                FirebaseDatabase.DefaultInstance.GetReference("SohbetIncelemeleri/Yanitlar/" +
                    sohbetInceleme.userID + "/" + sohbetInceleme.incelemeID).
                    SetRawJsonValueAsync(JsonConvert.SerializeObject(adminYaniti)).ContinueWithOnMainThread(task =>
                    {
                        if (task.IsFaulted || task.IsCanceled)
                        {
                            Debug.LogError(task.Exception.ToString());

                            adminYanitlayabilir = false;
                            adminYaniti.answer = string.Empty;
                            return;
                        }

                        AdminMessageHistory.Data data = new();
                        data.title = "Sohbet Inceleme";
                        data.userMessage = sohbetInceleme.inceleme;
                        data.adminsAnswer = adminYaniti.answer;
                        data.ID = adminYaniti.id;
                        data.timeStamp = Magnus.Time.DateTimeOperations.serverUnixTimeStamp;

                        realtimeDatabaseManager.SetData("AdminMessageHistory/" +
                            sohbetInceleme.userID + "/" + data.ID,
                            JsonConvert.SerializeObject(data));

                        adminYanitlayabilir = false;
                        adminYaniti.answer = string.Empty;
                    });
            }
        }

        foreach (AdminMessageHistory.Data adminData in adminDatas)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(Magnus.Time.DateTimeOperations.
    UnixTimeStampToDateTime(adminData.timeStamp).ToString());

            if (GUILayout.Button("Aç", GUILayout.Width(70)))
            {
                state = "drawMessage";
                currentData = adminData;
                EditorGUI.FocusTextInControl(null);
            }

            EditorGUILayout.EndHorizontal();

            EditorGUILayout.LabelField(adminData.title, h4);
            EditorGUILayout.Space(10);
        }
    }

    private void DrawMessage()
    {
        if (GUILayout.Button("<", GUILayout.Width(30)))
        {
            state = "inspect";
        }
        EditorGUILayout.Space(10);

        EditorGUILayout.LabelField(currentData.title);
        EditorGUILayout.LabelField(Magnus.Time.DateTimeOperations.
    UnixTimeStampToDateTime(currentData.timeStamp).ToString());
        EditorGUILayout.Space(10);

        EditorGUILayout.LabelField("Kullanıcı Mesajı");
        EditorGUILayout.LabelField(currentData.userMessage);
        EditorGUILayout.Space(5);

        EditorGUILayout.LabelField("Admin Yanıtı");
        EditorGUILayout.LabelField(currentData.adminsAnswer);

    }

    private void DownloadReviewList(int days)
    {
        currentPage = 0;
        state = "reviewPage";
        filtre = $"Son {days} gün";

        days = Mathf.Clamp(days, 0, 30);
        sohbetIncelemeleri = new();

        for (int i = 0; i < days; i++)
        {
            DateTime date = DateTime.Now.AddDays(-i);
            FirebaseDatabase.DefaultInstance
            .GetReference("SohbetIncelemeleri/TariheGore/" + $"{date.Day}-{date.Month}-{date.Year}/")
            .GetValueAsync().ContinueWithOnMainThread(task =>
            {
                if (task.IsFaulted || task.IsCanceled)
                {
                    Debug.LogError("Veriler alınırken hata meydana geldi");
                // Handle the error...
            }
                else if (task.IsCompleted)
                {
                    DataSnapshot snapshot = task.Result;
                    List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                    if (snapshotChilds.Count > 0)
                    {
                        for (int i = 0; i < snapshotChilds.Count; i++)
                        {
                            sohbetIncelemeleri.Add(new Inceleme(snapshot.Key, JsonConvert.DeserializeObject<InAppReview.SohbetInceleme>(snapshotChilds[i].GetRawJsonValue())));
                        }
                        avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(sohbetIncelemeleri);
                        Repaint();
                    }
                    else
                    {
                        Debug.Log(snapshot.Key + " tarihi için uygun inceleme bulunamadı");
                    }
                }
            });
        }
    }

    //Bu fonksiyon bir sohbet idsindeki tum incelemeleri indirir.
    private void DownloadReviewList(string sohbetID)
    {
        state = "reviewPageSohbeteOzel";
        filtre = $"{sohbetID} sohbet ID'si için tümü";

        sohbetIncelemeleri = new();

        FirebaseDatabase.DefaultInstance
        .GetReference("SohbetIncelemeleri/SohbeteGore/" + sohbetID)
        .GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsFaulted || task.IsCanceled)
            {
                Debug.LogError("Veriler alınırken hata meydana geldi");
                    // Handle the error...
                }
            else if (task.IsCompleted)
            {
                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                if (snapshotChilds.Count > 0)
                {
                    for (int i = 0; i < snapshotChilds.Count; i++)
                    {
                        sohbetIncelemeleri.Add(JsonConvert.DeserializeObject<Inceleme>(snapshotChilds[i].GetRawJsonValue()));
                    }
                    avaliableSohbetIncelemeleri = IncelemeleriTariheGoreSirala(sohbetIncelemeleri);
                    Repaint();
                }
                else
                {
                    Debug.Log(snapshot.Key + " tarihi için uygun inceleme bulunamadı");
                }
            }
        });
    }

    private List<Inceleme> IncelemeleriTariheGoreSirala(List<Inceleme> sohbetIncelemeleri)
    {
        if (sohbetIncelemeleri != null)
        {
            if (sohbetIncelemeleri.Count > 0)
            {
                List<Inceleme> _sohbetIncelemeleri2 = new List<Inceleme>();
                _sohbetIncelemeleri2.Add(sohbetIncelemeleri[0]);
                for (int i = 1; i < sohbetIncelemeleri.Count; i++)
                {
                    int currentIndex = _sohbetIncelemeleri2.Count;
                    for (int z = _sohbetIncelemeleri2.Count -1; z > -1; z--)
                    {
                        double deltaDay = (DateTime.Now - Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(sohbetIncelemeleri[i].inceleme.unixTimeStamp)).TotalDays;
                        double deltaDay2 = (DateTime.Now - Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(_sohbetIncelemeleri2[z].inceleme.unixTimeStamp)).TotalDays;

                        if (deltaDay < deltaDay2)
                        {
                            currentIndex = z;
                        }
                    }
                    _sohbetIncelemeleri2.Insert(currentIndex, sohbetIncelemeleri[i]);
                }

                sohbetIncelemeleri = _sohbetIncelemeleri2;
            }
        }

        return sohbetIncelemeleri;
    }

    public int GetMaxPageCount()
    {
        int remainder;
        int quotient = Math.DivRem(sohbetIncelemeleri.Count, maxElementCount, out remainder);
        //return remainder == 0 ? quotient : quotient + 1;
        return quotient;
    }

    private void DrawLine(int height)
    {
        Rect rect = EditorGUILayout.GetControlRect(false, height);

        rect.height = height;

        EditorGUI.DrawRect(rect, new Color(0.5f, 0.5f, 0.5f, 1));
    }

    private void DrawLine(int height, Color color)
    {
        Rect rect = EditorGUILayout.GetControlRect(false, height);

        rect.height = height;

        EditorGUI.DrawRect(rect, color);
    }

    private void DrawLineWithOffset(int height, float offset, float ratio)
    {
        Rect rect = EditorGUILayout.GetControlRect(false, height);

        rect.height = height;
        rect.width *= ratio;
        rect.x += offset;

        EditorGUI.DrawRect(rect, new Color(0.5f, 0.5f, 0.5f, 1));
    }

    private float DrawLine(int height, float ratio, Color color)
    {
        Rect rect = EditorGUILayout.GetControlRect(false, height);

        float firstWidth = rect.width;
        rect.height = height;
        rect.width *= ratio;
        float offset = rect.width - firstWidth;

        EditorGUI.DrawRect(rect, color);

        return offset;
    }

    static IEnumerable<string> Split(string str, int chunkSize)
    {
        return Enumerable.Range(0, str.Length / chunkSize)
            .Select(i => str.Substring(i * chunkSize, chunkSize));
    }

    public static string GetPartOfString(string text, int letterCount)
    {
        bool ucNoktaEkle = letterCount < text.Length;
        letterCount = Mathf.Clamp(letterCount, 0, text.Length);
        string returnText = string.Empty;

        for(int i = 0; i < letterCount; i++)
        {
            returnText += text[i];
        }

        if (ucNoktaEkle)
            returnText += "...";

        return returnText;
    }

    [System.Serializable]
    private class Inceleme
    {
        public string onlineKey;
        public InAppReview.SohbetInceleme inceleme;

        public Inceleme(string onlineKey, InAppReview.SohbetInceleme inceleme)
        {
            this.onlineKey = onlineKey;
            this.inceleme = inceleme;
        }
    }
}
