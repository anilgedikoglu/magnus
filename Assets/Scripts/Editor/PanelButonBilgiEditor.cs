using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(PanelButonBilgi))]
public class PanelButonBilgiEditor : Editor
{
    PanelButonBilgi panelButonBilgi;
    ChatVariables chatVariables;

    string denenenText;
    string aranacakText;
    string arananText;
    bool canCapital;

    GUIStyle h1, h2, h3, h4, descreption;

    List<Sohbet> bulunanSohbetler; 

    private void OnEnable()
    {
        panelButonBilgi = (PanelButonBilgi)target;
        chatVariables = FindObjectOfType<ChatVariables>();

        bulunanSohbetler = new List<Sohbet>();
        arananText = string.Empty;
        canCapital = false;
    }

    public override void OnInspectorGUI()
    {
        h1 = new GUIStyle("label");
        h1.fontSize = 27;
        h1.fontStyle = FontStyle.Bold;
        h1.wordWrap = true;

        h2 = new GUIStyle("label");
        h2.fontSize = 23;
        h2.fontStyle = FontStyle.Bold;
        h2.wordWrap = true;

        h3 = new GUIStyle("label");
        h3.fontSize = 18;
        h3.fontStyle = FontStyle.Bold;
        h3.wordWrap = true;

        h4 = new GUIStyle("label");
        h4.fontSize = 15;
        h4.fontStyle = FontStyle.Bold;
        h4.wordWrap = true;

        descreption = new GUIStyle("label");
        descreption.fontSize = 12;
        descreption.fontStyle = FontStyle.Italic;
        descreption.wordWrap = true;

        GUILayout.Label("Magnus Editor Fonksiyonları", h1);
        GUILayout.Space(20);

        GUILayout.Label("Buton Dene", h3);
        GUILayout.Space(5);

        if (EditorApplication.isPlaying)
        {
            panelButonBilgi.denenecekText = GUILayout.TextArea(panelButonBilgi.denenecekText, GUILayout.Height(300));
            GUILayout.Label(denenenText, descreption);

            if (GUILayout.Button("Değiştir"))
            {
                denenenText = chatVariables.OrtakButonlar(panelButonBilgi.denenecekText);
            }
        }
        else
        {
            EditorGUILayout.HelpBox("Butonları deneyebilmek için uygulamayı başlatmalısınız!", MessageType.Error);
            if (GUILayout.Button("Uygulamayı Başlat"))
            {
                EditorApplication.EnterPlaymode();
            }
        }

        GUILayout.Space(20);
        GUILayout.Label("Databasede Kelime Grubu Ara", h3);

        aranacakText = EditorGUILayout.TextField(aranacakText);
        canCapital = EditorGUILayout.Toggle("Büyük harfe duyarlı",canCapital);

        if (GUILayout.Button("Ara"))
        {
            arananText = canCapital ? aranacakText: aranacakText.ToLower();
            
            bulunanSohbetler = new List<Sohbet>();

            Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("");

            foreach(Sohbet sohbet in tumSohbetler)
            {
                foreach(string aciklama in sohbet.aciklama)
                {
                    string alinanAciklama = canCapital ? aciklama: aciklama.ToLower();
                    if (alinanAciklama.Contains(arananText))
                    {
                        bulunanSohbetler.Add(sohbet);
                        break;
                    }
                }
            }
        }

        if(bulunanSohbetler.Count > 0)
        {
            GUILayout.Label("\"" + arananText + "\" barındıran " + bulunanSohbetler.Count + " tane sohbet bulundu.", h4);
        }
        else if (!string.IsNullOrEmpty(arananText))
        {
            GUILayout.Label("\"" + arananText + "\" barındıran sohbet bulunamadı.", h4);
        }

        foreach(Sohbet sohbet in bulunanSohbetler)
        {
            EditorGUILayout.ObjectField(sohbet, typeof(Sohbet), false);
        }
    }
}
