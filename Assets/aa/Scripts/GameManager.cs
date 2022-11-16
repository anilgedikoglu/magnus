
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
using System;
using DG.Tweening;
using UnityEngine.Events;
using UnityEngine.EventSystems;
#if APPADVISORY_LEADERBOARD
using AppAdvisory.social;
#endif
#if APPADVISORY_ADS
using AppAdvisory.Ads;
#endif
#if VS_SHARE
using AppAdvisory.SharingSystem;
#endif

namespace AppAdvisory.AA
{
	/// <summary>
	/// Class in charge of the game logic.
	/// </summary>
	public class GameManager : MonobehaviourHelper
	{
		/// <summary>
		/// Event triggered when player successfully cleared a level
		/// </summary>
		public delegate void SuccessStart();
		public static event SuccessStart OnSuccessStart;

		/// <summary>
		/// Event triggered when player successfully cleared a level and the animation success is completed
		/// </summary>
		public delegate void SuccessComplete();
		public static event SuccessComplete OnSuccessComplete;

		/// <summary>
		/// Event triggered when player failed to clear a level
		/// </summary>
		public delegate void FailStart();
		public static event FailStart OnFailStart;

		/// <summary>
		/// Event triggered when player failed to clear a level and the animation success is completed
		/// </summary>
		public delegate void FailComplete();
		public static event FailComplete OnFailComplete;

		/// <summary>
		/// Text displayed in the main circle in the center of the screen
		/// </summary>
		public Text textNumLevel;


		int _level;
		/// <summary>
		/// Reference to the current level played, and modify the textNumLevel
		/// </summary>
		public int Level
		{
			get
			{
				return _level;
			}
			set
			{
				_level = value;

				if (textNumLevel == null)
					textNumLevel = CircleTransform.GetComponentInChildren<Text>();

				textNumLevel.text = value.ToString();
			}
		}


		public int _heart;
		public int Heart
        {
            get
            {
				return _heart;
            }
            set
            {
				_heart = value;
				heartText.text = value.ToString();
			}
        }
		public TMPro.TMP_Text heartText;

		/// <summary>
		/// true if player can shoot a dot, false if not
		/// </summary>
		public bool playerCanShoot;
		/// <summary>
		/// true if player sucessfully cleared a level
		/// </summary>
		public bool isSuccess;
		/// <summary>
		/// true if level is completed (success or not)
		/// </summary>
		public bool isGameOver;

		float sizeDot = 0;

		/// <summary>
		/// reference to the center circle of the game
		/// </summary>
		public Transform CircleTransform;
		/// <summary>
		/// reference to the parent transform of all dots linked to the center circle
		/// </summary>
		public Transform CircleBorder;

		/// <summary>
		/// list of all the dots the player have to shoot in the level
		/// </summary>
		List<DotManager> Dots;


		private float positionTouchBorder
		{
			get
			{
				var height = 2f * Camera.main.orthographicSize;
				var width = height * Camera.main.aspect;
				return Mathf.Min(width, height) * 1f / 4f * 0.5f * LEVEL.lineRadius;
			}
		}


		public GameObject DotPrefab;

		CurrentPlayerData playerData;


		/// <summary>
		/// Spawn the dot prefab from the ObjectPooling. 
		/// </summary>
		public GameObject SpawnDotPrefab()
		{
			var o = ObjectPoolingManager.Instance.GetObject(DotPrefab.name);
			o.transform.parent = CircleTransform;
			return o;
		}

		public AaSettings aaSettings;



		/// <summary>
		/// Spawn the dot prefabs from the ObjectPooling. 
		/// </summary>
		void PreparePoolDots()
		{

			ObjectPoolingManager.Instance.CreatePool(this.DotPrefab, 20, 30);

			var allDots = ObjectPoolingManager.Instance.GetObjects(DotPrefab.name);

			foreach (var d in allDots)
			{

				d.SetActive(true);
				d.transform.rotation = Quaternion.identity;
				d.GetComponent<DotManager>().SetScale();
				d.GetComponent<DotManager>().ActivateLine();

				d.transform.parent = transform;


				d.transform.position = new Vector3(0, Screen.height * 2, 0);


				d.SetActive(false);

			}
		}

		/// <summary>
		/// Disable all spawned object 
		/// </summary>
		public void DespawnAll()
		{
			var allDots = ObjectPoolingManager.Instance.GetObjects(DotPrefab.name);

			foreach (var d in allDots)
			{
				if (d.activeInHierarchy)
				{
					d.transform.rotation = Quaternion.identity;
					d.GetComponent<DotManager>().SetScale();
					d.GetComponent<DotManager>().DesactivateLine();

					d.transform.parent = CircleTransform;
					d.SetActive(false);
				}
			}

		}

