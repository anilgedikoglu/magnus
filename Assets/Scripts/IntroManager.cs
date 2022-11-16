using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;
using Firebase.Auth;
using Newtonsoft.Json;
using DG.Tweening;

//Classin temel gorevi
//Bu classin temel gorevi uygulama acildiginda hangi ekranda baslayacagina karar vermek
//ve arkaplanda donen videolarin intro, edit ve chat screen icin ayarlanamasini
//saglamaktir.

public class IntroManager : MonoBehaviour
{
    public VideoPlayer videoPlayerIntro, videoPlayerChat, videoPlayerEdit;

    private VideoClip kahveFaliClip;

    public AudioClip introSound;

    [HideInInspector] public AudioSource audioSource;

    public Image chatBackgroundImage;

    public GameObject kahveFaliRawImageObject;

    public GyroCamera gyroCamera;

    float introVideoTimer;

    public GameObject terminalPanel;
    public LoginPanelHandler loginPanelHandler;
    public GameObject fotoIntroPanel;

    public GameObject KahveFaliContent;

    [HideInInspector]
    public bool introDone;

    public CurrentPlayerData playerDataManager;

    public bool goToChatScreen;

    AuthenticationManager authenticationManager;

    public Sprite fotoIntroDefaultImage, fotoIntroPlustImage;

    public GameObject panelVersionError;
    public GameObject panelBakimError;
    public GameObject panelInternetError;
    public GameObject panelLoading;

    public Image introTransactionEffect;

    private void Awake()
    {
        //Uygulamanın bu scriptin olduğu ana sahnede bu panel ile başlaması gerektiği için paneli devreye sokuyoruz.
        if (!panelLoading.activeInHierarchy)
            StartCoroutine(SetActiveLoadingPanel(true));

        //Eger aşamasında bir nedenle bu panel açık unutulmuşsa bu çok ciddi bir problem olcağı için başlangıça kontrol edilir.
        if (panelVersionError.activeInHierarchy)
            panelVersionError.SetActive(false);

        //Eger aşamasında bir nedenle bu panel açık unutulmuşsa bu çok ciddi bir problem olcağı için başlangıça kontrol edilir.
        if (panelBakimError.activeInHierarchy)
            panelBakimError.SetActive(false);

        //Eger aşamasında bir nedenle bu panel açık unutulmuşsa bu çok ciddi bir problem olcağı için başlangıça kontrol edilir.
        if (panelInternetError.activeInHierarchy)
            panelInternetError.SetActive(false);
    }

    void Start()
    {
        introDone = true;
    }

