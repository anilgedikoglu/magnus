using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Michsky.UI.ModernUIPack;
using UnityEngine.UI;
using System;
using System.Globalization;
using TMPro;
using System.IO;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Net.Http;
using System.Text;
using UnityEngine.Networking;
using Firebase.Extensions;
using Firebase.Storage;
using System.Threading.Tasks;
using DG.Tweening;
using System.Threading;
using System.Text.RegularExpressions;

public class WelcomeScreen : MonoBehaviour
{
    public ChatManager chatManager;
    public CurrentPlayerData PlayerDataManager;
    public ChatVariables chatVariables;
    AuthenticationManager authenticationManager;
    RealtimeDatabaseManager databaseManager;

    public bool editMode;

    public Image profilePhotoImage;

    public Sprite[] profilePhotos;
    public Sprite capturedProfilePhoto;

    public GameObject generalEditScreenContent;
    public GameObject profilePhotosScreen;

    #region veriAl
    public CustomInputField nameInputField;
    public CustomInputField lastNameInputField, dogumGunuInputField, dogumYiliInputField, dogumSaatiInputField, dogumDakikasiInputField, dogumSehriInputField;

    //public CustomDropdown dropdownCinsiyet, dropdownMeslek, dropdownMedeniDurum, dropdownAy;
    public Dropdown dropdownCinsiyet, dropdownMeslek, dropdownMedeniDurum, dropdownAy, dropdownBurc, dropDownAyburcu, dropdownYukselen;
    #endregion

    public NotificationManager bilgilerEksikNotif;

    private int currentProfilePhotoNum;

    public GameObject cameraPanel;

    public Text kullaniciIdText;

    //Panel User Summary
    public Text ozetKullaniciIsmi;
    public Text ozetKullaniciDogumTarihi;
    public Text ozetKullaniciDogumSaati;
    public Text ozetKullaniciCinsiyeti;
    public Text ozetKullaniciMedeniDurumu;
    public Text ozetKullaniciMeslegi;

    public Text ozetKullaniciBurc;
    public Text ozetKullaniciYukselen;
    public Text ozetKullaniciAyburcu;
    public Text ozetKullaniciGezegen;

    public Text ozetDogumSehri;
    public Image ozetKullaniciFoto;

    public TMP_Text hosgeldinMesaji;
    private bool isHosgeldenMesajiSet = false;

    public PreferencesObject magnusPreferences;

    [HideInInspector] public string filePath;

    public CurrentPlayerData playerData;

    public Animator animator;

    public AnimationClip entryAnimClip, switchSummaryAnimClip;

    public BilgiEkraniSettings bilgiEkraniSettings;

    public Text verileriSilPanelBaslik;
    public Text VerileriSilPanelAciklama1, VerileriSilPanelAciklama2, VerileriSilPanelAciklama3;

    int ssCount = 0;

    public EnergyManager energyManagerAltin;
    public EnergyManager energyManagerElmas;

    public TimerItemManager timerItemManager;

    bool ozelGunVar = false;
    public RectTransform reviewAppRt;
    public RectTransform updateAppRt;

    private BilgiEkraniManager bilgiEkraniManager;

    public GameObject loadingCircleEffect;

    private ModSohbetManager modSohbetManager;

    private void Awake()
    {
        bilgiEkraniManager = GetComponent<BilgiEkraniManager>();
        modSohbetManager = FindObjectOfType<ModSohbetManager>();
    }

    void Start()
    {
        ssCount = 200;
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        databaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        timerItemManager = FindObjectOfType<TimerItemManager>();
        ozelGunVar = false;
        //StartEvent();
    }

