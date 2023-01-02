    using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.Video;

using Michsky.UI;
using UnityEngine.Events;

public class PanelShowWholeTextManager : MonoBehaviour
{
    public GameObject contentWithPhoto;

    public TMP_Text textWithPhoto;

    [HideInInspector] public Sohbet sohbet;

    public Image magnusLogo;

    public ContentPhoto contentPhoto;
    public Image contentPhotoBig;

    public RectTransform textPanel;
    public RectTransform textPanelPosWithoutPhoto, textPanelPosWithPhoto, textPos;

    public int minPanelHeight = 400;

    public int maxPanelHeightWithPhoto = 500;
    public int maxPanelHeightWithoutPhoto = 750;

    public int textAreaOffset = 120;

    public ScrollRect scrollRect;

    public RectTransform canvasRect;

    public VideoPlayer wheelChartVp;
    public float wheelChartDelay;

    public ChatManager chatManager;
    public GameObject panelZoomPhoto;
    public GameObject wheelCharFlareFolder;

    public GameObject editorPanel;
    public TMP_InputField passwordInputField;
    public Text infoPanelText;
    public bool isInfoPanelActive;

    public VideoManager videoManager;

    [HideInInspector] public bool showAdOnClose;

    string mod;

    internal string sohbetId;

    /// <summary>
    /// Bu degisken bilgi ekraninda zoom paneli 
    /// acilirsa logoyu kapatmak icin tutulur.
    /// </summary>
    public GameObject bilgiEkraniMagnusLogo;

    #region Tarot
    public List<Image> tarotMultiPhoto;

    #endregion

    public GameObject lockPanel;

    private RenderedText.Text renderedText;

    [Space(20)]
    [SerializeField] private GameObject simplePanelParent;
    [SerializeField] private TMP_Text simpleFocusText;
    [SerializeField] private Image[] simpleFocusImages;
    [SerializeField] private GameObject simpleFocusWheelChartMask;
    [SerializeField] private GameObject simpleFocusAdPanel;
    [SerializeField] private GameObject[] simpleFocusDeactivateObjects;

    // Start is called before the first frame update
    void Start()
    {
        ClosePanel();
    }
    
    // Update is called once per frame
    void Update()
    {
        if (scrollRect.velocity.y != 0)
        {
            Image scrollbarImage = scrollRect.verticalScrollbar.gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<Image>();
            scrollRect.verticalScrollbar.gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<Image>().color = new Color(scrollbarImage.color.r, scrollbarImage.color.r, scrollbarImage.color.r, 0.5f);
        }
        else
        {
            Image scrollbarImage = scrollRect.verticalScrollbar.gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<Image>();
            scrollRect.verticalScrollbar.gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<RectTransform>().GetChild(0).gameObject.GetComponent<Image>().color = new Color(scrollbarImage.color.r, scrollbarImage.color.r, scrollbarImage.color.r, 0f);
        }
    }

