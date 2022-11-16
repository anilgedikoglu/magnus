
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/


using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using System;
using System.Collections;

#if AADOTWEEN
using DG.Tweening;
#endif

namespace AppAdvisory.UI
{
	/// <summary>
	/// Class attached to the UIController GameObject (who is a Canvas).
	/// In Charge of all the logics of the UI: animation, events...
	/// </summary>
	public class UIController : MonoBehaviour 
	{
		static private UIController self;

		public Text scoreIngame;

		static public void SetScore(int score)
		{
			Text uiScore = self.scoreIngame;

			uiScore.text = score.ToString();
			#if AADOTWEEN
			uiScore.rectTransform.DOKill();
			#endif

			uiScore.transform.localScale = Vector3.one;

			if(score == 0)
				return;

			#if AADOTWEEN
			uiScore.rectTransform.DOScale(Vector2.one * 1.5f, 0.3f).SetEase(Ease.InBack).SetLoops(2, LoopType.Yoyo);
			#endif
		}

		static public void SetUIBestScore(int point)
		{
			self.SetBestText(point);
		}

		static public void SetUILastScore(int point)
		{
			self.SetLastText(point);
		}

		void SetInGameScoreOut()
		{
			#if AADOTWEEN
			scoreIngame.DOKill();
			#endif
			RectTransform r = scoreIngame.GetComponent<RectTransform>();

			var p = r.localPosition;

			p.y = Screen.height * 2;
			r.localPosition = p;
		}

		public void DOAnimInScoreInGame()
		{
			#if AADOTWEEN
			scoreIngame.DOKill();
			#endif

			SetInGameScoreOut();

			RectTransform r = scoreIngame.GetComponent<RectTransform>();
			#if AADOTWEEN
			r.DOLocalMoveY(0, 0.5f).SetDelay(0.5f);
			#endif
		}

		#region UI elements
		#region ToDesactivate
		public LayoutGroup[] layoutGroupToDesactivateAtStart;
		public ContentSizeFitter[] contentSizeFitterToDesactivateAtStart;
		public LayoutElement[] layoutElementToDesactivate;
		void DesactivateUIFitter()
		{
			if(layoutGroupToDesactivateAtStart != null && layoutGroupToDesactivateAtStart.Length > 0)
			{
				foreach(var v in layoutGroupToDesactivateAtStart)
				{
					v.enabled = false;
				}
			}

			if(contentSizeFitterToDesactivateAtStart != null && contentSizeFitterToDesactivateAtStart.Length > 0)
			{
				foreach(var v in contentSizeFitterToDesactivateAtStart)
				{
					v.enabled = false;
				}
			}

			if(layoutElementToDesactivate != null && layoutElementToDesactivate.Length > 0)
			{
				foreach(var v in layoutElementToDesactivate)
				{
					v.enabled = false;
				}
			}
		}
		#endregion
		/// <summary>
		/// Reference to all UI elements we will animate from the top of the screen.
		/// </summary>
		public RectTransform[] toAnimateFromTop;
		/// <summary>
		/// Reference to all UI elements we will animate horizontally.
		/// </summary>
		public RectTransform[] toAnimateHorizontaly;
		/// <summary>
		/// Reference to UI Text for the last score.
		/// </summary>
		public Text textLast;
		/// <summary>
		/// Reference to UI Text for the best score.
		/// </summary>
		public Text textBest;
		/// <summary>
		/// Set the last score.
		/// </summary>
		public void SetLastText(int point)
		{
			textBest.text  = "Best\n " + point;
		}
		/// <summary>
		/// Set the best score.
		/// </summary>
		public void SetBestText(int point)
		{
			textBest.text  = "Best\n " + point;
		}
		#endregion

		#region Unity Events
		#region Animation IN
		/// <summary>
		/// Unity event triggered when the animation IN, ie. from "out of the screen" to "in the screen" is started.
		/// </summary>
		[System.Serializable] public class OnUIAnimInStartHandler : UnityEvent{}
		/// <summary>
		/// Unity event triggered when the animation IN, ie. from "out of the screen" to "in the screen" is started.
		/// </summary>
		[SerializeField] public OnUIAnimInStartHandler OnUIAnimInStart;

		/// <summary>
		/// Unity event triggered when the animation IN, ie. from "out of the screen" to "in the screen" is ended.
		/// </summary>
		[System.Serializable] public class OnUIAnimInEndHandler : UnityEvent{}
		/// <summary>
		/// Unity event triggered when the animation IN, ie. from "out of the screen" to "in the screen" is ended.
		/// </summary>
		[SerializeField] public OnUIAnimInEndHandler OnUIAnimInEnd;
		#endregion

		#region Animation OUT
		/// <summary>
		/// Unity event triggered when the animation OUT, ie. from "in the the screen" to "out of screen" is started.
		/// </summary>
		[System.Serializable] public class OnUIAnimOUTStartHandler : UnityEvent{}
		/// <summary>
		/// Unity event triggered when the animation OUT, ie. from "in the the screen" to "out of screen" is started.
		/// </summary>
		[SerializeField] public OnUIAnimOUTStartHandler OnUIAnimOutStart;

		/// <summary>
		/// Unity event triggered when the animation OUT, ie. from "in the the screen" to "out of screen" is ended.
		/// </summary>
		[System.Serializable] public class OnUIAnimOUTEndHandler : UnityEvent{}
		/// <summary>
		/// Unity event triggered when the animation OUT, ie. from "in the the screen" to "out of screen" is ended.
		/// </summary>
		[SerializeField] public OnUIAnimOUTEndHandler OnUIAnimOutEnd;
		#endregion
		#endregion

		#region Methods