    public IEnumerator Initialize()
    {
        playerDataManager.Initiliaze();

        yield return new WaitForEndOfFrame();
        //yield return new WaitForSeconds(Time.deltaTime * 10f);
        ChatManager chatManager = FindObjectOfType<ChatManager>();
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        audioSource = gameObject.GetComponent<AudioSource>();

        videoPlayerEdit.clip = chatManager.magnusPreferences.editVideos[Random.Range(0, chatManager.magnusPreferences.editVideos.Length)];
        kahveFaliClip = chatManager.magnusPreferences.kahveFaliVideos[Random.Range(0, chatManager.magnusPreferences.kahveFaliVideos.Length)];

        videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerEdit.gameObject.transform.position = new Vector3(-500, 0, 0);

        videoPlayerChat.Prepare();
        videoPlayerEdit.Prepare();

        if (authenticationManager.user != null)
        {
            if (Application.internetReachability != NetworkReachability.NotReachable)
            {
                bool breakFunction = false;
                try
                {
                    StartCoroutine(playerDataManager.GetUserDataOnline());
                    if (playerDataManager.GetChatVariableValue("introtipi") == "video")
                        playerDataManager.AddElementToChatVariableList("introtipi", "sessiz");
                }
                catch
                {
                    authenticationManager.OnClickSignOutButton();
                    breakFunction = true;
                }

                //Eger hata varsa giris ekranina geri doner
                if (breakFunction)
                {
                    yield return new WaitForSeconds(1);
                    StartCoroutine(Initialize());
                    yield break;
                }

                yield return new WaitUntil(() => playerDataManager.onlineDataChecked);
            }
            else
            {
                playerDataManager.onlineDataChecked = true;
                panelInternetError.SetActive(true);
                Debug.Log("İnternet bağlantısı sağlanamadığı için uygulama kapatıldı!");
                yield break;
            }

            //Bu andan itibaren yüklenme işlemi bittiği için paneli kapatiyoruz.
            if(panelLoading.activeInHierarchy)
                StartCoroutine(SetActiveLoadingPanel(false));

            if (playerDataManager.localPlayerDatas.bakimDurumu)
            {
                panelBakimError.SetActive(true);
                Debug.Log("Uygulamada şuan <color=red><b>bakım</b></color=red> uygulanmakta");
                yield break;
            }
            else
            {
                panelBakimError.SetActive(false);
                Debug.Log("Uygulamada şuan bakım çalışması mevcut değil.");
            }

            if (playerDataManager.localPlayerDatas.releaseVersions.Contains(Application.version))
            {
                panelVersionError.SetActive(false);
                Debug.Log("Sürüm kullanılabilir: " + Application.version);
            }
            else
            {
                panelVersionError.SetActive(true);
                Debug.Log("Bu sürüm kullanıma uygun değil. Lütfen güncel sürümü indir!: " + Application.version);
                introDone = true;
                yield break;
            }

            if (!playerDataManager.datas.ilkeEnerjiVerildi)
            {
                playerDataManager.datas.energy = 10;
                playerDataManager.datas.konsantrasyon = 0;
                playerDataManager.datas.ilkeEnerjiVerildi = true;
            }

            //FindObjectOfType<WelcomeScreen>().SetProfilePhotoSpriteIEnumurator(playerDataManager.datas.profilePhotoNum);

            if (authenticationManager.user.IsEmailVerified || !(authenticationManager.auth.CurrentUser.ProviderId == "password" 
                || authenticationManager.auth.CurrentUser.ProviderId == "Firebase"))
            {
                Debug.Log(authenticationManager.user.IsEmailVerified);
                Debug.Log(authenticationManager.auth.CurrentUser.ProviderData.ToString());

                if (playerDataManager.datas.introGosterildi)
                {
                    loginPanelHandler.DeactivateSignInMenu();
                    terminalPanel.SetActive(false);
                    /*
                    if (playerDataManager.GetChatVariableValue("introtipi") == "video" )
                    { 
                        eski kisim
                        videoPlayerIntro.clip = (playerDataManager.GetChatVariableValue("plus") == "var") ? 
                            chatManager.magnusPreferences.introVideosPlus[Random.Range(0, chatManager.magnusPreferences.introVideosPlus.Length)] : 
                            chatManager.magnusPreferences.introVideos[Random.Range(0, chatManager.magnusPreferences.introVideos.Length)];

                        introVideoTimer = (float)videoPlayerIntro.clip.length;

                        SetIntroWallpaperActive();
                        fotoIntroPanel.SetActive(false);
                        videoPlayerIntro.Play();
                }*/
                    if (playerDataManager.GetChatVariableValue("introtipi") == "ses" || playerDataManager.GetChatVariableValue("introtipi") == "ayarlanmadi" || playerDataManager.GetChatVariableValue("introtipi") == "video")
                    {
                        fotoIntroPanel.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>().sprite =
                            (playerDataManager.GetChatVariableValue("plus") == "var") ? fotoIntroPlustImage : fotoIntroDefaultImage;

                        fotoIntroPanel.SetActive(true);
                        audioSource.clip = introSound;
                        audioSource.Play();

                        introDone = false;
                    }
                    else if (playerDataManager.GetChatVariableValue("introtipi") == "sessiz")
                    {
                        fotoIntroPanel.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>().sprite = (playerDataManager.GetChatVariableValue("plus") == "var") ?
                            fotoIntroPlustImage : fotoIntroDefaultImage;

                        fotoIntroPanel.SetActive(true);
                        audioSource.clip = introSound;
                        audioSource.Stop();
                        introVideoTimer = 1f;

                        introDone = false;
                    }
                    else
                    {
                        fotoIntroPanel.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>().sprite = (playerDataManager.GetChatVariableValue("plus") == "var") ?
                            fotoIntroPlustImage : fotoIntroDefaultImage;

                        fotoIntroPanel.SetActive(true);
                        audioSource.clip = introSound;
                        audioSource.Stop();
                        introVideoTimer = 1f;

                        introDone = false;
                    }
                }
                else
                {
                    Debug.Log("Terminal paneli açılıyor");
                    
                    loginPanelHandler.DeactivateSignInMenu();
                    terminalPanel.SetActive(true);
                    SetTerminalWallpaperActive();
                    loginPanelHandler.gameObject.SetActive(false);
                    introDone = true;
                }
            }
            else
            {
                terminalPanel.SetActive(false);
                loginPanelHandler.SetActivePanel(loginPanelHandler.verificationEmailPanel);
                introDone = true;
            }
        }
        else
        {
            //Bu andan itibaren yüklenme işlemi bittiği için paneli kapatiyoruz.
            if (panelLoading.activeInHierarchy)
                StartCoroutine(SetActiveLoadingPanel(false));

            terminalPanel.SetActive(false);
            loginPanelHandler.SetActivePanel(loginPanelHandler.signInPanel);
            SetTerminalWallpaperActive();
            introDone = true;
        }

        RectTransform canvas = GameObject.Find("Canvas").GetComponent<RectTransform>();
        float scale = (canvas.rect.width / 540f);

        if (scale > 1)
        {
            videoPlayerIntro.transform.localScale = new Vector3(videoPlayerIntro.transform.localScale.x * scale, videoPlayerIntro.transform.localScale.y * scale, videoPlayerIntro.transform.localScale.z);
            videoPlayerEdit.transform.localScale = new Vector3(videoPlayerEdit.transform.localScale.x * scale, videoPlayerEdit.transform.localScale.y * scale, videoPlayerEdit.transform.localScale.z);
            videoPlayerChat.transform.localScale = new Vector3(videoPlayerChat.transform.localScale.x * scale, videoPlayerChat.transform.localScale.y * scale, videoPlayerChat.transform.localScale.z);
        }

        KahveFaliContent.SetActive(false);
    }

