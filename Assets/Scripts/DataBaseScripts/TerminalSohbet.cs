using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "TerminalSohbeti", menuName = "Veri Tabani/Terminal Sohbeti Olustur")]
public class TerminalSohbet : ScriptableObject
{
    public string etiket;

    [TextArea(5, 20)]
    public string[] aciklama;

    public string aranacakEtiket;

    public ChatDegiskeni[] gerekenDegiskenler;

    [Space(30)]
    public int popUpIndex;

     public int popUpIntMin, popUpIntMax;

     public bool maxValueIsYear, maxMinDegerBelirle;

    public TouchScreenKeyboardType klavyeTipi;

    public bool isaretKoy = true;

    public bool typeWritingAnimation = true;

    public bool ucNokta;

    public float metinGecikmeCarpani = 1;

    public string ozelKontrol;
    public string ayarlanacakDegisken;
}