		/// <summary>
		/// Do it at first. Some configurations.
		/// </summary>
		void Awake()
		{
			playerData = FindObjectOfType<CurrentPlayerData>();

			if (Time.realtimeSinceStartup < 20)
			{
				DOTween.Init();
			}

			CircleTransform = GameObject.Find("Circle").transform.Find("SpriteCircleCenter");
			CircleBorder = GameObject.Find("Circle").transform.Find("Border");
			//		PlayerPrefs.DeleteKey ("LEVEL");
			if (!PlayerPrefs.HasKey("LEVEL"))
			{
				PlayerPrefs.SetInt("LEVEL", 1);
			}


			if (PlayerPrefs.GetInt("LEVEL", 0) <= 0)
			{
				PlayerPrefs.SetInt("LEVEL", 1);
			}

			if (!PlayerPrefs.HasKey("LEVEL_PLAYED"))
			{
				PlayerPrefs.SetInt("LEVEL_PLAYED", 1);
			}

			if (PlayerPrefs.GetInt("LEVEL_PLAYED", 0) <= 0)
			{
				PlayerPrefs.SetInt("LEVEL_PLAYED", 1);
			}

			isGameOver = true;

			Heart = 3;

			Dots = new List<DotManager>();

			//Camera.main.transform.position = new Vector3 (0, 2f, -10);

			PreparePoolDots();
		}

		void Start()
		{
			CircleTransform.GetComponentInChildren<SpriteRenderer>().color = constant.DotColor;
		}

		/// <summary>
		/// Add all listeners 
		/// </summary>
		void OnEnable()
		{
			InputTouch.OnTouchScreen += OnTouch;
			CanvasManager.OnCreateGame += CreateGame;
		}

		/// <summary>
		/// Remove all listeners 
		/// </summary>
		void OnDisable()
		{
			InputTouch.OnTouchScreen -= OnTouch;
			CanvasManager.OnCreateGame -= CreateGame;
		}

        private void Update()
        {
			if (!aaSettings.GetGameMode(playerData.GetChatVariableValue("mod")) && Heart>0)
			{
				Destroy(transform.parent.gameObject);
				FindObjectOfType<ChatManager>().ClickVirtualButton(aaSettings.cikisModu);
				Heart = 0;
			}
        }


        /// <summary>
        /// Player has shown rewarded video, unlock this level
        /// </summary>
        void OnReawardedVideoSuccess(bool success)
		{
			if (success)
			{
				AnimationCameraSuccess();
			}
			else
			{
				print("the user dismiss the video...");
			}
		}


		/// <summary>
		/// Function called by InputTouch delegate. Do the shoot of the dot.
		/// </summary>
		void OnTouch(Vector2 touchPos)
		{
			/*
			if (introMenu == null || introMenu.gameObject.activeInHierarchy)
				return;*/

			if ((Input.mousePosition.y < Screen.height * 0.6f) && (Input.mousePosition.x < Screen.width * 0.9f))
			{
				if (!isGameOver && playerCanShoot)
				{
					if (Dots == null)
					{
						return;
					}

					if (Dots.Count > 0)
					{
						ShootDot(Dots[0]);
					}
				}
			}
		}

		/// <summary>
		/// Keep a reference of the Dotween sequence use to rotate the circle and the dots linked to the circle
		/// </summary>
		Sequence sequence;

		/// <summary>
		/// Rotate the circle and the dots linked to it
		/// </summary>
		void LaunchRotateCircle()
		{
			if (sequence != null)
				sequence.Kill(false);

			sequence = DOTween.Sequence();

			if (constant.AnimLineAtEachTurn)
			{
				var listToAnim = CircleBorder.gameObject.GetComponentsInChildren<DotManager>();

				sequence.Append(DOVirtual.Float(Constant.LINE_WIDHT, Constant.LINE_WIDHT * 3, 0.2f, (float v) =>
				{

					foreach (var d in listToAnim)
					{
						d.SetLineScale(v);
					}

				}).SetLoops(6, LoopType.Yoyo));
			}
			if (LEVEL.rotateLoopType == LoopType.Incremental)
			{
				sequence.Append(CircleBorder.DORotate(LEVEL.rotateVector * UnityEngine.Random.Range(360, 500), LEVEL.rotateDelay, RotateMode.FastBeyond360)
					.SetEase(LEVEL.rotateEase));
				sequence.SetLoops(1, LEVEL.rotateLoopType);
			}
			else
			{
				sequence.Append(CircleBorder.DORotate(LEVEL.rotateVector * UnityEngine.Random.Range(360, 500), LEVEL.rotateDelay, RotateMode.FastBeyond360)
					.SetEase(LEVEL.rotateEase));
				sequence.SetLoops(2, LEVEL.rotateLoopType);
			}

			sequence.OnStepComplete(LaunchRotateCircle);

			sequence.Play();
		}

