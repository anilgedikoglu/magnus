using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Michsky.UI.ModernUIPack;
using TMPro;
using Firebase.Storage;
using Firebase.Extensions;
using UnityEngine.Networking;

public class SpeechBubbleRight : MonoBehaviour
{
    //*****************************  Kullanim Amaci  *****************************
    //targetposition degiskeni bu cevap baloncugunun gitmesi gereken noktanin koordinatlarini barindiran degiskendir. Baloncugun mevcut pozisyonu bu degere her bir framede Move fonksiyonunda belirtildigi oranda yaklasir.
    [HideInInspector] public Vector3 targetPosition;

    //*****************************  Kullanim Amaci  *****************************
    //previousTartgetPosition degiskeni baloncuk hareket etmeye basladigi anda baloncugun bulundugu degeri icinde barindirir. Bu basitce baloncugun hareket ettigi yonu anlamakta kullanilir.
    //Detaylar SetPositionToRealPotion fonksiyonuna bak.
    private Vector3 previousTartgetPosition;

    [HideInInspector] public bool forceToMultipleLines;
    [HideInInspector] public int bubbleType;
    [HideInInspector] public int variation;
    [HideInInspector] public Sohbet sohbet;
    [HideInInspector] public TakipSohbeti takipSohbet;
    [HideInInspector] public bool takipSohbetiAktif;
    [HideInInspector] public int answerBubbleType;    //Bu degisken sadece cevap butonuna uygun cevap olusturulurken cevap baloncugunun onu olusturan cevap butonunun bubbletpye degiskenine sahip olmak icin kullanilir.
    [HideInInspector] public bool movable;
    [HideInInspector] public bool isActive;
    [HideInInspector] public float startTime;
    [HideInInspector] public ChatManager chatManager;
    [HideInInspector] public RectTransform contentImageRt;

    private bool gifSizeSet;

    public TMP_Text text;
    public TMP_Text textMain;
    public ContentSizeFitter contFilter;
    public RectTransform rt;
    public RectTransform profilePhotoRect;
    public Image profilePhoto;
    public Image contentImage;
    public float animationDuration;

    public void Start()
    {
        contentImageRt = contentImage.GetComponent<RectTransform>();

        RectTransform rt = GetComponent<RectTransform>();
        //rt.localScale = new Vector3(0.1f, 0.4f, 1f);

        profilePhoto.gameObject.GetComponent<RectTransform>().localScale = new Vector3(profilePhoto.gameObject.GetComponent<RectTransform>().localScale.x, profilePhoto.gameObject.GetComponent<RectTransform>().localScale.y * (profilePhoto.sprite.rect.height / profilePhoto.sprite.rect.width), profilePhoto.gameObject.GetComponent<RectTransform>().localScale.z);

        SetPosition();
    }

    void Update()
    {
        //SetPositionToTargetPosition();
        //CheckIfShouldDestroy();
    }


    public void SetTextObjects()
    {
        ChatManager chatManager = GameObject.Find("ChatManager").GetComponent<ChatManager>();
        ChatVariables chatVariables = GameObject.Find("ChatVariables").GetComponent<ChatVariables>();

        //bubble type 0 sag baloncuk yani kullanici baloncugunun standart oldugu, sohbet ve takip sohbette neyi sectiyse onu soyledigi haldir. 0 disinda bir deger icin ozel metinler atanir.
        if (bubbleType == sohbet.cevaplar.Count + 1)
        {
            text.text = chatManager.magnusPreferences.konuDegisButonuMetinleri[variation];
        }
        else
        {
            text.text = sohbet.cevaplar[answerBubbleType - 1].cevapVaryasyonlari[variation];
        }


        text.text = chatVariables.OrtakButonlar(text.text);
        forceToMultipleLines = chatVariables.CheckForceMultipleLine(text.text);

        textMain.text = text.text;
    }

    void CheckIfShouldDestroy()
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();
        ChatScreenActivity chatScreenActivity = GameObject.Find("ChatScreen").GetComponent<ChatScreenActivity>();

