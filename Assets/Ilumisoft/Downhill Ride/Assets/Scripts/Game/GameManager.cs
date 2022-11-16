using Ilumisoft.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

public class GameManager : MonoBehaviour
{
    private IScoreSystem _scoreSystem;

    private IHighscoreSystem _highscoreSystem;

    private SceneManager _sceneManager;
    
    private EventManager _eventManager;

    private ObstacleSpawnSystem _obstacleSpawnSystem;

    private GameEvent _gameOverEvent;

    private ChatManager _chatManager;

    private RenderTexture cameraRenderTexture;

    public Canvas canvas;

    public Camera gameCamera;

    public RawImage cameraRawImage;

    public GameObject gameFolder;

    public Animator animator;

    private void Awake()
    {
        RectTransform canvasRect = canvas.gameObject.GetComponent<RectTransform>();

        _eventManager = FindObjectOfType<EventManager>();
        _sceneManager = FindObjectOfType<SceneManager>();
        _obstacleSpawnSystem = FindObjectOfType<ObstacleSpawnSystem>();
        _chatManager = FindObjectOfType<ChatManager>();

        _scoreSystem = InterfaceUtilities.FindObjectOfType<IScoreSystem>();
        _highscoreSystem = InterfaceUtilities.FindObjectOfType<IHighscoreSystem>();

        gameCamera.targetTexture = new RenderTexture((int)canvasRect.rect.width, (int)canvasRect.rect.height, 16, RenderTextureFormat.ARGB32);
        cameraRawImage.texture = gameCamera.targetTexture;
    }

    private void Start()
    {
        _gameOverEvent = _eventManager.GetEvent<GameOverEvent>();
        _gameOverEvent.AddListener(OnGameOver);

        _scoreSystem.ResetScore();

        //Time.timeScale = 1.0f;
    }

    private void Update()
    {
        _scoreSystem.ModifyScore(5 * Time.deltaTime);

        if (_chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnuflow")
        {
            foreach (GameObject obstacle in _obstacleSpawnSystem._pool)
            {
                Destroy(obstacle);
            }

            Destroy(gameFolder);
        }
    }

    private void OnGameOver()
    {
        //GameOver should only be triggered once
        _gameOverEvent.RemoveListener(OnGameOver);

        //Stop game time
        //Time.timeScale = 0.0f;

        //Update highscore
        if (_scoreSystem.Score > _highscoreSystem.Highscore)
        {
            _highscoreSystem.Highscore = _scoreSystem.Score;
            _chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "magnuflow en yuksek skor gecildi");
        }
        else
        {
            _chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "magnuflow en yuksek skor gecilmedi");
        }

        ChatManager chatManager = FindObjectOfType<ChatManager>();

        int kazanma = chatManager.PlayerDataManager.GetChatVariableValueInt("magnuflow kazanma");
        if (_scoreSystem.Score > chatManager.magnusPreferences.magnuFlow.baseScore + chatManager.magnusPreferences.magnuFlow.increaseAmount * kazanma)
        {
            chatManager.PlayerDataManager.AddElementToChatVariableList("magnuflow kazanma", (kazanma + 1).ToString());
        }

        //Load game over scene after 1 second
        DestroyGame();
    }

    public void DestroyGame()
    {
        _chatManager.PlayerDataManager.AddElementToChatVariableList("magnuflow eski en yuksek skor", _chatManager.PlayerDataManager.GetChatVariableValue("magnuflow en yuksek skor"));
        _chatManager.PlayerDataManager.AddElementToChatVariableList("magnuflow en yuksek skor", ((int)_highscoreSystem.Highscore).ToString());
        _chatManager.PlayerDataManager.AddElementToChatVariableList("magnuflow son skor", ((int)_scoreSystem.Score).ToString());

        if (_chatManager.magnusPreferences.magnuFlowEnerjiKazanmaSkoru != 0)
            _chatManager.PlayerDataManager.AddElementToChatVariableList("magnuflow kazanilan enerji", (((int)_scoreSystem.Score + _chatManager.magnusPreferences.magnuFlowEnerjiKazanmaSkoru) / _chatManager.magnusPreferences.magnuFlowEnerjiKazanmaSkoru).ToString(), false);
        else
            _chatManager.PlayerDataManager.AddElementToChatVariableList("magnuflow kazanilan enerji", (((int)_scoreSystem.Score + 100) / 100).ToString(), false);

        _chatManager.ClickAnswerBubble(null, 0, 0, false);

        animator.SetBool("exit", true);

        StartCoroutine(DestroyDelay());
    }

    System.Collections.IEnumerator DestroyDelay()
    {
        yield return new WaitForSeconds(0.5f);

        foreach (GameObject obstacle in _obstacleSpawnSystem._pool)
        {
            Destroy(obstacle);
        }

        Destroy(gameFolder);
    }
}