using System;
using UnityEngine;

[Serializable]
public class GameState2048Bricks : GameState
{
    [SerializeField]
    Vector2Int currentBrick;
    [SerializeField]
    int nextBrick;

    public Vector2Int CurrentBrick
    {
        get => currentBrick;
        set => currentBrick = value;
    }

    public int NextBrick
    {
        get => nextBrick;
        set => nextBrick = value;
    }
}
