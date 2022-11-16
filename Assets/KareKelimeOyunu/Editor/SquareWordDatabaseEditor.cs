using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(SquareWordDatabase))]
public class SquareWordDatabaseEditor : Editor
{
    private SquareWordDatabase squareWordDatabase;

    private SquareWordDatabase.Word currentWord;

    private bool isSettingsActive;

    private Vector2 scrollPos;

    private void OnEnable()
    {
        squareWordDatabase = (SquareWordDatabase)target;

        scrollPos = Vector2.zero;
    }

    public override void OnInspectorGUI()
    {
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

        for(int i = 0; i<squareWordDatabase.words.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Paket No:" + i.ToString()))
            {
                currentWord = squareWordDatabase.words[i];
                EditorGUI.FocusTextInControl(null);
            }
            if (GUILayout.Button("Sohbet Olustur", GUILayout.Width(90)))
            {
                CreateSohbet(i);
            }
            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.Space(5, true);
        if (GUILayout.Button("-", GUILayout.Width(80)))
        {
            squareWordDatabase.words.RemoveAt(squareWordDatabase.words.Count - 1);
        }
        if (GUILayout.Button("+", GUILayout.Width(80)))
        {
            squareWordDatabase.words.Add(new());
            EditorGUI.FocusTextInControl(null);
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(10);

        DrawGamePatternMenu();

        GUILayout.Space(10);
        if (GUILayout.Button("Dogru harf paketi ekle"))
        {
            currentWord.correctIndexs.Add(new());
            EditorGUI.FocusTextInControl(null);
        }

        GUILayout.Space(20);
        
        isSettingsActive = EditorGUILayout.BeginFoldoutHeaderGroup(isSettingsActive, "Ayarlar");

        if (isSettingsActive)
        {
            squareWordDatabase.kareKelimeOyunuModu = EditorGUILayout.TextField("mod", squareWordDatabase.kareKelimeOyunuModu);

            EditorGUILayout.Space(10);
            EditorStyles.textArea.wordWrap = true;
            EditorGUILayout.LabelField("Paket sohbeti açıklama");
            squareWordDatabase.defaultSohbetAciklama = EditorGUILayout.TextArea(squareWordDatabase.defaultSohbetAciklama, EditorStyles.textArea, GUILayout.Height(50));

            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("Doğru cevap sohbeti açıklama");
            squareWordDatabase.defaultDogruSohbetAciklama = EditorGUILayout.TextArea(squareWordDatabase.defaultDogruSohbetAciklama, EditorStyles.textArea, GUILayout.Height(50));
        }

        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.EndScrollView();

        EditorUtility.SetDirty(squareWordDatabase);
    }

    private void DrawGamePatternMenu()
    {
        if (currentWord == null)
            return;

        int firsSize = currentWord.Size;
        currentWord.Size = EditorGUILayout.IntField("Boyut", currentWord.Size);
        if (currentWord.Size <= 0)
            currentWord.Size = 5;

        if (currentWord.Size != firsSize)
        {
            currentWord.letters = new SquareWordDatabase.Letter[currentWord.Size * currentWord.Size];
        }

        for (int i = 0; i < currentWord.Size; i++)
        {
            EditorGUILayout.BeginHorizontal();
            for (int u = 0; u < currentWord.Size; u++)
            {
                EditorGUILayout.BeginVertical();

                if (currentWord.letters.Length <= i * currentWord.Size + u)
                    return;

                SquareWordDatabase.Letter letter = currentWord.letters[i * currentWord.Size + u];
                if (letter == null)
                    letter = new();

                letter.text = EditorGUILayout.TextField(letter.text.ToString(), GUILayout.Width(40), GUILayout.Height(40))[0];

                EditorGUILayout.LabelField((i * currentWord.Size + u).ToString(), GUILayout.Width(40), GUILayout.Height(15));

                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(10);
        }

        int deletedIndex = -1;
        for (int i = 0; i < currentWord.correctIndexs.Count; i++)
        {
            if (currentWord.correctIndexs[i].indexs == null)
                currentWord.correctIndexs[i].indexs = new();

            for (int u = 0; u < currentWord.correctIndexs[i].indexs.Count; u++)
            {
                currentWord.correctIndexs[i].indexs[u] = EditorGUILayout.IntField(currentWord.correctIndexs[i].indexs[u]);
            }

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(5, true);
            if (GUILayout.Button("-", GUILayout.Width(80)))
            {
                deletedIndex = i;
            }
            if (GUILayout.Button("+", GUILayout.Width(80)))
            {
                currentWord.correctIndexs[i].indexs.Add(0);
            }
            EditorGUILayout.EndHorizontal();

            GUILayout.Space(5);
        }

        if (deletedIndex >= 0)
            currentWord.correctIndexs.RemoveAt(deletedIndex);
    }
    
    private void CreateSohbet(int index)
    {
        var clone = CreateInstance<Sohbet>();
        clone.aciklama = new List<string>();
        clone.aciklama.Add(squareWordDatabase.defaultSohbetAciklama);
        clone.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();
        clone.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken("mod", "kare kelime"));

        clone.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>();
        clone.ayarlananDegiskenler.Add(new Sohbet.AyarlanacakDegisken("kare kelime paket no", index.ToString()));
        clone.sayac = 60;
        clone.sayacModu = "kare kelime sure doldu";
        clone.sayacTipi = Sohbet.sayacTipiEnum.barVeEkrandaText;

        clone.cevaplar = new List<CevapSohbet>();
        clone.cevaplar.Add(new CevapSohbet());
        clone.cevaplar[0].cevapVaryasyonlari = new List<string>
        {
            "İptal"
        };
        clone.cevaplar[0].ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>
        {
            new Sohbet.AyarlanacakDegisken("mod", "kare kelime iptal")
        };
        clone.anaMenuyeGitButonuOlustur = false;


        var cloneDogru = CreateInstance<Sohbet>();
        cloneDogru.aciklama = new List<string>();
        cloneDogru.aciklama.Add(squareWordDatabase.defaultDogruSohbetAciklama);
        cloneDogru.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>();
        cloneDogru.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken("mod", "kare kelime dogru"));
        cloneDogru.gerekliDegiskenler.Add(new Sohbet.GerekenDegisken("kare kelime paket no", index.ToString()));
        cloneDogru.ayarlananDegiskenler = new List<Sohbet.AyarlanacakDegisken>
        {
            new Sohbet.AyarlanacakDegisken("mod", "kare kelime")
        };

        ProjectWindowUtil.CreateAsset(clone, $"Paket {index}.asset");
        ProjectWindowUtil.CreateAsset(cloneDogru, $"Paket {index} Dogru.asset");
    }
}
