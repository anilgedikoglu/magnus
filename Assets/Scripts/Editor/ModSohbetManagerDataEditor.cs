using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Newtonsoft.Json;
using Firebase.Storage;
using System.IO;
using Firebase.Extensions;
using System.Threading;

[CustomEditor(typeof(ModSohbetManagerData))]
public class ModSohbetManagerDataEditor : Editor
{
    RealtimeDatabaseManager databaseManager;

    ModSohbetManagerData sohbetManagerData;
    private GUIStyle h1;
    private GUIStyle h2;
    private GUIStyle h3;
    private GUIStyle h4;
    private GUIStyle userFont;

    private int currentPackageName;

    float downloadRatio;

    CurrentPlayerData playerData;

    bool isOnlineDatabaseOld;

    private List<string> releaseVersions;
    private string addingVersionName;

    private string updatingVersionName;
    private int updatingPackageName;

    private void OnEnable()
    {
        sohbetManagerData = target as ModSohbetManagerData;
        databaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        playerData = FindObjectOfType<CurrentPlayerData>();
        downloadRatio = 0;
    }

    public override void OnInspectorGUI()
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

        EditorGUILayout.Space(10);

        if (!EditorApplication.isPlaying)
        {
            EditorGUILayout.HelpBox("Bu paneli kullanabilmek için uygulamayı başlatmalı ve giriş yapmalısınız!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();
                releaseVersions = new();
            }
        }
        else
        {
            if(releaseVersions == null)
            {
                releaseVersions = new();
            }

            if (playerData.isDatabaseLoaded)
            {
                DrawLocalePanel();

                DrawOnlinePanel();

                if (repaintIEnumerator != null)
                {
                    playerData.StopCoroutine(repaintIEnumerator);
                }

                repaintIEnumerator = null;
            }
            else
            {
                if (repaintIEnumerator == null)
                {
                    repaintIEnumerator = RepaintIEnumerator();
                }

                playerData.StartCoroutine(repaintIEnumerator);

                EditorGUILayout.HelpBox("Mevcut online vertabanı halen işleniyor. Lütfen bekleyin...", MessageType.Info);

                isOnlineDatabaseOld = true;
            }
        }
    }

    private void DrawLocalePanel()
    {
        EditorGUILayout.LabelField("Yerel Veritabanı", h1);
        if (sohbetManagerData.tumSohbetler != null)
        {
            EditorGUILayout.LabelField("Veritabanında bulunan toplam sohbet sayısı: " + sohbetManagerData.tumSohbetler.Length);
        }

        EditorGUILayout.LabelField("Veritabanında bulunan toplam ayrı mod sayısı: " + sohbetManagerData.mods.Count);

        if (downloadRatio <= 0)
        {
            if (GUILayout.Button("Yerel Sohbet Veritabanını Güncelle"))
            {
                sohbetManagerData.InitializeMods();
                EditorUtility.SetDirty(sohbetManagerData);
                isOnlineDatabaseOld = false;
                releaseVersions = new List<string>(playerData.localPlayerDatas.releaseVersions);

                databaseManager.GetData("Versions/OnlineDataVersion", (data) =>
                {
                    currentPackageName = JsonConvert.DeserializeObject<int>(data);
                });
            }
        }
    }

    private IEnumerator repaintIEnumerator;
    private IEnumerator RepaintIEnumerator()
    {
        while (!playerData.isDatabaseLoaded)
        {
            yield return new WaitForSeconds(.1f);
            Repaint();
        }
    }

    private void DrawOnlinePanel()
    {
        EditorGUILayout.LabelField("Online Veritabanı", h1);

        EditorGUILayout.Space(10);

        sohbetManagerData.useOnlineSohbetCacheOnEditor = EditorGUILayout.Toggle(
            "Online Klasorunu Kullan",
            sohbetManagerData.useOnlineSohbetCacheOnEditor);

        EditorGUILayout.LabelField("Online data versiyonu: " + currentPackageName +
            ((downloadRatio > 0) ? " -> " + (currentPackageName + 1) : string.Empty), h3);

        if (downloadRatio <= 0)
        {
            if (!isOnlineDatabaseOld)
            {
                if (currentPackageName > 0)
                {

                    EditorGUILayout.Space(10);

                    EditorGUILayout.LabelField("Bu Sürümlere Hemen Gönder", h3);

                    foreach (var version in releaseVersions)
                    {
                        EditorGUILayout.BeginHorizontal();
                        EditorGUILayout.LabelField(version);
                        if (GUILayout.Button("X", GUILayout.Width(40)))
                        {
                            releaseVersions.Remove(version);
                            EditorGUI.FocusTextInControl(null);
                            break;

                        }
                        EditorGUILayout.EndHorizontal();
                    }

                    EditorGUILayout.BeginHorizontal();
                    addingVersionName = EditorGUILayout.TextField(addingVersionName);
                    if (GUILayout.Button("+", GUILayout.Width(40)))
                    {
                        releaseVersions.Add(addingVersionName);
                        addingVersionName = string.Empty;
                        EditorGUI.FocusTextInControl(null);
                    }
                    EditorGUILayout.EndHorizontal();

                    EditorGUILayout.Space(10);
                    if (GUILayout.Button("Online Veritabanı Güncellemesi Gönder"))
                    {
                        UploadCurrentOnlineData();
                    }
                }
                else
                {
                    EditorGUILayout.HelpBox("Online veritabanı versiyonuna " +
               "erişilirken hata meydana geldi. Yerel sohbet veritabanini" +
               " guncellemek sorunu cozebilir", MessageType.Error);
                }
            }
            else
            {
                EditorGUILayout.HelpBox("Online veritabanı güncellemesi göndermeden önce" +
             " \"Yerel Sohbet Veritabanını\" tekrar güncelleyerek " +
             "gönderilecek pakete yereldeki dosyaları yazmanız gerekli!", MessageType.Warning);
            }
        }

        if (downloadRatio > 0)
        {
            EditorGUILayout.BeginHorizontal();
            float offset = DrawLine(2, downloadRatio * 2f, Color.white);
            DrawLineWithOffset(2, offset, 2f - downloadRatio * 2f);
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.LabelField("Uploading: %" + (int)(downloadRatio * 100));

            EditorGUILayout.Space(10);

            EditorGUILayout.HelpBox("Online veritabanı güncellemesi gönderiliyor. " +
                "Lütfen uygulamayı kapatmayın!", MessageType.Info);
        }

        EditorGUILayout.Space(50);
        EditorGUILayout.LabelField("Bir Sürüm İçin Online Database Versiyonunu Değiştir", h3);
        EditorGUILayout.BeginHorizontal();
        updatingVersionName = EditorGUILayout.TextField(updatingVersionName);
        if (!string.IsNullOrEmpty(updatingVersionName))
        {
            if (GUILayout.Button("Sorgula"))
            {
                databaseManager.GetData("Versions/OnlineDataVersionsByAppVersion/" + updatingVersionName.Replace(".", "-"), (data) =>
                {
                    int resVersion = JsonConvert.DeserializeObject<int>(data);
                    Debug.Log($"{updatingVersionName} versiyonu için mevcut online database paket adı: {resVersion}");
                });
            }
        }
        EditorGUILayout.EndHorizontal();
        updatingPackageName = EditorGUILayout.IntField(updatingPackageName);
        if (updatingPackageName > 0)
        {
            if (GUILayout.Button("Değiştir"))
            {
                databaseManager.SetData("Versions/OnlineDataVersionsByAppVersion/" + updatingVersionName.Replace(".", "-"), JsonConvert.SerializeObject(updatingPackageName),
                () =>
                {
                    Debug.Log($"<color=green><b>Online sohbet paket sürümü belirtilen uygulama sürümü için başarı ile değiştirildi {updatingVersionName}=>{updatingPackageName}.</b></color>");
                },
                (reason) =>
                {
                    Debug.LogError("Online sohbet paket numarasi yazilirken hata meydana geldi" + reason);
                });
            }
        }
    }

    private void UploadCurrentOnlineData()
    {
        string packageName = (currentPackageName + 1).ToString();
        FirebaseStorage storage = FirebaseStorage.DefaultInstance;
        StorageReference reference = storage.RootReference;
        StorageReference onlineDataRef = reference.Child("OnlineSohbetData").Child(packageName).Child("online.magnus");

        if(File.Exists(Application.persistentDataPath + "/online.magnus"))
        {
            // Start uploading a file
            var task = onlineDataRef.PutFileAsync(Application.persistentDataPath + "/online.magnus", null,
                    new StorageProgress<UploadState>(state => {
                    // called periodically during the upload
                        Debug.Log(System.String.Format("Progress: {0} of {1} bytes transferred." + downloadRatio + (((float)state.BytesTransferred) / state.TotalByteCount),
                            state.BytesTransferred, state.TotalByteCount));
                        downloadRatio = ((float)state.BytesTransferred) / state.TotalByteCount;
                        Repaint();
                    }), CancellationToken.None, null);


            task.ContinueWithOnMainThread(resultTask => {
                if (!resultTask.IsFaulted && !resultTask.IsCanceled)
                {
                    currentPackageName += 1;

                    Debug.Log("<color=green><b>Online sohbet paketi basari ile gonderildi.</b></color>");

                    playerData.datas.onlineDatabaseVersion += 1;

                    databaseManager.SetData("Versions/OnlineDataVersion", JsonConvert.SerializeObject(currentPackageName),
                    () =>
                    {
                        Debug.Log("<color=green><b>Online sohbet paket surumu basari ile gonderildi.</b></color>");
                    },
                    (reason) =>
                    {
                        Debug.LogError("Online sohbet paket numarasi yazilirken hata meydana geldi" + reason);
                    });


                    foreach (var version in releaseVersions)
                    {
                        databaseManager.SetData("Versions/OnlineDataVersionsByAppVersion/" + version.Replace(".", "-"), JsonConvert.SerializeObject(currentPackageName),
                        () =>
                        {
                            Debug.Log("<color=green><b>Online sohbet paket surumu basari ile gonderildi.</b></color>");
                        },
                        (reason) =>
                        {
                            Debug.LogError("Online sohbet paket numarasi yazilirken hata meydana geldi" + reason);
                        });
                    }
                }
                else
                {
                    Debug.LogError("Hata! " + resultTask.Exception.ToString());
                }
                downloadRatio = 0;
                Repaint();
            });
        }
        else
        {
            Debug.LogError("Online sohbet paketi gonderilirken hata meydana geldi!");
        }
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
}
