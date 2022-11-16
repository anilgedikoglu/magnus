using UnityEngine;

public class HighscoreSystem : MonoBehaviour, IHighscoreSystem
{
    private const string PlayerPrefsKey = "Highscore";

    private float _highscore = 0;

    public float Highscore
    {
        get => _highscore;
        set
        {
            _highscore = value;
            SaveHighscore();
        }
    }

    private void Awake()
    {
        LoadHighscore();
    }

    private void LoadHighscore()
    {
        if (PlayerPrefs.HasKey(PlayerPrefsKey))
        {
            _highscore = PlayerPrefs.GetFloat(PlayerPrefsKey);
        }
    }

    private void SaveHighscore()
    {
        PlayerPrefs.SetFloat(PlayerPrefsKey, _highscore);
    }
}
