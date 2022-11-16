using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.Globalization;
using System.IO;
using Newtonsoft.Json;
using Firebase.Storage;
using Firebase.Extensions;
using System.Threading.Tasks;
using Firebase.Database;
using System.Linq;
using System.Threading;

public class OnlineMessageWindow : EditorWindow
{
    public AuthenticationManager authenticationManager;
    public RealtimeDatabaseManager realtimeDatabaseManager;

    private string baslik;
    private string aciklama;
    private long tarihUnixTimeStamp;

    private int currentYear, currentMonth, currentDay;
    private DateTime silinecegiTarih;

    Texture2D messagePhoto;

    string _messagePhotoPath;
    string MessagePhotoPath
    {
        get
        {
            return _messagePhotoPath;
        }
        set
        {
            _messagePhotoPath = value;

            messagePhoto = new Texture2D(2, 2);
            messagePhoto.LoadImage(File.ReadAllBytes(_messagePhotoPath));
        }
    }
    string messagePhotoExt;

    private GUIStyle h1, h2, h3, h4, boldFont;

    public string menuState = "main";

    private List<OnlineMessage> downloadedMessages;
    private List<DownloadedTexure> downloadedTextures;

    private Vector2 scroll;

    [MenuItem("Magnus/Online Islemler/CevrimIciMesaj")]
    public static void ShowWindow()
    {
        OnlineMessageWindow window = (OnlineMessageWindow)EditorWindow.GetWindow(typeof(OnlineMessageWindow));
        window.minSize = new Vector2(400, 400);
    }

    private void OnEnable()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();

        currentYear = DateTime.Now.Year;
        currentMonth = DateTime.Now.Month;
        currentDay = DateTime.Now.Day;
        silinecegiTarih = new DateTime(currentYear, currentMonth, currentDay).AddDays(3);

        messagePhoto = null;
        messagePhotoExt = null;
        menuState = "main";

