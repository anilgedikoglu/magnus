
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using System.Collections;

namespace AppAdvisory.AA
{
	public class SetCameraColor : MonobehaviourHelper 
	{
		void Start()
		{
			GetComponent<Camera>().backgroundColor = constant.BackgroundColor;
		}

		#if UNITY_EDITOR
		void OnDrawGizmos() 
		{
			if (Application.isPlaying)
				return;

			GetComponent<Camera>().backgroundColor = constant.BackgroundColor;
		}
		#endif
	}
}