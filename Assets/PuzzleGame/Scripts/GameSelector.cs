using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class GameSelector : MonoBehaviour
{
    [SerializeField]
    GamePreset[] gamePresets;

    [SerializeField]
    GameObject navigation;
    [SerializeField]
    GameObject fieldBlocker;

    [SerializeField]
    Button next;
    [SerializeField]
    Button previous;
    [SerializeField]
    Toggle[] toggles;

    [SerializeField]
    GameObject restartButton;

    [SerializeField]
    PriceLabel priceLabel;

    [SerializeField]
    MonetizeButton monetizeButton;

    [SerializeField]
    GameObject gameOver;

        
    bool isGameFinished;

    int currentGameIndex;
    BaseGameController currentGame;

    static readonly int BigField = Animator.StringToHash("Big");
    static readonly int MiddleField = Animator.StringToHash("Middle");
    static readonly int SmallField = Animator.StringToHash("Small");


    [HideInInspector] public ChatManager chatManager;
    public GameObject gameFolder;
    protected GameState currentGameState;
    public Magnu2048Settings magnu2048Settings;

    protected virtual int TopScoreValue
    {
        get { return UserProgress.Current.GetGameState<GameState>(UserProgress.Current.CurrentGameId).TopScore; }
    }

    protected virtual int ScoreValue
    {
        get { return UserProgress.Current.GetGameState<GameState>(UserProgress.Current.CurrentGameId).Score; }
    }

    public void MinimizeCurrentGame(bool value)
    {
        if (!value)
        {
            MaximizeCurrentGame();
            return;
        }

        //Time.timeScale = 0;
        ResetTriggers();
        currentGame.fieldAnimator.SetTrigger(SmallField);
        navigation.SetActive(false);
        restartButton.SetActive(false);
    }

    void MaximizeCurrentGame()
    {
        bool isGameAvailable = gamePresets[currentGameIndex].price.value <= 0 ||
                               UserProgress.Current.IsItemPurchased(currentGame.name);

        if (isGameAvailable && !gameOver.activeSelf)
        {
            //Time.timeScale = 1;
            ResetTriggers();
            currentGame.fieldAnimator.SetTrigger(BigField);
            navigation.SetActive(true);
            restartButton.SetActive(true);
        }
        else
        {
            ResetTriggers();
            currentGame.fieldAnimator.SetTrigger(MiddleField);
            navigation.SetActive(true);
            fieldBlocker.SetActive(true);
        }
    }

    void ResetTriggers()
    {
        currentGame.fieldAnimator.ResetTrigger(BigField);
        currentGame.fieldAnimator.ResetTrigger(MiddleField);
        currentGame.fieldAnimator.ResetTrigger(SmallField);
    }

    void OnNextClick()
    {
        currentGameIndex++;
        currentGameIndex %= gamePresets.Length;

        UpdateCurrentGame();
    }

    void OnPreviousClick()
    {
        currentGameIndex--;
        if (currentGameIndex < 0)
            currentGameIndex += gamePresets.Length;

        UpdateCurrentGame();
    }

    void OnGamePurchased()
    {
        UserProgress.Current.OnItemPurchased(gamePresets[currentGameIndex].name);
        //UpdateCurrentGame();
    }

    void UpdateCurrentGame()
    {
        /*
        if (currentGame)
        {
            Destroy(currentGame.gameObject);
        }*/

        currentGame = Instantiate(gamePresets[currentGameIndex].gamePrefab);
        currentGame.name = gamePresets[currentGameIndex].name;
        UserProgress.Current.CurrentGameId = currentGame.name;

        for (int i = 0; i < toggles.Length; i++)
        {
            toggles[i].isOn = i == currentGameIndex;
        }

        gameOver.SetActive(false);

        Price price = gamePresets[currentGameIndex].price;

        bool isGameAvailable = price.value <= 0 ||
                               UserProgress.Current.IsItemPurchased(currentGame.name);

        //Time.timeScale = isGameAvailable ? 1 : 0;

        priceLabel.gameObject.SetActive(!isGameAvailable);
        monetizeButton.gameObject.SetActive(!isGameAvailable);

        restartButton.SetActive(isGameAvailable);
        fieldBlocker.SetActive(!isGameAvailable);

        if (isGameAvailable)
        {
            currentGame.GameOver += OnGameOver;
            return;
        }

        priceLabel.SetPrice(currentGame.name, price);

        ResetTriggers();
        currentGame.fieldAnimator.SetTrigger(MiddleField);

        monetizeButton.SetPrice(currentGame.name, price);
    }

    void OnGameOver(bool setMod)
    {
        StartCoroutine(GameOverDelay(setMod));
        currentGame.gameObject.GetComponent<Animator>().SetBool("exit", true);
    }

    void OnGameOver()
    {
        StartCoroutine(GameOverDelay(true));
        currentGame.gameObject.GetComponent<Animator>().SetBool("exit", true);
    }

    IEnumerator GameOverDelay(bool setMod)
    {
        yield return new WaitForSeconds(1f);

        ResetTriggers();
        currentGame.fieldAnimator.SetTrigger(MiddleField);
        fieldBlocker.SetActive(true);

        restartButton.SetActive(false);
        gameOver.SetActive(true);

        if (setMod)
        {
            int score = 0;
            int topScrore = 0;

            score = ScoreValue;
            topScrore = ScoreValue;
            Debug.Log(score);
            Debug.Log(topScrore);

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers son skor", score.ToString());

            int eskiEnYuksekSkor = 0;

            int.TryParse(chatManager.PlayerDataManager.GetChatVariableValue("magnumbers en yuksek skor"), out eskiEnYuksekSkor);

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers eski en yuksek skor", eskiEnYuksekSkor.ToString());

            if (chatManager.magnusPreferences.magnu2048EnerjiKazanmaSkoru != 0)
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers kazanilan enerji", (score / chatManager.magnusPreferences.magnu2048EnerjiKazanmaSkoru).ToString(), false);
            else
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers kazanilan enerji", (score / 100).ToString(), false);

            if (score > eskiEnYuksekSkor)
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers en yuksek skor", topScrore.ToString());
            else
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers en yuksek skor", eskiEnYuksekSkor.ToString());

            if (topScrore > eskiEnYuksekSkor)
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", chatManager.magnu2048Settings.rekorGecildiModu);
            else
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", chatManager.magnu2048Settings.rekorGecilmediModu);

            chatManager.ClickAnswerBubble(null, 0, 0, false);

            int kazanma = chatManager.PlayerDataManager.GetChatVariableValueInt("magnumbers kazanma");
            if (score > chatManager.magnusPreferences.magnuMbers.baseScore + chatManager.magnusPreferences.magnuMbers.increaseAmount * kazanma)
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnumbers kazanma", (kazanma + 1).ToString());
            }
        }

        Destroy(currentGame.gameObject);
        Destroy(gameFolder);
    }

    private void Update()
    {
        if (!magnu2048Settings.IsMagnu2048Mod(chatManager.PlayerDataManager.GetChatVariableValue("mod")) && !isGameFinished)
        {
            OnGameOver(false);
            isGameFinished = true;
        }
    }

    void Awake()
    {
        chatManager = GameObject.FindObjectOfType<ChatManager>();

        currentGameIndex = Array.FindIndex(gamePresets, g => g.name == UserProgress.Current.CurrentGameId);

        if (currentGameIndex < 0)
            currentGameIndex = 0;

        //UpdateCurrentGame();

        next.onClick.AddListener(OnNextClick);
        previous.onClick.AddListener(OnPreviousClick);

        monetizeButton.PurchaseComplete += OnGamePurchased;
    }

    public void AfterStart()
    {
        //Yorum satiri bulunanlar bizim eklediklerimiz. Asseti degistirmeye zaman olmadigi icin belirli komutlarla acilista istedigimiz hale getiriyoruz.

        //Oyunun daha onceki seferlerden kayit yapmasini istemdigimiz icin tum kayitlari siliyoruz.
        //PlayerPrefs.DeleteAll();

        //Az sonra tum oyun modlarini ve temalari satin alacagimiz icin kullaniciya para veriyoruz.
        UserProgress.Current.Coins = 10000;

        //Oyun modunu 0a esitliyoruz.
        currentGameIndex = 0;

        //UpdateCurrentGame();

        //Iki oyun modunu da satin aliyoruz.
        UserProgress.Current.OnItemPurchased(gamePresets[1].name);
        UserProgress.Current.OnItemPurchased(gamePresets[0].name);

        //Satin alma isleminin refresh edilip etkinlesmis olmasini icin sag tusa basilmis gibi yapiyoruz.
        next.onClick.Invoke();

        GameState gameState = UserProgress.Current.GetGameState<GameState>(UserProgress.Current.CurrentGameId);

        currentGameState = gameState;
    }
}
