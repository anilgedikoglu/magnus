using Firebase.Database;
using Firebase.Extensions;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class UsersInformationEditor : EditorWindow
{
    private CurrentPlayerData currentPlayerData;
    private Vector2 scroll;

    private List<Stat> cinsiyetStat;
    private List<Stat> meslekStat;
    private List<Stat> medeniDurumStat;
    private List<Stat> yasStat;
    private List<Stat> dogumSehriStat;

    private bool drawCinsiyet;
    private bool drawMeslek;
    private bool drawMedeniDurum;
    private bool drawYas;
    private bool drawDogumSehri;
    private GUIStyle h1;
    private GUIStyle h2;
    private GUIStyle h3;
    private GUIStyle h4;
    private GUIStyle userFont;

    [MenuItem("Magnus/Istatistikler/Kullanici Istatistikleri")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(UsersInformationEditor));
    }

    private void OnEnable()
    {
        currentPlayerData = FindObjectOfType<CurrentPlayerData>();

        ResetPanel();
    }

    private void OnGUI()
    {
        scroll = EditorGUILayout.BeginScrollView(scroll);
        if (!EditorApplication.isPlaying)
        {
            EditorGUILayout.HelpBox("Bu paneli kullanabilmek için uygulamayı başlatmalı ve giriş yapmalısınız!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();

                ResetPanel();
            }
        }
        else
        {
            DrawWindow();
        }
        EditorGUILayout.EndScrollView();
    }

    private void DrawWindow()
    {
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

        userFont = new GUIStyle("label");
        userFont.fontSize = 12;
        userFont.fontStyle = FontStyle.Italic;
        userFont.wordWrap = true;

        if (GUILayout.Button("Yenile"))
        {
            ResetPanel();
            DownloadStats();
        }

        EditorGUILayout.LabelField("Kullanıcı Dağılımı", h1);

        EditorGUILayout.Space(10);
        drawCinsiyet = EditorGUILayout.BeginFoldoutHeaderGroup(drawCinsiyet, "Cinsiyet | " + GetPopulerCategory(cinsiyetStat));
        if (drawCinsiyet)
        {
            foreach (Stat stat in cinsiyetStat)
            {
                EditorGUILayout.LabelField(stat.name + ": " + stat.value);

            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(5);
        drawYas = EditorGUILayout.BeginFoldoutHeaderGroup(drawYas, "Yaş | " + GetPopulerCategory(yasStat));
        if (drawYas)
        {
            foreach (Stat stat in yasStat)
            {
                EditorGUILayout.LabelField(stat.name + ": " + stat.value);

            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(5);
        drawMeslek = EditorGUILayout.BeginFoldoutHeaderGroup(drawMeslek, "Meslek | " + GetPopulerCategory(meslekStat));
        if (drawMeslek)
        {
            foreach (Stat stat in meslekStat)
            {
                EditorGUILayout.LabelField(stat.name + ": " + stat.value);

            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(5);
        drawMedeniDurum = EditorGUILayout.BeginFoldoutHeaderGroup(drawMedeniDurum, "Medeni Durum | " + GetPopulerCategory(medeniDurumStat));
        if (drawMedeniDurum)
        {
            foreach (Stat stat in medeniDurumStat)
            {
                EditorGUILayout.LabelField(stat.name + ": " + stat.value);

            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(5);
        drawDogumSehri = EditorGUILayout.BeginFoldoutHeaderGroup(drawDogumSehri, "Doğum Şehri | " + GetPopulerCategory(dogumSehriStat));
        if (drawDogumSehri)
        {
            foreach (Stat stat in dogumSehriStat)
            {
                EditorGUILayout.LabelField(stat.name + ": " + stat.value);

            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private string GetPopulerCategory(List<Stat> stats)
    {
        if (stats.Count <= 0)
            return string.Empty;

        int totalCount = 0;

        foreach(Stat stat in stats)
        {
            totalCount += stat.value;
        }

        int percentage = (int)(((float)stats[0].value / totalCount) * 100f);

        return stats[0].name + ":  %" + percentage;
    }

    private void DownloadStats()
    {
        FirebaseDatabase.DefaultInstance.GetReference("UsersInformation").
            GetValueAsync().ContinueWithOnMainThread(task =>
            {
                List<DataSnapshot> dataSnapshots = task.Result.Children.ToList();

                foreach (DataSnapshot dataSnapshot in dataSnapshots)
                {
                    List<DataSnapshot> statSnapshots = dataSnapshot.Children.ToList();

                    foreach (DataSnapshot stat in statSnapshots)
                    {
                        string onlineKey = stat.Key.ToString();
                        int.TryParse(stat.Value.ToString(), out int value);

                        AddStat(dataSnapshot.Key, onlineKey, value);
                    }
                }
                Repaint();
            });
    }

    private void AddStat(string listName, string onlineKey, int value)
    {
        switch (listName)
        {
            case "meslek":
                meslekStat.Add(new Stat(onlineKey, value));
                meslekStat = meslekStat.OrderByDescending(x => x.value).ToList();
                break;
            case "cinsiyet":
                cinsiyetStat.Add(new Stat(onlineKey, value));
                cinsiyetStat = cinsiyetStat.OrderByDescending(x => x.value).ToList();
                break;
            case "medeniDurum":
                medeniDurumStat.Add(new Stat(onlineKey, value));
                medeniDurumStat = medeniDurumStat.OrderByDescending(x => x.value).ToList();
                break;
            case "yas":
                yasStat.Add(new Stat(onlineKey, value));
                yasStat = yasStat.OrderByDescending(x => x.value).ToList();
                break;
            case "dogum sehri":
                dogumSehriStat.Add(new Stat(onlineKey, value));
                dogumSehriStat = dogumSehriStat.OrderByDescending(x => x.value).ToList();
                break;
        }
    }

    private void ResetPanel()
    {
        cinsiyetStat = new List<Stat>();
        meslekStat = new List<Stat>();
        medeniDurumStat = new List<Stat>();
        yasStat = new List<Stat>();
        dogumSehriStat = new List<Stat>();
    }

    public class Stat
    {
        public string name;
        public int value;

        public Stat()
        {
            name = string.Empty;
            value = 0;
        }

        public Stat(string name, int value)
        {
            this.name = name;
            this.value = value;
        }
    }
}
