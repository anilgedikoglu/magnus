
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using DG.Tweening;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace AppAdvisory.AA
{
	/// <summary>
	/// Class who make the level. Click right on the LevelManager in the editor and select "execute" to generate 1200 levels.
	/// </summary>
	public class LevelManager : MonobehaviourHelper
	{
		public List<Level> levels;

		void Awake(){
			int level = PlayerPrefs.GetInt ("LEVEL_PLAYED");
			if (level > 1200) {
				PlayerPrefs.SetInt ("LEVEL_PLAYED", 1200);
			}
		}

		#if UNITY_EDITOR
		[ContextMenu("Execute")]
		public virtual void CreateLevels ()
		{
			Debug.Log("execute");


			levels = new List<Level> ();

			for (int i = 1; i <= 1200; i++) 
			{
				Level l = new Level (i);
				if (i % 2 == 0) {
					l.rotateRight = true;
				} else {
					l.rotateRight = false;
				}
				levels.Add (l);
			}
		}
		#endif

		public Level GetLevel(int level)
		{
			return levels [level - 1];

		}
	}


	/// <summary>
	/// Level class with all the informations for to create the level in the GameManager
	/// </summary>
	[Serializable]
	public class Level
	{

		public int levelNumber = 0;
		public int numberDotsToCreate = 0;
		public int numberDotsOnCircle = 0;

		/// <summary>
		/// Radius of the line who link the dots to the circle
		/// </summary>
		[Range(0.7f,1f)] public float lineRadius = 1f;

		/// <summary>
		/// Delay of one rotation
		/// </summary>
		public float rotateDelay = 8f;

		/// <summary>
		/// Define the direction of the rotation
		/// </summary>
		public bool rotateRight;

		/// <summary>
		/// Define the direction of the rotation
		/// </summary>
		[HideInInspector] 
		public Vector3 rotateVector
		{
			get
			{ 
				if (rotateRight)
					return new Vector3 (0, 0, 1);
				else
					return new Vector3 (0, 0, -1);
			}
		}


		/// <summary>
		/// Ease type of the rotation
		/// </summary>
		public Ease rotateEase = Ease.InCirc;
		/// <summary>
		/// Loop type of the rotation
		/// </summary>
		public LoopType rotateLoopType = LoopType.Incremental;

		public override string ToString()
		{
			return "levelNumber = " + levelNumber + " - numberDotsToCreate = " + numberDotsToCreate + " - numberDotsOnCircle = " + numberDotsOnCircle + " - lineRadius = " + lineRadius + " - rotateDelay = " + rotateDelay
				+ " - rotateVector = " + rotateVector + " - rotateEase " + rotateEase.ToString () + " - rotateLoopType = " + rotateLoopType.ToString ();
			return "levelNumber = " + levelNumber + " - numberDotsToCreate = " + numberDotsToCreate + " - numberDotsOnCircle = " + numberDotsOnCircle + " - lineRadius = " + lineRadius + " - rotateDelay = " + rotateDelay
				+ " - rotateVector = " + rotateVector + " - rotateEase " + " - rotateLoopType = ";
		}

		/// <summary>
		/// Don't create more than 1200 levels
		/// </summary>
		static int maxLevel = 1200;


		/// <summary>
		/// Level constructor
		/// </summary>
		public Level (int level){


			levelNumber = level;


			if (level == 1) {
				numberDotsToCreate = 3;
				numberDotsOnCircle = 0;

			} else if (level == 2) {
				numberDotsToCreate = 4;
				numberDotsOnCircle = 2;

			} else if (level == 3) {
				numberDotsToCreate = 5;
				numberDotsOnCircle = 4;

			} else if (level == 4) {
				numberDotsToCreate = 6;
				numberDotsOnCircle = 5;

			} else {


				numberDotsToCreate = 
					(int)(
						(6 + level % 10)
					);

				numberDotsOnCircle = 
					(int)(
						(15 -  numberDotsToCreate)
					);

			}

			if (level > 5) {
				lineRadius = 1f - (level % 5f) / 10f;
			}




			if (level > 10) {

				if (level % 3 < 1) {
					lineRadius = 1f - (level % 5 + 1) / 10f;
				}

			}



			if (level > 20 && level < 30) {

				if (level % 2 == 1) {
					rotateDelay = 8f - (level % 3);
				} else {
					rotateDelay = 8f + (level % 3);
				}

			} else {

				if (level % 2 == 1) {
					rotateDelay = 10f - (level % 3);
				} else {
					rotateDelay = 10f + (level % 3);
				}
			}
			int variable = 0;

			if (level <= maxLevel/2) {

				rotateLoopType = LoopType.Incremental;

				variable = 0;
			} else {

				rotateLoopType = LoopType.Yoyo;
				variable = maxLevel/2;
			}

			if (level < 30 + variable) {
				//			Debug.Log ("level = " + level + " Ease.linear");
				rotateEase = Ease.Linear;
			}else if (level < 50 + variable) {
				//			Debug.Log ("level = " + level + " Ease.spring");
				rotateEase = Ease.Linear;
			} else if (level < 70 + variable) {
				rotateEase = Ease.InQuad;
			} else if (level < 90 + variable) {
				rotateEase = Ease.OutCirc;
			} else if (level < 110 + variable) {
				rotateEase = Ease.InOutQuart;
			} else if (level < 130 + variable) {
				rotateEase = Ease.InQuint;
			} else if (level < 150 + variable) {
				rotateEase = Ease.OutSine;
			} else if (level < 170 + variable) {
				rotateEase = Ease.InOutExpo;
			} else if (level < 190 + variable) {
				rotateEase = Ease.InCirc;
			} else if (level < 210 + variable) {
				rotateEase = Ease.OutBounce;
			} else if (level < 230 + variable) {
				rotateEase = Ease.InOutQuint;
			} else if (level < 250 + variable) {
				rotateEase = Ease.InExpo;
			} else if (level < 270 + variable) {
				rotateEase = Ease.OutQuart;
			} else if (level < 290 + variable) {
				rotateEase = Ease.InOutQuad;
			} else if (level < 310 + variable) {
				rotateEase = Ease.InSine;
			} else if (level < 330 + variable) {
				rotateEase = Ease.OutExpo;
			} else if (level < 350 + variable) {
				rotateEase = Ease.InOutCubic;
			} else if (level < 370 + variable) {
				rotateEase = Ease.InBounce;
			} else if (level < 390 + variable) {
				rotateEase = Ease.OutQuint;
			} else if (level < 410 + variable) {
				rotateEase = Ease.InOutSine;
			} else if (level < 430 + variable) {
				rotateEase = Ease.InQuart;
			} else if (level < 450 + variable) {
				rotateEase = Ease.OutQuad;
			} else if (level < 470 + variable) {
				rotateEase = Ease.InOutCirc;
			} else if (level < 490 + variable) {
				rotateEase = Ease.InCubic;
			} else if (level < 510 + variable) {
				rotateEase = Ease.OutCubic;
			} else if (level < 530 + variable) {
				rotateEase = Ease.InOutBounce;
			}

			int numOfEnum = (System.Enum.GetValues (typeof(Ease)).Length);


			int enumNumber = level % numOfEnum;
			rotateEase = (Ease)(enumNumber);

			while(rotateEase.ToString ().Contains ("Elastic") || rotateEase.ToString ().Contains ("INTERNAL_Zero") || rotateEase.ToString ().Contains ("INTERNAL_Custom"))
			{
				enumNumber++;
				if (enumNumber >= numOfEnum)
					enumNumber = 0;

				rotateEase = (Ease)(enumNumber);
			}

			if (level > maxLevel) {
				PlayerPrefs.SetInt (Constant.LEVEL_UNLOCKED, 1200);

				level = 1200;
				PlayerPrefs.SetInt (Constant.LAST_LEVEL_PLAYED, 1200);

				Application.OpenURL ("http://barouch.fr/moregames.php");

			}

		}


	}
}
