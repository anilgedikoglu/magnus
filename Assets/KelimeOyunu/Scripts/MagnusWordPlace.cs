using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MagnusWordPlace : MonoBehaviour
{
    private MagnusWordManager wordManager;

    internal RectTransform rect;

    internal int Index
    {
        get
        {
            return rect.GetSiblingIndex();
        }
    }

    private MagnusWord _word;
    internal MagnusWord Word
    {
        get
        {
            return _word;
        }

        set
        {
            if (value != null)
            {
                value.rect.SetParent(rect);
                value.WordPlace = this;
            }
            else
                if (_word != null)
                _word.WordPlace = null;

                _word = value;
        }
    }

    private void Awake()
    {
        wordManager = FindObjectOfType<MagnusWordManager>();
        rect = GetComponent<RectTransform>();
        CreateWord();
    }

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        
    }

    internal void CreateWord()
    {
        var word = Instantiate(wordManager.wordPrefab, rect).GetComponent<MagnusWord>();
        Word = word;
        word.wordManager = wordManager;
    }
}
