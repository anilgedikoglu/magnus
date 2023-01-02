using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using DG.Tweening;
using DG.Tweening.Core;
using DG.Tweening.Plugins.Options;
using UnityEngine.UI;
using Firebase.Storage;
using System.Threading.Tasks;
using Firebase.Extensions;
using System.Threading;
using System.IO;
using TMPro;

public class InboxElement : MonoBehaviour, IDragHandler, IBeginDragHandler, IEndDragHandler, IPointerClickHandler
{
    private RectTransform rt;
    public GameObject destroyObject;

    private ChatManager chatManager;

    public TMP_Text title;
    public TMP_Text descreption;
    public TMP_Text date;
    public Image icon;
    public Image flareImage;
    public Image processImage;
    public GameObject iconFlare;

    public GameObject notification;

    [HideInInspector] public RenderedText renderedText;

    public int index;

    public float animtionDuration = 0.5f;

    private InboxManager inboxManager;

    private Vector2 firsPos;
    private Vector2 clickPos;
    private float clickOffset;
    private TweenerCore<Vector3, Vector3, VectorOptions> moveTweener;

    private string descreptionData;

    private bool clickable = true;
    private bool ready = true;
    private bool directionChecked  =false;
    private bool showAd;
    private bool simpleFocusPanel = false;

    private bool canDrag;

    private void Awake()
    {
        rt = GetComponent<RectTransform>();
        inboxManager = FindObjectOfType<InboxManager>();
        chatManager = FindObjectOfType<ChatManager>();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        if (ready)
        {
            canDrag = false;
            clickable = false;
            directionChecked = false;

            firsPos = rt.position;
            clickPos = eventData.position;
            clickOffset = eventData.position.x - rt.position.x;

            if (moveTweener != null)
                if (moveTweener.active)
                    moveTweener.Kill();

            StartCoroutine(BeginDragDelay());
        }
    }

    private IEnumerator BeginDragDelay()
    {
        yield return new WaitForEndOfFrame();
        canDrag = true;
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        if (ready)
        {
            clickable = true;

            if (rt.position.x - firsPos.x < -inboxManager.canvasRect.sizeDelta.x * inboxManager.deleteSwipeRatio)
            {
                DeleteElement();

                return;
            }

            if (rt.position.x - firsPos.x < -rt.sizeDelta.y)
            {
                moveTweener = rt.DOMove(new Vector2((+inboxManager.canvasRect.sizeDelta.x / 2f - (rt.sizeDelta.y)) *
                    inboxManager.canvasRect.localScale.y, rt.position.y), animtionDuration);

                return;
            }

            moveTweener = rt.DOMove(new Vector3((+inboxManager.canvasRect.sizeDelta.x / 2f)
                * inboxManager.canvasRect.localScale.x, rt.position.y), animtionDuration);
        }
    }

    public void OnDrag(PointerEventData eventData)
    {
        if (ready && canDrag)
        {
            if (!directionChecked)
            {
                Vector2 delta = eventData.position - clickPos;

                if(Mathf.Abs(delta.y)> Mathf.Abs(delta.x))
                {
                    canDrag = false;
                    return;
                }

                directionChecked = true;
            }

            rt.position = new Vector3(eventData.position.x - clickOffset, rt.position.y);
        }
    }

    public void ResetElement()
    {
        rt.position = new Vector3((+inboxManager.canvasRect.sizeDelta.x / 2f) *
            inboxManager.canvasRect.localScale.x, rt.position.y);
    }

