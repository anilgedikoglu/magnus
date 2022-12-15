using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;
using Michsky.UI.ModernUIPack;
using TMPro;
using System.IO;
using System.Linq;

using UnityEngine.Networking;
using Firebase.Storage;
using Firebase.Extensions;
using UnityEngine.Purchasing;
#if UNITY_ANDROID || UNITY_IOS
using NativeGalleryNamespace;
#endif

public class AnswerBubble : MonoBehaviour
{
    //*****************************  Kullanim Amaci  *****************************
    //targetposition degiskeni bu cevap baloncugunun gitmesi gereken noktanin koordinatlarini barindiran degiskendir. Baloncugun mevcut pozisyonu bu degere her bir framede Move fonksiyonunda belirtildigi oranda yaklasir.
    [HideInInspector] public Vector3 targetPosition;

    //*****************************  Kullanim Amaci  *****************************
    //previousTartgetPosition degiskeni baloncuk hareket etmeye basladigi anda baloncugun bulundugu degeri icinde barindirir. Bu basitce baloncugun hareket ettigi yonu anlamakta kullanilir.
    //Detaylar SetPositionToRealPotion fonksiyonuna bak.
    private Vector3 previousTartgetPosition;

    [HideInInspector] public int bubbleType;    //  KULLANIM AMACI  ====>  bubbleType baloncugun secenek numarasidir. Bu degisken sayesinde hangi secenege tiklandigi anlasilir.
    [HideInInspector] public int textVariation;
    [HideInInspector] public Sohbet sohbet;
    [HideInInspector] public Sohbet sonrakiSohbet;
    [HideInInspector] public string sonrakiMod;
    [HideInInspector] public TakipSohbeti takipSohbet;
    [HideInInspector] public ChatManager chatManager;
    [HideInInspector] public KahveFalManager kahveFalManager;
    [HideInInspector] public bool isActive;
    [HideInInspector] public bool movable;
    [HideInInspector] public bool clickable;
    [HideInInspector] public float startTime;
    [HideInInspector] public string filePath;
    [HideInInspector] public bool isPhotoPicked;
    [HideInInspector] public RectTransform contentImageRt;
    [HideInInspector] public int avaliableAnswerBubblesCount;
    [HideInInspector] public int positionType;

    [SerializeField] private TMP_Text altinText;
    [SerializeField] private TMP_Text elmasText;

    ChatScreenActivity chatScreenActivity;

    private bool gifSizeSet;

    public Button button;
    public Image image;
    public TMP_Text text;
    public TMP_Text textForResize;
    public Image contentImage;
    public RectTransform rt;
    public float animationDuration;

    public Color normalColor, changeChatColor;

    private Texture2D loadedKahveFalPhoto;

    void Start()
    {
        chatScreenActivity = FindObjectOfType<ChatScreenActivity>();

        contentImageRt = contentImage.GetComponent<RectTransform>();

        SetColor(sohbet.cevaplar.Count);
        SetButtonListener(sohbet.cevaplar.Count);
        SetInitialPosition();
        SetGifActiveDelay();
    }

    void Update()
    {
        //SetPositionToTargetPosition();
        //CheckIfShouldDestroy();
        //SetGifPhotoSize();
    }

    private void OnEnable()
    {
        //bu durum gifler disable olduğunda silindiği için texture null duruma düşerse diye

        if (contentImage.sprite == null)
        {
            SetContentImageSprite();
        }
        else
        {
            if (contentImage.sprite.texture == null)
            {
                SetContentImageSprite();
            }
        }
    }

    public void SetGifActiveDelay()
    {
        /*
        if (sohbet.cevaplar != null)
        {
            if (bubbleType >= 1 && bubbleType <= sohbet.cevaplar.Count)
            {
                if (!string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.gifId) && sohbet.cevaplar[bubbleType - 1].contentImage.gifId != chatManager.magnusPreferences.wheelChartConentPhotoId && sohbet.cevaplar[bubbleType - 1].contentImage.gifId != chatManager.magnusPreferences.kullaniciPhotoId)
                {
                    contentImage.GetComponent<ProGifPlayerImage>().loadPath = $"https://media0.giphy.com/media/{sohbet.cevaplar[bubbleType - 1].contentImage.gifId}/200w.gif";
                    contentImage.GetComponent<ProGifPlayerImage>().enabled = true;
                }
                else
                {
                    contentImage.GetComponent<ProGifPlayerImage>().enabled = false;
                }
            }
        }*/
    }

    void SetGifPhotoSize()
    {
        /*
        if (!gifSizeSet)
        {
            if (sohbet.cevaplar != null)
            {
                if (bubbleType >= 1 && bubbleType <= sohbet.cevaplar.Count)
                {
                    if (!string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.gifId))
                    {
                        if (contentImage.GetComponent<ProGifPlayerImage>().isActiveAndEnabled)
                        {
                            if (contentImage.GetComponent<ProGifPlayerImage>().width == contentImage.sprite.rect.width)
                            {
                                contentImageRt.localScale = new Vector3((float)contentImage.GetComponent<ProGifPlayerImage>().width / (float)contentImage.GetComponent<ProGifPlayerImage>().height, contentImageRt.localScale.y, contentImageRt.localScale.z);
                                gifSizeSet = true;
                            }
                        }
                    }
                }
            }
        }*/
    }

