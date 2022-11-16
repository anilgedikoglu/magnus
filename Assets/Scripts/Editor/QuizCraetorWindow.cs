using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class QuizCraetorWindow : EditorWindow
{
    [Space(20)]
    public string bilgiYarismasiIsim = "";

    [TextArea(5, 20)]
    public string cevapAciklama;
    [TextArea(5, 20)]
    public string dogruCevapAciklama = "Harika doğru cevap!";
    public string dogruCevapSecenekA = "Sonraki soruya geçelim";
    public string dogruCevapSecenekB = "Yarışmadan ayrıl";
    [TextArea(5, 20)]
    public string yanlisCevapAciklama = "Bilemedin, yarışma sona erdi.";
    public string yanlisCevapSecenekA = "Doğru cevap neydi?";
    public string yanlisCevapSecenekB = "Teşekkürler";

    Sohbet bilgiYarismasiSohbeti = null;
    Sohbet bilgiYarismasiSohbetiCvp = null;
    Sohbet bilgiYarismasiSohbetiDcvp = null;
    Sohbet bilgiYarismasiSohbetiYcvp = null;

    SerializedProperty aciklamaProperty, cevaplarProperty;

    public enum KategoriAdi {bilim, genelKultur, spor, tarihCografya, custom };
    public KategoriAdi kategoriAdi;
    public string kategoriAdiString;

    QuizEditorDataType preferencesObject;

    Vector2 scrollPos;

    [MenuItem("Magnus/Olusturucular/Bilgi Yarismasi Olusturucu")]
    public static void ShowWindow()
    {
        QuizCraetorWindow window = (QuizCraetorWindow)EditorWindow.GetWindow(typeof(QuizCraetorWindow));
    }

    public void ResetWindow()
    {
        bilgiYarismasiIsim = "";
        cevapAciklama = "";

        preferencesObject.bilgiYarismasiAciklama = new List<string> { "" }; ;
        preferencesObject.cevaplar =new List<BilgiYarismasiCevap>(new BilgiYarismasiCevap[2]);

        aciklamaProperty = null;
        cevaplarProperty = null;

        dogruCevapAciklama = "Harika doğru cevap!";
        dogruCevapSecenekA = "Diğer soruya geçelim";
        dogruCevapSecenekB = "Bu kadar yeterli";

        yanlisCevapAciklama = "Ne yazık ki yanlış cevap.";
        yanlisCevapSecenekA = "Doğru cevap neydi?";
        yanlisCevapSecenekB = "Teşekkürler";

        bilgiYarismasiSohbeti = null;
        bilgiYarismasiSohbetiCvp = null;
        bilgiYarismasiSohbetiDcvp = null;
        bilgiYarismasiSohbetiYcvp = null;

        SerializedObject so = new SerializedObject(preferencesObject);
        aciklamaProperty = so.FindProperty("bilgiYarismasiAciklama");
        cevaplarProperty = so.FindProperty("cevaplar");
    }

    private void OnEnable()
    {
        Sohbet[] tumSohbetler = Resources.LoadAll<Sohbet>("SohbetVeriTabani");

        QuizEditorDataType[] preferencess = Resources.LoadAll<QuizEditorDataType>("");
        preferencesObject = preferencess[0];

        SerializedObject so = new SerializedObject(preferencesObject);
        aciklamaProperty = so.FindProperty("bilgiYarismasiAciklama");
        cevaplarProperty = so.FindProperty("cevaplar");

        ResetWindow();
    }

    void OnGUI()
    {
        if (preferencesObject.ustMenu == null)
        {
            EditorGUILayout.HelpBox("Bilgi yarismasi icin ustmenu objesi tanimlanmadi. Lutfen quizEditorDataType objesinin icerisinde ustmenu icin bilgi yarismasi sonunda yonlendirilecek ustmenuyu tanimlayin. aksi taktirde sohbet olusturulamaz.", MessageType.Warning);
        }

        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

        kategoriAdi = (KategoriAdi)EditorGUILayout.EnumPopup(kategoriAdi);
        if (kategoriAdi == KategoriAdi.bilim)
        {
            kategoriAdiString = "Bilim";
        }
        else if (kategoriAdi == KategoriAdi.genelKultur)
        {
            kategoriAdiString = "GenelKultur";
        }
        else if (kategoriAdi == KategoriAdi.spor)
        {
            kategoriAdiString = "Spor";
        }
        else if (kategoriAdi == KategoriAdi.tarihCografya)
        {
            kategoriAdiString = "TarihCografya";
        }
        else
        {
            kategoriAdiString = EditorGUILayout.TextField(kategoriAdiString);
        }

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Sohbet ismi", GUILayout.Width(120));
        bilgiYarismasiIsim = EditorGUILayout.TextField(bilgiYarismasiIsim);
        EditorGUILayout.EndHorizontal();

        SerializedObject so = new SerializedObject(preferencesObject);
        EditorGUILayout.PropertyField(aciklamaProperty, true);
        EditorGUILayout.PropertyField(cevaplarProperty, true);
        so.Update();

        GUILayout.Space(20);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Doğru cevap açıklama", GUILayout.Width(120));
        dogruCevapAciklama = EditorGUILayout.TextArea(dogruCevapAciklama, GUILayout.Height(60));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Diğer soru", GUILayout.Width(120));
        dogruCevapSecenekA = EditorGUILayout.TextField(dogruCevapSecenekA);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Bu kadar yeterli", GUILayout.Width(120));
        dogruCevapSecenekB = EditorGUILayout.TextField(dogruCevapSecenekB);
        EditorGUILayout.EndHorizontal();


        GUILayout.Space(20);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Yanlış cevap açıklama", GUILayout.Width(120));
        yanlisCevapAciklama = EditorGUILayout.TextArea(yanlisCevapAciklama, GUILayout.Height(60));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Doğru cevap nedir", GUILayout.Width(120));
        yanlisCevapSecenekA = EditorGUILayout.TextField(yanlisCevapSecenekA);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Bu kadar yeterli", GUILayout.Width(120));
        yanlisCevapSecenekB = EditorGUILayout.TextField(yanlisCevapSecenekB);
        EditorGUILayout.EndHorizontal();


        GUILayout.Space(20);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Cevap açıklama", GUILayout.Width(120));
        cevapAciklama = EditorGUILayout.TextArea(cevapAciklama, GUILayout.Height(80));
        EditorGUILayout.EndHorizontal();

        if (bilgiYarismasiIsim.Replace(" ", "") != "" && preferencesObject.ustMenu != null)
        {
            if (GUILayout.Button("Bilgi yarışması sohbetini kaydet"))
            {
                if (!System.IO.File.Exists(Application.dataPath + "/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim))
                {
                    var file = System.IO.Directory.CreateDirectory(Application.dataPath + "/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim);
                }

                if (System.IO.File.Exists(Application.dataPath + "/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + ".asset"))
                {
                    int index = 1;

                    while (System.IO.File.Exists(Application.dataPath + "/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + index.ToString() + ".asset"))
                    {
                        index += 1;
                    }

                    if (!System.IO.File.Exists(Application.dataPath + "/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + index.ToString() + ".asset"))
                    {
                        CreateSohbet(index);
                    }
                }
                else
                {
                    CreateSohbet(0);
                }

                bilgiYarismasiSohbeti = null;
            }

        }

        GUILayout.Space(20);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Üst menü sohbet", GUILayout.Width(120));
        preferencesObject.ustMenu = EditorGUILayout.ObjectField(preferencesObject.ustMenu, typeof(Sohbet), true) as Sohbet;
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.EndScrollView();

    }

    void CreateSohbet(int index)
    {
        bilgiYarismasiSohbeti = ScriptableObject.CreateInstance<Sohbet>();
        bilgiYarismasiSohbetiCvp = ScriptableObject.CreateInstance<Sohbet>();
        bilgiYarismasiSohbetiDcvp = ScriptableObject.CreateInstance<Sohbet>();
        bilgiYarismasiSohbetiYcvp = ScriptableObject.CreateInstance<Sohbet>();

        bilgiYarismasiSohbeti.aciklama = new List<string>(new string[preferencesObject.bilgiYarismasiAciklama.Count]);
        for (int i = 0; i < preferencesObject.bilgiYarismasiAciklama.Count; i++)
        {
            bilgiYarismasiSohbeti.aciklama[i] = preferencesObject.bilgiYarismasiAciklama[i];
        }


            bilgiYarismasiSohbeti.cevaplar =new List<CevapSohbet>(new CevapSohbet[preferencesObject.cevaplar.Count]);
        for (int i = 0; i < preferencesObject.cevaplar.Count; i++)
        {
            bilgiYarismasiSohbeti.cevaplar[i] = new CevapSohbet();
            bilgiYarismasiSohbeti.cevaplar[i].cevapVaryasyonlari =new List<string>(new string[] { preferencesObject.cevaplar[i].cevap });
            if (preferencesObject.cevaplar[i].dogruCevap)
                bilgiYarismasiSohbeti.cevaplar[i].sonrakiSohbetHavuzu = bilgiYarismasiSohbetiDcvp;
            else
                bilgiYarismasiSohbeti.cevaplar[i].sonrakiSohbetHavuzu = bilgiYarismasiSohbetiYcvp;
        }

        bilgiYarismasiSohbeti.sayac = 30;
        bilgiYarismasiSohbeti.sayacTipi = Sohbet.sayacTipiEnum.barVeEkrandaText;
        bilgiYarismasiSohbeti.sayacModu = "byzamandoldu";
        bilgiYarismasiSohbeti.sayaSonuAnaMenuyeGit = false;

        bilgiYarismasiSohbeti.sohbetBititmindeAnamenuyeDon = false;
        bilgiYarismasiSohbeti.anaMenuyeGitButonuOlustur = true;
        bilgiYarismasiSohbeti.gerekliDegiskenler = new List<Sohbet.GerekenDegisken> { new Sohbet.GerekenDegisken() };
        bilgiYarismasiSohbeti.gerekliDegiskenler[0].degiskenAdi = "mod";
        if (kategoriAdi == KategoriAdi.bilim)
        {
            bilgiYarismasiSohbeti.gerekliDegiskenler[0].degiskenDegeri = "byb";
        }
        else if (kategoriAdi == KategoriAdi.genelKultur)
        {
            bilgiYarismasiSohbeti.gerekliDegiskenler[0].degiskenDegeri = "bygk";
        }
        else if (kategoriAdi == KategoriAdi.spor)
        {
            bilgiYarismasiSohbeti.gerekliDegiskenler[0].degiskenDegeri = "bys";
        }
        else if (kategoriAdi == KategoriAdi.tarihCografya)
        {
            bilgiYarismasiSohbeti.gerekliDegiskenler[0].degiskenDegeri = "bytc";
        }
        else
        {
            bilgiYarismasiSohbeti.gerekliDegiskenler[0].degiskenDegeri = "by" + EditorGUILayout.TextField(kategoriAdiString).ToLower();
        }

        bilgiYarismasiSohbetiCvp.aciklama = new List<string> { cevapAciklama };
        bilgiYarismasiSohbetiCvp.sohbetBititmindeAnamenuyeDon = true;
        bilgiYarismasiSohbetiCvp.anaMenuyeGitButonuOlustur = false;

        bilgiYarismasiSohbetiDcvp.aciklama = new List<string> { dogruCevapAciklama };
        bilgiYarismasiSohbetiDcvp.cevaplar = new List<CevapSohbet>(new CevapSohbet[] { new CevapSohbet(), new CevapSohbet() });
        bilgiYarismasiSohbetiDcvp.cevaplar[0].cevapVaryasyonlari = new List<string>(new string[] { dogruCevapSecenekA });
        bilgiYarismasiSohbetiDcvp.cevaplar[1].cevapVaryasyonlari = new List<string>(new string[] { dogruCevapSecenekB });
        bilgiYarismasiSohbetiDcvp.cevaplar[1].sonrakiSohbetHavuzu = preferencesObject.ustMenu;
        bilgiYarismasiSohbetiDcvp.sohbetBititmindeAnamenuyeDon = false;
        bilgiYarismasiSohbetiDcvp.anaMenuyeGitButonuOlustur = false;

        bilgiYarismasiSohbetiYcvp.aciklama = new List<string> { yanlisCevapAciklama };
        bilgiYarismasiSohbetiYcvp.cevaplar = new List<CevapSohbet>(new CevapSohbet[] { new CevapSohbet(), new CevapSohbet() });
        bilgiYarismasiSohbetiYcvp.cevaplar[0].cevapVaryasyonlari = new List<string>(new string[] { yanlisCevapSecenekA });
        bilgiYarismasiSohbetiYcvp.cevaplar[0].sonrakiSohbetHavuzu = bilgiYarismasiSohbetiCvp;
        bilgiYarismasiSohbetiYcvp.cevaplar[1].cevapVaryasyonlari = new List<string>(new string[] { yanlisCevapSecenekB });
        bilgiYarismasiSohbetiYcvp.cevaplar[1].sonrakiSohbetHavuzu = preferencesObject.ustMenu;
        bilgiYarismasiSohbetiYcvp.sohbetBititmindeAnamenuyeDon = true;
        bilgiYarismasiSohbetiYcvp.anaMenuyeGitButonuOlustur = false;

        string path;
        string pathCvp;
        string pathDcvp;
        string pathYcvp;

        if (index != 0)
        {
            path = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + index.ToString() + ".asset";
            pathCvp = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + index.ToString() + "Cvp.asset";
            pathDcvp = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + index.ToString() + "Dcvp.asset";
            pathYcvp = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + index.ToString() + "Ycvp.asset";
        }
        else
        {
            path = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + ".asset";
            pathCvp = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + "Cvp.asset";
            pathDcvp = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + "Dcvp.asset";
            pathYcvp = "Assets/Resources/SohbetVeriTabani/Version1/HaydiBirazEglenelim/BilgiYarismasi/" + kategoriAdiString + "/" + bilgiYarismasiIsim + "/" + bilgiYarismasiIsim + "Ycvp.asset";
        }

        AssetDatabase.CreateAsset(bilgiYarismasiSohbeti, path);
        AssetDatabase.CreateAsset(bilgiYarismasiSohbetiCvp, pathCvp);
        AssetDatabase.CreateAsset(bilgiYarismasiSohbetiDcvp, pathDcvp);
        AssetDatabase.CreateAsset(bilgiYarismasiSohbetiYcvp, pathYcvp);

        EditorUtility.SetDirty(bilgiYarismasiSohbeti);
        EditorUtility.SetDirty(bilgiYarismasiSohbetiCvp);
        EditorUtility.SetDirty(bilgiYarismasiSohbetiDcvp);
        EditorUtility.SetDirty(bilgiYarismasiSohbetiYcvp);

        AssetDatabase.SaveAssets();

        ResetWindow();
    }
}