
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
	public class DesactivateSound : MonoBehaviour {

		AudioSource aSource;

		void Awake()
		{
			aSource = GetComponent<AudioSource> ();
		}

		void OnEnable()
		{
			aSource.Play ();

			StartCoroutine (DesatcivateWhenFinishPlaying ());
		}


		void OnDisable()
		{
			//StopAllCoroutines ();
		}

		IEnumerator DesatcivateWhenFinishPlaying()
		{
			yield return 0;

			while (aSource.isPlaying) 
			{
				yield return 0;
			}

			gameObject.SetActive (false);
		}

	}
}