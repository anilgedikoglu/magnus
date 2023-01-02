using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class DegiskeneGoreSohbetOlusturucuWindow : EditorWindow
{
    DegiskeneGoreSohbetOlusturucuData targetObject;

    int totalKombinasyon = 0;

    List<List<Sohbet.GerekenDegisken>> variableLists, emptyList;

    Vector2 scrollPos, scrollPossBeforeEdit;

    int secinlenDataIndex = -1;

    [MenuItem("Magnus/Olusturucular/Değişkene Göre Sohbet Oluşturucu")]
    public static void ShowWindow()
    {
        DegiskeneGoreSohbetOlusturucuWindow window = (DegiskeneGoreSohbetOlusturucuWindow)EditorWindow.GetWindow(typeof(DegiskeneGoreSohbetOlusturucuWindow));
    }

    private void OnEnable()
    {
         targetObject = Resources.Load<DegiskeneGoreSohbetOlusturucuData>($"{ModSohbetManagerData.localDatabaseName}/DegiskeneGoreSohbetOlusturucuData");
    }

    private void OnDisable()
    {
        EditorUtility.SetDirty(targetObject);
    }

    private void OnGUI()
    {
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
        /*
        List<List<int>> denemeComb = WriteeCombinationsOfList(new List<int> {5 ,7}, new List<List<int>> { new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 }, new List<int> { 0, 0, 0 } }, 0, 1);
        List<List<int>> denemeComb2 = WriteeCombinationsOfList(new List<int> { 3, 2, 1 }, denemeComb, 1, 2);
        List<List<int>> denemeComb3 = WriteeCombinationsOfList(new List<int> {11, 13 }, denemeComb2, 2, 6);
        Debug.Log("<color=green>basla</color>");
        foreach (List<int> degiskenDegerleri in denemeComb3)
        {
            foreach (int degiskenDegerleri2 in degiskenDegerleri)
            {
                Debug.Log(degiskenDegerleri2);
            }
        }*/



        SerializedObject serializedObject = new SerializedObject(targetObject);
        if (targetObject.menuState == 0)
        {
            EditorGUILayout.Space(20);
            EditorGUILayout.HelpBox("Değişkenlerde yapılan değişiklikler yazılan sohbeteri sıfırlar. Bu nedenle değişkenler ilk belirlenmenin ardından kapatılmalıdır.", MessageType.Error);

            EditorGUILayout.BeginHorizontal();
            foreach (DegiskeneGoreSohbetOlusturucuData.Degisken onTanimliDegiksen in targetObject.onTanimliDegiskenler)
            {
                if (GUILayout.Button(onTanimliDegiksen.degiskenAdi, GUILayout.Height(20)))
                {
                    targetObject.degiskenler.Add(onTanimliDegiksen.Clone());
                    EditorUtility.SetDirty(targetObject);

                }
            }
            EditorGUILayout.EndHorizontal();
            
            int removeIndexDegisken = -1;
            bool kategoriEkle = false;
            for (int u = 0; u < targetObject.degiskenler.Count; u++)
            {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField(targetObject.degiskenler[u].degiskenAdi, GUILayout.Width(100), GUILayout.ExpandWidth(false));
                if (GUILayout.Button("-", GUILayout.Width(20)))
                {
                    removeIndexDegisken = u;
                    EditorGUI.FocusTextInControl(null);
                }
                EditorGUILayout.EndHorizontal();

                targetObject.degiskenler[u].degiskenAdi = EditorGUILayout.TextField(targetObject.degiskenler[u].degiskenAdi);

                EditorGUILayout.Space(5);

                bool degiskenEkle = false;
                for (int i = 0; i < targetObject.degiskenler[u].degiskenDegerleri.Count; i++)
                {
                    int removeIndex = -1;
                    EditorGUILayout.BeginHorizontal();
                    targetObject.degiskenler[u].degiskenDegerleri[i] = EditorGUILayout.TextField(targetObject.degiskenler[u].degiskenDegerleri[i], GUILayout.ExpandWidth(true));
                    if (GUILayout.Button("-", GUILayout.Width(20)))
                    {
                        removeIndex = i;
                        EditorGUI.FocusTextInControl(null);
                    }
                    EditorGUILayout.EndHorizontal();
                    if (removeIndex >= 0)
                    {
                        targetObject.degiskenler[u].degiskenDegerleri.RemoveAt(i);
                    }
                }
                if (GUILayout.Button("Değişken ekle"))
                {
                    degiskenEkle = true;
                    EditorGUI.FocusTextInControl(null);
                }

                if (degiskenEkle)
                    targetObject.degiskenler[u].degiskenDegerleri.Add("yeni değer");

                EditorGUILayout.Space(10);
            }

            if (GUILayout.Button("Kategori ekle"))
            {
                kategoriEkle = true;
                EditorGUI.FocusTextInControl(null);
            }

            if (kategoriEkle)
                targetObject.degiskenler.Add(new DegiskeneGoreSohbetOlusturucuData.Degisken());

            if (removeIndexDegisken >= 0)
            {
                targetObject.degiskenler.RemoveAt(removeIndexDegisken);
            }

            EditorGUILayout.Space(50);
            if (GUILayout.Button("Değişkenleri kaydet ve düzenlemeye dön", GUILayout.Height(50)))
            {
                totalKombinasyon = 1;
                for (int i = 0; i < targetObject.degiskenler.Count; i++)
                {
                    totalKombinasyon *= targetObject.degiskenler[i].degiskenDegerleri.Count;
                }

                variableLists = new List<List<Sohbet.GerekenDegisken>>();
                emptyList = new List<List<Sohbet.GerekenDegisken>>();

                for (int i = 0; i < targetObject.degiskenler.Count; i++)
                {
                    variableLists.Add(new List<Sohbet.GerekenDegisken>());


                    for (int u = 0; u < targetObject.degiskenler[i].degiskenDegerleri.Count; u++)
                    {
                        variableLists[i].Add(new Sohbet.GerekenDegisken(targetObject.degiskenler[i].degiskenAdi, targetObject.degiskenler[i].degiskenDegerleri[u]));
                    }
                }

                for (int i = 0; i < totalKombinasyon; i++)
                {
                    emptyList.Add(new List<Sohbet.GerekenDegisken>());
                    foreach (DegiskeneGoreSohbetOlusturucuData.Degisken element in targetObject.degiskenler)
                    {
                        emptyList[i].Add(new Sohbet.GerekenDegisken());
                    }
                    emptyList = WriteeCombinationsOfAllList(emptyList, variableLists);
                }

                targetObject.datas = new List<DegiskeneGoreSohbetOlusturucuData.Data>();

                for (int i = 0; i < totalKombinasyon; i++)
                {
                    targetObject.datas.Add(new DegiskeneGoreSohbetOlusturucuData.Data());

                    targetObject.datas[i].gerekenDegiskenler = new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[emptyList[i].Count]);
                    for (int u = 0; u < targetObject.datas[i].gerekenDegiskenler.Count; u++)
                    {
                        targetObject.datas[i].gerekenDegiskenler[u] = emptyList[i][u];
                        if (emptyList[i][u].degiskenAdi != "mod")
                        {
                            targetObject.datas[i].sohbetAdi += emptyList[i][u].degiskenDegeri.Replace("ü", "u").Replace("Ü", "U").Replace("ö", "o").Replace("Ö", "O")
                                .Replace("ç", "c").Replace("Ç", "C").Replace("İ", "I").Replace("ı", "i").Replace("ğ", "g").Replace("Ğ", "G").Replace("Ş", "S").Replace("ş", "s").Replace(" ", ""); ;
                            if (u != targetObject.datas[i].gerekenDegiskenler.Count - 1)
                                targetObject.datas[i].sohbetAdi += "-";
                        }
                        Debug.Log(emptyList[i][u].degiskenAdi);
                    }
                }

                targetObject.menuState = 1;
                secinlenDataIndex = -1;
                EditorUtility.SetDirty(targetObject);
            }
        }
        else if (targetObject.menuState == 1)
        {
            if (secinlenDataIndex == -1)
            {
                int count = 0;
                if (GUILayout.Button("Sohbetleri dışarı aktar", GUILayout.Height(40)))
                {
                    EditorUtility.SetDirty(targetObject);

                    for (int i = 0; i < emptyList.Count; i++)
                    {
                        string debugstring = "";
                        foreach (Sohbet.GerekenDegisken degiskenDegerleri2 in emptyList[i])
                        {
                            debugstring += " | " + degiskenDegerleri2.degiskenAdi + ": " + degiskenDegerleri2.degiskenDegeri;
                        }

                        Sohbet sohbet = CreateInstance<Sohbet>();
                        sohbet.idIndex = "-1";
                        if (!string.IsNullOrEmpty(targetObject.datas[i].sohbetAdi))
                            sohbet.name = targetObject.datas[i].sohbetAdi;
                        else
                            sohbet.name = "Sohbet";

                        sohbet.aciklama = new List<string>() { targetObject.datas[i].aciklama };
                        sohbet.gerekliDegiskenler = targetObject.datas[i].gerekenDegiskenler;

                        EditorUtility.SetDirty(sohbet);
                        ProjectWindowUtil.CreateAsset(sohbet, sohbet.name + ".asset");

                        count += 1;
                    }
                    AssetDatabase.SaveAssets();
                }
                GUILayout.Label("Şuanki sohbet sayısı: " + targetObject.datas.Count);
                EditorGUILayout.Space(20);
                if (GUILayout.Button("Değişkenleri göster"))
                {
                    targetObject.menuState = -1;
                    EditorUtility.SetDirty(targetObject);
                }

                GUILayout.Label("Sohbet adlarını otomatik oluştur");

                EditorGUILayout.BeginHorizontal();
                if (GUILayout.Button("Değişkene göre"))
                {
                    for (int i = 0; i < targetObject.datas.Count; i++)
                    {
                        targetObject.datas[i].sohbetAdi = "";
                        for (int u = 0; u < targetObject.datas[i].gerekenDegiskenler.Count; u++)
                        {
                            if (targetObject.datas[i].gerekenDegiskenler[u].degiskenAdi != "mod")
                            {
                                targetObject.datas[i].sohbetAdi += targetObject.datas[i].gerekenDegiskenler[u].degiskenDegeri.Replace("ü", "u").Replace("Ü", "U").Replace("ö", "o").Replace("Ö", "O")
                                    .Replace("ç", "c").Replace("Ç", "C").Replace("İ", "I").Replace("ı", "i").Replace("ğ", "g").Replace("Ğ", "G").Replace("Ş", "S").Replace("ş", "s").Replace(" ", "");
                                if (u != targetObject.datas[i].gerekenDegiskenler.Count - 1)
                                    targetObject.datas[i].sohbetAdi += "-";
                            }
                        }
                    }
                }
                if (GUILayout.Button("Numaraya göre"))
                {
                    for (int i = 0; i < targetObject.datas.Count; i++)
                    {
                        targetObject.datas[i].sohbetAdi = (i + 1).ToString();
                    }
                }
                EditorGUILayout.EndHorizontal();

                GUIStyle customButton = new GUIStyle("button");
                customButton.alignment = TextAnchor.MiddleLeft;
                GUIStyle customLabel = new GUIStyle("label");
                customLabel.fontSize = 16;
                customLabel.fontStyle = FontStyle.Bold;

                for (int i = 0; i < targetObject.datas.Count; i++)
                {
                    EditorGUILayout.Space(10);
                    EditorGUILayout.BeginHorizontal();
                    foreach (Sohbet.GerekenDegisken degisken in targetObject.datas[i].gerekenDegiskenler)
                    {
                        GUILayout.Label(degisken.degiskenDegeri + " ", customLabel, GUILayout.ExpandWidth(false));
                    }
                    EditorGUILayout.EndHorizontal();
                    if (GUILayout.Button("Düzenle | Sohbet adı: " + targetObject.datas[i].sohbetAdi, customButton))
                    {
                        secinlenDataIndex = i; 
                        EditorGUI.FocusTextInControl(null);

                        scrollPossBeforeEdit = scrollPos;
                    }
                }
            }
            else
            {
                targetObject.datas[secinlenDataIndex].sohbetAdi = EditorGUILayout.TextField("Sohbet Adı: ", targetObject.datas[secinlenDataIndex].sohbetAdi);
                EditorGUILayout.Space(10);

                EditorGUILayout.BeginHorizontal();
                foreach(Sohbet.GerekenDegisken degisken in targetObject.datas[secinlenDataIndex].gerekenDegiskenler)
                {
                    GUILayout.Label(degisken.degiskenDegeri + " ", GUILayout.ExpandWidth(false));
                }
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(10);
                targetObject.datas[secinlenDataIndex].aciklama = GUILayout.TextArea(targetObject.datas[secinlenDataIndex].aciklama, GUILayout.ExpandHeight(true));

                EditorGUILayout.Space(20);
                if (GUILayout.Button("Tamam"))
                {
                    secinlenDataIndex =  -1;
                    EditorGUI.FocusTextInControl(null);
                    scrollPos = scrollPossBeforeEdit;
                }
            }
        }
        else if (targetObject.menuState == -1)
        {
            EditorGUILayout.Space(50);
            EditorGUILayout.LabelField("Emin misiniz?");
            EditorGUILayout.HelpBox("Değişken paneline girmek eğer varsa şuana kadar oluşturulan tüm sohbet verisini sıfırlar. Devam etmek istediğinize emin misiniz?", MessageType.Warning);
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Hayır", GUILayout.Height(30)))
            {
                targetObject.menuState = 1;
                EditorUtility.SetDirty(targetObject);
            }
            if (GUILayout.Button("Evet", GUILayout.Height(30)))
            {
                targetObject.menuState = 0;
                EditorUtility.SetDirty(targetObject);
            }
            EditorGUILayout.EndHorizontal();
        }

        serializedObject.Update();

        EditorGUILayout.EndScrollView();
    }

    List<List<T>> WriteeCombinationsOfAllList<T>(List<List<T>> unsortedLists, List<List<T>> allVariables)
    {
        int currentDepth = 1;
        int currentStartIndex = 0;
        for(int i =0; i< allVariables.Count;i++)
        {
            unsortedLists = WriteeCombinationsOfList(allVariables[i], unsortedLists, currentStartIndex, currentDepth);
            currentDepth *= allVariables[i].Count;
            currentStartIndex += 1;
        }
        return unsortedLists;
    }


 List<List<T>> WriteeCombinationsOfList<T>(List<T> writingList, List<List<T>> emptyList, int startIndex, int depth)
    {
        int index = 0;
        for (int a = 0; a < depth; a++)
        {
            for (int u = 0; u < writingList.Count; u++)
            {
                for (int i = 0; i < (emptyList.Count / depth) / writingList.Count; i++)
                {
                    emptyList[index][startIndex] = writingList[u];
                    index += 1;
                }
            }
        }
        return emptyList;
    }
}
