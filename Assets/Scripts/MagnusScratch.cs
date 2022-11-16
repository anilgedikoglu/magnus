using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ScratchCardAsset;
using TMPro;

public class MagnusScratch : MonoBehaviour
{
    public ScratchCardManager scratchCardManager;

    public Canvas canvas;
    public Vector2 defaultSize;

    public GameObject scratchPanel;

    public Camera scratchCamera;

    public RawImage rawImage;

    public RenderTexture renderTexture;

    public TMP_Text text;

    public Animator animator;

    public RectTransform cardBackgroundRt;

    public Image cardBackgroundImage;

    public List<Image> flareImagesRed, flareImagesBlue;

    public GameObject closePanelButtonBack, closePanelButtonFront;

    public ChatManager chatManager;

    public int succesPercentage;

    bool isCardDone;

    float CardClickableDelayDefault { get; } = 3f;
    float _cardClickableDelay = 3f;
    float CardClickableDelay
    {
        get
        {
            return _cardClickableDelay;
        }

        set
        {
            _cardClickableDelay = value;

            if (_cardClickableDelay <= 0)
            {
                closePanelButtonBack.SetActive(false);
                closePanelButtonFront.SetActive(true);
            }

        }
    }

    private void Awake()
    {
        //cardBackgroundImage.sprite = chatManager.magnusPreferences.scratchCardBack[Random.Range(0, chatManager.magnusPreferences.scratchCardBack.Length)];
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

        ClosePanel();
    }

    // Update is called once per frame
    void Update()
    {
        float maxProgress = 1f - (succesPercentage / 100f);
        float progress = scratchCardManager.Progress.GetProgress() / maxProgress;

        if (!isCardDone)
        {
            if (scratchCardManager.Progress.GetProgress() > succesPercentage / 100f)
            {
                isCardDone = true;
                scratchCardManager.Card.FillInstantly();
                scratchCardManager.Progress.UpdateProgress();
                closePanelButtonBack.SetActive(true);
            }

            foreach (Image flare in flareImagesRed)
            {
                flare.color = new Color(flare.color.r, flare.color.g, flare.color.b, progress);
            }
        }
        else
        {
            if (CardClickableDelay > 0)
            {
                CardClickableDelay -= Time.deltaTime;
            }


            foreach (Image flare in flareImagesBlue)
            {
                flare.color = new Color(flare.color.r, flare.color.g, flare.color.b, 1f);
            }

            foreach (Image flare in flareImagesRed)
            {
                flare.color = new Color(flare.color.r, flare.color.g, flare.color.b, 0f);
            }
        }
    }

    public void OpenPanel(List<SpeechBubbleLeft> allBubbles)
    {
        gameObject.transform.parent.gameObject.SetActive(true);
        gameObject.SetActive(true);

        string text = "";

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
            }
        }

        foreach (Image flare in flareImagesBlue)
        {
            flare.color = new Color(flare.color.r, flare.color.g, flare.color.b, 0f);
        }

        foreach (Image flare in flareImagesRed)
        {
            flare.color = new Color(flare.color.r, flare.color.g, flare.color.b, 0f);
        }

        this.text.text = text;

        animator.SetBool("exit", false);
        scratchPanel.SetActive(true);

        CardClickableDelay = CardClickableDelayDefault;
        closePanelButtonBack.SetActive(false);
        closePanelButtonFront.SetActive(false);

        scratchCardManager.Card.ClearInstantly();
        scratchCardManager.Progress.UpdateProgress();

        isCardDone = false;
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
        scratchCardManager.ResetScratchCard();
        chatManager.otomatikOdak = false;
        gameObject.transform.parent.gameObject.SetActive(false);
        gameObject.SetActive(false);
    }

}
