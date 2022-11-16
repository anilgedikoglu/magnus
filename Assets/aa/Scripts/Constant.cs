
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using System.Collections;
using System;

namespace AppAdvisory.AA
{
	/// <summary>
	/// Class where is define some constants use in the game
	/// </summary>
	public class Constant : MonobehaviourHelper
	{
		/// <summary>
		/// Each time the tweener complete a sequence, we anim - or not - the line who link the dot to the center. If you don't want this animation, turn this boolean to false
		/// </summary>
		public bool AnimLineAtEachTurn = true;

		/// <summary>
		/// Size fo the line who link each dots to the center circle
		/// </summary>
		public const int LINE_WIDHT = 4;

		public const string LAST_LEVEL_PLAYED = "LEVEL_PLAYED";
		public const string LEVEL_UNLOCKED = "LEVEL";
		public const string SOUND_ON = "SOUND_ON";

		/// <summary>
		/// Background color when the player lose
		/// </summary>
		public Color FailColor;

		/// <summary>
		/// Background color when the player win
		/// </summary>
		public Color SuccessColor;

		/// <summary>
		/// Default background color
		/// </summary>
		public Color BackgroundColor;

		/// <summary>
		/// Dot color
		/// </summary>
		public Color DotColor;
	}
}