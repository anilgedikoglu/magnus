using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(TerminalSohbet)), CanEditMultipleObjects]
public class TerminalSohbetEditor : Editor
{
    TerminalSohbet terminalSohbet;

    private void OnEnable()
    {
        terminalSohbet = (TerminalSohbet)target;
    }


    public override void OnInspectorGUI()
    {
        if (GUILayout.Button("Sohbeti kopyala", GUILayout.Width(120)))
        {
            CreateCopyOfSohbet(0);
        }
        base.OnInspectorGUI();
    }

    void CreateCopyOfSohbet(int index)
    {
        var clone = Instantiate(terminalSohbet);

        ProjectWindowUtil.CreateAsset(clone, terminalSohbet.name + ".asset");
    }
}
