using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;

public class PercentileManager : MonoBehaviour
{
    public List<PercentileBar> percentileBars;

    public Text header;
    public Image contentImage;

    RectTransform rt;

    public List<RectTransform> verticalLayoutGroups;

    //Colors
    public Color red, green, blue, yellow, orange, pink, magenta, cyan, brown, bakcgroundStadartColor;
    public Sprite scfiSprite;

    public GameObject barPrefab;
    public GameObject fireBar;

    public RectTransform barFolder;

    GameObject contentGameObj;

    public ScrollRect scrollRect;
    public Scrollbar scrollbar;

    public VideoPlayer videoPlayer;
    public Animator videoAnimator;

    public List<PanelVideo> panelVideos;
    [HideInInspector] public PanelVideo panelVideo;
    float videoLength;

    private CurrentPlayerData playerData;

    /// <summary>
    /// Bu degisken bilgi ekraninda zoom paneli 
    /// acilirsa logoyu kapatmak icin tutulur.
    /// </summary>
    public GameObject bilgiEkraniMagnusLogo;

    [HideInInspector] public bool showAdOnClose;

    private RenderedText.Text renderedText;

    [SerializeField] private GameObject lockPanel;

    // Start is called before the first frame update
    void Start()
    {
        rt = gameObject.GetComponent<RectTransform>();
        contentGameObj = gameObject.GetComponent<RectTransform>().GetChild(0).gameObject;
        playerData = FindObjectOfType<CurrentPlayerData>();

        showAdOnClose = false;
    }

    // Update is called once per frame
    void Update()
    {
        if (scrollRect.velocity.y != 0)
        {
            Image scrollbarImage = scrollbar.image;
            scrollbar.image.color = new Color(scrollbarImage.color.r, scrollbarImage.color.r, scrollbarImage.color.r, 0.5f);
        }
        else
        {
            Image scrollbarImage = scrollbar.image;
            scrollbar.image.color = new Color(scrollbarImage.color.r, scrollbarImage.color.r, scrollbarImage.color.r, 0f);
        }
    }

    public void InitiliazeBars(string jsonData, Sprite sprite)
    {
        DeleteAllBars();


        BarData barData = JsonUtility.FromJson<BarData>(jsonData);

        foreach (PanelVideo video in panelVideos)
        {
            if (video.headers.Exists(x => x.ToLower().Equals(playerData.GetChatVariableValue("mod"))))
            {
                panelVideo = video;
                break;
            }
            else
            {
                panelVideo = null;
            }
        }

        if (panelVideo == null)
        {
            videoLength = 0;
            StartCoroutine(SetVideoAnimatorExitState(videoLength));
        }
        else
        {
            if (panelVideo.videoClip == null)
            {
                videoLength = 0;
                StartCoroutine(SetVideoAnimatorExitState(videoLength));
            }
            else
            {
                videoLength = (float)panelVideo.videoClip.length;
                StartCoroutine(SetVideoAnimatorExitState(videoLength));
                videoPlayer.clip = panelVideo.videoClip;
            }
        }

        header.text = barData.header;

        if (sprite != null)
        {
            contentImage.gameObject.SetActive(true);
            contentImage.sprite = sprite;
        }
        else
        {
            contentImage.gameObject.SetActive(false);
        }

        percentileBars = new List<PercentileBar>(barData.bars.Count);

        foreach(Bar bar in barData.bars)
        {
            var barObject = Instantiate(barPrefab, barFolder);
            percentileBars.Add(barObject.GetComponent<PercentileBar>());

            List<string> explanationContents = new List<string>();
            foreach (Bar.Explanation explanation in bar.explanations)
            {
                explanationContents.Add(explanation.content);
            }
            barObject.GetComponent<PercentileBar>().InitiliazeBar(bar.header.content, explanationContents, bar.animation.startValue / bar.animation.targetValue, bar.color, bar.style, bar.backgroundColor);

            barObject.GetComponent<PercentileBar>().animationDelay = videoLength;
        }
        StartCoroutine(ForceUpdateToVerticalLayoutGroupsDelay());
    }

    public void AddBars(string jsonData)
    {
        BarData barData = JsonUtility.FromJson<BarData>(jsonData);

        foreach (Bar bar in barData.bars)
        {
            var barObject = Instantiate(barPrefab, barFolder);
            percentileBars.Add(barObject.GetComponent<PercentileBar>());

            List<string> explanationContents = new List<string>();
            foreach (Bar.Explanation explanation in bar.explanations)
            {
                explanationContents.Add(explanation.content);
            }
            barObject.GetComponent<PercentileBar>().InitiliazeBar(bar.header.content, explanationContents, bar.animation.startValue / bar.animation.targetValue, bar.color, bar.style, bar.backgroundColor);

            barObject.GetComponent<PercentileBar>().animationDelay = videoLength;
        }
        StartCoroutine(ForceUpdateToVerticalLayoutGroupsDelay());
    }