    public void StartEvent()
    {
        PlayerDataExist();

        PlayerDataManager.AddElementToChatVariableList("oturumAcilisTarihi", DateTime.Now.ToString(), false);

        GetDayDifferenceBetweenLastUse();
        TanismaGunuHesapla();
        SetProfilePhotoSize();
        OzelGunHesapla();
        //timerItemManager.Initiliaze(); KALDIRILDI

        CheckIfMoonSignEmpty();

        FindObjectOfType<IntroManager>().CheckPlus(true);

        FindObjectOfType<InAppNotifications>().StartEvent();

        StartCoroutine(FindObjectOfType<OpenWeatherApi>().StartLocal(false));
        energyManagerAltin.UpdateBars();

        if (authenticationManager.auth != null)
            if (authenticationManager.auth.CurrentUser != null)
                kullaniciIdText.text = "E-Posta: " + authenticationManager.auth.CurrentUser.Email + "\n"
                    + "ID: " + authenticationManager.auth.CurrentUser.UserId;

        FindObjectOfType<InvitationCodePanel>().openInvitationPanelButton.SetActive(!playerData.datas.inviteKey.used);

        bilgiEkraniManager.KarsilamaMetniAyarla();

        bilgiEkraniManager.CheckInboxNotificationState();

        bilgiEkraniManager.OnlineFalVarMiKontrol();

        bilgiEkraniManager.kontrolPaneliButonu.SetActive(playerData.datas.isAdmin);

        if(!playerData.datas.isUserInformationSent)
        {
            SetUserStat();
            playerData.datas.isUserInformationSent = true;
        }

        modSohbetManager.onlineCheckPerFrame += 50;

        //Wheel chart istegi
        System.TimeZone localZone = System.TimeZone.CurrentTimeZone;
        int minute;
        int hour;
        int day;
        int month;
        int year;
        double lat;
        double lon;
        float tzone = (float)localZone.GetUtcOffset(System.DateTime.Now).TotalHours;

        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum dakikasi"), out minute);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum saati"), out hour);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum gunu"), out day);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum ayi"), out month);
        int.TryParse(PlayerDataManager.GetChatVariableValue("dogum yili"), out year);
        double.TryParse(PlayerDataManager.GetChatVariableValue("dogum sehri enlem"), NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lat);
        double.TryParse(PlayerDataManager.GetChatVariableValue("dogum sehri boylam"), NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lon);

        chatManager.AstrologyWheelChart(day, month, year, hour, minute, (float)lat, (float)lon, tzone);

        int.TryParse(playerData.GetChatVariableValue("polarite feminen"), out int polariteFeminen);
        if (polariteFeminen <= 0)
        {
            bilgiEkraniManager.AstrologyGraphsRequest(day, month, year, hour, minute, (float)lat, (float)lon);
        }
        else
        {
            int.TryParse(PlayerDataManager.GetChatVariableValue("polarite maskulen"), out int polariteMaskulen);

            float totalPolarity = (polariteFeminen + polariteMaskulen) / 100f;
            bilgiEkraniManager.polarityGraph.elements[0].value = polariteFeminen / 100f * (1f / totalPolarity);
            bilgiEkraniManager.polarityGraph.elements[1].value = polariteMaskulen / 100f * (1f / totalPolarity);

            int.TryParse(PlayerDataManager.GetChatVariableValue("modalite kardinal"), out int modaliteKardinal);
            int.TryParse(PlayerDataManager.GetChatVariableValue("modalite degisken"), out int modaliteDegisken);
            int.TryParse(PlayerDataManager.GetChatVariableValue("modalite sabit"), out int modaliteSabit);

            float totalModality = (modaliteKardinal + modaliteDegisken + modaliteSabit) / 100f;
            bilgiEkraniManager.modalityGraph.elements[0].value = modaliteKardinal / 100f * (1f / totalModality);
            bilgiEkraniManager.modalityGraph.elements[1].value = modaliteDegisken / 100f * (1f / totalModality);
            bilgiEkraniManager.modalityGraph.elements[2].value = modaliteSabit / 100f * (1f / totalModality);

            int.TryParse(PlayerDataManager.GetChatVariableValue("element ates"), out int elementAtes);
            int.TryParse(PlayerDataManager.GetChatVariableValue("element toprak"), out int elementToprak);
            int.TryParse(PlayerDataManager.GetChatVariableValue("element hava"), out int elementHava);
            int.TryParse(PlayerDataManager.GetChatVariableValue("element su"), out int elementSu);

            float totalElement = (elementAtes + elementToprak + elementHava + elementSu) / 100f;
            bilgiEkraniManager.elementGraph.elements[0].value = elementAtes / 100f * (1f / totalElement);
            bilgiEkraniManager.elementGraph.elements[1].value = elementToprak / 100f * (1f / totalElement);
            bilgiEkraniManager.elementGraph.elements[2].value = elementHava / 100f * (1f / totalElement);
            bilgiEkraniManager.elementGraph.elements[3].value = elementSu / 100f * (1f / totalElement);

            bilgiEkraniManager.polarityGraph.Initialaze(true);
            bilgiEkraniManager.modalityGraph.Initialaze(true);
            bilgiEkraniManager.elementGraph.Initialaze(true);
            Debug.Log("polarite degeri yerelde bulundugu icin sever istegi gonderilemedi!");
        }

        string kayitKey = "ifadesayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.IfadeSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.IfadeSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.IfadeSayi($"{{{{{kayitKey}yil}}}}"));

        kayitKey = "ruhsayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.RuhSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.RuhSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.RuhSayi($"{{{{{kayitKey}yil}}}}"));

        kayitKey = "sessizbenliksayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.SessizBenlikSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.SessizBenlikSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.SessizBenlikSayi($"{{{{{kayitKey}yil}}}}"));

        kayitKey = "yasamyolusayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.YasamYoluSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.YasamYoluSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.YasamYoluSayi($"{{{{{kayitKey}yil}}}}"));

        kayitKey = "olgunluksayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.OlgunlukSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.OlgunlukSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.OlgunlukSayi($"{{{{{kayitKey}yil}}}}"));

        kayitKey = "dogumgunusayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.DogumYiliSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.DogumYiliSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.DogumYiliSayi($"{{{{{kayitKey}yil}}}}"));

        kayitKey = "karmikborcsayisi";
        playerData.AddElementToChatVariableList(kayitKey, chatVariables.KarmikBorcSayi($"{{{{{kayitKey}}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "bugun", chatVariables.KarmikBorcSayi($"{{{{{kayitKey}bugun}}}}"));
        playerData.AddElementToChatVariableList(kayitKey + "yil", chatVariables.KarmikBorcSayi($"{{{{{kayitKey}yil}}}}"));
    }

    void CheckIfMoonSignEmpty()
    {
        if (string.IsNullOrEmpty(playerData.GetChatVariableValue("ayburcu")) || string.IsNullOrEmpty(playerData.GetChatVariableValue("yukselen")))
        {
            SendAstrologyApiRequestIfDatasChanged(playerData.GetChatVariableValue("dogum yili"), playerData.GetChatVariableValue("dogum ayi"), playerData.GetChatVariableValue("dogum gunu"),
                playerData.GetChatVariableValue("dogum saati"), playerData.GetChatVariableValue("dogum dakikasi"), playerData.GetChatVariableValue("dogum sehri enlem"), 
                playerData.GetChatVariableValue("dogum sehri boylam"), false);
        }
    }

    void Update()
    {
        if (filePath != "")
        {
            Texture2D tex = null;
            byte[] fileData;

            if (File.Exists(filePath))
            {
                fileData = File.ReadAllBytes(filePath);
                tex = new Texture2D(2, 2);
                tex.LoadImage(fileData); //..this will auto-resize the texture dimensions.

                Sprite sprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), Vector2.zero);

                UploadProfilePhoto(filePath);
                loadingCircleEffect.SetActive(true);
                filePath = "";

                //playerData.datas.capturedProfilePhotoData = tex.EncodeToPNG();
                capturedProfilePhoto = sprite;

                ChangeProfilePhotoScreenActivity();
                SetProfilePhotoSize();
            }
        }
    }

    void OzelGunHesapla()
    {
        string tarih = DateTime.Today.Day.ToString() + "." + DateTime.Today.Month.ToString() + "." + DateTime.Today.Year.ToString();

        foreach (PreferencesObject.SpecialDate ozelGun in magnusPreferences.ozelGunler)
        {
            if (ozelGun.dogumGunu)
            {
                int kullaniciDogumGunu;
                int kullaniciDogumAyi;

                int.TryParse(playerData.GetChatVariableValue("dogum gunu"), out kullaniciDogumGunu);
                int.TryParse(playerData.GetChatVariableValue("dogum ayi"), out kullaniciDogumAyi);

                if (kullaniciDogumGunu == 0 || kullaniciDogumAyi == 0)
                {
                    kullaniciDogumGunu = 24;
                    kullaniciDogumAyi = 2;
                }

                DateTime baslangicTarihi = new DateTime(DateTime.Now.Year, kullaniciDogumAyi + ozelGun.baslangicAyi, kullaniciDogumGunu + ozelGun.baslangicGunu);
                DateTime bitisTarihi = new DateTime(DateTime.Now.Year, kullaniciDogumAyi + ozelGun.bitiscAyi, kullaniciDogumGunu + ozelGun.bitiscGunu);

                if (DateTime.Today.Ticks >= baslangicTarihi.Ticks && DateTime.Today.Ticks <= bitisTarihi.Ticks)
                {
                    playerData.AddElementToChatVariableList(ozelGun.gunAdi, "evet", false);
                    ozelGunVar = true;
                }
                else
                {
                    playerData.AddElementToChatVariableList(ozelGun.gunAdi, "hayır", false);
                }
            }
            else if (ozelGun.herYil)
            {
                DateTime baslangicTarihi = new DateTime(DateTime.Now.Year, ozelGun.baslangicAyi, ozelGun.baslangicGunu);
                DateTime bitisTarihi = new DateTime(DateTime.Now.Year, ozelGun.bitiscAyi, ozelGun.bitiscGunu);

                if (DateTime.Today.Ticks >= baslangicTarihi.Ticks && DateTime.Today.Ticks <= bitisTarihi.Ticks)
                {
                    playerData.AddElementToChatVariableList(ozelGun.gunAdi, "evet", false);
                    ozelGunVar = true;
                }
                else
                {
                    playerData.AddElementToChatVariableList(ozelGun.gunAdi, "hayır", false);
                }
            }
            else
            {
                DateTime baslangicTarihi = new DateTime(ozelGun.baslangicYili, ozelGun.baslangicAyi, ozelGun.baslangicGunu);
                DateTime bitisTarihi = new DateTime(ozelGun.bitisYili, ozelGun.bitiscAyi, ozelGun.bitiscGunu);

                if (DateTime.Today.Ticks >= baslangicTarihi.Ticks && DateTime.Today.Ticks <= bitisTarihi.Ticks)
                {
                    playerData.AddElementToChatVariableList(ozelGun.gunAdi, "evet", false);
                }
                else
                {
                    playerData.AddElementToChatVariableList(ozelGun.gunAdi, "hayır", false);
                }
            }
        }
    }

    public void GetDayDifferenceBetweenLastUse()
    {
        PlayerData.Date lastActiveDateString = PlayerDataManager.datas.lastActiveDay;

        DateTime lastActiveDate = Magnus.Time.DateTimeOperations.ToDateTime(lastActiveDateString);

        double totalDayDifference = (DateTime.Today - lastActiveDate).TotalDays;

        if (totalDayDifference < 0)
            totalDayDifference = 0;

        SetDefaultVariabels((int)totalDayDifference);

        PlayerDataManager.AddElementToChatVariableList("gun farki", ((int)totalDayDifference).ToString(), false);

        if (PlayerDataManager.datas.lastActiveDay != new PlayerData.Date(DateTime.Today))
        {
            PlayerDataManager.datas.lastActiveDay = new PlayerData.Date(DateTime.Today);
            PlayerDataManager.AddElementToChatVariableList("oturum sayisi", "1", true);

            int maxDailyEnergy = EnergyManager.GetMaxDailyEnergy();
            int dailyEnergy = EnergyManager.GetDailyEnergy();
            if (playerData.datas.energy < maxDailyEnergy)
            {
                playerData.datas.energy += dailyEnergy;
                playerData.datas.energy = Mathf.Clamp(playerData.datas.energy, 0, maxDailyEnergy);
            }

            PlayerDataManager.datas.bugunGelenMods = new List<PlayerData.BugunGelenMod>();
        }
        else
        {
            int buGunkuOturumSayisi = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("oturum sayisi"), out buGunkuOturumSayisi);
            PlayerDataManager.AddElementToChatVariableList("oturum sayisi", (buGunkuOturumSayisi + 1).ToString(), true);
        }

        if ((int)DateTime.Today.DayOfWeek == 0)
            PlayerDataManager.AddElementToChatVariableList("bugun", (7).ToString(), false);
        else
            PlayerDataManager.AddElementToChatVariableList("bugun", ((int)DateTime.Today.DayOfWeek).ToString(), false);
    }

    public void TanismaGunuHesapla()
    {
        DateTime date = Magnus.Time.DateTimeOperations.ToDateTime(PlayerDataManager.datas.tanismaTarihi);

        double totalDayDifference = (DateTime.Today - date).TotalDays;


        if (totalDayDifference < 0)
            totalDayDifference = 0;

        //Kaldirilacak!!!!
        if (totalDayDifference > 100000)
        {
            PlayerDataManager.datas.tanismaTarihi = new PlayerData.Date(DateTime.Now);
            totalDayDifference = 0;
        }

        //Bu kontrol emin olmak icin var
        if (totalDayDifference == 0)
            playerData.datas.tanismaTarihi = new PlayerData.Date(DateTime.Today);

        PlayerDataManager.AddElementToChatVariableList("kac gun tanisma", ((int)totalDayDifference).ToString(), false);
    }

    public void ChangeProfilePhotoScreenActivity() 
    {
        if (profilePhotosScreen.activeInHierarchy)
        {
            profilePhotosScreen.SetActive(false);
            generalEditScreenContent.SetActive(true);
        }
        else 
        {
            profilePhotosScreen.SetActive(true);
            generalEditScreenContent.SetActive(false);
        }
    }

    public void SetActiveProfilePhotoScreenActivity(bool value)
    {
        if (!value)
        {
            profilePhotosScreen.SetActive(false);
        }
        else
        {
            profilePhotosScreen.SetActive(true);
        }
    }

    public void SetProfilePhotoSprite(int index)
    {
        playerData.datas.profilePhotoLink = string.Empty;
        SetProfilePhotoSpriteIEnumurator(index);
    }

    public async void SetProfilePhotoSpriteIEnumurator(int index) 
    {
        Debug.Log("Kullanıcı fotoğrafı ayarlanıyor.");
        currentProfilePhotoNum = index;
        if (string.IsNullOrEmpty(playerData.datas.profilePhotoLink))
        {
            profilePhotoImage.sprite = profilePhotos[index];
            ozetKullaniciFoto.sprite = profilePhotos[index];

        }
        else
        {
            await DownloadProfilePhotoFile(playerData.datas.profilePhotoLink);
        }
        SetProfilePhotoSize();
    }

    public async Task DownloadProfilePhotoFile(string fileName)
    {
        string localUrl = Application.persistentDataPath + "/UserImages/" + fileName;

        if (!Directory.Exists(Application.persistentDataPath + "/UserImages/"))
            Directory.CreateDirectory(Application.persistentDataPath + "/UserImages/");

        /*
        if (!File.Exists(localUrl))
        {
            File.Delete(localUrl);
        }*/

        var storage = FirebaseStorage.DefaultInstance;

        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // Create a reference to the file you want to upload
        StorageReference riversRef = storageRef.Child("UserImages/" + fileName);

        // Start downloading a file
        Task task = riversRef.GetFileAsync((Application.platform == RuntimePlatform.IPhonePlayer) ? "file://" + localUrl : localUrl,
            new StorageProgress<DownloadState>(state =>
            {
                    // called periodically during the download
                Debug.Log(System.String.Format(
                                "Progress: {0} of {1} bytes transferred.",
                                state.BytesTransferred,
                                state.TotalByteCount
                            ));
            }), CancellationToken.None);

        await task.ContinueWithOnMainThread(async resultTask =>
        {
            if (!resultTask.IsFaulted && !resultTask.IsCanceled)
            {
                byte[] texBytes = new byte[0];

                await Task.Run(() =>
                {
                    texBytes = File.ReadAllBytes(localUrl);
                }).ContinueWithOnMainThread((taskLoadImage) =>
                {
                    Texture2D wheelChartTex = new Texture2D(2, 2);
                    wheelChartTex.LoadImage(texBytes);
                    Sprite sprite = Sprite.Create(wheelChartTex, new Rect(0.0f, 0.0f, wheelChartTex.width, wheelChartTex.height), new Vector2(0.5f, 0.5f), 100.0f);
                    profilePhotoImage.sprite = sprite;
                    ozetKullaniciFoto.sprite = sprite;
                    Debug.Log("Kullanıcı fotoğrafı indirildi ve başarıyla kaydedildi.");
                    SetProfilePhotoSize();
                    loadingCircleEffect.SetActive(false);
});

                Debug.Log("Download finished.");
            }
            else
            {
                Debug.Log("basarisiz");
            }
        });
    }

    public void UploadProfilePhoto(string path)
    {
        FirebaseStorage storage = FirebaseStorage.DefaultInstance;
        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.RootReference;

        List<string> allowedFileTypes = new List<string>() { ".jpg", ".jpeg", ".png" };
        string fileExtention = Path.GetExtension(path);

        if (allowedFileTypes.Contains(fileExtention))
        {
            // Create a reference to the file you want to upload
            StorageReference photoRef = storageRef.Child("UserImages/"+ authenticationManager.user.UserId + fileExtention);
            if (!string.IsNullOrEmpty(path))
            {
                var fileInfo = new System.IO.FileInfo(path);

                if (fileInfo.Length < 1024d * 1024 * 3d)
                {

                    // Upload the file to the path "images/rivers.jpg"
                    photoRef.PutFileAsync("file://" + path)
                    .ContinueWithOnMainThread((Task<StorageMetadata> task) =>
                    {
                        if (task.IsFaulted || task.IsCanceled)
                        {
                            Debug.LogError(task.Exception.ToString());
                            // Uh-oh, an error occurred!
                        }
                        else
                        {
                            // Metadata contains file metadata such as size, content-type, and download URL.
                            StorageMetadata metadata = task.Result;
                            string md5Hash = metadata.Md5Hash;
                            Debug.Log("Finished uploading...");
                            Debug.Log("md5 hash = " + md5Hash);
                            playerData.datas.profilePhotoLink = authenticationManager.user.UserId + fileExtention;

                            SetProfilePhotoSpriteIEnumurator(0);
                        }
                    });
                }
                else
                {
                    bilgilerEksikNotif.title = bilgiEkraniSettings.profilFotografiBoyutUyari.title;
                    bilgilerEksikNotif.description = bilgiEkraniSettings.profilFotografiBoyutUyari.description;
                    bilgilerEksikNotif.UpdateUI();
                    bilgilerEksikNotif.OpenNotification();
                    Debug.LogError($"<b>{bilgiEkraniSettings.profilFotografiBoyutUyari.title}</b>\n" +
                        $"<b>{bilgiEkraniSettings.profilFotografiBoyutUyari.description}</b>");
                }
            }
        }
        else
        {
            bilgilerEksikNotif.title = bilgiEkraniSettings.profilFotografiDosyaTipiUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.profilFotografiDosyaTipiUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            Debug.LogError($"<b>{bilgiEkraniSettings.profilFotografiDosyaTipiUyari.title}</b>\n" +
                $"<b>{bilgiEkraniSettings.profilFotografiDosyaTipiUyari.description}</b>");
        }
    }

    public void UploadProfilePhoto(byte[] bytes)
    {
        FirebaseStorage storage = FirebaseStorage.DefaultInstance;
        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.RootReference;

        List<string> allowedFileTypes = new List<string>() { ".jpg", ".jpeg", ".png" };
        string fileExtention = ".jpg";

        if (allowedFileTypes.Contains(fileExtention))
        {
            // Create a reference to the file you want to upload
            StorageReference photoRef = storageRef.Child("UserImages/" + authenticationManager.user.UserId + fileExtention);

            if (bytes.Length < 1024d * 1024 * 3d)
            {
                // Upload the file to the path "images/rivers.jpg"
                photoRef.PutBytesAsync(bytes)
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
                        playerData.datas.profilePhotoLink = authenticationManager.user.UserId + fileExtention;

                        SetProfilePhotoSpriteIEnumurator(0);
                    }
                });
            }
            else
            {
                bilgilerEksikNotif.title = bilgiEkraniSettings.profilFotografiBoyutUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.profilFotografiBoyutUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
                Debug.LogError($"<b>{bilgiEkraniSettings.profilFotografiBoyutUyari.title}</b>\n" +
                    $"<b>{bilgiEkraniSettings.profilFotografiBoyutUyari.description}</b>");
            }

        }
        else
        {
            bilgilerEksikNotif.title = bilgiEkraniSettings.profilFotografiDosyaTipiUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.profilFotografiDosyaTipiUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            Debug.LogError($"<b>{bilgiEkraniSettings.profilFotografiDosyaTipiUyari.title}</b>\n" +
                $"<b>{bilgiEkraniSettings.profilFotografiDosyaTipiUyari.description}</b>");
        }
    }

    void SetDefaultVariabels(int dayDifference)
    {
        foreach (DefaultVariables.DefaultChatDegiskeni defaultChatDegiskeni in chatManager.PlayerDataManager.defaultVariables.degiskenler)
        {
            if (defaultChatDegiskeni.resetType == DefaultVariables.DefaultChatDegiskeni.ResetType.everyLaunch)
            {
                playerData.AddElementToChatVariableList(defaultChatDegiskeni.degiskenAdi, defaultChatDegiskeni.degiskenDegeri, false);
            }
            else if (defaultChatDegiskeni.resetType == DefaultVariables.DefaultChatDegiskeni.ResetType.daily && dayDifference > 0)
            {
                playerData.AddElementToChatVariableList(defaultChatDegiskeni.degiskenAdi, defaultChatDegiskeni.degiskenDegeri, false);
            }
        }
    }

    void EditModeOn() 
    {
        Debug.Log("Edit mode aktif");
        editMode = true;

        dogumSehriInputField.GetComponent<InputFieldSuggestion>().EditButton();

        SetProfilePhotoSize();

        animator.SetInteger("state", 2);
    }

    void EditModeOff()
    {
        //Paneli kapatir
        bilgiEkraniManager.EndEditMod();

        editMode = false;

        animator.SetInteger("state", 1);

        if (PlayerDataManager.GetChatVariableValue("introtipi") != "ses" && PlayerDataManager.GetChatVariableValue("introtipi") != "sessiz" && PlayerDataManager.GetChatVariableValue("introtipi") != "ayarlanmadi")
        {
            PlayerDataManager.AddElementToChatVariableList("introtipi", "video");
        }
    }


    public void SetActive(bool value, bool IsStart)
    {
        bilgiEkraniManager.CheckInboxNotificationState();
        gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.SetActive(value);

        if (value)
        {
            playerData.AddElementToChatVariableList("mod", string.Empty);
        }

        if(IsStart)
        {
            StartEvent();
        }
    }

    public void EditModeOkButton() 
    {
        CheckInputItems();
    }

    public void EditModeCancelButton()
    {
        if (PlayerDataManager.GetChatVariableValue("isim") != "")
        {
            if (PlayerDataManager.GetChatVariableValue("soyisim") != "")
            {
                if (PlayerDataManager.GetChatVariableValue("cinsiyet") != "")
                {
                    if (PlayerDataManager.GetChatVariableValue("medeni durum") != "")
                    {
                        if (PlayerDataManager.GetChatVariableValue("meslek") != "")
                        {
                            if (PlayerDataManager.GetChatVariableValue("dogum yili") != "")
                            {
                                if (PlayerDataManager.GetChatVariableValue("dogum ayi") != "")
                                {
                                    if (PlayerDataManager.GetChatVariableValue("dogum gunu") != "")
                                    {
                                        if (PlayerDataManager.GetChatVariableValue("yas") != "")
                                        {
                                            if (PlayerDataManager.GetChatVariableValue("dogum sehri") != "")
                                            {
                                                SetTextsOfInputObjects();
                                                if (string.IsNullOrEmpty(PlayerDataManager.datas.profilePhotoLink))
                                                    SetProfilePhotoSpriteIEnumurator(PlayerDataManager.datas.profilePhotoNum);
                                                EditModeOff();
                                            }
                                        }
                                        else
                                        {
                                            EditModeOn();
                                            bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                                            bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                                            bilgilerEksikNotif.UpdateUI();
                                            bilgilerEksikNotif.OpenNotification();
                                        }
                                    }
                                    else
                                    {
                                        EditModeOn();
                                        bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                                        bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                                        bilgilerEksikNotif.UpdateUI();
                                        bilgilerEksikNotif.OpenNotification();
                                    }
                                }
                                else
                                {
                                    EditModeOn();
                                    bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                                    bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                                    bilgilerEksikNotif.UpdateUI();
                                    bilgilerEksikNotif.OpenNotification();
                                }
                            }
                            else
                            {
                                EditModeOn();
                                bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                                bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                                bilgilerEksikNotif.UpdateUI();
                                bilgilerEksikNotif.OpenNotification();
                            }
                        }
                        else
                        {
                            EditModeOn();
                            bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                            bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                            bilgilerEksikNotif.UpdateUI();
                            bilgilerEksikNotif.OpenNotification();
                        }
                    }
                    else
                    {
                        EditModeOn();
                        bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                        bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                        bilgilerEksikNotif.UpdateUI();
                        bilgilerEksikNotif.OpenNotification();
                    }
                }
                else
                {
                    EditModeOn();
                    bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                    bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                    bilgilerEksikNotif.UpdateUI();
                    bilgilerEksikNotif.OpenNotification();
                }
            }
            else
            {
                EditModeOn();
                bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        }
        else
        {
            EditModeOn();
            bilgilerEksikNotif.title = bilgiEkraniSettings.genelUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.genelUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
        }
    }

    public bool CheckInputItems() 
    {
        //Panel aktif degilse
        if (!GetComponent<RectTransform>().GetChild(0).gameObject.activeInHierarchy)
        {
            return false;
        }

        //Isim bos kalirsa
        if (string.IsNullOrEmpty(nameInputField.inputText.text))
        {
            EditModeOn();
            bilgilerEksikNotif.title = bilgiEkraniSettings.isimUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.isimUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            return false;
        }

        //Soyisim bos kalirsa
        if (string.IsNullOrEmpty(lastNameInputField.inputText.text))
        {
            EditModeOn();
            bilgilerEksikNotif.title = bilgiEkraniSettings.soyisimUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.soyisimUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            return false;
        }

        //Girilen yil degeri minimum yilden buyukse
        int.TryParse(dogumYiliInputField.inputText.text, out int girilenYil);
        if (!(girilenYil >= 1900 && girilenYil <= DateTime.Now.Year - (DateTime.Now.Year - magnusPreferences.minimumDogumYili)))
        {
            EditModeOn();
            bilgilerEksikNotif.title = bilgiEkraniSettings.dogumYiliUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.dogumYiliUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            return false;
        }

        //Girilen tarih ile tarih olusturulamiyorsa verilecek hata
        int.TryParse(dropdownAy.captionText.text, out int girilenAy);
        int.TryParse(dogumGunuInputField.inputText.text, out int girilenGun);
        System.DateTime dogumGunu;
        try
        {
            dogumGunu = new DateTime(girilenYil, girilenAy, girilenGun);
        }
        catch
        {
            EditModeOn();
            bilgilerEksikNotif.title = bilgiEkraniSettings.dogumGunuUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.dogumGunuUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            return false;
        }

        string cinsiyet = dropdownCinsiyet.captionText.text;

        // Bu günün tarihi
        DateTime buGun = DateTime.Today;
        // Yıl farkı
        int yas = buGun.Year - dogumGunu.Year;
        // Bu günün tarihinden yıl farkını çıkar. Doğum günü bu
        // tarihten büyük ise yılı bir azalt.
        if (dogumGunu > buGun.AddYears(-yas))
            yas--;

        //Dogum sehri bos ise
        if (!(dogumSehriInputField.inputText.text != "" && (PlayerDataManager.GetChatVariableValue("dogum sehri") != "" 
            || dogumSehriInputField.GetComponent<InputFieldSuggestion>().selectedCity != null)))
        {
            EditModeOn();
            bilgilerEksikNotif.title = bilgiEkraniSettings.dogumYeriUyari.title;
            bilgilerEksikNotif.description = bilgiEkraniSettings.dogumYeriUyari.description;
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
            return false;
        }

        //Bu asamadan sonra hata olmadmis demektir!

        string dogumGunuSonKayit = playerData.GetChatVariableValue("dogum gunu");
        string dogumAyiSonKayit = playerData.GetChatVariableValue("dogum ayi");
        string dogumYiliSonKayit = playerData.GetChatVariableValue("dogum yili");
        string dogumSaatiSonKayit = playerData.GetChatVariableValue("dogum saati");
        string dogumDakikasiSonKayit = playerData.GetChatVariableValue("dogum dakikasi");
        string dogumSehriLatSonKayit = playerData.GetChatVariableValue("dogum sehri enlem");
        string dogumSehriLonSonKayit = playerData.GetChatVariableValue("dogum sehri boylam");

        if (dogumSehriInputField.GetComponent<InputFieldSuggestion>().selectedCity != null)
        {
            if ((dogumGunuSonKayit == dogumGunuInputField.inputText.text && dogumAyiSonKayit == dropdownAy.captionText.text && dogumYiliSonKayit == dogumYiliInputField.inputText.text && dogumSaatiSonKayit == dogumSaatiInputField.inputText.text
    && dogumDakikasiSonKayit == dogumDakikasiInputField.inputText.text && dogumSehriLatSonKayit == dogumSehriInputField.GetComponent<InputFieldSuggestion>().selectedCity.lat.Replace("\"", "") 
    && dogumSehriLonSonKayit == dogumSehriInputField.GetComponent<InputFieldSuggestion>().selectedCity.lng.Replace("\"", "")) &&
    dropdownYukselen.captionText.text.ToLower() != "hesapla" && dropDownAyburcu.captionText.text.ToLower() != "hesapla" && dropdownBurc.captionText.text.ToLower() != "hesapla")
            {
                PlayerDataManager.AddElementToChatVariableList("burc", dropdownBurc.captionText.text.ToLower());
                PlayerDataManager.AddElementToChatVariableList("yukselen", dropdownYukselen.captionText.text.ToLower());
                PlayerDataManager.AddElementToChatVariableList("ayburcu", dropDownAyburcu.captionText.text.ToLower());
            }
            else
            {
                PlayerDataManager.AddElementToChatVariableList("burc", Burc.BurcHesapla(girilenGun, girilenAy));

                SendAstrologyApiRequestIfDatasChanged(dogumYiliInputField.inputText.text, dropdownAy.captionText.text, dogumGunuInputField.inputText.text, dogumSaatiInputField.inputText.text,
    dogumDakikasiInputField.inputText.text, dogumSehriInputField.GetComponent<InputFieldSuggestion>().selectedCity.lat.Replace("\"", ""),
    dogumSehriInputField.GetComponent<InputFieldSuggestion>().selectedCity.lng.Replace("\"", ""), true);
            }
        }
        else
        {
            if ((dogumGunuSonKayit == dogumGunuInputField.inputText.text && dogumAyiSonKayit == dropdownAy.captionText.text && dogumYiliSonKayit == girilenYil.ToString() && dogumSaatiSonKayit == dogumSaatiInputField.inputText.text
                && dogumDakikasiSonKayit == dogumDakikasiInputField.inputText.text) &&dropdownYukselen.captionText.text.ToLower() != "hesapla" 
                && dropDownAyburcu.captionText.text.ToLower() != "hesapla" && dropdownBurc.captionText.text.ToLower() != "hesapla")
            {
                PlayerDataManager.AddElementToChatVariableList("burc", dropdownBurc.captionText.text.ToLower());
                PlayerDataManager.AddElementToChatVariableList("yukselen", dropdownYukselen.captionText.text.ToLower());
                PlayerDataManager.AddElementToChatVariableList("ayburcu", dropDownAyburcu.captionText.text.ToLower());
            }
            else
            {
                PlayerDataManager.AddElementToChatVariableList("burc", Burc.BurcHesapla(girilenGun, girilenAy));

                SendAstrologyApiRequestIfDatasChanged(girilenYil.ToString(), dropdownAy.captionText.text, dogumGunuInputField.inputText.text, dogumSaatiInputField.inputText.text,
dogumDakikasiInputField.inputText.text, PlayerDataManager.GetChatVariableValue("dogum sehri enlem"), PlayerDataManager.GetChatVariableValue("dogum sehri boylam"), true);
            }
        }

        PlayerDataManager.AddElementToChatVariableList("isim", nameInputField.inputText.text.ToLower());
        PlayerDataManager.AddElementToChatVariableList("soyisim", lastNameInputField.inputText.text.ToLower());
        PlayerDataManager.AddElementToChatVariableList("dogum yili", dogumYiliInputField.inputText.text.ToString().ToLower());
        PlayerDataManager.AddElementToChatVariableList("dogum ayi", dropdownAy.captionText.text.ToLower());
        PlayerDataManager.AddElementToChatVariableList("dogum gunu", dogumGunuInputField.inputText.text.ToLower());
        PlayerDataManager.AddElementToChatVariableList("dogum saati", dogumSaatiInputField.inputText.text.ToString().ToLower());
        PlayerDataManager.AddElementToChatVariableList("dogum dakikasi", dogumDakikasiInputField.inputText.text.ToString().ToLower());

        PlayerDataManager.AddElementToChatVariableList("yas", yas.ToString().ToLower());
        PlayerDataManager.AddElementToChatVariableList("cinsiyet", cinsiyet.ToLower());
        PlayerDataManager.AddElementToChatVariableList("meslek", dropdownMeslek.captionText.text.ToLower());
        PlayerDataManager.AddElementToChatVariableList("medeni durum", dropdownMedeniDurum.captionText.text.ToLower());
;
        PlayerDataManager.AddElementToChatVariableList("son kullanici kaydi gun", DateTime.Now.Day.ToString().ToLower());
        PlayerDataManager.AddElementToChatVariableList("son kullanici kaydi ay", DateTime.Now.Month.ToString().ToLower());
        PlayerDataManager.AddElementToChatVariableList("son kullanici kaydi yil", DateTime.Now.Year.ToString().ToLower());

        PlayerDataManager.datas.profilePhotoNum = currentProfilePhotoNum;

        dogumSehriInputField.GetComponent<InputFieldSuggestion>().SaveButton();
        SetTextsOfInputObjects();
        EditModeOff();
        return true;
    }

    private void SetUserStat()
    {
        string meslek = GetOnlineKey(playerData.GetChatVariableValue("meslek"));
        string medeniDurum = GetOnlineKey(playerData.GetChatVariableValue("medeni durum"));
        string cinsiyet = GetOnlineKey(playerData.GetChatVariableValue("cinsiyet"));
        string yas = GetOnlineKey(playerData.GetChatVariableValue("yas"));
        string dogumYeri = GetOnlineKey(playerData.GetChatVariableValue("dogum sehri"));

        SendUserStat("meslek", meslek);
        SendUserStat("medeniDurum", medeniDurum);
        SendUserStat("cinsiyet", cinsiyet);
        SendUserStat("yas", yas);
        SendUserStat("dogum sehri", dogumYeri);
    }

    private void SendUserStat(string key, string value)
    {
        key += "/" + value;
        if (!string.IsNullOrEmpty(value))
        {
            databaseManager.GetData("UsersInformation/" + key, (data) =>
            {
                int count;

                try
                {
                    count = JsonConvert.DeserializeObject<int>(data);
                }
                catch
                {
                    count = 0;
                }

                string countJson = JsonConvert.SerializeObject((count + 1));

                databaseManager.SetData("UsersInformation/" + key, countJson);
            });
        }
    }

    private string GetOnlineKey(string value)
    {
        string[] nonAsciiCharacters = new string[] { "À", "Á", "Â", "Ã", "Å", "Ä", "Ç", "È", "É", "Ê", "Ë",
            "Ì", "Í", "Î", "Ï", "Ñ", "Ò", "Ó", "Ô", "Ö", "Õ", "Ù", "Ú", "Û", "Ü", "Ý", "à", "á", "â", "ã",
            "ä", "å", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ñ", "ò", "ó", "ô", "õ", "ö", "ø", "ù",
            "ú", "û", "ý", "ÿ", "Ā", "ā", "Ă", "ă", "Ą", "ą", "Ć", "ć", "Ĉ", "ĉ", "Ċ", "ċ", "Č", "č", "Ď",
            "ď", "Đ", "đ", "Ē", "ē", "Ĕ", "ĕ", "Ė", "ė", "Ę", "ę", "Ě", "ě", "Ĝ", "ĝ", "Ğ", "ğ", "Ġ", "ġ",
            "Ģ", "ģ", "Ĥ", "ĥ", "Ĩ", "ĩ", "Ī", "ī", "Ĭ", "ĭ", "Į", "į", "İ", "ı", "Ĵ", "ĵ", "Ķ", "ķ", "ĸ",
            "Ĺ", "ĺ", "Ļ", "ļ", "Ľ", "ľ", "Ŀ", "ŀ", "Ł", "ł", "Ń", "ń", "Ņ", "ņ", "Ň", "ň", "ŉ", "Ŋ", "ŋ",
            "Ō", "ō", "Ŏ", "ŏ", "Ő", "ő", "Ŕ", "ŕ", "Ŗ", "ŗ", "Ř", "ř", "Ś", "ś", "Ŝ", "ŝ", "Ş", "ş", "Š",
            "š", "Ţ", "ţ", "Ť", "ť", "Ũ", "ũ", "Ū", "ū", "Ŭ", "ŭ", "Ů", "ů", "Ű", "ű", "Ų", "ų", "Ŵ", "ŵ",
            "Ŷ", "ŷ", "Ÿ", "Ź", "ź", "Ż", "ż", "Ž", "ž", "Ơ", "ơ", "Ư", "ư", "Ǎ", "ǎ", "Ǐ", "ǐ", "Ǒ", "ǒ",
            "Ǔ", "ǔ", "Ǖ", "ǖ", "Ǘ", "ǘ", "Ǚ", "ǚ", "Ǜ", "ǜ", "Ǻ", "ǻ", "Ǿ", "ǿ" };

        string[] asciiCharacters = new string[] { "A", "A", "A", "A", "A", "A", "C", "E", "E", "E", "E",
            "I", "I", "I", "I", "N", "O", "O", "O", "O", "O", "U", "U", "U", "U", "Y", "a", "a", "a", "a",
            "a", "a", "c", "e", "e", "e", "e", "i", "i", "i", "i", "n", "o", "o", "o", "o", "o", "o", "u",
            "u", "u", "y", "y", "A", "a", "A", "a", "A", "a", "C", "c", "C", "c", "C", "c", "C", "c", "D",
            "c", "D", "d", "E", "e", "E", "e", "E", "e", "E", "e", "E", "e", "G", "g", "G", "g", "G", "g",
            "G", "g", "H", "h", "I", "i", "I", "i", "I", "i", "I", "i", "I", "i", "J", "j", "K", "k", "k",
            "L", "l", "L", "l", "L", "l", "L", "l", "L", "l", "N", "n", "N", "n", "N", "n", "n", "N", "n",
            "O", "o", "O", "o", "O", "o", "R", "r", "R", "r", "R", "r", "S", "s", "S", "s", "S", "s", "S",
            "s", "T", "t", "T", "t", "U", "u", "U", "u", "U", "u", "U", "u", "U", "u", "U", "u", "W", "w",
            "Y", "y", "Y", "Z", "z", "Z", "z", "Z", "z", "O", "o", "U", "u", "A", "a", "I", "i", "O", "o",
            "U", "u", "U", "u", "U", "u", "U", "u", "U", "u", "A", "a", "O", "o" };

        value = Regex.Replace(value, @"[\s]", "_"); // Replace white with under character

        for (int currentChar = 0; currentChar < nonAsciiCharacters.Length; currentChar++)
        {
            value = value.Replace(nonAsciiCharacters[currentChar], asciiCharacters[currentChar]);
        }

        return Regex.Replace(value, @"[^0-9a-zA-Z_]+", string.Empty); // Remove white characters
    }

    async void SendAstrologyApiRequestIfDatasChanged(string dogumYili, string dogumAyi, string dogumGunu, string dogumSaati, string dogumDakikasi, string dogumSehriLat, string dogumSehriLon, bool check)
    {
        int minute;
        int hour;
        int day;
        int month;
        int year;
        double lat;
        double lon;

        int.TryParse(dogumDakikasi, out minute);
        int.TryParse(dogumSaati, out hour);
        int.TryParse(dogumGunu, out day);
        int.TryParse(dogumAyi, out month);
        int.TryParse(dogumYili, out year);
        double.TryParse(dogumSehriLat, NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lat);
        double.TryParse(dogumSehriLon, NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lon);

        await FirstWelcomeScreenManager.AstrologyApiRequestAscendant(day, month, year, hour, minute, (float)lat, (float)lon);
        await FirstWelcomeScreenManager.AstrologyApiRequestMoonSign(day, month, year, hour, minute, (float)lat, (float)lon);
        GetComponent<BilgiEkraniManager>().AstrologyGraphsRequest(day, month, year, hour, minute, (float)lat, (float)lon);

        dropdownYukselen = SetDropdownMenuToValue(dropdownYukselen, PlayerDataManager.GetChatVariableValue("yukselen").ToLower());
        dropDownAyburcu = SetDropdownMenuToValue(dropDownAyburcu, PlayerDataManager.GetChatVariableValue("ayburcu").ToLower());

        SetTextsOfInputObjects();
    }

    public void PlayerDataExist()
    {
        if (PlayerDataManager.GetChatVariableValue("isim") != "")
        {
            if (PlayerDataManager.GetChatVariableValue("soyisim") != "")
            {
                if (PlayerDataManager.GetChatVariableValue("cinsiyet") != "")
                {
                    if (PlayerDataManager.GetChatVariableValue("medeni durum") != "")
                    {
                        if (PlayerDataManager.GetChatVariableValue("meslek") != "")
                        {
                            if (PlayerDataManager.GetChatVariableValue("dogum yili") != "")
                            {
                                if (PlayerDataManager.GetChatVariableValue("dogum ayi") != "")
                                {
                                    if (PlayerDataManager.GetChatVariableValue("dogum gunu") != "")
                                    {
                                        if (PlayerDataManager.GetChatVariableValue("dogum sehri") != "")
                                        {
                                            SetTextsOfInputObjects();
                                            EditModeOff();
                                        }
                                        else
                                        {
                                            EditModeOn();
                                            bilgilerEksikNotif.title = "Bilgi Eksik";
                                            bilgilerEksikNotif.description = "Doğum şehri bilgisi eksik. Lütfen eksik bilgileri tamamla.";
                                            bilgilerEksikNotif.UpdateUI();
                                            bilgilerEksikNotif.OpenNotification();
                                        }
                                    }
                                    else
                                    {
                                        EditModeOn();
                                        bilgilerEksikNotif.title = "Bilgi Eksik";
                                        bilgilerEksikNotif.description = "Doğum günü bilgisi eksik. Lütfen eksik bilgileri tamamla.";
                                        bilgilerEksikNotif.UpdateUI();
                                        bilgilerEksikNotif.OpenNotification();
                                    }
                                }
                                else
                                {
                                    EditModeOn();
                                    bilgilerEksikNotif.title = "Bilgi Eksik";
                                    bilgilerEksikNotif.description = "Doğum ayı bilgisi eksik. Lütfen eksik bilgileri tamamla.";
                                    bilgilerEksikNotif.UpdateUI();
                                    bilgilerEksikNotif.OpenNotification();
                                }
                            }
                            else
                            {
                                EditModeOn();
                                bilgilerEksikNotif.title = "Bilgi Eksik";
                                bilgilerEksikNotif.description = "Doğum yılı bilgisi eksik. Lütfen eksik bilgileri tamamla.";
                                bilgilerEksikNotif.UpdateUI();
                                bilgilerEksikNotif.OpenNotification();
                            }
                        }
                        else
                        {
                            EditModeOn();
                            bilgilerEksikNotif.title = "Bilgi Eksik";
                            bilgilerEksikNotif.description = "Meslek bilgisi eksik. Lütfen eksik bilgileri tamamla.";
                            bilgilerEksikNotif.UpdateUI();
                            bilgilerEksikNotif.OpenNotification();
                        }
                    }
                    else
                    {
                        EditModeOn();
                        bilgilerEksikNotif.title = "Bilgi Eksik";
                        bilgilerEksikNotif.description = "Medeni durum eksik. Lütfen eksik bilgileri tamamla.";
                        bilgilerEksikNotif.UpdateUI();
                        bilgilerEksikNotif.OpenNotification();
                    }
                }
                else
                {
                    EditModeOn();
                    bilgilerEksikNotif.title = "Bilgi Eksik";
                    bilgilerEksikNotif.description = "Cinsiyet bilgisi eksik. Lütfen eksik bilgileri tamamla.";
                    bilgilerEksikNotif.UpdateUI();
                    bilgilerEksikNotif.OpenNotification();
                }
            }
            else
            {
                EditModeOn();
                bilgilerEksikNotif.title = "Bilgi Eksik";
                bilgilerEksikNotif.description = "Soyisim bilgisi durum eksik. Lütfen eksik bilgileri tamamla.";
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        }
        else
        {
            EditModeOn();
            bilgilerEksikNotif.title = "Bilgi Eksik";
            bilgilerEksikNotif.description = "İsim bilgisi eksik. Lütfen eksik bilgileri tamamla.";
            bilgilerEksikNotif.UpdateUI();
            bilgilerEksikNotif.OpenNotification();
        }
    }

    public void SetProfilePhotoSize()
    {
        if (profilePhotoImage.sprite.rect.width >= profilePhotoImage.sprite.rect.height)
        {
            profilePhotoImage.GetComponent<RectTransform>().localScale = new Vector3(1f * (profilePhotoImage.sprite.rect.width / profilePhotoImage.sprite.rect.height), 1f );
            ozetKullaniciFoto.GetComponent<RectTransform>().localScale = profilePhotoImage.GetComponent<RectTransform>().localScale;
        }
        else
        {
            profilePhotoImage.GetComponent<RectTransform>().localScale = new Vector3(1f, 1f * (profilePhotoImage.sprite.rect.height / profilePhotoImage.sprite.rect.width));
            ozetKullaniciFoto.GetComponent<RectTransform>().localScale = profilePhotoImage.GetComponent<RectTransform>().localScale;
        }
    }

    public void ButtonSohbeteGec(string mod)
    {
        if (playerData.isDatabaseLoaded)
        {
            animator.SetInteger("state", -1);
            StartCoroutine(ButtonSohbeteGecDelay(mod));
            modSohbetManager.onlineCheckPerFrame += 100;
        }
        else
        {
            playerData.onlineDatabaseYukleniyorPanel.SetActive(true);
            playerData.onlineDatabaseLoadEvent += () => 
            {
                ButtonSohbeteGec(mod);
            };
        }
    }

    IEnumerator ButtonSohbeteGecDelay(string mod)
    {
        SetActive(false, false);
        yield return new WaitForEndOfFrame();
        chatManager.chatScreenActivityManager.SetActive();
        chatManager.introManager.SetChatWallpaperActive();
        yield return new WaitForEndOfFrame();
        chatManager.StartChatManager(mod);
    }

    public void ButtonSohbeteGec()
    {
        if (playerData.isDatabaseLoaded)
        {
            animator.SetInteger("state", -1);
            StartCoroutine(ButtonSohbeteGecDelay());
            modSohbetManager.onlineCheckPerFrame += 100;
        }
        else
        {
            playerData.onlineDatabaseYukleniyorPanel.SetActive(true);
            playerData.onlineDatabaseLoadEvent += () =>
            {
                ButtonSohbeteGec();
            };
        }
    }

    IEnumerator ButtonSohbeteGecDelay()
    {
        yield return new WaitForSeconds(0.5f);
        SetActive(false, false);
        chatManager.StartChatManager(ozelGunVar);
        chatManager.chatScreenActivityManager.SetActive();
        chatManager.introManager.SetChatWallpaperActive();

        if (playerData.GetChatVariableValue("uygulama degerlendirildi") != "degerlendirdi")
        {
            float chance = UnityEngine.Random.Range(0, 100);

            if (chance > 75)
            {
                updateAppRt.gameObject.SetActive(false);
                reviewAppRt.gameObject.SetActive(true);
                reviewAppRt.anchoredPosition = new Vector2(reviewAppRt.anchoredPosition.x, -80);
                reviewAppRt.DOAnchorPos(new Vector2(reviewAppRt.anchoredPosition.x, -137), 0.4f).onComplete = () => { reviewAppRt.DOPunchScale(new Vector3(0.17f, 0.17f, 0.17f), 0.3f, 2, 2); };

                Image reviewAppImage = reviewAppRt.GetComponent<Image>();
                reviewAppImage.color = new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0f);
                reviewAppImage.DOColor(new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0.8f), 0.4f);

                RectTransform starsParent = reviewAppRt.GetChild(0).GetComponent<RectTransform>();

                for (int i = 0; i < starsParent.childCount; i++)
                {
                    starsParent.GetChild(i).GetComponent<RectTransform>().localScale = new Vector3(0, 0, 1);
                }

                for (int i = 0; i < starsParent.childCount; i++)
                {
                    starsParent.GetChild(i).GetComponent<Image>().color = new Color(starsParent.GetChild(i).GetComponent<Image>().color.r, starsParent.GetChild(i).GetComponent<Image>().color.b, starsParent.GetChild(i).GetComponent<Image>().color.g, 1f);
                }

                for (int i = 0; i < starsParent.childCount; i++)
                {
                    yield return new WaitForSeconds(0.1f);
                    starsParent.GetChild(i).GetComponent<RectTransform>().DOScale(new Vector3(1f, 1f, 1f), 0.4f);
                }

                reviewAppRt.GetComponentInChildren<TMP_Text>().color = new Color(reviewAppRt.GetComponentInChildren<TMP_Text>().color.r, reviewAppRt.GetComponentInChildren<TMP_Text>().color.g, reviewAppRt.GetComponentInChildren<TMP_Text>().color.b, 1f);

                yield return new WaitForSeconds(7);

                reviewAppRt.GetComponentInChildren<TMP_Text>().DOColor(new Color(reviewAppRt.GetComponentInChildren<TMP_Text>().color.r, reviewAppRt.GetComponentInChildren<TMP_Text>().color.g, reviewAppRt.GetComponentInChildren<TMP_Text>().color.b, 0f), 0.4f);

                for (int i = 0; i < starsParent.childCount; i++)
                {
                    starsParent.GetChild(i).GetComponent<Image>().color = new Color(starsParent.GetChild(i).GetComponent<Image>().color.r, starsParent.GetChild(i).GetComponent<Image>().color.b, starsParent.GetChild(i).GetComponent<Image>().color.g, 1f);
                    starsParent.GetChild(i).GetComponent<Image>().DOColor(new Color(starsParent.GetChild(i).GetComponent<Image>().color.r, starsParent.GetChild(i).GetComponent<Image>().color.b, starsParent.GetChild(i).GetComponent<Image>().color.g, 0f), 0.4f);
                }

                reviewAppImage.color = new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0.8f);
                reviewAppImage.DOColor(new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0f), 0.4f);

                reviewAppRt.DOAnchorPos(new Vector2(reviewAppRt.anchoredPosition.x, -80), 0.4f).onComplete = () => { reviewAppRt.gameObject.SetActive(false); };
            }
            else
            {
                float chanceReview = UnityEngine.Random.Range(0, 100);
                if (chanceReview > 50)
                {
                    if (playerData.localPlayerDatas.showUpdateNotification)
                    {
                        Debug.Log("<color=green>Sürüm güncel değil bildirimi gösterildi!!!!</color>");

                        reviewAppRt.gameObject.SetActive(false);
                        updateAppRt.gameObject.SetActive(true);

                        Image updateAppImage = updateAppRt.GetComponent<Image>();
                        updateAppImage.color = new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0f);
                        updateAppImage.DOColor(new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0.8f), 0.4f);

                        updateAppRt.anchoredPosition = new Vector2(updateAppRt.anchoredPosition.x, -80);
                        updateAppRt.DOAnchorPos(new Vector2(updateAppRt.anchoredPosition.x, -137), 0.4f).onComplete = () => { updateAppRt.DOPunchScale(new Vector3(0.17f, 0.17f, 0.17f), 0.3f, 2, 2); };

                        yield return new WaitForSeconds(7);

                        updateAppImage.color = new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0.8f);
                        updateAppImage.DOColor(new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0f), 0.4f);

                        updateAppRt.DOAnchorPos(new Vector2(updateAppRt.anchoredPosition.x, -80), 0.4f).onComplete = () => { updateAppRt.gameObject.SetActive(false); };
                    }
                }
            }
        }
        else
        {
            float chanceReview = UnityEngine.Random.Range(0, 100);
            if (chanceReview > 50)
            {
                if (playerData.localPlayerDatas.showUpdateNotification)
                {
                    Debug.Log("<color=green>Sürüm güncel değil bildirimi gösterildi!!!!</color>");

                    reviewAppRt.gameObject.SetActive(false);
                    updateAppRt.gameObject.SetActive(true);

                    Image updateAppImage = updateAppRt.GetComponent<Image>();
                    updateAppImage.color = new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0f);
                    updateAppImage.DOColor(new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0.8f), 0.4f);

                    updateAppRt.anchoredPosition = new Vector2(updateAppRt.anchoredPosition.x, -80);
                    updateAppRt.DOAnchorPos(new Vector2(updateAppRt.anchoredPosition.x, -137), 0.4f).onComplete = () => { updateAppRt.DOPunchScale(new Vector3(0.17f, 0.17f, 0.17f), 0.3f, 2, 2); };

                    yield return new WaitForSeconds(7);

                    updateAppImage.color = new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0.8f);
                    updateAppImage.DOColor(new Color(updateAppImage.color.r, updateAppImage.color.g, updateAppImage.color.b, 0f), 0.4f);

                    updateAppRt.DOAnchorPos(new Vector2(updateAppRt.anchoredPosition.x, -80), 0.4f).onComplete = () => { updateAppRt.gameObject.SetActive(false); };
                }
            }
        }
    }

    public void ReviewOnStore()
    {
        if (playerData.GetChatVariableValue("uygulama degerlendirildi") != "degerlendirdi")
        {
            if (Application.platform == RuntimePlatform.Android)
                Application.OpenURL("https://play.google.com/store/apps/details?id=com.futurastic.Magnus");
            else
                Application.OpenURL("https://apps.apple.com/us/app/magnus-kahve-fal%C4%B1-tarot/id1612979368");

            //playerData.datas.plusExpireDateFromSystem = new PlayerData.Date(System.DateTime.Now.AddDays(3));
            energyManagerElmas.AddEnergy(0, 1);
            playerData.AddElementToChatVariableList("uygulama degerlendirildi", "degerlendirdi");

            RectTransform starsParent = reviewAppRt.GetChild(0).GetComponent<RectTransform>();

            reviewAppRt.GetComponentInChildren<TMP_Text>().DOColor(new Color(reviewAppRt.GetComponentInChildren<TMP_Text>().color.r, reviewAppRt.GetComponentInChildren<TMP_Text>().color.g, reviewAppRt.GetComponentInChildren<TMP_Text>().color.b, 0f), 0.4f);

            for (int i = 0; i < starsParent.childCount; i++)
            {
                starsParent.GetChild(i).GetComponent<Image>().color = new Color(starsParent.GetChild(i).GetComponent<Image>().color.r, starsParent.GetChild(i).GetComponent<Image>().color.b, starsParent.GetChild(i).GetComponent<Image>().color.g, 1f);
                starsParent.GetChild(i).GetComponent<Image>().DOColor(new Color(starsParent.GetChild(i).GetComponent<Image>().color.r, starsParent.GetChild(i).GetComponent<Image>().color.b, starsParent.GetChild(i).GetComponent<Image>().color.g, 0f), 0.4f);
            }

            Image reviewAppImage = reviewAppRt.GetComponent<Image>();
            reviewAppImage.color = new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0.8f);
            reviewAppImage.DOColor(new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0f), 0.4f);

            reviewAppRt.DOAnchorPos(new Vector2(reviewAppRt.anchoredPosition.x, -80), 0.4f).onComplete = () => { reviewAppRt.gameObject.SetActive(false); };

            //Magazaya zaten gittigi icin eger guncelleme icin sirada bildirim varsa bile yoksayilir
            playerData.localPlayerDatas.showUpdateNotification = false;
        } 
    }

    public void OpenStoreForUpdate()
    {
        if (Application.platform == RuntimePlatform.Android)
            Application.OpenURL("https://play.google.com/store/apps/details?id=com.futurastic.Magnus");
        else
            Application.OpenURL("https://apps.apple.com/us/app/magnus-kahve-fal%C4%B1-tarot/id1612979368");

        updateAppRt.GetComponentInChildren<TMP_Text>().DOColor(new Color(updateAppRt.GetComponentInChildren<TMP_Text>().color.r, updateAppRt.GetComponentInChildren<TMP_Text>().color.g, updateAppRt.GetComponentInChildren<TMP_Text>().color.b, 0f), 0.4f);

        Image reviewAppImage = updateAppRt.GetComponent<Image>();
        reviewAppImage.color = new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0.8f);
        reviewAppImage.DOColor(new Color(reviewAppImage.color.r, reviewAppImage.color.g, reviewAppImage.color.b, 0f), 0.4f);

        updateAppRt.DOAnchorPos(new Vector2(updateAppRt.anchoredPosition.x, -80), 0.4f).onComplete = () => { updateAppRt.gameObject.SetActive(false); };

        //Magazaya zaten gittigi icin eger guncelleme icin sirada bildirim varsa bile yoksayilir
        playerData.localPlayerDatas.showUpdateNotification = false;
    }

    public void SetTextsOfInputObjects()
    {
        verileriSilPanelBaslik.text = bilgiEkraniSettings.verileriSifirlaEkranBaslik;
        VerileriSilPanelAciklama1.text = bilgiEkraniSettings.verileriSifirlaAciklama;
        VerileriSilPanelAciklama2.text = bilgiEkraniSettings.hesabiSilAciklama;
        VerileriSilPanelAciklama3.text = bilgiEkraniSettings.hesabiSilDeaktifAciklama;

        nameInputField.inputText.text = PlayerDataManager.GetChatVariableValue("isim", true);
        nameInputField.UpdateState();
        lastNameInputField.inputText.text = PlayerDataManager.GetChatVariableValue("soyisim", true);
        lastNameInputField.UpdateState();
        dogumGunuInputField.inputText.text = PlayerDataManager.GetChatVariableValue("dogum gunu");
        dogumGunuInputField.UpdateState();
        dogumYiliInputField.inputText.text = PlayerDataManager.GetChatVariableValue("dogum yili");
        dogumYiliInputField.UpdateState();
        dogumSaatiInputField.inputText.text = PlayerDataManager.GetChatVariableValue("dogum saati");
        dogumSaatiInputField.UpdateState();
        dogumDakikasiInputField.inputText.text = PlayerDataManager.GetChatVariableValue("dogum dakikasi");
        dogumDakikasiInputField.UpdateState();
        dogumSehriInputField.inputText.text = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
        dogumSehriInputField.UpdateState();
        dropdownAy = SetDropdownMenuToValue(dropdownAy, PlayerDataManager.GetChatVariableValue("dogum ayi").ToLower());
        dropdownCinsiyet = SetDropdownMenuToValue(dropdownCinsiyet, PlayerDataManager.GetChatVariableValue("cinsiyet").ToLower());
        dropdownMedeniDurum = SetDropdownMenuToValue(dropdownMedeniDurum, PlayerDataManager.GetChatVariableValue("medeni durum").ToLower());
        dropdownMeslek = SetDropdownMenuToValue(dropdownMeslek, PlayerDataManager.GetChatVariableValue("meslek").ToLower());

        dropdownBurc = SetDropdownMenuToValue(dropdownBurc, PlayerDataManager.GetChatVariableValue("burc").ToLower());
        dropdownYukselen = SetDropdownMenuToValue(dropdownYukselen, PlayerDataManager.GetChatVariableValue("yukselen").ToLower());
        dropDownAyburcu = SetDropdownMenuToValue(dropDownAyburcu, PlayerDataManager.GetChatVariableValue("ayburcu").ToLower());

        ozetKullaniciCinsiyeti.text = PlayerDataManager.GetChatVariableValue("cinsiyet", true);
        ozetKullaniciDogumTarihi.text = PlayerDataManager.GetChatVariableValue("dogum gunu") + "." + PlayerDataManager.GetChatVariableValue("dogum ayi") + "." + PlayerDataManager.GetChatVariableValue("dogum yili");
        ozetKullaniciDogumSaati.text = PlayerDataManager.GetChatVariableValue("dogum saati") + "." + PlayerDataManager.GetChatVariableValue("dogum dakikasi");
        ozetKullaniciIsmi.text = PlayerDataManager.GetChatVariableValue("isim", true) + " " + PlayerDataManager.GetChatVariableValue("soyisim", true);
        ozetKullaniciMeslegi.text = PlayerDataManager.GetChatVariableValue("meslek", true);
        ozetKullaniciMedeniDurumu.text = PlayerDataManager.GetChatVariableValue("medeni durum", true);
        ozetKullaniciBurc.text = PlayerDataManager.GetChatVariableValue("burc", true);
        ozetKullaniciYukselen.text = PlayerDataManager.GetChatVariableValue("yukselen", true);
        ozetKullaniciAyburcu.text = PlayerDataManager.GetChatVariableValue("ayburcu", true);
        ozetKullaniciGezegen.text = Burc.GezegeniAl(PlayerDataManager.GetChatVariableValue("burc", true).ToLower());
        ozetDogumSehri.text = PlayerDataManager.GetChatVariableValue("dogum sehri", true);
    }

    public void OpenCameraPanel()
    {
        cameraPanel.SetActive(true);
    }

    public void ClearCapturedPhotoData()
    {
        PlayerDataManager.datas.profilePhotoLink = string.Empty;
    }

    Dropdown SetDropdownMenuToValue(Dropdown dropdown,string value) 
    {
        for (int i = 0; i < dropdown.options.Count; i++)
        {
            if (dropdown.options[i].text.ToLower() == value)
            {
                dropdown.SetValueWithoutNotify(i);
                //dropdown.ChangeDropdownInfo(dropdown.selectedItemIndex);
            }
        }
        return dropdown;
    }
}