    public void CheckPlusActiveObjects()
    {
        SetActiveWithPlus[] gameObjects = Resources.FindObjectsOfTypeAll<SetActiveWithPlus>();

        foreach (SetActiveWithPlus setActiveWithPlus in gameObjects)
        {
            setActiveWithPlus.Check();
        }
    }

    IEnumerator SetActiveLoadingPanel(bool value)
    {
        GameObject loadingPanelContentParent = panelLoading.GetComponent<RectTransform>().GetChild(0).gameObject;

        panelLoading.SetActive(value);

        //Eger panelin contenti açıksa bunu deaktif hale getiriyoruz. Çünkü bunun anında gözükmesini istemiyoruz.
        if (loadingPanelContentParent.activeInHierarchy)
            loadingPanelContentParent.SetActive(false);

        if (value)
        {
            yield return new WaitForSeconds(2);
            loadingPanelContentParent.SetActive(value);
        }
    }

    public void CheckPlus(bool retore)
    {
        System.DateTime plusExpireDateFromStore = Magnus.Time.DateTimeOperations.ToDateTime(playerDataManager.datas.plusExpireDateFromStore);
        System.DateTime plusExpireDateFromSystem = Magnus.Time.DateTimeOperations.ToDateTime(playerDataManager.datas.plusExpireDateFromSystem);
        System.DateTime plusExpireDate;


        if ((plusExpireDateFromSystem - plusExpireDateFromStore).TotalSeconds > 0)
        {
            plusExpireDate = plusExpireDateFromSystem;
        }
        else
        {
            plusExpireDate = plusExpireDateFromStore;
        }

        if ((plusExpireDate - System.DateTime.Now).TotalDays <= 0)
        {
            playerDataManager.AddElementToChatVariableList("plus", "yok");
        }
        else
        {
            playerDataManager.AddElementToChatVariableList("plus", "var");
        }
        CheckPlusActiveObjects();

        try {
            if (retore)
                FindObjectOfType<IAPManager>().Restore();
        }
        catch
        {
            Debug.LogError("Restore process skipped because " +
                "Codeless IAP Manager could not start. Most of the time the reason is " +
                "xcode version of the app. If you are using the " +
                "version that downloaded from App Store check the scripts about restore.");
        }
        }

