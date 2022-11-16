using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
using TMPro;

public class TopBarSlideText : MonoBehaviour
{
    [SerializeField] private TopBarSlideData data;

    [SerializeField] private RectTransform canvasRect;

    [SerializeField] private RectTransform firstRect;

    [SerializeField] private float duration;
    private float defaultWidth = 250f;

    private ChatVariables chatVariables;

    private List<string> texts;

    private void OnEnable()
    {
        playAnimation = PlayAnimation();

        if (chatVariables == null)
            chatVariables = FindObjectOfType<ChatVariables>();

        StartCoroutine(playAnimation);
    }

    private void OnDisable()
    {
        if (playAnimation != null)
            StopCoroutine(playAnimation);
    }

    private IEnumerator playAnimation;
    private IEnumerator PlayAnimation()
    {
        SetText();
        Canvas.ForceUpdateCanvases();
        firstRect.anchoredPosition = new Vector2(0, firstRect.anchoredPosition.y);

        yield return new WaitForEndOfFrame();

        float currentDuration = duration * Mathf.Clamp((firstRect.sizeDelta.x / defaultWidth), 1, Mathf.Infinity);

        //DOTween.KillAll

        firstRect.DOAnchorPos(
            new Vector2(firstRect.anchoredPosition.x - firstRect.sizeDelta.x - 50 * (currentDuration / duration) - canvasRect.sizeDelta.x,
            firstRect.anchoredPosition.y), currentDuration);

        yield return new WaitForSeconds(currentDuration);

        playAnimation = PlayAnimation();
        StartCoroutine(playAnimation);
    }

    private void CheckText()
    {
        if (texts == null)
        {
            texts = new List<string>(data.texts);
            return;
        }

        if(texts.Count<=0)
        {
            texts = new List<string>(data.texts);
            return;
        }
    }

    private void SetText()
    {
        CheckText();
        TMP_Text text = firstRect.GetComponent<TMP_Text>();

        int index = Random.Range(0, texts.Count);
        text.text = chatVariables.OrtakButonlar(texts[index]);
        texts.RemoveAt(index);
    }
}
