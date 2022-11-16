using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Firebase.Extensions;
using Newtonsoft.Json;
using Firebase.Database;
using System.Linq;

[CustomEditor(typeof(GeneralUserOperations))]
public class GeneralUserOperationsEditor : Editor
{
    public AuthenticationManager authenticationManager;
    public RealtimeDatabaseManager realtimeDatabaseManager;
    public DatabaseReference reference;

    GeneralUserOperations generalUserOperations;

    public PlayerData playerData;
    public enum PlayerDataSettingType
    {
        plus1Ay,
        plus3Ay,
        plus1Yil,
        energy,
        kons,
    }
    public PlayerDataSettingType playerDataSettingType;

    public string email, password, userId;

    public GeneralUserOperations.Admin atanacakAdmin;

    public string closedMod, deleteClosedMod;
    public string plusMod, deletePlusMod;

    int verilecekEnerji, verilecekKonsantrasyon;

    string versionToAdd;
    List<string> versions;

    private string menuState;

    GUIStyle h1, h2, h3, h4, descreption;

    public delegate void onFirebaseSaveSuccess();
    public delegate void onFirebaseRecieveSuccess();

    private void OnEnable()
    {
        reference = FirebaseDatabase.DefaultInstance.RootReference;
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        generalUserOperations = (GeneralUserOperations)target;
        atanacakAdmin = new();
        menuState = "main";
    }

    public override void OnInspectorGUI()
    {
        h1 = new GUIStyle("label");
        h1.fontSize = 27;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        h2 = new GUIStyle("label");
        h2.fontSize = 23;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        h3 = new GUIStyle("label");
        h3.fontSize = 18;
        h3.fontStyle = FontStyle.Bold;
        h3.wordWrap = true;

        h4 = new GUIStyle("label");
        h4.fontSize = 15;
        h4.fontStyle = FontStyle.Bold;
        h4.wordWrap = true;

        descreption = new GUIStyle("label");
        descreption.fontSize = 12;
        descreption.fontStyle = FontStyle.Italic;
        descreption.wordWrap = true;

        if (authenticationManager.auth != null)
        {
            if (authenticationManager.auth.CurrentUser != null)
            {
                if (menuState == "main")
                {
                    DrawMainMenu();
                }
                else if (menuState == "version")
                {
                    DrawVerisonsMenu();
                }
                else if (menuState == "versionKontrol")
                {
                    DrawVerisonsMenuWarning();
                }
                else if (menuState == "modEngel")
                {
                    DrawModBanMenu();
                }
                else if (menuState == "plusAta")
                {
                    DrawSetPlusForUserMenu();
                }
                else if (menuState == "adminIslemleri")
                {
                    DrawSetAdminAccountMenu();
                }
            }
            else
            {
                email = EditorGUILayout.TextField("E-mail: ", email);
                password = EditorGUILayout.TextField("Şifre: ", password);

                if (GUILayout.Button("Giriş yap"))
                    LoginFirebase(email, password);
            }
        }
        else
        {
            email = EditorGUILayout.TextField("E-mail: ", email);
            password = EditorGUILayout.TextField("Şifre: ", password);

            if (GUILayout.Button("Giriş yap"))
                LoginFirebase(email, password);
        }
    }