    void Update()
    {
        if (playerDataManager.datas.introGosterildi)
        {
            if (!introDone)
            {
                if (playerDataManager.GetChatVariableValue("introtipi") == "ses" 
                    || playerDataManager.GetChatVariableValue("introtipi") == "ayarlanmadi" 
                    || playerDataManager.GetChatVariableValue("introtipi") == "video")
                {
                    if (audioSource.time >= introSound.length / 3f)
                    {
                        introTransactionEffect.gameObject.SetActive(true);
                        introTransactionEffect.DOFade(0, .5f).onComplete = () => {
                            introTransactionEffect.gameObject.SetActive(false);
                        };

                        introDone = true;
                        if (playerDataManager.GetChatVariableValue("introtipi") == "ayarlanmadi")
                            playerDataManager.AddElementToChatVariableList("introtipi", "sessiz");
                        SetEditWallpaperActive();
                        FindObjectOfType<WelcomeScreen>().SetActive(true, true);
                        fotoIntroPanel.SetActive(false);

                        if (goToChatScreen)
                        {
                            IntroDoneEvent();
                        }
                    }
                }
                else if (playerDataManager.GetChatVariableValue("introtipi") == "sessiz")
                {
                    if (introVideoTimer > 0)
                    {
                        introVideoTimer -= Time.deltaTime;
                    }
                    else
                    {
                        introTransactionEffect.gameObject.SetActive(true);
                        introTransactionEffect.DOFade(0, .5f).onComplete = () => {
                            introTransactionEffect.gameObject.SetActive(false);
                        };

                        introDone = true;
                        if (playerDataManager.GetChatVariableValue("introtipi") == "ayarlanmadi")
                            playerDataManager.AddElementToChatVariableList("introtipi", "sessiz");
                        SetEditWallpaperActive();
                        FindObjectOfType<WelcomeScreen>().SetActive(true, true);
                        fotoIntroPanel.SetActive(false);

                        if (goToChatScreen)
                        {
                            IntroDoneEvent();
                        }
                    }
                }
            }
        }
    }

    void IntroDoneEvent()
    {
        GameObject.Find("WindowWelcomeScreen").GetComponent<WelcomeScreen>().SetTextsOfInputObjects();
        //GameObject.Find("WindowWelcomeScreen").GetComponent<WelcomeScreen>().CheckInputItems();

        GameObject.Find("WindowWelcomeScreen").GetComponent<WindowManager>().WindowAcivityButton(false);
        GameObject.Find("ChatManager").GetComponent<ChatManager>().StartChatManager(false);
        GameObject.Find("ChatScreen").GetComponent<ChatScreenActivity>().SetActive();
        SetChatWallpaperActive();
    }

    public void SetTerminalWallpaperActive()
    {
        videoPlayerIntro.enabled = false;
        videoPlayerIntro.gameObject.transform.position = new Vector3(-500, 0, 0);

        videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerChat.Pause();
        gyroCamera.SetActiveGyro(true);

        videoPlayerEdit.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerEdit.Pause();

        KahveFaliContent.GetComponent<Animator>().SetBool("exit", true);
    }

