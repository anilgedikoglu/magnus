using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Text))]
public class HighscoreText : MonoBehaviour
{
    private IHighscoreSystem _highscoreSystem;

    private Text _highscoreText;
    
    private void Awake()
    {
        _highscoreSystem = InterfaceUtilities.FindObjectOfType<IHighscoreSystem>();
        _highscoreText = GetComponent<Text>();
    }

    private void Start()
    {
        _highscoreText.text = ((int)_highscoreSystem.Highscore).ToString();
    }
}
