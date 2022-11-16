
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
using System;
#if APPADVISORY_LEADERBOARD
using AppAdvisory.social;
#endif
#if APPADVISORY_ADS
using AppAdvisory.Ads;
#endif

namespace AppAdvisory.AA
{
	/// <summary>
	/// In Charge to display and managed all the UI elements in the game
	/// </summary>
	public class CanvasManager : MonobehaviourHelper
	{
		/// <summary>
		/// Delegate subscribe by the GameManager and triggered when creating a new level (if player win, or if switching manually the levels)
		/// </summary>
		public delegate void CreateGame(int level);
		public static event CreateGame OnCreateGame;




		/// <summary>
		/// Facebook url open by the native app on mobile
		/// </summary>
		public string facebookApp = "fb://profile/515431001924232" ;
		/// <summary>
		/// Facebook url open by the web browser if failed to open the native app
		/// </summary>
		public string facebookAddress = "https://www.facebook.com/appadvisory";

		/// <summary>
		/// The level displayed on the top of the game view
		/// </summary>
		public Text m_levelText;

		/// <summary>
		/// Change the text of the level displayed on the top of the game view
		/// </summary>
		void SetLevelText(int level)
		{
			this.m_levelText.text = "Level " + level.ToString() + " / 1200";
		}

		/// <summary>
		/// Reference to the IntroMenu GameObject
		/// </summary>
		public GameObject IntroMenuGO;

		public Button buttonNextLevel;
		public Button buttonLastLevel;
		public Button buttonSetting;
		public Button buttonUnlock;
		public Button buttonLike;
		public Button buttonLeaderboard;
		public Button buttonRate;
		public Button buttonShare;
		public Button buttonMoreGames;
		public Button buttonSound;
		public Button buttonLikeIntro;
		public Button buttonLeaderboardIntro;
		public Button buttonRateIntro;
		public Button buttonShareIntro;
		public Button buttonMoreGamesIntro;
		public Button buttonSoundIntro;
		public Button buttonPlayIntro;
		public Button buttonOpenIntro;

		/// <summary>
		/// Get the max level the player could play. A level is playable if the player unlock the previous level. for exemple: to player the level 10, the player have to cleared the level 
		/// </summary>
		int maxLevel
		{
			get 
			{
				return PlayerPrefs.GetInt (Constant.LEVEL_UNLOCKED, 1);
			}
		}

		/// <summary>
		/// Get the last level the player played
		/// </summary>
		int lastLevel
		{
			get 
			{
				return PlayerPrefs.GetInt (Constant.LAST_LEVEL_PLAYED, 1);
			}
		}


		/// <summary>
		/// Reference to the setting button who will display some icons with an animation when the player click/tap on the settign button
		/// </summary>
		GridLayoutGroup gridLayoutGroup;


		void OnEnable()
		{
			GameManager.OnSuccessStart += OnSuccessStart;
			GameManager.OnSuccessComplete += OnSuccessComplete;
			GameManager.OnFailStart += OnFailStart;
			GameManager.OnFailComplete += OnFailComplete;
		}

		void OnDisable()
		{
			GameManager.OnSuccessStart -= OnSuccessStart;
			GameManager.OnSuccessComplete -= OnSuccessComplete;
			GameManager.OnFailStart -= OnFailStart;
			GameManager.OnFailComplete -= OnFailComplete;
		}


        private IEnumerator Start()
        {
			yield return new WaitForEndOfFrame();
			buttonPlayIntro.onClick.Invoke();
        }

        /// <summary>
        /// Called when GameManager trigger the delegate OnSuccessStart
        /// </summary>
        void OnSuccessStart()
		{
			buttonUnlock.transform.DOScale(Vector3.zero,0.3f);
		}

		/// <summary>
		/// Called when GameManager trigger the delegate OnSuccessComplete. Will create the next level
		/// </summary>
		void OnSuccessComplete()
		{
			PlayNextLevel ();
		}

