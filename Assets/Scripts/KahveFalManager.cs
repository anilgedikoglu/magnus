using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using UnityEngine;
using NatSuite.Examples;
using UnityEngine.Networking;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using UnityEngine.UI;
using TMPro;
using Newtonsoft.Json;
using Firebase.Storage;
using Firebase.Extensions;

public class KahveFalManager : MonoBehaviour
{
    public MagnusCameraManager cameraManager;
    public ChatManager chatManager;
    public CurrentPlayerData playerData;

    private RealtimeDatabaseManager realtimeDatabaseManager;
    private AuthenticationManager authenticationManager;

    public List<string> photoLabelNames = new List<string>();

    public int gerekenFotografSayisi = 3;

    public int totalUploadedPhotoCount = 0;

    //Upload type 1 kamera ile fotograf cekmek anlamina gelirken 0 cihaz hafizasindan yuklemektir.
    public int photoUploadType;

    private List<string> _filePath = new List<string>();

    [HideInInspector] public bool canClickOpenFilePicker = true;

    public List<Texture2D> onlineFalPhotos = new();
    public Image[] onlineFalImages;
    public GameObject onlineFalPanel;
    public Image onlineFalPanelBackground;
    public TMP_Text onlineFalAciklama;
    public TMP_Text onlineFalTitle;

    public Sprite onlineFalDefaultBackground;
    public Sprite onlineFalRuyaBackground;
    public Sprite onlineFalDertBackground;
    public Sprite onlineFalPremiumBackground;

    [HideInInspector]
    public List<string> filePath
    {
        get
        {
            return _filePath;

        }
        set
        {
            _filePath = value;

            if (_filePath.Count > 0)
            {
                if (_filePath != null)
                {
                    totalUploadedPhotoCount++;

                    if (!IsOnlineMod(mod))
                    {
                        if (maxNyckelRequestWait == null)
                        {
                            if (totalUploadedPhotoCount >= gerekenFotografSayisi)
                            {
                                maxNyckelRequestWait = MaxNyckelRequestWait();
                                StartCoroutine(maxNyckelRequestWait);
                                Debug.Log("Max wait kuruldu");
                            }
                        }
                        else
                        {
                            StopCoroutine(maxNyckelRequestWait);
                            maxNyckelRequestWait = null;
                            Debug.Log("Max wait işlemi iptal edildi!");

                            if (totalUploadedPhotoCount >= gerekenFotografSayisi)
                            {
                                maxNyckelRequestWait = MaxNyckelRequestWait();
                                StartCoroutine(maxNyckelRequestWait);
                                Debug.Log("Max wait kuruldu");
                            }
                        }
                    }
                }
                else
                {
                    totalUploadedPhotoCount = 0;
                }
            }
            else
            {
                totalUploadedPhotoCount = 0;
            }

            //ayalamadan hemen sonra
            if (filePath.Count > 0)
            {
                for (int i = 0; i < filePath.Count; i++)
                {
                    if (pickedTextures.Count - 1 < i)
                    {
                        Texture2D tex = null;
                        byte[] fileData;
                        if (File.Exists(filePath[i]))
                        {
                            fileData = File.ReadAllBytes(filePath[i]);
                            //tex.LoadImage(fileData); //..this will auto-resize the texture dimensions.
                            tex = NativeGallery.LoadImageAtPath(filePath[i], -1, false, true);
                            
                            if(tex == null)
                                tex = new Texture2D(2, 2);

                            Debug.Log(tex.width);

                            pickedTextures.Add(tex);
                            Sprite sprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), Vector2.zero);
                            for (int u = 0; u < chatManager.answerBubbles.Count; u++)
                            {
                                if (chatManager.answerBubbles[u].GetComponent<AnswerBubble>().button.enabled)
                                {
                                    AnswerBubble bubble = chatManager.answerBubbles[u].GetComponent<AnswerBubble>();
                                    if (!bubble.isPhotoPicked)
                                    {
                                        Image contentImage = bubble.contentImage;
                                        bubble.contentImage.sprite = sprite;

                                        contentImage.GetComponent<RectTransform>().pivot = new Vector2(0.5f, 0.5f);
                                        if (tex.height / tex.width > contentImage.GetComponent<RectTransform>().rect.height / contentImage.GetComponent<RectTransform>().rect.width)
                                        {
                                            contentImage.GetComponent<RectTransform>().localScale = new Vector3(contentImage.GetComponent<RectTransform>().localScale.x, ((float)tex.height / (float)tex.width) / (contentImage.GetComponent<RectTransform>().rect.height / contentImage.GetComponent<RectTransform>().rect.width));
                                        }
                                        else
                                        {
                                            contentImage.GetComponent<RectTransform>().localScale = new Vector3((contentImage.GetComponent<RectTransform>().rect.height / contentImage.GetComponent<RectTransform>().rect.width) / ((float)tex.height / (float)tex.width), contentImage.GetComponent<RectTransform>().localScale.y);
                                        }

                                        //bir önceki fotoğrafa göre offsetmin ve max değerleri değişmiş durumda. fakat biz zaten yukarıda scale ile ayarlama yaprığımız için y ekseni için offset min yani bottom değerini 0a eşitliyoruz.
                                        contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, 0f);

                                        bubble.isPhotoPicked = true;
                                        break;
                                    }
                                }
                            }
                        }

                        for (int u = 0; u < chatManager.answerBubbles.Count; u++)
                        {
                            AnswerBubble bubble = chatManager.answerBubbles[u].GetComponent<AnswerBubble>();
                            if (bubble.button.enabled)
                            {
                                if (maxRequestCount > 0)
                                {
                                    photoUploadType = 0;
                                    ProcessPhoto(tex);
                                    maxRequestCount -= 1;
                                    bubble.button.enabled = false;
                                    break;
                                }
                            }
                        }
                    }
                }

