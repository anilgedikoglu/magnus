using System;
using UnityEngine;

[Serializable]
public class GameState
{
    public event Action StateUpdate;

    [SerializeField]
    int score;
    [SerializeField]
    int topScore;

    [SerializeField]
    int[] field = new int[0];

    [SerializeField]
    bool isGameOver;

    [SerializeField]
    string themeId;

    public int Score
    {
        get => score;
        set
        {
            score = value;

            if (score > topScore)
                topScore = score;

            StateUpdate?.Invoke();
        }
    }

    public int TopScore => topScore;

    public bool IsGameOver
    {
        get => isGameOver;
        set => isGameOver = value;
    }

    public string ThemeId
    {
        get => themeId;
        set => themeId = value;
    }

    public int[] GetField()
    {
        return (int[]) field.Clone();
    }

    public void SetField(int[] value)
    {
        field = (int[]) value.Clone();
    }
}