    public void OpenPanel(List<SpeechBubbleLeft> allBubbles, Sohbet sohbet)
    {
        SetActiveNotSimpleFocusObjects(true);

           renderedText = null;
        lockPanel.SetActive(false);
        simpleFocusAdPanel.SetActive(false);

        bilgiEkraniMagnusLogo.SetActive(false);

        string text = "";
        sohbetId = "-";
        Sprite photo = null;
        RectTransform photoRect = null;
        this.sohbet = sohbet;

        //Sohbet.GerekenDegisken modDegiskeni = sohbet.gerekliDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));
        //mod = modDegiskeni != null ? modDegiskeni.degiskenDegeri : "";
        mod = chatManager.PlayerDataManager.Mod;

        videoManager.folder.SetActive(false);

        SetSohbetInfoText();

        foreach(VideoManager.VideoClipWithMod clipWithMod in videoManager.videoClipWithMods)
        {
            if (clipWithMod.mods.Contains(mod) && !string.IsNullOrEmpty(mod))
            {
                videoManager.videoPlayer.clip = clipWithMod.videoClip;
                StartCoroutine(SetActiveVideoPanel(!videoManager.wheelChart.mods.Contains(mod), clipWithMod.onVideoEnd));
                break;
            }
        }

        for (int i =0; i<allBubbles.Count; i++)
        {
            if (allBubbles[i].text.text != "" && allBubbles[i].text.text != " ")
            {
                if (i != allBubbles.Count - 1)
                {
                    text += allBubbles[i].text.text + "\n" + "\n";
                }
                else
                {
                    text += allBubbles[i].text.text;
                }
                sohbetId += allBubbles[i].sohbetId + "-";
            }

            if (allBubbles[i].contentImageActive)
            {
                photo = allBubbles[i].contentImage.sprite;
                photoRect = allBubbles[i].rt;
            }
        }

        if (photo == null)
        {
            contentWithPhoto.SetActive(true);
            tarotMultiPhoto[0].GetComponent<RectTransform>().parent.gameObject.SetActive(false);

            contentPhoto.image.gameObject.SetActive(false);
            contentPhoto.withWheelChart.gameObject.SetActive(false);

            this.textWithPhoto.text = text;
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().SetLayoutVertical();
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().SetLayoutHorizontal();

            textPanel.pivot = new Vector2(textPanel.pivot.x, 0.5f);

            Canvas.ForceUpdateCanvases();

            if (textWithPhoto.gameObject.GetComponent<RectTransform>().sizeDelta.y + minPanelHeight < maxPanelHeightWithPhoto)
            {
                textPanel.sizeDelta = new Vector2(textPanel.sizeDelta.x,
                    Mathf.Clamp(textWithPhoto.gameObject.GetComponent<RectTransform>().sizeDelta.y + textAreaOffset, minPanelHeight, maxPanelHeightWithoutPhoto));
                scrollRect.enabled = false;
            }
            else
            {
                textPanel.sizeDelta = new Vector2(textPanel.sizeDelta.x, maxPanelHeightWithoutPhoto);
                scrollRect.enabled = true;
            }

            contentPhoto.image.sprite = photo;
            contentPhoto.withWheelChart.sprite = contentPhoto.image.sprite;

            textPanel.position = textPanelPosWithoutPhoto.position;
        }
        else
        {
            contentWithPhoto.SetActive(true);
            tarotMultiPhoto[0].GetComponent<RectTransform>().parent.gameObject.SetActive(false);

            contentPhoto.image.gameObject.SetActive(!videoManager.wheelChart.mods.Contains(mod));
            contentPhoto.withWheelChart.gameObject.SetActive(videoManager.wheelChart.mods.Contains(mod));

            this.textWithPhoto.text = text;
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().horizontalFit = ContentSizeFitter.FitMode.Unconstrained; 
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().SetLayoutVertical();
            textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().SetLayoutHorizontal();

            textPanel.pivot = new Vector2(textPanel.pivot.x, 1f);

            Canvas.ForceUpdateCanvases();

            if (textWithPhoto.gameObject.GetComponent<RectTransform>().sizeDelta.y + minPanelHeight < maxPanelHeightWithPhoto)
            {
                textPanel.sizeDelta = new Vector2(textPanel.sizeDelta.x, 
                    Mathf.Clamp(textWithPhoto.gameObject.GetComponent<RectTransform>().sizeDelta.y + textAreaOffset, minPanelHeight, maxPanelHeightWithPhoto));
                scrollRect.enabled = false;
            }
            else
            {
                textPanel.sizeDelta = new Vector2(textPanel.sizeDelta.x, maxPanelHeightWithPhoto);
                scrollRect.enabled = true;
            }

            contentPhoto.image.sprite = photo;
            contentPhoto.withWheelChart.sprite = contentPhoto.image.sprite;

            textPanel.position = textPanelPosWithPhoto.position;
        }

        if (videoManager.wheelChart.mods.Contains(mod))
        {
            foreach (VideoManager.VideoClipWithMod clipWithMod in videoManager.videoClipWithMods)
            {
                if (clipWithMod.mods.Contains(mod) && !string.IsNullOrEmpty(mod))
                {
                    PanelZoomPhotoSetActive(true);
                    break;
                }
            }

            //asagidaki iki deger PanelZoomPhotoSetActive fonksiynu her cagrildiginda renk icin black animasyon degeri icin 0a esitlenir. sadece openPanel yani bu fonksiyon icin o esitlemeler degistirilip tekrar white ve 1 yapilir.
            //bu islemin aynisi PanelZoomPhotoSetActive fonksiyonuna ilkAcis diye bir bool parametresi tanimlayarak yapilabilirdi. ama birden fazla parametre olursa inspector icinde tanimlama yapialmayacagindan bu yola basvuruldu.
            //Bu yapi ilerde daha mantikli bir yapi ile degisilmeli.
            wheelChartVp.gameObject.GetComponent<RawImage>().color = Color.white;
            panelZoomPhoto.GetComponent<Animator>().SetInteger("entrytype", 1);
            wheelCharFlareFolder.SetActive(true);
            videoManager.wheelChart.front.SetActive(true);
        }
        else
        {
            PanelZoomPhotoSetActive(false);
            wheelCharFlareFolder.SetActive(false);
            videoManager.wheelChart.front.SetActive(false);
        }

        textWithPhoto.gameObject.GetComponent<RectTransform>().position = textPos.position;

        StartCoroutine(StartStopWheelChartVp());

        SetInfoTextActive(false);

        SetSimplePanel(new Sprite[] { photo });
    }