    public void SetChatWallpaperActive()
    {
        videoPlayerIntro.enabled = false;
        videoPlayerIntro.gameObject.transform.position = new Vector3(-500, 0, 0);

        playerDataManager.AddElementToChatVariableList("wallpaper tipi", "gyro");

        if (playerDataManager.GetChatVariableValue("wallpaper tipi") == "video")
        {
            videoPlayerChat.gameObject.transform.position = new Vector3(0, 0, 0);
            videoPlayerChat.Play();
            gyroCamera.SetActiveGyro(false);
        }
        else
        {
            videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
            videoPlayerChat.Pause();
            gyroCamera.SetActiveGyro(true);
        }

        videoPlayerEdit.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerEdit.Pause();

        KahveFaliContent.GetComponent<Animator>().SetBool("exit", true);
        StartCoroutine(KahveFaliExitDelay());
    }

    public void SetEditWallpaperActive()
    {
        videoPlayerIntro.enabled = false;
        videoPlayerIntro.gameObject.transform.position = new Vector3(-500, 0, 0);

        videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerChat.Pause();
        gyroCamera.SetActiveGyro(false);

        videoPlayerEdit.gameObject.transform.position = new Vector3(0, 0, 0);
        videoPlayerEdit.Play();

        KahveFaliContent.SetActive(false);
        KahveFaliContent.GetComponent<Animator>().SetBool("exit", false);
    }

    public void SetIntroWallpaperActive()
    {
        videoPlayerIntro.enabled = true;
        videoPlayerIntro.frame = 0;
        introDone = false;
        videoPlayerIntro.gameObject.transform.position = new Vector3(0, 0, 0);
        videoPlayerIntro.Play();

        videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerChat.Pause();
        gyroCamera.SetActiveGyro(false);

        videoPlayerEdit.gameObject.transform.position = new Vector3(-500, 0, 0);
        videoPlayerEdit.Pause();

        KahveFaliContent.SetActive(false);
        KahveFaliContent.GetComponent<Animator>().SetBool("exit", false);
    }

    public void SetKahveFaliWallpaperActive(bool changeWallpaper)
    {
        StartCoroutine(KahveFaliDelay(changeWallpaper));
    }

    IEnumerator KahveFaliDelay(bool changeWallpaper)
    {
        yield return new WaitForSeconds(2f);

        if (changeWallpaper)
        {
            videoPlayerIntro.enabled = false;
            videoPlayerIntro.gameObject.transform.position = new Vector3(-500, 0, 0);

            videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
            videoPlayerChat.clip = kahveFaliClip;
            videoPlayerChat.Play();
            gyroCamera.SetActiveGyro(true);

            KahveFaliContent.GetComponent<Animator>().SetBool("exit", false);
            KahveFaliContent.SetActive(true);
            kahveFaliRawImageObject.SetActive(true);

            videoPlayerEdit.gameObject.transform.position = new Vector3(-500, 0, 0);
            videoPlayerEdit.Pause();
        }
        else
        {
            KahveFaliContent.GetComponent<Animator>().SetBool("exit", false);
            KahveFaliContent.SetActive(true);
            kahveFaliRawImageObject.SetActive(false);
        }
    }

    IEnumerator KahveFaliExitDelay()
    {
        yield return new WaitForSeconds(0.3f);
        KahveFaliContent.SetActive(false);
  
        if (playerDataManager.GetChatVariableValue("wallpaper tipi") == "video")
        {
            videoPlayerChat.gameObject.transform.position = new Vector3(0, 0, 0);
            videoPlayerChat.Play();
        }
        else
        {
            videoPlayerChat.gameObject.transform.position = new Vector3(-500, 0, 0);
            gyroCamera.SetActiveGyro(true);
        }
    }
}