    public async Task SetTextsAsync(RenderedText renderedText)
    {
        title.text = chatManager.chatVariablesManager.OrtakButonlar(inboxManager.bilgiEkraniSettings.inbox.defaultElement.title);

        descreption.text = "Yeni bir bildirim var."; //Simdilik hard coded birakildi!
        icon.sprite = inboxManager.bilgiEkraniSettings.inbox.defaultElement.icon;


        if (renderedText.renderedTexts[index].text.Contains("{{barmenu}}"))
        {
            string[] words = renderedText.renderedTexts[index].text.Split(new string[] { "{{barmenu}}" }, System.StringSplitOptions.None);

            for (int i = 0; i < words.Length; i++)
            {
                if (!string.IsNullOrEmpty(words[i]))
                {
                    try
                    {
                        descreptionData = Newtonsoft.Json.JsonConvert.DeserializeObject<PercentileManager.BarData>(words[i]).bars[0].explanations[0].content;
                    }
                    catch
                    {
                        Debug.LogError("Data json formatina cevrilemedi+\n" + words[i]);
                        descreptionData = "Veri yüklenemedi."; //Simdilik hard coded birakildi!
                    }
                }
            }
        }
        else
        {
            descreptionData = string.Empty;
            bool write = false;
            for (int i = 0; i < renderedText.renderedTexts[index].text.Length; i++)
            {
                if (renderedText.renderedTexts[index].text[i] != '\n')
                    write = true;

                if(write)
                    descreptionData += renderedText.renderedTexts[index].text[i];
            }
        }



        this.renderedText = renderedText;

        if (renderedText != null)
        {
            processImage.gameObject.SetActive(false);
            iconFlare.gameObject.SetActive(true);

            if (string.IsNullOrEmpty(renderedText.renderedTexts[index].uIInformation.title) ||
                string.IsNullOrEmpty(renderedText.renderedTexts[index].uIInformation.onlinePhotoID))
            {
                BilgiEkraniSettings.Inbox.InboxElement inboxElement = 
                    inboxManager.bilgiEkraniSettings.inbox.inboxElements.Find(x => x.mod.Equals(renderedText.renderedTexts[index].mod));

                if (inboxElement != null)
                {
                    title.text = inboxElement.title;
                    icon.sprite = inboxElement.icon;
                    flareImage.sprite = inboxElement.flare;
                    flareImage.color = inboxElement.flare == null ?
                        new Color(1, 1, 1, 0) : Color.white;
                    showAd = inboxElement.showAd;
                    simpleFocusPanel = inboxElement.simpleFocusPanel;
                }

                date.text = renderedText.renderedTexts[index].date;

                float currentDif = renderedText.renderedTexts[index].uIInformation.showTimeStamp -
                    Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now);
                if (currentDif <= 0)
                {
                    descreption.text = descreptionData;

                    ready = inboxElement.deletable;

                    if (renderedText.renderedTexts[index].uIInformation.showTimeStamp > 0)
                    {
                        renderedText.renderedTexts[index].isOpened = false;
                        renderedText.renderedTexts[index].uIInformation.showTimeStamp = 0;
                    }
                }
                else
                {
                    float firstDif = renderedText.renderedTexts[index].uIInformation.showTimeStamp - 
                        renderedText.renderedTexts[index].uIInformation.firstTimeStamp;

                    descreption.text = inboxElement.notReadyText;

                    ready = false;

                    flareImage.color = new Color(1, 1, 1, 0);

                    inboxManager.updateUIAgain = true;

                    processImage.gameObject.SetActive(true);
                    iconFlare.gameObject.SetActive(false);
                    processImage.fillAmount = currentDif / firstDif;
                }
            }
            else
            {
                title.text = renderedText.renderedTexts[index].uIInformation.title;

                await DownloadImageFile(renderedText.renderedTexts[index].uIInformation.onlinePhotoID);

                descreption.text = descreptionData;
                date.text = renderedText.renderedTexts[index].date;
            }
        }