    public void OpenPanel(List<SpeechBubbleLeft> allBubbles, Sohbet sohbet, RenderedText.Text renderedText)
    {
        OpenPanel(allBubbles, sohbet);
        lockPanel.SetActive(!renderedText.isOpened);
        simpleFocusAdPanel.SetActive(!renderedText.isOpened);
        this.renderedText = renderedText;
    }


    public void OpenPanel(List<SpeechBubbleLeft> allBubbles, Sohbet sohbet, List<Sprite> tarotCards)
    {
        SetActiveNotSimpleFocusObjects(true);

        renderedText = null;
        lockPanel.SetActive(false);
        simpleFocusAdPanel.SetActive(false);

        bilgiEkraniMagnusLogo.SetActive(false);

        string text = "";
        sohbetId = "-";
        Sprite photo = null;
        RectTransform photoRect = null;
        this.sohbet = sohbet;

        //Sohbet.GerekenDegisken modDegiskeni = sohbet.gerekliDegiskenler.Find(x => x.degiskenAdi.Equals("mod"));
        //mod = modDegiskeni != null ? modDegiskeni.degiskenDegeri : "";

        mod = chatManager.PlayerDataManager.Mod;
        videoManager.folder.SetActive(false);

        SetSohbetInfoText();

        for (int i = 0; i < allBubbles.Count; i++)
        {
            if (allBubbles[i].text.text != "" && allBubbles[i].text.text != " ")
            {
                if (i != allBubbles.Count - 1)
                {
                    text += allBubbles[i].text.text + "\n" + "\n";
                }
                else
                {
                    text += allBubbles[i].text.text;
                }
                sohbetId += allBubbles[i].sohbetId + "-";
            }

            if (allBubbles[i].contentImageActive)
            {
                photo = allBubbles[i].contentImage.sprite;
                photoRect = allBubbles[i].rt;
            }
        }

        Debug.Log(allBubbles.Count);

        contentWithPhoto.SetActive(true);
        if (tarotCards.Count == 3)
        {
            tarotMultiPhoto[0].GetComponent<RectTransform>().parent.gameObject.SetActive(true);

            tarotMultiPhoto[0].sprite = tarotCards[0];
            tarotMultiPhoto[1].sprite = tarotCards[1];
            tarotMultiPhoto[2].sprite = tarotCards[2];

            contentPhoto.image.gameObject.SetActive(false);
            contentPhoto.withWheelChart.gameObject.SetActive(false);

        }
        else if (tarotCards.Count == 1)
        {
            tarotMultiPhoto[0].GetComponent<RectTransform>().parent.gameObject.SetActive(false);

            contentPhoto.image.sprite = tarotCards[0];
            contentPhoto.withWheelChart.sprite = contentPhoto.image.sprite;

            contentPhoto.image.gameObject.SetActive(true);
            contentPhoto.withWheelChart.gameObject.SetActive(true);
        }
        else
        {
            contentPhoto.image.sprite = photo;
            contentPhoto.withWheelChart.sprite = contentPhoto.image.sprite;
            tarotMultiPhoto[0].GetComponent<RectTransform>().parent.gameObject.SetActive(false);

            contentPhoto.withWheelChart.gameObject.SetActive(true);
            contentPhoto.image.gameObject.SetActive(true);
        }


        this.textWithPhoto.text = text;
        textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
        textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().SetLayoutVertical();
        textWithPhoto.gameObject.GetComponent<ContentSizeFitter>().SetLayoutHorizontal();

        textPanel.pivot = new Vector2(textPanel.pivot.x, 1f);

        Canvas.ForceUpdateCanvases();

        if (textWithPhoto.gameObject.GetComponent<RectTransform>().sizeDelta.y + minPanelHeight < maxPanelHeightWithPhoto)
        {
            textPanel.sizeDelta = new Vector2(textPanel.sizeDelta.x,
                Mathf.Clamp(textWithPhoto.gameObject.GetComponent<RectTransform>().sizeDelta.y + textAreaOffset, minPanelHeight, maxPanelHeightWithPhoto));
            scrollRect.enabled = false;
        }
        else
        {
            textPanel.sizeDelta = new Vector2(textPanel.sizeDelta.x, maxPanelHeightWithPhoto);
            scrollRect.enabled = true;
        }

        textPanel.position = textPanelPosWithPhoto.position;

        if (videoManager.wheelChart.mods.Contains(mod))
        {
            PanelZoomPhotoSetActive(true);
            //asagidaki iki deger PanelZoomPhotoSetActive fonksiynu her cagrildiginda renk icin black animasyon degeri icin 0a esitlenir. sadece openPanel yani bu fonksiyon icin o esitlemeler degistirilip tekrar white ve 1 yapilir.
            //bu islemin aynisi PanelZoomPhotoSetActive fonksiyonuna ilkAcis diye bir bool parametresi tanimlayarak yapilabilirdi. ama birden fazla parametre olursa inspector icinde tanimlama yapialmayacagindan bu yola basvuruldu.
            //Bu yapi ilerde daha mantikli bir yapi ile degisilmeli.
            wheelChartVp.gameObject.GetComponent<RawImage>().color = Color.white;
            panelZoomPhoto.GetComponent<Animator>().SetInteger("entrytype", 1);
            wheelCharFlareFolder.SetActive(true);
            videoManager.wheelChart.front.SetActive(true);
        }
        else
        {
            PanelZoomPhotoSetActive(false);
            wheelCharFlareFolder.SetActive(false);
            videoManager.wheelChart.front.SetActive(false);
        }

        textWithPhoto.gameObject.GetComponent<RectTransform>().position = textPos.position;

        StartCoroutine(StartStopWheelChartVp());

        SetInfoTextActive(false);

        chatManager.tarotSohbetleri = new List<Sohbet>();



        if (tarotCards.Count == 3)
        {
            SetSimplePanel(tarotCards.ToArray());

        }
        else if (tarotCards.Count == 1)
        {
            SetSimplePanel(tarotCards.ToArray());
        }
        else
        {
            SetSimplePanel(null);
        }
    }

