
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using System.Collections;
using UnityEngine.UI;


namespace AppAdvisory.AA
{
	public class UpdateColorEqualCamColor : MonobehaviourHelper 
	{

		Image image;

		Text text;

		Camera cam;

		void Start()
		{
			cam = Camera.main;

			image = GetComponent<Image> ();

			text = GetComponent<Text> ();
		}


		void OnEnable()
		{
			StartCoroutine (CoUpdate ());
		}

		void OnDisable()
		{
			//StopAllCoroutines ();
		}

		IEnumerator CoUpdate () 
		{
			while (true) {

				ChangeColor ();

				yield return 0;
			}
		}

		void ChangeColor()
		{
			if (image != null) {
				image.color = cam.backgroundColor;
			}

			if (text != null) {
				text.color = cam.backgroundColor;
			}
		}

		#if UNITY_EDITOR
		void OnDrawGizmos() 
		{
			if (Application.isPlaying)
				return;

			if (cam == null && image == null && text == null) 
			{
				if (cam == null)
					cam = Camera.main;

				if (image == null)
					image = GetComponent<Image> ();

				if (text == null)
					text = GetComponent<Text> ();
			}

			ChangeColor();
		}
		#endif
	}
}