		/// <summary>
		///  Keep a reference of the LEVEL use to generate the level
		/// </summary>
		Level LEVEL;


		/// <summary>
		/// Method to create the level
		/// </summary>
		public void CreateGame(int level)
		{
			playerCanShoot = false;
			isGameOver = true;

			Time.timeScale = 1;

			GC.Collect();

			this.Level = level;


			//StopAllCoroutines();

			Camera.main.backgroundColor = constant.BackgroundColor;

			DespawnAll();

			Dots = new List<DotManager>();

			this.LEVEL = levelManager.GetLevel(Level);

			CircleBorder.localScale = new Vector3(1, 1, 1);

			CreateDotOnCircle();

			CreateListDots();

			PositioningDotsToShoot();

			LaunchRotateCircle();

			isSuccess = false;
			isGameOver = false;

			if (Heart > 0)
				playerCanShoot = true;

#if VS_SHARE
			VSSHARE.DOOpenScreenshotButton();
#endif
		}


		/// <summary>
		/// Create the dots on the circle and activate the line to link the dots to the circle
		/// </summary>
		void CreateDotOnCircle()
		{
			for (int i = 0; i < LEVEL.numberDotsOnCircle; i++)
			{
				CircleBorder.rotation = Quaternion.Euler(new Vector3(0, 0, ((float)i) * 360f / LEVEL.numberDotsOnCircle));

				Transform t = SpawnDotPrefab().transform;

				t.position = new Vector3(0, -positionTouchBorder, 0);
				t.parent = CircleBorder;
				t.rotation = Quaternion.identity;

				t.gameObject.SetActive(true);

				DotManager dm = t.GetComponent<DotManager>();
				t.GetComponent<Collider2D>().enabled = true;
				dm.ActivateLine();

				dm.ActivateNum(false);
			}
		}

		/// <summary>
		/// Create the dots on the circle and activate the line to link the dots to the circle
		/// </summary>
		void CreateListDots()
		{

			for (int i = 0; i < LEVEL.numberDotsToCreate; i++)
			{

				DotManager dm = SpawnDotPrefab().GetComponent<DotManager>();

				dm.SetNum(i + 1);

				dm.ActivateNum(true);

				dm.GetComponent<Collider2D>().enabled = false;

				dm.transform.parent = CircleTransform;

				if (sizeDot == 0)
				{
					sizeDot = dm.DotSprite.bounds.size.x * 1.1f;
				}

				Dots.Add(dm);
			}
		}


		/// <summary>
		/// Method to shoot the first dot and moving the other. This method check if the list of dots to shoot is empty or not. If the list is empty, this method triggered the success for this level.
		/// </summary>
		void ShootDot(DotManager d)
		{
			playerCanShoot = false;

			StopCoroutine("PositioningDots");

			StopCoroutine("MoveStartPositionDot");

			d.GetComponent<Collider2D>().enabled = true;

			soundManager.PlaySoundBeep();

			int totalShoot = (LEVEL.numberDotsToCreate - Dots.Count) + 1;

			float chance = UnityEngine.Random.Range(0f, 100f);

			if (chance > 70)
			{
				if (totalShoot > 0 && totalShoot < aaSettings.basariModuSayisi)
				{
					FindObjectOfType<ChatManager>().ClickVirtualButton(aaSettings.basariModu + " " + totalShoot.ToString());
				}
				else
				{
					FindObjectOfType<ChatManager>().ClickVirtualButton(aaSettings.basariModuMax);
				}
			}

			Dots.Remove(d);

			PositioningDotsToShoot();

			d.GetComponent<Collider2D>().enabled = true;

			d.transform.position = new Vector3(0, -positionTouchBorder + (-0 - 2) * sizeDot, 0);

			d.transform.DOKill();

			d.transform.DOMoveY(-positionTouchBorder, 0.1f).SetEase(Ease.Linear)
				.OnUpdate(() =>
				{
					playerCanShoot = false;
					if (isGameOver)
						DOTween.Kill(d.transform);
				})
				.OnComplete(() =>
				{
					d.ActivateLine();

					d.transform.parent = CircleBorder;

					if (Heart > 0)
						playerCanShoot = true;

					if (Dots.Count == 0 && !isGameOver)
						isSuccess = true;

					if (isSuccess && !isGameOver)
					{
						AnimationCameraSuccess();
					}

					PositioningDotsToShoot();

				});
		}