		/// <summary>
		/// Called when GameManager trigger the delegate OnFailStart. Will show the button unlock if a rewarded video is available
		/// </summary>
		void OnFailStart()
		{
			ShowButtonUnlock();
		}

		/// <summary>
		/// Called when GameManager trigger the delegate OnFailComplete. Will restart the current level
		/// </summary>
		void OnFailComplete()
		{
			ReplayCurrentLevel (lastLevel);
		}

		/// <summary>
		/// Set all the UI In Game Buttons
		/// </summary>
		void SetButtons()
		{

			buttonNextLevel.onClick.AddListener (() => {
				ButtonLogic ();
				OnClickedButtonNextLevel();
				ButtonLogic ();
			});

			buttonLastLevel.onClick.AddListener (() => {
				ButtonLogic ();
				OnClickedButtonPreviousLevel();
				ButtonLogic ();
			});


			foreach (Transform t in buttonSetting.transform.parent) 
			{
				if (t.GetComponent<Canvas> () != null)
					t.GetComponent<Canvas> ().sortingOrder = buttonSetting.transform.parent.childCount - t.GetSiblingIndex ();
			}

			var g = buttonSetting.transform.parent.gameObject;

			g.SetActive (false);
			g.SetActive (true);

			gridLayoutGroup = buttonSetting.GetComponentInParent<GridLayoutGroup>();

			gridLayoutGroup.spacing = new Vector2(0,-43);

			buttonSetting.onClick.AddListener (OnClickedSetting);

			buttonUnlock.onClick.AddListener (() => {
				buttonUnlock.transform.DOScale(Vector3.zero,0.3f);
			});

			buttonUnlock.transform.localScale = Vector3.zero;


			buttonLike.onClick.AddListener (()=>{
				OnClickedSetting();
				OnClickedLike();
			});
			buttonLikeIntro.onClick.AddListener (OnClickedLike);

			buttonLeaderboard.onClick.AddListener (OnClickedOpenLeaderboard);
			buttonLeaderboardIntro.onClick.AddListener (OnClickedOpenLeaderboard);

			buttonRate.onClick.AddListener (()=>{
				OnClickedSetting();
				OnClickedRate();
			});
			buttonRateIntro.onClick.AddListener (OnClickedRate);

			buttonShare.onClick.AddListener (()=>{
				OnClickedSetting();
				OnClickedShare();
			});
			buttonShareIntro.onClick.AddListener (OnClickedShare);


			buttonMoreGames.onClick.AddListener (()=>{
				OnClickedSetting();
				OnClickedMoreGame();
			});
			buttonMoreGamesIntro.onClick.AddListener (OnClickedMoreGame);


			buttonPlayIntro.onClick.AddListener (() => {
				StartTheGame();
				introMenu.AnimationIntroToGame(()=>{
					introMenu.gameObject.SetActive(false);
				});
			});

			buttonOpenIntro.onClick.AddListener (() => {
				OnClickedSetting();
				introMenu.gameObject.SetActive(true);
				introMenu.AnimationGameToIntro(()=>{
				});
			});


			int soundOn = PlayerPrefs.GetInt(Constant.SOUND_ON,1);

			if (soundOn == 0) 
			{
				//music.Stop ();
				buttonSound.transform.GetChild (0).gameObject.SetActive (false);
				buttonSound.transform.GetChild (1).gameObject.SetActive (true);

				buttonSoundIntro.transform.GetChild (1).gameObject.SetActive (false);
				buttonSoundIntro.transform.GetChild (2).gameObject.SetActive (true);
			}
			else 
			{
				//music.Play ();
				buttonSound.transform.GetChild (0).gameObject.SetActive (true);
				buttonSound.transform.GetChild (1).gameObject.SetActive (false);

				buttonSoundIntro.transform.GetChild (1).gameObject.SetActive (true);
				buttonSoundIntro.transform.GetChild (2).gameObject.SetActive (false);
			}

			buttonSound.onClick.AddListener (()=>{
				OnClickedSetting();
				OnClickedSound();
			});
			buttonSoundIntro.onClick.AddListener (OnClickedSound);
		}

