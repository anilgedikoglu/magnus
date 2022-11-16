
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
	/// <summary>
	/// A class to avoid some duplicate code.
	/// </summary>
	public class MonobehaviourHelper : MonoBehaviour 
	{


		LevelManager _levelManager;
		/// <summary>
		/// Reference to the LevelManager GameObject
		/// </summary>
		public LevelManager levelManager
		{
			get
			{
				if (_levelManager == null)
					_levelManager = FindObjectOfType<LevelManager> ();

				return _levelManager;
			}
		}


		Constant _constant;
		/// <summary>
		/// Reference to the Constant GameObject
		/// </summary>
		public Constant constant
		{
			get
			{
				if (_constant == null)
					_constant = FindObjectOfType<Constant> ();

				return _constant;
			}
		}


		IntroMenu _introMenu;
		/// <summary>
		/// Reference to the IntroMenu GameObject
		/// </summary>
		public IntroMenu introMenu
		{
			get
			{
				if (_introMenu == null)
					_introMenu = FindObjectOfType<IntroMenu> ();

				return _introMenu;
			}
		}

		SoundManager _soundManager;
		/// <summary>
		/// Reference to the IntroMenu GameObject
		/// </summary>
		public SoundManager soundManager
		{
			get
			{
				if (_soundManager == null)
					_soundManager = FindObjectOfType<SoundManager> ();

				return _soundManager;
			}
		}

	}
}