		void Awake()
		{
			DesactivateUIFitter();
			self = this;
			SetInGameScoreOut();
		}

		#region Animation IN
		/// <summary>
		/// Method called to do the animation IN, ie. from "out of the screen" to "in the screen".
		/// We will anim from top and horizontally.
		/// </summary>
		public void DOAnimIN () 
		{
			DesactivateUIFitter();

			OnUIAnimInStart.Invoke();

			bool animFromTopFinished = false;
			bool animHorizontallyFinished = false;
			AnimateINFromTop(() => {
				animFromTopFinished = true;

				if(animFromTopFinished && animHorizontallyFinished)
				{
					animFromTopFinished = false;
					animHorizontallyFinished = false;
					OnUIAnimInEnd.Invoke();
				}
			});
			AnimateINHorizontaly(() => {
				animHorizontallyFinished = true;

				if(animFromTopFinished && animHorizontallyFinished)
				{
					animFromTopFinished = false;
					animHorizontallyFinished = false;
					OnUIAnimInEnd.Invoke();
				}
			});
		}
		/// <summary>
		/// Do the animation IN, ie. from "out of the screen" to "in the screen", from top.
		/// </summary>
		void AnimateINFromTop(Action callback)
		{
			DesactivateUIFitter();

			int countCompleted = 0;

			if(toAnimateFromTop != null && toAnimateFromTop.Length != 0)
			{
				for(int i = 0; i < toAnimateFromTop.Length; i++)
				{
					var r = toAnimateFromTop[i];

					var p = r.localPosition;

					p.y = Screen.height * 2;
					r.localPosition = p;

					#if AADOTWEEN
					r.DOLocalMoveY(0, 0.5f).SetDelay(0.5f + i * 0.1f)
						.OnComplete(() => {
							countCompleted++;
							if(countCompleted >= toAnimateFromTop.Length)
							{
								if(callback!=null)
									callback();
							}
						});
					#endif
				}
			}
		}
		/// <summary>
		/// Do the animation IN, ie. from "out of the screen" to "in the screen", horizontally.
		/// </summary>
		void AnimateINHorizontaly(Action callback)
		{
			int countCompleted = 0;

			if(toAnimateHorizontaly != null && toAnimateHorizontaly.Length != 0)
			{
				for(int i = 0; i < toAnimateHorizontaly.Length; i++)
				{
					var r = toAnimateHorizontaly[i];

					if(i%2==0)
					{
						r.localPosition = new Vector2(-Screen.width * 2f, r.localPosition.y);
					}
					else
					{
						r.localPosition = new Vector2(+Screen.width * 2f, r.localPosition.y);
					}

					#if AADOTWEEN
					r.DOLocalMoveX(0, 0.5f).SetDelay(0.5f + i * 0.1f)
						.OnComplete(() => {
							countCompleted++;
							if(countCompleted >= toAnimateHorizontaly.Length)
							{
								if(callback!=null)
									callback();
							}
						});
					#endif
				}
			}
		}
		#endregion


		#region Animation OUT
		/// <summary>
		/// Method called to do the animation OUT, ie. from "in the the screen" to "out of the screen".
		/// We will anim from top and horizontally.
		/// </summary>
		public void DOAnimOUT () 
		{
			DOAnimInScoreInGame();

			OnUIAnimOutStart.Invoke();

			bool animFromTopFinished = false;
			bool animHorizontallyFinished = false;
			AnimateOUTFromTop(() => {
				animFromTopFinished = true;

				if(animFromTopFinished && animHorizontallyFinished)
				{
					animFromTopFinished = false;
					animHorizontallyFinished = false;
					OnUIAnimOutEnd.Invoke();
				}
			});
			AnimateOUTHorizontaly(() => {
				animHorizontallyFinished = true;

				if(animFromTopFinished && animHorizontallyFinished)
				{
					animFromTopFinished = false;
					animHorizontallyFinished = false;
					OnUIAnimOutEnd.Invoke();
				}
			});
		}
		/// <summary>
		/// Do the animation OUT, ie. from "in the screen" to "out of the screen", from top.
		/// </summary>
		void AnimateOUTFromTop(Action callback)
		{
			int countCompleted = 0;

			if(toAnimateFromTop != null && toAnimateFromTop.Length != 0)
			{
				for(int i = 0; i < toAnimateFromTop.Length; i++)
				{
					var r = toAnimateFromTop[i];
					#if AADOTWEEN
					r.DOLocalMoveY(Screen.height * 2f, 0.5f).SetDelay(0.1f + i * 0.03f)
						.OnComplete(() => {
							countCompleted++;
							if(countCompleted >= toAnimateFromTop.Length)
							{
								if(callback!=null)
									callback();
							}
						});
					#endif
				}
			}
		}
		/// <summary>
		/// Do the animation OUT, ie. from "in the screen" to "out of the screen", horizontaly.
		/// </summary>
		void AnimateOUTHorizontaly(Action callback)
		{
			int countCompleted = 0;

			if(toAnimateHorizontaly != null && toAnimateHorizontaly.Length != 0)
			{
				for(int i = 0; i < toAnimateHorizontaly.Length; i++)
				{
					var r = toAnimateHorizontaly[i];

					int sign = 1;

					if(i%2==0)
					{
						sign = -1;
					}

					#if AADOTWEEN
					r.DOLocalMoveX(sign * Screen.width * 2f, 0.5f).SetDelay(0.1f + i * 0.03f)
						.OnComplete(() => {
							countCompleted++;
							if(countCompleted >= toAnimateHorizontaly.Length)
							{
								if(callback!=null)
									callback();
							}
						});
					#endif
				}
			}
		}
		#endregion
		#endregion
	}
}

