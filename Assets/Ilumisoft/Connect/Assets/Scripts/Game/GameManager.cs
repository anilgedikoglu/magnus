namespace Ilumisoft.Connect.Game
{
    using Ilumisoft.Connect;
    using Ilumisoft.Connect.Core;
    using System.Collections;
    using UnityEngine;
    using UnityEngine.UI;

    /// <summary>
    /// Handles the game flow
    /// </summary>
    public class GameManager : SingletonBehaviour<GameManager>
    {
        [SerializeField]
        private Button returnButton = null;

        /// <summary>
        /// The score of the player
        /// </summary>
        public static int Score { get; private set; }

        /// <summary>
        /// Reference to the game grid
        /// </summary>
        [SerializeField] private GameGrid grid = null;

        /// <summary>
        /// The number of moves the player has left
        /// </summary>
        [SerializeField] private int movesAvailable = 20;

        /// <summary>
        /// Gets or sets the  number of moves the player has left
        /// </summary>
        public int MovesAvailable
        {
            get => this.movesAvailable;
            set => this.movesAvailable = value;
        }

        public Canvas canvas;
        public Camera gameCamera;
        public Camera rawImageCamera;
        public RawImage rawImage;
        private ChatManager chatManager;

        /// <summary>
        /// Start listening to relevant events
        /// </summary>
        private void OnEnable()
        {
            GameEvents.OnElementsDespawned.AddListener(OnElementsDespawned);
        }

        //Stop listening from all events
        private void OnDisable()
        {
            GameEvents.OnElementsDespawned.RemoveListener(OnElementsDespawned);
        }

        /// <summary>
        /// Starts and processes the game flow
        /// </summary>
        /// <returns></returns>
        private IEnumerator Start()
        {
            this.returnButton.onClick.AddListener(OnBackButtonClick);

            InitializeGame();

            //Wait for the game to be executed completely
            yield return StartCoroutine(RunGame());

            //Wait for the game to finish
            yield return StartCoroutine(EndGame());
        }

        /// <summary>
        /// Returns to the menu scene
        /// </summary>
        protected void OnBackButtonClick()
        {
            SceneLoadingManager.Instance.LoadScene(SceneNames.Menu);
        }

        /// <summary>
        /// Check for escape button
        /// </summary>
        private void Update()
        {
            /*
            if (Input.GetKey(KeyCode.Escape))
            {
                OnBackButtonClick();
            }*/

            if (chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnudots" && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 1" && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 2"
                && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 3" && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 4"
                && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 5" && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 6"
                && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 7" && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 8"
                && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap 9" && chatManager.PlayerDataManager.GetChatVariableValue("mod") != "magnusdots hamle cevap cok iyi")
            {
                Destroy(gameObject.transform.parent.gameObject);
            }
        }

        /// <summary>
        /// Initilaizes the game and the grid
        /// </summary>
        public void InitializeGame()
        {
            chatManager = FindObjectOfType<ChatManager>();

            RectTransform canvasRect = canvas.gameObject.GetComponent<RectTransform>();

            rawImageCamera.targetTexture = new RenderTexture((int)canvasRect.sizeDelta.x, (int)canvasRect.sizeDelta.y, 16, RenderTextureFormat.ARGB32);
            rawImage.texture = rawImageCamera.targetTexture;

            Score = 0;

            this.grid.SetUpGrid();
        }

        /// <summary>
        /// Runs the game loop
        /// </summary>
        /// <returns></returns>
        public IEnumerator RunGame()
        {
            //Game Loop
            while (this.MovesAvailable > 0)
            {
                //Wait for the Player to select elements
                yield return this.grid.WaitForSelection();

                //Despawn selected elements
                yield return this.grid.DespawnSelection();

                //Wait for the grid elements to finish movement
                yield return this.grid.WaitForMovement();

                //Respawn despawned elements
                yield return this.grid.RespawnElements();
            }
        }

        /// <summary>
        /// Loads the game over scene
        /// </summary>
        /// <returns></returns>
        public IEnumerator EndGame()
        {
            yield return new WaitForSeconds(0.5f);

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots son skor", Score.ToString());

            int highScore = 0;

            if (!int.TryParse(chatManager.PlayerDataManager.GetChatVariableValue("magnudots en yuksek skor"), out highScore))
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots en yuksek skor", Score.ToString());
            }

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots eski en yuksek skor", chatManager.PlayerDataManager.GetChatVariableValue("magnudots en yuksek skor"));

            if (Score > highScore)
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots en yuksek skor", Score.ToString());

                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "magnudots en yuksek skor gecildi");
            }
            else
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "magnudots en yuksek skor gecilmedi");
            }

            int kazanma = chatManager.PlayerDataManager.GetChatVariableValueInt("magnudots kazanma");
            if (Score > chatManager.magnusPreferences.magnuDots.baseScore + chatManager.magnusPreferences.magnuDots.increaseAmount * kazanma)
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots kazanma", (kazanma + 1).ToString());
            }

            chatManager.ClickAnswerBubble(null, 0, 0, false);

            if (chatManager.magnusPreferences.magnuDotsEnerjiKazanmaSkoru != 0)
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots kazanilan enerji", (((int)Score + chatManager.magnusPreferences.magnuDotsEnerjiKazanmaSkoru) / chatManager.magnusPreferences.magnuDotsEnerjiKazanmaSkoru).ToString(), false);
            else
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnudots kazanilan enerji", (((int)Score + 100) / 100).ToString(), false);

            Destroy(gameObject.transform.parent.gameObject);
        }

        /// <summary>
        /// Gets invoked when the user has finished its move and 
        /// the selected elements are despawned
        /// </summary>
        /// <param name="count"></param>
        private void OnElementsDespawned(int count)
        {
            chatManager = GameObject.FindObjectOfType<ChatManager>();

            if (count < 10)
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "magnusdots hamle cevap " + count.ToString());
            }
            else
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", "magnusdots hamle cevap cok iyi");
            }

            chatManager.ClickAnswerBubble(null, 0, 0, false);

            //Update score
            int oldScore = Score;
            Score = oldScore + count * (count - 1);

            //Invoke score changed event
            GameEvents.OnScoreChanged.Invoke(oldScore, Score);
        }
    }
}