using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ScratchCardAsset;
using TMPro;
using Firebase.Storage;
using UnityEngine.Networking;
using Firebase.Extensions;

public class ScratchQuiz : MonoBehaviour
{
    public ScratchCardManager scratchCardManager;

    public Canvas canvas;
    public Vector2 defaultSize;

    public GameObject scratchPanel;

    public Camera scratchCamera;

    public RawImage rawImage;

    public RenderTexture renderTexture;

    public Animator animator;

    public RectTransform cardBackgroundRt;

    public Image cardBackgroundImage;
    public Image contentImage;
    public string contentPhotoId;
    public string imageId;

    public RectTransform progressBar, progressBarSuccesPart, progressBarUnsuccesPart;

    [HideInInspector] public ChatManager chatManager;
    [HideInInspector] public Sohbet sohbet;
    [HideInInspector] public string mod;
    public int kazimaSonuBekleme;

    public int succesPercentage;

    public Transform cardWorldPositon;

   [HideInInspector] public int cardState;

    int gifSizeSet = 0;

    private void Awake()
    {
        //cardBackgroundRt.anchoredPosition = new Vector3(cardBackgroundRt.anchoredPosition.x, scratchCamera.WorldToScreenPoint(cardWorldPositon.position).y);

        cardWorldPositon.position = new Vector3(cardWorldPositon.position.x, scratchCamera.ScreenToWorldPoint(cardBackgroundRt.anchoredPosition).y, cardWorldPositon.position.z);
    }

    void Start()
    {
        RectTransform canvasRect = canvas.gameObject.GetComponent<RectTransform>();

        renderTexture = new RenderTexture((int)canvasRect.rect.width, (int)canvasRect.rect.height, 16, RenderTextureFormat.ARGB32);
        renderTexture.Create();
        scratchCamera.targetTexture = renderTexture;
        rawImage.texture = renderTexture;

        float xScale = (canvasRect.rect.width / (defaultSize.x / 2f));
        float yScale = (canvasRect.rect.height / (defaultSize.y / 2f));

        if (xScale < yScale)
        {
            transform.localScale = new Vector3(xScale, xScale, (transform.parent.localScale.z));
        }
        else
        {
            transform.localScale = new Vector3(yScale, yScale, (transform.parent.localScale.z));
        }
        cardBackgroundRt.localScale = transform.localScale;

        cardWorldPositon.position = new Vector3(cardWorldPositon.position.x, scratchCamera.ScreenToWorldPoint(cardBackgroundRt.anchoredPosition).y, cardWorldPositon.position.z);
    }

    // Update is called once per frame
    void Update()
    {
        if (cardState==0)
        {
            if (scratchCardManager.Progress.GetProgress() > succesPercentage / 100f)
            {
                scratchCardManager.Card.FillInstantly();
                StartCoroutine(CardDoneDelay());

                cardState = 1;

                foreach(GameObject gameObject in chatManager.answerBubbles)
                {
                    AnswerBubble answerBubble = gameObject.GetComponent<AnswerBubble>();
                    answerBubble.button.onClick.RemoveAllListeners();
                }
            }

            progressBar.localScale = new Vector3(scratchCardManager.Progress.GetProgress(), progressBar.localScale.y, progressBar.localScale.z);
        }

        SetGifPhotoSize();
    }

    public IEnumerator CardDoneDelay()
    {
        yield return new WaitForSeconds(kazimaSonuBekleme);
        if (sohbet != null)
        {
            chatManager.ClickAnswerBubble(sohbet, 0, 0, false);
        }
        else
        {
            chatManager.PlayerDataManager.AddElementToChatVariableList("mod", mod);
            chatManager.ClickAnswerBubble(null, 0, 0, false);
        }
    }

    public IEnumerator CancelCard()
    {
        cardState = 2;
        scratchCardManager.Card.FillInstantly();
        yield return new WaitForSeconds(kazimaSonuBekleme);
        ClosePanel();
    }

    public void OpenPanel()
    {
        SetContentImageSprite();
        SetContentImageScale();

        progressBarSuccesPart.localScale = new Vector3(succesPercentage / 100f, progressBarSuccesPart.localScale.y, progressBarSuccesPart.localScale.z);
        progressBarUnsuccesPart.localScale = new Vector3((100f - succesPercentage) / 100f, progressBarUnsuccesPart.localScale.y, progressBarUnsuccesPart.localScale.z);

        gameObject.transform.parent.gameObject.SetActive(true);
        gameObject.SetActive(true);

        scratchCardManager.ResetScratchCard();
        //scratchCardManager.Progress.ResetProgress();
        //scratchCardManager.Progress.UpdateProgress();
        scratchCardManager.Card.ClearInstantly();

        animator.SetBool("exit", false);
        scratchPanel.SetActive(true);

        cardState = 0;
    }

