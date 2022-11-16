using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class MagnusWordManager : MonoBehaviour
{
    internal List<MagnusWordPlace> places;

    [SerializeField] internal MagnusWordDatabase wordDatabase;

    private ChatManager chatManager;
    private CurrentPlayerData playerData;

    [SerializeField] internal GameObject wordPrefab;
    [SerializeField] internal GameObject wordPlacePrefab;

    [SerializeField] private RectTransform wordPlacesParent;

    private List<MagnusWordDatabase.wordData> wordDatas;

    private MagnusWordDatabase.wordData _wordData;
    internal MagnusWordDatabase.wordData WordData
    {
        get { return _wordData; }
        set 
        {
            _wordData = value;
            UpdateLetters();
        }
    }

    internal List<string> currentDescreption;

    private int totalUsedTips;

    private List<string> tipMods;

    [SerializeField] private TMP_Text remainingTipCountText;

    private void Awake()
    {
        chatManager = FindObjectOfType<ChatManager>();
        playerData = FindObjectOfType<CurrentPlayerData>();
        places = new List<MagnusWordPlace>(FindObjectsOfType<MagnusWordPlace>());
        currentDescreption = new();
        GetWordDatabase();
    }

    // Start is called before the first frame update
    IEnumerator Start()
    {
        yield return new WaitForSeconds(chatManager.AiMessageDelay);
        SetWord();
    }

    // Update is called once per frame
    void Update()
    {
        if (!IsGameMod(playerData.GetChatVariableValue("mod")))
            Destroy(gameObject);
    }

    private void UpdateLetters()
    {
        CheckPlaces();

        List<char> letters = new List<char>(WordData.word.ToUpper().ToCharArray());
        foreach (MagnusWordPlace wordPlace in places)
        {
            if (letters.Count <= 0)
                break;

            int index = Random.Range(0, letters.Count);
            wordPlace.Word.Letter = letters[index];
            letters.RemoveAt(index);
        }

        if (CheckCorrect())
        {
            UpdateLetters();
            return;
        }
    }

    private void CheckPlaces()
    {
        bool spawn = WordData.word.Length > places.Count;
        int placeCount = places.Count;

        if (spawn)
        {
            for (int i = 0; i < WordData.word.Length - placeCount; i++)
            {
                places.Add(Instantiate(wordPlacePrefab, wordPlacesParent).GetComponent<MagnusWordPlace>());
            }
        }
        else
        {

            for (int i = 0; i < placeCount - WordData.word.Length; i++)
            {
                Destroy(places[^1].gameObject);
                places.RemoveAt(places.Count - 1);
            }
        }
    }

    internal void CheckCorrectAndDestroy()
    {
        string checkedText = string.Empty;
        foreach (MagnusWordPlace wordPlace in places)
        {
            checkedText += wordPlace.Word.Letter;
        }

        if(checkedText == WordData.word.ToUpper())
        {
            Debug.Log("<color=green><b>Doğru bildin. Tebrikler!</b></color>");
            chatManager.ClickVirtualButton(wordDatabase.wordGameTrueMod);
            Destroy(gameObject);
        }
        else
        {
            Debug.Log($"<color=yellow><b>{checkedText} doğru değil.</b></color>");
        }
    }

    internal bool CheckCorrect()
    {
        string checkedText = string.Empty;
        foreach (MagnusWordPlace wordPlace in places)
        {
            checkedText += wordPlace.Word.Letter;
        }

        if (checkedText == WordData.word.ToUpper())
        {
            Debug.Log("<color=green><b>Doğru bildin. Tebrikler!</b></color>");
            return true;
        }
        else
        {
            Debug.Log($"<color=yellow><b>{checkedText} doğru değil.</b></color>");
        }

        return false;
    }

    public void ShowDesreptionText()
    {
        if (tipMods.Count <= 0)
            return;

        totalUsedTips++;
        chatManager.ClickVirtualButton(tipMods[0]);
        tipMods.RemoveAt(0);

        remainingTipCountText.text = "Kalan ipucu: " + tipMods.Count.ToString();
    }

    private void SetWord()
    {
        if (wordDatas.Count <= 0)
            GetWordDatabase();

        totalUsedTips = 0;

        int index = wordDatas.FindIndex(x => x.word.ToLower().Equals(playerData.GetChatVariableValue("kelime").ToLower()));
        WordData = wordDatas[index];
        tipMods = new List<string>(WordData.tipMods);

        remainingTipCountText.text = "Kalan ipucu: " + tipMods.Count.ToString();

        wordDatas.RemoveAt(index);
    }

    private void GetWordDatabase()
    {
        wordDatas = new List<MagnusWordDatabase.wordData>(wordDatabase.words);
    }

    public bool IsGameMod(string mod)
    {
        if (mod == wordDatabase.wordGameMod)
        {
            return true;
        }
        else
        {
            foreach (string tipMod in WordData.tipMods)
            {
                if (mod == tipMod)
                    return true;
            }
        }

        return false;
    }
}