    public void OpenPanel(List<SpeechBubbleLeft> allBubbles, Sohbet sohbet, List<Sprite> tarotCards, RenderedText.Text renderedText)
    {
        OpenPanel(allBubbles, sohbet, tarotCards);
        lockPanel.SetActive(!renderedText.isOpened);
        simpleFocusAdPanel.SetActive(!renderedText.isOpened);
        this.renderedText = renderedText;
    }

    public void SetInfoTextActive(bool value)
    {
        if (value)
        {
            string dogumGunu = chatManager.PlayerDataManager.GetChatVariableValue("dogum gunu");
            string dogumAyi = chatManager.PlayerDataManager.GetChatVariableValue("dogum ayi");
            char[] dogumYili = chatManager.PlayerDataManager.GetChatVariableValue("dogum yili").ToCharArray();
            string dogumYiliSonIki = dogumYili[dogumYili.Length - 2].ToString() + dogumYili[dogumYili.Length - 1].ToString();

            char[] mevcutYil = System.DateTime.Today.Year.ToString().ToCharArray();
            string mevcutYilSonIki = mevcutYil[mevcutYil.Length - 2].ToString() + mevcutYil[mevcutYil.Length - 1].ToString();

            if (passwordInputField.text == System.DateTime.Today.Day.ToString() + System.DateTime.Today.Month.ToString() + mevcutYilSonIki + dogumGunu + dogumAyi + dogumYiliSonIki || passwordInputField.text== "17309421580")
            {
                infoPanelText.gameObject.SetActive(true);
                passwordInputField.gameObject.SetActive(false);
            }
            else
            {
                infoPanelText.gameObject.SetActive(false);
                passwordInputField.gameObject.SetActive(true);
                editorPanel.SetActive(false);
                Debug.Log(System.DateTime.Today.Day.ToString() + System.DateTime.Today.Month.ToString() + mevcutYilSonIki + dogumGunu + dogumAyi + dogumYiliSonIki);
            }
        }
        else
        {
            infoPanelText.gameObject.SetActive(false);
            passwordInputField.gameObject.SetActive(true);
            editorPanel.SetActive(false);
        }
        passwordInputField.text = "";
    }