    void SetContentImageSprite()
    {
        if (contentPhotoId == chatManager.magnusPreferences.wheelChartConentPhotoId)
        {
            contentImage.sprite = chatManager.wheelChartSprite;
        }
        else if (contentPhotoId == chatManager.magnusPreferences.kullaniciPhotoId)
        {
            contentImage.sprite = FindObjectOfType<WelcomeScreen>().profilePhotoImage.sprite;
        }
        else
        {
            if (!string.IsNullOrEmpty(contentPhotoId))
            {
                if (contentImage.sprite == null)
                {
                    contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent2;
                }
                else
                {
                    contentImage.sprite = contentImage.sprite;
                }
            }
            else
            {
                if (!string.IsNullOrEmpty(imageId))
                {
                    if (contentImage.sprite == null)
                    {
                        contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent2;
                        GetOnlineSprite(imageId);
                    }
                    else
                    {
                        contentImage.sprite = contentImage.sprite;
                    }
                }
            }
        }
        contentImage.gameObject.SetActive(true);

        RectTransform contentImageRt = contentImage.GetComponent<RectTransform>();
        contentImageRt.localScale = new Vector3(1, 1, 1);

        if (!string.IsNullOrEmpty(contentPhotoId) && contentPhotoId != chatManager.magnusPreferences.wheelChartConentPhotoId && contentPhotoId != chatManager.magnusPreferences.kullaniciPhotoId)
        {
            contentImage.GetComponent<ProGifPlayerImage>().loadPath = $"https://media.giphy.com/media/{contentPhotoId}/giphy.gif"; 
            contentImage.GetComponent<ProGifPlayerImage>().enabled = true;
            gifSizeSet = 1;
        }
        else
        {
            contentImage.GetComponent<ProGifPlayerImage>().enabled = false;
            gifSizeSet = 2;
        }
    }

    void SetContentImageScale()
    {
        RectTransform contentImageRt = contentImage.GetComponent<RectTransform>();
        float scale = (((float)contentImageRt.rect.width / (float)contentImageRt.rect.height) * (float)contentImage.sprite.texture.width / (float)contentImage.sprite.texture.height) * (cardBackgroundRt.sizeDelta.y / cardBackgroundRt.sizeDelta.x);
        contentImageRt.localScale = new Vector3(scale, scale, contentImageRt.localScale.z);
    }

    void SetGifPhotoSize()
    {
        if (gifSizeSet == 1)
        {
            if (!string.IsNullOrEmpty(contentPhotoId))
            {
                if (contentImage.GetComponent<ProGifPlayerImage>().isActiveAndEnabled)
                {
                    if (contentImage.GetComponent<ProGifPlayerImage>().width == contentImage.sprite.rect.width)
                    {
                        RectTransform contentImageRt = contentImage.GetComponent<RectTransform>();
                        contentImageRt.localScale = new Vector3(((float)contentImageRt.rect.width/ (float)contentImageRt.rect.height) *(float)contentImage.GetComponent<ProGifPlayerImage>().width / (float)contentImage.GetComponent<ProGifPlayerImage>().height, contentImageRt.localScale.y, contentImageRt.localScale.z);
                        Debug.Log(contentImageRt.sizeDelta.x);
                        Debug.Log(contentImageRt.sizeDelta.y);
                        Debug.Log(contentImage.GetComponent<ProGifPlayerImage>().width);
                        Debug.Log((float)contentImage.GetComponent<ProGifPlayerImage>().height);
                        Debug.Log(contentImage.sprite.rect.width);
                        gifSizeSet = 2;
                    }
                }
            }
        }
    }

    public void ClosePanel()
    {
        animator.SetBool("exit", true);
        StartCoroutine(ClosePanelDelay());
    }

    IEnumerator ClosePanelDelay()
    {
        yield return new WaitForSeconds(0.5f);
        scratchPanel.SetActive(false);
        chatManager.otomatikOdak = false;
        gameObject.transform.parent.gameObject.SetActive(false);
        gameObject.SetActive(false);
        scratchCardManager.ResetScratchCard();
        scratchCardManager.Progress.ResetProgress();
        scratchCardManager.Progress.UpdateProgress();
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
            Debug.Log(downloadedSprite.rect);
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
            contentImage.sprite = Sprite.Create(texture, new Rect(0.0f, 0.0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100.0f);
            FindObjectOfType<PhotoManager>().AddTextureToDownloadedTexture(fileName, contentImage.sprite);
        }
    }

}
