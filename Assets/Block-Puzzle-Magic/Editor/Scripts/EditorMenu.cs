using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System;

public class EditorMenu 
{
	[MenuItem("Hyperbyte/Plugin Setup/Check Setup", false,1)]
	private static void SetUp()
	{
		DependencyChecker.OpenWelcomeWindow();
	}

	[MenuItem("Hyperbyte/Plugin Setup/Setup IAP Catalog", false,2)]
	private static void SetUpIAPCatalog()
	{
		string sourcePath = Application.dataPath +"/Block-Puzzle-Magic/UnityIAPCatalog/IAPProductCatalog.json";
		string destPath = Application.dataPath +"/Plugins/UnityPurchasing/Resources/IAPProductCatalog.json";
		
		if(File.Exists(sourcePath))
		{
			if(!File.Exists(destPath))
			{		
				File.Copy(sourcePath, destPath);
				AssetDatabase.Refresh();
			}
			else
			{
				Debug.LogWarning("IAP Catalog already exists.");
			}
		}
	}

    #region Hyperbyte Documentation
    [MenuItem("Hyperbyte/Documentation/General", false, 1)]
	public static void OpenGeneralDocument() {
		Application.OpenURL("http://hyperbytestudios.com/Documents/BPM/BlockPuzzleMagic-ReadMe.pdf");
	}

	[MenuItem("Hyperbyte/Documentation/SetUp Ad Network", false, 1)]
	public static void OpenAdSetupDocumentation() {
		Application.OpenURL("http://hyperbytestudios.com/Documents/BPM/AdNetworkSetup-ReadMe.pdf");
	}
	#endregion

	#region Unity Monetization SDK 3.0 Setup
	[MenuItem("Hyperbyte/Support-Modules/Ad-Network/Unity Monetization/Download SDK", false, 2)]
	private static void DownloadUnityMonetizationSDK() {
		Application.OpenURL("https://assetstore.unity.com/packages/add-ons/services/unity-monetization-3-0-66123");
	}

	 [MenuItem("Hyperbyte/Support-Modules/Ad-Network/Unity Monetization/Setup", false, 2)]
	 private static void SetupUnityMonetizationSupportModule() {
	 	SetupUnityMonetizationSDK();
	 }

	[MenuItem("Hyperbyte/Support-Modules/Ad-Network/Unity Monetization/Official Document", false, 2)]
	private static void OpenUnityMonetizationOfficialDocument() {
		Application.OpenURL("https://unityads.unity3d.com/help/unity/integration-guide-unity");
	}

	public static void SetupUnityMonetizationSDK() {
		if(Directory.Exists ("Assets/UnityAds")) {
			ImportUnityMonetizationSupportPackage();
		} else {
			EditorUtility.DisplayDialog("Alert!", "Seems like Unity Monetization SDK is not imported yet, Please Download and Import SDK first. " + 
			"\n\nIf you want a hasslefree ready package with full setup done, please let us know via support email."
			, "OK");
		}
	}

	public static void ImportUnityMonetizationSupportPackage() {
		AssetDatabase.ImportPackage(Application.dataPath + "/Block-Puzzle-Magic/Support-Classes/Monetization/AdSupport-UNITY-UM-3.0.unitypackage",true);
	}
	#endregion

	#region Unity Google AdMob Setup
	[MenuItem("Hyperbyte/Support-Modules/Ad-Network/Google AdMob/Download SDK", false, 2)]
	private static void DownloadGoogleAdMobSDK() {
		Application.OpenURL("https://developers.google.com/admob/unity/start");
	}

	 [MenuItem("Hyperbyte/Support-Modules/Ad-Network/Google AdMob/Setup", false, 2)]
	 private static void SetupGoogleAdMobSupportModule() {
	 	SetupGoogleAdMobSupportSDK();
	 }

	[MenuItem("Hyperbyte/Support-Modules/Ad-Network/Google AdMob/Official Document", false, 2)]
	private static void OpenAdMobOfficialDocument() {
		Application.OpenURL("https://developers.google.com/admob/unity/start");
	}

	[MenuItem("Hyperbyte/Support-Modules/Ad-Network/Google AdMob/Mediation Integration Guide", false, 2)]
	private static void OpenMediationIntegrationGuide() {
		Application.OpenURL("https://developers.google.com/admob/unity/mediation");
	}