    internal bool simplePanelActive = false;
    public enum SimplePanelSizeType { normal = 1, small = 0, large = 2 }
    private int simplePanelCurrentSize = 1;
    private void SetSimplePanel(Sprite[] sprites)
    {
        //Sohbete baglanacak!
        if (!simplePanelActive)
        {
            simplePanelParent.SetActive(false);
            return;
        }

        SetSimplePanelSize(1);

        simplePanelParent.SetActive(true);
        SetActiveNotSimpleFocusObjects(false);

        simpleFocusText.text = textWithPhoto.text;

        simpleFocusWheelChartMask.gameObject.SetActive(false);

        if (sprites != null)
        {
            for (int i = 0; i < simpleFocusImages.Length; i++)
            {
                simpleFocusImages[i].gameObject.SetActive(sprites.Length > i);

                if (sprites.Length > i)
                {
                    if (sprites[i] == null)
                    {
                        simpleFocusImages[i].gameObject.SetActive(false);
                    }
                    else
                    {
                        simpleFocusImages[i].sprite = sprites[i];
                        simpleFocusImages[i].gameObject.SetActive(true);
                    }
                }
                else
                {
                    simpleFocusImages[i].gameObject.SetActive(false);
                }
            }

            if (sprites.Length > 0)
                simpleFocusWheelChartMask.gameObject.SetActive(videoManager.wheelChart.mods.Contains(mod));
        }
        else
        {
            for (int i = 0; i < simpleFocusImages.Length; i++)
            {
                simpleFocusImages[i].gameObject.SetActive(false);
            }
        }
    }

