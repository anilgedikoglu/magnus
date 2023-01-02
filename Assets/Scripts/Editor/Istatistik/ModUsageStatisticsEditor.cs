using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Firebase.Database;
using System;
using Firebase.Extensions;
using System.Linq;

public class ModUsageStatisticsEditor : EditorWindow
{
    private CurrentPlayerData currentPlayerData;

    List<DownloadedModStat> downloadedModStats;

    private Vector2 scroll;

    private string userID;
    private List<PlayerData.FalModlariIstatistik> userMods;
    private bool userIDError;

    private ModUsageStat modUsageStatData;

    private Sohbet mevcutSohbet;

    [MenuItem("Magnus/Istatistikler/Mod Kullanimi")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(ModUsageStatisticsEditor));
    }

    private void OnEnable()
    {
        userMods = new();
        currentPlayerData = FindObjectOfType<CurrentPlayerData>();
        downloadedModStats = new();
        mevcutSohbet = null;

        modUsageStatData = (ModUsageStat)Resources.Load($"{ModSohbetManagerData.localDatabaseName}/ModUsageStatData");
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
        if (GUILayout.Button("Bugün"))
        {
            DownloadStats(1);
        }
        if (GUILayout.Button("Son 3 Gün"))
        {
            DownloadStats(3);
        }
        if (GUILayout.Button("Son 1 Hafta"))
        {
            DownloadStats(7);
        }
        if (GUILayout.Button("Son 1 Ay"))
        {
            DownloadStats(30);
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(10);

        GUILayout.Label("Mod İstatistikleri", h1);
        EditorGUILayout.Space(5);

        GUILayout.Label("Mod/Kullanım miktarı", h3);
        EditorGUILayout.Space(5);
        foreach (DownloadedModStat downloadedModStat in downloadedModStats)
        {
            ModUsageStat.ModStat modStat = modUsageStatData.mods.Find(x => x.onlineKey.Equals(downloadedModStat.onlineKey));

            if (modStat != null)
            {
                GUILayout.Label(modStat.UITitle + ": " +
          downloadedModStat.count.ToString(), GUILayout.ExpandWidth(false));
                EditorGUILayout.Space(2);
            }
            else
            {
                GUILayout.Label(downloadedModStat.onlineKey + ": " +
      downloadedModStat.count.ToString(), GUILayout.ExpandWidth(false));
                EditorGUILayout.Space(2);
            }

        }

        EditorGUILayout.Space(10);
        userID = EditorGUILayout.TextField("User ID:",userID);
        if (GUILayout.Button("Son 10 fal modu"))
        {
            FirebaseDatabase.DefaultInstance.GetReference($"Users/{userID}/falModlariIstatistik").GetValueAsync().ContinueWithOnMainThread(task =>
            {
                if (task.IsCanceled || task.IsFaulted)
                {
                    userIDError = true;
                }
                else
                {
                    try
                    {
                        userMods = Newtonsoft.Json.JsonConvert.DeserializeObject<List<PlayerData.FalModlariIstatistik>>(task.Result.GetRawJsonValue());
                        userIDError = false;
                    }
                    catch
                    {
                        userIDError = true;
                        Debug.LogError(task.Result.GetRawJsonValue());
                    }
                }

                mevcutSohbet = null;
                Repaint();
            });
        }

        if (userIDError)
        {
            EditorGUILayout.HelpBox("Kullanici ID yanlis girildi veya bu ID'ye ait data bulunamadi", MessageType.Error);
        }
        else
        {
            foreach(PlayerData.FalModlariIstatistik istatistik in userMods)
            {
                EditorGUILayout.Space(5);

           
                ModUsageStat.ModStat modStat = modUsageStatData.mods.Find(x => x.mod.Equals(istatistik.mod));

                if (modStat != null)
                {
                    EditorGUILayout.LabelField(modStat.UITitle, h2);
                }
                else
                {
                    EditorGUILayout.LabelField(istatistik.mod, h2);
                }

                foreach (string id in istatistik.sohbetIDleri)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField(id);
                    if(GUILayout.Button("Bul", GUILayout.Width(30)))
                        mevcutSohbet = PreferecesEditor.FindSohbet(id);
                    EditorGUILayout.EndHorizontal();
                }
            }
        }

        if (userMods.Count > 0 && mevcutSohbet != null)
            EditorGUILayout.ObjectField(mevcutSohbet, typeof(Sohbet), false);
    }

    private void DownloadStats(int days)
    {
        downloadedModStats = new List<DownloadedModStat>();
        for (int i = 0; i < days; i++)
        {
            DateTime date = DateTime.Now.AddDays(-i);
            FirebaseDatabase.DefaultInstance.GetReference("ModUsage/" + $"{date.Day}-{date.Month}-{date.Year}").
                GetValueAsync().ContinueWithOnMainThread(task =>
                {
                    List<DataSnapshot> dataSnapshots = task.Result.Children.ToList();

                    if (dataSnapshots.Count > 0)
                    {
                        foreach (DataSnapshot dataSnapshot in dataSnapshots)
                        {
                            Debug.Log(dataSnapshot.Key);
                            Debug.Log(dataSnapshot.Value);

                            string onlineKey = dataSnapshot.Key.ToString();
                            int.TryParse(dataSnapshot.Value.ToString(), out int count);
                            string mod = dataSnapshot.Key;


                            DownloadedModStat currentStat = downloadedModStats.Find(x => x.onlineKey.Equals(onlineKey));

                            if (currentStat == null)
                                downloadedModStats.Add(new DownloadedModStat(mod, onlineKey, count));
                            else
                                currentStat.count += count;
                        }
                    }
                    else
                    {
                        Debug.Log(task.Result.Key + " tarihi için veri bulunamadi");
                    }

                    Repaint();

                    var playerData = FindObjectOfType<CurrentPlayerData>();
                    foreach (ModUsageStat.ModStat modStat in playerData.modUsageStat.mods)
                    {
                        var stat = downloadedModStats.Find(x => x.onlineKey.Equals(modStat.onlineKey));
                        if (stat == null)
                        {
                            downloadedModStats.Add(new DownloadedModStat(modStat.mod, modStat.onlineKey, 0));
                        }
                    }

                    downloadedModStats = downloadedModStats.OrderByDescending(x => x.count).ToList();
                });
        }
    }

    private class DownloadedModStat
    {
        public string mod;
        public string onlineKey;
        public int count;

        public DownloadedModStat()
        {
            mod = string.Empty;
            onlineKey = string.Empty;
            count = 0;
        }

        public DownloadedModStat(string mod, string onlineKey, int count)
        {
            this.mod = mod;
            this.onlineKey = onlineKey;
            this.count = count;
        }
    }
}
