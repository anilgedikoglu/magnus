using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace AimTrainer
{
    public class ScoreBoardManager : MonoBehaviour
    {
        public Text scoreText;
        public Text bestScoreText;
        public Text timerText;
        public RectTransform timerRt;

        float startTime;

        ChatManager chatManager;

        private void Awake()
        {
            chatManager = GameObject.FindObjectOfType<ChatManager>();

            AimTrainer.pause = false;
            AimTrainer.endOfTheGame = false;
            AimTrainer.score = 0;
        }

        // Start is called before the first frame update
        void Start()
        {
            startTime = Time.time;
        }

        // Update is called once per frame
        void Update()
        {
            scoreText.text = AimTrainer.score.ToString();
            bestScoreText.text = PlayerPrefs.GetInt("aimTrainerBestScore", 0).ToString();

            float scale = 1f - (Time.time - startTime) / AimTrainer.timer;

            if (scale > 0)
            {
                timerRt.localScale = new Vector3(scale, timerRt.localScale.y, timerRt.localScale.z);
                timerText.text = ((int)(AimTrainer.timer - (Time.time - startTime))).ToString();
            }
            else
            {
                timerRt.localScale = new Vector3(0f, timerRt.localScale.y, timerRt.localScale.z);
                timerText.text = (0).ToString();

                if (!AimTrainer.endOfTheGame)
                {
                    AimTrainer.endOfTheGame = true;
                    EndGame();
                }
            }

            if (!chatManager.magNukemSettings.IsMagNukeMod(chatManager.PlayerDataManager.GetChatVariableValue("mod")))
            {
                Destroy(gameObject.GetComponent<RectTransform>().parent.GetComponent<RectTransform>().parent.gameObject);
#if UNITY_EDITOR
                Cursor.lockState = CursorLockMode.None;
#endif
            }
        }

        void EndGame()
        {
            Debug.Log("End of the game");

            int oldBestScore = PlayerPrefs.GetInt("aimTrainerBestScore", 0);

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnukem son skor", AimTrainer.score.ToString());

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnukem eski en yuksek skor", oldBestScore.ToString());

            if (chatManager.magnusPreferences.magnukemEnerjiKazanmaSkoru != 0)
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnukem kazanilan enerji", (AimTrainer.score / chatManager.magnusPreferences.magnukemEnerjiKazanmaSkoru).ToString(), false);
            else
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnukem kazanilan enerji", (AimTrainer.score / 100).ToString(), false);

            int kazanma = chatManager.PlayerDataManager.GetChatVariableValueInt("magnukem kazanma");

            if (AimTrainer.score > chatManager.magnusPreferences.magnuKem.baseScore + chatManager.magnusPreferences.magnuKem.increaseAmount * kazanma)
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("magnukem kazanma", (kazanma + 1).ToString());

                if (AimTrainer.score > oldBestScore)
                {
                    PlayerPrefs.SetInt("aimTrainerBestScore", AimTrainer.score);

                    chatManager.ClickVirtualButton(chatManager.magNukemSettings.enYuksekSkorGecildiEnerjiModu);
                }
                else
                {
                    chatManager.ClickVirtualButton(chatManager.magNukemSettings.enYuksekSkorGecilmediEnerjiModu);
                }
            }
            else
            {
                if (AimTrainer.score > oldBestScore)
                {
                    PlayerPrefs.SetInt("aimTrainerBestScore", AimTrainer.score);
                    chatManager.ClickVirtualButton(chatManager.magNukemSettings.enYuksekSkorGecildiModu);
                }
                else
                {
                    chatManager.ClickVirtualButton(chatManager.magNukemSettings.enYuksekSkorGecilmediModu);
                }
            }

            chatManager.PlayerDataManager.AddElementToChatVariableList("magnukem en yuksek skor", PlayerPrefs.GetInt("aimTrainerBestScore", 0).ToString());
        }
    }
}