	public static void SetupGoogleAdMobSupportSDK() {
		if(Directory.Exists ("Assets/GoogleMobileAds")) {
			ImportGoogleAdMobSupportPackage();
		} else {
			EditorUtility.DisplayDialog("Alert!", "Seems like Google AdMob SDK is not imported yet, Please Download and Import SDK first. " + 
			"\n\nIf you want a hasslefree ready package with full setup done, please let us know via support email."
			, "OK");
		}
	}

	public static void ImportGoogleAdMobSupportPackage() {
		AssetDatabase.ImportPackage(Application.dataPath + "/Block-Puzzle-Magic/Support-Classes/Monetization/AdSupport-AdMob-v3.15.1.unitypackage",true);
	}
	#endregion

	#region  Delete Preferences
	[MenuItem("Hyperbyte/Delete Preferences", false, 4)]
	public static void DeleteAllPreferences() {
		PlayerPrefs.DeleteAll();
		EditorPrefs.DeleteKey("WelcomeScreenShown");
	}
	#endregion

	#region CaptureScreenshot
	[MenuItem("Hyperbyte/Capture Screenshot/1X")]
	private static void Capture1XScreenshot() {
		CaptureScreenshot(1);
	}

	[MenuItem("Hyperbyte/Capture Screenshot/2X")]
	private static void Capture2XScreenshot() {
		CaptureScreenshot(2);
	}

	[MenuItem("Hyperbyte/Capture Screenshot/3X")]
	private static void Capture3XScreenshot() {
		CaptureScreenshot(3);
	}

	public static void CaptureScreenshot(int supersize) {
		string imgName = "IMG-"+ DateTime.Now.Year.ToString() + DateTime.Now.Month.ToString("00") + DateTime.Now.Day.ToString("00") + "-" + DateTime.Now.Hour.ToString("00") + DateTime.Now.Minute.ToString("00") + DateTime.Now.Second.ToString("00") +".png";
		ScreenCapture.CaptureScreenshot ((Application.dataPath + "/" + imgName),supersize);
		AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
	}
	#endregion
	
}

[InitializeOnLoad]
public class AutorunNew
{
	static AutorunNew()
	{
		EditorApplication.update += RunOnce;
		AssetDatabase.importPackageCompleted += importPackageStartedCallback;	
	}

	static void RunOnce() 
	{
		EditorApplication.update -= RunOnce;
		if(!EditorPrefs.HasKey("WelcomeScreenShown")) {
			//WelcomeScreen.OpenWelcomeWindow();
		}
	}

	public static void importPackageStartedCallback(string str) {
		if(str.Contains("GoogleMobileAds")) {
			ShowGoogleAdMobSupportImportAlert();
		} else if(str.Contains("Unity Monetization")) {
			ShowUnityAdSupportImportAlert();
		//} else if(str == "UnityIAP") {
			//ShowUnityIAPSupportImportAlert();
		} else if(str.Contains("AdSupport")) {
			Application.OpenURL("http://hyperbytestudios.com/Documents/BPM/AdNetworkSetup-ReadMe.pdf");
		// } else if(str.Contains("UnityIAPManager")) {
		// 	Application.OpenURL(Application.dataPath + "/Block-Puzzle-Magic/Documentation/UnityIAPSetup-ReadMe.pdf");
		}
	}

	public static void ShowGoogleAdMobSupportImportAlert() {
		bool result = EditorUtility.DisplayDialog("Google AdMob SDK Setup!",
		"Seems like you just imported Google AdMob SDK, Please import Google AdMob Support Script to complete setup.", 
		"OK!, Let's do it",
		"I'll do Later!");

		if(result == true) {
			EditorMenu.SetupGoogleAdMobSupportSDK();
		}
	}

	public static void ShowUnityAdSupportImportAlert() {
		bool result = EditorUtility.DisplayDialog("Unity Monetization SDK Setup!",
		"Seems like you just imported Unity Monetization SDK, Please import Unity Monetization Support Script to complete setup.", 
		"OK!, Let's do it",
		"I'll do Later!");

		if(result == true) {
			EditorMenu.SetupUnityMonetizationSDK();
		}
	}
}
