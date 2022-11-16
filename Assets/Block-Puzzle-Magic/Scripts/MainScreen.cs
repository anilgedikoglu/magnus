using UnityEngine;
using System.Collections;

public class MainScreen : MonoBehaviour 
{	
	/// <summary>
	/// Raises the play button pressed event.
	/// </summary>
	public void OnPlayButtonPressed()
	{
		if (InputManager.Instance.canInput ()) {
			AudioManager.Instance.PlayButtonClickSound ();
			StackManager.Instance.selectModeScreen.Activate();
		}
	}

	private void Start()
	{
		StartCoroutine(PressPlayButton());
	}

	IEnumerator PressPlayButton()
	{
		yield return new WaitForEndOfFrame();
		OnPlayButtonPressed();
		yield return new WaitForEndOfFrame();

		ChatManager chatManager = FindObjectOfType<ChatManager>();
		switch(chatManager.PlayerDataManager.GetChatVariableValue("magnutris oyun modu"))
        {
			case "zaman":
				FindObjectOfType<SelectMode>().OnTimedButtonPressed();
				break;
			case "bomba":
				FindObjectOfType<SelectMode>().OnBlastButtonPressed();
				break;
			case "gelişmiş":
				FindObjectOfType<SelectMode>().OnAdvanceButtonPressed();
				break;
			default:
				FindObjectOfType<SelectMode>().OnClassicButtonPressed();
				break;
		}
		//FindObjectOfType<SelectMode>().OnClassicButtonPressed();
	
	}
}