        if (rt.position.y > canvasRt.position.y + canvasRt.sizeDelta.y * canvasRt.localScale.y || !chatScreenActivity.isChatScreenActive)
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
        else
        {
            for (int i = 0; i < rt.childCount; i++)
            {
                if (!rt.GetChild(i).gameObject.activeInHierarchy)
                {
                    rt.GetChild(i).gameObject.SetActive(true);
                }
            }
        }

    }

    public void SetPosition()
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();
        ChatManager chatManager = FindObjectOfType<ChatManager>();

        SetTargetPosition(rt.position);

        float firstXPos = canvasRt.sizeDelta.x / 2f + rt.sizeDelta.x / 2f + chatManager.spaceBetweenBubbles * 2f;

        rt.position = GameGeneral.MoveRecttransform(rt.position, canvasRt, new Vector2(firstXPos, -200));
        SetTargetPosition(new Vector3(canvasRt.position.x + (canvasRt.sizeDelta.x / 2f - rt.sizeDelta.x / 2f - 30f - profilePhotoRect.sizeDelta.x) * canvasRt.localScale.x, targetPosition.y 
            + (rt.sizeDelta.y / 2f + chatManager.spaceBetweenBubbles) * canvasRt.localScale.y, targetPosition.z));
    }

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
        textMain.fontSize = text.fontSize;
    }

    /// <summary>
    /// Baloncugun turune gore boyutunu ayarlayan fonksiyon. Bu fonksiyon ayni zaman  SetTextFontSize() fonksiyonunu da cagirir.
    /// </summary>
    public void SetFirstSizes()
    {
        SetTextFontSize();

        //Canvas objesinin RectTransform componentine erisilmesi.
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        //genislik ve yukseklik degerlerinin ayarlanmasi.
        //maxWidth degeri canvasin boyutuna yuzdelik olarak ayarlanir.
        float maxWidth = canvasRt.sizeDelta.x * (80f / 100f);
        float minWidth = 50f;
        float minHeight = 35f;

        //****************************  #1 - BALONCUGUN HORIZONTAL OLARAK TEXTE GORE BOYUTLANDIRILMASI.  ****************************
        //Ilk once horizontal olarak texte gore boyut ayarliyoruz. Bunu once yapmamizin sebebi eger balon horizontal olarak max boyuta ulasmamissa vertical uzunlugu standart boyutta birakip horizontal olarak
        //boyutlandiriyoruz. 
        SetContentSizeFilter("horizontal");
        rt.sizeDelta = new Vector2(rt.sizeDelta.x, minHeight);

        //****************************  Canvas.ForceUpdateCanvases() FONKSIYONUNUN KULLANIM NEDENI  ****************************
        //ContentSize filter componenti ile her yapilan boyutlandirma isleminden sonra Canvas Update'e zorlanmalidir. Aksi taktirde size'in ayarlanmasi birkac frame sonraya atilabilir
        //bu durumda boyut mevcut frame icinde alanamadigi icin boyutlandirmada hatalar olusur.
        Canvas.ForceUpdateCanvases();

        //Yukaridaki #1 nolu kisimda sadece yatay duzlemde texte gore boyutlandirma ayarladigimiz icin simdi kontrol etmemiz gereken durum yatay duzlemde baloncugun bizim olmasini istedigimiz
        //Maksimum degerden daha buyuk bir degere esitlenip esitlenmedigi. Eger balouncugun yatay boyutu olmasini istedigimiz maksimum boyur olan maxWidth degerinden buyukse
        //artik yatay duzlemdeki boyutunu ContentSizeFitter compoenenti ile ayarlamak yerine maxWidth componentinin degerine sabitliyoruz. Dusey boyutunu ise ContentSizeFitter componenti ile ayarliyoruz.
        if (rt.sizeDelta.x > maxWidth || forceToMultipleLines)
        {
            SetContentSizeFilter("vertical");
            rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y);
        }
        else if (rt.sizeDelta.x < minWidth)
        {                                                                                       //Onemli bir diger kontrol de eger yatay boyutun alabilecegi minumum deger olan minWidth'den kucuk oldugu durum. 
            SetContentSizeFilter("none");                                                       //Bu durumda ise ContentSizeFitter compenentinin hem yatayda hem duseyde boyut ayarlamasini kapatiyoruz ve
            rt.sizeDelta = new Vector2(minWidth, minHeight);                                    //hem yatayda hem de duseyde sirasiyla minWidth ve minHeight degerlerine esitlenmesini sagliyoruz.
        }
        Canvas.ForceUpdateCanvases();

        if (!takipSohbetiAktif)
        {
            if (bubbleType - 1 >= 0 && bubbleType - 1 < sohbet.cevaplar.Count)
            {
                if (sohbet.cevaplar[bubbleType - 1].contentImage.image != null || !string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.gifId) || !string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.imageId))
                {
                    text.alignment = TextAlignmentOptions.Left;
                    textMain.alignment = text.alignment;

                    maxWidth = canvasRt.sizeDelta.x * (45f / 100f);
                    rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y);
                    SetContentSizeFilter("vertical");

                    Canvas.ForceUpdateCanvases();

                    
                    SetContentSizeFilter("none");

                    SetContentImageSprite();


                    if (sohbet.cevaplar[bubbleType - 1].fotografKonum == CevapSohbet.contentPhotoLocation.basta)
                    {
                        contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, -rt.sizeDelta.y);
                        contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMin.y);

                        rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y + maxWidth * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x));

                        text.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(text.gameObject.GetComponent<RectTransform>().offsetMax.x, text.gameObject.GetComponent<RectTransform>().offsetMax.y);
                        text.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(text.gameObject.GetComponent<RectTransform>().offsetMin.x, contentImage.gameObject.GetComponent<RectTransform>().rect.height + chatManager.bubbleFrameBlank / 2f);
                    }
                    else if (sohbet.cevaplar[bubbleType - 1].fotografKonum == CevapSohbet.contentPhotoLocation.sonda)
                    {
                        contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMax.y);
                        contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, rt.sizeDelta.y);

                        rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y + maxWidth * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x));

                        text.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(text.gameObject.GetComponent<RectTransform>().offsetMax.x, -contentImage.gameObject.GetComponent<RectTransform>().rect.height - chatManager.bubbleFrameBlank / 2f);
                        text.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(text.gameObject.GetComponent<RectTransform>().offsetMin.x, text.gameObject.GetComponent<RectTransform>().offsetMin.y);
                    }
                }
            }
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
                    if (!string.IsNullOrEmpty(sohbet.cevaplar[bubbleType - 1].contentImage.imageId))
                    {
                        contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent;
                        Debug.Log("Firebase veritabanindan fotograf alınıyor");
                        GetOnlineSprite(sohbet.cevaplar[bubbleType - 1].contentImage.imageId);
                    }
                }
                else
                {
                    contentImage.sprite = sohbet.cevaplar[bubbleType - 1].contentImage.image;
                }
            }

        }
        contentImage.gameObject.SetActive(true);
    }

    private void SetContentSizeFilter(string axis)
    {
        if (axis == "horizontal")
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
        }
        else if (axis == "vertical")
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        }
        else
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
        }
        contFilter.SetLayoutVertical();
        contFilter.SetLayoutHorizontal();
        Canvas.ForceUpdateCanvases();
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

    public void SetTargetPosition(Vector3 realPosition)
    {
        RectTransform rt = GetComponent<RectTransform>();

        this.targetPosition = realPosition;
        previousTartgetPosition = rt.position;
    }

    public void GetOnlineSprite(string fileName)
    {
        Sprite downloadedSprite = FindObjectOfType<PhotoManager>().GetDownloadedSprite(fileName);
        if (downloadedSprite == null)
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
            contentImage.sprite = downloadedSprite;
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
