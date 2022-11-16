using UnityEngine;

[CreateAssetMenu(fileName = "ThemesCollection", menuName = "Themes Collection")]
public class ThemesCollection : ScriptableObject
{
    public ThemePreset[] themes;
}
