using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class InboxManager : MonoBehaviour
{
    public RectTransform canvasRect;
    public List<InboxElement> inboxElements;

    public int elementCount = 10;

    public float deleteSwipeRatio = 0.75f;
    public float snapSwipeRatio = 0.5f;

    [HideInInspector]public CurrentPlayerData playerData;

    public BilgiEkraniSettings bilgiEkraniSettings;
    [HideInInspector] public BilgiEkraniManager bilgiEkraniManager;
    
    public delegate void OnDelete();
    public OnDelete onDelete;

    public EmptyExplanation emptyExplanation;

    [HideInInspector] public bool isUIUpdated = false;

    [HideInInspector] public PanelShowWholeTextManager panelShowText;
    [HideInInspector] public PercentileManager percentileManager;

    [HideInInspector] public bool updateUIAgain;

    [SerializeField] internal List<DownloadedImage> downloadedImageCache;

    private void Awake()
    {
        panelShowText = FindObjectOfType<PanelShowWholeTextManager>();
        percentileManager = FindObjectOfType<PercentileManager>();
        bilgiEkraniManager = FindObjectOfType<BilgiEkraniManager>();
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    private void OnEnable()
    {
        isUIUpdated = false;
        StartCoroutine(OnEnableIEnumerator());
    }

    private void OnDisable()
    {
        //Eger Inboxtan dolayi reklam kaldiysa sifirlanir.
        panelShowText.showAdOnClose = false;
        percentileManager.showAdOnClose = false;
    }

    private IEnumerator OnEnableIEnumerator()
    {

        yield return new WaitForEndOfFrame();
        StartCoroutine(UpdateUI(0));
    }

    // Start is called before the first frame update
    void Start()
    {
        isUIUpdated = false;
        emptyExplanation.SetTexts(bilgiEkraniSettings.inbox.emptyExplanation.title,
           bilgiEkraniSettings.inbox.emptyExplanation.descreption);

        onDelete += ()=> {
            isUIUpdated = false;
            StartCoroutine(UpdateUI(0));
        };
        StartCoroutine(UpdateUI(0));
    }

    // Update is called once per frame
    void Update()
    {
        if (updateUIAgain)
        {
            isUIUpdated = false;
            StartCoroutine(UpdateUI(60));
            updateUIAgain = false;
        }
    }

    public IEnumerator UpdateUI(float delay)
    {
        yield return new WaitForSeconds(delay);
        if (!isUIUpdated)
        {
            //Eger elimizde yeterli inbox element yoksa olusuturulur.
            while (inboxElements.Count < elementCount)
            {
                yield return new WaitForSeconds(Time.deltaTime * 3f);
                var createdElement = Instantiate(inboxElements[0].gameObject, inboxElements[0].GetComponent<RectTransform>().parent);
                inboxElements.Add(createdElement.GetComponent<InboxElement>());
            }

            UpdateListPriorty();

            emptyExplanation.container.SetActive(false);
            RenderedText son5MetinTexts = playerData.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");
            if (son5MetinTexts != null && son5MetinTexts.renderedTexts.Count > 0)
            {
                for (int i = 0; i < inboxElements.Count; i++)
                {
                    if (i < son5MetinTexts.renderedTexts.Count)
                    {
                        inboxElements[i].index = son5MetinTexts.renderedTexts.Count - 1 - i;
                        inboxElements[i].gameObject.SetActive(true);
                        SetTextOfElementAsync(inboxElements[i], son5MetinTexts);

                        inboxElements[i].notification.SetActive(!son5MetinTexts.renderedTexts[inboxElements[i].index].isOpened);
                    }
                    else
                    {
                        inboxElements[i].gameObject.SetActive(false);
                    }
                }
                isUIUpdated = true;
                yield break;
            }

            //Eger bu kisma gelirse tum elemetnler kapatilir ve Inbox bos mesaji verilir!
            for (int i = 0; i < inboxElements.Count; i++)
            {
                inboxElements[i].gameObject.SetActive(false);
            }

            emptyExplanation.container.SetActive(true);

            bilgiEkraniManager.CheckInboxNotificationState();

            GetComponent<VerticalLayoutGroup>().CalculateLayoutInputVertical();
        }
        isUIUpdated = true;
    }

    public void UpdateListPriorty()
    {
        RenderedText son5MetinTexts = playerData.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");

        if (son5MetinTexts != null && son5MetinTexts.renderedTexts.Count > 0)
        {
            foreach(RenderedText.Text text in son5MetinTexts.renderedTexts)
            {
                BilgiEkraniSettings.Inbox.InboxElement inboxElement = bilgiEkraniSettings.inbox.inboxElements.Find(x => x.mod.Equals(text.mod));

                if (inboxElement == null)
                    text.priority = 0;
                else
                    text.priority = inboxElement.priority;

                float currentDif = text.uIInformation.showTimeStamp - Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now);

                if (currentDif > 0)
                    text.priority += 1;

                if (!text.isOpened)
                {
                    //Okunmayanlarin en yukarida olmasi icin
                    text.priority += 100;
                }
            }

            son5MetinTexts.renderedTexts = son5MetinTexts.renderedTexts.OrderBy(x => x.priority).ToList();
        }
    }

    async void SetTextOfElementAsync(InboxElement inboxElement, RenderedText renderedText)
    {
        await inboxElement.SetTextsAsync(renderedText);
    }

    [System.Serializable]
    public class EmptyExplanation
    {
        public GameObject container;
        public TMP_Text titleText;
        public TMP_Text descreptionText;

        public void SetTexts(string title, string descreption)
        {
            titleText.text = title;
            descreptionText.text = descreption;
        }
    }

    [System.Serializable]
    public class DownloadedImage
    {
        public string ID;
        public Sprite sprite;

        public DownloadedImage(string iD, Sprite sprite)
        {
            ID = iD;
            this.sprite = sprite;
        }
    }
}
