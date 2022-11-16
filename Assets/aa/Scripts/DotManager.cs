
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using System.Collections;
using DG.Tweening;

namespace AppAdvisory.AA
{
	public class DotManager : MonobehaviourHelper 
	{
		GameManager _gameManager;
		GameManager gameManager
		{
			get
			{
				if(_gameManager == null)
					_gameManager = FindObjectOfType<GameManager>();

				return _gameManager;
			}
		}

		public bool isTrigger = true;

		public GameObject line;
		Vector3 defaultLineScale = new Vector3 (500, Constant.LINE_WIDHT, 1);

		public SpriteRenderer DotSprite;

		public UnityEngine.UI.Text textNum;

		void Start()
		{
			Reset ();
		}

		void OnEnable()
		{

			Reset ();
		}

		void Reset()
		{
			if (line != null) 
			{
				line.SetActive (false);
				var lineSpriteRenderer = line.GetComponent<SpriteRenderer> ();
				if (lineSpriteRenderer != null) 
				{
					lineSpriteRenderer.color = constant.DotColor;
				}
			}

			DotSprite.color = constant.DotColor;


			GetComponent<Collider2D>().enabled = false;

			GetComponent<Collider2D> ().isTrigger = isTrigger;

			//StopAllCoroutines ();

			if (GetComponent<Rigidbody2D>() == null) {
				gameObject.AddComponent<Rigidbody2D> ();
			}

			SetScale();

			line.transform.localScale = defaultLineScale;

			DesactivateLine ();


		}

		public void SetLineScale(float width)
		{
			line.transform.localScale = new Vector3 (defaultLineScale.x, width, 1);
		}

		public void SetScale()
		{
			float ratio = 1f;

			if(transform.parent != null)
				ratio = transform.parent.localScale.x;

			transform.localScale = Vector3.one / ratio;
		}

		public void ActivateNum(bool activate)
		{
			textNum.gameObject.SetActive (activate);
		}

		public void SetNum(int num)
		{
			textNum.text = num.ToString ();
		}

		public void ActivateLine()
		{

			SetScale();

			GetComponent<Collider2D>().enabled = true;

			line.SetActive (true);
			DOVirtual.DelayedCall (0.01f,() => {
				GetComponent<Collider2D>().enabled = true;
				line.SetActive (true);
			});
		}

		public void DesactivateLine()
		{


			line.SetActive (false);
		}

		void OnCollisionEnter2D(Collision2D col)
		{
			GameOverLogic (col.gameObject);
		}

		void OnCollisionStay2D(Collision2D col)
		{
			GameOverLogic (col.gameObject);
		}

		void OnTriggerEnter2D(Collider2D col)
		{
			GameOverLogic (col.gameObject);
		}

		void OnTriggerStay2D(Collider2D col) 
		{
			GameOverLogic (col.gameObject);
		}

		void GameOverLogic(GameObject col)
		{
			if( !gameManager.isGameOver &&  col.name.Contains("Dot"))
			{
				GetComponent<Collider2D> ().enabled = false;

				col.GetComponent<Collider2D> ().enabled = false;

				gameManager.AnimationCameraGameOver ();
			}

		}

	}
}