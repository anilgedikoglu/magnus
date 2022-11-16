/***************************************************************************************
 * THIS SCRIPT WILL PUT A EMPTY AREA ON TOP TO HANDLE THE NOTCH OF IOS DEVICE.
 ***************************************************************************************/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// This script will leave create a empty top area in iPhone with notch.
// This is done to make sure app's top area don't get hidden behind the notch of device.
//Only works on iOS. if not required, you can comment this code.

[RequireComponent(typeof(Camera))]
public class iPhoneNotchSupport : MonoBehaviour 
{
	#if UNITY_IOS
	void Start() {
		CheckForNotchCutout();
	}

	void CheckForNotchCutout() {
		if (Screen.orientation == ScreenOrientation.Portrait || Screen.orientation == ScreenOrientation.PortraitUpsideDown)
		{
			float screenAspect = ((float) Screen.height) / ((float) Screen.width);
			if(screenAspect >= 2.0F) {
				Camera cam = GetComponent<Camera>();
				cam.rect = new Rect(0,-0.04F,1,1);
			}
			
		}
	}
	#endif
}