    /// <summary>
    /// Balouncugun rengini ayarlar. Bu renkler normalColor, changeChatColor adlariyla alinan renklerdir.
    /// </summary>
    void SetColor(int answerBubbleCount)
    {
        if (bubbleType >= 1 && bubbleType <= answerBubbleCount)
            image.color = normalColor;
        else if (bubbleType == answerBubbleCount + 1)
            image.color = changeChatColor;

        //Yüz falı fotoğraf çekimi sırasında çıkan butonların ilk geldiğinde görünmemesi için aşağıdaki değişiklikler yapılır.
        //Minicam scripti içinde fotoğraf çekme butonuna basıldığı anda bu işlenler tersine uygualanarak butan tekrar aktif edilir.

        if (chatManager.PlayerDataManager.GetChatVariableValue("mod") == "yüz falı fotoğraf yükle")
        {
            Image buttonImage = button.GetComponent<Image>();
            buttonImage.color = new Color(buttonImage.color.r, buttonImage.color.g, buttonImage.color.b, 0f);

            text.color = new Color(text.color.r, text.color.g, text.color.b, 0f);

            contentImage.color = new Color(contentImage.color.r, contentImage.color.g, contentImage.color.b, 0f);
        }
    }

    /// <summary>
    /// Butonlarin evetnlerini ayarlayan fonksiyon.
    /// </summary>
    public void SetButtonListener(int answerBubbleCount)
    {
        SetTakipSohbet();
        if (bubbleType >= 1 && bubbleType <= answerBubbleCount)
        {
            //Anroidte ve IOSta dosya manager ile dosya cekip yukleyince olan bir sikintidan doalyi geri donuse 1 saniye delay koyulmustir. Sikinti giderilip delay kaldirilacak.
            if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fotoğraf seç kahve" || sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fotoğraf seç yüz" ||
                sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fotoğraf seç el" || sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "yuz fali profil fotografi" ||
                sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc aramayi durdur" || sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "bilgi ekranina git"
                || sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "store" || sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "online fotoğraf seç kahve")
            {
                OzelFonksiyonAyarla();
                //button.onClick.AddListener(() => StartCoroutine(ClickFunctionDelay()));
            }
            else
            {
                OzelFonksiyonAyarla();

                button.onClick.AddListener(() => chatManager.ClickAnswerBubble(sonrakiSohbet, bubbleType, textVariation, !sohbet.tepkiBalonuYok));
            }
        }
        else if (bubbleType == answerBubbleCount + 1)
        {
            button.onClick.AddListener(() => chatManager.ClickVirtualButton("ana menu"));
        }
    }


    /// <summary>
    /// Takip sohbeti ve sonraki sohbeti ayarlayan fonksiyon.
    /// </summary>
    void SetTakipSohbet()
    {
        if (bubbleType == sohbet.cevaplar.Count + 1)
        {
            takipSohbet = null;
        }
        else
        {
            var sohbetSonra = sohbet.cevaplar[bubbleType - 1].CurrentSonrakiSohbetHavuzu;

            if (sohbetSonra != null)
                Debug.Log(sohbetSonra.GetSohbetId());
            else
                Debug.Log("Sonraki sohbet yok");

            sonrakiSohbet = sohbetSonra;
            takipSohbet = sohbet.cevaplar[bubbleType - 1].takipSohbeti;
        }
    }

    /// <summary>
    /// Bu fonksiyon seceneklere istenilen baska bir fonksiyon atanabilmesini saglar.
    /// </summary>
    void OzelFonksiyonAyarla()
    {
        button.onClick.AddListener(() => OzelFonksiyonlar());
    }

    public void OzelFonksiyonlar()
    {
        if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "uygulamayı değerlendir")
        {
            OzelFonksiyonManager.UygulamayiDegerlendir();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "uygulamadn çık")
        {
            OzelFonksiyonManager.UygulamayiKapat();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "ilk geliş tamamlandı")
        {
            OzelFonksiyonManager.IlkGelisTamam();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fotoğraf seç kahve")
        {
            if (chatManager.kahveFalManager.canClickOpenFilePicker)
                FotografSec("kahve");
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fotoğraf seç yüz")
        {
            if (chatManager.kahveFalManager.canClickOpenFilePicker)
                FotografSec("yuz");
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fotoğraf seç el")
        {
            if (chatManager.kahveFalManager.canClickOpenFilePicker)
                FotografSec("el");
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "online fotoğraf seç kahve")
        {
            if (chatManager.kahveFalManager.canClickOpenFilePicker)
                FotografSec("online kahve");
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "kahve fali video")
        {
            chatManager.kahveFalManager.KahveFaliArkaplanAyarla(true);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "yuz fali profil fotografi")
        {
            ProfilFotografiYuzFali();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc kullanici rengi beyaz")
        {
            ChessPlayerIsWhite(1);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc kullanici rengi siyah")
        {
            ChessPlayerIsWhite(0);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc kullanici rengi rastgele")
        {
            ChessPlayerIsWhite(-1);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc zorluk 0")
        {
            ChessSetDificultiy(0);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc zorluk 1")
        {
            ChessSetDificultiy(1);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc zorluk 2")
        {
            ChessSetDificultiy(2);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc zorluk 3")
        {
            ChessSetDificultiy(3);
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "satranc aramayi durdur")
        {
            SatranctanCik();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "bilgi ekranina git")
        {
            OzelFonksiyonManager.BilgiEkraninaGit();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "magnutris kayitli oyun kontrol")
        {
            SetMagnuTrisLastData();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "fireworks")
        {
            FindObjectOfType<OzelFonksiyonManager>().FireWork();
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "al")
        {
            CodelessIAPStoreListener.Instance.InitiatePurchase("1ayplus");
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "store")
        {
            GameObject.Find("PanelMagaza").GetComponent<RectTransform>().GetChild(0).gameObject.SetActive(true);
            GameObject.Find("PanelMagaza").GetComponent<RectTransform>().GetChild(0).GetComponent<StoreMenu>().SetAnimatorState(1);
            //chatManager.chatScreenActivityManager.SetDeactive();
            chatManager.otomatikOdak = true;
        }
        else if (sohbet.cevaplar[bubbleType - 1].ozelFonksiyon == "chat wallpaper ayarla")
        {
            if (chatManager.PlayerDataManager.GetChatVariableValue("wallpaper tipi") != "video")
                chatManager.PlayerDataManager.AddElementToChatVariableList("wallpaper tipi", "video");
            else
                chatManager.PlayerDataManager.AddElementToChatVariableList("wallpaper tipi", "gyro");

            FindObjectOfType<IntroManager>().SetChatWallpaperActive();
        }
    }

    void CheckIfShouldDestroy()
    {
        if (!chatScreenActivity.isChatScreenActive)
        {
            for (int i = 0; i < rt.childCount; i++)
            {
                if (rt.GetChild(i).gameObject.activeInHierarchy)
                {
                    if (gameObject.GetComponent<TMP_SubMeshUI>() == null)
                        rt.GetChild(i).gameObject.SetActive(false);
                }
            }
        }
    }

    //KALDIRILACAK!
    void SetMagnuTrisLastData()
    {
        if (PlayerPrefs.GetString("GameProgress" + GameController.gameMode.ToString(), string.Empty) != string.Empty)
            chatManager.PlayerDataManager.AddElementToChatVariableList("magnutris son oyun", "var", false);
        else
            chatManager.PlayerDataManager.AddElementToChatVariableList("magnutris son oyun", "yok", false);
    }

    void SatranctanCik()
    {
        foreach(GameObject element in chatManager.answerBubbles)
        {
            element.GetComponent<AnswerBubble>().button.onClick.RemoveAllListeners();
        }

        chatManager.cgChessBoardScript.isGameEnd = true;
        StartCoroutine(SatranctanCikDelay());
    }

    IEnumerator SatranctanCikDelay()
    {
        while (chatManager.cgChessBoardScript.currentEngineProgress < 1)
        {
            yield return null;
        }
        chatManager.ClickAnswerBubble(sonrakiSohbet, bubbleType, textVariation, true);
    }

    void ProfilFotografiYuzFali()
    {
        CurrentPlayerData playerData = GameObject.Find("PlayerDatas").GetComponent<CurrentPlayerData>();
        kahveFalManager.mod = "yuz";
        kahveFalManager.gerekenFotografSayisi = 1;
        kahveFalManager.photoUploadType = 0;
        kahveFalManager.ProcessPhoto(FindObjectOfType<WelcomeScreen>().ozetKullaniciFoto.sprite.texture);

        foreach(GameObject element in chatManager.answerBubbles)
        {
            AnswerBubble bubbleManager = element.GetComponent<AnswerBubble>();
            bubbleManager.button.onClick.RemoveAllListeners();
        }
    }

    public void ChessPlayerIsWhite(int value)
    {
        if(value==1)
             chatManager.cgChessBoardScript.Mode = cgChessBoardScript.BoardMode.PlayerVsEngine;
        else if (value == 0)
            chatManager.cgChessBoardScript.Mode = cgChessBoardScript.BoardMode.EngineVsPlayer;
        else
        {
            int state = Random.Range(0, 2);

            if (state == 0)
                if (state == 1)
                    chatManager.cgChessBoardScript.Mode = cgChessBoardScript.BoardMode.PlayerVsEngine;
                else
                    chatManager.cgChessBoardScript.Mode = cgChessBoardScript.BoardMode.EngineVsPlayer;
        }
    }

    public void ChessSetDificultiy(int value)
    {
        if (value == 0)
        {
            chatManager.cgChessBoardScript.searchDepthStrong = 4;
            chatManager.cgChessBoardScript.searchDepthWeak = 3;
        }
        else if (value == 1)
        {
            chatManager.cgChessBoardScript.searchDepthStrong = 4;
            chatManager.cgChessBoardScript.searchDepthWeak = 4;
        }
        else if (value == 2)
        {
            chatManager.cgChessBoardScript.searchDepthStrong = 5;
            chatManager.cgChessBoardScript.searchDepthWeak = 4;
        }
        else if (value == 3)
        {
            chatManager.cgChessBoardScript.searchDepthStrong = 6;
            chatManager.cgChessBoardScript.searchDepthWeak = 4;
        }
    }

    public void FotografSec(string mod)
    {
        NativeGallery.Permission permission = NativeGallery.GetImageFromGallery((path) =>
        {
            if (path == null)
            {
                Debug.Log("Operation cancelled");
            }
            else
            {
                Debug.Log("Picked file: " + path);

                kahveFalManager.mod = mod;
                if (chatManager.kahveFalManager.openFilePickerDelay != null)
                {
                    StopCoroutine(chatManager.kahveFalManager.openFilePickerDelay);
                    chatManager.kahveFalManager.openFilePickerDelay = null;
                }
                List<string> pathList = chatManager.kahveFalManager.filePath;
                pathList.Add(path);

                chatManager.kahveFalManager.filePath = pathList;
            }
        });

        Debug.Log("Permission result: " + permission);
    }

    /// <summary>
    /// Bu fonksiyon secenegin text degerini ayarlar ve bu degerlerin icerisindeki metin degiskenlerini degistirir.
    /// </summary>
    public void SetTextObjects()
    {
        ChatVariables chatVariables = GameObject.Find("ChatVariables").GetComponent<ChatVariables>();

        if (bubbleType >= 1 && bubbleType <= sohbet.cevaplar.Count)
        {
            SetAltintElmasText();

            textVariation = Random.Range(0, sohbet.cevaplar[bubbleType - 1].cevapVaryasyonlari.Count);
            text.text = sohbet.cevaplar[bubbleType - 1].cevapVaryasyonlari[textVariation];
        }
        else if (bubbleType == sohbet.cevaplar.Count + 1)
        {
            if (chatManager.magnusPreferences.konuDegisButonuMetinleri != null)
            {
                if (chatManager.magnusPreferences.konuDegisButonuMetinleri.Length > 0)
                {
                    textVariation = Random.Range(0, chatManager.magnusPreferences.konuDegisButonuMetinleri.Length - 1);
                    text.text = chatManager.magnusPreferences.konuDegisButonuMetinleri[textVariation];
                }
                else
                {
                    text.text = "Baska bir konudan konusabilir miyiz?";
                }
            }
            else
            {
                text.text = "Baska bir konudan konusabilir miyiz?";
            }
        }


        text.text = chatVariables.OrtakButonlar(text.text);

        textForResize.text = text.text;
    }

    private void SetAltintElmasText()
    {
        if (sohbet.balonTipi == Sohbet.typeOfAnswerBubble.altAlta)
            return;

        altinText.text = sohbet.cevaplar[bubbleType - 1].gerekenEnerjiKons.enerji.ToString();
        altinText.transform.parent.gameObject.SetActive(sohbet.cevaplar[bubbleType - 1].gerekenEnerjiKons.enerji > 0);

        if(!altinText.transform.parent.gameObject.activeSelf)
        {
            altinText.text = sohbet.cevaplar[bubbleType - 1].uIEnerjiKonsOverwrite?.enerji.ToString();
            altinText.transform.parent.gameObject.SetActive(sohbet.cevaplar[bubbleType - 1].uIEnerjiKonsOverwrite?.enerji > 0);
        }

        elmasText.text = sohbet.cevaplar[bubbleType - 1].gerekenEnerjiKons.kons.ToString();
        elmasText.gameObject.SetActive(sohbet.cevaplar[bubbleType - 1].gerekenEnerjiKons.kons > 0);

        if (!elmasText.transform.parent.gameObject.activeSelf)
        {
            elmasText.text = sohbet.cevaplar[bubbleType - 1].uIEnerjiKonsOverwrite?.kons.ToString();
            elmasText.gameObject.SetActive(sohbet.cevaplar[bubbleType - 1].uIEnerjiKonsOverwrite?.kons > 0);
        }
    }

    /// <summary>
    /// Bu fonksiyon baloncugun ilk pozisyonunu ayarlar.
    /// </summary>
    public void SetInitialPosition()
    {
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        SetTargetPosition(rt.position);

        //Bu kisim tamamen keyfi atanmis degerlere dayanir. Objeyi canvasin sagindan disina tasir ve 50 birim daha saga iter.
        float firstXPos = canvasRt.sizeDelta.x / 2f;

        //Bu kisimda ise obje 200 birim asagi otelenir. Bu sekilde ilk olustugunda asagidan yukari gelen bir animasyon mumkun olur.
        rt.position = GameGeneral.MoveRecttransform(rt.position, canvasRt, new Vector2(firstXPos, -500));

        if (chatManager.IsPhotoMode())
        {
            int colonIndex = 0;
            int totalColonCount = 0;
            
            float sizeX = rt.sizeDelta.x + chatManager.answerBubbleFrameBlank * 2;
            float blankBetweenBubbles=0;

            switch (avaliableAnswerBubblesCount)
            {
                case 1:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                    }
                    break;
                case 2:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 2;
                            totalColonCount = 2;
                            break;

                        case 2:
                            colonIndex = 1;
                            totalColonCount = 2;
                            break;
                    }
                    break;

                case 3:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;
                            
                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                    }
                    break;

                case 4:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 2;
                            totalColonCount = 2;
                            break;

                        case 2:
                            colonIndex = 1;
                            totalColonCount = 2;
                            break;

                        case 3:
                            colonIndex = 2;
                            totalColonCount = 2;
                            break;

                        case 4:
                            colonIndex = 1;
                            totalColonCount = 2;
                            break;
                    }
                    break;
                case 5:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 2;
                            totalColonCount = 2;
                            break;

                        case 5:
                            colonIndex = 1;
                            totalColonCount = 2;
                            break;
                    }
                    break;

                case 6:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                    }
                    break;

                case 7:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount= 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 7:
                            colonIndex = 1;
                            totalColonCount = 1;
                            break;
                    }
                    break;

                case 8:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 7:
                            colonIndex = 2;
                            totalColonCount = 2;
                            break;

                        case 8:
                            colonIndex = 1;
                            totalColonCount = 2;
                            break;
                    }
                    break;
                case 9:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 7:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 8:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;
                        case 9:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                    }
                    break;
                case 10:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 7:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 8:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;
                        case 9:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                        case 10:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;
                    }
                    break;
                case 11:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 7:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 8:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;
                        case 9:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                        case 10:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;
                        case 11:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;
                    }
                    break;
                case 12:
                    switch (positionType)
                    {
                        case 1:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 2:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 3:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 4:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 5:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;

                        case 6:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;

                        case 7:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;

                        case 8:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;
                        case 9:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                        case 10:
                            colonIndex = 3;
                            totalColonCount = 3;
                            break;
                        case 11:
                            colonIndex = 2;
                            totalColonCount = 3;
                            break;
                        case 12:
                            colonIndex = 1;
                            totalColonCount = 3;
                            break;
                    }
                    break;
            }
            blankBetweenBubbles = (canvasRt.sizeDelta.x - (sizeX) * (totalColonCount)) / (totalColonCount + 1f);

            SetTargetPosition(new Vector3(canvasRt.position.x + (canvasRt.sizeDelta.x / 2f - (sizeX / 2f) * (1 + (colonIndex - 1f) * 2f) - blankBetweenBubbles * colonIndex) * canvasRt.localScale.x, targetPosition.y
             + (rt.sizeDelta.y / 2f + chatManager.answerBubbleFrameBlank) * canvasRt.localScale.y, targetPosition.z));
        }
        else
        {
            SetTargetPosition(new Vector3(canvasRt.position.x + (canvasRt.sizeDelta.x / 2f - rt.sizeDelta.x / 2f - chatManager.answerBubbleFrameBlank - chatManager.spaceBetweenAnswerBubbles) * canvasRt.localScale.x, targetPosition.y
             + (rt.sizeDelta.y / 2f + chatManager.answerBubbleFrameBlank) * canvasRt.localScale.y, targetPosition.z));
        }
    }

    /// <summary>
    /// Baloncugun turune gore boyutunu ayarlayan fonksiyon. Bu fonksiyon ayni zaman  SetTextFontSize() fonksiyonunu da cagirir.
    /// </summary>
    public void SetFirstSizes()
    {
        SetTextFontSize();

        //Canvas objesinin RectTransform componentine erisilmesi.
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        //baloncugun ContentSizeFitter componentine erisilmesi. Bu component textbox icindeki yaziya gore baloncugun RectTransform degiskeninin boyutunu ayarlar.
        ContentSizeFitter contFilter = GetComponent<ContentSizeFitter>();

        //genislik ve yukseklik degerlerinin ayarlanmasi.
        //maxWidth degeri canvasin boyutuna yuzdelik olarak ayarlanir.
        float maxWidth = canvasRt.sizeDelta.x * (50f / 100f);
        float maxHeight = rt.sizeDelta.y;

        if(sohbet.balonTipi==Sohbet.typeOfAnswerBubble.yanYana)
        {
            maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
            maxHeight = maxWidth;
        }
        //Eğer baloncuklar yan yana gelsin modundaysa
        if (chatManager.IsPhotoMode())
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.SetLayoutVertical();
            contFilter.SetLayoutHorizontal();

            switch (avaliableAnswerBubblesCount)
            {
                case 1:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 2:
                    maxWidth = canvasRt.sizeDelta.x * (40f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (40f / 100f) * (118f / 100f);
                    break;

                case 3:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 4:
                    maxWidth = canvasRt.sizeDelta.x * (40f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (40f / 100f) * (118f / 100f);
                    break;

                case 5:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 6:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 7:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 8:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 9:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 10:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 11:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 12:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
            }
            rt.sizeDelta = new Vector2(maxWidth, maxHeight);

            if (bubbleType - 1 >= 0 && bubbleType - 1 < sohbet.cevaplar.Count)
            {
                if (sohbet.cevaplar[bubbleType - 1].contentImage.image != null || !string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.gifId) || !string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.imageId))
                {
                    SetContentImageSprite();

                    text.alignment = TextAlignmentOptions.Center;
                    textForResize.alignment = text.alignment;

                    RectTransform contentImageParentRt = contentImage.gameObject.GetComponent<RectTransform>().parent.GetComponent<RectTransform>();
                    RectTransform contentImageRt = contentImage.gameObject.GetComponent<RectTransform>();

                    float contentImageRtRatio = (float)contentImageRt.rect.width / contentImageRt.rect.height;
                    float contentImageTexRatio = (float)contentImage.sprite.rect.width / contentImage.sprite.rect.height;

                    contentImageParentRt.offsetMax = new Vector2(contentImageParentRt.offsetMax.x, -(contentImageParentRt.rect.height - contentImageParentRt.rect.width));
                    contentImageParentRt.offsetMin = new Vector2(contentImageParentRt.offsetMin.x, contentImageParentRt.offsetMin.y);

                    if (contentImageRtRatio > contentImageTexRatio)
                        contentImageRt.localScale = new Vector3(1f, contentImageRtRatio  / contentImageTexRatio, 1f);
                    else
                        contentImageRt.localScale = new Vector3(contentImageTexRatio /  contentImageRtRatio, 1f, 1f);

                    if (contentImage.sprite.rect.width >= contentImage.sprite.rect.height)
                    {
                        contentImageRt.localScale = new Vector3(1f * (contentImage.sprite.rect.width / contentImage.sprite.rect.height), 1f);
                    }
                    else
                    {
                        contentImageRt.localScale = new Vector3(1f, 1f * (contentImage.sprite.rect.height / contentImage.sprite.rect.width));
                    }

                    text.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(-5, 0);
                    text.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(5, contentImage.gameObject.GetComponent<RectTransform>().rect.height + chatManager.answerBubbleFrameBlank/2f);
                }
            }
        }
        else
        {
            rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y);
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            contFilter.SetLayoutVertical();
            contFilter.SetLayoutHorizontal();

            Canvas.ForceUpdateCanvases();
            if (!chatManager.takipSohbetiAktif)
            {
                if (bubbleType - 1 >= 0 && bubbleType - 1 < sohbet.cevaplar.Count)
                {
                    if (sohbet.cevaplar[bubbleType - 1].contentImage.image != null || !string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.gifId) || !string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.imageId))
                    {
                        contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
                        contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
                        contFilter.SetLayoutVertical();
                        contFilter.SetLayoutHorizontal();

                        SetContentImageSprite();

                        if (sohbet.cevaplar[bubbleType - 1].fotografKonum == CevapSohbet.contentPhotoLocation.basta)
                        {
                            text.alignment = TextAlignmentOptions.TopLeft;
                            textForResize.alignment = text.alignment;

                            contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, -rt.sizeDelta.y - 10f);
                            contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMin.y);
                        }
                        else if (sohbet.cevaplar[bubbleType - 1].fotografKonum == CevapSohbet.contentPhotoLocation.sonda)
                        {
                            text.alignment = TextAlignmentOptions.BottomLeft;
                            textForResize.alignment = text.alignment;

                            contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMax.y);
                            contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, rt.sizeDelta.y + 10f);
                        }

                        maxHeight = rt.sizeDelta.y + maxWidth * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x);
                    }
                }
            }

            rt.sizeDelta = new Vector2(maxWidth, maxHeight);
        }

        Canvas.ForceUpdateCanvases();
    }

    public void ReCalculateContentImageSize()
    {
        //Canvas objesinin RectTransform componentine erisilmesi.
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        //baloncugun ContentSizeFitter componentine erisilmesi. Bu component textbox icindeki yaziya gore baloncugun RectTransform degiskeninin boyutunu ayarlar.
        ContentSizeFitter contFilter = GetComponent<ContentSizeFitter>();

        //genislik ve yukseklik degerlerinin ayarlanmasi.
        //maxWidth degeri canvasin boyutuna yuzdelik olarak ayarlanir.
        float maxWidth = canvasRt.sizeDelta.x * (50f / 100f);
        float maxHeight = rt.sizeDelta.y;

        if (sohbet.balonTipi == Sohbet.typeOfAnswerBubble.yanYana)
        {
            maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
            maxHeight = maxWidth;
        }
        //Eğer baloncuklar yan yana gelsin modundaysa
        if (chatManager.IsPhotoMode())
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.SetLayoutVertical();
            contFilter.SetLayoutHorizontal();

            switch (avaliableAnswerBubblesCount)
            {
                case 1:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 2:
                    maxWidth = canvasRt.sizeDelta.x * (40f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (40f / 100f) * (118f / 100f);
                    break;

                case 3:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 4:
                    maxWidth = canvasRt.sizeDelta.x * (40f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (40f / 100f) * (118f / 100f);
                    break;

                case 5:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 6:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 7:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;

                case 8:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 9:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 10:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 11:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
                case 12:
                    maxWidth = canvasRt.sizeDelta.x * (27f / 100f);
                    maxHeight = canvasRt.sizeDelta.x * (27f / 100f) * (125f / 100f);
                    break;
            }
            rt.sizeDelta = new Vector2(maxWidth, maxHeight);

            if (bubbleType - 1 >= 0 && bubbleType - 1 < sohbet.cevaplar.Count)
            {
                text.alignment = TextAlignmentOptions.Center;
                textForResize.alignment = text.alignment;

                RectTransform contentImageRt = contentImage.gameObject.GetComponent<RectTransform>();

                if (contentImage.sprite.rect.width >= contentImage.sprite.rect.height)
                {
                    contentImageRt.localScale = new Vector3(1f * (contentImage.sprite.rect.width / contentImage.sprite.rect.height), 1f);
                }
                else
                {
                    contentImageRt.localScale = new Vector3(1f, 1f * (contentImage.sprite.rect.height / contentImage.sprite.rect.width));
                }
            }
        }
        else
        {
            rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y);
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            contFilter.SetLayoutVertical();
            contFilter.SetLayoutHorizontal();

            Canvas.ForceUpdateCanvases();
            if (!chatManager.takipSohbetiAktif)
            {
                if (bubbleType - 1 >= 0 && bubbleType - 1 < sohbet.cevaplar.Count)
                {
                    contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
                    contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
                    contFilter.SetLayoutVertical();
                    contFilter.SetLayoutHorizontal();

                    if (sohbet.cevaplar[bubbleType - 1].fotografKonum == CevapSohbet.contentPhotoLocation.basta)
                    {
                        text.alignment = TextAlignmentOptions.TopLeft;
                        textForResize.alignment = text.alignment;

                        contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, -rt.sizeDelta.y - 10f);
                        contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMin.y);
                    }
                    else if (sohbet.cevaplar[bubbleType - 1].fotografKonum == CevapSohbet.contentPhotoLocation.sonda)
                    {
                        text.alignment = TextAlignmentOptions.BottomLeft;
                        textForResize.alignment = text.alignment;

                        contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMax.y);
                        contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, rt.sizeDelta.y + 10f);
                    }

                    maxHeight = rt.sizeDelta.y + maxWidth * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x);
                }
            }

            rt.sizeDelta = new Vector2(maxWidth, maxHeight);
        }

        Canvas.ForceUpdateCanvases();
    }

    void SetContentImageSprite()
    {
        if (sohbet.cevaplar[bubbleType - 1].contentImage.gifId == chatManager.magnusPreferences.wheelChartConentPhotoId)
        {
            contentImage.sprite = chatManager.wheelChartSprite;
        }
        else if (sohbet.cevaplar[bubbleType - 1].contentImage.gifId == chatManager.magnusPreferences.kullaniciPhotoId)
        {
            contentImage.sprite = FindObjectOfType<WelcomeScreen>().profilePhotoImage.sprite;
        }
        else
        {
            if (!string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.gifId))
            {
                if (sohbet.cevaplar[bubbleType - 1].contentImage.image == null)
                {
                    contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent;
                }
                else
                {
                    contentImage.sprite = sohbet.cevaplar[bubbleType - 1].contentImage.image;
                }
            }
            else
            {
                if (sohbet.cevaplar[bubbleType - 1].contentImage.image == null)
                {
                    contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent;

                    var photoManager = FindObjectOfType<PhotoManager>();
                    Sprite localPhoto = photoManager.GetSprite(sohbet.cevaplar[bubbleType - 1].contentImage.imageId);

                    if (localPhoto == null)
                    {
                        if (!string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.imageId))
                        {
                            contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent;
                            Debug.Log("Firebase veritabanindan fotograf alınıyor");
                            GetOnlineSprite(sohbet.cevaplar[bubbleType - 1].contentImage.imageId);
                        }
                    }
                    else
                    {
                        contentImage.sprite = localPhoto;
                    }
                }
                else
                {
                    contentImage.sprite = sohbet.cevaplar[bubbleType - 1].contentImage.image;
                }
            }

        }

        if (contentImage.sprite != null)

        if (contentImage.sprite != null)
        {
            var checkedSprite = ContentImageBugunGeldiKontrol(contentImage.sprite);

            if (checkedSprite != null)
                contentImage.sprite = checkedSprite;
        }

        contentImage.gameObject.SetActive(true);
    }

    private Sprite ContentImageBugunGeldiKontrol(Sprite sprite)
    {
        var photoManager = FindObjectOfType<PhotoManager>();

        var modDegiskeni = sohbet.cevaplar[bubbleType - 1].ayarlananDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));

        if (modDegiskeni != null)
        {
            var mod = modDegiskeni.degiskenDegeri;

            PlayerData.BugunGelenMod bugunGelenMod = chatManager.PlayerDataManager.datas.bugunGelenMods.Find(x => x.mod.Equals(mod));
            if (bugunGelenMod != null)
            {
                var gunlukMod = chatManager.magnusPreferences.gunlukModlar.Find(x => x.mod.Equals(mod));

                if (gunlukMod != null)
                {
                    if((chatManager.PlayerDataManager.IsPlus
                        ?gunlukMod.countPlus: gunlukMod.count)<=
                        bugunGelenMod.count)
                    {
                        return photoManager.GetSprite(sprite.name + "2");
                    }
                }
            }
        }

        return sprite;
    }

    /// <summary>
    /// Texteki karakter sayisina gore font buyulugunu ayarlayan fonksiyon.
    /// </summary>
    void SetTextFontSize()
    {
        char[] textCharacters = text.text.ToCharArray();

        if (textCharacters.Length > 400)
        {
            text.fontSize = 13;
        }
        else
        {
            text.fontSize = 17;
        }
        textForResize.fontSize = text.fontSize;
    }

    /// <summary>
    /// targetPosition degiskenini mevcut pozisyona ayarlayan fonksiyon.
    /// </summary>
    public void SetMovableFalse()
    {
        //rt.position = targetPosition;
        movable = false;
    }

    /// <summary>
    /// Her bir frame'de cagrilan ve rectTransform componentinin pozisyon degerini realPosition degerine yaklastiran fonksiyon.
    /// </summary>
    public void SetPositionToTargetPosition()
    {
        //****************************  movable DEGISKENI NE ISE YARIYOR?  ****************************
        //Eger baloncuk hareket edebilir turde ise kontrolu yapilir. Bu kontrolun yapilma amaci, eger baloncuklarin gelme animasyonu tamamlanirsa baloncuklarin hareketi scrollRect componenti
        //tarafindan kontrol edilir. Bu sayede baloncuklari ekranda belirli bir noktaya sabitleyen asagidaki kodlar calismaz.

        //****************************  isActive DEGISKENI NE ISE YARIYOR?  ****************************
        //Isactive degiskeni baloncugun olustugu anda target position'a gitmesini engeller. Baloncuklarin belirli siralamalar ile hedeflerine gitmesini istedigimiz icin
        //baloncuklari olusturduktan sonra belirli sureler ile isActive degiskenini baloncuklar icin devre disi birakiriz. Bu degiksen ne zama TRUE degerini alirsa
        //o zaman baloncugun targetPosition'a dogru gitmesini saglayacak asagidaki kodlar calismaya balsar bu kontrol ile.
        if (movable && isActive)
        {
            float t = (Time.time - startTime) / animationDuration;
            //****************************************************************************************************************************************************************************************************
            rt.position = new Vector3(Mathf.SmoothStep(previousTartgetPosition.x, targetPosition.x, t), Mathf.SmoothStep(previousTartgetPosition.y, targetPosition.y, t), rt.position.z);
        }
    }

    public void SetTargetPosition(Vector3 targetPosition)
    {
        RectTransform rt = GetComponent<RectTransform>();

        this.targetPosition = targetPosition;
        previousTartgetPosition = rt.position;
    }

    public void GetOnlineSprite(string fileName)
    {
        Sprite downdloadedSprite = FindObjectOfType<PhotoManager>().GetDownloadedSprite(fileName);
        if (downdloadedSprite == null)
        {
            FirebaseStorage storage = FirebaseStorage.DefaultInstance;

            // Create a storage reference from our storage service
            StorageReference storageRef =
                storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

            // Create a reference to the file you want to upload
            StorageReference riversRef = storageRef.Child("Images/" + fileName);

            // Start downloading a file
            riversRef.GetDownloadUrlAsync().ContinueWithOnMainThread(taskGetUrl =>
            {
                Debug.Log("Image url is: " + taskGetUrl.Result.ToString());
                StartCoroutine(DownloadImage(fileName, taskGetUrl.Result.ToString()));

            });
        }
        else
        {
            Debug.Log("Fotoğraf daha önce indirildiği için tekrar indirilmedi.");
            contentImage.sprite = downdloadedSprite;
        }
    }

    IEnumerator DownloadImage(string fileName, string url)
    {
        UnityWebRequest request = UnityWebRequestTexture.GetTexture(url);
        yield return request.SendWebRequest();
        if (request.isNetworkError || request.isHttpError)
            Debug.Log(request.error);
        else
        {
            Texture2D texture = ((DownloadHandlerTexture)request.downloadHandler).texture;
            Debug.Log("Wheel chart basariyla indirildi ve kaydedildi.");
            contentImage.sprite = Sprite.Create(texture, new Rect(0.0f, 0.0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100.0f);
            FindObjectOfType<PhotoManager>().AddTextureToDownloadedTexture(fileName, contentImage.sprite);
        }
    }
}