                if (pickedTextures.Count < gerekenFotografSayisi)
                {
                    if (openFilePickerDelay == null && pickedTextures[pickedTextures.Count - 1] != new Texture2D(2, 2))
                    {
                        openFilePickerDelay = FilePickerDelay();
                        StartCoroutine(openFilePickerDelay);
                    }
                }
            }
        }
    }

    List<Texture2D> pickedTextures = new List<Texture2D>();

    [HideInInspector] public IEnumerator openFilePickerDelay;

    [HideInInspector] public string mod;

    public Image incelenecekFotograf;

    public TMP_InputField falAciklamaInputField;

    int maxRequestCount = 100;

    private void Awake()
    {
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        authenticationManager = FindObjectOfType<AuthenticationManager>();
    }

    void Start()
	{
        canClickOpenFilePicker = true;
    }

    void Update()
    {

    }

    IEnumerator FilePickerDelay() 
    {
        canClickOpenFilePicker = false;
        yield return new WaitForSeconds(0.5f);
        canClickOpenFilePicker = true;
        chatManager.answerBubbles[chatManager.answerBubbles.Count - 1].GetComponent<AnswerBubble>().OzelFonksiyonlar();
    }

    IEnumerator maxNyckelRequestWait;
    IEnumerator MaxNyckelRequestWait()
    {
        yield return new WaitForSeconds(10f);

        if (photoLabelNames != null)
        {
            if (photoLabelNames.Count > 0)
            {
                EndOfAllEvaluation(new Texture2D(2, 2));
            }
            else
            {
                if (mod == "kahve")
                {
                    chatManager.ClickVirtualButton("internet yok kahve");
                }
                else if (mod == "yuz")
                {
                    chatManager.ClickVirtualButton("internet yok yuz");
                }
                else if (mod == "ele")
                {
                    chatManager.ClickVirtualButton("internet yok el");
                }
                else
                {
                    chatManager.ClickVirtualButton("internet yok");
                }
            }
        }
        else
        {
            if (mod == "kahve")
            {
                chatManager.ClickVirtualButton("internet yok kahve");
            }
            else if (mod == "yuz")
            {
                chatManager.ClickVirtualButton("internet yok yuz");
            }
            else if (mod == "ele")
            {
                chatManager.ClickVirtualButton("internet yok el");
            }
            else
            {
                chatManager.ClickVirtualButton("internet yok");
            }
        }
    }

    public void ProcessPhoto(Texture2D texture)
    {
        if (IsOnlineMod(mod))
        {
            OnlineFalPhotoProcess(texture);
        }
        else
        {
            NyckelFalPhotoProcess(texture);
        }
    }

    private bool IsOnlineMod(string mod)
    {
        return mod.ToLower().Contains("online");
    }

    private void OnlineFalPhotoProcess(Texture2D texture)
    {
        onlineFalPhotos.Add(texture);

        if (photoUploadType == 1)
            cameraManager.EndOfRequest();

        onlineFalTitle.text = "ÖZEL FAL GÖNDERİMİ";

        onlineFalPanelBackground.color = new Color(0.3f, 0.3f, 0.3f);
        onlineFalPanelBackground.sprite = onlineFalPremiumBackground;
        onlineFalImages[0].transform.parent.parent.parent.gameObject.SetActive(true);
        if (onlineFalPhotos.Count >= gerekenFotografSayisi)
        {
            for (int i = 0; i < onlineFalImages.Length; i++)
            {
                if (onlineFalPhotos.Count > i)
                {
                    onlineFalImages[i].sprite = Sprite.Create(onlineFalPhotos[i],
                        new Rect(0, 0, onlineFalPhotos[i].width, onlineFalPhotos[i].height), new Vector2(.5f, .5f));

                    var photoRect = onlineFalImages[i].GetComponent<RectTransform>();

                    float scale;
                    if (onlineFalPhotos[i].height > onlineFalPhotos[i].width)
                        scale = ((float)onlineFalPhotos[i].height) / onlineFalPhotos[i].width;
                    else
                        scale = ((float)onlineFalPhotos[i].width) / onlineFalPhotos[i].height;

                    photoRect.localScale = new Vector3(scale, scale, 1);
                }
                else
                {
                    onlineFalImages[i].gameObject.SetActive(false);
                }
            }

            chatManager.otomatikOdak = true;
            onlineFalPanel.SetActive(true);

            var bilgiEkraniSettings = FindObjectOfType<WelcomeScreen>().bilgiEkraniSettings;
            onlineFalAciklama.text = bilgiEkraniSettings.onlineFalAciklama
                [Random.Range(0, bilgiEkraniSettings.onlineFalAciklama.Length)];
        }
    }

    public void SendOnlineFal()
    {
        if (!string.IsNullOrEmpty(falAciklamaInputField.text))
        {
            var falData = new OnlineFalData(falAciklamaInputField.text);

            falData.userID = authenticationManager.auth.CurrentUser.UserId;

            if (mod == "online kahve")
            {
                falData.fotoCount = 3;
                falData.type = OnlineFalData.Type.premium;
            }
            else if (mod == "online dertles")
            {
                falData.fotoCount = 0;
                falData.type = OnlineFalData.Type.dertles;
            }
            else if (mod == "online ruya")
            {
                falData.fotoCount = 0;
                falData.type = OnlineFalData.Type.ruya;
            }

            falData.kullaniciAdi = playerData.GetChatVariableValue("isim");
            falData.kullaniciSoyadi = playerData.GetChatVariableValue("soyisim");
            falData.kullaniciCinsiyet = playerData.GetChatVariableValue("cinsiyet");
            falData.kullaniciYas = playerData.GetChatVariableValue("yas");
            falData.kullaniciMeslek = playerData.GetChatVariableValue("meslek");
            falData.kullaniciMedeniDurum = playerData.GetChatVariableValue("medeni durum");
            falData.kullaniciDogumTarihi = playerData.GetChatVariableValue("dogum gunu") + "/"
                + playerData.GetChatVariableValue("dogum ayi") + "/"
                + playerData.GetChatVariableValue("dogum yili");
            falData.kullaniciDogumSaati = playerData.GetChatVariableValue("dogum saati") + ":"
                + playerData.GetChatVariableValue("dogum dakikasi");
            falData.kullaniciDogumYeri = playerData.GetChatVariableValue("dogum sehri");
            falData.kullaniciBurc = playerData.GetChatVariableValue("burc");
            falData.kullaniciYukselen = playerData.GetChatVariableValue("yukselen");
            falData.kullaniciAyBurcu = playerData.GetChatVariableValue("ayburcu");
            falData.kullaniciYasadigiSehir = playerData.GetChatVariableValue("kullanici sehri");

            falData.kullaniciMeslekMemnun = playerData.GetChatVariableValue("meslektenmemnun");
            falData.kullaniciTakim = playerData.GetChatVariableValue("tutulantakım");
            falData.kullaniciTelefonSecim = playerData.GetChatVariableValue("telefonseçim");
            falData.kullaniciKacKardes = playerData.GetChatVariableValue("kaçkardeş");
            falData.kullaniciKacCocuk = playerData.GetChatVariableValue("kaççocuk");
            falData.kullaniciBirCocukCins = playerData.GetChatVariableValue("birçocukcins");
            falData.kullaniciIkiCocukCins = playerData.GetChatVariableValue("ikiçocukcins");
            falData.kullaniciUcCocukCins = playerData.GetChatVariableValue("üççocukcins");
            falData.kullaniciEgitimde = playerData.GetChatVariableValue("eğitimde");
            falData.kullaniciGozRengi = playerData.GetChatVariableValue("gözrengisoru");
            falData.kullaniciHayatta = playerData.GetChatVariableValue("hayatta");
            falData.kullaniciMood = playerData.GetChatVariableValue("mood");
            falData.kullaniciSaglikDurumu = playerData.GetChatVariableValue("sağlıkdurumu");
            falData.kullaniciAskHayati = playerData.GetChatVariableValue("aşkhayatı");
            falData.kullaniciKariyer = playerData.GetChatVariableValue("kariyer");
            falData.kullaniciSaglikYakini = playerData.GetChatVariableValue("sağlıkyakını");
            falData.kullaniciBenSeniTanisam = playerData.GetChatVariableValue("bensenitanısam");
            falData.kullaniciPlatonik = playerData.GetChatVariableValue("platonikkim");
            falData.kullaniciEsleAra = playerData.GetChatVariableValue("eşleara");
            falData.kullaniciKimleYasiyor = playerData.GetChatVariableValue("kimleyaşıyor");
            falData.kullaniciMaddiDurum = playerData.GetChatVariableValue("maddidurum");
            falData.kullaniciEvlilikSuresi = playerData.GetChatVariableValue("evliliksüresi");
            falData.kullaniciAyrilikNeKadar = playerData.GetChatVariableValue("ayrılalınekadar");
            falData.kullaniciNeOgrencisi = playerData.GetChatVariableValue("neöğrencisi");

            var bilgiEkraniSettings = FindObjectOfType<WelcomeScreen>().bilgiEkraniSettings;

            realtimeDatabaseManager.SetData("OnlineFallar/" + falData.userID + "/" + falData.ID,
                JsonConvert.SerializeObject(falData),
                () =>
                {
                    Debug.Log("<color=green>basarili</color>");

                    if (falData.type == OnlineFalData.Type.premium)
                    {
                        onlineFalAciklama.text = bilgiEkraniSettings.onlineFalBasariliAciklama
                         [Random.Range(0, bilgiEkraniSettings.onlineFalBasariliAciklama.Length)];
                    }
                    else if (falData.type == OnlineFalData.Type.dertles)
                    {
                        onlineFalAciklama.text = bilgiEkraniSettings.dertlesBasariliAciklama
                            [Random.Range(0, bilgiEkraniSettings.dertlesBasariliAciklama.Length)];
                    }
                    else if (falData.type == OnlineFalData.Type.ruya)
                    {
                        onlineFalAciklama.text = bilgiEkraniSettings.onlineRuyaBasariliAciklama
                            [Random.Range(0, bilgiEkraniSettings.onlineRuyaBasariliAciklama.Length)];
                    }

                },
                (string reason) =>
                {
                    Debug.Log("<color=red>basarisiz</color> " + reason);

                    if (falData.type == OnlineFalData.Type.premium)
                    {
                        onlineFalAciklama.text = bilgiEkraniSettings.onlineFalBasarisizAciklama
                         [Random.Range(0, bilgiEkraniSettings.onlineFalBasarisizAciklama.Length)];
                    }
                    else if (falData.type == OnlineFalData.Type.dertles)
                    {
                        onlineFalAciklama.text = bilgiEkraniSettings.dertlesBasarisizAciklama
                            [Random.Range(0, bilgiEkraniSettings.dertlesBasarisizAciklama.Length)];
                    }
                    else if (falData.type == OnlineFalData.Type.ruya)
                    {
                        onlineFalAciklama.text = bilgiEkraniSettings.onlineRuyaBasarisizAciklama
                            [Random.Range(0, bilgiEkraniSettings.onlineRuyaBasarisizAciklama.Length)];
                    }
                });

            string inboxMod = string.Empty;
            string inboxDescription = string.Empty;

            if(falData.type == OnlineFalData.Type.premium)
            {
                inboxMod = "onlineFalHazirlaniyor";
                inboxDescription = "Gönderdiğin fal özenle yorumlanıyor...";
            }
            else if (falData.type == OnlineFalData.Type.dertles)
            {
                inboxMod = "dertlesHazirlaniyor";
                inboxDescription = "Gönderdiğin konuyu özenle inceliyorum...";
            }
            else if (falData.type == OnlineFalData.Type.ruya)
            {
                inboxMod = "ruyaHazirlaniyor";
                inboxDescription = "Anlattığın rüyanı yorumluyorum...";
            }

            var uIInfo = new RenderedText.Text.UIInformation(string.Empty, string.Empty);
            uIInfo.firstTimeStamp = Magnus.Time.DateTimeOperations.serverUnixTimeStamp;

            RenderedText son5MetinTexts = playerData.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");
            if (son5MetinTexts == null)
            {
                playerData.localPlayerDatas.renderedTexts.Add(new RenderedText(
                    "son5Metin", inboxMod, inboxDescription, string.Empty, falData.ID, true, uIInfo));
            }
            else
            {
                son5MetinTexts.renderedTexts.Add(new RenderedText.Text(inboxMod, inboxDescription,
                    string.Empty, falData.ID, true, uIInfo));
            }

            if (son5MetinTexts.renderedTexts.Count > 10)
            {
                son5MetinTexts.renderedTexts.RemoveAt(0);
            }

            for (int i = 0; i < falData.fotoCount; i++)
            {
                UploadImage(i.ToString(), falData.ID, onlineFalPhotos[i]);
            }
        }
    }

    public void UploadImage(string fileName, string falID, Texture2D texture)
    {
        var bytes = texture.EncodeToJPG();

        var storage = FirebaseStorage.DefaultInstance;
        // Create a storage reference from our storage service
        StorageReference storageRef =
            storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

        // Create a reference to the file you want to upload
        StorageReference fileRef = storageRef.Child("OnlineFallar/" +
            authenticationManager.auth.CurrentUser.UserId + "/" + falID + "/" + fileName + ".jpg");

        // Upload the file to the path "images/rivers.jpg"
        fileRef.PutBytesAsync(bytes)
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

    public void CloseOnileFalPanel(string mod)
    {
        mod = this.mod + " " + mod;

        onlineFalPanel.SetActive(false);
        chatManager.otomatikOdak = false;
        chatManager.ClickVirtualButton(mod);

        filePath = new List<string>();
        pickedTextures = new List<Texture2D>();
        photoLabelNames = new List<string>();

        onlineFalPhotos = new();

        falAciklamaInputField.text = string.Empty;
    }

    public void OpenDertlesMenu()
    {
        chatManager.otomatikOdak = true;
        onlineFalPanel.SetActive(true);
        for (int i = 0; i < onlineFalImages.Length; i++)
        {
            onlineFalImages[i].gameObject.SetActive(false);
        }
    }

    private async void NyckelFalPhotoProcess(Texture2D texture)
    {
        string accesToken;

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage(new HttpMethod("POST"), "https://www.nyckel.com/connect/token"))
            {
                request.Content = new StringContent("client_id=ajxn2ecu1ant70gtxzct4k86kwrbuuuu&client_secret=viuvpq4reeotzj909vptcrvqaq36m106fsxo5l47vlfqvf71nq2y51h3m4kynx4d&grant_type=client_credentials");
                request.Content.Headers.ContentType = MediaTypeHeaderValue.Parse("application/x-www-form-urlencoded");

                if (Application.internetReachability == NetworkReachability.NotReachable)
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }

                var response = await httpClient.SendAsync(request);

                if (response.IsSuccessStatusCode)
                {
                    string jsonString = await response.Content.ReadAsStringAsync();

                    accesToken = JsonUtility.FromJson<NyckelAuthenticationRespons>(jsonString).access_token;
                }
                else
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }
            }
        }

        byte[] bytes = ImageConversion.EncodeToJPG(texture);
        using (var httpClient = new HttpClient())
        {
            string url = "";
            if (mod == "kahve")
                url = "https://www.nyckel.com/v1/functions/8qkdao5kd65q1fvn/invoke";
            else if (mod == "yuz")
                url = "https://www.nyckel.com/v1/functions/ktdqn42bqcp2ouex/invoke";
            else if (mod == "el")
                url = "https://www.nyckel.com/v1/functions/er7tfv0yq6a9lttc/invoke";

            using (var request = new HttpRequestMessage(new HttpMethod("POST"), url))
            {
                request.Headers.TryAddWithoutValidation("Authorization", $"Bearer {accesToken}");

                var multipartContent = new MultipartFormDataContent();
                //multipartContent.Add(new ByteArrayContent(File.ReadAllBytes("831.jpg")), "data", Path.GetFileName(Application.dataPath + "/831.jpg"));
                if (bytes != null)
                    multipartContent.Add(new ByteArrayContent(bytes), "data", Path.GetFileName(Application.dataPath + "/.jpg"));
                else
                    multipartContent.Add(new ByteArrayContent(new byte[2]), "data", Path.GetFileName(Application.dataPath + "/.jpg"));
                request.Content = multipartContent;

                httpClient.Timeout = System.TimeSpan.FromSeconds(20);
                Debug.Log("Nyckel server'a istek iletildi.");

                if (Application.internetReachability == NetworkReachability.NotReachable)
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }

                var response = await httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }
                string jsonString = await response.Content.ReadAsStringAsync();

                photoLabelNames.Add(JsonUtility.FromJson<NyckelResponse>(jsonString).labelName);

                if (photoUploadType == 1)
                {
                    cameraManager.EndOfRequest();
                }

                if (photoLabelNames.Count >= gerekenFotografSayisi)
                {
                    if (maxNyckelRequestWait != null)
                    {
                        StopCoroutine(maxNyckelRequestWait);
                        maxNyckelRequestWait = null;
                        Debug.Log("Max wait işlemi iptal edildi!");
                    }

                    EndOfAllEvaluation(texture);
                }
            }
        }
    }

    /// <summary>
    /// Bu fonksiyon tum onlien degerlendirmelerin sonucunda gidilecek modun karar verilmesinde
    /// kullanilir.
    /// </summary>
    /// <param name="texture">Texture objesi 
    /// gidilecek olan modda eger animasyon varsa o animasyonda kullanilacak olan objedir.</param>
    public void EndOfAllEvaluation(Texture2D texture)
    {
        //Online degerlendirmeler bittikten sonra bu degisken tekrar sifirlanir.
        totalUploadedPhotoCount = 0;

        //Labellarin kac tane olduklari bilgisini barindiracak liste.
        List<NyckelPhotoLabel> photoLabels = new List<NyckelPhotoLabel>();

        //Labelların kac tane olduklari durumuna gore yeni listeye yazilmasi
        foreach (string element in photoLabelNames)
        {
            if (photoLabels.Exists(x => x.labelName.Equals(element)))
            {
                int index = photoLabels.FindIndex(x => x.labelName.Equals(element));
                photoLabels[index].count++;
            }
            else
            {
                photoLabels.Add(new NyckelPhotoLabel(element, 1));
            }
        }

        //En cok bulunan label.
        NyckelPhotoLabel maxFoundLabel = new NyckelPhotoLabel();
        foreach (NyckelPhotoLabel element in photoLabels)
        {
            Debug.Log(element.labelName);
            Debug.Log(element.count);

            if (maxFoundLabel.count < element.count)
            {
                maxFoundLabel = element;
            }
        }

        if (mod == "kahve") //Eger kahve fali bakiliyorsa.
        {
            if (photoLabelNames.Contains("TrKahveFincan") || photoLabelNames.Contains("TrKahveTabak")) //Eger Nyckel sonuclarindan birisi bile telveli kahve fincani ya da tabağı ise
            {
                Debug.Log(maxFoundLabel.labelName);

                if ((maxFoundLabel.count > 1 && (maxFoundLabel.labelName == "TrKahveFincan" || maxFoundLabel.labelName == "TrKahveTabak"))
                    || (photoLabelNames.Contains("TrKahveFincan") && photoLabelNames.Contains("TrKahveTabak")))                             //Eger en cok bulunan label telveli tabak veya fincan ise ve
                {                                                                                                                           //maxVariable 1den buyukse yani tamami 1 1 1 degisle durumunda
                    playerData.AddElementToChatVariableList("mod", "kahve falı fincan değerlendirme");                                      //Magnus kendinden emin bir sekilde degerlendirir.
                }
                else                                                                                                                        //Eger telveli fincan ya da tabak varsa ama sadece 1 tane ise bu durumda
                {                                                                                                                           //Magnus yine degerlendirir fakat kendinden emin olmayan sekilde.
                    playerData.AddElementToChatVariableList("mod", "kahve falı fincan değerlendirme emin değil");
                }
            }
            else //Eger telveli fincan yoksa fal verilmez. Bu durumda gidilecek tepki sohbeti gonderilen fotograf
            {   //turlerine gore secilir.
                if (maxFoundLabel.count > 1)//Eger gonderilen fotograf turlerinden herhangi birisi 1den buyukse bu durumda
                {                           //o label turunun tepki moda gidilir. Cunku toplamda 3 fotograf vardir
                    switch (maxFoundLabel.labelName)    //birisinin 1'den buyuk olabilmesi icin en cok bulunan olmasi gerekir.
                    {
                        /*
                        case "TrKahveTabak": //Eger 2 tane bulunan label telveli tabak ise...
                            playerData.AddElementToChatVariableList("mod", "kahve falı tabak değerlendirme");
                            break;*/ //Bu kisim silindi!!!!
                        case "BoşTrKahveFincan": //Eger 2 tane bulunan label telvesiz fincan ise...
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı boş fincan değerlendirme");
                            break;
                        case "BoşTrKahveTabak": //Eger 2 tane bulunan label telvesiz tabak ise...
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı boş tabak değerlendirme");
                            break;
                        case "DiğerFincan": //Eger 2 tane bulunan label nescafe bulunan fincan gibi bir sey ise...
                                            //Bu kisim kalkti o yuzden diger moduna gidiyor. eskiden diger fincan moduna gidiyordu!!!
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                            break;
                        case "Ayak": //Eger 2 tane bulunan label ayak ise...
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı ayak değerlendirme");
                            break;
                        case "Yüz": //Eger 2 tane bulunan label yuz ise...
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı yüz değerlendirme");
                            break;
                        case "El": //Eger 2 tane bulunan label telvesiz el ise...
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı el değerlendirme");
                            break;
                        case "Diğer": //Eger 2 tane bulunan label telvesiz diger ise...
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                            break;
                        default: //Eger 2 tane bulunan label bir nedenle nykcelden henuz algoritmaya eklenmemis bir label gelirse...
                                 //BU KOSULUN GERCEKLESEBILECEGI DURUMLAR
                                 //-Nycel sistemine yanlislikla baska bir label eklenmesi.
                                 //-Nyckel sisteminin bir nedenden hatali bir mesaj gondermesi. Ornegin ERROR adinda.
                                 //-(En buyuk olasilik)Ilerleyen guncellemelerde Nyckele eklenebilecek olasi labellarin cok eski surumda kalan
                                 //kullanicilarin surumunda tanımlanmamasi!
                            Debug.Log(maxFoundLabel.labelName);
                            playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                            break;
                    }
                }
                else //Eger Nyckelden 3 tane birbirinden tamamen farkli soncu geldiyse...
                {
                    Debug.Log(maxFoundLabel.labelName);
                    playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                }
            }

            /* ESKİ
            foreach (string element in photoLabelNames)
            {
                switch (element)
                {
                    case "TrKahveFincan":
                        kahveFincaniVar = true;
                        break;
                    case "TrKahveTabak":
                        playerData.AddElementToChatVariableList("mod", "kahve falı tabak değerlendirme");
                        break;
                    case "BoşTrKahveFincan":
                        playerData.AddElementToChatVariableList("mod", "kahve falı boş fincan değerlendirme");
                        break;
                    case "BoşTrKahveTabak":
                        playerData.AddElementToChatVariableList("mod", "kahve falı boş tabak değerlendirme");
                        break;
                    case "DiğerFincan": //Bu kisim kalkti o yuzden diger moduna gidiyor. eskiden diger fincan moduna gidiyordu!!!
                        playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                        break;
                    case "Ayak":
                        playerData.AddElementToChatVariableList("mod", "kahve falı ayak değerlendirme");
                        break;
                    case "Yüz":
                        playerData.AddElementToChatVariableList("mod", "kahve falı yüz değerlendirme");
                        break;
                    case "El":
                        playerData.AddElementToChatVariableList("mod", "kahve falı el değerlendirme");
                        break;
                    case "Diğer":
                        playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                        break;
                    default:
                        playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                        break;
                }

                //Eger kahve fincani bulduysak direkt fali vermeye gidiyoruz...
                if (kahveFincaniVar)
                    break;



                switch (element)
                {
                    case "TrKahveFincan":
                        playerData.AddElementToChatVariableList("mod", "kahve falı fincan değerlendirme");
                        break;
                    case "TrKahveTabak":
                        playerData.AddElementToChatVariableList("mod", "kahve falı tabak değerlendirme");
                        break;
                    case "BoşTrKahveFincan":
                        playerData.AddElementToChatVariableList("mod", "kahve falı boş fincan değerlendirme");
                        break;
                    case "BoşTrKahveTabak":
                        playerData.AddElementToChatVariableList("mod", "kahve falı boş tabak değerlendirme");
                        break;
                    case "DiğerFincan": //Bu kisim kalkti o yuzden diger moduna gidiyor. eskiden diger fincan moduna gidiyordu!!!
                        playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                        break;
                    case "Ayak":
                        playerData.AddElementToChatVariableList("mod", "kahve falı ayak değerlendirme");
                        break;
                    case "Yüz":
                        playerData.AddElementToChatVariableList("mod", "kahve falı yüz değerlendirme");
                        break;
                    case "El":
                        playerData.AddElementToChatVariableList("mod", "kahve falı el değerlendirme");
                        break;
                    case "Diğer":
                        playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                        break;
                    default:
                        playerData.AddElementToChatVariableList("mod", "kahve falı diğer değerlendirme");
                        break;
                }
            }*/


        }
        else if (mod == "yuz")
        {
            foreach (string element in photoLabelNames)
            {
                if (element == "insan")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı insan değerlendirme");

                    if (texture != null)
                    {
                        NyckelRequestExtraInformations(texture, "sacRengi");
                        NyckelRequestExtraInformations(texture, "sapka");
                        NyckelRequestExtraInformations(texture, "moral");
                        NyckelRequestExtraInformations(texture, "kupe");
                        NyckelRequestExtraInformations(texture, "gozluk");
                        NyckelRequestExtraInformations(texture, "sacBoyu");
                        NyckelRequestExtraInformations(texture, "sakal");
                        NyckelRequestExtraInformations(texture, "gozRengi");

                        incelenecekFotograf.sprite = Sprite.Create(texture, new Rect(0.0f, 0.0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100.0f);
                    }
                }
                else if (element == "fincan")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı fincan değerlendirme");
                }
                else if (element == "ayak")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı ayak değerlendirme");
                }
                else if (element == "manzara")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı manzara değerlendirme");
                }
                else if (element == "el")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı el değerlendirme");
                }
                else if (element == "diger")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı diğer değerlendirme");
                }
                else if (element == "evici")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı ev içi değerlendirme");
                }
                else if (element == "kus")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı kuş değerlendirme");
                }
                else if (element == "kedi")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı kedi değerlendirme");
                }
                else if (element == "kopek")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı köpek değerlendirme");
                }
                else if (element == "balik")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı balık değerlendirme");
                }
                else if (element == "hayvan")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı hayvan değerlendirme");
                }
                else if (element == "araba")
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı araba değerlendirme");
                }
                else
                {
                    playerData.AddElementToChatVariableList("mod", "yüz falı diğer değerlendirme");
                    break;
                }
            }
        }
        else if (mod == "el")
        {
            foreach (string element in photoLabelNames)
            {
                if (element == "solel")
                {
                    playerData.AddElementToChatVariableList("mod", "el falı sol el değerlendirme");

                    if (texture != null)
                    {
                        incelenecekFotograf.sprite = Sprite.Create(texture, new Rect(0.0f, 0.0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100.0f);
                    }
                }
                else if (element == "sagel")
                {
                    playerData.AddElementToChatVariableList("mod", "el falı sağ el değerlendirme");

                    if (texture != null)
                    {
                        incelenecekFotograf.sprite = Sprite.Create(texture, new Rect(0.0f, 0.0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100.0f);
                    }
                }
                else if (element == "elustu")
                {
                    playerData.AddElementToChatVariableList("mod", "el falı sağ el değerlendirme");
                }
                else if (element == "yumruk")
                {
                    playerData.AddElementToChatVariableList("mod", "el falı yumruk değerlendirme");
                }
                else if (element == "hareket")
                {
                    playerData.AddElementToChatVariableList("mod", "el falı hareket değerlendirme");
                }
                else if (element == "eldegil")
                {
                    playerData.AddElementToChatVariableList("mod", "el falı el değil değerlendirme");
                }
                else
                {
                    playerData.AddElementToChatVariableList("mod", "el falı el değil değerlendirme");
                    break;
                }
            }
        }

        if (photoUploadType == 1)
        {
            chatManager.answerBubbles[chatManager.answerBubbles.Count - 1].GetComponent<AnswerBubble>().button.onClick.Invoke();

            
            if (playerData.GetChatVariableValue("mod") == "yüz falı insan değerlendirme")
            {
                KahveFaliArkaplanAyarla(false);
            }
            else if (playerData.GetChatVariableValue("mod") == "el falı sağ el değerlendirme")
            {
                KahveFaliArkaplanAyarla(false);
            }
            else if (playerData.GetChatVariableValue("mod") == "el falı sol el değerlendirme")
            {
                KahveFaliArkaplanAyarla(false);
            }

            photoLabelNames = new List<string>();
        }
        else
        {
            chatManager.ClickAnswerBubble(null, 0, 0, false);
            
            if (playerData.GetChatVariableValue("mod") == "yüz falı insan değerlendirme")
            {
                KahveFaliArkaplanAyarla(false);
            }
            else if (playerData.GetChatVariableValue("mod") == "el falı sağ el değerlendirme")
            {
                KahveFaliArkaplanAyarla(false);
            }
            else if (playerData.GetChatVariableValue("mod") == "el falı sol el değerlendirme")
            {
                KahveFaliArkaplanAyarla(false);
            }

            filePath = new List<string>();
            pickedTextures = new List<Texture2D>();
            photoLabelNames = new List<string>();
        }
    }

    public async void NyckelRequestExtraInformations(Texture2D texture, string variable)
    {
        string accesToken;

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage(new HttpMethod("POST"), "https://www.nyckel.com/connect/token"))
            {
                request.Content = new StringContent("client_id=ajxn2ecu1ant70gtxzct4k86kwrbuuuu&client_secret=viuvpq4reeotzj909vptcrvqaq36m106fsxo5l47vlfqvf71nq2y51h3m4kynx4d&grant_type=client_credentials");
                request.Content.Headers.ContentType = MediaTypeHeaderValue.Parse("application/x-www-form-urlencoded");

                if (Application.internetReachability == NetworkReachability.NotReachable)
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }

                httpClient.Timeout = System.TimeSpan.FromSeconds(20);
                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                accesToken = JsonUtility.FromJson<NyckelAuthenticationRespons>(jsonString).access_token;
            }
        }

        byte[] bytes = ImageConversion.EncodeToJPG(texture);
        using (var httpClient = new HttpClient())
        {
            string url = "";
            if (variable == "sacRengi")
                url = "https://www.nyckel.com/v1/functions/1srskayu1jtn7cf8/invoke";
            else if (variable == "sapka")
                url = "https://www.nyckel.com/v1/functions/74v7tnc7baj75xl1/invoke";
            else if (variable == "moral")
                url = "https://www.nyckel.com/v1/functions/ataefshzu9fr9fj9/invoke";
            else if (variable == "kupe")
                url = "https://www.nyckel.com/v1/functions/pdkoh4m0l0fm2a6c/invoke";
            else if (variable == "gozluk")
                url = "https://www.nyckel.com/v1/functions/xrqfufv30lxvns8q/invoke";
            else if (variable == "sacBoyu")
                url = "https://www.nyckel.com/v1/functions/yanrucfzx4cf2k5t/invoke";
            else if (variable == "sakal")
                url = "https://www.nyckel.com/v1/functions/6c5kykl8yehqctfw/invoke";
            else if (variable == "gozRengi")
                url = "https://www.nyckel.com/v1/functions/rb6ku3jx5ixzdtk7/invoke";

            using (var request = new HttpRequestMessage(new HttpMethod("POST"), url))
            {
                request.Headers.TryAddWithoutValidation("Authorization", $"Bearer {accesToken}");

                var multipartContent = new MultipartFormDataContent();
                //multipartContent.Add(new ByteArrayContent(File.ReadAllBytes("831.jpg")), "data", Path.GetFileName(Application.dataPath + "/831.jpg"));
                if (bytes != null)
                    multipartContent.Add(new ByteArrayContent(bytes), "data", Path.GetFileName(Application.dataPath + "/.jpg"));
                else
                    multipartContent.Add(new ByteArrayContent(new byte[2]), "data", Path.GetFileName(Application.dataPath + "/.jpg"));
                request.Content = multipartContent;

                if (Application.internetReachability == NetworkReachability.NotReachable)
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }

                httpClient.Timeout = System.TimeSpan.FromSeconds(20);
                Debug.Log("Nyckel server'a istek iletildi.");
                var response = await httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    chatManager.ClickVirtualButton("internet yok");
                    return;
                }

                string jsonString = await response.Content.ReadAsStringAsync();

                if (variable == "sacRengi")
                    playerData.AddElementToChatVariableList("yuz fali sac rengi", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "sapka")
                    playerData.AddElementToChatVariableList("yuz fali sapka", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "moral")
                    playerData.AddElementToChatVariableList("yuz fali moral", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "kupe")
                    playerData.AddElementToChatVariableList("yuz fali kupe", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "gozluk")
                    playerData.AddElementToChatVariableList("yuz fali gozluk", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "sacBoyu")
                    playerData.AddElementToChatVariableList("yuz fali sac boyu", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "sakal")
                    playerData.AddElementToChatVariableList("yuz fali sakal", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
                else if (variable == "gozRengi")
                    playerData.AddElementToChatVariableList("yuz fali goz rengi", JsonUtility.FromJson<NyckelResponse>(jsonString).labelName.ToLower(), false);
            }
        }
    }

    public class NyckelPhotoLabel
    {
        public string labelName;
        public int count;

        public NyckelPhotoLabel()
        {
            labelName = string.Empty;
            count = 0;                 
        }

        public NyckelPhotoLabel(string labelName)
        {
            this.labelName = labelName;
            count = 0;
        }

        public NyckelPhotoLabel(string labelName, int count)
        {
            this.labelName = labelName;
            this.count = count;
        }
    }

    public class NyckelAuthenticationRespons
    {
        public string access_token;
        public string token_type;
        public int expires_in;
    }

    public class NyckelResponse
    {
        public string labelName;
        public string labelId;
        public double confidence;
    }

    public void KahveFaliArkaplanAyarla(bool changeWallpaper)
    {
        if(changeWallpaper)
            incelenecekFotograf.gameObject.SetActive(false);
        else
            incelenecekFotograf.gameObject.SetActive(true);

        chatManager.introManager.SetKahveFaliWallpaperActive(changeWallpaper);
        StartCoroutine(chatManager.FunctionDelay(() => chatManager.introManager.SetChatWallpaperActive(), 23));
    }

    [System.Serializable]
    public class OnlineFalData
    {
        public string fal;
        public string ID;

        public Type type;

        public string userID;

        public int fotoCount;

        public string kullaniciAdi;
        public string kullaniciSoyadi;
        public string kullaniciCinsiyet;
        public string kullaniciYas;
        public string kullaniciMeslek;
        public string kullaniciMedeniDurum;
        public string kullaniciDogumTarihi;
        public string kullaniciDogumSaati;
        public string kullaniciDogumYeri;
        public string kullaniciBurc;
        public string kullaniciYukselen;
        public string kullaniciAyBurcu;
        public string kullaniciYasadigiSehir;

        public string kullaniciMeslekMemnun;
        public string kullaniciTakim;
        public string kullaniciTelefonSecim;
        public string kullaniciKacKardes;
        public string kullaniciKacCocuk;
        public string kullaniciBirCocukCins;
        public string kullaniciIkiCocukCins;
        public string kullaniciUcCocukCins;
        public string kullaniciEgitimde;
        public string kullaniciGozRengi;
        public string kullaniciHayatta;
        public string kullaniciMood;
        public string kullaniciSaglikDurumu;
        public string kullaniciAskHayati;
        public string kullaniciKariyer;
        public string kullaniciSaglikYakini;
        public string kullaniciBenSeniTanisam;
        public string kullaniciPlatonik;
        public string kullaniciEsleAra;
        public string kullaniciKimleYasiyor;
        public string kullaniciMaddiDurum;
        public string kullaniciEvlilikSuresi;
        public string kullaniciAyrilikNeKadar;
        public string kullaniciNeOgrencisi;

        public OnlineFalData()
        {
            fal = string.Empty;
            ID = string.Empty;

            type = Type.premium;

            userID = string.Empty;

            fotoCount = 0;

            kullaniciAdi = string.Empty;
            kullaniciSoyadi = string.Empty;
            kullaniciCinsiyet = string.Empty;
            kullaniciYas = string.Empty;
            kullaniciMeslek = string.Empty;
            kullaniciMedeniDurum = string.Empty;
            kullaniciDogumTarihi = string.Empty;
            kullaniciDogumSaati = string.Empty;
            kullaniciDogumYeri = string.Empty;
            kullaniciBurc = string.Empty;
            kullaniciYukselen = string.Empty;
            kullaniciAyBurcu = string.Empty;
            kullaniciYasadigiSehir = string.Empty;

            kullaniciMeslekMemnun = string.Empty;
            kullaniciTakim = string.Empty;
            kullaniciTelefonSecim = string.Empty;
            kullaniciKacKardes = string.Empty;
            kullaniciKacCocuk = string.Empty;
            kullaniciBirCocukCins = string.Empty;
            kullaniciIkiCocukCins = string.Empty;
            kullaniciUcCocukCins = string.Empty;
            kullaniciEgitimde = string.Empty;
            kullaniciGozRengi = string.Empty;
            kullaniciHayatta = string.Empty;
            kullaniciMood = string.Empty;
            kullaniciSaglikDurumu = string.Empty;
            kullaniciAskHayati = string.Empty;
            kullaniciKariyer = string.Empty;
            kullaniciSaglikYakini = string.Empty;
            kullaniciBenSeniTanisam = string.Empty;
            kullaniciPlatonik = string.Empty;
            kullaniciEsleAra = string.Empty;
            kullaniciKimleYasiyor = string.Empty;
            kullaniciMaddiDurum = string.Empty;
            kullaniciEvlilikSuresi = string.Empty;
            kullaniciAyrilikNeKadar = string.Empty;
            kullaniciNeOgrencisi = string.Empty;
        }

        public OnlineFalData(string fal)
        {
            this.fal = fal;
            ID = CreateID();
        }

        public enum Type
        {
            premium,
            dertles,
            ruya
        }

        private string CreateID()
        {
            string returnValue = string.Empty;
            string letters = "abcdefghijklmnouprstvyz123456789";
            for(int i = 0; i<6; i++)
            {
                returnValue += letters[Random.Range(0, letters.Length)];
            }
            return returnValue;
        }
    }
}
