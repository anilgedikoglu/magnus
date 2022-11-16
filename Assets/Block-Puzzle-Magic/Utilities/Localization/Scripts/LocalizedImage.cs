using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent (typeof(Image))]
public class LocalizedImage : MonoBehaviour
{
	public string txtTag;
	Image thisImage;

	void Awake ()
	{
		thisImage = GetComponent<Image> ();
	}

	void OnEnable ()
	{
		LocalizationManager.OnLanguageChangedEvent += OnLanguageChangedEvent;
		Invoke ("SetLocalizedImage", 0.01F);
	}

	void OnDisable ()
	{
		LocalizationManager.OnLanguageChangedEvent -= OnLanguageChangedEvent;
	}

	public void SetLocalizedImage ()
	{
		if (!string.IsNullOrEmpty (txtTag.Trim ())) {
			thisImage.SetLocalizedImageForTag (txtTag);
		}
		
	}

	void OnLanguageChangedEvent (string langCode)
	{
		SetLocalizedImage ();
	}
}