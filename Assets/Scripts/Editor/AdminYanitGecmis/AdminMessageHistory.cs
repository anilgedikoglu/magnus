using Firebase.Database;
using Firebase.Extensions;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class AdminMessageHistory : EditorWindow
{
    private AuthenticationManager authenticationManager;
    private RealtimeDatabaseManager realtimeDatabaseManager;
    private string currentUserID;
    private string state;
    private Data currentData;

    private Data[] adminDatas;

    private GUIStyle h1;
    private GUIStyle h2;
    private GUIStyle h3;
    private GUIStyle h4;
    private GUIStyle userFont;

    private Vector2 scrollPos;

    [MenuItem("Magnus/Istatistikler/Admin Yanit Gecmisi")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(AdminMessageHistory));
    }

    private void OnEnable()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        adminDatas = new Data[0];
    }

    private void OnGUI()
    {
        h1 = new GUIStyle("label");
        h1.fontSize = 20;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        h2 = new GUIStyle("label");
        h2.fontSize = 16;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        h3 = new GUIStyle("label");
        h3.fontSize = 14;
        h3.fontStyle = FontStyle.Bold;
        h3.wordWrap = true;

        h4 = new GUIStyle("label");
        h4.fontSize = 12;
        h4.fontStyle = FontStyle.Bold;
        h4.wordWrap = true;

        userFont = new GUIStyle("label");
        userFont.fontSize = 12;
        userFont.fontStyle = FontStyle.Italic;
        userFont.wordWrap = true;

        if (!EditorApplication.isPlaying)
        {
            EditorGUILayout.HelpBox("Bu paneli kullanabilmek için uygulamayı " +
                "başlatmalı ve giriş yapmalısınız!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                state = "mainMenu";
                EditorApplication.EnterPlaymode();
            }
        }
        else
        {
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

            switch (state)
            {
                case "mainMenu":
                    EditorGUILayout.LabelField("Yanıt Geçmişi", h1);
                    DrawMainMenu();
                    break;
                case "drawMessage":
                    EditorGUILayout.LabelField("İncele", h1);
                    DrawMessage();
                    break;
                default:
                    EditorGUILayout.LabelField("Yanıt Geçmişi", h1);
                    DrawMainMenu();
                    break;
            }

            EditorGUILayout.EndScrollView();
        }
    }

    private void DrawMainMenu()
    {
        currentUserID = EditorGUILayout.TextField(currentUserID);

        if (GUILayout.Button("Kullanıcı Yanıt Geçmişini Görüntüle"))
        {
            FirebaseDatabase.DefaultInstance.GetReference("AdminMessageHistory").Child(currentUserID).
                GetValueAsync().ContinueWithOnMainThread(task =>
                {
                    if (task.IsFaulted || task.IsCanceled)
                    {
                        Debug.LogError(task.Exception.ToString());
                        return;
                    }

                    DataSnapshot[] childs = task.Result.Children.ToArray();
                    adminDatas = new Data[childs.Length];

                    for (int i = 0; i < childs.Length; i++)
                    {
                        adminDatas[i] = JsonConvert.DeserializeObject
                                <Data>(childs[i].GetRawJsonValue());

                    
                    }

                    adminDatas = adminDatas.OrderByDescending(item => item.timeStamp).ToArray();

                    Repaint();
                });
        }

        EditorGUILayout.Space(10);
        foreach (Data adminData in adminDatas)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(Magnus.Time.DateTimeOperations.
    UnixTimeStampToDateTime(adminData.timeStamp).ToString());

            if (GUILayout.Button("İncele", GUILayout.Width(70)))
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
            state = "mainMenu";
        }
        EditorGUILayout.Space(10);

        EditorGUILayout.LabelField(currentData.title, h2);
        EditorGUILayout.LabelField(Magnus.Time.DateTimeOperations.
    UnixTimeStampToDateTime(currentData.timeStamp).ToString());
        EditorGUILayout.Space(10);

        EditorGUILayout.LabelField("Kullanıcı Mesajı", h4);
        EditorGUILayout.LabelField(currentData.userMessage);
        EditorGUILayout.Space(5);

        EditorGUILayout.LabelField("Admin Yanıtı", h4);
        EditorGUILayout.LabelField(currentData.adminsAnswer);

    }

    [System.Serializable]
    public class Data
    {
        public string title;
        public string userMessage;
        public string adminsAnswer;
        public long timeStamp;
        public string ID;

        public Data()
        {
            title=string.Empty;
            userMessage = string.Empty;
            adminsAnswer = string.Empty;
            ID = string.Empty;
            timeStamp = 0;
        }
    }
}
