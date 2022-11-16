
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using UnityEngine.UI;
using System;
using System.Collections;
using DG.Tweening;

namespace AppAdvisory.AA
{
	/// <summary>
	/// Class in charge to display the intro menu
	/// </summary>
	public class IntroMenu : MonobehaviourHelper
	{
		/// <summary>
		/// Time for the fade duration use in the transition between intro and game
		/// </summary>
		public float fadeDuration = 0.2f;

		/// <summary>
		/// Time for the  the panel who move horizontally when transitioning between intro and game
		/// </summary>
		public float hidderAnimDuration = 0.5f;

		RectTransform panelHidder;

		RectTransform container;

		CanvasGroup canvasGroup;

		void Awake()
		{
			GetComponent<Canvas> ().overrideSorting = true;
			GetComponent<Canvas> ().pixelPerfect = false;
			GetComponent<Canvas> ().sortingOrder = 100;

			canvasGroup = GetComponent<CanvasGroup> ();

			panelHidder = transform.Find ("PanelHidder").GetComponent<RectTransform>();

			container = transform.Find ("Container").GetComponent<RectTransform>();

		}

		void Start()
		{
			canvasGroup.alpha = 1;

			panelHidder.localPosition = new Vector2(0,0);

			container.gameObject.SetActive(false);

			this.DoFade(canvasGroup, 0, 1, fadeDuration, () => {

				container.gameObject.SetActive(true);
				panelHidder.DOLocalMoveX (panelHidder.rect.size.x, hidderAnimDuration).SetUpdate (false).SetEase(Ease.Linear).OnComplete (() => {

					panelHidder.localPosition = new Vector2(panelHidder.rect.size.x,0);

				});
			});
		}

		public void AnimationIntroToGame(Action callback)
		{
			canvasGroup.alpha = 1;

			container.gameObject.SetActive(true);

			panelHidder.localPosition = new Vector2(panelHidder.rect.size.x,0);

			panelHidder.DOLocalMoveX (0, hidderAnimDuration).SetUpdate (false).SetEase(Ease.Linear).OnComplete (() => {

				container.gameObject.SetActive(false);

				this.DoFade(canvasGroup, 1, 0, fadeDuration, () => {

					if(callback != null)
						callback();
				});
			});
		}

		public void AnimationGameToIntro(Action callback)
		{
			canvasGroup.alpha = 0;

			panelHidder.localPosition = new Vector2(0,0);

			container.gameObject.SetActive(false);

			//		canvasGroup.DOFade (1, fadeDuration).SetUpdate (false).OnComplete (() => {

			this.DoFade(canvasGroup, 0, 1, fadeDuration, () => {

				container.gameObject.SetActive(true);
				panelHidder.DOLocalMoveX (panelHidder.rect.size.x, hidderAnimDuration).SetUpdate (false).SetEase(Ease.Linear).OnComplete (() => {

					panelHidder.localPosition = new Vector2(panelHidder.rect.size.x,0);

					if(callback != null)
						callback();
				});
			});
		}


		public void DoFade(CanvasGroup c, float from, float to, float time, Action callback)
		{
			StartCoroutine (DoLerpAlpha (c, from, to, time, callback));
		}


		public IEnumerator DoLerpAlpha(CanvasGroup c, float from, float to, float time, Action callback)
		{
			float timer = 0;

			c.alpha = from;

			while (timer <= time)
			{
				timer += Time.deltaTime;
				c.alpha = Mathf.Lerp(from, to, timer / time);
				yield return null;
			}

			c.alpha = to;

			if (callback != null)
				callback ();
		}
	}
}