		/// <summary>
		/// Turn on/off the sounds in the game
		/// </summary>
		void OnClickedSound()
		{
			int soundOn = PlayerPrefs.GetInt(Constant.SOUND_ON,1);

			if (soundOn == 1) 
			{
				//music.Stop ();
				PlayerPrefs.SetInt (Constant.SOUND_ON, 0);
				buttonSound.transform.GetChild (0).gameObject.SetActive (false);
				buttonSound.transform.GetChild (1).gameObject.SetActive (true);

				buttonSoundIntro.transform.GetChild (1).gameObject.SetActive (false);
				buttonSoundIntro.transform.GetChild (2).gameObject.SetActive (true);
			}
			else 
			{
				//music.Play ();
				PlayerPrefs.SetInt (Constant.SOUND_ON, 1);
				buttonSound.transform.GetChild (0).gameObject.SetActive (true);
				buttonSound.transform.GetChild (1).gameObject.SetActive (false);

				buttonSoundIntro.transform.GetChild (1).gameObject.SetActive (true);
				buttonSoundIntro.transform.GetChild (2).gameObject.SetActive (false);
			}


			PlayerPrefs.Save();
		}

		/// <summary>
		/// Open the buttons menu in the game
		/// </summary>
		void OnClickedSetting()
		{
			buttonSetting.enabled = false;

			float startvalue = 10;
			float endvalue = -43;
			if(gridLayoutGroup.spacing.y == -43)
			{
				startvalue = -43;
				endvalue = 10;

				buttonSetting.transform.DORotate ( new Vector3(0, 0, 360), 1, RotateMode.FastBeyond360);
			}
			else
			{
				buttonSetting.transform.DORotate ( new Vector3(0, 0, -360), 1, RotateMode.FastBeyond360);
			}

			DOVirtual.Float(startvalue, endvalue, 1, (float value) => {
				gridLayoutGroup.spacing = new Vector2(0,value);
			}).OnComplete(() => {
				buttonSetting.enabled = true;
			});
		}

		/// <summary>
		/// Open the like page. Please define your URL here
		/// </summary>
		void OnClickedLike()
		{
			Debug.Log ("TODO: replace your like links here");

			float startTime;
			startTime = Time.timeSinceLevelLoad;

			//open the facebook app
			Application.OpenURL(facebookApp);

			if (Time.timeSinceLevelLoad - startTime <= 1f)
			{
				//fail. Open safari.
				Application.OpenURL(facebookAddress);
			}
		}

		/// <summary>
		/// If player clics on the leaderbord button, we call this method. Works only on mobile (iOS & Android) if using Very Simple Leaderboard by App Advisory : http://u3d.as/qxf
		/// </summary>
		public void OnClickedOpenLeaderboard()
		{
			#if APPADVISORY_LEADERBOARD
			LeaderboardManager.ShowLeaderboardUI();
			#else
			Debug.LogWarning("OnClickedOpenLeaderboard : works only on mobile (iOS & Android), with Very Simple Leaderboard : http://u3d.as/qxf");
			#endif
		}


		/// <summary>
		/// Call the share method. Please define your methods here.
		/// </summary>
		/// 
		void OnClickedShare()
		{
			Debug.Log ("TODO: put your share code here");
		}

		/// <summary>
		/// Call the rate method of the RateManager. If yhe player click on it, we display immediately the pop up of the RateManager by the method PromptPopup
		/// </summary>
		void OnClickedRate()
		{
			//FindObjectOfType<RateUsManager>().PromptPopup();
		}


		/// <summary>
		/// Open a link to your games (exemple: App Store Developer page). Please put your own URL here.
		/// </summary>
		void OnClickedMoreGame()
		{
			Debug.Log ("TODO: replace the link here");

			Application.OpenURL ("https://barouch.fr/moregames.php");
		}

