using Firebase.Database;
using Firebase.Extensions;
using Firebase.Storage;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;

public class OnlineFalEditor : EditorWindow
{
    private AuthenticationManager authenticationManager;
    private RealtimeDatabaseManager realtimeDatabaseManager;
    private string state;

    private List<KahveFalManager.OnlineFalData> tumFalDatalari = new();
    private List<CurrentPlayerData.AdminAnswer> tumFalYanitlari = new();
    private List<CurrentPlayerData.AdminAnswer> tumOkumayanFalYanitlari = new();

    private KahveFalManager.OnlineFalData currentFalData;
    private CurrentPlayerData.AdminAnswer currentFalYanit;

    private List<Texture2D> downloadedTextures;
    private Texture2D zoomedPhoto;
    private CurrentPlayerData.AdminAnswer adminYaniti;

    private GUIStyle h1;
    private GUIStyle h2;
    private GUIStyle h3;
    private GUIStyle h4;
    private GUIStyle userFont;

    private AdminMessageHistory.Data currentData;
    private AdminMessageHistory.Data[] adminDatas;

    private Vector2 scrollPos;

    [MenuItem("Magnus/Online Islemler/Online Fal")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(OnlineFalEditor));
    }

    private void OnEnable()
    {
        authenticationManager= FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager= FindObjectOfType<RealtimeDatabaseManager>();
        downloadedTextures = new();
        adminYaniti = new();
        state = "mainMenu";
        adminDatas = new AdminMessageHistory.Data[0];
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

        EditorStyles.textArea.wordWrap = true;
        EditorStyles.label.wordWrap = true;

        if (!EditorApplication.isPlaying)
        {
            EditorGUILayout.HelpBox("Bu paneli kullanabilmek için uygulamayı başlatmalı ve giriş yapmalısınız!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();
                state = "mainMenu";
            }
        }
        else
        {
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
            EditorGUILayout.BeginHorizontal();
            if (state == "falMenu")
            {
                if (GUILayout.Button("Geri", GUILayout.Width(50)))
                {
                    state = "mainMenu";
                }
                EditorGUILayout.LabelField("Fal Detayı", h1);
            }
            else if (state == "falYanitMenu")
            {
                if (GUILayout.Button("Geri", GUILayout.Width(50)))
                {
                    state = "mainMenu";
                }
                EditorGUILayout.LabelField("Gönderilen Fal", h1);
            }
            else if (state == "zoomMenu")
            {
                if (GUILayout.Button("Geri", GUILayout.Width(50)))
                {
                    state = "falMenu";
                }
                EditorGUILayout.LabelField("Fotoğrafı İncele", h1);
            }
            else if (state == "yanitIncele")
            {
                if (GUILayout.Button("Geri", GUILayout.Width(50)))
                {
                    state = "falMenu";
                }
                EditorGUILayout.LabelField("Falı Incele", h1);
            }
            else if (state == "islemBasarili")
            {
                EditorGUILayout.LabelField("Başarılı", h1);
            }
            else if (state == "mainMenu")
            {
                EditorGUILayout.LabelField("Tüm Fallar", h1);
            }
            else if (state == "drawMessage")
            {
                EditorGUILayout.LabelField("Kullanıcı Geçmişi", h1);
            }

            EditorGUILayout.Space(50, true);

            if (state == "mainMenu")
            {
                if (GUILayout.Button("Yenile", GUILayout.Width(50)))
                {
                    DownloadReviews();
                }
            }
            EditorGUILayout.EndHorizontal();

            if (state == "mainMenu")
            {
                DrawMainMenu();
            }
            else if (state == "falMenu")
            {
                DrawFalMenu();
            }
            else if (state == "falYanitMenu")
            {
                DrawFalYanitMenu();
            }
            else if (state == "zoomMenu")
            {
                DrawZoomMenu();
            }
            else if (state == "yanitIncele")
            {
                DrawYanitiInceleMenu();
            }
            else if (state == "islemBasarili")
            {
                DrawAciklamaMenu("İşlem başarılı bir şekilde gerçekleştirildi.");
            }
            else if (state == "drawMessage")
            {
                DrawMessage();
            }
            EditorGUILayout.EndScrollView();
        }
    }

    private void DrawMainMenu()
    {
        EditorGUILayout.Space(10);

        KahveFalManager.OnlineFalData silinecekFalData = null;
        foreach (KahveFalManager.OnlineFalData falData in tumFalDatalari)
        {
            if (falData.type == KahveFalManager.OnlineFalData.Type.premium)
                EditorGUILayout.LabelField("PREMIUM FAL");
            else if (falData.type == KahveFalManager.OnlineFalData.Type.dertles)
            {
                EditorGUILayout.LabelField("DERTLEŞ");
            }
            else if (falData.type == KahveFalManager.OnlineFalData.Type.ruya)
            {
                EditorGUILayout.LabelField("RÜYA");
            }

            EditorGUILayout.LabelField(falData.kullaniciAdi + " " + falData.kullaniciSoyadi, h3);
            EditorGUILayout.LabelField(falData.fal, userFont);

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Aç"))
            {
                currentFalData = falData;

                downloadedTextures = new();

                for (int i = 0; i < falData.fotoCount; i++)
                {
                    DownloadImageFile(falData.userID, falData.ID, i.ToString());
                }

                state = "falMenu";

                adminYaniti.id = falData.ID;

                FirebaseDatabase.DefaultInstance.GetReference("AdminMessageHistory").Child(falData.userID).
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
            if (GUILayout.Button("Sil", GUILayout.Width(50)))
            {
                DeleteFal(falData);
                silinecekFalData = falData;
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(20);
        }

        if(silinecekFalData != null)
        {
            tumFalDatalari.Remove(silinecekFalData);
            Repaint();
        }

        EditorGUILayout.LabelField("Yeni Gönderilenler", h1);
        foreach (CurrentPlayerData.AdminAnswer falData in tumFalYanitlari)
        {
            bool okundu = true;

            foreach (CurrentPlayerData.AdminAnswer okunmayanFalData in tumOkumayanFalYanitlari)
            {
                if (okunmayanFalData.id == falData.id)
                {
                    okundu = false;
                    break;
                }
            }

            string title = string.Empty;
            if (falData.type == CurrentPlayerData.AdminAnswer.Type.premium)
                title = "PREMIUM FAL";
            else if (falData.type == CurrentPlayerData.AdminAnswer.Type.dertles)
            {
                title = "DERTLEŞ";
            }
            else if (falData.type == CurrentPlayerData.AdminAnswer.Type.ruya)
            {
                title = "RÜYA";
            }

            title += okundu ? " | OKUNDU" : " | OKUNMADI";

            EditorGUILayout.LabelField(title);

            EditorGUILayout.LabelField(InAppReviewEditor.GetPartOfString(falData.answer, 200));

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Düzenle"))
            {
                currentFalYanit = falData;

                adminYaniti = falData;

                downloadedTextures = new();

                state = "falYanitMenu";

                EditorGUI.FocusTextInControl(null);
            }

            bool breakThis = false;
            if (GUILayout.Button("Sil", GUILayout.Width(50)))
            {
                breakThis = true;
                
                realtimeDatabaseManager.SetData("OnlineFalYanitlariGecmis/" + falData.id, "null");

                EditorGUI.FocusTextInControl(null);

                tumFalYanitlari.Remove(falData);
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(20);

            if (breakThis)
                break;
        }
    }

    private void DrawFalMenu()
    {
        EditorGUILayout.Space(10);

        EditorGUILayout.LabelField("Kullanıcı Bilgileri", h2);
        EditorGUILayout.Space(2);

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("Kullanıcı Yorumu", h2);
        EditorGUILayout.Space(2);
        EditorGUILayout.LabelField(currentFalData.fal, userFont);

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("Fotoğraflar", h2);
        EditorGUILayout.Space(2);

        EditorGUILayout.BeginHorizontal();
        foreach (Texture2D tex in downloadedTextures)
        {
            if (GUILayout.Button(tex, GUILayout.Width(75), GUILayout.Height(75)))
            {
                zoomedPhoto = tex;
                state = "zoomMenu";
            }
        }
        EditorGUILayout.EndHorizontal();

        adminYaniti.answer = EditorGUILayout.TextArea(adminYaniti.answer, EditorStyles.textArea, GUILayout.MinHeight(400));

        #region Degiskenler
        int titleWidth = 130;

        if (currentFalData.type == KahveFalManager.OnlineFalData.Type.premium)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Online Fal Tipi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField("PREMIUM FAL");
            EditorGUILayout.EndHorizontal();
        }
        else if (currentFalData.type == KahveFalManager.OnlineFalData.Type.dertles)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Online Fal Tipi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField("DERTLEŞ");
            EditorGUILayout.EndHorizontal();
        }
        else if (currentFalData.type == KahveFalManager.OnlineFalData.Type.ruya)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Online Fal Tipi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
            EditorGUILayout.LabelField("RÜYA");
            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("İsim: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciAdi + " " + currentFalData.kullaniciSoyadi);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Cinsiyet: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciCinsiyet);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Yaş: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciYas);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Doğum Tarihi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciDogumTarihi);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Doğum Saati: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciDogumSaati);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Doğum Yeri: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciDogumYeri);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Yaşadığı Şehir: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciYasadigiSehir);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Meslek: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciMeslek);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Medeni Durum: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciMedeniDurum);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Burc: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciBurc);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Yukselen: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciYukselen);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Ay Burcu: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciMeslekMemnun);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Tuttuğu Takım: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciTakim);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Telefon Seçim: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciTelefonSecim);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Kaç Kardeş: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciKacKardes);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Kaç Çocuk: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciKacCocuk);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Bir Çocuk: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciBirCocukCins);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("İki Çocuk: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciIkiCocukCins);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Üç Çocuk: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciUcCocukCins);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Eğitimde: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciEgitimde);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Göz Rengi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciGozRengi);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Hayatta: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciHayatta);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Mood: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciMood);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Sağlık Durumu: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciSaglikDurumu);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Ben Seni Tanısam: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciBenSeniTanisam);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Platonik: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciPlatonik);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Eşle Ara: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciEsleAra);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Kimle Yaşıyor: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciKimleYasiyor);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Maddi Durum: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciMaddiDurum);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Evlilik Süresi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciEvlilikSuresi);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Ayrılık Ne kadar: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciAyrilikNeKadar);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Ne Öğrencisi: ", h4, GUILayout.Width(titleWidth), GUILayout.ExpandWidth(false));
        EditorGUILayout.LabelField(currentFalData.kullaniciNeOgrencisi);
        EditorGUILayout.EndHorizontal();
        #endregion

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.Space(50, true);
        if (GUILayout.Button("İncele", GUILayout.Width(150), GUILayout.Height(50)))
        {
            state = "yanitIncele";
        }
        EditorGUILayout.EndHorizontal();

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

    private void DrawFalYanitMenu()
    {
        EditorGUILayout.Space(10);

        adminYaniti.answer = EditorGUILayout.TextArea(adminYaniti.answer, EditorStyles.textArea, GUILayout.MinHeight(600));

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.Space(50, true);
        if (GUILayout.Button("İncele", GUILayout.Width(150), GUILayout.Height(50)))
        {
            state = "yanitIncele";
        }
        EditorGUILayout.EndHorizontal();

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
            state = "falMenu";
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

    public void DrawZoomMenu()
    {
        if (GUILayout.Button(zoomedPhoto, GUILayout.Width(500), GUILayout.Height(500)))
        {
            state = "falMenu";
        }
    }

    public void DrawYanitiInceleMenu()
    {
        EditorGUILayout.Space(10);

        if (currentFalData == null)
        {
            state = "falMenu";
            return;
        }

        EditorGUILayout.LabelField($"Aşağıdaki falı {currentFalData.kullaniciAdi} {currentFalData.kullaniciSoyadi} " +
            $"adlı kullanıcıya göndermek üzeresin. Bu işlem geri alınamaz. Emin misin?");

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.Space(50, true);
        if (GUILayout.Button("Gönder", GUILayout.Width(150), GUILayout.Height(50)))
        {
            adminYaniti.type = (CurrentPlayerData.AdminAnswer.Type)((int)currentFalData.type);

            realtimeDatabaseManager.SetData($"OnlineFalYanitlariGecmis/{currentFalData.userID}/{currentFalData.ID}", JsonConvert.SerializeObject(adminYaniti));


          realtimeDatabaseManager.SetData($"OnlineFalYanitlari/{currentFalData.userID}/{currentFalData.ID}", JsonConvert.SerializeObject(adminYaniti),
                () =>
                {
                    AdminMessageHistory.Data data = new();

                    if (adminYaniti.type == CurrentPlayerData.AdminAnswer.Type.premium)
                    {
                        data.title = "Premium";
                    }
                    else if (adminYaniti.type == CurrentPlayerData.AdminAnswer.Type.dertles)
                    {
                        data.title = "Dertleş";
                    }
                    else if (adminYaniti.type == CurrentPlayerData.AdminAnswer.Type.ruya)
                    {
                        data.title = "Rüya Yorumu";
                    }

                    data.userMessage = currentFalData.fal;
                    data.adminsAnswer = adminYaniti.answer;
                    data.ID = adminYaniti.id;
                    data.timeStamp = Magnus.Time.DateTimeOperations.serverUnixTimeStamp;

                    realtimeDatabaseManager.SetData("AdminMessageHistory/" +
                        currentFalData.userID + "/" + data.ID,
                        JsonConvert.SerializeObject(data));

                    state = "islemBasarili";
                    adminYaniti.answer = string.Empty;
                    DownloadReviews();
                },
                (string reason) =>
                {
                    state = "mainMenu";
                    Debug.LogError("Fal yaniti gonderilirken bir hata meydana geldi!" + reason);
                });

            realtimeDatabaseManager.reference.Child($"OnlineFallar/{currentFalData.userID}/{currentFalData.ID}").SetValueAsync(null).
                ContinueWithOnMainThread(task =>
                {
                    if(task.IsFaulted || task.IsCanceled)
                    {
                        Debug.LogError("Fal datasi silinirken hata meydana geldi.");
                    }
                });
        }
        EditorGUILayout.EndHorizontal();
    }

    public void DrawAciklamaMenu(string aciklama)
    {
        EditorGUILayout.Space(10);

        EditorGUILayout.LabelField(aciklama);

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.Space(50, true);
        if (GUILayout.Button("Ana Menü", GUILayout.Width(150), GUILayout.Height(50)))
        {
            state = "mainMenu";
        }
        EditorGUILayout.EndHorizontal();
    }

    private void DeleteFal(KahveFalManager.OnlineFalData falData)
    {
        FirebaseDatabase.DefaultInstance
                  .GetReference("OnlineFallar/" + falData.userID + "/" + falData.ID).SetValueAsync(null);
    }

    private void DownloadReviews()
    {
        FirebaseDatabase.DefaultInstance
        .GetReference("OnlineFallar")
        .GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsFaulted || task.IsCanceled)
            {
                Debug.LogError("Veriler alınırken hata meydana geldi");
                            // Handle the error...
            }
            else if (task.IsCompleted)
            {
                tumFalDatalari = new();

                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                if (snapshotChilds.Count > 0)
                {
                    foreach(DataSnapshot userSnapshot in snapshotChilds)
                    {
                        List<DataSnapshot> fallar = userSnapshot.Children.ToList();
                        foreach (DataSnapshot fal in fallar)
                        {
                            Debug.Log(fal.GetRawJsonValue());
                            var falData = JsonConvert.DeserializeObject<KahveFalManager.OnlineFalData>(fal.GetRawJsonValue());
                            tumFalDatalari.Add(falData);
                        }
                    }
                    
                    Repaint();
                }
                else
                {
                    Debug.Log(snapshot.Key + " Bir hata meydana geldi...");
                }
            }
        });

        DownloadFalYanit();
    }

    private void DownloadFalYanit()
    {
        FirebaseDatabase.DefaultInstance
        .GetReference("OnlineFalYanitlariGecmis")
        .GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsFaulted || task.IsCanceled)
            {
                Debug.LogError("Veriler alınırken hata meydana geldi");
                // Handle the error...
            }
            else if (task.IsCompleted)
            {
                tumFalYanitlari = new();

                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                if (snapshotChilds.Count > 0)
                {
                    foreach (DataSnapshot userSnapshot in snapshotChilds)
                    {
                        List<DataSnapshot> fallar = userSnapshot.Children.ToList();
                        foreach (DataSnapshot fal in fallar)
                        {
                            Debug.Log(fal.GetRawJsonValue());
                            var falData = JsonConvert.DeserializeObject<CurrentPlayerData.AdminAnswer>(fal.GetRawJsonValue());
                            falData.id = userSnapshot.Key + "/" + falData.id;
                     
                            tumFalYanitlari.Add(falData);
                        }
                    }

                    Repaint();
                }
                else
                {
                    Debug.Log(snapshot.Key + " Bir hata meydana geldi...");
                }
            }
        });

        DownloadOkunmayanFalYanit();
    }

    private void DownloadOkunmayanFalYanit()
    {
        FirebaseDatabase.DefaultInstance
        .GetReference("OnlineFalYanitlari")
        .GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsFaulted || task.IsCanceled)
            {
                Debug.LogError("Veriler alınırken hata meydana geldi");
                // Handle the error...
            }
            else if (task.IsCompleted)
            {
                tumOkumayanFalYanitlari = new();

                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                if (snapshotChilds.Count > 0)
                {
                    foreach (DataSnapshot userSnapshot in snapshotChilds)
                    {
                        List<DataSnapshot> fallar = userSnapshot.Children.ToList();
                        foreach (DataSnapshot fal in fallar)
                        {
                            Debug.Log(fal.GetRawJsonValue());
                            var falData = JsonConvert.DeserializeObject<CurrentPlayerData.AdminAnswer>(fal.GetRawJsonValue());
                            falData.id = userSnapshot.Key + "/" + falData.id;

                            tumOkumayanFalYanitlari.Add(falData);
                        }
                    }

                    Repaint();
                }
                else
                {
                    Debug.Log(snapshot.Key + " Bir hata meydana geldi...");
                }
            }
        });
    }

    public void DownloadImageFile(string userID, string falID, string fileName)
    {
        var storage = FirebaseStorage.DefaultInstance;

        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // Create a reference to the file you want to upload
        StorageReference riversRef = storageRef.Child($"OnlineFallar/{userID}/{falID}/" + fileName + ".jpg");

        const long maxAllowedSize = 5 * 1024 * 1024;
        riversRef.GetBytesAsync(maxAllowedSize).ContinueWithOnMainThread(task => {
            if (task.IsFaulted || task.IsCanceled)
            {
                Debug.LogException(task.Exception);
                // Uh-oh, an error occurred!
            }
            else
            {
                byte[] fileContents = task.Result;
                Texture2D tex = new Texture2D(2, 2);
                tex.LoadImage(fileContents);
                downloadedTextures.Add(tex);
                Repaint();
                Debug.Log("Finished downloading!");
            }
        });
    }
}