        descreption.text = chatManager.chatVariablesManager.OrtakButonlar(descreption.text);
    }

    public async Task DownloadImageFile(string fileName)
    {
        string localUrl = Application.persistentDataPath + "/SystemMessages/" + fileName;

        if (!Directory.Exists(Application.persistentDataPath + "/SystemMessages"))
            Directory.CreateDirectory(Application.persistentDataPath + "/SystemMessages");

        var downloadedImage = inboxManager.downloadedImageCache.Find(x => x.ID.Equals(fileName));

        if (downloadedImage != null)
        {
            icon.sprite = downloadedImage.sprite;
            return;
        }

        if (!File.Exists(localUrl))
        {

            var storage = FirebaseStorage.DefaultInstance;

            // Create a storage reference from our storage service
            StorageReference storageRef =
                storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

            // Create a reference to the file you want to upload
            StorageReference riversRef = storageRef.Child("SystemMessages/" + fileName);

            // Start downloading a file
            Task task = riversRef.GetFileAsync((Application.platform == 
                RuntimePlatform.IPhonePlayer) ? "file://" + localUrl : localUrl,
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
                    Texture2D tex = new Texture2D(2, 2);
                    byte[] texBytes = new byte[0];

                    await Task.Run(() =>
                    {
                        texBytes = File.ReadAllBytes(localUrl);
                    }).ContinueWithOnMainThread((taskLoadImage) =>
                    {
                        tex.LoadImage(texBytes);
                        icon.sprite = Sprite.Create(tex, new Rect(0, 0,
                            tex.width, tex.height), new Vector2(0.5f, 0.5f));
                    });

                    inboxManager.downloadedImageCache.Add(new InboxManager.DownloadedImage(fileName, icon.sprite));
                    Debug.Log("Download finished.");
                }
                else
                {
                    Debug.Log("basarisiz");
                }
            });
        }
        else
        {
            Texture2D tex = new Texture2D(2, 2);
            byte[] texBytes = new byte[0];
            await Task.Run(() =>
            {
                texBytes = File.ReadAllBytes(localUrl);
            }).ContinueWithOnMainThread((taskLoadImage) =>
            {
                tex.LoadImage(texBytes);
                icon.sprite = Sprite.Create(tex, new Rect(0, 0, tex.width,
                    tex.height), new Vector2(0.5f, 0.5f));

                inboxManager.downloadedImageCache.Add(new InboxManager.DownloadedImage(fileName, icon.sprite));
            });

        }
    }

    public void DeleteElement()
    {
        if (moveTweener != null)
            if (moveTweener.active)
                moveTweener.Kill();

        rt.DOMove(new Vector2(-rt.sizeDelta.x/2f * inboxManager.canvasRect.localScale.y,
            rt.position.y), animtionDuration).onComplete = () =>
        {
            if (renderedText != null)
            {
                if (renderedText.renderedTexts.Count > index)
                    renderedText.renderedTexts.RemoveAt(index);
            }
            ResetElement();
            //inboxManager.elementCount--;
            inboxManager.onDelete();
        };

        inboxManager.isUIUpdated = false;
        StartCoroutine(inboxManager.UpdateUI(.1f));
        inboxManager.bilgiEkraniManager.CheckInboxNotificationState();
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if (clickable && ready)
        {
            Sohbet sohbet = ScriptableObject.CreateInstance(typeof(Sohbet)) as Sohbet;
            sohbet.idIndex = renderedText.renderedTexts[index].ID;
            sohbet.aciklama = new List<string>() { "{{hafiza, son5Metin" + "=" + (index + 1) + "}}" };
            sohbet.gerekliDegiskenler = new();
            sohbet.ayarlananDegiskenler = new();
            sohbet.contentImage = new Sohbet.ContentImage();

            if (!string.IsNullOrEmpty(renderedText.renderedTexts[index].photoId))
                sohbet.contentImage.image = FindObjectOfType<PhotoManager>().
                    GetSprite(renderedText.renderedTexts[index].photoId);

            sohbet.fotografKonum = Sohbet.contentPhotoLocation.balonIcindeBasta;
            sohbet.yeniFocusPaneliKullan = simpleFocusPanel;

            if (renderedText.renderedTexts[index].mod == "dogumharitasi")
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "dogumharitasibugungeldi");
                sohbet.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken("mod", "dogumharitasibugungeldi"));
                sohbet.contentImage.gifId = chatManager.magnusPreferences.wheelChartConentPhotoId;
            }
            else
                sohbet.contentImage.gifId = "";

            var bubble = Instantiate(chatManager.leftBubble).GetComponent<SpeechBubbleLeft>();
            bubble.sohbet = sohbet;
            bubble.chatManager = chatManager;
            bubble.SetTextObjects();
            //Hafizadan cagrilan metin online metin ise icinde tekrar
            //buton olacagi icin o butonarin da renderlanmasi icin
            //tekrar replace islemi cagrilir.
            bubble.text.text = bubble.ReplaceChatVariables(bubble.text.text);
            bubble.textMain.text = bubble.text.text;
            bubble.SetFirstSizes();
            StartCoroutine(ClickDelay(bubble, sohbet));

            notification.SetActive(false);

            inboxManager.panelShowText.showAdOnClose = showAd && !chatManager.PlayerDataManager.IsPlus;
            inboxManager.percentileManager.showAdOnClose = showAd && !chatManager.PlayerDataManager.IsPlus;

            if (!renderedText.renderedTexts[index].isOpened)
            {
                if (chatManager.PlayerDataManager.IsPlus)
                {
                    renderedText.renderedTexts[index].isOpened = true;
                    inboxManager.playerData.AddElementToSessionMods(
                        renderedText.renderedTexts[index].uIInformation.title, true);
                }
                else
                {
                    inboxManager.panelShowText.showAdOnClose = false;
                }
            }

            inboxManager.isUIUpdated = false;
            StartCoroutine(inboxManager.UpdateUI(.1f));
            inboxManager.bilgiEkraniManager.CheckInboxNotificationState();
        }
    }

    IEnumerator ClickDelay(SpeechBubbleLeft speechBubbleLeft, Sohbet sohbet)
    {
        yield return new WaitForEndOfFrame();

        if (speechBubbleLeft.text.text.Contains("{{barmenu}}"))
        {
            string[] words = speechBubbleLeft.text.text.Split(new string[] { "{{barmenu}}" }, System.StringSplitOptions.None);
            Debug.Log(words.Length);

            for (int i = 0; i < words.Length; i++)
            {
                if (!string.IsNullOrEmpty(words[i]))
                {
                    try
                    {
                        FindObjectOfType<PercentileManager>().SetActive(true, words[i], sohbet.contentImage.image, renderedText.renderedTexts[index]);
                    }
                    catch
                    {
                        Debug.LogError("Bar icin json datasi bulunamadi: " + words[i]);
                    }
                }
            }
        }
        else
        {
            string[] photoIds = new string[0];

            if (!string.IsNullOrEmpty(renderedText.renderedTexts[index].photoId))
                photoIds = renderedText.renderedTexts[index].photoId.Split(",");

            List<Sprite> sprites = new();
            foreach (string id in photoIds)
            {
                sprites.Add(FindObjectOfType<PhotoManager>().GetSprite(id));
            }

            if (sprites.Count > 1)
            {
                inboxManager.panelShowText.simplePanelActive = simpleFocusPanel;
                inboxManager.panelShowText.OpenPanel(new List<SpeechBubbleLeft>() { speechBubbleLeft }, sohbet, sprites, renderedText.renderedTexts[index]);
            }
            else
            {
                if (sprites.Count == 1)
                {
                    speechBubbleLeft.contentImageActive = true;
                    speechBubbleLeft.contentImage.sprite = FindObjectOfType<PhotoManager>().GetSprite(photoIds[0]);
                }
                inboxManager.panelShowText.simplePanelActive = simpleFocusPanel;
                inboxManager.panelShowText.OpenPanel(new List<SpeechBubbleLeft>() { speechBubbleLeft }, sohbet, renderedText.renderedTexts[index]);
            }
        }
    }
}