        downloadedMessages = new();
        downloadedTextures = new();
    }

    private void OnGUI()
    {
        h1 = new GUIStyle("label");
        h1.fontSize = 40;
        h1.fontStyle = FontStyle.Bold;

        h2 = new GUIStyle("label");
        h2.fontSize = 30;
        h2.fontStyle = FontStyle.Bold;

        h3 = new GUIStyle("label");
        h3.fontSize = 20;
        h3.fontStyle = FontStyle.Bold;

        h4 = new GUIStyle("label");
        h4.fontSize = 14;
        h4.fontStyle = FontStyle.Bold;

        boldFont = new GUIStyle("label");
        boldFont.fontSize = 11;
        boldFont.fontStyle = FontStyle.Bold;

        EditorStyles.textField.wordWrap = true;
        EditorStyles.label.wordWrap = true;
        EditorStyles.label.alignment = TextAnchor.MiddleLeft;

        scroll = EditorGUILayout.BeginScrollView(scroll);

        if (EditorApplication.isPlaying)
        {
            switch (menuState)
            {
                case "main":
                    DrawMainMenu();
                    break;
                case "write":
                    DrawWriteMessageMenu();
                    break;
                default:
                    DrawMainMenu();
                    break;
            }
        }
        else
        {
            EditorGUILayout.HelpBox("Bu paneli kullabilmek icin uygulamayi baslatmalisiniz!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();
            }
        }

        EditorGUILayout.EndScrollView();
    }

    private void DrawMainMenu()
    {
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("Mesay Yaz", GUILayout.Height(60)))
        {
            menuState = "write";
        }
        if (GUILayout.Button("Yenile", GUILayout.Width(60), GUILayout.Height(60)))
        {
            GetOnlineSystemMessages();
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.LabelField("Mevcut mesajlar", h3);

        EditorGUILayout.Space(15);
        foreach (OnlineMessage onlineMessage in downloadedMessages)
        {
            DrawLine(2);
            EditorGUILayout.Space(10);

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, true);
            if (GUILayout.Button("Sil", GUILayout.Width(30), GUILayout.Height(30)))
            {
                DeleteMessage(onlineMessage.iD, onlineMessage.extension);
                GetOnlineSystemMessages();
                return;
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            DownloadedTexure downloadedTexure = downloadedTextures.Find(x => x.id.Equals(onlineMessage.iD + onlineMessage.extension));
            Texture2D texture = null;

            if (downloadedTexure != null)
                texture = downloadedTexure.texture;

            if (texture != null)
                GUILayout.Label(texture, GUILayout.Width(40), GUILayout.Height(40));
            EditorGUILayout.LabelField("ID: ", boldFont, GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField(onlineMessage.iD, GUILayout.ExpandWidth(false));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Başlık: ", h4, GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField(onlineMessage.title, GUILayout.ExpandWidth(false));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Mesaj: ", h4, GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField(onlineMessage.message, GUILayout.ExpandWidth(false));
            EditorGUILayout.EndHorizontal();

            DateTime date = Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(onlineMessage.destroyDate * 1000);
            string difference = ((date - DateTime.Now).TotalDays > 1) ? ((int)(date - DateTime.Now).TotalDays).ToString() + " gün" : ((int)(date - DateTime.Now).TotalHours).ToString() + " saat";
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Son Aktif Tarih: ", h4, GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField(date.ToString() + " | " + difference, GUILayout.ExpandWidth(false));
            EditorGUILayout.EndHorizontal();
        }

        EditorStyles.label.alignment = TextAnchor.UpperLeft;
    }

    private void DrawWriteMessageMenu()
    {
        if (GUILayout.Button("Geri"))
        {
            menuState = "main";
        }

        Rect rect = EditorGUILayout.BeginHorizontal();

        if (messagePhoto != null)
        {
            EditorGUILayout.BeginVertical();
            GUILayout.Label(messagePhoto, GUILayout.Width(60), GUILayout.Height(60));
            if (GUILayout.Button("Değiştir", GUILayout.Width(60)))
            {
                MessagePhotoPath = EditorUtility.OpenFilePanel("Forograf Sec", "", "png,jpg,jpeg");
                messagePhotoExt = Path.GetExtension(MessagePhotoPath);
            }
            EditorGUILayout.EndVertical();
        }
        else
        {
            if (GUILayout.Button("Fotoğraf\nSeç", GUILayout.Width(60), GUILayout.Height(60)))
            {
                MessagePhotoPath = EditorUtility.OpenFilePanel("Forograf Sec", "", "png,jpg,jpeg");
                messagePhotoExt = Path.GetExtension(MessagePhotoPath);
            }
        }

        EditorGUILayout.BeginVertical();
        EditorGUILayout.LabelField("Başlık");
        baslik = EditorGUILayout.TextArea(baslik, GUILayout.Height(35));
        EditorGUILayout.EndVertical();

        EditorGUILayout.EndHorizontal();
        GUI.Box(rect, GUIContent.none);

        GUILayout.Space(10);

        EditorGUILayout.LabelField("Açıklama");
        aciklama = EditorGUILayout.TextArea(aciklama, GUILayout.Height(200));

        EditorGUILayout.LabelField($"Silineceği Tarih ({silinecegiTarih.Day}/{silinecegiTarih.Month}/{silinecegiTarih.Year})", h3, GUILayout.Height(30));


        EditorGUILayout.BeginHorizontal();

        EditorGUILayout.Space(100, true);

        EditorGUILayout.BeginVertical();

        EditorGUILayout.LabelField(currentYear.ToString() + " " + new DateTime(currentYear, currentMonth, currentDay).ToString("MMMM", CultureInfo.CurrentCulture), h4, GUILayout.Height(30));
        EditorGUILayout.BeginHorizontal();

        bool isCurrentMonth = currentYear > DateTime.Now.Year || (currentYear == DateTime.Now.Year && currentMonth > DateTime.Now.Month);
        if (isCurrentMonth)
        {
            if (GUILayout.Button("<", GUILayout.Width(105)))
            {
                currentMonth--;

                if (currentMonth < 1)
                {
                    currentYear--;
                    currentMonth = 12;
                }

                if (currentMonth == DateTime.Now.Month && currentYear == DateTime.Now.Year)
                {
                    currentDay = DateTime.Now.Day;
                }
                else
                {
                    currentDay = 1;
                }
                Repaint();
            }
        }
        if (GUILayout.Button(">", GUILayout.Width(isCurrentMonth ? 105 : 200)))
        {
            currentMonth++;

            if (currentMonth > 12)
            {
                currentYear++;
                currentMonth = 1;
            }

            if (currentMonth == DateTime.Now.Month && currentYear == DateTime.Now.Year)
            {
                currentDay = DateTime.Now.Day;
            }
            else
            {
                currentDay = 1;
            }
            Repaint();
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();

        int totalDayCount = DateTime.DaysInMonth(currentYear, currentMonth) - currentDay;
        int thisLineCount = 0;
        for (int i = 1; i <= totalDayCount; i++)
        {
            if (GUILayout.Button((i + currentDay).ToString(), GUILayout.Width(40), GUILayout.Height(40)))
            {
                silinecegiTarih = new DateTime(currentYear, currentMonth, i + currentDay);
            }

            thisLineCount++;
            if (thisLineCount >= 5)
            {
                thisLineCount = 0;
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.BeginHorizontal();
            }
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.EndVertical();

        EditorGUILayout.Space(100, true);

        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(10);
        if (GUILayout.Button("Mesaji Paylaş", GUILayout.Height(30)))
        {
            OnlineMessage message = new OnlineMessage(baslik, aciklama, Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(silinecegiTarih), messagePhotoExt);

            string jsonData = JsonConvert.SerializeObject(message);

            if (messagePhoto == null)
            {
                Debug.LogError("Fotograf secimi yapmalisiniz");
                return;
            }

            if (new FileInfo(MessagePhotoPath).Length / (long)1024 > 200)
            {
                Debug.LogError("Online mesajlar icin maksimum fotograf boyutu 200 KB'dir. Tavsiye edilen fotograf cozunurlukleri ise 64x64 veya 128x128'dir!");
                return;
            }

            if (string.IsNullOrEmpty(baslik))
            {
                Debug.LogError("Baslik bos birakilamaz");
                return;
            }

            if (string.IsNullOrEmpty(aciklama))
            {
                Debug.LogError("Aciklama bos birakilamaz");
                return;
            }



            realtimeDatabaseManager.SetData("SystemMessages/" + message.iD, jsonData, () => {
                Debug.Log("<b><color=green>Basarili: </color></b> Mesaj basariyla sunucuya gonderildi.");
                UploadImage(message);
            }, (reason) => {
                Debug.LogError("<b><color=green>Hata: </color></b> Mesaj gonderilirken bir hata meydana geldi!");
            });

            menuState = "main";
            Repaint();
        }
    }

    private void GetOnlineSystemMessages()
    {
        downloadedTextures = new();
        downloadedMessages = new List<OnlineMessage>();
        RealtimeDatabaseManager realtimeDatabase = FindObjectOfType<RealtimeDatabaseManager>();

        realtimeDatabase.reference.Child("SystemMessages").GetValueAsync().ContinueWithOnMainThread((task) =>
        {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> childrenDatas = snapshot.Children.ToList();

                foreach (DataSnapshot child in childrenDatas)
                {
                    string jsonValue = child.GetRawJsonValue();
                    OnlineMessage onlineMessage = JsonConvert.DeserializeObject<OnlineMessage>(jsonValue);
                    downloadedMessages.Add(onlineMessage);
                    DownloadImageFile(onlineMessage.iD + onlineMessage.extension);
                }

                Repaint();
            }
        });
    }

    public void DownloadImageFile(string fileName)
    {
        string localUrl = Application.persistentDataPath + "/SystemMessages/" + fileName;
        if (!Directory.Exists(Application.persistentDataPath + "/SystemMessages"))
            Directory.CreateDirectory(Application.persistentDataPath + "/SystemMessages");

        if (!File.Exists(localUrl))
        {

            var storage = FirebaseStorage.DefaultInstance;

            // Create a storage reference from our storage service
            StorageReference storageRef =
                storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

            // Create a reference to the file you want to upload
            StorageReference riversRef = storageRef.Child("SystemMessages/" + fileName);

            // Start downloading a file
            Task task = riversRef.GetFileAsync(localUrl,
                new StorageProgress<DownloadState>(state =>
                {
                    // called periodically during the download
                    Debug.Log(System.String.Format(
                                    "Progress: {0} of {1} bytes transferred.",
                                    state.BytesTransferred,
                                    state.TotalByteCount
                                ));
                }), CancellationToken.None);

            task.ContinueWithOnMainThread(resultTask =>
            {
                if (!resultTask.IsFaulted && !resultTask.IsCanceled)
                {
                    Debug.Log("Download finished.");
                    Texture2D tex = new Texture2D(2, 2);
                    tex.LoadImage(File.ReadAllBytes(localUrl));
                    downloadedTextures.Add(new DownloadedTexure(tex , fileName));
                    Repaint();
                }
                else
                {
                    Debug.LogError("Aranan fotograf database'de bulunamadi veya" +
                        " bir hata meydana geldi!");
                }
            });
        }
        else
        {
            Texture2D tex = new Texture2D(2, 2);
            tex.LoadImage(File.ReadAllBytes(localUrl));
            downloadedTextures.Add(new DownloadedTexure(tex, fileName));
            Repaint();
        }
    }

    private void DeleteMessage(string id, string ext)
    {
        RealtimeDatabaseManager realtimeDatabase = FindObjectOfType<RealtimeDatabaseManager>();

        if (File.Exists(Application.persistentDataPath + "/SystemMessages/" + id + ext))
            File.Delete(Application.persistentDataPath + "/SystemMessages/" + id + ext);

        realtimeDatabase.reference.Child("SystemMessages/" + id).RemoveValueAsync();
    }

    public void UploadImage(OnlineMessage message)
    {
        var storage = FirebaseStorage.DefaultInstance;
        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // Create a reference to the file you want to upload
        StorageReference riversRef = storageRef.Child("SystemMessages/" + message.iD + message.extension);

        if (!string.IsNullOrEmpty(MessagePhotoPath))
        {
            // Upload the file to the path "images/rivers.jpg"
            riversRef.PutFileAsync(MessagePhotoPath)
                .ContinueWithOnMainThread((Task<StorageMetadata> task) =>
                {
                    if (task.IsFaulted || task.IsCanceled)
                    {
                        Debug.Log(task.Exception.ToString());
                        // Uh-oh, an error occurred!
                    }
                    else
                    {
                        // Metadata contains file metadata such as size, content-type, and download URL.
                        StorageMetadata metadata = task.Result;
                        string md5Hash = metadata.Md5Hash;
                        Debug.Log("Finished uploading...");
                        Debug.Log("md5 hash = " + md5Hash);
                    }
                });
        }
        else
        {
            Debug.Log("Path is null");
        }
    }

    private void DrawLine(int height)
    {
        Rect rect = EditorGUILayout.GetControlRect(false, height);

        rect.height = height;

        EditorGUI.DrawRect(rect, new Color(0.5f, 0.5f, 0.5f, 1));
    }

    [System.Serializable]
    public class OnlineMessage
    {
        public string title;
        public string message;
        public string iD;
        public string extension;
        public long destroyDate;

        public OnlineMessage()
        {
            title = string.Empty;
            message = string.Empty;
            iD = CreateID();
            destroyDate = 0;
            extension = string.Empty;
        }

        public OnlineMessage(string title, string message, long destroyDate, string extension)
        {
            this.title = title;
            this.message = message;
            iD = CreateID();
            this.destroyDate = destroyDate;
            this.extension = extension;
        }

        string CreateID()
        {
            string characters = "acbdefhijklmnzxvwq123456789";

            string iD = string.Empty;

            for(int i = 0; i < 8; i++)
            {
                iD += characters[UnityEngine.Random.Range(0, characters.Length)];
            }
            return iD;
        }
    }

    public class DownloadedTexure
    {
        public Texture2D texture;
        public string id;

        public DownloadedTexure()
        {
            texture = new Texture2D(32, 32);
            id = string.Empty;
        }

        public DownloadedTexure(Texture2D texture, string id)
        {
            this.texture = texture;
            this.id = id;
        }
    }
}
