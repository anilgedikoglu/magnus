using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using Firebase.Extensions;
using Firebase.Storage;
using NUnit.Framework;
using System.Threading.Tasks;
using System.Threading;
using Firebase.Database;
using Newtonsoft.Json;
using System.Linq;

[CustomEditor(typeof(PhotoSettings)), CanEditMultipleObjects]
public class PhotoSettingsEditor : Editor
{
    PhotoSettings targetObject;

    AuthenticationManager authenticationManager;
    string email, password;

    static int columCount = 3;

    FirebaseStorage storage;

    List<DownloadedStorageImage> downloadedImages;

    Texture2D lineTexture;

    int page;
    int pageElementCount;

    string error;

    private void OnEnable()
    {
        page = 0;
        pageElementCount = 4;
        error = string.Empty;

        if (target != null)
        {
            targetObject = (PhotoSettings)target;
            EditorUtility.SetDirty(targetObject);

            authenticationManager = FindObjectOfType<AuthenticationManager>();
        }

        storage = FirebaseStorage.DefaultInstance;

        CheckFirebaseStorageImages();
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Local fotoğrafları güncelle"))
        {
            Sprite[] sprites = Resources.LoadAll<Sprite>($"{ModSohbetManagerData.localDatabaseName}/Gorseller");

            for (int i = 0; i < sprites.Length; i++)
            {
                for (int u = 0; u < targetObject.localSprites.Count; u++)
                {
                    if (targetObject.localSprites[u].sprite != sprites[i])
                    {
                        if (u == targetObject.localSprites.Count - 1)
                        {
                            targetObject.localSprites.Add(new PhotoSettings.LocalSprite(sprites[i]));
                        }
                    }
                    else
                    {
                        break;
                    }
                }
            }

            List<int> deletedItems = new List<int>();
            for (int u = 0; u < targetObject.localSprites.Count; u++)
            {
                for (int i = 0; i < sprites.Length; i++)
                {
                    if (targetObject.localSprites[u].sprite == sprites[i])
                    {
                        break;
                    }
                    else if (i == sprites.Length - 1)
                    {
                        deletedItems.Add(u);
                    }
                }
            }

            foreach (int item in deletedItems)
            {
                targetObject.localSprites.RemoveAt(item);
            }

            EditorUtility.SetDirty(targetObject);
        }

        GUILayout.Space(10);

        if (authenticationManager.auth != null)
        {
            if (authenticationManager.auth.CurrentUser != null)
            {
                EditorGUILayout.LabelField("Mevcut oturum:");

                GUIStyle userNameHeader = new GUIStyle("label");
                userNameHeader.fontSize = 17;
                userNameHeader.fontStyle = FontStyle.Bold;
                userNameHeader.alignment = TextAnchor.UpperLeft;
                EditorGUILayout.LabelField(authenticationManager.auth.CurrentUser.Email, userNameHeader, GUILayout.Height(22));
                if (GUILayout.Button("Oturumu kapat"))
                {
                    LogOutFirebase();
                }
                GUILayout.Space(20);

                if (!string.IsNullOrEmpty(error))
                {
                    EditorGUILayout.HelpBox(error, MessageType.Error);
                    GUILayout.Space(20);
                }

                EditorGUILayout.BeginHorizontal();
                if (GUILayout.Button("Dosya seç", GUILayout.Height(50), GUILayout.ExpandWidth(true)))
                {
                    UploadFile();
                }
                if (GUILayout.Button("Yenile", GUILayout.Height(50), GUILayout.ExpandWidth(false)))
                {
                    CheckFirebaseStorageImages();
                    error = string.Empty;
                }
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
              
                if (GUILayout.Button("<", GUILayout.Width(100)))
                {
                    if (page > 0)
                        page -= 1;
                }
                GUIStyle pageLabelStyle = new GUIStyle("label");
                pageLabelStyle.fontSize = 12;
                pageLabelStyle.fontStyle = FontStyle.Bold;
                pageLabelStyle.alignment = TextAnchor.MiddleCenter;
                EditorGUILayout.LabelField($"{Mathf.Clamp((page + 1) * pageElementCount, 0, downloadedImages.Count)}/{downloadedImages.Count}", pageLabelStyle, GUILayout.ExpandWidth(true));
                if (GUILayout.Button(">", GUILayout.Width(100)))
                {
                    if (page < (downloadedImages.Count / pageElementCount))
                        page += 1;
                }
                EditorGUILayout.EndHorizontal();

                if (downloadedImages.Count > 0)
                {
                    int imageWidth = 150;
                    int index = page * pageElementCount;
                    for (int i = 0; i < (pageElementCount / (columCount)) + 1; i++)
                    {
                        EditorGUILayout.BeginHorizontal();
                        while (index < (columCount) * (i + 1) + page * pageElementCount)
                        {
                            if (index < downloadedImages.Count && index < (page + 1) * pageElementCount)
                            {
                                EditorGUILayout.BeginVertical();

                                GUIStyle nameLabelStyle = new GUIStyle("label");
                                nameLabelStyle.fontSize = 15;
                                nameLabelStyle.fontStyle = FontStyle.Bold;
                                nameLabelStyle.alignment = TextAnchor.MiddleCenter;

                                EditorGUILayout.LabelField(downloadedImages[index].name, nameLabelStyle, GUILayout.Width(imageWidth));

                                EditorGUI.DrawRect(EditorGUILayout.GetControlRect(false, 1), new Color(0.5f, 0.5f, 0.5f, 1));

                                EditorGUILayout.BeginHorizontal();

                                if (GUILayout.Button("Dosyayi ac", GUILayout.Width(120)))
                                {
                                    Application.OpenURL(Application.persistentDataPath + "/FirebaseStorage/Images/" + downloadedImages[index].name + downloadedImages[index].extension);
                                }

                                if (GUILayout.Button("Sil", GUILayout.Width(30)))
                                {
                                    DeleteFile(downloadedImages[index].name, downloadedImages[index].extension);
                                }

                                EditorGUILayout.EndHorizontal();

                                GUILayout.Label(downloadedImages[index].texture, nameLabelStyle, GUILayout.Width(imageWidth), GUILayout.Height(imageWidth));

                                if (GUILayout.Button("Kopyala", GUILayout.Width(imageWidth)))
                                {
                                    TextEditor te = new TextEditor();
                                    te.text = downloadedImages[index].name + downloadedImages[index].extension;
                                    te.SelectAll();
                                    te.Copy();
                                }
                                EditorGUI.DrawRect(EditorGUILayout.GetControlRect(false, 1), new Color(0.5f, 0.5f, 0.5f, 1));
                                EditorGUILayout.BeginHorizontal();

                                EditorGUILayout.EndHorizontal();

                                EditorGUILayout.EndVertical();
                            }
                            index += 1;
                        }
                        EditorGUILayout.EndHorizontal();
                        GUILayout.Space(20);
                    }
                }

                pageElementCount = EditorGUILayout.IntSlider("Her Sayfadaki Fotoğraf: ", pageElementCount, 3, 20);
                columCount = EditorGUILayout.IntSlider("Her Satırdaki Fotoğraf: ", columCount, 1, 10);

                EditorGUILayout.HelpBox("Online veritabanındaki fotoğraflar daha sonra gösterilmek üzere yerel olarak belirli süreli saklanır. Eğer fotoğraflar bir nedenden" +
                    " bilgisayarınıza doğru bir şekilde indirilemediyse, görünmüyorsa veya başka bir hata meydana geldiyse yerel dosyaları temizleyip indirme işlemini" +
                    " tekrar başlatabilirsiniz.", MessageType.Info);
                if (GUILayout.Button("Yenilemeye zorla"))
                {
                    DeleteCache();
                    CheckFirebaseStorageImages();
                    error = string.Empty;
                }
            }
            else
            {
                EditorGUILayout.LabelField("Online veritabanına fotoğraf yüklemek için giriş yapın.");

                email = EditorGUILayout.TextField("E-mail", email);
                password = EditorGUILayout.TextField("Şifre", password);

                if (!string.IsNullOrEmpty(email) && !string.IsNullOrEmpty(password))
                {
                    if (GUILayout.Button("Giris"))
                    {
                        LoginFirebase(email, password);
                    }
                }
            }
        }
        else
        {
            EditorGUILayout.LabelField("Online veritabanına fotoğraf yüklemek için giriş yapın.");

            email = EditorGUILayout.TextField("E-mail", email);
            password = EditorGUILayout.TextField("Şifre", password);

            if (!string.IsNullOrEmpty(email) && !string.IsNullOrEmpty(password))
            {
                if (GUILayout.Button("Giris"))
                {
                    LoginFirebase(email, password);
                }
            }
        }
    }