		private IEnumerator CloseGameWithMode(string mod)
		{
			playerCanShoot = false;
			yield return new WaitForSeconds(soundManager.failFX.length - .3f);
			FindObjectOfType<ChatManager>().ClickVirtualButton(mod);
			Destroy(transform.parent.gameObject);
		}

		/// <summary>
		/// Move the list of the dots to shoot when a dot is shooted.
		/// </summary>
		void PositioningDotsToShoot()
		{
			for (int i = 0; i < Dots.Count; i++)
			{
				if (Dots.Count > 0)
				{
					Dots[i].transform.DOKill();

					Dots[i].SetScale();
					Dots[i].transform.DOMove(new Vector3(0, -positionTouchBorder - 2 + (-i - 2) * sizeDot), 0.2f);
					Dots[i].GetComponent<Collider2D>().enabled = false;
				}
			}
		}

		/// <summary>
		/// Clean memory if the game is pausing
		/// </summary>
		public void OnApplicationPause(bool pause)
		{
			if (!pause)
			{
				GC.Collect();
				Resources.UnloadUnusedAssets();
				Time.timeScale = 1.0f;
				Application.targetFrameRate = 60;
			}
			else
			{
				GC.Collect();
				Resources.UnloadUnusedAssets();
				Time.timeScale = 0.0f;
			}
		}

		/// <summary>
		/// Save the PlayerPrefs when the game is quiting
		/// </summary>
		void OnApplicationQuit()
		{
			Resources.UnloadUnusedAssets();

			PlayerPrefs.Save();
		}

		/// <summary>
		/// Animation when the player lose
		/// </summary>
		public void AnimationCameraGameOver()
		{
			if (isGameOver)
				return;

			//DOTween.KillAll();

			soundManager.PlaySoundFail();
			isGameOver = true;
			isGameOver = true;

			//StopAllCoroutines();


			playerCanShoot = false;

			if (OnFailStart != null)
				OnFailStart();

			Color colorFrom = constant.BackgroundColor;
			Color colorTo = constant.FailColor;

			float delay = 0.3f;


			Camera.main.backgroundColor = colorFrom;

			Camera.main.DOColor(colorTo, delay).OnComplete(() =>
			{
				Heart--;

				if (Heart <= 0)
				{
					StartCoroutine(CloseGameWithMode(aaSettings.oyunSonuModu));
                }
                else
                {
					FindObjectOfType<ChatManager>().ClickVirtualButton(aaSettings.basarisizlikModu);
				}

				DOVirtual.DelayedCall(delay, () =>
				{
					if (OnFailComplete != null)
						OnFailComplete();
				});
				Camera.main.DOColor(colorFrom, delay).SetDelay(delay).OnComplete(() =>
				{

					Camera.main.DOColor(colorFrom, delay).SetDelay(delay / 2).OnComplete(() =>
					{
					});

				});


			});
		}

		/// <summary>
		/// Animation when the player cleared the level
		/// </summary>
		public void AnimationCameraSuccess()
		{
			if (isGameOver)
				return;

			PlayerPrefs.SetInt("LEVEL", PlayerPrefs.GetInt("LEVEL", 1) + 1);

			playerCanShoot = false;
			soundManager.PlaySoundSuccess();
			isGameOver = true;


			if (OnSuccessStart != null)
				OnSuccessStart();

			Color colorFrom = constant.BackgroundColor;
			Color colorTo = constant.SuccessColor;


			float delay = 0.10f;

			Camera.main.backgroundColor = colorFrom;
			Camera.main.DOColor(colorTo, delay);

			CircleBorder.DOScale(Vector3.one * 1.4f, delay * 4).OnComplete(() =>
			{
				CircleBorder.DOScale(Vector3.one, delay * 4).OnComplete(() =>
				{
					Camera.main.DOColor(colorFrom, delay);
				});

				if (OnSuccessComplete != null)
					OnSuccessComplete();
			});
		}
	}
}