using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class ThemeButton : MonoBehaviour 
{
	/// The button theme.
	public Button btnTheme;

	/// The button theme image.
	public Image btnThemeImage;

	/// The night mode on sprite.
	public Sprite nightModeOnSprite;

	/// The night mode off sprite.
	public Sprite nightModeOffSprite;

	/// <summary>
	/// Start this instance.
	/// </summary>
	void Start()
	{
		btnTheme.onClick.AddListener(() => {
			if (InputManager.Instance.canInput ()) {
				UIThemeManager.Instance.ToggleThemeStatus	();
			}
		});
	}

	/// <summary>
	/// Raises the enable event.
	/// </summary>
	void OnEnable()
	{
		UIThemeManager.OnUIThemeChangedEvent += OnUIThemeChangedEvent;
		initMusicStatus ();
	}

	/// <summary>
	/// Raises the disable event.
	/// </summary>
	void OnDisable()
	{
		UIThemeManager.OnUIThemeChangedEvent -= OnUIThemeChangedEvent;
	}

	/// <summary>
	/// Inits the music status.
	/// </summary>
	void initMusicStatus()
	{
		btnThemeImage.sprite = (AudioManager.Instance.isMusicEnabled) ? nightModeOnSprite : nightModeOffSprite;
	}

	/// <summary>
	/// Raises the user interface theme changed event event.
	/// </summary>
	/// <param name="isDarkThemeEnabled">If set to <c>true</c> is dark theme enabled.</param>
	void OnUIThemeChangedEvent (bool isDarkThemeEnabled)
	{
		btnThemeImage.sprite = (isDarkThemeEnabled) ? nightModeOnSprite : nightModeOffSprite;
	}	
}
