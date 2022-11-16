using System.Collections;
using System.Reflection;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;

public class BasamakliSohbetWindow : EditorWindow
{
    List<BasamakliSohbet> basamakliSohbets;

    Vector2 mainScroll;

    GUIStyle h1;
    GUIStyle h2;
    GUIStyle h3;
    GUIStyle h4;

    Editor sohbetEditor = null;

    string sohbetName = "Sohbet";
    string sohbetHeader = "Sohbet";

    int menuState = 1;

    [MenuItem("Magnus/Olusturucular/Basamakli Sohbet Olusturucu")]
    public static void ShowWindow()
    {
        BasamakliSohbetWindow window = (BasamakliSohbetWindow)EditorWindow.GetWindow(typeof(BasamakliSohbetWindow));
        window.minSize = new Vector2(400, 400);
    }

    private void OnEnable()
    {
        basamakliSohbets = new List<BasamakliSohbet>();
        basamakliSohbets.Add(new BasamakliSohbet());
        basamakliSohbets[0].sohbetAdi = "Sohbet - 1";

        h1 = new GUIStyle();
        h1.fontSize = 30;
        h1.normal.textColor = Color.white;
        h1.fontStyle = FontStyle.Bold;

        h2 = new GUIStyle();
        h2.fontSize = 21;
        h2.normal.textColor = Color.white;
        h2.fontStyle = FontStyle.Bold;

        h3 = new GUIStyle();
        h3.fontSize = 15;
        h3.normal.textColor = Color.white;
        h3.fontStyle = FontStyle.Bold;

        h4 = new GUIStyle();
        h4.fontSize = 10;
        h4.normal.textColor = Color.white;
        h4.fontStyle = FontStyle.Bold;
    }

    private void OnGUI()
    {
        mainScroll = EditorGUILayout.BeginScrollView(mainScroll);

        sohbetName = EditorGUILayout.TextField("Sohbet Adı: ", sohbetName);

        if (menuState == 0)
        {
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("X", GUILayout.Height(50), GUILayout.Width(50)))
            {
                menuState = 1;
                EditorGUI.FocusTextInControl("");
            }
            EditorGUILayout.LabelField(sohbetHeader, h1, GUILayout.Height(50));
            EditorGUILayout.EndHorizontal();

            sohbetEditor.OnInspectorGUI();
        }
        else
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Basamaklı Sohbet\nOluşturucu", h2, GUILayout.Height(50));
            if (GUILayout.Button("Sohbeti veritabanına aktar", GUILayout.Height(50), GUILayout.Width(200)))
            {
                InitiateCreateSohbets();
                menuState = 1; 
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(20);
        }

        DrawBasamakliSohbetEditor(basamakliSohbets, null, 0);