    public async void LoginFirebase(string email, string password)
    {
        authenticationManager.auth = Firebase.Auth.FirebaseAuth.DefaultInstance;
        await authenticationManager.auth.SignInWithEmailAndPasswordAsync(email, password).ContinueWithOnMainThread(task =>
         {
             if (task.IsCanceled)
             {
                 Debug.LogError("SignInWithEmailAndPasswordAsync was canceled.");
                 return;
             }
             if (task.IsFaulted)
             {
                 Debug.LogError("SignInWithEmailAndPasswordAsync encountered an error: " + task.Exception);
                 return;
             }

             Firebase.Auth.FirebaseUser newUser = task.Result;
             Debug.LogFormat("User signed in successfully: {0} ({1})",
                 newUser.DisplayName, newUser.UserId);

             CheckFirebaseStorageImages();
         });
    }

    public void LogOutFirebase()
    {
        authenticationManager.auth.SignOut();
        downloadedImages = new List<DownloadedStorageImage>();
    }

    public void UploadFile()
    {
        storage = FirebaseStorage.DefaultInstance;
        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // File located on disk
        string localFile = EditorUtility.OpenFilePanel("Yüklenecek dosya", "", "png,jpg,jpeg");

        string fileName = Path.GetFileNameWithoutExtension(localFile);
        char[] fileNameChar = fileName.ToCharArray();

        fileName = string.Empty;
        foreach (char letter in fileNameChar)
        {
            if (char.IsLetterOrDigit(letter))
                fileName += letter;
        }

        foreach(DownloadedStorageImage image in downloadedImages)
        {
            if (image.name == fileName)
            {
                error = "Daha önce bu isimle bir dosya kaydedildi. Dosya isimleri her dosya için benzersiz olmalı!";
                Debug.LogError(error);
                return;
            }
        }

        error = string.Empty;

        string fileExtension = Path.GetExtension(localFile);

        Debug.Log("FirebaseStorage/Images" + fileName);

        // Create a reference to the file you want to upload
        StorageReference riversRef = storageRef.Child("Images/" + fileName + fileExtension);

        if (!string.IsNullOrEmpty(localFile))
        {
            // Upload the file to the path "images/rivers.jpg"
            riversRef.PutFileAsync(localFile)
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

                        metadata.Reference.GetDownloadUrlAsync().ContinueWithOnMainThread(taskGetUrl =>
                        {
                            SaveStorageImageUrl(fileName, fileExtension, taskGetUrl.Result.ToString());
                        });
                    }
                });
        }
        else
        {
            Debug.Log("Path is null");
        }
    }

    public void DownloadFile(string fileName, string extension)
    {
        storage = FirebaseStorage.DefaultInstance;

        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // Create a reference to the file you want to upload
        StorageReference riversRef = storageRef.Child("Images/" + fileName + extension);

        // Create local filesystem URL
        string localUrl = Application.persistentDataPath + "/FirebaseStorage/Images/" + fileName + extension;

        // Start downloading a file
        Task task = riversRef.GetFileAsync(localUrl,
            new StorageProgress<DownloadState>(state => {
                // called periodically during the download
                Debug.Log(System.String.Format(
                            "Progress: {0} of {1} bytes transferred.",
                            state.BytesTransferred,
                            state.TotalByteCount
                        ));
            }), CancellationToken.None);

        task.ContinueWithOnMainThread(resultTask => {
            if (!resultTask.IsFaulted && !resultTask.IsCanceled)
            {
                Debug.Log("Download finished.");
                UpdateFirebaseStorageImagesFromLocalFolder();
            }
        });
    }

    public void DeleteFile(string fileName, string extension)
    {
        storage = FirebaseStorage.DefaultInstance;

        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // Create a reference to the file you want to upload
        StorageReference riversRef = storageRef.Child("Images/" + fileName + extension);

        // Create local filesystem URL
        string localUrl = Application.persistentDataPath + "/FirebaseStorage/Images/" + fileName + extension;

        Debug.Log("delete basladi");
        // Start downloading a file
        Task task = riversRef.DeleteAsync();

        task.ContinueWithOnMainThread(resultTask => {
            if (!resultTask.IsFaulted && !resultTask.IsCanceled)
            {
                Debug.Log("Delete file is finished with success.");
                DeleteStorageImageUrl(fileName);
            }
            else
            {
                Debug.Log(task.Exception);
            }
        });
    }

    public void SaveStorageImageUrl(string fileName, string extension, string url)
    {
        DatabaseReference reference = FirebaseDatabase.DefaultInstance.RootReference;
        Debug.Log(url);
        reference.Child("FirebaseStorage/Images/" + fileName).SetRawJsonValueAsync(JsonConvert.SerializeObject(new FirebaseStorageImage(fileName, extension, url))).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                Debug.Log(fileName);
                Debug.Log(task.Exception.ToString());
                return;
            }

            Debug.Log("Firebase veritabanina yazma islemi basarili");
            CheckFirebaseStorageImages();
        });
    }

    public void DeleteStorageImageUrl(string fileName)
    {
        DatabaseReference reference = FirebaseDatabase.DefaultInstance.RootReference;
        reference.Child("FirebaseStorage/Images/" + fileName).RemoveValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                Debug.Log(fileName);
                Debug.Log(task.Exception.ToString());
                return;
            }

            Debug.Log("Firebase veritabanina yazma islemi basarili");
            CheckFirebaseStorageImages();
        });
    }

    public void CheckFirebaseStorageImages()
    {
        downloadedImages = new List<DownloadedStorageImage>();

        Debug.Log("Image sorgulaniyor: ");

        FirebaseDatabase.DefaultInstance
    .GetReference("FirebaseStorage/Images")
    .GetValueAsync().ContinueWithOnMainThread(task =>
    {
        if (task.IsFaulted || task.IsCanceled)
        {
            Debug.Log("hata");
            // Handle the error...
        }
        else if (task.IsCompleted)
        {
            DataSnapshot snapshot = task.Result;

            List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

            List<string> existingFiles = new List<string>();
            for (int i = 0; i < snapshotChilds.Count; i++)
            {
                FirebaseStorageImage firebaseStorageImage = JsonConvert.DeserializeObject<FirebaseStorageImage>(snapshotChilds[i].GetRawJsonValue());
                existingFiles.Add(firebaseStorageImage.name + firebaseStorageImage.extension);
                IsStorageImageExistInFolder(firebaseStorageImage);
                Debug.Log(snapshotChilds[i].GetRawJsonValue());
            }

            foreach (string file in System.IO.Directory.GetFiles(Application.persistentDataPath + "/FirebaseStorage/Images"))
            {
                if (!existingFiles.Contains(Path.GetFileName(file)))
                {
                    File.Delete(file);
                }
                else
                {
                    Debug.Log(Path.GetFileName(file) + " yerel yedekte mevcut olduğu için indirilmedi");
                }
            }

            UpdateFirebaseStorageImagesFromLocalFolder();

            Debug.Log(snapshot.GetRawJsonValue());
            //Debug.Log(snapshot.);
        }
    });
    }

    void UpdateFirebaseStorageImagesFromLocalFolder()
    {
        if (!File.Exists(Application.persistentDataPath + "/FirebaseStorage/Images"))
        {
            Directory.CreateDirectory(Application.persistentDataPath + "/FirebaseStorage/Images");
        }

        downloadedImages = new List<DownloadedStorageImage>();
        foreach (string file in System.IO.Directory.GetFiles(Application.persistentDataPath + "/FirebaseStorage/Images"))
        {
            downloadedImages.Add(new DownloadedStorageImage(Path.GetFileNameWithoutExtension(file), Path.GetExtension(file), file, LoadPNG(file)));
        }
        Repaint();
    }

    public void IsStorageImageExistInFolder(FirebaseStorageImage image)
    {
        Debug.Log("Image sorgulaniyor: " + image.name);
        if (!File.Exists(Application.persistentDataPath + "/FirebaseStorage/Images/" + image.name + image.extension))
        {
            Debug.Log("Image yerel dosya olarak bulunmadigi için indiriliyor: " + image.name);
            DownloadFile(image.name, image.extension);
        }
    }

    public void DeleteCache()
    {
        foreach(DownloadedStorageImage image in downloadedImages)
        {
            File.Delete(Application.persistentDataPath + "/FirebaseStorage/Images/" + image.name + image.extension);
        }
    }

    [System.Serializable]
    public class DownloadedStorageImage
    {
        public string name;
        public string extension;
        public string path;
        public Texture2D texture;

        public DownloadedStorageImage(string name, string extension, string path, Texture2D texture)
        {
            this.name = name;
            this.extension = extension;
            this.path = path;
            this.texture = texture;
        }
    }

    [System.Serializable]
    public class FirebaseStorageImage
    {
        public string name;
        public string extension;
        public string url;

        public FirebaseStorageImage(string name, string extension, string url)
        {
            this.name = name;
            this.extension = extension;
            this.url = url;
        }
    }

    public static Texture2D LoadPNG(string filePath)
    {

        Texture2D tex = null;
        byte[] fileData;

        if (File.Exists(filePath))
        {
            fileData = File.ReadAllBytes(filePath);
            tex = new Texture2D(2, 2);
            tex.LoadImage(fileData); //..this will auto-resize the texture dimensions.
        }
        return tex;
    }
}
