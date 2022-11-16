using UnityEngine;

[CreateAssetMenu(fileName = "GamePreset", menuName = "Game Preset")]
public class GamePreset : ScriptableObject
{
    public Price price;
    public BaseGameController gamePrefab;
}