using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

[RequireComponent(typeof(Button))]
public class RestartButton : MonoBehaviour
{
    void Start()
    {
        GetComponent<Button>().onClick.AddListener(OnClick);
    }

    public static void OnClick()
    {
        if (UserProgress.Current.GetGameState<GameState>(UserProgress.Current.CurrentGameId) != null)
        {
            UserProgress.Current.GetGameState<GameState>(UserProgress.Current.CurrentGameId).IsGameOver = true;
            UserProgress.Current.SaveGameState(UserProgress.Current.CurrentGameId);
            UserProgress.Current.Save();
        }

        //SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }
}