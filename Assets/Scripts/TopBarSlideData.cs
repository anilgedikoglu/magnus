using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName ="KayanYaziData", menuName ="Veri Tabani/KayanYaziData")]
public class TopBarSlideData : ScriptableObject
{
    [TextArea(2, 5)]
    public string[] texts;
}
