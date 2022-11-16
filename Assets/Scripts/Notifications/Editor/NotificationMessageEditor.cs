using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(NotificationMessage))]
public class NotificationMessageEditor : Editor
{
    NotificationMessage notificationMessage;

    private SerializedProperty title, subtitle, body, tip, yil, ay, gun, saat, gonderilecegiZaman, platform, gerekliDegiskenler;

    private void OnEnable()
    {
        notificationMessage = (NotificationMessage)target;

        title = serializedObject.FindProperty("title");
        subtitle = serializedObject.FindProperty("subtitle");
        body = serializedObject.FindProperty("Body");
        tip = serializedObject.FindProperty("tip");
        yil = serializedObject.FindProperty("yil");
        ay = serializedObject.FindProperty("ay");
        gun = serializedObject.FindProperty("gun");
        saat = serializedObject.FindProperty("saat");
        gonderilecegiZaman = serializedObject.FindProperty("gonderilecegiZaman");
        platform = serializedObject.FindProperty("platform");
        gerekliDegiskenler = serializedObject.FindProperty("gerekliDegiskenler");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        if (GUILayout.Button("Kopyala", GUILayout.Width(80)))
        {
            var clone = Instantiate(notificationMessage);

            ProjectWindowUtil.CreateAsset(clone, notificationMessage.name + ".asset");
        }

        EditorGUILayout.PropertyField(title);
        EditorGUILayout.PropertyField(subtitle);
        EditorGUILayout.PropertyField(body);

        EditorGUILayout.PropertyField(tip);

        if (notificationMessage.tip == NotificationMessage.NotificationType.belirliTarih)
        {
            EditorGUILayout.PropertyField(yil);
            EditorGUILayout.PropertyField(ay);
            EditorGUILayout.PropertyField(gun);
        }
        else if (notificationMessage.tip == NotificationMessage.NotificationType.sayac)
        {
            EditorGUILayout.PropertyField(saat);
        }
        else if (notificationMessage.tip == NotificationMessage.NotificationType.yillikTekrar)
        {
            EditorGUILayout.PropertyField(ay);
            EditorGUILayout.PropertyField(gun);
        }
        else if (notificationMessage.tip == NotificationMessage.NotificationType.haftalik)
        {
            EditorGUILayout.IntSlider(gun, 1, 7);
        }

        EditorGUILayout.PropertyField(gonderilecegiZaman);

        EditorGUILayout.PropertyField(platform);

        EditorGUILayout.PropertyField(gerekliDegiskenler);

        serializedObject.ApplyModifiedProperties();
    }
}