        EditorGUILayout.EndScrollView();
    }

    void DrawBasamakliSohbetEditor(List<BasamakliSohbet> basamakliSohbetsList, BasamakliSohbet parent,  int depth)
    {
        if (basamakliSohbetsList != null)
        {
            //foreach (BasamakliSohbet basamakliSohbet in basamakliSohbetsList)
            for(int a = 0; a<basamakliSohbetsList.Count; a++)
            {
                if (basamakliSohbetsList[a].sohbet.cevaplar.Count > 0)
                {
                    if (basamakliSohbetsList[a].basamakliSohbets != null)
                    {
                        if (basamakliSohbetsList[a].sohbet.cevaplar.Count > basamakliSohbetsList[a].basamakliSohbets.Count)
                        {
                            string sohbetName = basamakliSohbetsList[a].sohbetAdi;
                            int countOffset = 0;
                            if (depth == 0)
                            {
                                sohbetName = this.sohbetName;
                                countOffset = 1;
                            }

                            basamakliSohbetsList[a].basamakliSohbets.Add(new BasamakliSohbet());
                            basamakliSohbetsList[a].basamakliSohbets[basamakliSohbetsList[a].basamakliSohbets.Count - 1].sohbetAdi = sohbetName + " - " + (basamakliSohbetsList[a].sohbet.cevaplar.Count + countOffset);
                            basamakliSohbetsList[a].sohbet.cevaplar[basamakliSohbetsList[a].sohbet.cevaplar.Count - 1].sonrakiSohbetHavuzu = basamakliSohbetsList[a].basamakliSohbets[basamakliSohbetsList[a].basamakliSohbets.Count - 1].sohbet;
                        }
                        else if (basamakliSohbetsList[a].sohbet.cevaplar.Count < basamakliSohbetsList[a].basamakliSohbets.Count)
                        {
                            for (int i = 0; i < basamakliSohbetsList[a].basamakliSohbets.Count; i++)
                            {
                                for (int u = 0; u < basamakliSohbetsList[a].sohbet.cevaplar.Count; u++)
                                {
                                    if (basamakliSohbetsList[a].basamakliSohbets[i].sohbet != basamakliSohbetsList[a].sohbet.cevaplar[u].sonrakiSohbetHavuzu)
                                    {
                                        if (u == basamakliSohbetsList[a].sohbet.cevaplar.Count - 1)
                                        {
                                            Debug.Log("cikarildi");
                                            DestroyImmediate(basamakliSohbetsList[a].basamakliSohbets[i].sohbet);
                                            basamakliSohbetsList[a].basamakliSohbets.RemoveAt(i);
                                        }
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        if (basamakliSohbetsList[a].sohbet.cevaplar.Count > 0)
                        {
                            string sohbetName = basamakliSohbetsList[a].sohbetAdi;
                            int countOffset = 0;
                            if (depth == 0)
                            {
                                sohbetName = this.sohbetName;
                                countOffset = 1;
                            }

                            Debug.Log("eklendi");
                            basamakliSohbetsList[a].basamakliSohbets = new List<BasamakliSohbet>();
                            basamakliSohbetsList[a].basamakliSohbets.Add(new BasamakliSohbet());
                            basamakliSohbetsList[a].basamakliSohbets[basamakliSohbetsList[a].basamakliSohbets.Count - 1].sohbetAdi = sohbetName + " - " + (basamakliSohbetsList[a].sohbet.cevaplar.Count + countOffset);
                            basamakliSohbetsList[a].sohbet.cevaplar[basamakliSohbetsList[a].sohbet.cevaplar.Count - 1].sonrakiSohbetHavuzu = basamakliSohbetsList[a].basamakliSohbets[basamakliSohbetsList[a].basamakliSohbets.Count - 1].sohbet;
                        }
                    }
                }
                else
                {
                    if (basamakliSohbetsList[a].basamakliSohbets != null)
                    {
                        if (basamakliSohbetsList[a].basamakliSohbets.Count > 0)
                        {
                            DestroyImmediate(basamakliSohbetsList[a].basamakliSohbets[0].sohbet);
                            basamakliSohbetsList[a].basamakliSohbets.RemoveAt(0);
                        }
                    }
                }

                if (basamakliSohbetsList[a] != null)
                {
                    if (menuState == 1)
                    {
                        GUIStyle contentStyle = new GUIStyle("Button");

                        contentStyle.alignment = TextAnchor.MiddleLeft;

                        int sizeDepth = depth;

                        float offset = 5f + (position.width/15f) * sizeDepth;

                        float buttonWidth = position.width - offset - 10f;

                        while (buttonWidth < 100)
                        {
                            sizeDepth -= 1;
                            offset = 5f + (position.width / 15f) * sizeDepth;
                            buttonWidth = position.width - offset - 10f;
                        }

                        if (basamakliSohbetsList[a].sohbet.aciklama != null)
                        {
                            if (basamakliSohbetsList[a].sohbet.aciklama.Count > 0)
                            {
                                //EditorGUILayout.LabelField(basamakliSohbet.sohbetAdi, h1, GUILayout.Height(40));
                                int maxChar = 50;
                                string headerAciklama = "";
                                string headerCevap = "";

                                headerAciklama += basamakliSohbetsList[a].sohbet.aciklama[0];

                                if (parent != null)
                                {
                                    if (parent.sohbet.cevaplar != null)
                                    {
                                        if (parent.sohbet.cevaplar[a].cevapVaryasyonlari != null)
                                        {
                                            headerCevap += parent.sohbet.cevaplar[a].cevapVaryasyonlari[0];
                                        }
                                    }
                                }

                                if (headerAciklama.Length >= maxChar)
                                {
                                    headerAciklama = headerAciklama.Substring(0, maxChar);
                                }

                                if (!string.IsNullOrEmpty(headerCevap))
                                {
                                    GUILayout.BeginHorizontal();
                                    GUILayout.Space(offset);
                                    if (GUILayout.Button($"{basamakliSohbetsList[a].sohbetAdi} CEVAP: {headerCevap} | SORU: {headerAciklama}", contentStyle, GUILayout.Height(30), GUILayout.Width(buttonWidth), GUILayout.ExpandHeight(false)))
                                    {
                                        sohbetEditor = Editor.CreateEditor(basamakliSohbetsList[a].sohbet);
                                        sohbetHeader = basamakliSohbetsList[a].sohbetAdi;
                                        menuState = 0;
                                    }
                                    GUILayout.EndHorizontal();
                                }
                                else
                                {
                                    GUILayout.BeginHorizontal();
                                    GUILayout.Space(offset);
                                    if (GUILayout.Button($"{basamakliSohbetsList[a].sohbetAdi} SORU: {headerAciklama}", contentStyle, GUILayout.Height(30), GUILayout.Width(buttonWidth), GUILayout.ExpandHeight(false)))
                                    {
                                        sohbetEditor = Editor.CreateEditor(basamakliSohbetsList[a].sohbet);
                                        sohbetHeader = basamakliSohbetsList[a].sohbetAdi;
                                        menuState = 0;
                                    }
                                    GUILayout.EndHorizontal();
                                }
                            }
                            else
                            {
                                string headerCevap = "";
                                if (parent != null)
                                {
                                    if (parent.sohbet.cevaplar != null)
                                    {
                                        if (parent.sohbet.cevaplar[a].cevapVaryasyonlari != null)
                                        {
                                            headerCevap += parent.sohbet.cevaplar[a].cevapVaryasyonlari[0];
                                        }
                                    }
                                }

                                if (!string.IsNullOrEmpty(headerCevap))
                                {
                                    GUILayout.BeginHorizontal();
                                    GUILayout.Space(offset);
                                    if (GUILayout.Button($"{basamakliSohbetsList[a].sohbetAdi} CEVAP: {headerCevap}", contentStyle, GUILayout.Height(30), GUILayout.Width(buttonWidth), GUILayout.ExpandHeight(false)))
                                    {
                                        sohbetEditor = Editor.CreateEditor(basamakliSohbetsList[a].sohbet);
                                        sohbetHeader = basamakliSohbetsList[a].sohbetAdi;
                                        menuState = 0;
                                    }
                                    GUILayout.EndHorizontal();
                                }
                                else
                                {
                                    GUILayout.BeginHorizontal();
                                    GUILayout.Space(offset);
                                    if (GUILayout.Button($"{basamakliSohbetsList[a].sohbetAdi}", contentStyle, GUILayout.Height(30), GUILayout.Width(buttonWidth), GUILayout.ExpandHeight(false)))
                                    {
                                        sohbetEditor = Editor.CreateEditor(basamakliSohbetsList[a].sohbet);
                                        sohbetHeader = basamakliSohbetsList[a].sohbetAdi;
                                        menuState = 0;
                                    }
                                    GUILayout.EndHorizontal();
                                }
                            }
                        }
                        else
                        {
                            string headerCevap = "";
                            if (parent != null)
                            {
                                if (parent.sohbet.cevaplar != null)
                                {
                                    if (parent.sohbet.cevaplar[a].cevapVaryasyonlari != null)
                                    {
                                        headerCevap += " | " + parent.sohbet.cevaplar[a].cevapVaryasyonlari[0];
                                    }
                                }
                            }

                            if (!string.IsNullOrEmpty(headerCevap))
                            {
                                GUILayout.BeginHorizontal();
                                GUILayout.Space(offset);
                                if (GUILayout.Button($"{basamakliSohbetsList[a].sohbetAdi} CEVAP: {headerCevap}", contentStyle, GUILayout.Height(30), GUILayout.Width(buttonWidth), GUILayout.ExpandHeight(false)))
                                {
                                    sohbetEditor = Editor.CreateEditor(basamakliSohbetsList[a].sohbet);
                                    sohbetHeader = basamakliSohbetsList[a].sohbetAdi;
                                    menuState = 0;
                                }
                                GUILayout.EndHorizontal();
                            }
                            else
                            {
                                GUILayout.BeginHorizontal();
                                GUILayout.Space(offset);
                                if (GUILayout.Button($"{basamakliSohbetsList[a].sohbetAdi}", contentStyle, GUILayout.Height(30), GUILayout.Width(buttonWidth), GUILayout.ExpandHeight(false)))
                                {
                                    sohbetEditor = Editor.CreateEditor(basamakliSohbetsList[a].sohbet);
                                    sohbetHeader = basamakliSohbetsList[a].sohbetAdi;
                                    menuState = 0;
                                }
                                GUILayout.EndHorizontal();
                            }
                        }
                        EditorGUILayout.Space(5);
                    }

                    DrawBasamakliSohbetEditor(basamakliSohbetsList[a].basamakliSohbets, basamakliSohbetsList[a], depth + 1);
                }
                /*
                if (basamakliSohbet.basamakliSohbets != null)
                {
                    foreach (BasamakliSohbet basamakliSohbet2 in basamakliSohbet.basamakliSohbets)
                    {
                        if (basamakliSohbet2.basamakliSohbets != null)
                        {
                            Debug.Log(basamakliSohbet2.basamakliSohbets.Count);
                        }
                        else
                        {
                            Debug.Log(null);
                        }
                        DrawBasamakliSohbetEditor(basamakliSohbet2.basamakliSohbets);
                    }
                }*/
            }
        }
    }

    void DeleteSohbets(List<BasamakliSohbet> basamakliSohbetsList)
    {
        if (basamakliSohbetsList != null)
        {
            foreach (BasamakliSohbet basamakliSohbet in basamakliSohbetsList)
            {
                DestroyImmediate(basamakliSohbet.sohbet);

                if (basamakliSohbet != null)
                {
                    DeleteSohbets(basamakliSohbet.basamakliSohbets);
                }
            }
        }
    }

    void InitiateCreateSohbets()
    {
        System.Type projectWindowUtilType = typeof(ProjectWindowUtil);
        MethodInfo getActiveFolderPath = projectWindowUtilType.GetMethod("GetActiveFolderPath", BindingFlags.Static | BindingFlags.NonPublic);
        object obj = getActiveFolderPath.Invoke(null, new object[0]);
        string pathToCurrentFolder = obj.ToString();

        CreateSohbets(basamakliSohbets, pathToCurrentFolder, sohbetName, true);

        basamakliSohbets = new List<BasamakliSohbet>();
        basamakliSohbets.Add(new BasamakliSohbet());
        basamakliSohbets[0].sohbetAdi = "Sohbet";
    }

    void CreateSohbets(List<BasamakliSohbet> basamakliSohbetsList, string path, string sohbetName, bool isMainSohbet)
    {
        if (basamakliSohbetsList != null)
        {
            for (int i = 0; i < basamakliSohbetsList.Count; i++)
            {
                EditorUtility.SetDirty(basamakliSohbetsList[i].sohbet);

                string newPath;
                if (isMainSohbet)
                {
                    newPath = AssetDatabase.GenerateUniqueAssetPath(path + "/" + sohbetName);

                    AssetDatabase.CreateFolder(path, sohbetName);

                    string uniquePath = AssetDatabase.GenerateUniqueAssetPath(newPath + "/" + sohbetName + ".asset");

                    basamakliSohbetsList[i].sohbet.idIndex = "-1";
                    AssetDatabase.CreateAsset(basamakliSohbetsList[i].sohbet, uniquePath);

                    if (basamakliSohbetsList[i] != null)
                    {
                        CreateSohbets(basamakliSohbetsList[i].basamakliSohbets, newPath, sohbetName, false);
                    }
                }
                else
                {
                    newPath = AssetDatabase.GenerateUniqueAssetPath(path + "/Secenek" + (i + 1).ToString());

                    AssetDatabase.CreateFolder(path, "Secenek" + (i + 1).ToString());

                    string uniquePath = AssetDatabase.GenerateUniqueAssetPath(newPath + "/" + sohbetName + GetIndexLetter(i) + ".asset");

                    basamakliSohbetsList[i].sohbet.idIndex = "-1";
                    AssetDatabase.CreateAsset(basamakliSohbetsList[i].sohbet, uniquePath);

                    if (basamakliSohbetsList[i] != null)
                    {
                        CreateSohbets(basamakliSohbetsList[i].basamakliSohbets, newPath, sohbetName + GetIndexLetter(i), false);
                    }
                }

                EditorUtility.SetDirty(basamakliSohbetsList[i].sohbet);
            }
        }
    }

    string GetIndexLetter(int index)
    {
        string returnValue = "N";

        switch (index + 1)
        {
            case 1:
                returnValue = "A";
                break;
            case 2:
                returnValue = "B";
                break;
            case 3:
                returnValue = "C";
                break;
            case 4:
                returnValue = "D";
                break;
            case 5:
                returnValue = "E";
                break;
            case 6:
                returnValue = "F";
                break;
            case 7:
                returnValue = "G";
                break;
            case 8:
                returnValue = "H";
                break;
            case 9:
                returnValue = "I";
                break;
            case 10:
                returnValue = "J";
                break;
            case 11:
                returnValue = "K";
                break;
            case 12:
                returnValue = "L";
                break;
            case 13:
                returnValue = "M";
                break;
            case 14:
                returnValue = "N";
                break;
        }

        return returnValue;
    }

    class BasamakliSohbet
    {
        public Sohbet sohbet = CreateInstance(typeof(Sohbet)) as Sohbet;
        public string sohbetAdi = "";
        public List<BasamakliSohbet> basamakliSohbets = null;

        public BasamakliSohbet()
        {
            sohbet.idIndex = "-1";
            sohbet.cevaplar = new List<CevapSohbet>();
        }
    }
}
