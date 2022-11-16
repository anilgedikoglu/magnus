using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor.Build.Reporting;
using UnityEditor;
using UnityEditor.Build;
class MyCustomBuildProcessor : IPreprocessBuildWithReport
{
    public int callbackOrder { get { return 0; } }
    public void OnPreprocessBuild(BuildReport report)
    {
        if (GameObject.FindObjectOfType<CurrentPlayerData>() != null)
        {
            GameObject.FindObjectOfType<CurrentPlayerData>().ResetVariables();
            Debug.Log("Tüm kayıtlar <color=#4F9A3D><b>BUILD</b></color> öncesi <color=green><b>sıfırlandı</b></color>.");
        }
    }
}
#endif
