using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Magnus;

using UnityEditor;
using NatSuite.Examples;
using UnityEngine.Networking;
using System.Net.Http;
using System.Text;
using Newtonsoft.Json;
using System.Globalization;
using System.IO;

using DG.Tweening;
using System.Threading.Tasks;

public class ChatManager : MonoBehaviour
{
    [HideInInspector] public List<GameObject> answerBubbles = new List<GameObject>(); //bubbles
    [HideInInspector] public float answerBubbleFrameBlank = 10; //bubble
    [HideInInspector] public float bubbleFrameBlank = 5; //bubble
    public Sohbet sohbet, sonrakiSohbet; // sohbet picker
    [HideInInspector] public TakipSohbeti takipSobhet; // sohbet picker
    public List<Sohbet> tumSohbetler; // sohbet picker
    public List<AciklamaSohbetleri> aciklamasiEklenecekSohbetler; // sohbet picker
    public List<bool> secimYapildi = new List<bool>(); // sohbet picker
    public Sohbet tekrarSohbeti;
    [HideInInspector] public bool takipSohbetiAktif; // sohbet picker
    [HideInInspector] public bool modAyarlandi; // sohbet picker
    [HideInInspector] public int lastAnswerBubbleType; //bubbles
    [HideInInspector] public int lastAnswerVariation;//bubbles
    [HideInInspector] public string sohbettenCikMetni;// sohbet picker
    [HideInInspector] public bool chatIsActive = false;
    [HideInInspector] public float writingAnimationTimer = 0;
    [HideInInspector] public float writingAnimationDelayTimer = 0;
    [HideInInspector] public float writingAnimationType = 0;
    [HideInInspector] public bool anamenuyeGidebilir;
    [HideInInspector] public IntroManager introManager;

    public Sprite wheelChartSprite;

    private int takipSohbetNumarasi;
    private float fpstimer;
    private GameObject[] allBubbles;
    public int modListSohbetCount;
    public float sohbetTimer = 3;
    public float AiMessageDelay;

    public GameObject leftBubble;
    public GameObject rightBubble;
    public GameObject answerBubble;
    public RectTransform canvasRect;
    public RectTransform spawnPoint;
    public RectTransform bubbleParentObject;
    public RectTransform bubbleMover;

    public float spaceBetweenBubbles = 13;
    public float spaceBetweenAnswerBubbles = 10;
    public ChatVariables chatVariablesManager;
    public CurrentPlayerData PlayerDataManager;
    public ModSohbetManager modSohbetManager;
    public ChatScreenActivity chatScreenActivityManager;
    public KahveFalManager kahveFalManager;

    public Animator writingAnimator;
    bool dontShowWritingAnimation;

    public GameObject welcomeWindow;
    public PreferencesObject magnusPreferences;

    public EnergyManager energyBarManager;
    public EnergyManager konsantrasyonBarManager;

    public RectTransform scrollRectContainerRt, scrollRectContentRt, scrollRectPivotRt, scrollRectNotClickableArea;
    public GameObject scrollRectMaskLifted;
    public int bubblePivotInt = 300;
    [HideInInspector] public Vector2 scrollRectPivotTartgetPos, scrollRectPivotPreviousPos;
    private float scrollRectPivotDuration = 0.6f, scrollRectPivotStartTime;
    public Sohbet sohbetBulunamadiSohbeti;
    public GameObject timerBackground;
    public GameObject kelebekLogo;
    public PanelShowWholeTextManager PanelShowWholeTextManager;

    public GameObject panelInternetError;
    float internetPanelTimer;

    public Text fps;

    public bool spawned = false;
    public int herFramedekiKontSayisi;
    public Sohbet sohbet2;

    public GameObject deviceCameraFolder;
    public GameObject cameraButton;

    public int cekilecekFotografSayisi;

    public bool otomatikOdak;

    public cgChessBoardScript cgChessBoardScript;

    public BookManager bookManager;

    [HideInInspector] public int scrollOfftet;
    [HideInInspector] public bool screenShifted;
    public string lastScreenShiftedMod;

    public GameObject magnuFlowGamePrefab;
    public GameObject magnuDotsGamePrefab;
    public GameObject magnu2048GamePrefab;
    public GameObject magnuTrisPrefab;
    public GameObject magnuFPSPrefab;
    public GameObject magnusWord;
    public GameObject magnusKareKelime;

    public int modCounter;
    string lastCounterMod;

    public MagnusScratch magnusScratch;
    public ScratchQuiz scratchQuiz;

    public Magnu2048Settings magnu2048Settings;
    public MagnuTrisSettings magnuTrisSettings;
    public MagNukemSettings magNukemSettings;
    public MagnusWordDatabase magnusWordDatabase;
    public SquareWordDatabase squareWordDatabase;

    public Transform fireworkPivotTr;
    public GameObject fireworkPrefab;
    
    public TarotSettings tarotSettings;
    public GameObject tarotPrefab;
    public List<Sohbet> tarotSohbetleri;


    public SpinWheelSettings spinWheelSettings;
    public GameObject spinWheelPrefab;
    public SpinWheelDragManager spinWheelDragManager;
    public Transform spinWheelPivot;

    public GeneralUserOperations generalUserOperations;

    public AaSettings aaSettings;

    Vector3 previousBubbleMoverPos;

    public ModUsageStat modUsageStat;

    [HideInInspector] public string reklamSonuModu;
    [HideInInspector] public int reklamSonuAzalacakEnerji;
    [HideInInspector] public int reklamSonuAzalacakKons;

    public WheelModSelector wheelModSelector;

    void Start()
    {
#if UNITY_EDITOR
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 200;
#elif UNITY_ANDROID
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 60;
#else
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 60;
#endif

        takipSohbetNumarasi = 1;
        spawned = true;

        PlayerDataManager.AddElementToChatVariableList("arkaplan", "off", false);

        previousBubbleMoverPos = bubbleMover.position;

        scrollRectPivotRt.position = new Vector2(scrollRectPivotRt.position.x, scrollRectPivotRt.parent.GetComponent<RectTransform>().sizeDelta.y);

        introManager = FindObjectOfType<IntroManager>();

        if (PlayerDataManager.datas.dahaOnceGeldi)
            PlayerDataManager.AddElementToChatVariableList("mod", "hoşgeldin");
        else
            PlayerDataManager.AddElementToChatVariableList("mod", "ilk geliş");

        internetPanelTimer = 1f;

        //Mod degistikce gunluk modlarin haric tutulma durumunun kontorlunu yapar
        PlayerDataManager.onModChange += GunlukModlarHaricTutKontrol;

        Input.multiTouchEnabled = true;
    }

