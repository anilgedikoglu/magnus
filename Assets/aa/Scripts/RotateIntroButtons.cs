
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
	public class RotateIntroButtons : MonoBehaviour 
	{
		void OnEnable()
		{
			StartCoroutine (DoRotate());
		}

		void OnDisable()
		{
			//StopAllCoroutines ();
		}


		IEnumerator DoRotate()
		{
			yield return new WaitForSeconds (0.1f);
			transform.DORotate (Vector3.back * 360f, 10, RotateMode.FastBeyond360).SetEase (Ease.Linear).SetLoops (-1, LoopType.Incremental);
		}
	}
}