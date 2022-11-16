using DG.Tweening;
using DG.Tweening.Core;
using DG.Tweening.Plugins.Options;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SquareWordLetter : MonoBehaviour
{
    internal Image image;
    internal RectTransform rect;
    internal TMP_Text text;

    internal bool isCorrect;

    [SerializeField] internal Image indicator;

    internal TweenerCore<Color, Color, ColorOptions> indicatorTween;

    private void Awake()
    {
        rect = GetComponent<RectTransform>();
        image = GetComponent<Image>();
        text = GetComponentInChildren<TMP_Text>();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }


    // Update is called once per frame
    void Update()
    {
        
    }

    internal void SetCorrect()
    {
        isCorrect = true;

        if (indicatorTween != null)
            if (indicatorTween.IsPlaying())
            indicatorTween.Kill();

        indicator.color = Color.green;

        indicatorTween = indicator.DOFade(0f, 0f);
        indicatorTween = indicator.DOFade(1f, .2f);
    }

    internal void SetWrong()
    {
        if (indicatorTween != null)
            if (indicatorTween.IsPlaying())
                indicatorTween.Kill();

        indicator.color = isCorrect ? Color.green : Color.red;

        indicatorTween = indicator.DOFade(0f, 0f);
        indicatorTween = indicator.DOFade(1f, .2f);
    }

    internal void SetSelected()
    {
        if (indicatorTween != null)
            if (indicatorTween.IsPlaying())
                indicatorTween.Kill();

        indicator.color = Color.cyan;

        indicatorTween = indicator.DOFade(0f, 0f);
        indicatorTween = indicator.DOFade(1f, .2f);
    }
}
