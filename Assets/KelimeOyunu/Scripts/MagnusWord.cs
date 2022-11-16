using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
using UnityEngine.EventSystems;
using TMPro;

public class MagnusWord : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
    internal MagnusWordManager wordManager;

    internal RectTransform rect;

    private TMP_Text text;
    private RectTransform canvasRect;
    private char _letter;
    internal char Letter
    {
        get { return _letter; }
        set 
        {
            _letter = value;
            SetText();
        }
    }

    internal MagnusWordPlace _wordPlace;
    
    internal bool onTop;
    internal bool isSecondAnimLetter;

    internal MagnusWordPlace WordPlace
    {
        get
        {
            return _wordPlace;
        }

        set
        {
            _wordPlace = value;
            UpdatePosition();
        }
    }

    private void Awake()
    {
        rect = GetComponent<RectTransform>();
        text = GetComponentInChildren<TMP_Text>();

        canvasRect = GameObject.Find("Canvas").GetComponent<RectTransform>();
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
        
    }

    public void OnDrag(PointerEventData eventData)
    {
        rect.position = new Vector2(eventData.position.x, eventData.position.y + (rect.sizeDelta.y) * canvasRect.localScale.y);
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        var closePlace = GetClosestPlace();

        onTop = rect.anchoredPosition.y >= 0;
        isSecondAnimLetter = false;

        MagnusWord word = closePlace.Word;
        word.onTop = !onTop;
        word.isSecondAnimLetter = true;
        MagnusWordPlace wordPlace = WordPlace;
        closePlace.Word = this;
        wordPlace.Word = word;
    }

    private MagnusWordPlace GetClosestPlace()
    {
        MagnusWordPlace currentPlace = wordManager.places[0];
        for (int i = 1; i < wordManager.places.Count; i++)
        {
            if (Vector3.Distance(currentPlace.rect.position, rect.position) >
                Vector3.Distance(wordManager.places[i].rect.position, rect.position))
            {
                currentPlace = wordManager.places[i];
            }
        }
        return currentPlace;
    }

    private void UpdatePosition()
    {
        if (isSecondAnimLetter)
        {
            rect.DOAnchorPosX(0, 0.5f).onComplete = () => 
            {
                wordManager.CheckCorrectAndDestroy();
            };
            rect.DOAnchorPosY(onTop ? 100 : -100, .25f).onComplete = () =>
            {
                rect.DOAnchorPosY(0, .25f);
            };
        }
        else
        {
            rect.DOAnchorPos(Vector2.zero, .25f);
        }
    }

    private void SetText()
    {
        text.text = Letter.ToString();
    }
}
