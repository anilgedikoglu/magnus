using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using DG.Tweening;

public class SquareWordManager : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
    private RectTransform rect;
    private RectTransform parentLetterRect;

    private CurrentPlayerData playerData;

    private SquareWordLetter[] letters;

    private SquareWordDatabase.Word _currentWord;
    private SquareWordDatabase.Word CurrentWord
    {
        get { return _currentWord; }
        set 
        {
            _currentWord = value;
            SetWord();
        }
    }

    private int _currentLetterIndex;
    private int CurrentLetterIndex
    {
        get { return _currentLetterIndex; }
        set 
        {
            _currentLetterIndex = value;

            if(_currentLetterIndex != -1)
            {
                SelectLetter(_currentLetterIndex);
            }
        }
    }

    private int firstLetterIndex;

    private enum DragType { notAssigned = 0, horizontal =1, vertical = 2 }
    private DragType dragType;

    [SerializeField] private SquareWordDatabase wordDatabase;

    private List<int> currentIndexs;

    [SerializeField] private List<int> allCorrectAnswerIndexs;

    private Vector2 firstPos;

    private int _remainingWordCount;
    private int RemainingWordCount
    {
        get { return _remainingWordCount; }
        set 
        {
            _remainingWordCount = value;
            remainingWordText.text = "Kalan kelime: " + value;
        }
    }
    [SerializeField] private TMPro.TMP_Text remainingWordText;

    private void Awake()
    {
        rect = GetComponent<RectTransform>();
        parentLetterRect = rect.GetChild(0).GetComponent<RectTransform>();
        playerData = FindObjectOfType<CurrentPlayerData>();

        firstPos = rect.anchoredPosition;
    }

    // Start is called before the first frame update
    IEnumerator Start()
    {
        yield return new WaitForSeconds(FindObjectOfType<ChatManager>().AiMessageDelay);
        yield return new WaitForEndOfFrame();
        CurrentWord = wordDatabase.words[playerData.GetChatVariableValueInt("kare kelime paket no")];
    }

    // Update is called once per frame
    void Update()
    {
        if (!IsGameMod(playerData.GetChatVariableValue("mod")))
        {
            Destroy(gameObject);
        }
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        dragType = DragType.notAssigned;
        firstLetterIndex = -1;
        CurrentLetterIndex = -1;
        currentIndexs = new List<int>();

        foreach (var letter in letters)
        {
            if(letter.indicator.color == Color.red)
            {
                letter.indicator.DOFade(0f, 0f);
            }
        }
    }

    public void OnDrag(PointerEventData eventData)
    {
        for(int i = 0; i<letters.Length; i++)
        {
            var letter = letters[i];
            if (RectTransformUtility.RectangleContainsScreenPoint(letter.rect, eventData.position))
            {
                if (CurrentLetterIndex != i)
                {
                    if (firstLetterIndex != -1)
                    {
                        if(dragType == DragType.horizontal)
                        {
                            if (firstLetterIndex / CurrentWord.Size != i / CurrentWord.Size)
                            {
                                break;
                            }
                        }
                        else if (dragType == DragType.vertical)
                        {
                            if ((firstLetterIndex % CurrentWord.Size) != (i % CurrentWord.Size))
                            {
                                break;
                            }
                        }
                    }

                    if (CurrentLetterIndex != -1 && firstLetterIndex == -1)
                    {
                        if (CurrentLetterIndex / CurrentWord.Size == i / CurrentWord.Size)
                        {
                            firstLetterIndex = CurrentLetterIndex;
                            dragType = DragType.horizontal;
                            CurrentLetterIndex = i;
                        }
                        else if ((CurrentLetterIndex % CurrentWord.Size) == (i % CurrentWord.Size))
                        {
                            firstLetterIndex = CurrentLetterIndex;
                            dragType = DragType.vertical;
                            CurrentLetterIndex = i;
                        }
                    }
                    else
                    {
                        CurrentLetterIndex = i;
                    }
                }
                break;
            }
        }
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        int isCorrect = -1;

        foreach (SquareWordDatabase.CorrectIndex correctIndex in CurrentWord.correctIndexs)
        {
            if (correctIndex.indexs.Count == currentIndexs.Count)
            {
                for (int i = 0; i < currentIndexs.Count; i++)
                {
                    for (int u = 0; u < correctIndex.indexs.Count; u++)
                    {
                        if (correctIndex.indexs[u] == currentIndexs[i])
                        {
                            if (i == currentIndexs.Count - 1 && u == correctIndex.indexs.Count - 1)
                            {
                                isCorrect = 0;
                                foreach(var index in currentIndexs) {
                                    if (!letters[index].isCorrect)
                                    {
                                        isCorrect = 1;
                                        break;
                                    }
                                }

                                foreach (int index in currentIndexs)
                                {
                                    if (!letters[index].isCorrect)
                                        allCorrectAnswerIndexs.Add(index);
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }

        bool isLevelCompleted = allCorrectAnswerIndexs.Count > 0;


        foreach (SquareWordDatabase.CorrectIndex correctIndex in CurrentWord.correctIndexs)
        {
            for (int u = 0; u < correctIndex.indexs.Count; u++)
            {
                for (int i = 0; i < allCorrectAnswerIndexs.Count; i++)
                {
                    if (correctIndex.indexs[u] != allCorrectAnswerIndexs[i])
                    {
                        if (i == allCorrectAnswerIndexs.Count - 1)
                        {
                            Debug.Log(correctIndex.indexs[u]);
                            isLevelCompleted = false;
                            u = correctIndex.indexs.Count;
                            break;
                        }

                    }
                    else
                    {
                        break;
                    }
                }
            }
        }


        PlayEndPredectionAnim(isCorrect);

        if (isLevelCompleted)
        {
            StartCoroutine(LevelCompleted());
        }
    }

    private IEnumerator LevelCompleted() 
    {
        yield return new WaitForSeconds(.3f);
        FindObjectOfType<ChatManager>().ClickVirtualButton("kare kelime dogru");
        Destroy(gameObject);
    }

    private void SetWord()
    {
        RemainingWordCount = CurrentWord.correctIndexs.Count;
        allCorrectAnswerIndexs = new List<int>();

        int firstChildCount = parentLetterRect.childCount;
        if (firstChildCount < CurrentWord.Size * CurrentWord.Size)
        {
            var gameObject = parentLetterRect.GetChild(0).gameObject;


            for (int i = 0; i < (CurrentWord.Size * CurrentWord.Size) - firstChildCount; i++)
            {
                Instantiate(gameObject, parentLetterRect);
            }
        }
        else if (firstChildCount > CurrentWord.Size * CurrentWord.Size)
        {
            for (int i = 0; i < firstChildCount - (CurrentWord.Size * CurrentWord.Size); i++)
            {
                DestroyImmediate(parentLetterRect.GetChild(0).gameObject);
            }
        }

        letters = GetComponentsInChildren<SquareWordLetter>();

        float cellSize = (rect.sizeDelta.x - (CurrentWord.Size + 1) * 5) / CurrentWord.Size;

        for (int i = 0; i<letters.Length; i++)
        {
            var letter = letters[i];
            letter.isCorrect = false;

            if (letter.indicatorTween != null)
                if (letter.indicatorTween.IsPlaying())
                    letter.indicatorTween.Kill();
            letter.indicator.DOFade(0, 0);

            letter.rect.localScale = Vector3.one;

            letter.rect.sizeDelta = new Vector2(cellSize, cellSize);
            letter.rect.anchoredPosition = new Vector2(5 + (cellSize + 5) * (i % CurrentWord.Size), -5 -(cellSize + 5) * (i / CurrentWord.Size));

            letter.text.text = CurrentWord.letters[i].text.ToString().ToUpper();
        }
    }

    private void SelectLetter(int index)
    {
        currentIndexs.Add(index);

        var letter = letters[index];

        letter.SetSelected();

        letter.rect.DOScale(1.2f, .2f).onComplete = () =>
        {
            letter.rect.DOScale(1f, .2f);
        };
    }

    private void PlayEndPredectionAnim(int isCorrect)
    {
        if (isCorrect == 1)
        {
            foreach(int index in currentIndexs)
            {
                var letter = letters[index];

                letter.SetCorrect();
            }

            rect.DOScale(1.25f, 0.25f).onComplete = () =>
            {
                rect.DOScale(1f, 0.1f);
            };

            RemainingWordCount--;
        }
        else if (isCorrect == 0)
        {
            rect.DOAnchorPosY(firstPos.y + 50, 0.3f).onComplete = () =>
            {
                rect.DOAnchorPos(firstPos, 0.1f);
            };

            foreach (int index in currentIndexs)
            {
                var letter = letters[index];

                letter.SetCorrect();
            }
        }
        else if (isCorrect == -1)
        {
            foreach (int index in currentIndexs)
            {
                var letter = letters[index];

                letter.SetWrong();
            }

            rect.DOShakeAnchorPos(0.35f, 30, 16, 90, true, true).onComplete = () =>
            {
                rect.DOAnchorPos(firstPos, 0.1f);
            };
        }
    }

    public bool IsGameMod(string mod)
    {
        return mod == wordDatabase.kareKelimeOyunuModu;
    }
}
