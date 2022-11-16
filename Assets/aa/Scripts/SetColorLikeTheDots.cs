
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
	public class SetColorLikeTheDots : MonobehaviourHelper 
	{
		Image image;

		Text text;


		void Start()
		{
			image = GetComponent<Image> ();

			text = GetComponent<Text> ();

			ChangeColor();
		}

		void ChangeColor()
		{
			if (image != null) 
			{
				image.color = constant.DotColor;
			}

			if (text != null) 
			{
				text.color = constant.DotColor;
			}
		}

		#if UNITY_EDITOR
		void OnDrawGizmos() 
		{
			if (Application.isPlaying)
				return;

			if (image == null && text == null) 
			{
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