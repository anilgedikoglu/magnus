using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class NumberedBrick : Brick
{
    public Text label;
    public Image labelImage;

    [SerializeField]
    float moveDuration;

    int number;
    int colorIndex;
    bool isDestroyed;

    public bool IsDestroyed => isDestroyed;
    public int Number
    {
        get => number;
        set
        {
            number = value;
            if(label)
                label.text = number.ToString();
        }
    }

    public int ColorIndex
    {
        get => colorIndex;
        set
        {
            colorIndex = value;
            UpdateColors(ThemeController.Instance.CurrentTheme);
        }
    }
    
    public void DoLocalMove(Vector2 position, Action onComplete)
    {
        StartCoroutine(LocalMove(position, onComplete));
    }

    public void DoLocalPath(List<Vector2> path, Action onComplete)
    {
        if (path.Count == 0)
        {
            onComplete?.Invoke();
            return;
        }

        Vector2 position = path[0];
        path.RemoveAt(0);
        DoLocalMove(position, () => DoLocalPath(path, onComplete));
    }

    public void DoLandingAnimation(Action onComplete)
    {
        GetComponent<Animator>().SetTrigger("Land");
        this.DelayedCall(0.25f, onComplete);
    }

    public void DoMergingAnimation(Action onComplete)
    {
        GetComponent<Animator>().SetTrigger("Merge");
        this.DelayedCall(0.25f, onComplete);
    }

    public void DoBlinkingAnimation()
    {
        GetComponent<Animator>().SetTrigger("Blink");
    }

    public void DoStopBlinking()
    {
        GetComponent<Animator>().SetTrigger("Default");
    }

    IEnumerator LocalMove(Vector2 position, Action onComplete)
    {
        Vector2 startPosition = RectTransform.anchoredPosition;
        float t = Time.deltaTime;
        while (t < moveDuration)
        {
            RectTransform.anchoredPosition = Vector2.Lerp(startPosition, position, t / moveDuration);
            yield return null;
            t += Time.deltaTime;
        }

        RectTransform.anchoredPosition = position;

        onComplete?.Invoke();
    }

    
    protected virtual void UpdateColors(ThemePreset theme)
    {
        if (label)
        {
            label.gameObject.SetActive(theme.label.labelType == LabelType.Text);
            label.color = theme.labelColors[Mathf.Clamp(colorIndex, 0, theme.labelColors.Length - 1)];
        }

        if (labelImage)
        {
            labelImage.gameObject.SetActive(theme.label.labelType == LabelType.Sprite);

            if (theme.label.labelType == LabelType.Sprite && theme.label.collection != null)
            {
                SpritesCollection collection = theme.label.collection;

                labelImage.sprite = collection.sprites[Mathf.Clamp(colorIndex, 0, collection.sprites.Length - 1)];
                labelImage.color = theme.labelColors[Mathf.Clamp(colorIndex, 0, theme.labelColors.Length - 1)];
            }
        }
        
        sprite.color = theme.spriteColors[Mathf.Clamp(colorIndex, 0, theme.spriteColors.Length - 1)];
    }

    void Start()
    {
        UpdateColors(ThemeController.Instance.CurrentTheme);
        ThemeController.Instance.ThemeChanged += UpdateColors;
    }

    void OnDestroy()
    {
        ThemeController.Instance.ThemeChanged -= UpdateColors;
        isDestroyed = true;
    }
}