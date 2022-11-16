using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using DG.Tweening;

public class TarotCard : MonoBehaviour
{
    public RectTransform pivotRectTransform;
    public RectTransform rectTransform;

    public bool isUsed;

    void Awake()
    {
        pivotRectTransform = GetComponent<RectTransform>();

        if (pivotRectTransform.childCount > 0)
            rectTransform = pivotRectTransform.GetChild(0).GetComponent<RectTransform>();
    }

    private void Start()
    {

    }

    public void StartAnimation()
    {
        if (rectTransform.childCount > 0)
        {
            rectTransform.GetChild(0).position = new Vector3(-rectTransform.GetChild(0).GetComponent<RectTransform>().rect.width * 2f, rectTransform.position.y, rectTransform.position.z);
            StartCoroutine(MoveToParent(0.5f));
        }
    }

    public void EndAnimation(int index)
    {
        if (rectTransform.childCount > 0)
        {
            rectTransform.GetChild(0).DOMove(new Vector3(rectTransform.position.x, -rectTransform.GetChild(0).GetComponent<RectTransform>().rect.height * 2f, rectTransform.position.z), 0.2f + index * 0.08f);
        }
    }

    IEnumerator MoveToParent(float delay)
    {
        yield return new WaitForSeconds(delay);
        if (rectTransform.childCount > 0)
            rectTransform.GetChild(0).DOMove(rectTransform.position, 0.5f);
    }

    void Update()
    {

    }

    public void SelectThisCard(RectTransform cardRect)
    {
        GameObject clone = Instantiate(cardRect.gameObject, cardRect.parent);
        cardRect.gameObject.SetActive(false);
        cardRect.parent.GetComponent<RectTransform>().parent.GetComponent<TarotCard>().isUsed = true;
        clone.GetComponent<RectTransform>().SetParent(FindObjectOfType<TarotPanelManager>().cardMoveAreas[0].rectTransform);
        clone.GetComponent<RectTransform>().DOAnchorPos(new Vector2(0, 0), 0.5f);
    }
}
