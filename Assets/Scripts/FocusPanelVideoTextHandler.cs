using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using DG.Tweening;

public class FocusPanelVideoTextHandler : MonoBehaviour
{
    [SerializeField] private TMP_Text tMPText;
    [SerializeField] private RectTransform rect;

    [SerializeField] private ZoomPanelData panelData;

    private CurrentPlayerData playerData;

    private void Awake()
    {
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    private void OnEnable()
    {
        if (startAnimation != null)
            StopCoroutine(startAnimation);

        startAnimation = StartAnimation();
        StartCoroutine(startAnimation);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private IEnumerator startAnimation;
    private IEnumerator StartAnimation()
    {
        List<ZoomPanelData.VideoText> videoTexts = new List<ZoomPanelData.VideoText>(panelData.videoTexts);
        videoTexts.Shuffle();

        ZoomPanelData.VideoText texts = videoTexts.Find(x=>x.mod.Equals(playerData.GetChatVariableValue("mod")));

        tMPText.color = new Color(tMPText.color.r, tMPText.color.g, tMPText.color.b, 0);

        if (texts == null)
        {
            yield break;
        }
        else
        {
            //First delay...
            yield return new WaitForSeconds(1f);
        }

        foreach (ZoomPanelData.VideoText.Text text in texts.texts)
        {
            tMPText.text = text.text;

            rect.anchoredPosition = new Vector2(-100, rect.anchoredPosition.y);
            tMPText.color = new Color(tMPText.color.r, tMPText.color.g, tMPText.color.b, 0);
            rect.DOAnchorPos(new Vector2(0, rect.anchoredPosition.y), .25f);
            tMPText.DOFade(1, .25f);
            yield return new WaitForSeconds(.25f);
            yield return new WaitForSeconds(text.duration);
            tMPText.DOFade(0, .25f);
            rect.DOAnchorPos(new Vector2(100, rect.anchoredPosition.y), .25f);
            yield return new WaitForSeconds(.25f);
        }
        startAnimation = null;
    }
}
