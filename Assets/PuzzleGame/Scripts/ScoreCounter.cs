using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Text))]
public class ScoreCounter : MonoBehaviour
{
    Text label;

    protected GameState currentGameState;
    
    protected virtual int Value
    {
        get { return currentGameState.Score; }
    }

    void Start()
    {
        label = GetComponent<Text>();

        OnProgressUpdate();
        UserProgress.Current.ProgressUpdate += OnProgressUpdate;
    }

    void OnDestroy()
    {
        UserProgress.Current.ProgressUpdate -= OnProgressUpdate;

        if (currentGameState != null)
            currentGameState.StateUpdate -= OnStateUpdate;
    }

    void OnProgressUpdate()
    {
        GameState gameState = UserProgress.Current.GetGameState<GameState>(UserProgress.Current.CurrentGameId);

        if (currentGameState != null)
            currentGameState.StateUpdate -= OnStateUpdate;

        currentGameState = gameState;

        if (gameState == null)
            return;

        OnStateUpdate();
        gameState.StateUpdate += OnStateUpdate;
    }

    void OnStateUpdate()
    {
        label.text = Value.ToString();
    }
}