    public void SetActive(bool value, string jsonData, Sprite sprite)
    {
        renderedText = null;

        if (value && !contentGameObj.activeInHierarchy)
        {
            InitiliazeBars(jsonData, sprite);
        }
        else if (value && contentGameObj.activeInHierarchy)
        {
            AddBars(jsonData);
        }

        contentGameObj.SetActive(value);

        StartCoroutine(ForceUpdateToVerticalLayoutGroupsDelay());

        if (!value)
        {
            bilgiEkraniMagnusLogo.SetActive(true);
            FindObjectOfType<ChatManager>().otomatikOdak = false;

            if (showAdOnClose)
                FindObjectOfType<AdManager>().ShowInterstitial();
        }
        else
        {
            bilgiEkraniMagnusLogo.SetActive(false);
        }
    }

    public void SetActive(bool value, string jsonData, Sprite sprite, RenderedText.Text renderedText)
    {
        SetActive(value, jsonData, sprite);
        this.renderedText = renderedText;
        lockPanel.SetActive(!renderedText.isOpened);
        showAdOnClose = renderedText.isOpened && showAdOnClose;
    }

    public void SetActive(bool value)
    {
        contentGameObj.SetActive(value);

        StartCoroutine(ForceUpdateToVerticalLayoutGroupsDelay());

        if (!value)
        {
            bilgiEkraniMagnusLogo.SetActive(true);
            FindObjectOfType<ChatManager>().otomatikOdak = false;

            if (showAdOnClose)
                FindObjectOfType<AdManager>().ShowInterstitial();
        }
    }

    public void ForceUpdateToVerticalLayoutGroups()
    {
        foreach (RectTransform verticalLayoutGroup in verticalLayoutGroups)
        {
            LayoutRebuilder.ForceRebuildLayoutImmediate(verticalLayoutGroup);
        }
    }

    IEnumerator ForceUpdateToVerticalLayoutGroupsDelay()
    {
        yield return new WaitForEndOfFrame();
        ForceUpdateToVerticalLayoutGroups();
    }
    IEnumerator SetVideoAnimatorExitState(float time)
    {
        yield return new WaitForSeconds(time);

        if (time > 0)
            videoAnimator.SetInteger("exit", 1);
        else
            videoAnimator.SetInteger("exit", 2);
    }


    void DeleteAllBars()
    {
        for(int i = 0; i<percentileBars.Count; i++)
        {
            Destroy(percentileBars[i].gameObject);
        }
    }

    public void ClickWatchAdButton()
    {
        if (renderedText == null)
        {
            lockPanel.SetActive(false);
        }
        else
        {
            var adManager = FindObjectOfType<AdManager>();

            adManager.ShowRewarded(() => {
                lockPanel.SetActive(false);
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
    public class PanelVideo
    {
        //Headera gore video secmek icin kullanilir
        public List<string> headers;
        public VideoClip videoClip;
    }

    [System.Serializable]
    public class Bar
    {
        [HideInInspector] public string color;
        [HideInInspector] public PercentileBar.Bar.Style style;

        [HideInInspector] public string backgroundColor;

        public Animation animation;
        public Header header;
        public List<Explanation> explanations;

        public Bar(string color, string backgroundColor, Animation animation, Header header, List<Explanation> explanations)
        {
            this.color = color;
            this.backgroundColor = backgroundColor;
            this.animation = animation;
            this.header = header;
            this.explanations = explanations;
        }

        [System.Serializable]
        public class Animation
        {
            [HideInInspector] public float startValue, targetValue;
            [HideInInspector] public float startTime;
            public float duration;

            public Animation()
            {
                startValue = 0;
                targetValue = 0;
                startTime = 0;
                duration = 0;
            }

            public Animation(float startValue, float targetValue, float startTime, float duration)
            {
                this.startValue = startValue;
                this.targetValue = targetValue;
                this.startTime = startTime;
                this.duration = duration;
            }
        }

        public void InitiliazeBar(GameObject gameObject, GameObject backgroundGameObject)
        {
            color = "";
            backgroundColor = "";
        }

        [System.Serializable]
        public class Header
        {
            public string content;

            public Header()
            {
                content = "Bar başlığı";
            }

            public Header(string content)
            {
                this.content = content;
            }
        }

        [System.Serializable]
        public class Explanation
        {
            public string content;

            public Explanation()
            {
                content = "Bar açıklaması";
            }

            public Explanation(string content)
            {
                this.content = content;
            }
        }
    }

    public class BarData
    {
        public string header;
        public List<Bar> bars;

        public BarData()
        {
            bars = new List<Bar>();
        }
    }
}
