using UnityEditor;
using UnityEngine;

[CustomPropertyDrawer(typeof(Label))]
public class ThemePresetLabelPropertyDrawer : PropertyDrawer
{
    const float padding = 2;
    int fieldіAmount = 1;
    
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        Rect pos = new Rect(position);
        pos = EditorGUI.PrefixLabel(pos, GUIContent.none);
        EditorGUI.indentLevel = 0;
        
        EditorGUI.PropertyField(pos, property.FindPropertyRelative("labelType"), true);
        
        if (property.FindPropertyRelative("labelType").enumValueIndex == 1)
        {
            EditorGUI.indentLevel = 1;

            fieldіAmount = 2;
            Rect propPos = new Rect(pos);
            propPos.y += EditorGUIUtility.singleLineHeight + padding;
            EditorGUI.PropertyField(propPos, property.FindPropertyRelative("collection"), true);
        }
        else
            fieldіAmount = 1;
    }

    public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
    {
        return fieldіAmount * EditorGUIUtility.singleLineHeight + padding;
    }
}