		void Awake()
		{
			if (!PlayerPrefs.HasKey (Constant.LAST_LEVEL_PLAYED)) {
				PlayerPrefs.SetInt (Constant.LAST_LEVEL_PLAYED, 1);
			} 

			if (!PlayerPrefs.HasKey (Constant.LEVEL_UNLOCKED))
			{
				Debug.LogError("asdsa");
				PlayerPrefs.SetInt (Constant.LEVEL_UNLOCKED, 1);
			} 

			PlayerPrefs.Save ();



			SetButtons ();


			ButtonLogic ();


			IntroMenuGO.SetActive (true);
		}


		/// <summary>
		/// Display the next and/or last button (the arrow around the level at the top of the screen)
		/// </summary>
		void ButtonLogic()
		{

			if (lastLevel == 1)
				SetButtonActive(buttonLastLevel,false);
			else
				SetButtonActive(buttonLastLevel,true);

			if(lastLevel >= maxLevel)
				SetButtonActive(buttonNextLevel,false);
			else
				SetButtonActive(buttonNextLevel,true);
		}

		/// <summary>
		/// Activate and enable - or not - buttons
		/// </summary>
		void SetButtonActive(Button b,bool isActive)
		{
			Color c = b.GetComponent<Image> ().color;

			if (isActive) {
				b.GetComponent<Image> ().color = new Color(c.r,c.g,c.b,1f);
				b.interactable = true;
			}  else {
				b.GetComponent<Image> ().color = new Color(c.r,c.g,c.b,0f);
				b.interactable = false;
			}

		}

		/// <summary>
		/// Call StartTheGameCorout 
		/// </summary>
		public void StartTheGame()
		{
			StartCoroutine ("StartTheGameCorout");
		}

		/// <summary>
		/// Start PlayLevel method at the next frame
		/// </summary>
		IEnumerator StartTheGameCorout()
		{
			yield return 0;

			PlayLevel (lastLevel);
		}

		/// <summary>
		/// When the player failed, we show an unlock button ONLY IF there is a rewarded video available
		/// </summary>
		void ShowButtonUnlock()
		{
			bool isReadyRewardedVideo = false;

			if (isReadyRewardedVideo)
			{
				if (buttonUnlock.transform.localScale.x == 1) {
					buttonUnlock.transform.DOScale (Vector3.one * 1.5f, 0.3f).SetLoops (6, LoopType.Yoyo);
				} else {
					buttonUnlock.transform.DOScale (Vector3.one, 0.3f);
				}
			}
		}

		/// <summary>
		/// Run the level logic on the UI side
		/// </summary>
		private void PlayLevel(int level)
		{
			SetLevelText (level);

			if (level > maxLevel)
			{
				PlayerPrefs.SetInt(Constant.LEVEL_UNLOCKED, level);
			}

			PlayerPrefs.SetInt (Constant.LAST_LEVEL_PLAYED, level);

			PlayerPrefs.Save ();

			ButtonLogic ();

			if(OnCreateGame != null)
				OnCreateGame(level);
		}

		/// <summary>
		/// Method called when the player clicked on the left arrow on the left of the level text on the top of the screen during the game
		/// </summary>
		private void OnClickedButtonPreviousLevel()
		{
			int last = lastLevel;

			last--;

			if (last < 1)
				last = 1;

			SetLevelText(last);

			PlayLevel(last);
		}

		/// <summary>
		/// Method called when the player clicked on the right arrow on the roght of the level text on the top of the screen during the game
		/// </summary>
		private void OnClickedButtonNextLevel()
		{
			PlayNextLevel ();

		}

		/// <summary>
		/// Method called when the player failed and so ... we replay the current level
		/// </summary>
		private void ReplayCurrentLevel(int level)
		{
			PlayLevel(level);
		}

		/// <summary>
		/// Method called when the player have to play the next level (if the current level is cleared, or if the payer taps/Clicks on the next button or if the player see a rewarded video to unlock the current level
		/// </summary>
		private void PlayNextLevel()
		{
			int last = lastLevel;

			last++;
			SetLevelText(last);

			PlayLevel(last);
		}
	}
}