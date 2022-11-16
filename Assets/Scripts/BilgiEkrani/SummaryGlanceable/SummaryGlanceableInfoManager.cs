using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;

public class SummaryGlanceableInfoManager : MonoBehaviour
{
    private RectTransform rect;
    public List<RectTransform> pages;
    public float animationDuration = .3f;

    private int currentIndex;

    private void Awake()
    {
        rect = GetComponent<RectTransform>();
    }

    // Start is called before the first frame update
    void Start()
    {
        SetActivePage(0, false);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetActivePage(int index)
    {
        if (currentIndex > index)
        {
            pages[currentIndex].DOAnchorPos(new Vector2(pages[currentIndex].sizeDelta.x + Screen.width,
            pages[currentIndex].anchoredPosition.y), animationDuration);

            pages[index].anchoredPosition =
            new Vector2(-pages[currentIndex].sizeDelta.x - Screen.width,
            pages[index].anchoredPosition.y);

            pages[index].DOAnchorPos(new Vector2(0,
            pages[index].anchoredPosition.y), animationDuration);
        }
        else if (currentIndex < index)
        {
            pages[currentIndex].DOAnchorPos(new Vector2(-pages[currentIndex].sizeDelta.x - Screen.width,
            pages[currentIndex].anchoredPosition.y), animationDuration);

            pages[index].anchoredPosition =
            new Vector2(pages[currentIndex].sizeDelta.x + Screen.width,
            pages[index].anchoredPosition.y);

            pages[index].DOAnchorPos(new Vector2(0,
            pages[index].anchoredPosition.y), animationDuration);
        }

        currentIndex = index;
    }

    public void SetActivePage(int index, bool animate)
    {
        if (animate)
        {
            SetActivePage(index);
        }
        else
        {
            DeactivateAllPages();
            pages[index].anchoredPosition = new Vector2(0,
            pages[index].anchoredPosition.y);

            currentIndex = index;
        }
    }

    public void DeactivateAllPages()
    {
        foreach(RectTransform page in pages)
        {
            page.position = new Vector3(page.position.x, rect.position.y, page.position.z);
            page.anchoredPosition =
            new Vector2(page.sizeDelta.x + Screen.width,
            page.anchoredPosition.y);
        }
    }
}
