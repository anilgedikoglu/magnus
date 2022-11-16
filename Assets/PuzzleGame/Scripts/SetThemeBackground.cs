using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SetThemeBackground : MonoBehaviour
{
    Image image;

    void Start()
    {
        image = GetComponent<Image>();
        
        UpdateColor(ThemeController.Instance.CurrentTheme);
        ThemeController.Instance.ThemeChanged += UpdateColor;
    }
    
    void OnDestroy()
    {
        ThemeController.Instance.ThemeChanged -= UpdateColor;
    }
    
    void UpdateColor(ThemePreset theme)
    {
        image.sprite = theme.backgroundSprite;
        image.color = theme.backgroundColor;
    }
}