    public void SetSimplePanelSize(int sizeTypeInt)
    {
        var sizeType = (SimplePanelSizeType)sizeTypeInt;
        switch (sizeType)
        {
            case SimplePanelSizeType.normal:
                simpleFocusText.fontSize = 21;
                break;

            case SimplePanelSizeType.large:
                simpleFocusText.fontSize = 26;//sad
                break;

            case SimplePanelSizeType.small:
                simpleFocusText.fontSize = 18;
                break;
        }
    }

    public void IncreaseSimplePanelTextSize()
    {
        simplePanelCurrentSize = Mathf.Clamp(simplePanelCurrentSize + 1, 0, 2);

        SetSimplePanelSize(simplePanelCurrentSize);
    }

    public void DecreaseSimplePanelTextSize()
    {
        simplePanelCurrentSize = Mathf.Clamp(simplePanelCurrentSize - 1, 0, 2);

        SetSimplePanelSize(simplePanelCurrentSize);
    }

    private void SetActiveNotSimpleFocusObjects(bool isActive)
    {
        foreach (var element in simpleFocusDeactivateObjects)
            element.gameObject.SetActive(isActive);
    }

    void SetSohbetInfoText()
    {
        infoPanelText.text = "";
        infoPanelText.text += $"Sohbet dosyası adı: {sohbet.name}\n\n";
        infoPanelText.text += $"Sohbet Id: {sohbet.idIndex}\n\n";

        foreach(Sohbet.GerekenDegisken chatDegiskeni in sohbet.gerekliDegiskenler)
        {
            infoPanelText.text += $"Gereken değişken adı: {chatDegiskeni.degiskenAdi}, değeri: {chatDegiskeni.degiskenDegeri}\n\n";
        }

        foreach (Sohbet.AyarlanacakDegisken chatDegiskeni in sohbet.ayarlananDegiskenler)
        {
            infoPanelText.text += $"Ayarlanacak değişken adı: {chatDegiskeni.degiskenAdi}, değeri: {chatDegiskeni.degiskenDegeri}\n\n";
        }

        infoPanelText.text += $"Sohbet bitimi anamenüye dön: {sohbet.sohbetBititmindeAnamenuyeDon}\n\n";
    }

    IEnumerator StartStopWheelChartVp()
    {
        //We are waiting little bit for the entry animation.
        yield return new WaitForSeconds(0.1f);
        if (videoManager.wheelChart.mods.Contains(mod))
        {
            wheelChartVp.Play();
            yield return new WaitForSeconds((float)wheelChartVp.length + wheelChartDelay);
            PanelZoomPhotoSetActive(false);
        }
        else
        {
            wheelChartVp.Stop();
        }
    }

    IEnumerator SetActiveVideoPanel(bool value, UnityEvent onEnd)
    {
        if (value)
        {
            videoManager.folder.SetActive(value);
            yield return new WaitForSeconds((float)videoManager.videoPlayer.clip.length);
            onEnd.Invoke();
            videoManager.folder.SetActive(!value);
        }
        else
        {
            videoManager.folder.SetActive(value);
        }
    }

