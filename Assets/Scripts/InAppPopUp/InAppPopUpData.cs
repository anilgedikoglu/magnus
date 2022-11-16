using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName ="PopUpData", menuName ="MagnusSettings/UI/PopUpData")]
public class InAppPopUpData : ScriptableObject
{
    public Type typeLog;
    public Type typeLogWarning;
    public Type typeLogError;
    public Type typeLogSuccess;

    [System.Serializable]
    public class Type
    {
        public Sprite sprite;
        public Color color;
        public Color backgroundColor;
    }
}