    public async void AstrologyWheelChart(int day, int month, int year, int hour, int min, float lat, float lon, float tzone)
    {

        string data = JsonConvert.SerializeObject(new AstrologyApiRequestData(day, month, year, hour, min, (float)System.Math.Round((decimal)lat, 2), (float)System.Math.Round((decimal)lon, 2), tzone));

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                Content = new System.Net.Http.StringContent(data, Encoding.UTF8, "application/json"),
                RequestUri = new System.Uri("https://json.astrologyapi.com/v1/natal_wheel_chart"),
            })
            {
                string contentJsonString = await request.Content.ReadAsStringAsync();

                //if(JsonUtility.FromJson<AstrologyApiResponse>(contentJsonString).ascendant)


                string apiKey = "618158" + ":" + "5baea1bb862488ad92f6e614dc540f98";
                var apiKeyBytes = System.Text.Encoding.UTF8.GetBytes(apiKey);
                var apiKeyData = System.Convert.ToBase64String(apiKeyBytes);

                request.Headers.TryAddWithoutValidation("dataType", "json");
                request.Headers.TryAddWithoutValidation("authorization", "Basic " + apiKeyData);

                var multipartContent = new MultipartFormDataContent();

                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                string chart_url = JsonUtility.FromJson<AstrologyWheelChartResponse>(jsonString).chart_url;
                Debug.Log(jsonString);
                Debug.Log($"Wheel chart icin {chart_url} adresinde istek gonderildi");
                StartCoroutine(DownloadWheelChart(chart_url));
            }
        }
    }

    IEnumerator DownloadWheelChart(string url)
    {
        UnityWebRequest request = UnityWebRequestTexture.GetTexture(url);
        yield return request.SendWebRequest();
        if (request.isNetworkError || request.isHttpError)
            Debug.Log(request.error);
        else
        {
            Texture2D wheelChartTex = ((DownloadHandlerTexture)request.downloadHandler).texture;
            wheelChartSprite = Sprite.Create(wheelChartTex, new Rect(0.0f, 0.0f, wheelChartTex.width, wheelChartTex.height), new Vector2(0.5f, 0.5f), 100.0f);
            Debug.Log("Wheel chart basariyla indirildi ve kaydedildi.");
        }
    }

    [System.Serializable]
    public class AstrologyApiRequestData
    {
        public int day;
        public int month;
        public int year;
        public int hour;
        public int min;
        public float lat;
        public float lon;
        public float tzone;
        public string planet_icon_color;
        public string inner_circle_background;
        public string sign_icon_color;
        public string sign_background;
        public int chart_size = 500;
        public string image_type = "png";

        public AstrologyApiRequestData(int day, int month, int year, int hour, int min, float lat, float lon, float tzone)
        {
            this.day = day;
            this.month = month;
            this.year = year;
            this.hour = hour;
            this.min = min;
            this.lat = lat;
            this.lon = lon;
            this.tzone = tzone;
            this.planet_icon_color = "#F57C00";
            this.inner_circle_background = "#FCFF96";
            this.sign_icon_color = "red";
            this.sign_background = "#ffffff";
            this.chart_size = 500;
            this.image_type = "png";
        }
    }

    class AstrologyWheelChartResponse
    {
        public bool status;
        public string chart_url;
        public string msg;
    }

    public void SetCameraActivity(bool activity)
    {
        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
        {
            deviceCameraFolder.gameObject.SetActive(activity);
            //cameraButton.gameObject.SetActive(activity);
        }
        else
        {
            Debug.Log("Platform android olmadıgı için kamera açılamadı.");
            deviceCameraFolder.gameObject.SetActive(false);
            cameraButton.gameObject.SetActive(activity);
        }
    }

    void Update()
    {
        WritingTimeUpdate();
        CheckInternetStatusUpdate();

        if (fpstimer < 0)
        {
            fps.text = (1f / Time.deltaTime).ToString();
            fpstimer = 0.1f;
        }
        else
        {
            fpstimer -= Time.deltaTime;
        }

        if (sohbet != null && chatIsActive)
        {
            if (AiMessageDelay <= 0)
            {
                if (sohbetTimer > 0)
                {
                    if (sohbet.sayacTipi != Sohbet.sayacTipiEnum.gorunmez || (sohbet.sayacTipi == Sohbet.sayacTipiEnum.gorunmez && chatScreenActivityManager.isChatScreenActive))
                    {
                        if (!otomatikOdak)
                            sohbetTimer -= Time.deltaTime;

                        if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.textEkranda || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                        {
                            timerBackground.SetActive(true);
                            kelebekLogo.SetActive(false);
                            timerBackground.GetComponent<RectTransform>().GetChild(0).GetComponent<Text>().text = ((int)sohbetTimer).ToString();
                        }
                        else
                        {
                            timerBackground.SetActive(false);
                            kelebekLogo.SetActive(true);
                        }

                        if (sohbetTimer == 0)
                        {
                            sohbetTimer = -1;
                            timerBackground.SetActive(false);
                            kelebekLogo.SetActive(true);
                        }
                    }
                }
                else if (sohbetTimer < 0)
                {
                    InitiazeTimerSohbet();
                    sohbetTimer = 0;
                    timerBackground.SetActive(false);
                    kelebekLogo.SetActive(true);
                }
            }
            else
            {
                AiMessageDelay -= Time.deltaTime;

                if (sohbetTimer > 0)
                {
                    if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.textEkranda)
                    {
                        timerBackground.SetActive(true);
                        kelebekLogo.SetActive(false);
                        timerBackground.GetComponent<RectTransform>().GetChild(0).GetComponent<Text>().text = ((int)sohbetTimer).ToString();
                    }
                    else
                    {
                        timerBackground.SetActive(false);
                        kelebekLogo.SetActive(true);
                    }
                }
            }
        }

        if (!spawned)
        {
            for (int i = 0; i < secimYapildi.Count; i++)
            {
                if (!secimYapildi[i])
                {
                    if (i == 0)
                    {
                        sohbet = SohbetPicker2();
                        break;
                    }
                    else
                    {
                        PlayerDataManager.AddElementToChatVariableList("mod", aciklamasiEklenecekSohbetler[i - 1].mod);
                        tumSohbetler = modSohbetManager.ChooseSohbetList();
                        aciklamasiEklenecekSohbetler[i - 1].sohbet = SohbetPicker2();
                        break;
                    }
                }
                else if (i == secimYapildi.Count - 1)
                {
                    if (PlayerDataManager.GetChatVariableValue(sohbet.yokSayDegiskeni) != "" && sohbet.yokSayDegiskeni != "")
                    {
                        if (sohbet.yokSayilmaSohbeti != null)
                        {
                            secimYapildi = new List<bool>();
                            secimYapildi.Add(true);

                            takipSohbetiAktif = false;
                            takipSobhet = null;
                            sohbet = sohbet.yokSayilmaSohbeti;

                            StartCoroutine(CreateChatElements());
                            spawned = true;
                        }
                        else
                        {
                            secimYapildi = new List<bool>();
                            aciklamasiEklenecekSohbetler = new List<AciklamaSohbetleri>();
                            secimYapildi.Add(false);

                            tumSohbetler = modSohbetManager.ChooseSohbetList();
                            sohbet = ChooseNewSohbet();
                            takipSobhet = null;
                            takipSohbetiAktif = false;
                            this.sonrakiSohbet = null;
                        }
                    }
                    else
                    {
                        if (!spawned)
                        {
                            foreach (Sohbet.GerekenDegisken element in sohbet.gerekliDegiskenler)
                            {
                                //Birlestirilen sohbetleri olan sohbetlerde
                                //tekrar asil sohbetin moduna donulur
                                if (element.degiskenAdi == "mod" && 
                                    PlayerDataManager.GetChatVariableValue("mod") != element.degiskenDegeri)
                                {
                                    PlayerDataManager.AddElementToChatVariableList("mod", element.degiskenDegeri);
                                    break;
                                }
                            }
                            herFramedekiKontSayisi = 0;

                            StartCoroutine(CreateChatElements());
                            spawned = true;
                        }
                    }
                }
            }
        }
        

        float t = (Time.time - scrollRectPivotStartTime) / scrollRectPivotDuration;
        scrollRectPivotRt.anchoredPosition = new Vector2(scrollRectPivotRt.anchoredPosition.x, Mathf.SmoothStep(scrollRectPivotPreviousPos.y, scrollRectPivotTartgetPos.y, t));
    }

    void CheckInternetStatusUpdate()
    {
        if (internetPanelTimer > 0)
        {
            internetPanelTimer -= Time.deltaTime;
        }
        else
        {
            internetPanelTimer = 1f;
            CheckInternetStatus();
        }
    }

    void CheckInternetStatus()
    {
        if(Application.internetReachability == NetworkReachability.NotReachable)
        {
            if (!panelInternetError.activeInHierarchy)
            {
                panelInternetError.SetActive(true);
            }
        }
        else
        {
            if (panelInternetError.activeInHierarchy)
            {
                panelInternetError.SetActive(false);
            }
        }
    }

    void WritingTimeUpdate()
    {
        if (writingAnimationDelayTimer > 0)
        {
            writingAnimationDelayTimer -= Time.deltaTime;
        }
        else if (writingAnimationDelayTimer <= 0)
        {
            writingAnimationDelayTimer = 0;

            if (writingAnimationType == 1)
            {
                if (writingAnimationTimer > 0 && !dontShowWritingAnimation)
                {
                    writingAnimationTimer -= Time.deltaTime;
                    writingAnimator.SetInteger("state", 1);
                }
                else
                {
                    writingAnimationTimer = 0;
                    writingAnimator.SetInteger("state", 0);
                }
            }
            else
            {
                if (writingAnimationTimer > 0 && !dontShowWritingAnimation)
                {
                    writingAnimationTimer -= Time.deltaTime;
                    writingAnimator.SetInteger("state", 2);
                }
                else
                {
                    writingAnimationTimer = 0;
                    writingAnimator.SetInteger("state", 0);
                }
            }
        }
    }

    void SetWritingTimer(float time)
    {
        if (writingAnimationTimer < time)
        {
            writingAnimationTimer = time;
        }
    }

    Sohbet ChooseNewSohbet()
    {
        Sohbet secilenSohbet = null;

        if (sohbet.sohbetBititmindeAnamenuyeDon && string.IsNullOrEmpty(sohbet.sohbetBitimModu)
            && string.IsNullOrEmpty(sohbet.kazimaModu) && !modAyarlandi)
        {
            PlayerDataManager.AddElementToChatVariableList("mod", "ana menu");
        }

        secimYapildi = new List<bool>();
        secimYapildi.Add(false);
        spawned = false;
        aciklamasiEklenecekSohbetler = new List<AciklamaSohbetleri>();
        tekrarSohbeti = null;

        return secilenSohbet;
    }

    Sohbet SohbetPicker2()
    {
        int herFramedekiKontSayisiIlk = herFramedekiKontSayisi;
        herFramedekiKontSayisi += 20;

        if (herFramedekiKontSayisi > tumSohbetler.Count)
            herFramedekiKontSayisi = tumSohbetler.Count;

        List<int> sohbetNumaralari = new List<int>();
        //int tumSohbetlerFirstCount = modSohbetManager.TotalSohbetElementCount();
        for (int i = herFramedekiKontSayisiIlk; i < tumSohbetler.Count; i++)
        {
            sohbetNumaralari.Add(i);
        }
        Sohbet secilenSohbet = null;

        List<int> ileriAtilacakSohbetNumaralari = new List<int>();
        for (int u = herFramedekiKontSayisiIlk; u < herFramedekiKontSayisi; u++)
        {
            if (secilenSohbet == null)
            {
                int index = Random.Range(0, sohbetNumaralari.Count);

                ileriAtilacakSohbetNumaralari.Add(sohbetNumaralari[index]);

                bool jump = false;
                //Saat ve yas degiskenlerinin diger degiskenlerden ayrilmasi ve ozel degiskenlere atanmasi
                #region yasSaatGunFarkiDegiskenleriAyarlama
                //max minlerde maxlar dahil değil minler dahil
                List<Sohbet.GerekenDegisken> secilenSohbetDegiskenleri = new List<Sohbet.GerekenDegisken>();

                Sohbet.GerekenDegisken yasMaxDegiskeni = new Sohbet.GerekenDegisken();
                Sohbet.GerekenDegisken yasMinDegiskeni = new Sohbet.GerekenDegisken();

                Sohbet.GerekenDegisken saatMaxDegiskeni = new Sohbet.GerekenDegisken();
                Sohbet.GerekenDegisken saatMinDegiskeni = new Sohbet.GerekenDegisken();

                Sohbet.GerekenDegisken gunFarkiMaxDegiskeni = new Sohbet.GerekenDegisken();
                Sohbet.GerekenDegisken gunFarkiMinDegiskeni = new Sohbet.GerekenDegisken();

                foreach (Sohbet.GerekenDegisken element in tumSohbetler[sohbetNumaralari[index]].gerekliDegiskenler)
                {
                    if (element.degiskenAdi != "yasmin")
                    {
                        if (element.degiskenAdi != "yasmax")
                        {
                            if (element.degiskenAdi != "saatmin")
                            {
                                if (element.degiskenAdi != "saatmax")
                                {
                                    if (element.degiskenAdi != "gunmin")
                                    {
                                        if (element.degiskenAdi != "gunmax")
                                        {
                                            secilenSohbetDegiskenleri.Add(element);
                                        }
                                        else
                                        {
                                            gunFarkiMaxDegiskeni = element;
                                        }
                                    }
                                    else
                                    {
                                        gunFarkiMinDegiskeni = element;
                                    }
                                }
                                else
                                {
                                    saatMaxDegiskeni = element;
                                }
                            }
                            else
                            {
                                saatMinDegiskeni = element;
                            }
                        }
                        else
                        {
                            yasMaxDegiskeni = element;
                        }
                    }
                    else
                    {
                        yasMinDegiskeni = element;
                    }
                }

                int gerekenDegiskenlerLength = secilenSohbetDegiskenleri.Count;

                //Yas
                int yas = 0;
                int.TryParse(PlayerDataManager.GetChatVariableValue("yas"), out yas);

                int yasMin = 0;
                int yasMax = 100;
                int.TryParse(yasMinDegiskeni.degiskenDegeri, out yasMin);
                int.TryParse(yasMaxDegiskeni.degiskenDegeri, out yasMax);

                if (yasMax == 0)
                    yasMax = 1000;

                bool yasAraligiCheck = false;

                if (yas >= yasMin && yas < yasMax)
                {
                    yasAraligiCheck = true;
                }

                //Gun farki
                int gunFarki = 0;
                int.TryParse(PlayerDataManager.GetChatVariableValue("gun farki"), out gunFarki);//Bu degisken welcomeScreen classinda kaydedilir!

                int gunFarkiMin = 0;
                int gunFarkiMax = 100;
                int.TryParse(gunFarkiMinDegiskeni.degiskenDegeri, out gunFarkiMin);
                int.TryParse(gunFarkiMaxDegiskeni.degiskenDegeri, out gunFarkiMax);

                if (gunFarkiMax == 0)
                    gunFarkiMax = int.MaxValue;

                bool gunFarkiAraligiCheck = false;

                if (gunFarki >= gunFarkiMin && gunFarki < gunFarkiMax)
                {
                    gunFarkiAraligiCheck = true;
                }

                //Saat
                int saat = System.DateTime.Now.TimeOfDay.Hours;

                int saatMin = 0;
                int saatMax = 100;
                int.TryParse(saatMinDegiskeni.degiskenDegeri, out saatMin);
                int.TryParse(saatMaxDegiskeni.degiskenDegeri, out saatMax);

                if (saatMax == 0)
                    saatMax = 1000;

                bool saatAraligiCheck = false;

                if (saat >= saatMin && saat < saatMax)
                {
                    saatAraligiCheck = true;
                }
                #endregion

                if (gunFarkiAraligiCheck)
                {
                    if (yasAraligiCheck)
                    {
                        if (saatAraligiCheck)
                        {

                            if (gerekenDegiskenlerLength > 0)
                            {
                                if (TekrarDegiskenleriKontrol(tumSohbetler[sohbetNumaralari[index]]))
                                {

                                    for (int i = 0; i < gerekenDegiskenlerLength; i++)
                                    {
                                        if (!jump)
                                        {
                                            string secilenSohbetDegiskenDegeri = PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[i].degiskenAdi);
                                            if (!string.IsNullOrEmpty(secilenSohbetDegiskenDegeri))
                                            {
                                                if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                                                {
                                                    if (secilenSohbetDegiskenleri[i].degiskenDegeri.ToLower() == secilenSohbetDegiskenDegeri)
                                                    {
                                                        if (i == gerekenDegiskenlerLength - 1)
                                                        {
                                                            if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                            {
                                                                //sohbetSecildi
                                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                            }
                                                            else 
                                                            {
                                                                if (tekrarSohbeti == null)
                                                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                sohbetNumaralari.RemoveAt(index);
                                                                secilenSohbet = null;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        bool breakUpperForLoop = false;
                                                        for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                        {
                                                            if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                            {
                                                                if (secilenSohbetDegiskenleri[a].degiskenDegeri.ToLower() == secilenSohbetDegiskenDegeri)
                                                                {
                                                                    if (i == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                                        {
                                                                            //sohbetSecildi
                                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                                        }
                                                                        else
                                                                        {
                                                                            if (tekrarSohbeti == null)
                                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                            sohbetNumaralari.RemoveAt(index);
                                                                            secilenSohbet = null;
                                                                        }
                                                                    }
                                                                    break;
                                                                }
                                                                else
                                                                {
                                                                    if (a == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        sohbetNumaralari.RemoveAt(index);
                                                                        secilenSohbet = null;

                                                                        breakUpperForLoop = true;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (a == gerekenDegiskenlerLength - 1)
                                                                {
                                                                    sohbetNumaralari.RemoveAt(index);
                                                                    secilenSohbet = null;

                                                                    breakUpperForLoop = true;
                                                                }
                                                            }
                                                        }
                                                        if (breakUpperForLoop)
                                                            break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                                                {
                                                    if (secilenSohbetDegiskenleri[i].degiskenDegeri.ToLower() != secilenSohbetDegiskenDegeri)
                                                    {
                                                        if (i == gerekenDegiskenlerLength - 1)
                                                        {
                                                            if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                            {
                                                                //sohbetSecildi
                                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                            }
                                                            else
                                                            {
                                                                if (tekrarSohbeti == null)
                                                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                sohbetNumaralari.RemoveAt(index);
                                                                secilenSohbet = null;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        bool breakUpperForLoop = false;
                                                        for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                        {
                                                            if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                            {
                                                                if (secilenSohbetDegiskenleri[a].degiskenDegeri.ToLower() != secilenSohbetDegiskenDegeri)
                                                                {
                                                                    if (i == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                                        {
                                                                            //sohbetSecildi
                                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                                        }
                                                                        else
                                                                        {
                                                                            if (tekrarSohbeti == null)
                                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                            sohbetNumaralari.RemoveAt(index);
                                                                            secilenSohbet = null;
                                                                        }
                                                                    }
                                                                    break;
                                                                }
                                                                else
                                                                {
                                                                    if (a == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        sohbetNumaralari.RemoveAt(index);
                                                                        secilenSohbet = null;

                                                                        breakUpperForLoop = true;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (a == gerekenDegiskenlerLength - 1)
                                                                {
                                                                    sohbetNumaralari.RemoveAt(index);
                                                                    secilenSohbet = null;

                                                                    breakUpperForLoop = true;
                                                                }
                                                            }
                                                        }
                                                        if (breakUpperForLoop)
                                                            break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(secilenSohbetDegiskenDegeri, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 > value2)
                                                    {
                                                        if (i == gerekenDegiskenlerLength - 1)
                                                        {
                                                            if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                            {
                                                                //sohbetSecildi
                                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                            }
                                                            else
                                                            {
                                                                if (tekrarSohbeti == null)
                                                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                sohbetNumaralari.RemoveAt(index);
                                                                secilenSohbet = null;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        bool breakUpperForLoop = false;
                                                        for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                        {
                                                            if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                            {
                                                                int.TryParse(secilenSohbetDegiskenleri[a].degiskenDegeri, out value2);
                                                                if (value1 > value2)
                                                                {
                                                                    if (i == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                                        {
                                                                            //sohbetSecildi
                                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                                        }
                                                                        else
                                                                        {
                                                                            if (tekrarSohbeti == null)
                                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                            sohbetNumaralari.RemoveAt(index);
                                                                            secilenSohbet = null;
                                                                        }
                                                                    }
                                                                    break;
                                                                }
                                                                else
                                                                {
                                                                    if (a == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        sohbetNumaralari.RemoveAt(index);
                                                                        secilenSohbet = null;

                                                                        breakUpperForLoop = true;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (a == gerekenDegiskenlerLength - 1)
                                                                {
                                                                    sohbetNumaralari.RemoveAt(index);
                                                                    secilenSohbet = null;

                                                                    breakUpperForLoop = true;
                                                                }
                                                            }
                                                        }
                                                        if (breakUpperForLoop)
                                                            break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(secilenSohbetDegiskenDegeri, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 < value2)
                                                    {
                                                        if (i == gerekenDegiskenlerLength - 1)
                                                        {
                                                            if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                            {
                                                                //sohbetSecildi
                                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                            }
                                                            else
                                                            {
                                                                if (tekrarSohbeti == null)
                                                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                sohbetNumaralari.RemoveAt(index);
                                                                secilenSohbet = null;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        bool breakUpperForLoop = false;
                                                        for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                        {
                                                            if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                            {
                                                                int.TryParse(secilenSohbetDegiskenleri[a].degiskenDegeri, out value2);
                                                                if (value1 < value2)
                                                                {
                                                                    if (i == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                                        {
                                                                            //sohbetSecildi
                                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                                        }
                                                                        else
                                                                        {
                                                                            if (tekrarSohbeti == null)
                                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                            sohbetNumaralari.RemoveAt(index);
                                                                            secilenSohbet = null;
                                                                        }
                                                                    }
                                                                    break;
                                                                }
                                                                else
                                                                {
                                                                    if (a == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        sohbetNumaralari.RemoveAt(index);
                                                                        secilenSohbet = null;

                                                                        breakUpperForLoop = true;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (a == gerekenDegiskenlerLength - 1)
                                                                {
                                                                    sohbetNumaralari.RemoveAt(index);
                                                                    secilenSohbet = null;

                                                                    breakUpperForLoop = true;
                                                                }
                                                            }
                                                        }
                                                        if (breakUpperForLoop)
                                                            break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(secilenSohbetDegiskenDegeri, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 >= value2)
                                                    {
                                                        if (i == gerekenDegiskenlerLength - 1)
                                                        {
                                                            if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                            {
                                                                //sohbetSecildi
                                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                            }
                                                            else
                                                            {
                                                                if (tekrarSohbeti == null)
                                                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                sohbetNumaralari.RemoveAt(index);
                                                                secilenSohbet = null;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        bool breakUpperForLoop = false;
                                                        for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                        {
                                                            if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                            {
                                                                int.TryParse(secilenSohbetDegiskenleri[a].degiskenDegeri, out value2);
                                                                if (value1 >= value2)
                                                                {
                                                                    if (i == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                                        {
                                                                            //sohbetSecildi
                                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                                        }
                                                                        else
                                                                        {
                                                                            if (tekrarSohbeti == null)
                                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                            sohbetNumaralari.RemoveAt(index);
                                                                            secilenSohbet = null;
                                                                        }
                                                                    }
                                                                    break;
                                                                }
                                                                else
                                                                {
                                                                    if (a == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        sohbetNumaralari.RemoveAt(index);
                                                                        secilenSohbet = null;

                                                                        breakUpperForLoop = true;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (a == gerekenDegiskenlerLength - 1)
                                                                {
                                                                    sohbetNumaralari.RemoveAt(index);
                                                                    secilenSohbet = null;

                                                                    breakUpperForLoop = true;
                                                                }
                                                            }
                                                        }
                                                        if (breakUpperForLoop)
                                                            break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(secilenSohbetDegiskenDegeri, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 <= value2)
                                                    {
                                                        if (i == gerekenDegiskenlerLength - 1)
                                                        {
                                                            if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                            {
                                                                //sohbetSecildi
                                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                            }
                                                            else
                                                            {
                                                                if (tekrarSohbeti == null)
                                                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                sohbetNumaralari.RemoveAt(index);
                                                                secilenSohbet = null;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        bool breakUpperForLoop = false;
                                                        for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                        {
                                                            if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                            {
                                                                int.TryParse(secilenSohbetDegiskenleri[a].degiskenDegeri, out value2);
                                                                if (value1 <= value2)
                                                                {
                                                                    if (i == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                                        {
                                                                            //sohbetSecildi
                                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                                        }
                                                                        else
                                                                        {
                                                                            if (tekrarSohbeti == null)
                                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                                            sohbetNumaralari.RemoveAt(index);
                                                                            secilenSohbet = null;
                                                                        }
                                                                    }
                                                                    break;
                                                                }
                                                                else
                                                                {
                                                                    if (a == gerekenDegiskenlerLength - 1)
                                                                    {
                                                                        sohbetNumaralari.RemoveAt(index);
                                                                        secilenSohbet = null;

                                                                        breakUpperForLoop = true;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (a == gerekenDegiskenlerLength - 1)
                                                                {
                                                                    sohbetNumaralari.RemoveAt(index);
                                                                    secilenSohbet = null;

                                                                    breakUpperForLoop = true;
                                                                }
                                                            }
                                                        }
                                                        if (breakUpperForLoop)
                                                            break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                //Yazılan kodun bir değişken değil de bir buton olması durumunun kontrolü için butonun değerine erişilir.
                                                string deger = "{{" + secilenSohbetDegiskenleri[i].degiskenAdi + "}}";
                                                deger = chatVariablesManager.OrtakButonlar(deger).ToLower();

                                                if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                                                {
                                                    if (secilenSohbetDegiskenleri[i].degiskenDegeri == "")
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else if (secilenSohbetDegiskenleri[i].degiskenDegeri.ToLower() == deger)
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sohbetNumaralari.RemoveAt(index);
                                                        secilenSohbet = null;

                                                        break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                                                {
                                                    if (secilenSohbetDegiskenleri[i].degiskenDegeri != "")
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else if (secilenSohbetDegiskenleri[i].degiskenDegeri.ToLower() != deger)
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sohbetNumaralari.RemoveAt(index);
                                                        secilenSohbet = null;

                                                        break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(deger, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 > value2)
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sohbetNumaralari.RemoveAt(index);
                                                        secilenSohbet = null;

                                                        break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(deger, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 < value2)
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sohbetNumaralari.RemoveAt(index);
                                                        secilenSohbet = null;

                                                        break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(deger, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 >= value2)
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sohbetNumaralari.RemoveAt(index);
                                                        secilenSohbet = null;

                                                        break;
                                                    }
                                                }
                                                else if (secilenSohbetDegiskenleri[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                                                {
                                                    int value1 = 0;
                                                    int value2 = 0;

                                                    int.TryParse(deger, out value1);
                                                    int.TryParse(secilenSohbetDegiskenleri[i].degiskenDegeri, out value2);

                                                    if (value1 <= value2)
                                                    {
                                                        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                                        {
                                                            //sohbetSecildi
                                                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]); 
                                                        }
                                                        else
                                                        {
                                                            if (tekrarSohbeti == null)
                                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                                            sohbetNumaralari.RemoveAt(index);
                                                            secilenSohbet = null;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sohbetNumaralari.RemoveAt(index);
                                                        secilenSohbet = null;

                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                }
                                else
                                {
                                    sohbetNumaralari.RemoveAt(index);
                                    secilenSohbet = null;

                                }
                            }
                            else
                            {
                                sohbetNumaralari.RemoveAt(index);
                                secilenSohbet = null;

                            }

                        }
                        else
                        {
                            sohbetNumaralari.RemoveAt(index);
                            secilenSohbet = null;

                        }
                    }
                    else
                    {
                        sohbetNumaralari.RemoveAt(index);
                        secilenSohbet = null;

                    }
                }
                else
                {
                    sohbetNumaralari.RemoveAt(index);
                    secilenSohbet = null;

                }
            }
            else
            {
                break;
            }
        }

        ileriAtilacakSohbetNumaralari.Sort();
        for (int i = 0; i < ileriAtilacakSohbetNumaralari.Count; i++)
        {
            modSohbetManager.MoveForwardChoosenSohbet(ileriAtilacakSohbetNumaralari[i]);

            for (int u = i + 1; u < ileriAtilacakSohbetNumaralari.Count; u++)
            {
                ileriAtilacakSohbetNumaralari[u] -= 1;
            }
        }
        if (herFramedekiKontSayisi >= tumSohbetler.Count)
        {
            if (secilenSohbet == null)
            {
                if (modListSohbetCount > 0)
                {
                    tumSohbetler = modSohbetManager.ChooseSohbetList();
                 
                    herFramedekiKontSayisi = 0;

                    if (secimYapildi.Count > 0)
                    {
                        if (secimYapildi[secimYapildi.Count - 1])
                        {
                            secimYapildi[secimYapildi.Count - 1] = false;
                        }
                    }
                }
                else
                {
                    if (tekrarSohbeti != null)
                    {
                        modSohbetManager.TekrarDegiskenleriniSifirla();
                        secilenSohbet = SohbetiSec(tekrarSohbeti);

                        PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Add(secilenSohbet.GetSohbetId().ToString());
                        tekrarSohbeti = null;
                    }
                    else
                    {
                        secilenSohbet = SohbetiSec(sohbetBulunamadiSohbeti);
                    }
                }
            }
        }

        return secilenSohbet;
    }

    Sohbet SohbetPickerDuzenlenmis()
    {
        int herFramedekiKontSayisiIlk = herFramedekiKontSayisi;
        herFramedekiKontSayisi += 20;

        if (herFramedekiKontSayisi > tumSohbetler.Count)
            herFramedekiKontSayisi = tumSohbetler.Count;

        List<int> sohbetNumaralari = new List<int>();
        //int tumSohbetlerFirstCount = modSohbetManager.TotalSohbetElementCount();
        for (int i = herFramedekiKontSayisiIlk; i < tumSohbetler.Count; i++)
        {
            sohbetNumaralari.Add(i);

        }
        Debug.LogWarning(sohbetNumaralari.Count);
        Sohbet secilenSohbet = null;

        List<int> ileriAtilacakSohbetNumaralari = new List<int>();
        for (int u = herFramedekiKontSayisiIlk; u < herFramedekiKontSayisi; u++)
        {
            //Eger daha onceki adimda bir sohbet secildiyse.
            if (secilenSohbet != null)
                break;

            //Random bir sohbeti kontrol etmek icin rastgele index secimi
            int index = Random.Range(0, sohbetNumaralari.Count);

            ileriAtilacakSohbetNumaralari.Add(sohbetNumaralari[index]);

            //Saat ve yas degiskenlerinin diger degiskenlerden ayrilmasi ve ozel degiskenlere atanmasi
            #region yasSaatGunFarkiDegiskenleriAyarlama
            //max minlerde maxlar dahil değil minler dahil
            List<Sohbet.GerekenDegisken> secilenSohbetDegiskenleri = new List<Sohbet.GerekenDegisken>();

            Sohbet.GerekenDegisken yasMaxDegiskeni = new Sohbet.GerekenDegisken();
            Sohbet.GerekenDegisken yasMinDegiskeni = new Sohbet.GerekenDegisken();

            Sohbet.GerekenDegisken saatMaxDegiskeni = new Sohbet.GerekenDegisken();
            Sohbet.GerekenDegisken saatMinDegiskeni = new Sohbet.GerekenDegisken();

            Sohbet.GerekenDegisken gunFarkiMaxDegiskeni = new Sohbet.GerekenDegisken();
            Sohbet.GerekenDegisken gunFarkiMinDegiskeni = new Sohbet.GerekenDegisken();

            foreach (Sohbet.GerekenDegisken element in tumSohbetler[sohbetNumaralari[index]].gerekliDegiskenler)
            {
                if (element.degiskenAdi != "yasmin")
                {
                    if (element.degiskenAdi != "yasmax")
                    {
                        if (element.degiskenAdi != "saatmin")
                        {
                            if (element.degiskenAdi != "saatmax")
                            {
                                if (element.degiskenAdi != "gunmin")
                                {
                                    if (element.degiskenAdi != "gunmax")
                                    {
                                        secilenSohbetDegiskenleri.Add(element);
                                    }
                                    else
                                    {
                                        gunFarkiMaxDegiskeni = element;
                                    }
                                }
                                else
                                {
                                    gunFarkiMinDegiskeni = element;
                                }
                            }
                            else
                            {
                                saatMaxDegiskeni = element;
                            }
                        }
                        else
                        {
                            saatMinDegiskeni = element;
                        }
                    }
                    else
                    {
                        yasMaxDegiskeni = element;
                    }
                }
                else
                {
                    yasMinDegiskeni = element;
                }
            }

            int gerekenDegiskenlerLength = secilenSohbetDegiskenleri.Count;

            //Yas
            int yas = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("yas"), out yas);

            int yasMin = 0;
            int yasMax = 100;
            int.TryParse(yasMinDegiskeni.degiskenDegeri, out yasMin);
            int.TryParse(yasMaxDegiskeni.degiskenDegeri, out yasMax);

            if (yasMax == 0)
                yasMax = 1000;

            bool yasAraligiCheck = false;

            if (yas >= yasMin && yas < yasMax)
            {
                yasAraligiCheck = true;
            }

            //Gun farki
            int gunFarki = 0;
            int.TryParse(PlayerDataManager.GetChatVariableValue("gun farki"), out gunFarki);//Bu degisken welcomeScreen classinda kaydedilir!

            int gunFarkiMin = 0;
            int gunFarkiMax = 100;
            int.TryParse(gunFarkiMinDegiskeni.degiskenDegeri, out gunFarkiMin);
            int.TryParse(gunFarkiMaxDegiskeni.degiskenDegeri, out gunFarkiMax);

            if (gunFarkiMax == 0)
                gunFarkiMax = int.MaxValue;

            bool gunFarkiAraligiCheck = false;

            if (gunFarki >= gunFarkiMin && gunFarki < gunFarkiMax)
            {
                gunFarkiAraligiCheck = true;
            }

            //Saat
            int saat = System.DateTime.Now.TimeOfDay.Hours;

            int saatMin = 0;
            int saatMax = 100;
            int.TryParse(saatMinDegiskeni.degiskenDegeri, out saatMin);
            int.TryParse(saatMaxDegiskeni.degiskenDegeri, out saatMax);

            if (saatMax == 0)
                saatMax = 1000;

            bool saatAraligiCheck = false;

            if (saat >= saatMin && saat < saatMax)
            {
                saatAraligiCheck = true;
            }
            #endregion

            bool hata = !gunFarkiAraligiCheck || !yasAraligiCheck ||
                !saatAraligiCheck || gerekenDegiskenlerLength <= 0;

            if (hata)
            {
                sohbetNumaralari.RemoveAt(index);
                secilenSohbet = null;
            }
            else
            {
                for (int i = 0; i < gerekenDegiskenlerLength; i++)
                {
                    string secilenSohbetDegiskenDegeri = PlayerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[i].degiskenAdi);
                    if (!string.IsNullOrEmpty(secilenSohbetDegiskenDegeri))
                    {
                        if (DegiskenKontrol(secilenSohbetDegiskenleri[i],
                            secilenSohbetDegiskenDegeri,
                            tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                        {

                            if (TekrarDegiskenleriKontrol(tumSohbetler[sohbetNumaralari[index]]))
                            {
                                if (i == gerekenDegiskenlerLength - 1)
                                {
                                    //sohbetSecildi
                                    secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]);
                                    break;
                                }
                            }
                            else
                            {
                                if (tekrarSohbeti == null)
                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                sohbetNumaralari.RemoveAt(index);
                                secilenSohbet = null;

                                break;
                            }
                        }
                        else
                        {
                            for (int a = 0; a < gerekenDegiskenlerLength; a++)
                            {
                                if (secilenSohbetDegiskenleri[i].degiskenAdi == secilenSohbetDegiskenleri[a].degiskenAdi)
                                {
                                    if (DegiskenKontrol(secilenSohbetDegiskenleri[a],
                                            secilenSohbetDegiskenDegeri,
                                            tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                                    {
                                        if (TekrarDegiskenleriKontrol(tumSohbetler[sohbetNumaralari[index]]))
                                        {
                                            if (a == gerekenDegiskenlerLength - 1)
                                            {
                                                //sohbetSecildi
                                                secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]);
                                                break;
                                            }
                                        }
                                        else
                                        {
                                            if (tekrarSohbeti == null)
                                                tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                            sohbetNumaralari.RemoveAt(index);
                                            secilenSohbet = null;
                                            i = gerekenDegiskenlerLength;
                                            break;
                                        }
                                    }
                                    else
                                    {
                                        if (a == gerekenDegiskenlerLength - 1)
                                        {
                                            sohbetNumaralari.RemoveAt(index);
                                            secilenSohbet = null;
                                            i = gerekenDegiskenlerLength;
                                        }
                                    }
                                }
                                else
                                {
                                    if (a == gerekenDegiskenlerLength - 1)
                                    {
                                        sohbetNumaralari.RemoveAt(index);
                                        secilenSohbet = null;
                                        i = gerekenDegiskenlerLength;
                                    }
                                }
                            }
                        }

                    }
                    else
                    {
                        //Yazılan kodun bir değişken değil de bir buton olması durumunun kontrolü için butonun değerine erişilir.
                        string deger = "{{" + secilenSohbetDegiskenleri[i].degiskenAdi + "}}";
                        deger = chatVariablesManager.OrtakButonlar(deger).ToLower();

                        if (DegiskenKontrol(secilenSohbetDegiskenleri[i],
                            deger,
                            tumSohbetler[sohbetNumaralari[index]].GetSohbetId()))
                        {
                            //sohbetSecildi
                            secilenSohbet = SohbetiSec(tumSohbetler[sohbetNumaralari[index]]);
                            break;
                        }
                        else
                        {
                            if (i == gerekenDegiskenlerLength - 1)
                            {
                                if (tekrarSohbeti == null)
                                    tekrarSohbeti = tumSohbetler[sohbetNumaralari[index]];

                                sohbetNumaralari.RemoveAt(index);
                                secilenSohbet = null;
                            }
                        }
                    }
                }
            }
        }

        ileriAtilacakSohbetNumaralari.Sort();
        for (int i = 0; i < ileriAtilacakSohbetNumaralari.Count; i++)
        {
            modSohbetManager.MoveForwardChoosenSohbet(ileriAtilacakSohbetNumaralari[i]);

            for (int u = i + 1; u < ileriAtilacakSohbetNumaralari.Count; u++)
            {
                ileriAtilacakSohbetNumaralari[u] -= 1;
            }
        }

        if (herFramedekiKontSayisi >= tumSohbetler.Count)
        {
            if (secilenSohbet == null)
            {
                if (modListSohbetCount > 0)
                {
                    tumSohbetler = modSohbetManager.ChooseSohbetList();
                    herFramedekiKontSayisi = 0;
                    if (secimYapildi.Count > 0)
                    {
                        if (secimYapildi[secimYapildi.Count - 1])
                        {
                            secimYapildi[secimYapildi.Count - 1] = false;
                        }
                    }
                }
                else
                {
                    if (tekrarSohbeti != null)
                    {
                        Debug.LogError("Tekrar sohbeti secildi!");
                        modSohbetManager.TekrarDegiskenleriniSifirla();
                        secilenSohbet = SohbetiSec(tekrarSohbeti);

                        PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Add(secilenSohbet.GetSohbetId().ToString());
                        tekrarSohbeti = null;
                    }
                    else
                    {
                        secilenSohbet = SohbetiSec(sohbetBulunamadiSohbeti);
                    }
                }
            }
        }

        return secilenSohbet;
    }

    private bool DegiskenKontrol(Sohbet.GerekenDegisken gerekenDegisken, string deger, string sohbetID)
    {
        if (gerekenDegisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
        {
            if (string.IsNullOrEmpty(gerekenDegisken.degiskenDegeri) ||
               gerekenDegisken.degiskenDegeri.ToLower() == deger)
            {
                return true;
            }
        }
        else if (gerekenDegisken.kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
        {
            if (string.IsNullOrEmpty(gerekenDegisken.degiskenDegeri) ||
               gerekenDegisken.degiskenDegeri.ToLower() != deger)
            {
                return true;
            }
        }
        else if (gerekenDegisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
        {
            int.TryParse(deger, out int value1);
            int.TryParse(gerekenDegisken.degiskenDegeri, out int value2);

            if (value1 > value2)
            {
                return true;
            }
        }
        else if (gerekenDegisken.kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
        {
            int.TryParse(deger, out int value1);
            int.TryParse(gerekenDegisken.degiskenDegeri, out int value2);

            if (value1 >= value2)
            {
                return true;
            }
        }
        else if (gerekenDegisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
        {
            int.TryParse(deger, out int value1);
            int.TryParse(gerekenDegisken.degiskenDegeri, out int value2);

            if (value1 < value2)
            {
                return true;
            }
        }
        else if (gerekenDegisken.kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
        {
            int.TryParse(deger, out int value1);
            int.TryParse(gerekenDegisken.degiskenDegeri, out int value2);

            if (value1 <= value2)
            {
                return true;
            }
        }

        return false;
    }

    /// <summary>Bu fonksiyon secilen sohbeti geri dondurur. Fakat bu sirada bazi islemler yuruturek
    ///SohbetPicker fonksiyonunda secilenSohbet assign edilirken bu islemlerin
    ///gerceklesmesini saglar. Dolayisiyla tek satirda islem yapilmis olur.</summary>
    /// <param name="secilenSohbet">Algoritmanin sectigi ve bu secimin ardindan aktif olabilmesi icin gerekli
    /// islemlerin yapilmasina ihtiyac duyan sohbet. Fonksiyon sonucun <b>AYNEN</b> geri dondurulur</param>
    Sohbet SohbetiSec(Sohbet secilenSohbet)
    {
        //Eger bu secilen sohbet ana sohbet ise
        if (aciklamasiEklenecekSohbetler.Count<1)
        {
            var sohbetModDegiskeni = secilenSohbet.gerekliDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));

            if (sohbetModDegiskeni != null)
                SaveLastMods(sohbetModDegiskeni.degiskenDegeri, secilenSohbet.GetSohbetId(), false);
        }
        else
        {
            var sohbetModDegiskeni = sohbet.gerekliDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));

            if (sohbetModDegiskeni != null)
                SaveLastMods(sohbetModDegiskeni.degiskenDegeri, secilenSohbet.GetSohbetId(), true);
        }

        tekrarSohbeti = null;
        TekrarlamaDegiskenleriniKaydet(secilenSohbet);
        BirlestirilecekModlariBaslat(secilenSohbet);

        for (int i = 0; i < secimYapildi.Count; i++)
        {
            if (secimYapildi[i] == false)
            {
                secimYapildi[i] = true;

                if (i < aciklamasiEklenecekSohbetler.Count)
                {
                    PlayerDataManager.AddElementToChatVariableList("mod", aciklamasiEklenecekSohbetler[i].mod);
                    modListSohbetCount = modSohbetManager.TotalSohbetElementCount();
                }

                if (i == secimYapildi.Count - 1)
                {
                    CheckModCounter();
                }

                break;
            }
        }

        return secilenSohbet;
    }

    /// <summary>
    /// Kullanicinin son mod istatistiklerini kaydeder.
    /// </summary>
    private void SaveLastMods(string mod, string sohbetID, bool birlestirilecekModaAit)
    {
        if (modUsageStat.mods.Exists(x => x.mod.Equals(mod)))
        {
            if (birlestirilecekModaAit)
            {
                var lastMode = PlayerDataManager.datas.falModlariIstatistik[^1];
                lastMode.sohbetIDleri.Add(sohbetID);
            }
            else
            {
                PlayerDataManager.datas.falModlariIstatistik.Add(new PlayerData.FalModlariIstatistik(mod, new List<string> { sohbetID }));
            }

            if (PlayerDataManager.datas.falModlariIstatistik.Count > 10)
                PlayerDataManager.datas.falModlariIstatistik.RemoveAt(0);
        }
    }

    /// <summary>Bu fonksiyon tekrarlama degiskenlerinin kaydini saglar. Bir kez gelen sohbetin uygulama kapatilip acilsa dahi
    ///tekrar gelememesi icin bunu playerData icindeki dahaOnceGelenSohbetlere kaydeder. Kayit islemi sohbet id'si
    ///  ile yapilir. Ayni zamanda sohbetin sohbetTekrarlama degiskeni ile her acilista. kullanici unutunca gibi
    /// durumlarda gelmesini de saglar.</summary>
    /// <param name="sohbet">Tekrar degiskenlerinin kontrol edilecegi sohbet</param>
    void TekrarlamaDegiskenleriniKaydet(Sohbet sohbet)
    {
        //dahaOnce geldi degiskeni kayit.
        if (!PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Contains(sohbet.GetSohbetId()))
            PlayerDataManager.localPlayerDatas.dahaOnceGelenSohbetler.Add(sohbet.GetSohbetId());

        if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.sonrakiAcilista)
        {
            PlayerDataManager.AddElementToChatVariableList(sohbet.GetSohbetId() + "buOturum", PlayerDataManager.GetChatVariableValue("oturumAcilisTarihi"), false);
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.sonrakiGun)
        {
            PlayerDataManager.AddElementToChatVariableList(sohbet.GetSohbetId() + "tarih", System.DateTime.Today.ToString(), false);
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.unutunca)
        {
            PlayerDataManager.AddElementToChatVariableList(sohbet.GetSohbetId() + "gun", System.DateTime.Now.Day.ToString(), false);
            PlayerDataManager.AddElementToChatVariableList(sohbet.GetSohbetId() + "ay", System.DateTime.Now.Month.ToString(), false);
            PlayerDataManager.AddElementToChatVariableList(sohbet.GetSohbetId() + "yil", System.DateTime.Now.Year.ToString(), false);
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.tekSefer)
        {
            PlayerDataManager.AddElementToChatVariableList(sohbet.GetSohbetId() + "tekSefer", "Secildi", false);
        }
    }

    //Bu fonksiyon her bir birlestirilecek mod icin secim algoritmasinin calisabilmesi
    //icin gerekli islemleri gerceklestirir.
    void BirlestirilecekModlariBaslat(Sohbet secilenSohbet)
    {
        foreach (string element in secilenSohbet.birlestirilecekModlar)
        {
            secimYapildi.Add(false);

            aciklamasiEklenecekSohbetler.Add(new AciklamaSohbetleri(element));
            herFramedekiKontSayisi = 0;
        }
    }

    bool TekrarDegiskenleriKontrol(Sohbet sohbet) 
    {
        bool returnValue = false;

        if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.surekli)
        {
            returnValue = true;
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.sonrakiAcilista)
        {
            if (PlayerDataManager.GetChatVariableValue(sohbet.GetSohbetId() + "buOturum") != PlayerDataManager.GetChatVariableValue("oturumAcilisTarihi"))
            {
                returnValue = true;
            }
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.sonrakiGun)
        {
            if (PlayerDataManager.GetChatVariableValue(sohbet.GetSohbetId() + "tarih") != System.DateTime.Today.ToString())
            {
                returnValue = true;
            }
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.unutunca)
        {
            int day = 1;
            int month = 1;
            int year = 2020;

            int.TryParse(PlayerDataManager.GetChatVariableValue(sohbet.GetSohbetId() + "gun"), out day);
            int.TryParse(PlayerDataManager.GetChatVariableValue(sohbet.GetSohbetId() + "ay"), out month);
            int.TryParse(PlayerDataManager.GetChatVariableValue(sohbet.GetSohbetId() + "yil"), out year);

            if (year <= 0)
            {
                day = 1;
                month = 1;
                year = 2020;
            }

            var dt = System.DateTime.Now;

            var targetDate = new System.DateTime(year, month, day, 0, 0, 0);
            if (System.Math.Abs((targetDate - dt).TotalDays) >= 40.0d)
            {
                returnValue = true;
            }
        }
        else if (sohbet.tekrarlama == Sohbet.sohbetTekrarlama.tekSefer)
        {
            if (PlayerDataManager.GetChatVariableValue(sohbet.GetSohbetId() + "tekSefer") != "Secildi")
            {
                returnValue = true;
            }
        }

        return returnValue;
    }

    public void StartChatManager(bool ozelGunVar)
    {
        if (!chatIsActive)
        {
            AcilisModunuAyarla(ozelGunVar);

            modListSohbetCount = modSohbetManager.TotalSohbetElementCount();

            tumSohbetler = modSohbetManager.ChooseSohbetList();
            //sohbet = SohbetPicker();

            chatIsActive = true;

            secimYapildi = new List<bool>();
            secimYapildi.Add(false);
            aciklamasiEklenecekSohbetler = new List<AciklamaSohbetleri>();
            spawned = false;
        }

        if (string.IsNullOrEmpty(PlayerDataManager.datas.profilePhotoLink))
        {
            PlayerDataManager.AddElementToChatVariableList("ozel profil foto", "hayır", false);
        }
        else
        {
            PlayerDataManager.AddElementToChatVariableList("ozel profil foto", "evet", false);
        }
    }

    public void StartChatManager(string mod)
    {
        if (!chatIsActive)
        {
            chatIsActive = true;
        }

        if (string.IsNullOrEmpty(PlayerDataManager.datas.profilePhotoLink))
        {
            PlayerDataManager.AddElementToChatVariableList("ozel profil foto", "hayır", false);
        }
        else
        {
            PlayerDataManager.AddElementToChatVariableList("ozel profil foto", "evet", false);
        }

        modListSohbetCount = modSohbetManager.TotalSohbetElementCount();
        tumSohbetler = modSohbetManager.ChooseSohbetList();

        secimYapildi = new List<bool>();
        secimYapildi.Add(false);
        aciklamasiEklenecekSohbetler = new List<AciklamaSohbetleri>();
        spawned = false;

        if (sohbet == null)
        {
            sohbet = new Sohbet();
            sohbet.sohbetBititmindeAnamenuyeDon = false;
        }

        ClickVirtualButton(mod);

        //Bu kisim ilerde kaldirilacak
        PlayerData.BugunGelenMod bugunGelenMod = PlayerDataManager.datas.bugunGelenMods.Find(x => x.mod.Equals(mod));
        if (bugunGelenMod == null)
            PlayerDataManager.datas.bugunGelenMods.Add(new PlayerData.BugunGelenMod(mod, 1));
        else
            bugunGelenMod.count += 1;
    }

    //Bu fonksiyon bos zamanda cok daha islevsel ve clean code olarak duzenlenecek.
    void AcilisModunuAyarla(bool ozelGunVar)
    {
        if (PlayerDataManager.datas.dahaOnceGeldi)
        {
            if (PlayerDataManager.GetChatVariableValue("oturum sayisi") == "1")
            {
                if (ozelGunVar)
                {
                    //OzelGun
                    PlayerDataManager.AddElementToChatVariableList("mod", "özelgün");
                }
                else
                {
                    float havadurumuSans = 20f;

                    if (havadurumuSans > Random.Range(0f, 100f) && !string.IsNullOrEmpty(PlayerDataManager.GetChatVariableValue("havadurumu main")))
                    {
                        //Havadurumu
                        PlayerDataManager.AddElementToChatVariableList("mod", "havadurumu");
                    }
                    else
                    {
                        PlayerDataManager.AddElementToChatVariableList("mod", "hoşgeldin");
                    }
                }
            }
            else
            {
                PlayerDataManager.AddElementToChatVariableList("mod", "hoşgeldin");
            }
        }
        else
        {
            PlayerDataManager.AddElementToChatVariableList("mod", "ilk geliş");
        }
    }

    public SpeechBubbleRight CreateRightBubble(int type, float delay)
    {
        writingAnimationDelayTimer = delay + 0.2f;

        //Objenin oluşturulması
        GameObject bubble = Instantiate(rightBubble, spawnPoint.position, Quaternion.identity);

        //gerekli yerel değişkenler
        RectTransform bubbleRect = bubble.GetComponent<RectTransform>();
        SpeechBubbleRight bubbleManager = bubble.GetComponent<SpeechBubbleRight>();

        //Objenin parent olarak canvastaki klasöre ayarlanması.
        bubbleRect.SetParent(bubbleParentObject);
        //Canvasın scale değeleri ekran boyutuna göre değiştiği için parent atamasından sonra objenin de scale değeleri değişecek. Bunu yeniden 1'e ayarlanıyor.
        //Bunun daha iyi yolları var. İlerde düzeltilecek.
        bubbleRect.localScale = new Vector3(1, 1, 1);

        //Bu bir sağ baloncuk olduğu için sağ balonun değeri olarak 0 a eşitlenmesi.
        //Bubbletype değişkeni şuan çok fazla işleve sahip. İlerde bu işlevler azaltılıp görevlerinin dağıtılması bu classlardaki karmaşıklığı azaltabilir.
        bubbleManager.bubbleType = type;
        //sağ baloncuk için kendini oluşturan objenin iki değşkeni çok önemli. Bunlar onu oluşturan cevap balonunun tipi ve varyasyonu. Tipi kaçıncı sıradaki cevap balonu olduğunu belirler.
        //Kaçıncı sırada ise sohbet ya da takipSohbet classlarının o cevap seçeneğinin seçildiği anlaşılır. Varyasyon ise o cevabın aynı anlama gelen hangi halinin seçilidiğini belirler.
        bubbleManager.answerBubbleType = lastAnswerBubbleType;
        bubbleManager.variation = lastAnswerVariation;

        bubbleManager.sohbet = sohbet;
        bubbleManager.chatManager = this;
        bubbleManager.takipSohbet = takipSobhet;
        bubbleManager.takipSohbetiAktif = takipSohbetiAktif;

        bubbleManager.profilePhoto.sprite = FindObjectOfType<WelcomeScreen>().ozetKullaniciFoto.sprite;
        //Bubblechatin text objelerinin ayarlanması.
        //Bu fonksiyonun tek görevi sohbet ya da takipSohbetten hangsi kullanılıyorsa onun textini objeye göndermesidir.
        bubbleManager.SetTextObjects();

        //Text objesinin yazısı atandıktan sonra çağrılan boyutlandırma fonksiyonu. Bu fonksiyonun textlerin atanmasından sorna çağrılması çok önemli. Çünkü text objesinin boyutlandırılması barındırdığı
        //Textin uzunluğuna ve satır sayısına göre yapılır. O yüzden önce textler ayarlanmalı sonra boyutlandırma yapılmalıdır.
        bubbleManager.SetFirstSizes();

        //*********************************
        //Ayrılarak belirtilmiş bu kısım çok önemlidir.
        //Bu kısımda önce objenin taggi bir değişkene atanır ardından tagg Untagged şeklinde değiştirilir.
        //Bunun sebebi yeni oluşan obje ile aynı taggde yani chatBubble taginde olan tüm bubbleların yukarı kaymasının istenmesi ama yeni oluşan obje için bunun istenmemesidir.
        string bubbleRealTag = "newBubble";
        bubbleRect.tag = "Untagged";
        float moveOffset = bubbleRect.rect.height + bubbleFrameBlank * 2 + spaceBetweenBubbles;
        StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
        StartCoroutine(BubbleFunctionDelay(() => ResetTags(bubbleRealTag, bubble), delay));
        //*********************************

        //Cevap seçeneğine tıklandıktan sonra kullanıcı mesaji bilgisayar mesaji ve cevap seçenekleri bubbleları olmak üzerek tüm bubblelar aynı anda oluşur. Fakat bunların ekrana gelme sırası farklıdır.
        //Bu objelerin isActive değişkeni oluştuktan sonra false olan bu değşiken true olana kadar bu objelerin ekranın dışında kalmasını sağlar.
        StartCoroutine(BubbleFunctionDelay(() =>
        {
            bubbleManager.isActive = true;
            bubbleManager.movable = true;
            bubbleManager.startTime = Time.time;
            bubbleManager.rt.DOMove(bubbleManager.targetPosition, bubbleManager.animationDuration);
            //bubbleManager.rt.SetParent(bubbleMover);
        }, delay));

        return bubbleManager;
    }

    public SpeechBubbleLeft CreateLeftBubble(int type, float delay, int variation, int contentIndex)
    {
        GameObject bubble = Instantiate(leftBubble, spawnPoint.position, Quaternion.identity);

        RectTransform bubbleRect = bubble.GetComponent<RectTransform>();
        SpeechBubbleLeft bubbleManager = bubble.GetComponent<SpeechBubbleLeft>();

        bubbleRect.SetParent(bubbleParentObject);
        bubbleRect.localScale = new Vector3(1, 1, 1);

        bubbleManager.bubbleType = type;
        bubbleManager.sohbet = sohbet;
        bubbleManager.chatManager = this;
        bubbleManager.contentIndex = contentIndex;
        bubbleManager.variation = variation;

        bubbleManager.takipSohbet = takipSobhet;
        bubbleManager.takipSohbetiAktif = takipSohbetiAktif;

        bubbleManager.sohbettenCikMetini = sohbettenCikMetni;
        sohbettenCikMetni = "";

        bubbleManager.SetTextObjects();
        bubbleManager.SetFirstSizes();




        bool isPercentilePanelMode = false;
        if (bubbleManager.text.text.Contains("{{barmenu}}") && sohbet.otomatikOdak)
        {
            string[] words = bubbleManager.text.text.Split(new string[] { "{{barmenu}}" }, System.StringSplitOptions.None);
            Debug.Log(words.Length);

            for (int i = 0; i < words.Length; i++)
            {
                if (!string.IsNullOrEmpty(words[i]))
                {
                    try
                    {
                        FindObjectOfType<PercentileManager>().SetActive(true, words[i], sohbet.contentImage.image);
                        otomatikOdak = true;
                        isPercentilePanelMode = true;
                    }
                    catch
                    {
                        Debug.LogError("Bar icin json datasi bulunamadi: " + words[i]);
                        Debug.LogError(bubbleManager.text.text);
                    }
                }
            }
        }


        string bubbleRealTag = "newBubble";
        bubbleRect.tag = "Untagged";
        float moveOffset = bubbleRect.rect.height + bubbleFrameBlank * 2 + spaceBetweenBubbles;

        StartCoroutine(BubbleFunctionDelay(() => {

            if (sohbet.contentImage.image != null)
            {
                if (sohbet.kazimaTipi == Sohbet.KazimaModuEnum.panel && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]))
                {
                    if (PlayerDataManager.GetChatVariableValue("mod") != "tefeul")
                        magnusScratch.OpenPanel(bubbleManager.realtedBubbles);
                }
            }
            else
            {
                if (sohbet.kazimaTipi == Sohbet.KazimaModuEnum.panel && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]) - 1)
                {
                    if (PlayerDataManager.GetChatVariableValue("mod") != "tefeul")
                        magnusScratch.OpenPanel(bubbleManager.realtedBubbles);
                }
            }

            if (sohbet.contentImage.image != null)
            {
                if (sohbet.otomatikOdak && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]))
                {
                    if (PlayerDataManager.GetChatVariableValue("mod") == "tefeul")
                        bubbleManager.OpenTefeulBook();
                }
            }
            else
            {
                if (sohbet.otomatikOdak && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]) - 1)
                {
                    if (PlayerDataManager.GetChatVariableValue("mod") == "tefeul")
                        bubbleManager.OpenTefeulBook();
                }

            }
        }, delay));

        if (PlayerDataManager.GetChatVariableValue("mod") == "tefeul")
        {
            if (sohbet.contentImage.image != null)
            {
                if (sohbet.otomatikOdak && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]))
                {
                    otomatikOdak = true;
                }
            }
            else
            {
                if (sohbet.otomatikOdak && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]) - 1)
                {
                    otomatikOdak = true;
                }
            }
            
        }

        if (sohbet.contentImage.image != null)
        {
            if (sohbet.kazimaTipi == Sohbet.KazimaModuEnum.panel && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]))
            {
                otomatikOdak = true;
            }
        }
        else
        {
            if (sohbet.kazimaTipi == Sohbet.KazimaModuEnum.panel && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]) - 1)
            {
                otomatikOdak = true;
            }
        }

        if (!sohbet.aciklamaBalonuYok)
        {
            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
        }

        StartCoroutine(BubbleFunctionDelay(() => ResetTags(bubbleRealTag, bubble), delay));
        StartCoroutine(BubbleFunctionDelay(() =>
        {
            bubbleManager.isActive = true;
            bubbleManager.movable = true; 
            bubbleManager.startTime = Time.time;
            bubbleManager.rt.DOMove(bubbleManager.targetPosition, bubbleManager.animationDuration);
            //bubbleManager.rt.SetParent(bubbleMover);
        }, delay));

        StartCoroutine(BubbleFunctionDelay(() => {

            if (sohbet.contentImage.image != null)
            {
                if (sohbet.otomatikOdak && !isPercentilePanelMode && 
                contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]))
                {
                    if (PlayerDataManager.GetChatVariableValue("mod").ToLower() != "tefeul")
                    {
                        if (tarotSohbetleri.Count<= 0)
                        {
                            PanelShowWholeTextManager.OpenPanel(bubbleManager.realtedBubbles, sohbet);
                        }
                        else
                        {
                            List<Sprite> tarotSprites = new List<Sprite>();
                            foreach (Sohbet tarotSohbeti in tarotSohbetleri)
                                tarotSprites.Add(tarotSohbeti.contentImage.image);
                            PanelShowWholeTextManager.OpenPanel(bubbleManager.realtedBubbles, sohbet, tarotSprites);
                            tarotSohbetleri = new List<Sohbet>();
                        }
                    }
                }
            }
            else
            {
                if (sohbet.otomatikOdak && !isPercentilePanelMode && 
                contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]) - 1)
                {
                    if (PlayerDataManager.GetChatVariableValue("mod").ToLower() != "tefeul")
                    {
                        if (tarotSohbetleri.Count <= 0)
                        {
                            PanelShowWholeTextManager.OpenPanel(bubbleManager.realtedBubbles, sohbet);
                        }
                        else
                        {
                            List<Sprite> tarotSprites = new List<Sprite>();
                            foreach (Sohbet tarotSohbeti in tarotSohbetleri)
                                tarotSprites.Add(tarotSohbeti.contentImage.image);
                            PanelShowWholeTextManager.OpenPanel(bubbleManager.realtedBubbles, sohbet, tarotSprites);
                            tarotSohbetleri = new List<Sohbet>();
                        }
                    }
                }
            }
        }, delay));

        if (PlayerDataManager.GetChatVariableValue("mod").ToLower() != "tefeul")
        {
            if (sohbet.contentImage.image != null)
            {
                if (sohbet.otomatikOdak && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]))
                {
                    otomatikOdak = true;
                }
            }
            else
            {
                if (sohbet.otomatikOdak && contentIndex == chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]) - 1)
                {
                    otomatikOdak = true;
                }
            }
        }
        return bubbleManager;
    }

    public AnswerBubble CreateAnswerBubble(int type, float delay, int positionType, int totalAvaliableAnswerBubbleCount)
    {

        GameObject bubble = Instantiate(answerBubble, spawnPoint.position, Quaternion.identity);

        RectTransform bubbleRect = bubble.GetComponent<RectTransform>();
        AnswerBubble bubbleManager = bubble.GetComponent<AnswerBubble>();

        bubbleRect.SetParent(bubbleParentObject);
        bubbleRect.localScale = new Vector3(1, 1, 1);

        // SetAnswerBubbleType(type, bubbleManager);

        bubbleManager.bubbleType = type;

        answerBubbles.Add(bubble);
        bubbleManager.sohbet = sohbet;
        bubbleManager.avaliableAnswerBubblesCount = totalAvaliableAnswerBubbleCount;
        bubbleManager.positionType = positionType;
        bubbleManager.chatManager = this;
        bubbleManager.kahveFalManager = kahveFalManager;

        bubbleManager.takipSohbet = takipSobhet;

        bubbleManager.SetTextObjects();
        bubbleManager.SetFirstSizes();


        string bubbleRealTag = "newBubble";
        bubbleRect.tag = "Untagged";
        float moveOffset = bubbleRect.rect.height + answerBubbleFrameBlank * 2 + spaceBetweenAnswerBubbles;

        if (IsPhotoMode())
        {
            switch (totalAvaliableAnswerBubbleCount)
            {
                case 1:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;
                    }
                    break;
                case 2:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:
                            
                            break;
                    }
                    break;

                case 3:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:

                            break;
                    }
                    break;

                case 4:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;
                        case 4:

                            break;

                    }
                    break;

                case 5:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:
                           
                            break;
                        case 4:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 5:

                            break;

                    }
                    break;

                case 6:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:

                            break;
                        case 4:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 5:

                            break;

                        case 6:

                            break;

                    }
                    break;

                case 7:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:

                            break;
                        case 4:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 5:
                     
                            break;

                        case 6:

                            break;

                        case 7:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                    }
                    break;

                case 8:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:

                            break;
                        case 4:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 5:
                      
                            break;

                        case 6:
                            
                            break;

                        case 7:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 8:

                            break;

                    }
                    break;
                case 9:
                    switch (positionType)
                    {
                        case 1:
                            if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                            {
                                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
                            }
                            else
                            {
                                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            }
                            break;

                        case 2:

                            break;

                        case 3:

                            break;
                        case 4:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 5:

                            break;

                        case 6:

                            break;

                        case 7:
                            StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
                            break;

                        case 8:

                            break;

                    }
                    break;
            }

        }
        else
        {
            if (positionType == 1 && (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText))
            {
                //asagidaki 19.4163 degeri timer barin dusey uzunlugudur. Bu kisim simdilik hard code
                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset + 19.4163f + 5f), delay));
            }
            else
            {
                StartCoroutine(BubbleFunctionDelay(() => MoveAllBubbles(moveOffset), delay));
            }
        }

        StartCoroutine(BubbleFunctionDelay(() => ResetTags(bubbleRealTag, bubble), delay));
        StartCoroutine(BubbleFunctionDelay(() =>
        {
            bubbleManager.isActive = true;
            bubbleManager.movable = true;
            bubbleManager.startTime = Time.time;
            bubbleManager.rt.DOMove(bubbleManager.targetPosition, bubbleManager.animationDuration);
            //bubbleManager.rt.SetParent(bubbleMover);
        }, delay));

        return bubbleManager;
    }                                                                                                                                                                         

    private IEnumerator clickAnswerBubbleIEnumerator;
    public void ClickAnswerBubble(Sohbet sonrakiSohbet, int type, int variation, bool createRightBubble)
    {
        if (clickAnswerBubbleIEnumerator != null)
        {
            StopCoroutine(clickAnswerBubbleIEnumerator);
        }
        clickAnswerBubbleIEnumerator = ClickAnswerBubbleCourotine(sonrakiSohbet, type, variation, createRightBubble);

        StartCoroutine(clickAnswerBubbleIEnumerator);
    }

    IEnumerator ClickAnswerBubbleCourotine(Sohbet sonrakiSohbet, int type, int variation, bool createRightBubble)
    {
        while (AiMessageDelay > 0)
        {
            yield return null;
        }

        AiMessageDelay = 0;
        secimYapildi = new List<bool>();
        secimYapildi.Add(false);
        spawned = false;

        PanelShowWholeTextManager showPanel = FindObjectOfType<PanelShowWholeTextManager>();

        Canvas.ForceUpdateCanvases();

        lastAnswerBubbleType = type;
        lastAnswerVariation = variation;

        AiMessageDelay += AddMessageDelay(0.2f, 0.4f);

        if (!sohbet.IsPhotographMode())
        {
            if (createRightBubble)
            {
                CreateRightBubble(type, AiMessageDelay = 0);
            }
        }
        else
        {
            SetCameraActivity(false);
        }

        float moveAmount = 0;
        int answerBubblesCount = answerBubbles.Count;
        for (int i = 0; i < answerBubblesCount; i++)
        {
            if (!sohbet.IsPhotographMode() && !sohbet.IsFilePickerMode())
            {
                RectTransform bubbleRect = answerBubbles[0].GetComponent<RectTransform>();
                float offset = -(bubbleRect.rect.height + answerBubbleFrameBlank * 2 + spaceBetweenAnswerBubbles);

                if (IsPhotoMode())
                {
                    switch (answerBubblesCount)
                    {
                        case 1:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;
                            }
                            break;

                        case 2:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:

                                    break;
                            }
                            break;

                        case 3:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:

                                    break;

                                case 3:

                                    break;
                            }
                            break;

                        case 4:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:

                                    break;

                                case 3:
                                    moveAmount += offset;
                                    break;
                                case 4:

                                    break;

                            }
                            break;

                        case 5:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:

                                    break;

                                case 3:
                                    moveAmount += offset;
                                    break;
                                case 4:

                                    break;

                            }
                            break;

                        case 6:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:

                                    break;

                                case 3:
                                    moveAmount += offset;
                                    break;
                                case 4:

                                    break;

                            }
                            break;

                        case 7:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:
                                    moveAmount += offset;
                                    break;

                                case 3:
                                    moveAmount += offset;
                                    break;
                                case 4:

                                    break;
                            }
                            break;

                        case 8:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:
                                    moveAmount += offset;
                                    break;

                                case 3:
                                    moveAmount += offset;
                                    break;
                                case 4:

                                    break;
                            }
                            break;
                        case 9:
                            switch (i + 1)
                            {
                                case 1:
                                    moveAmount += offset;
                                    break;

                                case 2:
                                    moveAmount += offset;
                                    break;

                                case 3:
                                    moveAmount += offset;
                                    break;
                                case 4:

                                    break;
                            }
                            break;
                    }
                }
                else
                {
                    moveAmount += offset;
                }

             
                Destroy(bubbleRect.gameObject);
                answerBubbles.RemoveAt(0);
          
            }
            else
            {
                AnswerBubble bubbleComponent = answerBubbles[0].GetComponent<AnswerBubble>();

                bubbleComponent.button.enabled = false;

                answerBubbles.RemoveAt(0);
            }
        }

        MoveAllBubbles(moveAmount);

        bool bugunGeldi = false;
        if (sohbet.cevaplar != null && type > 0 && type < sohbet.cevaplar.Count + 1)
        {
            if (sohbet.cevaplar.Count > 0)
            {
                if ((PlayerDataManager.datas.energy >= sohbet.cevaplar[type - 1].gerekenEnerjiKons.enerji
    && PlayerDataManager.datas.konsantrasyon >= sohbet.cevaplar[type - 1].gerekenEnerjiKons.kons))
                {
                    bugunGeldi = DegiskenleriKaydet(type - 1);
                }
                else
                {
                    var modSecenegi = sohbet.cevaplar[type - 1].ayarlananDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));

                    if (modSecenegi != null)
                    {
                        PreferencesObject.BugunGelenMod bugunGelenMod = magnusPreferences.gunlukModlar.Find(x => x.mod.Equals(modSecenegi.degiskenDegeri));
                        if (bugunGelenMod != null)
                        {
                            PlayerData.BugunGelenMod dataBugunGelenMod = PlayerDataManager.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));
                            if (dataBugunGelenMod != null)
                            {
                                if (PlayerDataManager.IsPlus)
                                {
                                    if (dataBugunGelenMod.count >= bugunGelenMod.countPlus)
                                    {
                                        PlayerDataManager.AddElementToChatVariableList("mod", modSecenegi.degiskenDegeri + "bugungeldi");
                                        bugunGeldi = true;
                                    }
                                }
                                else
                                {
                                    if (dataBugunGelenMod.count >= bugunGelenMod.count)
                                    {
                                        PlayerDataManager.AddElementToChatVariableList("mod", modSecenegi.degiskenDegeri + "bugungeldi");
                                        bugunGeldi = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                bugunGeldi = DegiskenleriKaydet(type - 1);
            }
        }
        else
        {
            bugunGeldi = DegiskenleriKaydet(type - 1);
        }

        //Bu kontrol degiksenleri kaydetin altinda ama mevcut sohbet yenisine esitlemden de once kontrol edilmeli
        if (introManager.chatBackgroundImage.gameObject.activeInHierarchy)
        {
            if (sohbet != null)
            {
                if (sohbet.cevaplar != null)
                {
                    if (PlayerDataManager.GetChatVariableValue("arkaplan") != "on" || sohbet.cevaplar.Count <= 0)
                    {
                        StartCoroutine(BubbleFunctionDelay(() =>
                        {
                            PlayerDataManager.AddElementToChatVariableList("arkaplan", "off", false);
                            introManager.chatBackgroundImage.gameObject.SetActive(false);
                        }, sohbet.arkaplanDelay));
                    }
                }
                else
                {
                    StartCoroutine(BubbleFunctionDelay(() =>
                    {
                        PlayerDataManager.AddElementToChatVariableList("arkaplan", "off", false);
                        introManager.chatBackgroundImage.gameObject.SetActive(false);
                    }, sohbet.arkaplanDelay));
                }
            }
        }


        //Sayac modu sohbet null'a ya da baska bir degere esitlenmeden hemen once kontrol edilmelidir!
        if (sohbet.sayacModu != "" && sohbetTimer<0)
        {
            PlayerDataManager.AddElementToChatVariableList("mod", sohbet.sayacModu);
        }
        sohbetTimer = 0;
        timerBackground.SetActive(false);
        kelebekLogo.SetActive(true);

        modListSohbetCount = modSohbetManager.TotalSohbetElementCount();

        if (sohbet.cevaplar != null && type > 0 && type < sohbet.cevaplar.Count + 1)
        {
            if (sohbet.cevaplar.Count > 0)
            {
                if (PlayerDataManager.GetChatVariableValue("plus") != "var")
                    if (sohbet.cevaplar[type - 1].reklamGoster)
                        FindObjectOfType<AdManager>().ShowInterstitial();

                if ((PlayerDataManager.datas.energy >= sohbet.cevaplar[type - 1].gerekenEnerjiKons.enerji
                    && PlayerDataManager.datas.konsantrasyon >= sohbet.cevaplar[type - 1].gerekenEnerjiKons.kons) || bugunGeldi)
                {
                    if (!bugunGeldi)
                    {
                        energyBarManager.AddEnergy(-sohbet.cevaplar[type - 1].gerekenEnerjiKons.enerji, 0);
                        konsantrasyonBarManager.AddEnergy(0, -sohbet.cevaplar[type - 1].gerekenEnerjiKons.kons);
                    }
                    if (sonrakiSohbet == null)
                    {
                        tumSohbetler = modSohbetManager.ChooseSohbetList();
                        sohbet = ChooseNewSohbet();
                        takipSobhet = null;
                        takipSohbetiAktif = false;
                        this.sonrakiSohbet = null;
                    }
                    else
                    {
                        takipSohbetiAktif = false;
                        takipSobhet = null;
                        sohbet = sonrakiSohbet;
                        secimYapildi = new List<bool>();
                        secimYapildi.Add(true);
                    }
                }
                else
                {
                    if (PlayerDataManager.datas.energy < sohbet.cevaplar[type - 1].gerekenEnerjiKons.enerji)
                    {
                        Sohbet.AyarlanacakDegisken modDegiskeni = sohbet.cevaplar[type - 1].ayarlananDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));
                        if (modDegiskeni != null)
                        {
                            reklamSonuModu = modDegiskeni.degiskenDegeri;
                            reklamSonuAzalacakEnerji = sohbet.cevaplar[type - 1].gerekenEnerjiKons.enerji;
                            reklamSonuAzalacakKons = sohbet.cevaplar[type - 1].gerekenEnerjiKons.kons;
                        }
                        else
                        {
                            reklamSonuModu = string.Empty;
                            reklamSonuAzalacakEnerji = 0;
                            reklamSonuAzalacakKons = 0;
                        }
                        takipSohbetiAktif = false;
                        takipSobhet = null;
                        sohbet = PlayerDataManager.GetChatVariableValue("plus") == "var" ? magnusPreferences.enerjiKalmadiPlus: magnusPreferences.enerjiKalmadi;
                        secimYapildi = new List<bool>();
                        secimYapildi.Add(true);
                    }
                    else if (PlayerDataManager.datas.konsantrasyon < sohbet.cevaplar[type - 1].gerekenEnerjiKons.kons)
                    {
                        Sohbet.AyarlanacakDegisken modDegiskeni = sohbet.cevaplar[type - 1].ayarlananDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));
                        if (modDegiskeni != null)
                        {
                            reklamSonuModu = string.Empty;
                            reklamSonuAzalacakEnerji = sohbet.cevaplar[type - 1].gerekenEnerjiKons.enerji;
                            reklamSonuAzalacakKons = sohbet.cevaplar[type - 1].gerekenEnerjiKons.kons;
                        }
                        else
                        {
                            reklamSonuModu = string.Empty;
                            reklamSonuAzalacakEnerji = 0;
                            reklamSonuAzalacakKons = 0;
                        }
                        takipSohbetiAktif = false;
                        takipSobhet = null;
                        sohbet = magnusPreferences.konsantrasyonKalmadi;
                        secimYapildi = new List<bool>();
                        secimYapildi.Add(true);
                    }
                }
            }
            else
            {
                if (sonrakiSohbet == null)
                {
                    tumSohbetler = modSohbetManager.ChooseSohbetList();
                    sohbet = ChooseNewSohbet();
                    takipSobhet = null;
                    takipSohbetiAktif = false;
                    this.sonrakiSohbet = null;
                }
                else
                {
                    takipSohbetiAktif = false;
                    takipSobhet = null;
                    sohbet = sonrakiSohbet;
                    secimYapildi = new List<bool>();
                    secimYapildi.Add(true);
                }
            }
        }
        else
        {
            if (sonrakiSohbet == null)
            {
                tumSohbetler = modSohbetManager.ChooseSohbetList();
                sohbet = ChooseNewSohbet();
                takipSobhet = null;
                takipSohbetiAktif = false;
                this.sonrakiSohbet = null;
            }
            else
            {
                takipSohbetiAktif = false;
                takipSobhet = null;
                sohbet = sonrakiSohbet;
                secimYapildi = new List<bool>();
                secimYapildi.Add(true);
            }
        }

        if (scratchQuiz.gameObject.activeInHierarchy && scratchQuiz.cardState != 2)
        {
            StartCoroutine(scratchQuiz.CancelCard());
        }
    }

    public void GunlukModlarHaricTutKontrol(string mod)
    {
        //Gunluk modlarin haric tutulan modlarindan birisine giderse yapilacaklar.
        int gunlukModIndex = magnusPreferences.gunlukModlar.FindIndex(x => x.exceptedMods.Contains(mod));
        if (gunlukModIndex >= 0)
        {
            int index = PlayerDataManager.datas.bugunGelenMods.FindIndex(x => x.mod.Equals(magnusPreferences.gunlukModlar[gunlukModIndex].mod));
            if (index >= 0)
            {
                PlayerDataManager.datas.bugunGelenMods[index].count--;
            }
        }
    }

    public void ClickVirtualButton(string mod)
    {
        PlayerDataManager.AddElementToChatVariableList("mod", mod);
        ClickAnswerBubble(null, 0, 0, false);
        anamenuyeGidebilir = false;
    }

    public bool IsPhotoMode()
    {
        bool value = false;

        //   if (!takipSohbetiAktif && sohbet.balonTipi == Sohbet.typeOfAnswerBubble.yanYana && sohbet.cevaplar.Count > 1 && sohbet.cevaplar.Count <= 9)
        if (!takipSohbetiAktif && sohbet.balonTipi == Sohbet.typeOfAnswerBubble.yanYana && sohbet.cevaplar.Count > 0)
        {
            for (int i = 0; i < sohbet.cevaplar.Count; i++)
            {
                if (sohbet.cevaplar[i].contentImage.image != null || !string.IsNullOrEmpty(sohbet.cevaplar[i].contentImage.imageId))
                {
                    value = true;
                    break;
                }
                else
                {
                    value = false;
                }
            }
        }
        return value;
    }

    //Sohbetin bugun gelip gelmediğini döndürür. İsmi işlevinden çok bağımsız. Bu fonksiyon bölünecek!
    bool DegiskenleriKaydet(int type)
    {
        bool bugunGeldi = false;

        string mod = PlayerDataManager.GetChatVariableValue("mod");

        if (sohbet.sohbetBitimModu != "")
        {
            PlayerDataManager.AddElementToChatVariableList("mod", sohbet.sohbetBitimModu);
        }

        if (type < sohbet.cevaplar.Count && type >= 0 && sohbet.cevaplar.Count > 0)
        {
            for (int i = 0; i < sohbet.cevaplar[type].ayarlananDegiskenler.Count; i++)
            {
                if (sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi == "mod")
                {

                    if (magnusPreferences.gunlukModlar.Count > 0)
                    {
                        for (int y = 0; y < magnusPreferences.gunlukModlar.Count; y++)
                        {
                            if (magnusPreferences.gunlukModlar[y].mod == sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri)
                            {
                                if (PlayerDataManager.datas.bugunGelenMods != null)
                                {
                                    if (PlayerDataManager.datas.bugunGelenMods.Count > 0)
                                    {
                                        for (int u = 0; u < PlayerDataManager.datas.bugunGelenMods.Count; u++)
                                        {
                                            if (PlayerDataManager.datas.bugunGelenMods[u].mod != sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri)
                                            {
                                                if (u == PlayerDataManager.datas.bugunGelenMods.Count - 1)
                                                {
                                                    if (PlayerDataManager.datas.energy >= sohbet.cevaplar[type].gerekenEnerjiKons.enerji && PlayerDataManager.datas.konsantrasyon >= sohbet.cevaplar[type].gerekenEnerjiKons.kons)
                                                    {
                                                        int modİndex = PlayerDataManager.datas.bugunGelenMods.FindIndex(x => x.mod.Equals(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri));
                                                        if (modİndex >= 0)
                                                            PlayerDataManager.datas.bugunGelenMods[modİndex] = (new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri, PlayerDataManager.datas.bugunGelenMods[modİndex].count + 1));
                                                        else
                                                            PlayerDataManager.datas.bugunGelenMods.Add(new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri));

                                                        PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                                                    }
                                                    y = magnusPreferences.gunlukModlar.Count;
                                                    i = sohbet.cevaplar[type].ayarlananDegiskenler.Count;
                                                    break;
                                                }
                                            }
                                            else
                                            {
                                                int modMaxCount = (PlayerDataManager.GetChatVariableValue("plus") == "var") ? magnusPreferences.gunlukModlar[y].countPlus : magnusPreferences.gunlukModlar[y].count;
                                                if (PlayerDataManager.datas.bugunGelenMods[u].count >= modMaxCount)
                                                {
                                                    PlayerDataManager.AddElementToChatVariableList("mod", sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri + "bugungeldi");
                                                    bugunGeldi = true;
                                                }
                                                else if (PlayerDataManager.datas.energy >= sohbet.cevaplar[type].gerekenEnerjiKons.enerji && PlayerDataManager.datas.konsantrasyon >= sohbet.cevaplar[type].gerekenEnerjiKons.kons)
                                                {
                                                    PlayerDataManager.datas.bugunGelenMods[u] = (new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri, PlayerDataManager.datas.bugunGelenMods[u].count + 1));

                                                    PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                                                }
                                                y = magnusPreferences.gunlukModlar.Count;
                                                i = sohbet.cevaplar[type].ayarlananDegiskenler.Count;
                                                break;
                                            }
                                        }
                                    }
                                    else
                                    {
                                        PlayerDataManager.datas.bugunGelenMods.Add(new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri));
                                        PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                                        i = sohbet.cevaplar[type].ayarlananDegiskenler.Count;
                                    }
                                }
                                else
                                {
                                    PlayerDataManager.datas.bugunGelenMods = new List<PlayerData.BugunGelenMod>() { new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri) };
                                    PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                                    i = sohbet.cevaplar[type].ayarlananDegiskenler.Count;
                                }

                                break;
                            }
                            else
                            {
                                if (y == magnusPreferences.gunlukModlar.Count - 1)
                                {
                                    int modİndex = PlayerDataManager.datas.bugunGelenMods.FindIndex(x => x.mod.Equals(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri));
                                    if (modİndex >= 0)
                                        PlayerDataManager.datas.bugunGelenMods[modİndex] = (new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri, PlayerDataManager.datas.bugunGelenMods[modİndex].count + 1));
                                    else
                                        PlayerDataManager.datas.bugunGelenMods.Add(new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri));

                                    PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                                }
                            }
                        }
                    }
                    else
                    {
                        PlayerDataManager.datas.bugunGelenMods.Add(new PlayerData.BugunGelenMod(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri));
                        PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                        break;
                    }
                }
                else
                {
                    //Bu kısım mod dışındkai değşikenlerin ayarlandığı kısımdır
                    if (sohbet.cevaplar[type].ayarlananDegiskenler[i].islem == Sohbet.AyarlanacakDegisken.Islem.esitleme)
                    {
                        PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                    }
                    else
                    {
                        float oldValue = 0;
                        float transactionValue = 0;
                        bool canUse = false;

                        if (float.TryParse(PlayerDataManager.GetChatVariableValue(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi), out oldValue)
                            || string.IsNullOrEmpty(PlayerDataManager.GetChatVariableValue(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi)))
                        {
                            if (float.TryParse(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri, out transactionValue)
                                || string.IsNullOrEmpty(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri))
                            {
                                canUse = true;
                            }
                        }

                        if (canUse)
                        {
                            if (sohbet.cevaplar[type].ayarlananDegiskenler[i].islem == Sohbet.AyarlanacakDegisken.Islem.toplama)
                                oldValue += transactionValue;
                            else if (sohbet.cevaplar[type].ayarlananDegiskenler[i].islem == Sohbet.AyarlanacakDegisken.Islem.cikartma)
                                oldValue -= transactionValue;
                            else if (sohbet.cevaplar[type].ayarlananDegiskenler[i].islem == Sohbet.AyarlanacakDegisken.Islem.carpma)
                                oldValue *= transactionValue;
                            else if (sohbet.cevaplar[type].ayarlananDegiskenler[i].islem == Sohbet.AyarlanacakDegisken.Islem.bolme)
                                oldValue /= transactionValue;

                            transactionValue = (float)System.Math.Round(transactionValue, 1);
                            PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, oldValue.ToString());
                        }
                        else
                        {
                            PlayerDataManager.AddElementToChatVariableList(sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenAdi, sohbet.cevaplar[type].ayarlananDegiskenler[i].degiskenDegeri);
                        }
                    }
                }
            }
        }


        if (magnusPreferences.counterMods.Exists(x => x.mod.Equals(mod)))
        {
            int dataIndex = PlayerDataManager.datas.counterModDatas.FindIndex(x => x.mod.Equals(mod));
            if (dataIndex >= 0)
            {
                if (modCounter >= magnusPreferences.GetModCounter(mod, PlayerDataManager.datas.counterModDatas[dataIndex].Value) && magnusPreferences.GetModCounter(mod, PlayerDataManager.datas.counterModDatas[dataIndex].Value) != -1)
                {
                    PlayerDataManager.AddElementToChatVariableList("mod", magnusPreferences.GetModCounterMod(mod, PlayerDataManager.datas.counterModDatas[dataIndex].Value));
                    PlayerDataManager.datas.counterModDatas[dataIndex].Value += 1;
                }
                else
                {
                    //Debug.Log(modCounter);
                    //Debug.Log(magnusPreferences.GetModCounter(mod, PlayerDataManager.datas.counterModDatas[dataIndex].value));
                }
            }
            else
            {
                PlayerDataManager.datas.counterModDatas.Add(new PlayerData.CounterModData(mod, 0));
            }
        }

        return bugunGeldi;
    }


    void MoveAllBubbles(float offset)
    {
        //scrollRectContentRt.position = new Vector3(scrollRectContainerRt.position.x, scrollRectContainerRt.position.y + ((scrollRectContentRt.sizeDelta.y) * canvasRect.localScale.y) / 2f, scrollRectContainerRt.position.z);
        allBubbles = GameObject.FindGameObjectsWithTag("ChatBubble");
        GameObject[] newBubbles = GameObject.FindGameObjectsWithTag("newBubble");

        if (newBubbles != null)
        {
            for (int i = 0; i < newBubbles.Length; i++)
            {
                if (newBubbles[i] != null)
                {

                    if (newBubbles[i].GetComponent<AnswerBubble>() != null)
                    {
                        AnswerBubble answerBubbleManager = newBubbles[i].GetComponent<AnswerBubble>();
                        answerBubbleManager.SetTargetPosition(new Vector3(answerBubbleManager.targetPosition.x, answerBubbleManager.targetPosition.y + offset * canvasRect.localScale.y, answerBubbleManager.targetPosition.z));
                        answerBubbleManager.movable = true;
                        answerBubbleManager.startTime = Time.time;
                        answerBubbleManager.rt.DOMove(answerBubbleManager.targetPosition, answerBubbleManager.animationDuration);
                    }
                    else if (newBubbles[i].GetComponent<SpeechBubbleRight>() != null)
                    {
                        SpeechBubbleRight rightBubbleManager = newBubbles[i].GetComponent<SpeechBubbleRight>();
                        rightBubbleManager.SetTargetPosition(new Vector3(rightBubbleManager.targetPosition.x, rightBubbleManager.targetPosition.y + offset * canvasRect.localScale.y, rightBubbleManager.targetPosition.z));
                        rightBubbleManager.movable = true;
                        rightBubbleManager.startTime = Time.time;
                        rightBubbleManager.rt.DOMove(rightBubbleManager.targetPosition, rightBubbleManager.animationDuration);
                    }
                    else if (newBubbles[i].GetComponent<SpeechBubbleLeft>() != null)
                    {
                        SpeechBubbleLeft leftBubbleManager = newBubbles[i].GetComponent<SpeechBubbleLeft>();
                        leftBubbleManager.SetTargetPosition(new Vector3(leftBubbleManager.targetPosition.x, leftBubbleManager.targetPosition.y + offset * canvasRect.localScale.y, leftBubbleManager.targetPosition.z));
                        leftBubbleManager.movable = true;
                        leftBubbleManager.startTime = Time.time;
                        leftBubbleManager.rt.DOMove(leftBubbleManager.targetPosition, leftBubbleManager.animationDuration);
                    }


                }
            }
        }

        previousBubbleMoverPos = new Vector3(previousBubbleMoverPos.x, previousBubbleMoverPos.y + offset * canvasRect.localScale.y, previousBubbleMoverPos.z);
        bubbleMover.DOMove(previousBubbleMoverPos, 0.215f);
        //bubbleParentObject.anchoredPosition = new Vector3(bubbleParentObject.anchoredPosition.x, bubbleParentObject.anchoredPosition.y + offset * canvasRect.localScale.y);
    }

    void MoveAllBubbles(float offset, bool movable)
    {
       
        //scrollRectContentRt.position = new Vector3(scrollRectContainerRt.position.x, scrollRectContainerRt.position.y + ((scrollRectContentRt.sizeDelta.y) * canvasRect.localScale.y) / 2f, scrollRectContainerRt.position.z);

        allBubbles = GameObject.FindGameObjectsWithTag("ChatBubble");

        if (allBubbles != null)
        {
            for (int i = 0; i < allBubbles.Length; i++)
            {
                if (allBubbles[i].GetComponent<AnswerBubble>() != null)
                {
                    AnswerBubble answerBubbleManager = allBubbles[i].GetComponent<AnswerBubble>();
                    answerBubbleManager.SetTargetPosition(new Vector3(answerBubbleManager.targetPosition.x, answerBubbleManager.targetPosition.y + offset * canvasRect.localScale.y, answerBubbleManager.targetPosition.z));
                    answerBubbleManager.movable = movable;
                    answerBubbleManager.startTime = Time.time;
                    DOTween.Kill(answerBubbleManager.gameObject);
                }
                else if (allBubbles[i].GetComponent<SpeechBubbleRight>() != null)
                {
                    SpeechBubbleRight rightBubbleManager = allBubbles[i].GetComponent<SpeechBubbleRight>();
                    rightBubbleManager.SetTargetPosition(new Vector3(rightBubbleManager.targetPosition.x, rightBubbleManager.targetPosition.y + offset * canvasRect.localScale.y, rightBubbleManager.targetPosition.z));
                    rightBubbleManager.movable = movable;
                    rightBubbleManager.startTime = Time.time;
                    DOTween.Kill(rightBubbleManager.gameObject);
                }
                else if (allBubbles[i].GetComponent<SpeechBubbleLeft>() != null)
                {
                    SpeechBubbleLeft leftBubbleManager = allBubbles[i].GetComponent<SpeechBubbleLeft>();
                    leftBubbleManager.SetTargetPosition(new Vector3(leftBubbleManager.targetPosition.x, leftBubbleManager.targetPosition.y + offset * canvasRect.localScale.y, leftBubbleManager.targetPosition.z));
                    leftBubbleManager.movable = movable;
                    leftBubbleManager.startTime = Time.time;
                    DOTween.Kill(leftBubbleManager.gameObject);
                }
            }
        }

        previousBubbleMoverPos = new Vector3(previousBubbleMoverPos.x, previousBubbleMoverPos.y + offset * canvasRect.localScale.y, previousBubbleMoverPos.z);
    }

    void SetAllBubblesMoveType() 
    {
        allBubbles = GameObject.FindGameObjectsWithTag("ChatBubble");

        if (allBubbles != null)
        {
            for (int i = 0; i < allBubbles.Length; i++)
            {
                if (allBubbles[i] != null)
                {
                    if (allBubbles[i].GetComponent<AnswerBubble>() != null)
                    {
                        AnswerBubble answerBubbleManager = allBubbles[i].GetComponent<AnswerBubble>();
                        answerBubbleManager.SetMovableFalse();
                    }
                    else if (allBubbles[i].GetComponent<SpeechBubbleRight>() != null)
                    {
                        SpeechBubbleRight rightBubbleManager = allBubbles[i].GetComponent<SpeechBubbleRight>();
                        rightBubbleManager.SetMovableFalse();
                    }
                    else if (allBubbles[i].GetComponent<SpeechBubbleLeft>() != null)
                    {
                        SpeechBubbleLeft leftBubbleManager = allBubbles[i].GetComponent<SpeechBubbleLeft>();
                        leftBubbleManager.SetMovableFalse();
                    }
                }
            }
        }
    }

    void ResetTags(string tag, GameObject obj)
    {
        if (obj != null)
        {
            obj.tag = tag;
        }
    }

    public delegate void CreateBubbleDelegate();

    private IEnumerator scrolStopIEnumerator;

    void ChatElementleriniBirlestir()
    {
        aciklamasiEklenecekSohbetler = new List<AciklamaSohbetleri>();
        string firstMod = PlayerDataManager.GetChatVariableValue("mod");
        if (sohbet.birlestirilecekModlar != null)
        {
            foreach(string element in sohbet.birlestirilecekModlar)
            {
                PlayerDataManager.AddElementToChatVariableList("mod", element);
                modListSohbetCount = modSohbetManager.TotalSohbetElementCount();
                //aciklamasiEklenecekSohbetler.Add(SohbetPicker());
            }
        }
        PlayerDataManager.AddElementToChatVariableList("mod", firstMod);
    }

    public void GetSpriteWithContentPhotoId()
    {
        if (chatVariablesManager.IfTextContainsRenderedTextKey(sohbet.aciklama[0]))
        {
            string contentPhotoId = chatVariablesManager.GetRenderedTextSpriteId(sohbet.aciklama[0]);
            Debug.Log(contentPhotoId);
            string[] words = contentPhotoId.Split(new string[] { "," }, System.StringSplitOptions.None);

            if (words.Length == 1)
            {
                if (!string.IsNullOrEmpty(contentPhotoId))
                {
                    Sprite contentSprite = FindObjectOfType<PhotoManager>().GetSprite(contentPhotoId);

                    if (contentSprite != null)
                    {
                        sohbet.contentImage.image = contentSprite;
                    }
                }
            }
            else if (words.Length == 3) //Tarot icin durum. Bu gecici ve cok cok acele berbat bir cozumdur. Ilerleyen zamanlarda coktu foto destegi eklenip KESINLIKLE kaldirilacak!!!
            {
                tarotSohbetleri = new List<Sohbet>() { ScriptableObject.CreateInstance<Sohbet>(), ScriptableObject.CreateInstance<Sohbet>(), ScriptableObject.CreateInstance<Sohbet>() };
                tarotSohbetleri[0].contentImage = new Sohbet.ContentImage();
                tarotSohbetleri[0].contentImage.image = FindObjectOfType<PhotoManager>().GetSprite(words[0]);

                tarotSohbetleri[1].contentImage = new Sohbet.ContentImage();
                tarotSohbetleri[1].contentImage.image = FindObjectOfType<PhotoManager>().GetSprite(words[1]);

                tarotSohbetleri[2].contentImage = new Sohbet.ContentImage();
                tarotSohbetleri[2].contentImage.image = FindObjectOfType<PhotoManager>().GetSprite(words[2]);

                Debug.Log(words[0] + words[1] + words[2]);
            }
        }
    }

    IEnumerator CreateChatElements()
    {
        modAyarlandi = false;

        GetSpriteWithContentPhotoId();

        //Ozel fonksiyon her zaman degisken kayitlarindan once calismalidir. Cunku sohbetteki bazi degiskenler ozel fonksiyon ile secildigi anda degistirilir!
        OzelFonksiyonAyarla();
        SaveVariablesAfterCreateSohbet();

        var adManager = FindObjectOfType<AdManager>();

        if (PlayerDataManager.GetChatVariableValue("plus") != "var")
            if (sohbet.reklam.type == Sohbet.Ad.Type.interstatial)
            if (sohbet.reklam.placement == Sohbet.Ad.Placement.sohbettenOnce)
                    adManager.ShowInterstitial();

        if (sohbet.reklam.type == Sohbet.Ad.Type.rewarded)
            if (sohbet.reklam.placement == Sohbet.Ad.Placement.sohbettenOnce)
            {
                adManager.rewardItem = sohbet.reklam.odul;
                adManager.ShowRewarded(() => { adManager.UserEarnedEnergyKons(); });
            }

        if (sohbet.kazima.kazimaTipi == Sohbet.Scratch.KazimaModuEnum.quiz)
        {
            scratchQuiz.contentImage.sprite = sohbet.kazima.image;
            scratchQuiz.contentPhotoId = sohbet.kazima.gifId;
            scratchQuiz.imageId= sohbet.kazima.imageId;
            scratchQuiz.succesPercentage = sohbet.kazima.kazimaOrani;
            scratchQuiz.mod = sohbet.kazima.kazimaModu;
            scratchQuiz.sohbet = sohbet.kazima.kazimaSohbeti;
            scratchQuiz.kazimaSonuBekleme = sohbet.kazima.kazimaSonuBekleme;
            scratchQuiz.OpenPanel();
        }

        if (sohbet.sohbetArkaplani != null)
        {
            if (sohbet.sohbetArkaplani.Count > 0 && PlayerDataManager.GetChatVariableValue("arkaplan") != "on")
            {
                introManager.chatBackgroundImage.sprite = sohbet.sohbetArkaplani[Random.Range(0, sohbet.sohbetArkaplani.Count)];
                introManager.chatBackgroundImage.gameObject.SetActive(true);
                PlayerDataManager.AddElementToChatVariableList("arkaplan", "on", false);
            }
        }
        dontShowWritingAnimation = false;

        if (scrolStopIEnumerator != null)
        {
            StopCoroutine(scrolStopIEnumerator);
        }

        scrollRectContainerRt.gameObject.GetComponent<Magnus.UI.ScrollRect>().enabled = false;

        List<int> availableAnswerBubbles = new List<int>();

        //Sohnet geri sayim sayaci simdilik bu fonkiyonda cagiriliyor. Ilerde yeri degisecek.
        if (sohbet != null)
        {
            sohbetTimer = sohbet.sayac;

            energyBarManager.AddEnergy(sohbet.sohbetEnerjisi, 0);
            konsantrasyonBarManager.AddEnergy(0, sohbet.sohbetKonsantrasyonu);

            if (sohbet.IsPhotographMode())
            {
                chatScreenActivityManager.SetBackButtonActivity(false);
            }
            else
            {
                chatScreenActivityManager.SetBackButtonActivity(true);
            }
        }

        for (int u = 0; u < sohbet.cevaplar.Count; u++)
        {
            bool onlineException = false;
            if (sohbet.cevaplar[u].ayarlananDegiskenler.Exists(x => x.degiskenAdi.Equals("mod")))
            {
                int index = sohbet.cevaplar[u].ayarlananDegiskenler.FindIndex(x => x.degiskenAdi.Equals("mod"));

                if (PlayerDataManager.localPlayerDatas.closedMods.Contains(sohbet.cevaplar[u].ayarlananDegiskenler[index].degiskenDegeri))
                {
                    onlineException = true;
                }
                else if (PlayerDataManager.GetChatVariableValue("plus") != "var")
                {
                    if (PlayerDataManager.localPlayerDatas.plusMods.Contains(sohbet.cevaplar[u].ayarlananDegiskenler[index].degiskenDegeri))
                    {
                        onlineException = true;
                    }
                }
            }

            if (!onlineException)
            {
                if (sohbet.cevaplar[u].gerekliDegiskenler != null)
                {
                    if (sohbet.cevaplar[u].gerekliDegiskenler.Count > 0)
                    {
                        for (int i = 0; i < sohbet.cevaplar[u].gerekliDegiskenler.Count; i++)
                        {
                            string secenekDegiskeniDegeri = PlayerDataManager.GetChatVariableValue(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi);
                            if (PlayerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)) 
                                || PlayerDataManager.yerelChatDegiskenleri.Exists(x => x.degiskenAdi.Equals(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)))
                            {
                                if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                                {
                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == secenekDegiskeniDegeri)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        bool breakUpperForLoop = false;
                                        for (int a = 0; a < sohbet.cevaplar[u].gerekliDegiskenler.Count; a++)
                                        {
                                            if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenAdi == sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)
                                            {
                                                if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenDegeri == secenekDegiskeniDegeri)
                                                {
                                                    if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        availableAnswerBubbles.Add(u);
                                                    }
                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        breakUpperForLoop = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                {
                                                    breakUpperForLoop = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (breakUpperForLoop)
                                            break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                                {
                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri != secenekDegiskeniDegeri)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        bool breakUpperForLoop = false;
                                        for (int a = 0; a < sohbet.cevaplar[u].gerekliDegiskenler.Count; a++)
                                        {
                                            if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenAdi == sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)
                                            {
                                                if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenDegeri != secenekDegiskeniDegeri)
                                                {
                                                    if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        availableAnswerBubbles.Add(u);
                                                    }
                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        breakUpperForLoop = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                {
                                                    breakUpperForLoop = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (breakUpperForLoop)
                                            break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(secenekDegiskeniDegeri, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (value1 >= value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        bool breakUpperForLoop = false;
                                        for (int a = 0; a < sohbet.cevaplar[u].gerekliDegiskenler.Count; a++)
                                        {
                                            if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenAdi == sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)
                                            {
                                                int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenDegeri, out value2);
                                                if (value1 >= value2)
                                                {
                                                    if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        availableAnswerBubbles.Add(u);
                                                    }
                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        breakUpperForLoop = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                {
                                                    breakUpperForLoop = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (breakUpperForLoop)
                                            break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(secenekDegiskeniDegeri, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (value1 <= value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        bool breakUpperForLoop = false;
                                        for (int a = 0; a < sohbet.cevaplar[u].gerekliDegiskenler.Count; a++)
                                        {
                                            if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenAdi == sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)
                                            {
                                                int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenDegeri, out value2);
                                                if (value1 <= value2)
                                                {
                                                    if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        availableAnswerBubbles.Add(u);
                                                    }
                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        breakUpperForLoop = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                {
                                                    breakUpperForLoop = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (breakUpperForLoop)
                                            break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(secenekDegiskeniDegeri, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (value1 > value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        bool breakUpperForLoop = false;
                                        for (int a = 0; a < sohbet.cevaplar[u].gerekliDegiskenler.Count; a++)
                                        {
                                            if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenAdi == sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)
                                            {
                                                int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenDegeri, out value2);
                                                if (value1 > value2)
                                                {
                                                    if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        availableAnswerBubbles.Add(u);
                                                    }
                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        breakUpperForLoop = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                {
                                                    breakUpperForLoop = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (breakUpperForLoop)
                                            break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(secenekDegiskeniDegeri, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (value1 < value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        bool breakUpperForLoop = false;
                                        for (int a = 0; a < sohbet.cevaplar[u].gerekliDegiskenler.Count; a++)
                                        {
                                            if (sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenAdi == sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi)
                                            {
                                                int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[a].degiskenDegeri, out value2);
                                                if (value1 < value2)
                                                {
                                                    if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        availableAnswerBubbles.Add(u);
                                                    }
                                                    break;
                                                }
                                                else
                                                {
                                                    if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                    {
                                                        breakUpperForLoop = true;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if (a == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                                {
                                                    breakUpperForLoop = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (breakUpperForLoop)
                                            break;
                                    }
                                }
                            }
                            else
                            {
                                string deger = chatVariablesManager.OrtakButonlar("{{" + sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenAdi + "}}").ToLower();

                                if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esit)
                                {
                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == "" || sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == deger)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.esitDegil)
                                {
                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == "" || sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri != deger)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyukEsit)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(deger, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == "" || value1 >= value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucukEsit)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(deger, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == "" || value1 <= value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.buyuk)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(deger, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == "" || value1 > value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                else if (sohbet.cevaplar[u].gerekliDegiskenler[i].kontrol == Sohbet.GerekenDegisken.Kontrol.kucuk)
                                {
                                    int value1 = 0;
                                    int value2 = 0;

                                    int.TryParse(deger, out value1);
                                    int.TryParse(sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri, out value2);

                                    if (sohbet.cevaplar[u].gerekliDegiskenler[i].degiskenDegeri == "" || value1 < value2)
                                    {
                                        if (i == sohbet.cevaplar[u].gerekliDegiskenler.Count - 1)
                                        {
                                            availableAnswerBubbles.Add(u);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        availableAnswerBubbles.Add(u);
                    }
                }
                else
                {
                    availableAnswerBubbles.Add(u);
                }
            }
        }

        if (sohbet.cevaplar.Count > 0)
        {
            if (availableAnswerBubbles.Count > 0)
            {
                List<SpeechBubbleLeft> relatedBubbles = new List<SpeechBubbleLeft>();
                int variation = Random.Range(0, sohbet.aciklama.Count);

                if (chatVariablesManager.IsBubbleSlint(sohbet.aciklama[variation]))
                {
                    dontShowWritingAnimation = true;
                }

                for (int i = 0; i < chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]); i++)
                {
                    if (!sohbet.aciklamaBalonuYok)
                        AiMessageDelay += AddMessageDelay(sohbet.aciklama[variation], i) + chatVariablesManager.GetNewBubbleDelayCount(sohbet.aciklama[variation], i - 1);

                    yield return new WaitForSeconds(Time.deltaTime * 5f);
                    relatedBubbles.Add(CreateLeftBubble(0, AiMessageDelay, variation, i));
                }

                if (sohbet.contentImage.image != null || !string.IsNullOrEmpty(sohbet.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
                {
                    if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaBasta || sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaSonda)
                    {
                        variation = Random.Range(0, sohbet.aciklama.Count);
                        if (!sohbet.aciklamaBalonuYok)
                            AiMessageDelay += AddMessageDelay(0.5f, 2f);
                        yield return new WaitForSeconds(Time.deltaTime * 5f);
                        relatedBubbles.Add(CreateLeftBubble(0, AiMessageDelay, variation, chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation])));
                    }
                }
                foreach (SpeechBubbleLeft element in relatedBubbles)
                {
                    element.realtedBubbles = relatedBubbles;
                }

                int spawnedBubbkleNumber = 0;
                for (int i = 0; i < sohbet.cevaplar.Count; i++)
                {
                    if (availableAnswerBubbles.Contains(i))
                    {
                        spawnedBubbkleNumber += 1;
                        AiMessageDelay += .15f;
                        yield return new WaitForSeconds(Time.deltaTime * 5f);
                        CreateAnswerBubble(i + 1, AiMessageDelay, spawnedBubbkleNumber, availableAnswerBubbles.Count);
                    }
                }

                if (sohbet.anaMenuyeGitButonuOlustur && sohbet.balonTipi == Sohbet.typeOfAnswerBubble.altAlta && !sohbet.IsPhotographMode())
                {
                    spawnedBubbkleNumber += 1;
                    AiMessageDelay += 0.3f;
                    yield return new WaitForSeconds(Time.deltaTime * 5f);
                    CreateAnswerBubble(sohbet.cevaplar.Count + 1, AiMessageDelay, spawnedBubbkleNumber, availableAnswerBubbles.Count);
                }
                takipSohbetNumarasi = 0;
            }
            else
            {
                float x = Random.Range(0f, 100f);
                if (x >= 100f - sohbet.gostermeSansi)
                {
                    List<SpeechBubbleLeft> relatedBubbles = new List<SpeechBubbleLeft>();
                    int variation = Random.Range(0, sohbet.aciklama.Count);

                    if (chatVariablesManager.IsBubbleSlint(sohbet.aciklama[variation]))
                    {
                        dontShowWritingAnimation = true;
                    }

                    for (int i = 0; i < chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]); i++)
                    {
                        if (!sohbet.aciklamaBalonuYok)
                            AiMessageDelay += AddMessageDelay(sohbet.aciklama[variation], i) + chatVariablesManager.GetNewBubbleDelayCount(sohbet.aciklama[variation], i - 1);
                        yield return new WaitForSeconds(Time.deltaTime * 5f);
                        relatedBubbles.Add(CreateLeftBubble(0, AiMessageDelay, variation, i));
                    }
                    if (sohbet.contentImage.image != null || !string.IsNullOrEmpty(sohbet.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
                    {
                        if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaBasta || sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaSonda)
                        {
                            variation = Random.Range(0, sohbet.aciklama.Count);
                            if (!sohbet.aciklamaBalonuYok)
                                AiMessageDelay += AddMessageDelay(0.5f, 2f);
                            yield return new WaitForSeconds(Time.deltaTime * 5f);
                            relatedBubbles.Add(CreateLeftBubble(0, AiMessageDelay, variation, chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation])));
                        }
                    }
                    foreach (SpeechBubbleLeft element in relatedBubbles)
                    {
                        element.realtedBubbles = relatedBubbles;
                    }
                }
                takipSohbetNumarasi += 1;
                //StartCoroutine(FunctionDelay(() => ClickAnswerBubble(null, 0, 0, false), AiMessageDelay + sohbet.sayac + 0.5f));
            }
        }
        else
        {
            float x = Random.Range(0f, 100f);
            if (x >= 100f - sohbet.gostermeSansi)
            {
                List<SpeechBubbleLeft> relatedBubbles = new List<SpeechBubbleLeft>();
                int variation = Random.Range(0, sohbet.aciklama.Count);

                if (chatVariablesManager.IsBubbleSlint(sohbet.aciklama[variation]))
                {
                    dontShowWritingAnimation = true;
                }

                for (int i = 0; i < chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation]); i++)
                {
                    if (!sohbet.aciklamaBalonuYok)
                        AiMessageDelay += AddMessageDelay(sohbet.aciklama[variation], i) + chatVariablesManager.GetNewBubbleDelayCount(sohbet.aciklama[variation], i - 1);
                    yield return new WaitForSeconds(Time.deltaTime * 5f);
                    relatedBubbles.Add(CreateLeftBubble(0, AiMessageDelay, variation, i));
                }
                if (sohbet.contentImage.image != null || !string.IsNullOrEmpty(sohbet.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
                {
                    if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaBasta || sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaSonda)
                    {
                        variation = Random.Range(0, sohbet.aciklama.Count);
                        if (!sohbet.aciklamaBalonuYok)
                            AiMessageDelay += AddMessageDelay(0.5f, 2f);
                        yield return new WaitForEndOfFrame();
                        relatedBubbles.Add(CreateLeftBubble(0, AiMessageDelay, variation, chatVariablesManager.GetBubbleCount(sohbet.aciklama[variation])));
                    }
                }
                foreach (SpeechBubbleLeft element in relatedBubbles)
                {
                    element.realtedBubbles = relatedBubbles;
                }
            }
            takipSohbetNumarasi += 1;
            //StartCoroutine(FunctionDelay(() => ClickAnswerBubble(null, 0, 0, false), AiMessageDelay + sohbet.sayac + 0.5f));
        }

        //Bu satirin yeri cok onemli!!!
        aciklamasiEklenecekSohbetler = new List<AciklamaSohbetleri>();

        SetWritingTimer(AiMessageDelay - 0.5f);
        AiMessageDelay += 0.2f;

        if (sohbet.kazimaTipi != Sohbet.KazimaModuEnum.quiz)
        {
            AiMessageDelay += scratchQuiz.kazimaSonuBekleme;
            scratchQuiz.kazimaSonuBekleme = 0;
        }

        //scrolStopIEnumerator = StopScrollDelay(AiMessageDelay + sohbet.sayac, availableAnswerBubbles);
        scrolStopIEnumerator = StopScrollDelay(AiMessageDelay, availableAnswerBubbles);
        StartCoroutine(scrolStopIEnumerator);
        AiMessageDelay += 0.5f;
    }

    void SaveVariablesAfterCreateSohbet()
    {
        if (!PlayerDataManager.datas.dahaOnceGeldi)
        {
            if (magnusPreferences.ilkGelisSonlari.Contains(sohbet))
            {
                PlayerDataManager.datas.dahaOnceGeldi = true;
            }
        }
    }

    void SohbetayarlananDegiskenleriniAyarla()
    {
        if (sohbet.ayarlananDegiskenler != null)
        {
            foreach (Sohbet.AyarlanacakDegisken ayalanacakDegisken in sohbet.ayarlananDegiskenler)
            {
                PlayerDataManager.AddElementToChatVariableList(ayalanacakDegisken.degiskenAdi, ayalanacakDegisken.degiskenDegeri);
            }
        }
    }

    void CheckModCounter()
    {
        string mod = PlayerDataManager.GetChatVariableValue("mod");

        int modIndex = magnusPreferences.counterMods.FindIndex(x => x.mod.Equals(mod));
        int lastModIndex = magnusPreferences.counterMods.FindIndex(x => x.mod.Equals(lastCounterMod));

        if (modIndex >= 0)
        {
            modCounter += 1;
            lastCounterMod = mod;
        }
        else if (lastCounterMod != mod)
        {
            if (lastModIndex >= 0)
            {
                if (magnusPreferences.counterMods[lastModIndex].yanModlar.Contains(mod))
                {
                    //modCounter = 0;
                    Debug.Log("Counter yan moduna geçildiği için counter duraklatıldı. Başka bir moda geçmeden geri dönülürse devam edecek.");
                }
                else
                {
                    modCounter = 0;
                }
            }
            else
            {
                modCounter = 0;
            }
        }

        /*
        for (int i = 0; i < magnusPreferences.counterMods.Count; i++)
        {
            if (mod == magnusPreferences.counterMods[i].mod)
            {
                modCounter += 1;
                lastCounterMod = mod;
                break;
            }
            else if (i == magnusPreferences.counterMods.Count - 1 && lastCounterMod != PlayerDataManager.GetChatVariableValue("mod"))
            {
                modCounter = 0;
            }
        }*/

        PlayerDataManager.AddElementToChatVariableList("mod counter", modCounter.ToString(), false);
    }
    void OzelFonksiyonAyarla()
    {
        OzelFonksiyonlar();
    }

    void OzelFonksiyonlar()
    {
        if (sohbet.ozelFonksiyon == "uygulamayı değerlendir")
        {
            OzelFonksiyonManager.UygulamayiDegerlendir();
        }
        else if (sohbet.ozelFonksiyon == "uygulamadn çık")
        {
            OzelFonksiyonManager.UygulamayiKapat();
        }
        else if (sohbet.ozelFonksiyon == "ilk geliş tamamlandı")
        {
            OzelFonksiyonManager.IlkGelisTamam();
        }
        else if (sohbet.ozelFonksiyon == "bilgi ekranina git")
        {
            PlayerDataManager.AddElementToChatVariableList("mod", "bilgi ekrani");
            OzelFonksiyonManager.BilgiEkraninaGit();
        }
        else if (sohbet.ozelFonksiyon == "kahve fali video")
        {
            kahveFalManager.KahveFaliArkaplanAyarla(true);
        }
        else if (sohbet.ozelFonksiyon == "fireworks")
        {
            FindObjectOfType<OzelFonksiyonManager>().FireWork();
        }
        else if (sohbet.ozelFonksiyon == "tarot falı ayarla")
        {
            FindObjectOfType<OzelFonksiyonManager>().TarotFaliAyarla();
        }
        else if (sohbet.ozelFonksiyon == OzelFonksiyonManager.tarotMenuButonDegiskenleriAyarla)
        {
            FindObjectOfType<OzelFonksiyonManager>().TarotMenuButonlarDegiskenleriAyarla(sohbet);
        }
        else if (sohbet.ozelFonksiyon == "tarot geçmiş sohbeti başlat")
        {
            FindObjectOfType<OzelFonksiyonManager>().TarotGecmisBaslat();
        }
        else if (sohbet.ozelFonksiyon == "tarot şimdi sohbeti başlat")
        {
            Debug.Log("tarot şimdi sohbeti başlat");
            FindObjectOfType<OzelFonksiyonManager>().TarotSimdiBaslat();
        }
        else if (sohbet.ozelFonksiyon == "tarot gelecek sohbeti başlat")
        {
            FindObjectOfType<OzelFonksiyonManager>().TarotGelecekBaslat();
        }
        else if (sohbet.ozelFonksiyon == "tarot tüm sohbeti başlat")
        {
            FindObjectOfType<OzelFonksiyonManager>().TarotGecmisBaslat();
        }
    }

    float AddMessageDelay(string text)
    {
        float returnValue = 0;
        if (!magnusPreferences.yazmaSureleriniSifirla || !Application.isEditor)
        {
            text = chatVariablesManager.OrtakButonlar(text);
            returnValue = (text.ToCharArray().Length / (15f * magnusPreferences.yazmaSuresiCarpani));

            //Magnusun da gercek bir insanda olacagi gibi ayni paragrafi her yazdigi seferde ufak farklar olusmasini istedigimiz icin yazdigi yazinin yazilma suresi ile orantili random bir sayi ekliyoruz.
            returnValue += Random.Range(0f, returnValue / 5f);
        }
        else
        {
            returnValue += Random.Range(0f, 0.5f);
        }
        return returnValue;
    }

    float AddMessageDelay(string text, int contentIndex)
    {
        float returnValue = 0;

        float minReturnValue = Random.Range(0.1f, 0.5f);
        float maxReturnValue = Random.Range(5f, 10f);
        
        if (!magnusPreferences.yazmaSureleriniSifirla || !Application.isEditor)
        {
            text = ReplaceChatVariables(text, contentIndex);
            returnValue = (text.ToCharArray().Length / (15f * magnusPreferences.yazmaSuresiCarpani));

            //Magnusun da gercek bir insanda olacagi gibi ayni paragrafi her yazdigi seferde ufak farklar olusmasini istedigimiz icin yazdigi yazinin yazilma suresi ile orantili random bir sayi ekliyoruz.
            returnValue += Random.Range(0f, returnValue / 5f);

            if (returnValue > maxReturnValue)
                returnValue = maxReturnValue;
            else if (returnValue < minReturnValue)
                returnValue = minReturnValue;
        }
        else
        {
            returnValue += Random.Range(0f, 0.5f);
        }

        return returnValue;
    }

    float AddMessageDelay(float delayMin, float delayMax)
    {
        float returnValue = 0;
        if (!magnusPreferences.yazmaSureleriniSifirla || !Application.isEditor)
        {
            returnValue += Random.Range(delayMin, delayMax);
        }
        else
        {
            returnValue += Random.Range(0.1f, 0.25f);
        }
        return returnValue;
    }

    public string ReplaceChatVariables(string text, int contentIndex)
    {
        //Bu degisken texti belirledigi icin ilk basta kontrol edilir.
        text = chatVariablesManager.NewBubble(text, contentIndex);

        text = chatVariablesManager.OrtakButonlar(text);

        return text;
    }

    void InitiazeTimerSohbet()
    {
        ClickAnswerBubble(sohbet.sayacSohbeti, 0, 0, false);

    }

    void TakipSohbettenCik()
    {
        secimYapildi = new List<bool>();
        secimYapildi.Add(false);
        spawned = false;

        if (sohbet.sohbetBitimModu != "")
        {
            PlayerDataManager.AddElementToChatVariableList("mod", sohbet.sohbetBitimModu);
            modListSohbetCount = modSohbetManager.TotalSohbetElementCount();
        }
        tumSohbetler = modSohbetManager.ChooseSohbetList();

        sohbet = ChooseNewSohbet();
        takipSobhet = null;
        takipSohbetiAktif = false;
    }

    public IEnumerator FunctionDelay(CreateBubbleDelegate createBubbleFunction, float delay)
    {
        yield return new WaitForSeconds(delay);
        createBubbleFunction();
    }

    public IEnumerator BubbleFunctionDelay( CreateBubbleDelegate createBubbleFunction, float delay)
    {
        while (otomatikOdak)
        {
            yield return null;
        }
        yield return new WaitForSeconds(delay);
        createBubbleFunction();
    }

    void SetScrollRectSize()
    {
        RectTransform topBubble = new RectTransform();

        /*
        for (int i = 0; i < allBubbles.Length; i++)
        {
            if (allBubbles[i] != null)
            {
                RectTransform currentBubble = allBubbles[i].GetComponent<RectTransform>();
                if (topBubble != null)
                {
                    if (topBubble.position.y < currentBubble.position.y) 
                    {
                        topBubble = currentBubble;
                    }
                }
                else
                {
                    topBubble = currentBubble;
                }
            }
        }*/

        if (bubbleMover.childCount > 0)
        {
            topBubble = bubbleMover.GetChild(0).GetComponent<RectTransform>();
            float newSize = canvasRect.sizeDelta.y + (topBubble.position.y / canvasRect.localScale.y - canvasRect.sizeDelta.y);
            if (newSize + 125f * canvasRect.localScale.y > canvasRect.sizeDelta.y)
            {
                scrollRectContentRt.sizeDelta = new Vector2(scrollRectContentRt.sizeDelta.x, newSize + 125f * canvasRect.localScale.y);
            }
            else
            {
                scrollRectContentRt.sizeDelta = new Vector2(scrollRectContentRt.sizeDelta.x, canvasRect.sizeDelta.y);
            }
        }
        else
        {
            scrollRectContentRt.sizeDelta = new Vector2(scrollRectContentRt.sizeDelta.x, canvasRect.sizeDelta.y);
        }

        Vector3 bubbleMoverOldPos = bubbleMover.position;
        scrollRectContentRt.position = new Vector3(scrollRectContentRt.position.x, (scrollRectContentRt.sizeDelta.y / 2f + scrollOfftet) * canvasRect.localScale.y, scrollRectContentRt.position.z);
        bubbleMover.position = bubbleMoverOldPos;
    }

    IEnumerator StopScrollDelay(float delay, List<int> availableAnswerBubbles)
    {
        while (otomatikOdak)
        {
            yield return null;
        }
        yield return new WaitForSeconds(delay + 0.3f);

        var adManager = FindObjectOfType<AdManager>();

        if (PlayerDataManager.GetChatVariableValue("plus") != "var")
            if (sohbet.reklam.type == Sohbet.Ad.Type.interstatial)
            if (sohbet.reklam.placement == Sohbet.Ad.Placement.sohbettenSonra)
                    adManager.ShowInterstitial();

        if (sohbet.reklam.type == Sohbet.Ad.Type.rewarded)
            if (sohbet.reklam.placement == Sohbet.Ad.Placement.sohbettenSonra)
            {
                adManager.rewardItem = sohbet.reklam.odul;
                adManager.ShowRewarded(() => { adManager.UserEarnedEnergyKons(); });
            }

        GameObject[] newBubbles = GameObject.FindGameObjectsWithTag("newBubble");
        foreach(GameObject  gameObject in newBubbles)
        {
            gameObject.GetComponent<RectTransform>().SetParent(bubbleMover);
            gameObject.GetComponent<RectTransform>().tag = "ChatBubble";

            if (gameObject.GetComponent<SpeechBubbleLeft>() != null)
            {
                if (sohbet.sayac == 0)
                    Destroy(gameObject.GetComponent<SpeechBubbleLeft>());
            }
            else if (gameObject.GetComponent<SpeechBubbleRight>() != null)
            {
                Destroy(gameObject.GetComponent<SpeechBubbleRight>());
            }
            else if (gameObject.GetComponent<AnswerBubble>() != null)
            {
                //Destroy(gameObject.GetComponent<AnswerBubble>());
            }
        }

        yield return new WaitForSeconds(Time.deltaTime * 2f);

        SetAllBubblesMoveType(); 
        Canvas.ForceUpdateCanvases();
        SetScrollRectSize();
        scrollRectContainerRt.gameObject.GetComponent<Magnus.UI.ScrollRect>().enabled = true;
        SetAllBubblesMoveType();

        MagnusWordManager wordManager = FindObjectOfType<MagnusWordManager>();
        SquareWordManager squareWordManager = FindObjectOfType<SquareWordManager>();

        if (sohbet.IsPhotographMode())
        {
            kahveFalManager.photoUploadType = 1;

            if (PlayerDataManager.GetChatVariableValue("mod") == "kahve falı fotoğraf yükle")
            {
                kahveFalManager.gerekenFotografSayisi = 3;
            }
            else if (PlayerDataManager.GetChatVariableValue("mod") == "online kahve falı fotoğraf yükle")
            {
                kahveFalManager.gerekenFotografSayisi = 3;
            }
            else if (PlayerDataManager.GetChatVariableValue("mod") == "yüz falı fotoğraf yükle")
            {
                kahveFalManager.gerekenFotografSayisi = 1;
            }
            else if (PlayerDataManager.GetChatVariableValue("mod") == "el falı fotoğraf yükle")
            {
                kahveFalManager.gerekenFotografSayisi = 1;
            }

            SetCameraActivity(true);
            cekilecekFotografSayisi = answerBubbles.Count;

            foreach (GameObject element in answerBubbles)
            {
                element.GetComponent<AnswerBubble>().button.enabled = false;
            }
        }
        else if (sohbet.IsFilePickerMode())
        {
            kahveFalManager.photoUploadType = 0;

            if (PlayerDataManager.GetChatVariableValue("mod") == "kahve falı fotoğraf seç")
            {
                kahveFalManager.gerekenFotografSayisi = 3;
            }
            else if (PlayerDataManager.GetChatVariableValue("mod") == "online kahve falı fotoğraf seç")
            {
                kahveFalManager.gerekenFotografSayisi = 3;
                kahveFalManager.onlineFalPhotos = new();
            }
            else if (PlayerDataManager.GetChatVariableValue("mod") == "yüz falı fotoğraf seç")
            {
                kahveFalManager.gerekenFotografSayisi = 1;
            }
            else if (PlayerDataManager.GetChatVariableValue("mod") == "el falı fotoğraf seç")
            {
                kahveFalManager.gerekenFotografSayisi = 1;
            }
            answerBubbles[0].GetComponent<AnswerBubble>().button.onClick.Invoke();
        }

        if (cekilecekFotografSayisi > 0)
        {
            if (lastScreenShiftedMod != PlayerDataManager.GetChatVariableValue("mod"))
            {
                SlideScreenUp(500);

                StartCoroutine(BubbleFunctionDelay(() => { cgChessBoardScript.SetActive(false); }, 0.4f));
            }
        }
        else if (PlayerDataManager.GetChatVariableValue("mod") == "online dertles")
        {
            kahveFalManager.onlineFalPanel.gameObject.SetActive(true);
            kahveFalManager.onlineFalImages[0].transform.parent.parent.parent.gameObject.SetActive(false);
            kahveFalManager.mod = "online dertles";
            otomatikOdak = true;
            kahveFalManager.onlineFalPanelBackground.color = new Color(0.3f, 0.3f, 0.3f);
            kahveFalManager.onlineFalPanelBackground.sprite = kahveFalManager.onlineFalDertBackground;

            kahveFalManager.onlineFalTitle.text = "DERDİNİ ANLAT";

            kahveFalManager.falAciklamaInputField.text = string.Empty;

            var bilgiEkraniSettings = FindObjectOfType<WelcomeScreen>().bilgiEkraniSettings;
            kahveFalManager.onlineFalAciklama.text = bilgiEkraniSettings.dertlesAciklama
                [Random.Range(0, bilgiEkraniSettings.dertlesAciklama.Length)];
        }
        else if (PlayerDataManager.GetChatVariableValue("mod") == "online ruya")
        {
            kahveFalManager.onlineFalPanel.gameObject.SetActive(true);
            kahveFalManager.onlineFalImages[0].transform.parent.parent.parent.gameObject.SetActive(false);
            kahveFalManager.mod = "online ruya";
            otomatikOdak = true;
            kahveFalManager.onlineFalPanelBackground.color = new Color(0.3f, 0.3f, 0.3f);
            kahveFalManager.onlineFalPanelBackground.sprite = kahveFalManager.onlineFalRuyaBackground;

            kahveFalManager.onlineFalTitle.text = "RÜYANI ANLAT";

            kahveFalManager.falAciklamaInputField.text = string.Empty;

            var bilgiEkraniSettings = FindObjectOfType<WelcomeScreen>().bilgiEkraniSettings;
            kahveFalManager.onlineFalAciklama.text = bilgiEkraniSettings.onlineRuyaAciklama
                [Random.Range(0, bilgiEkraniSettings.dertlesAciklama.Length)];
        }
        else if (cgChessBoardScript.chessSettings.IsChessMod(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!cgChessBoardScript.chessSettings.IsChessMod(lastScreenShiftedMod))
            {
                SlideScreenUp(500);

                StartCoroutine(FindObjectOfType<GyroCamera>().PauseBackgroundGyro(2));
                cgChessBoardScript.SetActive(true);
                cgChessBoardScript.transform.parent.DOLocalMoveY(-16.5f, .3f);
            }
        }
        else if (sohbet.kazimaTipi == Sohbet.KazimaModuEnum.quiz)
        {
            if (lastScreenShiftedMod != PlayerDataManager.GetChatVariableValue("mod"))
            {
                SlideScreenUp(320);
            }
        }
        else if (PlayerDataManager.GetChatVariableValue("mod") == "magnuflow")
        {
            if (lastScreenShiftedMod != PlayerDataManager.GetChatVariableValue("mod"))
            {
                SlideScreenUp(650);

                Instantiate(magnuFlowGamePrefab);
            }
        }
        else if (wordManager != null)
        {
            if (wordManager.IsGameMod(PlayerDataManager.GetChatVariableValue("mod")))
            {
                if (!wordManager.IsGameMod(lastScreenShiftedMod))
                {
                    SlideScreenUp(300);

                    Instantiate(magnusWord, canvasRect);
                }
            }
        }
        else if (magnusWordDatabase.wordGameMod == PlayerDataManager.GetChatVariableValue("mod"))
        {
            if (lastScreenShiftedMod != magnusWordDatabase.wordGameMod)
            {
                SlideScreenUp(300);

                Instantiate(magnusWord, canvasRect);
            }
        }
        else if (squareWordManager != null)
        {
            if (squareWordManager.IsGameMod(PlayerDataManager.GetChatVariableValue("mod")))
            {
                if (!squareWordManager.IsGameMod(lastScreenShiftedMod))
                {
                    SlideScreenUp(400);

                    Instantiate(magnusKareKelime, canvasRect);
                }
            }
        }
        else if (squareWordDatabase.kareKelimeOyunuModu == PlayerDataManager.GetChatVariableValue("mod"))
        {
            if (lastScreenShiftedMod != squareWordDatabase.kareKelimeOyunuModu)
            {
                SlideScreenUp(400);

                Instantiate(magnusKareKelime, canvasRect);
            }
        }
        else if (aaSettings.GetGameMode(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!aaSettings.GetGameMode(lastScreenShiftedMod))
            {
                SlideScreenUp(650);

                Instantiate(aaSettings.prefab);
            }
        }
        else if (MagnuDotsKontrol(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!MagnuDotsKontrol(lastScreenShiftedMod))
            {
                SlideScreenUp(550);

                Instantiate(magnuDotsGamePrefab, new Vector3(-5000, -5000, 0), Quaternion.identity);
            }
        }
        else if (magnu2048Settings.IsMagnu2048Mod(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!magnu2048Settings.IsMagnu2048Mod(lastScreenShiftedMod))
            {
                SlideScreenUp(620);

                var gameSelecter = Instantiate(magnu2048GamePrefab).transform.GetChild(0).GetComponent<RectTransform>().GetChild(0).GetComponent<GameSelector>();
                //Olusturmadan once son oyundan kalan datalar silinir ve oyun başlatılır.
                StartCoroutine(BubbleFunctionDelay(() => { RestartButton.OnClick(); gameSelecter.AfterStart(); }, 0.1f));
            }
        }
        else if (magnuTrisSettings.IsMagnuTrisMod(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!magnuTrisSettings.IsMagnuTrisMod(lastScreenShiftedMod))
            {
                SlideScreenUp(620);
                Instantiate(magnuTrisPrefab, new Vector3(-2000, 2000), Quaternion.identity);
            }
        }
        else if (magNukemSettings.IsMagNukeMod(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!magNukemSettings.IsMagNukeMod(lastScreenShiftedMod))
            {
                SlideScreenUp(650);

                Instantiate(magnuFPSPrefab, new Vector3(-2000, 2000), Quaternion.identity);
            }
        }
        else if (tarotSettings.IsTarotCardPickerMod(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!tarotSettings.IsTarotCardPickerMod(lastScreenShiftedMod))
            {
                SlideScreenUp(620);

                Instantiate(tarotPrefab, canvasRect);
            }
        }
        else if (spinWheelSettings.IsSpinWheelMod(PlayerDataManager.GetChatVariableValue("mod")))
        {
            if (!spinWheelSettings.IsSpinWheelMod(lastScreenShiftedMod))
            {
                SlideScreenUp(550);

                GameObject spinSwheel = Instantiate(spinWheelPrefab, spinWheelPivot);
                spinWheelDragManager.wheelTransform = spinSwheel.transform.GetChild(0).GetComponent<MagnusSpinWheelManager>().wheel;
                spinWheelDragManager.magnusSpinWheelManager = spinSwheel.transform.GetChild(0).GetComponent<MagnusSpinWheelManager>();
                spinWheelDragManager.gameObject.SetActive(true);
            }
        }
        else if (wheelModSelector.wheelModSelectorData.datas.Exists
            (x => x.wheelModu.Equals(PlayerDataManager.GetChatVariableValue("mod"))))
        {
            SlideScreenUp(550);

            var data = wheelModSelector.wheelModSelectorData.datas.Find
            (x => x.wheelModu.Equals(PlayerDataManager.GetChatVariableValue("mod")));

            wheelModSelector.currentData = data;

            if (data.type == WheelModSelectorData.WheelData.Type.wheel)
            {
                wheelModSelector.SetActive(true, data.wheelPhoto);
            }
            else
            {
                wheelModSelector.SetActive(true, data);
            }
        }
        else
        {
            if (screenShifted)
            {
                SlideScreenDown();

                //scrollRectPivotRt.anchoredPosition = new Vector2(scrollRectPivotRt.anchoredPosition.x, scrollRectPivotRt.parent.GetComponent<RectTransform>().sizeDelta.y);
                scrollOfftet = 0;

                AiMessageDelay += scrollRectPivotDuration + scrollRectPivotDuration / 2f;

                cgChessBoardScript.transform.parent.DOLocalMoveY(-120f, .3f);
                StartCoroutine(BubbleFunctionDelay(() => { cgChessBoardScript.SetActive(false); }, 0.4f));
            }
        }

        if (screenShifted)
        {
            //Bu delay eger ekran yukari kaydiysa DOTWEEN animsyonun tamamlanmasi icin ekstra zaman verilmesi icin bulunuyor.
            //DOTWEEN apisine henuz tam olarak hakim olunmadigi icin boyle bir cozume gidilmistir. Ideal cozum bulundugunda burasu degisecek

            //HATANIN NEDENI
            //DOTWEEN apisi anlik fps dususlerinde animasyonu anlik duraklamadan sonra kaldigi yerdend devam ettirdigi icin
            //ornek olrak 0.5f surecek bir animasyon anlik donma olursa 0.564f surebiliyor. Bu durumda animasyon bizim
            //Bitmesini istedigmiz andan sonra bitiyor. Ozellikle ekran yukari kayinca bundan dolayi bazi butonlar altta kaliyor.

            yield return new WaitForSeconds(Time.deltaTime * 3f);
        }
        
        scrollRectPivotTartgetPos = new Vector2(scrollRectPivotRt.anchoredPosition.x, scrollRectPivotRt.parent.GetComponent<RectTransform>().sizeDelta.y + scrollOfftet);

        scrollRectPivotPreviousPos = scrollRectPivotRt.anchoredPosition;

        scrollRectPivotStartTime = Time.time;


        SohbetayarlananDegiskenleriniAyarla();

        if ((sohbet.cevaplar.Count <= 0 || availableAnswerBubbles.Count <= 0))
        {
            //eger sayac aktifse initiliazeSayacTimer sohbeti zaten clickAnswerBubble isini yaptigi icin cift tiklama olmasin diye bu kontrol yapilir.
            if (sohbet.sayac <= 0)
            {
                StartCoroutine(BubbleFunctionDelay(() => ClickAnswerBubble(null, 0, 0, false), 0f));
            }
        }
    }

    private bool MagnuDotsKontrol(string mod)
    {
        //MagnuDotsSettings olusturulup oraya alinacak!!!
       return mod == "magnudots" || mod == "magnusdots hamle cevap 1" || mod == "magnusdots hamle cevap 2"
            || mod == "magnusdots hamle cevap 3" || mod == "magnusdots hamle cevap 4"
            || mod == "magnusdots hamle cevap 5" || mod == "magnusdots hamle cevap 6"
            || mod == "magnusdots hamle cevap 7" || mod == "magnusdots hamle cevap 8"
            || mod == "magnusdots hamle cevap 9" || mod == "magnusdots hamle cevap cok iyi";
    }

    private void SlideScreenUp(int amount)
    {
        int delatScrollOffset = amount - scrollOfftet;
        scrollOfftet = amount;

        if (!screenShifted)
        {
            MoveAllBubbles(scrollOfftet, false);
            screenShifted = true;
            scrollRectNotClickableArea.gameObject.SetActive(true);
            scrollRectMaskLifted.GetComponent<Image>().enabled = true;
            scrollRectMaskLifted.GetComponent<Mask>().enabled = true;
            writingAnimationType = 1;
        }
        else
        {
            MoveAllBubbles(delatScrollOffset, false);
            scrollRectPivotTartgetPos = new Vector2(scrollRectPivotRt.anchoredPosition.x, 
                scrollRectPivotRt.parent.GetComponent<RectTransform>().sizeDelta.y + scrollOfftet);
        }

        lastScreenShiftedMod = PlayerDataManager.GetChatVariableValue("mod");
    }

    private void SlideScreenDown()
    {
        MoveAllBubbles(-scrollOfftet, false);
        screenShifted = false;
        scrollRectNotClickableArea.gameObject.SetActive(false);
        scrollRectMaskLifted.GetComponent<Image>().enabled = false;
        scrollRectMaskLifted.GetComponent<Mask>().enabled = false;

        writingAnimationType = 0;

        lastScreenShiftedMod = string.Empty;
        tarotSohbetleri = new();
    }
}