    #region MENUS
    public void DrawMainMenu()
    {
        GUILayout.Label("Online İşlemler", h2);
        EditorGUILayout.Space(10);

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("1. Aktif Versiyonları Belirle", h4);
        GUILayout.Label("Uygulamanın hangi sürümler için aktif olarak kullanılabileceğini ayarla. Ayarlanan listenin dışındaki sürüm adına sahip olan tüm kullanıcıların" +
        " uygulamaya girmesi engellenir!", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("Aç", GUILayout.ExpandHeight(true)))
        {
            menuState = "version";
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("2. Modları Engelle", h4);
        GUILayout.Label("Listedeki modlar için, bu modlara yönlendiren seçenek butonlarını tamamen kapat veya sadece plus kullanıcılarına görünür yap.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "modEngel";
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("3. Kullanıcıya Enerji Ver", h4);
        GUILayout.Label("Belirlenen kullanıcı ID'si(28 haneli Firebase USER-ID) için enerji atamasında bulun.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "plusAta";
            playerDataSettingType = PlayerDataSettingType.energy;
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("4. Kullanıcıya Konsantrasyon Ver", h4);
        GUILayout.Label("Belirlenen kullanıcı ID'si(28 haneli Firebase USER-ID) için konsantrasyon atamasında bulun.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "plusAta";
            playerDataSettingType = PlayerDataSettingType.kons;
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("5. Kullanıcıya 1 Aylık Plus Ata", h4);
        GUILayout.Label("Belirlenen kullanıcı ID'si(28 haneli Firebase USER-ID) için 1 aylık plus sürüm atamasında bulun.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "plusAta";
            playerDataSettingType = PlayerDataSettingType.plus1Ay;
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("6. Kullanıcıya 3 Aylık Plus Ata", h4);
        GUILayout.Label("Belirlenen kullanıcı ID'si(28 haneli Firebase USER-ID) için 3 aylık plus sürüm atamasında bulun.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "plusAta";
            playerDataSettingType = PlayerDataSettingType.plus3Ay;
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("7. Kullanıcıya 1 Yıllık Plus Ata", h4);
        GUILayout.Label("Belirlenen kullanıcı ID'si(28 haneli Firebase USER-ID) için 1 yıllık plus sürüm atamasında bulun.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "plusAta";
            playerDataSettingType = PlayerDataSettingType.plus1Yil;
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();
        GUILayout.Label("8. Admin Ataması", h4);
        GUILayout.Label("Herhangi bir email ile magnusa giriş yapan kullanıcıyı admin olarak ata. Admin kullanıcılar kendileri ve diğer kullanıcılar üzerinde" +
            " birçok yetkiye sahip olurlar.", descreption);
        EditorGUILayout.EndVertical();

        if (GUILayout.Button("AÇ", GUILayout.ExpandHeight(true)))
        {
            menuState = "adminIslemleri";
            playerDataSettingType = PlayerDataSettingType.plus1Yil;
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(20);
    }


    public void DrawSetAdminAccountMenu()
    {
        GUILayout.Label("adminIslemleri", h1);

        GUILayout.Space(5);
        GUILayout.Label("Tüm adminler", h2);
        if (GUILayout.Button("Yenile"))
        {
            FirebaseDatabase.DefaultInstance
            .GetReference("Admins")
            .GetValueAsync().ContinueWithOnMainThread(task =>
            {
                if (task.IsFaulted || task.IsCanceled)
                {
                    Debug.LogError("Veriler alınırken hata meydana geldi");
                    // Handle the error...
                }
                else if (task.IsCompleted)
                {
                    generalUserOperations.admins = new();

                    DataSnapshot snapshot = task.Result;
                    List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                    if (snapshotChilds.Count > 0)
                    {
                        for (int i = 0; i < snapshotChilds.Count; i++)
                        {
                            generalUserOperations.admins.Add(JsonConvert.DeserializeObject<GeneralUserOperations.Admin>(snapshotChilds[i].GetRawJsonValue()));
                            Debug.Log(snapshotChilds[i].GetRawJsonValue());
                        }
                        Repaint();
                    }
                    else
                    {
                        Debug.Log(snapshot.Key + " tarihi için uygun inceleme bulunamadı");
                    }
                }
            });
        }

        GUILayout.Space(5);
        GUILayout.Label("Admin Ata", h2);

        if (generalUserOperations.admins != null)
        {
            foreach(GeneralUserOperations.Admin admin in generalUserOperations.admins)
            {
                GUILayout.Label(admin.name, h4);
                GUILayout.Label("Admin Adı: " + admin.name);
                GUILayout.Label("Email: " + admin.email);
                GUILayout.Label("Şifre: " + admin.password);
                GUILayout.Space(5);
            }
        }

        GUILayout.Space(5);
        atanacakAdmin.name = EditorGUILayout.TextField("Admin Adı: ", atanacakAdmin.name);
        atanacakAdmin.email = EditorGUILayout.TextField("Email: ", atanacakAdmin.email);
        atanacakAdmin.password = EditorGUILayout.TextField("Şifre: ", atanacakAdmin.password);
        if (GUILayout.Button("Admini Ata"))
        {
            realtimeDatabaseManager.SetData("Admins/" + atanacakAdmin.email.Replace("@", string.Empty).Replace(".", string.Empty), JsonConvert.SerializeObject(atanacakAdmin));
        }
    
    }

    public void DrawSetPlusForUserMenu()
    {
        if (GUILayout.Button("Ana menü"))
        {
            menuState = "main";
        }

        string saveButtonText = "Kaydet";

        if (playerDataSettingType == PlayerDataSettingType.plus1Ay)
        {
            GUILayout.Label("1 Ay Plus Ata", h1);
            saveButtonText = "1 ay Plus ver";
        }
        else if (playerDataSettingType == PlayerDataSettingType.plus1Ay)
        {
            GUILayout.Label("3 Ay Plus Ata", h1);
            saveButtonText = "3 ay Plus ver";
        }
        else if (playerDataSettingType == PlayerDataSettingType.plus1Yil)
        {
            GUILayout.Label("1 Yil Plus Ata", h1);
            saveButtonText = "1 yıl Plus ver";
        }
        else if (playerDataSettingType == PlayerDataSettingType.energy)
        {
            GUILayout.Label("Enerji Ata", h1);
            verilecekEnerji = EditorGUILayout.IntSlider(verilecekEnerji, 1, 200);
            saveButtonText = verilecekEnerji + " enerji ver";
        }
        else if (playerDataSettingType == PlayerDataSettingType.kons)
        {
            GUILayout.Label("Konsantrasyon Ata", h1);
            verilecekKonsantrasyon = EditorGUILayout.IntSlider(verilecekKonsantrasyon, 1, 200);
            saveButtonText = verilecekKonsantrasyon + " kontantrasyon ver";
        }


        userId = EditorGUILayout.TextField("User-ID: ", userId);
        if (GUILayout.Button("Plus Üyelik Ata"))
        {
            SetPlayerData();
            Debug.Log(JsonConvert.SerializeObject(playerData));
        }
    }

    public void DrawVerisonsMenu()
    {
        GUILayout.Label("Kullanılabilir sürümler", h1);

        foreach (string version in generalUserOperations.versions)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(version);
            if (GUILayout.Button("x", GUILayout.Width(20), GUILayout.Height(20)))
            {
                if (generalUserOperations.versions.Contains(version))
                {
                    generalUserOperations.versions.Remove(version);
                    break;
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        versionToAdd = EditorGUILayout.TextField("Eklenecek sürüm", versionToAdd);
        if (GUILayout.Button("Sürümü ekle", GUILayout.Height(20)))
        {
            if (!generalUserOperations.versions.Contains(versionToAdd))
            {
                generalUserOperations.versions.Add(versionToAdd);
            }
        }

        generalUserOperations.lastAndroidVersion = EditorGUILayout.TextField("Yayındaki güncel Android sürümü", generalUserOperations.lastAndroidVersion);
        generalUserOperations.lastIosVersion = EditorGUILayout.TextField("Yayındaki güncel IOS sürümü", generalUserOperations.lastIosVersion);

        EditorGUILayout.Space(10);
        GUILayout.Label("Sürüm Uyarı", h3);
        EditorGUILayout.Space(10);

        GUILayout.Label("Başlık", h4, GUILayout.ExpandWidth(false));
        generalUserOperations.surumEskiUyari.title = GUILayout.TextArea(generalUserOperations.surumEskiUyari.title, GUILayout.ExpandWidth(true));
        EditorGUILayout.Space(10);

        GUILayout.Label("Alt Başlık", h4, GUILayout.ExpandWidth(false));
        generalUserOperations.surumEskiUyari.subTitle = GUILayout.TextArea(generalUserOperations.surumEskiUyari.subTitle, GUILayout.ExpandWidth(true));
        EditorGUILayout.Space(10);

        GUILayout.Label("Açıklama", h4, GUILayout.ExpandWidth(false));
        generalUserOperations.surumEskiUyari.description = GUILayout.TextArea(generalUserOperations.surumEskiUyari.description, GUILayout.ExpandWidth(true));
        EditorGUILayout.Space(30);


        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Bakım", h3, GUILayout.ExpandWidth(false));
        generalUserOperations.bakim = EditorGUILayout.Toggle(generalUserOperations.bakim);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(10);
        GUILayout.Label("Bakım Uyarı", h3);
        EditorGUILayout.Space(10);

        GUILayout.Label("Başlık", h4, GUILayout.ExpandWidth(false));
        generalUserOperations.bakimUyari.title = GUILayout.TextArea(generalUserOperations.bakimUyari.title, GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
        EditorGUILayout.Space(10);

        GUILayout.Label("Alt Başlık", h4, GUILayout.ExpandWidth(false));
        generalUserOperations.bakimUyari.subTitle = GUILayout.TextArea(generalUserOperations.bakimUyari.subTitle, GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
        EditorGUILayout.Space(10);

        GUILayout.Label("Açıklama", h4, GUILayout.ExpandWidth(false));
        generalUserOperations.bakimUyari.description = GUILayout.TextArea(generalUserOperations.bakimUyari.description, GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
        EditorGUILayout.Space(10);

        EditorGUILayout.Space(20);
        if (GUILayout.Button("Vazgeç", GUILayout.Height(50)))
        {
            menuState = "main";
        }

        EditorGUILayout.Space(20);

        if (GUILayout.Button("Yayınla"))
        {
            menuState = "versionKontrol";
        }
    }

    public void DrawVerisonsMenuWarning()
    {
        GUILayout.Label("Kullanılabilir sürümler", h1);

        string versionInfoText = string.Empty;

        foreach (string version in generalUserOperations.versions)
        {
            versionInfoText += "\n" + version + " ";
        }

        EditorGUILayout.HelpBox("Bu işlem mevcut kullanıcıların listedeki sürümler dışındaki sürümler ile uygulamaya girmesini tamamen engeller! \n\nİzin verilen sürümler: " + versionInfoText, MessageType.Warning);

        if(generalUserOperations.bakim)
            EditorGUILayout.HelpBox("Bu işlem onaylandıktan sonra uygulama tüm sürümlerde bakım moduna geçer. \n\nTÜM KULLANICLAR değişikliklerin yayınlanmasından" +
                " hemen sonraki yapacaklar ilk uygulamaya giriş denemesinden itibaren uygulamaya giremezler. \n\nBunun ne anlama geldiğini bilmiyorsanız lütfen devam etmeyin!", MessageType.Error);

        if (GUILayout.Button("Vazgeç", GUILayout.Height(50)))
        {
            generalUserOperations.versions = new List<string>(versions);
            menuState = "version";
        }

        GUILayout.Space(20);
        if (GUILayout.Button("Değişiklikleri online olarak yayınla!", GUILayout.Height(20)))
        {
            SaveDataToOnlineDatabase("Versions/Release", JsonConvert.SerializeObject(generalUserOperations.versions), () =>
            {
                Debug.Log("Firebase veritabanina yazma islemi basarili");
            });

            SaveDataToOnlineDatabase("Versions/LastAndroidVersion", JsonConvert.SerializeObject(generalUserOperations.lastAndroidVersion), () =>
            {
                Debug.Log("Firebase veritabanina yazma islemi basarili");
            });

            SaveDataToOnlineDatabase("Versions/LastIOSVersion", JsonConvert.SerializeObject(generalUserOperations.lastIosVersion), () =>
            {
                Debug.Log("Firebase veritabanina yazma islemi basarili");
            });

            SaveDataToOnlineDatabase("Bakim", JsonConvert.SerializeObject(generalUserOperations.bakim), () => {
                Debug.Log("Firebase veritabanina yazma islemi basarili");
            });

            versions = new List<string>(generalUserOperations.versions);
            menuState = "version";
        }
    }

    public void DrawModBanMenu()
    {
        if (GUILayout.Button("Ana menü"))
        {
            menuState = "main";
        }

        GUILayout.Label("Engellenen Modlar", h1);

        EditorGUILayout.Space(20);
        GUILayout.Label("Sadece Plus olmayan kullanıcılara kapalı olanlar", h3);

        GUILayout.Space(5);
        foreach (string element in generalUserOperations.plusMods)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(element);
            if (GUILayout.Button("x", GUILayout.Width(20), GUILayout.Height(20)))
            {
                plusMod = string.Empty;
                deletePlusMod = element;

                generalUserOperations.plusMods.Remove(deletePlusMod);
                EditorUtility.SetDirty(generalUserOperations);
                break;
            }
            EditorGUILayout.EndHorizontal();
        }

        plusMod = GUILayout.TextArea(plusMod);

        if (GUILayout.Button("Modu Ekle"))
        {
            if (!generalUserOperations.plusMods.Contains(plusMod))
            {
                generalUserOperations.plusMods.Add(plusMod);
                EditorUtility.SetDirty(generalUserOperations);
            }
            else
                Debug.LogError("Mod daha önce zaten bu işlemde kullanıldığı için tekrar eklenemiyor!");
        }


        EditorGUILayout.Space(50);
        GUILayout.Label("Tüm kullanıcılara kapalı olanlar", h3);

        GUILayout.Space(5);
        foreach (string element in generalUserOperations.closedMods)
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(element);
            if (GUILayout.Button("x", GUILayout.Width(20), GUILayout.Height(20)))
            {
                closedMod = string.Empty;
                deleteClosedMod = element;

                generalUserOperations.closedMods.Remove(deleteClosedMod);
                EditorUtility.SetDirty(generalUserOperations);
                break;
            }
            EditorGUILayout.EndHorizontal();
        }

        closedMod = GUILayout.TextArea(closedMod);

        if (GUILayout.Button("Modu Ekle"))
        {
            if (!generalUserOperations.closedMods.Contains(closedMod))
            {
                generalUserOperations.closedMods.Add(closedMod);
                EditorUtility.SetDirty(generalUserOperations);
            }
            else
                Debug.LogError("Mod daha önce zaten bu işlemde kullanıldığı için tekrar eklenemiyor!");
        }

        EditorGUILayout.Space(40);

        if (GUILayout.Button("Geri Dön", GUILayout.Height(50)))
        {
            menuState = "main";
        }

        EditorGUILayout.Space(10);

        if (GUILayout.Button("Kaydet", GUILayout.Height(20)))
        {
            SaveDataToOnlineDatabase("SohbetModlari/Plus", JsonConvert.SerializeObject(generalUserOperations.plusMods), () => {
                Debug.Log("Firebase veritabanina yazma islemi basarili");
            });

            SaveDataToOnlineDatabase("SohbetModlari/Kapali", JsonConvert.SerializeObject(generalUserOperations.closedMods), () => {
                Debug.Log("Firebase veritabanina yazma islemi basarili");
            });

            menuState = "main";
        }
    }
    #endregion

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
            GetVersionData();
            GetDataExceptedMod();
        });
    }

    public void SetPlayerData()
    {
        if (Application.internetReachability != NetworkReachability.NotReachable)
        {
            FirebaseDatabase.DefaultInstance
     .GetReference("Users/" + userId)
     .GetValueAsync().ContinueWithOnMainThread(task =>
     {
         if (task.IsFaulted || task.IsCanceled)
         {
             Debug.Log("hata: " + task.Exception);
             // Handle the error...
         }
         else if (task.IsCompleted)
         {
             DataSnapshot snapshot = task.Result;
             if (snapshot.GetRawJsonValue() != null)
             {
                 playerData = JsonConvert.DeserializeObject<PlayerData>(snapshot.GetRawJsonValue());

                 if (playerDataSettingType == PlayerDataSettingType.plus1Ay)
                 {
                     playerData.plusExpireDateFromSystem = new PlayerData.Date(System.DateTime.Now.AddMonths(1));
                 }
                 else if (playerDataSettingType == PlayerDataSettingType.plus3Ay)
                 {
                     playerData.plusExpireDateFromSystem = new PlayerData.Date(System.DateTime.Now.AddMonths(3));
                 }
                 else if (playerDataSettingType == PlayerDataSettingType.plus1Yil)
                 {
                     playerData.plusExpireDateFromSystem = new PlayerData.Date(System.DateTime.Now.AddYears(1));
                 }
                 else if (playerDataSettingType == PlayerDataSettingType.energy)
                 {
                     playerData.energy += verilecekEnerji;
                 }
                 else if (playerDataSettingType == PlayerDataSettingType.kons)
                 {
                     playerData.konsantrasyon += verilecekKonsantrasyon;
                 }

                 reference = FirebaseDatabase.DefaultInstance.RootReference;
                 reference.Child("Users/" + userId).SetRawJsonValueAsync(JsonConvert.SerializeObject(playerData)).ContinueWithOnMainThread(task =>
                 {
                     if (task.IsCanceled || task.IsFaulted)
                     {
                         Debug.Log(task.Exception.ToString());
                         return;
                     }

                     Debug.Log("Firebase veritabanina yazma islemi basarili");
                 });

                 Debug.Log("Bilgiler online veritabanından başarıyla alındı");
             }
             else
             {
                 playerData = new PlayerData();
                 Debug.Log("Bilgiler online veritabanında bulunamadığı için uygulama terminal ekranına yönlendiriliyor...");
             }
         }
     });
        }
        else
        {
            //FindObjectOfType<CurrentPlayerData>().onlineDataChecked = 1;
        }
    }

    public void GetDataExceptedMod()
    {
        if (Application.internetReachability != NetworkReachability.NotReachable)
        {
            FirebaseDatabase.DefaultInstance
     .GetReference("SohbetModlari/Kapali")
     .GetValueAsync().ContinueWithOnMainThread(task =>
     {
         if (task.IsFaulted || task.IsCanceled)
         {
             Debug.Log("hata: " + task.Exception);
             // Handle the error...
         }
         else if (task.IsCompleted)
         {
             Debug.Log("Bilgiler online veritabanından başarıyla alındı");
             DataSnapshot snapshot = task.Result;

             try
             {
                 generalUserOperations.closedMods = JsonConvert.DeserializeObject<List<string>>(snapshot.GetRawJsonValue());
             }
             catch
             {
                 generalUserOperations.closedMods = new List<string>();
             }
         }
     });

            FirebaseDatabase.DefaultInstance
    .GetReference("SohbetModlari/Plus")
    .GetValueAsync().ContinueWithOnMainThread(task =>
    {
        if (task.IsFaulted || task.IsCanceled)
        {
            Debug.Log("hata: " + task.Exception);
            // Handle the error...
        }
        else if (task.IsCompleted)
        {
            DataSnapshot snapshot = task.Result;
            try
            {
                generalUserOperations.plusMods = JsonConvert.DeserializeObject<List<string>>(snapshot.GetRawJsonValue());
            }
            catch
            {
                generalUserOperations.plusMods = new List<string>();
                Debug.LogWarning("Sistem yanıtı doğru formatta değil veya bilgiler online veritabanında mevcut değil!");
            }

            //Uygulama bakimda mi degil kontrolu
            FindObjectOfType<RealtimeDatabaseManager>().GetData("Bakim", (string rawJson) =>
            {
                if (rawJson != null)
                {
                    generalUserOperations.bakim = JsonConvert.DeserializeObject<bool>(rawJson);
                }
                else
                {
                    generalUserOperations.bakim = false;
                    Debug.Log("Bakım bilgisi veritabanında bulunamadı. Bu nedenle bakım yok sayılıyor.");
                }

            }, (string reason) =>
            {
                Debug.Log(reason);
                generalUserOperations.bakim = false;
            });
        }
    });
        }
        else
        {
            //FindObjectOfType<CurrentPlayerData>().onlineDataChecked = 1;
        }
    }

    public void GetVersionData()
    {
        if (Application.internetReachability != NetworkReachability.NotReachable)
        {
            FirebaseDatabase.DefaultInstance
     .GetReference("Versions/Release")
     .GetValueAsync().ContinueWithOnMainThread(task =>
     {
         if (task.IsFaulted || task.IsCanceled)
         {
             Debug.Log("hata: " + task.Exception);
             // Handle the error...
         }
         else if (task.IsCompleted)
         {
             DataSnapshot snapshot = task.Result;
             if (snapshot.GetRawJsonValue() != null)
             {
                 generalUserOperations.versions = JsonConvert.DeserializeObject<List<string>>(snapshot.GetRawJsonValue());
                 EditorUtility.SetDirty(generalUserOperations);
                 Debug.Log("Bilgiler online veritabanından başarıyla alındı");
             }
             else
             {
                 generalUserOperations.versions = new List<string>();
                 Debug.Log("Bilgiler online veritabanında bulunamadığı için uygulama terminal ekranına yönlendiriliyor...");
             }
             versions = new List<string>(generalUserOperations.versions);
         }
     });
        }
        else
        {
            //FindObjectOfType<CurrentPlayerData>().onlineDataChecked = 1;
        }
    }

    public void SaveDataToOnlineDatabase(string key, string rawJson, onFirebaseSaveSuccess onSuccess)
    {
        reference = FirebaseDatabase.DefaultInstance.RootReference;
        reference.Child(key).SetRawJsonValueAsync(rawJson).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                Debug.Log(task.Exception.ToString());
                return;
            }
            onSuccess();
        });
    }
}