    public void PanelZoomPhotoSetActive(bool value)
    {
        panelZoomPhoto.GetComponent<Animator>().SetInteger("entrytype", 0);
        wheelChartVp.gameObject.GetComponent<RawImage>().color = Color.black;

        Image contentPhotoChildImage = contentPhoto.withWheelChart.gameObject.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>();
        Image contentPhotoParentImage = contentPhoto.withWheelChart.gameObject.GetComponent<RectTransform>().parent.GetComponent<Image>();

        if (videoManager.wheelChart.mods.Contains(mod))
        {
            panelZoomPhoto.SetActive(value);

            if (value)
            {
                //contentPhoto.image.color = new Color(contentPhoto.image.color.r, contentPhoto.image.color.g, contentPhoto.image.color.b, 0f);
              //  contentPhotoChildImage.color = new Color(contentPhotoChildImage.color.r, contentPhotoChildImage.color.g, contentPhotoChildImage.color.b, 0f);
             //   contentPhotoParentImage.color = new Color(contentPhotoParentImage.color.r, contentPhotoParentImage.color.g, contentPhotoParentImage.color.b, 0f);

                contentPhotoBig.sprite = contentPhoto.image.sprite;
            }
            else
            {
              //  contentPhoto.image.color = new Color(contentPhoto.image.color.r, contentPhoto.image.color.g, contentPhoto.image.color.b, 1f);
              //  contentPhotoChildImage.color = new Color(contentPhotoChildImage.color.r, contentPhotoChildImage.color.g, contentPhotoChildImage.color.b, 1f);
              //  contentPhotoParentImage.color = new Color(contentPhotoParentImage.color.r, contentPhotoParentImage.color.g, contentPhotoParentImage.color.b, 1f);
            }
        }
        else
        {
            if (contentPhoto.image.sprite != null)
            {
               // contentPhoto.image.color = new Color(contentPhoto.image.color.r, contentPhoto.image.color.g, contentPhoto.image.color.b, 1f);
              //  contentPhotoChildImage.color = new Color(contentPhotoChildImage.color.r, contentPhotoChildImage.color.g, contentPhotoChildImage.color.b, 0f);
              //  contentPhotoParentImage.color = new Color(contentPhotoParentImage.color.r, contentPhotoParentImage.color.g, contentPhotoParentImage.color.b, 0f);
            }
            else
            {
               // contentPhoto.image.color = new Color(contentPhoto.image.color.r, contentPhoto.image.color.g, contentPhoto.image.color.b, 0f);
               // contentPhotoChildImage.color = new Color(contentPhotoChildImage.color.r, contentPhotoChildImage.color.g, contentPhotoChildImage.color.b, 0f);
              //  contentPhotoParentImage.color = new Color(contentPhotoParentImage.color.r, contentPhotoParentImage.color.g, contentPhotoParentImage.color.b, 0f);
            }
        }
    }

    public void ClosePanel()
    {
        bilgiEkraniMagnusLogo.SetActive(true);

        chatManager.otomatikOdak = false;

        contentWithPhoto.SetActive(false);

        if (showAdOnClose)
            FindObjectOfType<AdManager>().ShowInterstitial();
    }

    public void ClickWatchAdButton()
    {
        if (renderedText == null)
        {
            lockPanel.SetActive(false);
            simpleFocusAdPanel.SetActive(false);
        }
        else
        {
            var adManager = FindObjectOfType<AdManager>();

            adManager.ShowRewarded(() => {
                lockPanel.SetActive(false);
                simpleFocusAdPanel.SetActive(false);
                renderedText.isOpened = true;
                var inboxManager = FindObjectOfType<InboxManager>();
                inboxManager.isUIUpdated = false;
                StartCoroutine(inboxManager.UpdateUI(0));
                FindObjectOfType<BilgiEkraniManager>().CheckInboxNotificationState();
            });
        }
    }

    public void ClickBuyPremiumButton()
    {
        showAdOnClose = false;
        FindObjectOfType<StoreMenu>(true).gameObject.SetActive(true);
    }

    [System.Serializable]
    public class ContentPhoto
    {
        public Image image;
        public Image withWheelChart;
        public GameObject flare;
    }

    [System.Serializable]
    public class VideoManager
    {
        public GameObject folder;
        public VideoPlayer videoPlayer;
        public RawImage videoManagerRawImage;
        public WheelChart wheelChart;
        public List<VideoClipWithMod> videoClipWithMods;

        [System.Serializable]
        public class VideoClipWithMod
        {
            public List<string> mods;
            public VideoClip videoClip;
            public UnityEvent onVideoEnd;
        }

        [System.Serializable]
        public class WheelChart
        {
            public List<string> mods;
            public GameObject folder;
            public GameObject front;
        }
    }
}
