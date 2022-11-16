using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class MagnusEditorWindow : EditorWindow
{
    MagnusEditorWindow window;

    public xmlDeneme xml;

    public int menuState = -1;

    public string sohbetAdi;
    public string aciklama;

    Vector2 scrollPos;
    Vector2 scrollPosMainMenu;
    Vector2 scrollPosDataButtonMenu;

    string activeFolderPath = "Assets/Resources/SohbetVeriTabani";

    #region DataButtonVariables
    public List<string> degiskenler = new List<string>();
    public List<string> degerler = new List<string>();
    public List<string> metinler = new List<string>();
    #endregion

    //[MenuItem("Magnus/Olusturucular/Editor Paneli")]
    public static void ShowWindow()
    {
        MagnusEditorWindow window = (MagnusEditorWindow)EditorWindow.GetWindowWithRect(typeof(MagnusEditorWindow), new Rect(0, 0, 1000, 500));
    }

    void Initialize()
    {
        window = (MagnusEditorWindow)EditorWindow.GetWindowWithRect(typeof(MagnusEditorWindow), new Rect(0, 0, 100, 150));
    }

    private void OnEnable()
    {
        //activeFolderPath = "Assets";
        //Initialize();
    }

    void OnGUI()
    {
        if (menuState == 0)
        {
            MainMenu();
        }
        else if (menuState == 1)
        {
            DataButonMenu();
        }
    }

    public void MainMenu()
    {
        scrollPosMainMenu = EditorGUILayout.BeginScrollView(scrollPosMainMenu, GUILayout.Width(1000), GUILayout.Height(500));

        var folders = AssetDatabase.GetSubFolders(activeFolderPath);

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField(activeFolderPath);
        sohbetAdi = EditorGUILayout.TextField("Sohbet Adı:", sohbetAdi);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        #region FolderPanel
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos, GUILayout.Width(500), GUILayout.Height(40));
        EditorGUILayout.BeginHorizontal();

        foreach (var folder in folders)
        {
            string buttonName = "";
            char[] folderChar = folder.ToCharArray();

            for (int i = folderChar.Length - 1; i > 0; i--)
            {
                if (folderChar[i] == '/')
                {
                    for (int u = i + 1; u < folderChar.Length; u++)
                    {
                        buttonName += folderChar[u];
                    }
                    i = 0;
                    break;
                }
            }

            if (GUILayout.Button(buttonName))
            {
                activeFolderPath = folder;
            }
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndScrollView();
        #endregion

        if (activeFolderPath != "Assets/Resources/SohbetVeriTabani")
        {
            if (GUILayout.Button("<-", GUILayout.Width(40), GUILayout.Height(40)))
            {
                string backPath = "";
                char[] activeFolderPathChar = activeFolderPath.ToCharArray();

                for (int i = activeFolderPathChar.Length - 1; i > 0; i--)
                {
                    if (activeFolderPathChar[i] == '/')
                    {
                        for (int u = 0; u < i; u++)
                        {
                            backPath += activeFolderPathChar[u];
                        }
                        i = 0;
                        break;
                    }
                }

                activeFolderPath = backPath;
                //Debug.Log(activeFolderPath);
            }
        }
        else
        {
            GUILayout.Space(40);
        }

        if (Selection.activeObject != null)
        {
            if (!Selection.activeObject.GetType().Equals(typeof(Sohbet)) && !IfPathContainsSohbet(activeFolderPath, sohbetAdi))
            {
                if (GUILayout.Button("Sohbeti Oluştur", GUILayout.Height(40)))
                {
                    if (sohbetAdi.Replace(" ", "") != "")
                    {
                        Sohbet asset = ScriptableObject.CreateInstance<Sohbet>();
                        AssetDatabase.CreateAsset(asset, activeFolderPath + $"/{sohbetAdi.Replace(" ", "")}" + ".asset");

                        asset.aciklama = new List<string> { "" };
                        asset.aciklama[0] = aciklama;
                        Selection.activeObject = asset;
                        EditorGUIUtility.PingObject(asset);

                        EditorUtility.SetDirty(asset);
                        AssetDatabase.SaveAssets();
                    }
                }
            }
            else
            {
                if (GUILayout.Button("Sohbetin Üstüne Yaz", GUILayout.Height(40)))
                {
                    //Selection.pat
                }
            }
        }
        else
        {
            if (GUILayout.Button("Sohbeti Oluştur", GUILayout.Height(40)))
            {
                if (sohbetAdi.Replace(" ", "") != "")
                {
                    Sohbet asset = ScriptableObject.CreateInstance<Sohbet>();
                    AssetDatabase.CreateAsset(asset, activeFolderPath + $"/{sohbetAdi.Replace(" ", "")}" + ".asset");

                    asset.aciklama = new List<string> { "" };
                    asset.aciklama[0] = aciklama;
                    Selection.activeObject = asset;
                    EditorGUIUtility.PingObject(asset);

                    EditorUtility.SetDirty(asset);
                    AssetDatabase.SaveAssets();
                }
            }
        }

        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();

        EditorGUILayout.EndHorizontal();

        // The actual window code goes here
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("Data", GUILayout.Width(150), GUILayout.Height(25)))
        {
            menuState = 1;
        }

        if (GUILayout.Button("İsimciğim", GUILayout.Width(150), GUILayout.Height(25)))
        {

        }

        EditorGUILayout.EndHorizontal();

        GUIStyle textStyle = EditorStyles.textArea;
        textStyle.wordWrap = true;
        aciklama = EditorGUILayout.TextField("Açıklama", aciklama, GUILayout.Height(50));

        /*
        var list = new List<string>();

        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");
        list.Add("asdas");

        for (int i = 0; i < list.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space();
            list[i] = EditorGUILayout.TextField("Seçenekler", list[i], GUILayout.Width(900), GUILayout.Height(50));
            EditorGUILayout.EndHorizontal();
        }
        */


        EditorGUILayout.EndScrollView();
    }

    public void DataButonMenu()
    {
        scrollPosMainMenu = EditorGUILayout.BeginScrollView(scrollPosMainMenu, GUILayout.Width(1000), GUILayout.Height(500));
        //EditorGUILayout.Space(150);
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("<-", GUILayout.Width(40), GUILayout.Height(40)))
        {
            menuState = 0;
        }
        if (GUILayout.Button("Ekle", GUILayout.Height(40)))
        {
            menuState = 0;
            for (int i = 0; i < degerler.Count; i++)
            {
                if (i == 0)
                {
                    aciklama += "{{data, ";
                }

                aciklama += degiskenler[i] + "=" + degerler[i] + "|" + metinler[i];

                if (i == degerler.Count - 1)
                {
                    aciklama += "}}";
                }
            }
        }

        EditorGUILayout.EndHorizontal();

        for (int i = 0; i < degerler.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            degiskenler[i] = EditorGUILayout.TextField("Değişken Adı", degiskenler[i], GUILayout.Height(25));
            degerler[i] = EditorGUILayout.TextField("Değişken Değeri", degerler[i], GUILayout.Height(25));
            EditorGUILayout.EndHorizontal();
            metinler[i] = EditorGUILayout.TextField("Metin", metinler[i], GUILayout.Height(25));
            EditorGUILayout.Space(20);
        }

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("+", GUILayout.Width(40), GUILayout.Height(40)))
        {
            degiskenler.Add("");
            degerler.Add("");
            metinler.Add("");
        }

        if (GUILayout.Button("-", GUILayout.Width(40), GUILayout.Height(40)))
        {
            degiskenler.RemoveAt(degiskenler.Count - 1);
            degerler.RemoveAt(degerler.Count - 1);
            metinler.RemoveAt(metinler.Count - 1);

        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndScrollView();
    }

    bool IfPathContainsSohbet(string path, string name)
    {
        bool returnValue = false;

        char[] pathChar = path.ToCharArray();

        bool writeNewPath = false;
        string newPath = "";
        string resourcesPath = "Assets/Resources/";

        for(int i=0; i<pathChar.Length; i++)
        {
            if (!writeNewPath)
            {
                if (newPath != resourcesPath)
                {
                    newPath += pathChar[i];
                }
                else
                {
                    newPath = pathChar[i].ToString();
                    writeNewPath = true;
                }
            }
            else
            {
                newPath += pathChar[i];
            }
        }

        Sohbet[] sohbets = Resources.LoadAll<Sohbet>(newPath);
        foreach (Sohbet element in sohbets)
        {
            if (element.name == name)
            {
                returnValue = true;
           
                break;
            }
        }

        return returnValue;
    }
}
