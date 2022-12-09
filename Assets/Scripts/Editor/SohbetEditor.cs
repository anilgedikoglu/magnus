using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using UnityEngine.UIElements;
using System;

[CustomEditor(typeof(Sohbet)), CanEditMultipleObjects]
public class SohbetEditor : Editor
{
    public string  menuState = "veriGirisi";

    int secilenList;
    string focusedTextBoxId;
    int secilenListVariation;

    #region dataButonu
    string dataAciklama;
    List<DataButonu> dataButonu = new List<DataButonu>();
    #endregion

    #region kelimeButonu
    List<string> kelimeAciklama = new List<string>();
    #endregion

    #region saateGoreKelimeSec
    string saatCumle1 = "";
    string saatCumle2 = "";
    string saatCumle3 = "";
    string saatCumle4 = "";
    string saatCumle5 = "";
    #endregion

    #region sayiButonlari
    string sayiButonuAdi = "";
    int sayiButonuSayi = 0;
    #endregion

    #region aralikliSayiButonlari
    string aralikliSayiButonuAdi = "";
    int aralikliSayiButonuSayi1 = 0;
    int aralikliSayiButonuSayi2 = 0;
    #endregion

    Sohbet sohbet;

    #region ButtonStyles
    GUIStyle metinSecButton;
    GUIStyle boldButton;
    #endregion

    #region TextAreaStyles
    GUIStyle aciklamaTextArea;
    #endregion

    #region LabelStyles
    GUIStyle labelHeadline1;
    GUIStyle labelHeadline2;

    GUIStyle labelRegularRight;

    GUIStyle secenekSilButtonStyle;
    GUIStyle secenekEkleButtonStyle;
    #endregion

    #region Foldout
    static bool showAciklama = true;
    static bool showBirlestirilecekModlar = true;
    static bool showCevaplar = true;
    static bool showGerekenDegiskenler = true;
    static bool showFotgrafOzellikleri = true;
    static bool showYoksayOzellikleri = true;
    static bool showSayacOzellikleri = true;
    static bool showTekrarlamaOzellikleri = true;
    static bool showSohbetBitimiOzellikleri = true;
    static bool showEnerjiOzellikleri = true;
    static bool showSecenekOzellikleri = true;
    List<bool> showCevapVaryasyonlari;
    List<bool> showCevap;
    List<bool> showCevapGerekenDegiskenler;
    List<bool> showCevapayarlananDegiskenler;
    #endregion

    bool deletable = false;

    Vector2 mainScroll = new Vector2();

    List<Vector2> scroll = new List<Vector2>();
    List<bool> scrollUsed = new List<bool>();

    static int gorunum = 0;

    SerializedProperty aciklama;

    bool panelAciklamaRender;

    private List<string> renderlananAciklamalar;

    private void OnEnable()
    {
        if (target != null)
        {
            sohbet = (Sohbet)target;
            aciklama = serializedObject.FindProperty("aciklama");
        }
        //EditorUtility.SetDirty(sohbet);
        //AssetDatabase.SaveAssets();
        sohbet.preferencesObject = Resources.Load<PreferencesObject>(PreferencesObject.PreferencesPath);

        if (sohbet.preferencesObject == null)
        {
            Debug.LogError($"Preferecens onjesi bulunamadi. Lutfen objenin {PreferencesObject.PreferencesPath} yolunda bulunup bulunmadigini kontrol edin. Eger konumu veya ismi degistiyse Sohbet classi icinde bunu degistirin.");
        }

        renderlananAciklamalar = new List<string>();
    }

    private void OnDisable()
    {
        if (target != null)
        {
            EditorUtility.SetDirty(sohbet);
        }
    }

    public override void OnInspectorGUI()
    {
        /*
        string[] excludes= new string[5];
        excludes[0] = "d5f3511d02455d84c815ec1158145792";
        excludes[1] = "aciklama";
        excludes[2] = "birlestirilecekModlar";
        excludes[3] = "cevaplar";
        excludes[4] = "gostermeSansi";
        DrawPropertiesExcluding(serializedObject, excludes);*/

        //Bu satir en basta olmali
        for (int i = 0; i < scrollUsed.Count; i++)
        {
            scrollUsed[i] = false;
        }

        EditorStyles.textArea.wordWrap = true;

        if (metinSecButton == null)
        {
            metinSecButton = new GUIStyle("button");
            boldButton = new GUIStyle("button");
            labelHeadline1 = new GUIStyle("label");
            labelHeadline2 = new GUIStyle("label");
            labelRegularRight = new GUIStyle("label");

            dataButonu.Add(new DataButonu());

            #region setStyles

            metinSecButton.fontSize = 14;
            metinSecButton.wordWrap = true;
            metinSecButton.stretchHeight = true;

            boldButton.fontSize = 16;
            boldButton.fontStyle = FontStyle.Bold;
            boldButton.wordWrap = true;
            boldButton.stretchHeight = true;

            labelHeadline1.fontSize = 16;
            labelHeadline1.fontStyle = FontStyle.Bold;

            labelHeadline2.fontSize = 12;
            labelHeadline2.fontStyle = FontStyle.Bold;

            labelRegularRight.alignment = TextAnchor.UpperRight;
            labelRegularRight.stretchWidth = true;

            secenekSilButtonStyle = new GUIStyle(GUI.skin.button);
            secenekSilButtonStyle.normal.textColor = new Color(255f / 255f, 60f / 255f, 70f / 255f);
            secenekSilButtonStyle.fontStyle = FontStyle.Bold;

            secenekEkleButtonStyle = new GUIStyle(GUI.skin.button);
            secenekEkleButtonStyle.normal.textColor = new Color(60f / 255f, 255f / 255f, 70f / 255f);
            secenekEkleButtonStyle.fontStyle = FontStyle.Bold;
            secenekEkleButtonStyle.fontSize = 13;

            aciklamaTextArea = new GUIStyle(GUI.skin.textArea);

            #endregion

            showCevap = new List<bool>();
            showCevapGerekenDegiskenler = new List<bool>();
            showCevapayarlananDegiskenler = new List<bool>();
            showCevapVaryasyonlari = new List<bool>();

            if (sohbet.cevaplar != null)
            {
                while (showCevap.Count < sohbet.cevaplar.Count)
                {
                    showCevap.Add(true);
                    showCevapGerekenDegiskenler.Add(true);
                    showCevapayarlananDegiskenler.Add(true);
                    showCevapVaryasyonlari.Add(true);
                }
            }
        }

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("Diğer görünüm"))
        {
            if (gorunum == 0)
            {
                gorunum = 1;
            }
            else
            {
                gorunum = 0;
            }
        }
        if (GUILayout.Button("Sohbeti kopyala"))
        {
            CreateCopyOfSohbet(0);
        }
        if (GUILayout.Button("Açıklamaları ayır"))
        {
            AciklamalardanSohbetOlustur();
        }
        EditorGUILayout.LabelField("Sohbet Id: " + sohbet.idIndex.ToString(), labelRegularRight);
        EditorGUILayout.EndHorizontal();

        panelAciklamaRender = EditorGUILayout.BeginFoldoutHeaderGroup(panelAciklamaRender, "Aciklamayi Renderla");
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorStyles.label.wordWrap = true;

        if (panelAciklamaRender)
        {
            foreach (string aciklama in renderlananAciklamalar)
            {
                EditorGUILayout.LabelField(aciklama);
            }

            if (GUILayout.Button("Renderla"))
            {
                ChatVariables chatVariables = FindObjectOfType<ChatVariables>();
                if (chatVariables == null)
                    return;

                renderlananAciklamalar = new List<string>(sohbet.aciklama);

                for(int i = 0; i<renderlananAciklamalar.Count; i++)
                {
                    renderlananAciklamalar[i] = chatVariables.OrtakButonlar(renderlananAciklamalar[i]);
                }
            }
        }

        if (gorunum == 1)
        {
            PanelAnamenu();
            PanelButonlar();
            PanelDataButonu();
            PanelMetinSec();
            PanelSayiGir();
            PanelAralikliSayiGir();
            PanelSayiyaGoreKelimeSec();
            PanelKelimeButonu();

            EditorGUILayout.Space(10);
            GUIStyle foldoutStyle = EditorStyles.foldoutHeader;
            foldoutStyle.stretchWidth = true;
            foldoutStyle.fontSize = 16;


            if (showAciklama)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showAciklama = EditorGUILayout.Foldout(showAciklama, "Açıklamalar", foldoutStyle);
            EditorGUILayout.EndHorizontal();
            if (showAciklama)
            {
                sohbet.aciklama = StringArrayField("0|", sohbet.aciklama, 50);
            }
            //EditorGUILayout.PropertyField(aciklama);
            EditorGUILayout.Space(20);

            if (showCevaplar)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showCevaplar = EditorGUILayout.Foldout(showCevaplar, "Cevaplar", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showCevaplar)
            {
                foldoutStyle.fontSize = 13;
                for (int i = 0; i < sohbet.cevaplar.Count; i++)
                {
                    //Eğer silinen cevap seçeneği ctr+z islemi ile geri alinmissa bu listeler sohbetteki cevap sayisindan kucuk kalacağı için bu sorgulama yapılır.
                    while (showCevap.Count < sohbet.cevaplar.Count)
                    {
                        showCevap.Add(true);
                    }

                    while (showCevapVaryasyonlari.Count < sohbet.cevaplar.Count)
                    {
                        showCevapVaryasyonlari.Add(true);
                    }

                    while (showCevapayarlananDegiskenler.Count < sohbet.cevaplar.Count)
                    {
                        showCevapayarlananDegiskenler.Add(true);
                    }

                    while (showCevapGerekenDegiskenler.Count < sohbet.cevaplar.Count)
                    {
                        showCevapGerekenDegiskenler.Add(true);
                    }

                    //EditorGUILayout.LabelField("Cevap Seçeneği " + (i + 1).ToString());
                    EditorGUILayout.BeginHorizontal("box");
                    GUILayout.Space(10);

                    showCevap[i] = EditorGUILayout.Foldout(showCevap[i], "Cevap Seçeneği " + (i + 1).ToString(), foldoutStyle);

                    EditorGUILayout.EndHorizontal();
                    if (showCevap[i])
                    {
                        EditorGUILayout.BeginHorizontal();
                        GUILayout.Space(10);
                        Rect r = EditorGUILayout.BeginHorizontal("Button");
                        if (GUI.Button(r, GUIContent.none))
                        {
                            if (showCevapVaryasyonlari[i])
                                showCevapVaryasyonlari[i] = false;
                            else
                                showCevapVaryasyonlari[i] = true;
                        }
                        GUILayout.Space(10);
                        showCevapVaryasyonlari[i] = EditorGUILayout.Foldout(showCevapVaryasyonlari[i], "Cevap varyasyonları ");
                        EditorGUILayout.EndHorizontal();
                        EditorGUILayout.EndHorizontal();
                        if (showCevapVaryasyonlari[i])
                            sohbet.cevaplar[i].cevapVaryasyonlari = StringArrayField((i + 1).ToString() + "|", sohbet.cevaplar[i].cevapVaryasyonlari, 50);

                        EditorGUILayout.BeginHorizontal("box");
                        sohbet.cevaplar[i].contentImage.image = (Sprite)EditorGUILayout.ObjectField(sohbet.cevaplar[i].contentImage.image, typeof(Sprite), false, GUILayout.Height(50), GUILayout.Width(50));
                        sohbet.balonTipi = (Sohbet.typeOfAnswerBubble)EditorGUILayout.EnumPopup(sohbet.balonTipi);
                        EditorGUILayout.EndHorizontal();


                        sohbet.cevaplar[i].sonrakiSohbetHavuzu = (Sohbet)EditorGUILayout.ObjectField("Sonraki sohbet", sohbet.cevaplar[i].sonrakiSohbetHavuzu, typeof(Sohbet), false);


                        EditorGUILayout.BeginHorizontal();
                        EditorGUILayout.Space(10, false);
                        showCevapayarlananDegiskenler[i] = EditorGUILayout.Foldout(showCevapayarlananDegiskenler[i], "Ayarlanacak değişkenler (Cevap seçeneği " + (i + 1).ToString() + ")", foldoutStyle);
                        EditorGUILayout.EndHorizontal();
                        if (showCevapayarlananDegiskenler[i])
                        {
                            for (int b = 0; b < sohbet.cevaplar[i].ayarlananDegiskenler.Count; b++)
                            {
                                EditorGUILayout.BeginHorizontal("box");

                                EditorGUILayout.BeginVertical("box");
                                EditorGUILayout.LabelField("Değişken adı", GUILayout.Width(150));
                                sohbet.cevaplar[i].ayarlananDegiskenler[b].degiskenAdi = EditorGUILayout.TextField(sohbet.cevaplar[i].ayarlananDegiskenler[b].degiskenAdi, GUILayout.Height(25));
                                EditorGUILayout.EndVertical();

                                EditorGUILayout.BeginVertical("box");
                                EditorGUILayout.LabelField("Değişken değeri", GUILayout.Width(150));
                                sohbet.cevaplar[i].ayarlananDegiskenler[b].degiskenDegeri = EditorGUILayout.TextField(sohbet.cevaplar[i].ayarlananDegiskenler[b].degiskenDegeri, GUILayout.Height(25));
                                EditorGUILayout.EndVertical();

                                if (GUILayout.Button("-", GUILayout.Width(20)))
                                {
                                    EditorGUI.FocusTextInControl(null);
                                    List<Sohbet.AyarlanacakDegisken> old = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[sohbet.cevaplar[i].ayarlananDegiskenler.Count - 1]);

                                    int indexDif = 0;
                                    for (int u = 0; u < old.Count; u++)
                                    {
                                        if (u == b)
                                        {
                                            indexDif = 1;
                                        }
                                        old[u] = sohbet.cevaplar[i].ayarlananDegiskenler[u + indexDif];
                                    }
                                    sohbet.cevaplar[i].ayarlananDegiskenler = old;
                                }

                                EditorGUILayout.EndHorizontal();
                            }
                            if (GUILayout.Button("+", secenekEkleButtonStyle, GUILayout.Width(50)))
                            {
                                List<Sohbet.AyarlanacakDegisken> old = new List<Sohbet.AyarlanacakDegisken>(new Sohbet.AyarlanacakDegisken[sohbet.cevaplar[i].ayarlananDegiskenler.Count + 1]);
                                for (int b = 0; b < old.Count; b++)
                                {
                                    if (b != old.Count - 1)
                                    {
                                        old[b] = sohbet.cevaplar[i].ayarlananDegiskenler[b];
                                    }
                                    else
                                    {
                                        old[b] = new Sohbet.AyarlanacakDegisken();
                                    }
                                }
                                sohbet.cevaplar[i].ayarlananDegiskenler = old;
                            }
                        }

                        EditorGUILayout.BeginHorizontal();
                        EditorGUILayout.Space(10, false);
                        showCevapGerekenDegiskenler[i] = EditorGUILayout.Foldout(showCevapGerekenDegiskenler[i], "Gereken değişkenler (Cevap seçeneği " + (i + 1).ToString() + ")", foldoutStyle);
                        EditorGUILayout.EndHorizontal();
                        if (showCevapGerekenDegiskenler[i])
                        {
                            for (int b = 0; b < sohbet.cevaplar[i].gerekliDegiskenler.Count; b++)
                            {
                                EditorGUILayout.BeginHorizontal("box");

                                EditorGUILayout.BeginVertical("box");
                                EditorGUILayout.LabelField("Değişken adı", GUILayout.Width(150));
                                sohbet.cevaplar[i].gerekliDegiskenler[b].degiskenAdi = EditorGUILayout.TextField(sohbet.cevaplar[i].gerekliDegiskenler[b].degiskenAdi, GUILayout.Height(25));
                                EditorGUILayout.EndVertical();

                                EditorGUILayout.BeginVertical("box");
                                EditorGUILayout.LabelField("Değişken değeri", GUILayout.Width(150));
                                sohbet.cevaplar[i].gerekliDegiskenler[b].degiskenDegeri = EditorGUILayout.TextField(sohbet.cevaplar[i].gerekliDegiskenler[b].degiskenDegeri, GUILayout.Height(25));
                                EditorGUILayout.EndVertical();

                                if (GUILayout.Button("-", secenekSilButtonStyle, GUILayout.Width(20)))
                                {
                                    EditorGUI.FocusTextInControl(null);
                                    List<Sohbet.GerekenDegisken> old = new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[sohbet.cevaplar[i].gerekliDegiskenler.Count - 1]);

                                    int indexDif = 0;
                                    for (int u = 0; u < old.Count; u++)
                                    {
                                        if (u == b)
                                        {
                                            indexDif = 1;
                                        }
                                        old[u] = sohbet.cevaplar[i].gerekliDegiskenler[u + indexDif];
                                    }
                                    sohbet.cevaplar[i].gerekliDegiskenler = old;
                                }

                                EditorGUILayout.EndHorizontal();
                            }

                            if (GUILayout.Button("+", secenekEkleButtonStyle, GUILayout.Width(50)))
                            {
                              List<Sohbet.GerekenDegisken> old = new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[sohbet.cevaplar[i].gerekliDegiskenler.Count + 1]);
                                for (int b = 0; b < old.Count; b++)
                                {
                                    if (b != old.Count - 1)
                                    {
                                        old[b] = sohbet.cevaplar[i].gerekliDegiskenler[b];
                                    }
                                    else
                                    {
                                        old[b] = new Sohbet.GerekenDegisken();
                                    }
                                }
                                sohbet.cevaplar[i].gerekliDegiskenler = old;
                            }
                        }
                        string cevapSecenegiSilButtonText = "SİL | " + " Cevap seçeneği " + (i + 1).ToString() + " (Çift tık)";
                        if (deletable)
                        {
                            cevapSecenegiSilButtonText = "Silmek için tekrar tıkla";
                        }

                        if (GUILayout.Button(cevapSecenegiSilButtonText, secenekSilButtonStyle))
                        {
                            if (deletable)
                            {
                                EditorGUI.FocusTextInControl(null);
                                List<CevapSohbet> old = new List<CevapSohbet>(new CevapSohbet[sohbet.cevaplar.Count - 1]);

                                int indexDif = 0;
                                for (int u = 0; u < old.Count; u++)
                                {
                                    if (u == i)
                                    {
                                        indexDif = 1;
                                    }
                                    old[u] = sohbet.cevaplar[u + indexDif];
                                }
                                sohbet.cevaplar = old;
                                showCevap.RemoveAt(i);
                                showCevapGerekenDegiskenler.RemoveAt(i);
                                showCevapayarlananDegiskenler.RemoveAt(i);
                                showCevapVaryasyonlari.RemoveAt(i);
                            }
                            else
                            {
                                SetDeletable();
                            }
                        }
                        GUILayout.Space(50);
                    }
                }
                if (GUILayout.Button("Cevap seçeneği ekle", secenekEkleButtonStyle))
                {
                    List<CevapSohbet> old = new List<CevapSohbet>(new CevapSohbet[sohbet.cevaplar.Count + 1]);
                    for (int i = 0; i < old.Count; i++)
                    {
                        if (i != old.Count - 1)
                        {
                            old[i] = sohbet.cevaplar[i];
                        }
                        else
                        {
                            old[i] = new CevapSohbet();
                        }
                    }
                    sohbet.cevaplar = old;
                    showCevap.Add(true);
                    showCevapGerekenDegiskenler.Add(true);
                    showCevapayarlananDegiskenler.Add(true);
                    showCevapVaryasyonlari.Add(true);
                }
            }
            EditorGUILayout.Space(20);

            if (showFotgrafOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showFotgrafOzellikleri = EditorGUILayout.Foldout(showFotgrafOzellikleri, "Fotoğraf ve özellikleri", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showFotgrafOzellikleri)
            {
                EditorGUILayout.BeginHorizontal("box");
                sohbet.contentPhoto = (Sprite)EditorGUILayout.ObjectField(sohbet.contentPhoto, typeof(Sprite), false, GUILayout.Height(50), GUILayout.Width(50));
                sohbet.fotografKonum = (Sohbet.contentPhotoLocation)EditorGUILayout.EnumPopup(sohbet.fotografKonum);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.Space(20);

            if (showBirlestirilecekModlar)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showBirlestirilecekModlar = EditorGUILayout.Foldout(showBirlestirilecekModlar, "Birleştirilecek modlar", foldoutStyle);
            EditorGUILayout.EndHorizontal();
            if (showBirlestirilecekModlar)
            {
                sohbet.birlestirilecekModlar = StringArrayField("birlestirilecekmodlar", sohbet.birlestirilecekModlar);
            }
            EditorGUILayout.Space(20);

            if (showGerekenDegiskenler)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showGerekenDegiskenler = EditorGUILayout.Foldout(showGerekenDegiskenler, "Gereken değişkenler", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showGerekenDegiskenler)
            {
                for (int i = 0; i < sohbet.gerekliDegiskenler.Count; i++)
                {

                    EditorGUILayout.BeginHorizontal("box");

                    EditorGUILayout.BeginVertical("box");
                    EditorGUILayout.LabelField("Değişken adı", GUILayout.Width(150));
                    sohbet.gerekliDegiskenler[i].degiskenAdi = EditorGUILayout.TextField(sohbet.gerekliDegiskenler[i].degiskenAdi, GUILayout.Height(25));
                    EditorGUILayout.EndVertical();

                    EditorGUILayout.BeginVertical("box");
                    EditorGUILayout.LabelField("Değişken değeri", GUILayout.Width(150));
                    sohbet.gerekliDegiskenler[i].degiskenDegeri = EditorGUILayout.TextField(sohbet.gerekliDegiskenler[i].degiskenDegeri, GUILayout.Height(25));
                    EditorGUILayout.EndVertical();

                    if (GUILayout.Button("-", secenekSilButtonStyle, GUILayout.Width(20)))
                    {
                        EditorGUI.FocusTextInControl(null);
                        List<Sohbet.GerekenDegisken> old = new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[sohbet.gerekliDegiskenler.Count - 1]);
                        int indexDif = 0;
                        for (int u = 0; u < old.Count; u++)
                        {
                            if (u == i)
                            {
                                indexDif = 1;
                            }
                            old[u] = sohbet.gerekliDegiskenler[u + indexDif];
                        }
                        sohbet.gerekliDegiskenler = old;
                    }

                    EditorGUILayout.EndHorizontal();
                }
                if (GUILayout.Button("+", secenekEkleButtonStyle, GUILayout.Width(50)))
                {
                    List<Sohbet.GerekenDegisken> old = new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[sohbet.gerekliDegiskenler.Count + 1]);
                    for (int i = 0; i < old.Count; i++)
                    {
                        if (i != old.Count - 1)
                        {
                            old[i] = sohbet.gerekliDegiskenler[i];
                        }
                        else
                        {
                            old[i] = new Sohbet.GerekenDegisken();
                        }
                    }
                    sohbet.gerekliDegiskenler = old;
                }
            }
            EditorGUILayout.Space(20);

            if (showYoksayOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showYoksayOzellikleri = EditorGUILayout.Foldout(showYoksayOzellikleri, "Sohbeti yoksayma", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showYoksayOzellikleri)
            {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Yoksayma değişkeni", GUILayout.Width(130));
                sohbet.yokSayDegiskeni = EditorGUILayout.TextField(sohbet.yokSayDegiskeni);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(5, false);
                sohbet.yokSayilmaSohbeti = (Sohbet)EditorGUILayout.ObjectField("Yoksayilma sohbeti", sohbet.yokSayilmaSohbeti, typeof(Sohbet), false);
            }
            EditorGUILayout.Space(20);


            if (showSayacOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showSayacOzellikleri = EditorGUILayout.Foldout(showSayacOzellikleri, "Sayaç özellikleri", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showSayacOzellikleri)
            {
                EditorGUILayout.Space(5, false);
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Sayaç süresi", GUILayout.Width(200));
                sohbet.sayac = EditorGUILayout.IntField(sohbet.sayac);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(5, false);
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Sayaç görünümü", GUILayout.Width(200));
                sohbet.sayacTipi = (Sohbet.sayacTipiEnum)EditorGUILayout.EnumPopup(sohbet.sayacTipi);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(5, false);
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Sayaç sohbeti", GUILayout.Width(200));
                sohbet.sayacSohbeti = (Sohbet)EditorGUILayout.ObjectField(sohbet.sayacSohbeti, typeof(Sohbet), false);
                EditorGUILayout.EndHorizontal();

                if (sohbet.sayacSohbeti == null)
                {
                    if (!sohbet.sayaSonuAnaMenuyeGit)
                    {
                        EditorGUILayout.Space(5, false);
                        EditorGUILayout.BeginHorizontal();
                        EditorGUILayout.LabelField("Sayaç modu", GUILayout.Width(200));
                        sohbet.sayacModu = EditorGUILayout.TextField(sohbet.sayacModu, GUILayout.Height(25));
                        EditorGUILayout.EndHorizontal();
                    }

                    EditorGUILayout.Space(5, false);
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField("Süre bitince anamenüye dön", GUILayout.Width(200));
                    sohbet.sayaSonuAnaMenuyeGit = EditorGUILayout.Toggle(sohbet.sayaSonuAnaMenuyeGit);
                    EditorGUILayout.EndHorizontal();
                }
            }
            EditorGUILayout.Space(20);

            if (showTekrarlamaOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showTekrarlamaOzellikleri = EditorGUILayout.Foldout(showTekrarlamaOzellikleri, "Sohbetin tekrarlanışı", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showTekrarlamaOzellikleri)
            {
                EditorGUILayout.Space(5);
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Tekralama", GUILayout.Width(100));
                sohbet.tekrarlama = (Sohbet.sohbetTekrarlama)EditorGUILayout.EnumPopup(sohbet.tekrarlama);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.Space(20);

            if (showSohbetBitimiOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showSohbetBitimiOzellikleri = EditorGUILayout.Foldout(showSohbetBitimiOzellikleri, "Sohbet bitimi özellikleri", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showSohbetBitimiOzellikleri)
            {
                EditorGUILayout.Space(5, false);

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Sohbet bitimi modu", GUILayout.Width(200));
                sohbet.sohbetBitimModu = EditorGUILayout.TextField(sohbet.sohbetBitimModu, GUILayout.Height(25));
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Sohbet bitiminde anamenüye dön", GUILayout.Width(200));
                sohbet.sohbetBititmindeAnamenuyeDon = EditorGUILayout.Toggle(sohbet.sohbetBititmindeAnamenuyeDon);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.Space(20);

            if (showEnerjiOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showEnerjiOzellikleri = EditorGUILayout.Foldout(showEnerjiOzellikleri, "Enerji", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showEnerjiOzellikleri)
            {
                EditorGUILayout.Space(5, false);

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Eklenecek enerji miktarı", GUILayout.Width(200));
                sohbet.sohbetEnerjisi = EditorGUILayout.IntField(sohbet.sohbetEnerjisi);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Eklenecek konsantrasyon miktarı", GUILayout.Width(200));
                sohbet.sohbetKonsantrasyonu = EditorGUILayout.IntField(sohbet.sohbetKonsantrasyonu);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.Space(20);

            if (showSecenekOzellikleri)
                foldoutStyle.fontSize = 20;
            else
                foldoutStyle.fontSize = 16;
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.Space(10, false);
            showSecenekOzellikleri = EditorGUILayout.Foldout(showSecenekOzellikleri, "Diğer özellikler", foldoutStyle);
            EditorGUILayout.EndHorizontal();

            if (showSecenekOzellikleri)
            {
                EditorGUILayout.Space(5, false);

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Ana menüye dön seçeneği oluştur", GUILayout.Width(250));
                sohbet.anaMenuyeGitButonuOlustur = EditorGUILayout.Toggle(sohbet.anaMenuyeGitButonuOlustur);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Açıklamaya otomatik odaklan", GUILayout.Width(250));
                sohbet.otomatikOdak = EditorGUILayout.Toggle(sohbet.otomatikOdak);
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Metni kaydet", GUILayout.Width(250));
                sohbet.metniKaydet = EditorGUILayout.Toggle(sohbet.metniKaydet);
                EditorGUILayout.EndHorizontal();
            }

            /*
            EditorGUILayout.Space(5);
            if (sohbet.sayacSohbeti == null)
            {
                if (!sohbet.sohbetBititmindeAnamenuyeDon)
                {
                    if (sohbet.sayacModu.Replace(" ", "") == "")
                    {
                        EditorGUILayout.HelpBox("Bu sohbetin sonunda sohbetten önceki mod ne ise o mod ile aramaya devam edilecek.", MessageType.Error);
                    }
                    else
                    {
                        EditorGUILayout.HelpBox("Bu sohbetin sonunda \"" + sohbet.sayacModu + "\" modu ile arama yapılacak.", MessageType.Info);
                    }
                }
                else
                {
                    if (sohbet.sayaSonuAnaMenuyeGit)
                    {
                        EditorGUILayout.HelpBox("Bu sohbetin sonunda anamenüye giderek devam edilecek.", MessageType.Warning);
                    }
                }
            }
            else
            {
                EditorGUILayout.HelpBox("Bu sohbetin sonunda \"" + sohbet.sayacSohbeti.name + "\" adlı sohbet ile devam edilecek.", MessageType.Info);
            }*/
            Undo.RecordObject(sohbet, "sohbet" + sohbet.idIndex.ToString());

            //base.DrawDefaultInspector();

            foldoutStyle.fontSize = 12;
        }
        else
        {
            base.DrawDefaultInspector();
        }
    }

    void CreateCopyOfSohbet(int index)
    {
        var clone = Instantiate(sohbet);
        clone.idIndex = "-1";

        ProjectWindowUtil.CreateAsset(clone, sohbet.name + ".asset");
    }

    void AciklamalardanSohbetOlustur()
    {
        if (sohbet.aciklama != null)
        {
            if (sohbet.aciklama.Count > 0)
            {
                for (int i = 1; i < sohbet.aciklama.Count; i++)
                {
                    var clone = Instantiate(sohbet);
                    clone.idIndex = "-1";

                    clone.aciklama =new List<string>(new string[1]);
                    clone.aciklama[0] = sohbet.aciklama[i];

                    ProjectWindowUtil.CreateAsset(clone, sohbet.name + ".asset");
                }

                string newAciklama = sohbet.aciklama[0];
                sohbet.aciklama = new List<string>(new string[1]);
                sohbet.aciklama[0] = newAciklama;
            }
        }
    }

   async void PanelAnamenu()
    {
        GUIStyle buttonStyle = new GUIStyle(EditorStyles.miniButton);
        if (menuState == "veriGirisi")
        {
            EditorGUILayout.BeginHorizontal();

            if (!GUI.GetNameOfFocusedControl().Contains("|"))
            {
                buttonStyle.normal.textColor = new Color(255f / 255f, 210f / 255f, 210f / 255f);
            }
            if (GUI.GetNameOfFocusedControl().Contains("|"))
            {
                buttonStyle.normal.textColor = new Color(buttonStyle.normal.textColor.r, buttonStyle.normal.textColor.g, buttonStyle.normal.textColor.b, 1f);
            }
            if (GUILayout.Button("İsim", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isim");
                }
            }
            if (GUILayout.Button("İsimciğim", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isimcigim");
                }
            }
            if (GUILayout.Button("İsim Hanım/Bey", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isim hanim/bey");
                }
            }
            if (GUILayout.Button("İsimi", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);
        
                    PanelKelimeButonlari("isimi");
                }
            }
            if (GUILayout.Button("İsime", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isime");
                }
            }
            if (GUILayout.Button("İsimde", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);
             
                    PanelKelimeButonlari("isimde");
                }
            }
            if (GUILayout.Button("İsimden", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);
            
                    PanelKelimeButonlari("isimden");
                }
            }
            if (GUILayout.Button("İsimsin", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isimsin");
                }
            }
            if (GUILayout.Button("İsimdin", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isimdin");
                }
            }
            if (GUILayout.Button("İsim ilk", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isimilk");
                }
            }
            if (GUILayout.Button("İsim iki", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isimiki");
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("İsim Son", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isimson");
                }
            }
            if (GUILayout.Button("Soyisim", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("soyisim");
                }
            }
            if (GUILayout.Button("Soyisim ilk", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("soyisimilk");
                }
            }
            if (GUILayout.Button("Soyisim iki", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("soyisimiki");
                }
            }
            if (GUILayout.Button("Soyisim Son", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("soyisimson");
                }
            }
            if (GUILayout.Button("İsmHsys", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isim harf");
                }
            }
            if (GUILayout.Button("İsmSesszHsys", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isim sessiz harf");
                }
            }
            if (GUILayout.Button("İsmSesliHsys", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("isim sesli harf");
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Doğum günü", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "dogum gunu_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Doğum günü (yazı)", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "dogum gunu yazi_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Doğum ayı", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "dogum ayi_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Doğum ayı (yazı)", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "dogum ayi yazi_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Doğum yılı", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "dogum yili_";
                    menuState = "sayiGir";
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Burç", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("burc");
                }
            }
            if (GUILayout.Button("Burçluğunu", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("burclugunu");
                }
            }
            if (GUILayout.Button("Medeni durum", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("medeni durum");
                }
            }
            if (GUILayout.Button("Meslek", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("meslek");
                }
            }
            if (GUILayout.Button("Cinsiyet", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("cinsiyet");
                }
            }
            if (GUILayout.Button("Yaş", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "yas_";
                    menuState = "sayiGir";
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Gün", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "gunsayi_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Gün (yazı)", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "gun_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Ay", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "aysayi_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Ay (yazı)", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "ay_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Yıl", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "yil_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Mevsim", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "mevsim_";
                    menuState = "sayiGir";
                }
            }
            if (GUILayout.Button("Geçen ay", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("gecen_ay");
                }
            }
            if (GUILayout.Button("Şimdiki ay", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("simdiki_ay");
                }
            }
            if (GUILayout.Button("Gelecek ay", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("gelecek_ay");
                }
            }


            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Harf", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("harf");
                }
            }
            if (GUILayout.Button("Sabit harf", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("sabit_harf");
                }
            }
            if (GUILayout.Button("Sayı", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "sayi,";
                    menuState = "aralikliSayiGir";
                }
            }
            if (GUILayout.Button("Sabit sayı", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    sayiButonuAdi = "sabit_sayi,";
                    menuState = "aralikliSayiGir";
                }
            }
            if (GUILayout.Button("Rastgele burç", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("rastgeleburc");
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("DoğalıXgündür", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("xgundur");
                }
            }
            if (GUILayout.Button("Kaç gün tanışma", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("kac gun tanisma");
                }
            }
            if (GUILayout.Button("Tanışma tarihi", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("tanisma tarihi");
                }
            }
            if (GUILayout.Button("Saat kaç", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("saat kac");
                }
            }
            if (GUILayout.Button("Saat kaç yazı", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    PanelKelimeButonlari("saat kac yazi");
                }
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Data", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    dataButonu = new List<DataButonu>();
                    dataButonu.Add(new DataButonu());
                    menuState = "dataButonu";
                }
            }
            if (GUILayout.Button("Kelime", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    kelimeAciklama = new List<string>();
                    kelimeAciklama.Add("");
                    kelimeAciklama.Add("");
                    menuState = "kelimeButonu";
                }
            }
            if (GUILayout.Button("Saatli cümle", buttonStyle))
            {
                if (GUI.GetNameOfFocusedControl().Contains("|"))
                {
                    focusedTextBoxId = GUI.GetNameOfFocusedControl();

                    EditorGUI.FocusTextInControl(null);

                    menuState = "saateGoreKelimeSec";
                }
            }
            EditorGUILayout.EndHorizontal();
            //base.OnInspectorGUI();
        }
    }

    void PanelButonlar()
    {
        if (menuState == "butonlar")
        {
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Data"))
            {
                menuState = "dataButonu";

                
                //secilenArrayIndex = i;
                EditorGUI.FocusTextInControl(null);
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(10);
            if (GUILayout.Button("Geri", boldButton))
            {
                menuState = "metinSec";

                //secilenArrayIndex = i;
                EditorGUI.FocusTextInControl(null);
            }
        }
    }

    void PanelDataButonu()
    {
        if (menuState == "dataButonu")
        {
            EditorStyles.textField.wordWrap = true; // This sets the wordwrap value of the property

            foreach(DataButonu element in dataButonu)
            {
                for (int i = 0; i<element.degisken.Count; i++)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUIUtility.labelWidth = 1;
                    EditorGUILayout.LabelField("Değişken adı: ");
                    element.degisken[i].degiskenAdi = EditorGUILayout.TextField(element.degisken[i].degiskenAdi, GUILayout.Height(25));
                    EditorGUILayout.LabelField("Değişken değeri: ");
                    element.degisken[i].degiskenDegeri = EditorGUILayout.TextField(element.degisken[i].degiskenDegeri, GUILayout.Height(25));
                    EditorGUILayout.EndHorizontal();
                }
                EditorGUILayout.BeginHorizontal();
                GUILayout.Space(200);
                if (GUILayout.Button("-"))
                {
                    if (element.degisken.Count > 0)
                    {
                        element.degisken.RemoveAt(element.degisken.Count - 1);
                    }
                }
                if (GUILayout.Button("+"))
                {
                    element.degisken.Add(new Sohbet.AyarlanacakDegisken());
                }
                EditorGUILayout.EndHorizontal();

                element.Aciklama = EditorGUILayout.TextArea(element.Aciklama, EditorStyles.textArea, GUILayout.Height(70));
            }
            GUILayout.Space(20);

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("-"))
            {
                if (dataButonu.Count > 0)
                {
                    dataButonu.RemoveAt(dataButonu.Count - 1);
                }
            }
            if (GUILayout.Button("+"))
            {
                dataButonu.Add(new DataButonu());
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(10);
            if (GUILayout.Button("Ok", boldButton))
            {
                menuState = "veriGirisi";

                string text = "{{data, ";
                for (int u = 0; u < dataButonu.Count; u++)
                {
                    for (int i = 0; i < dataButonu[u].degisken.Count; i++)
                    {
                        text += dataButonu[u].degisken[i].degiskenAdi + "=" + dataButonu[u].degisken[i].degiskenDegeri;
                        if (i != dataButonu[u].degisken.Count - 1)
                            text += "+";
                        else
                            text += ", ";
                    }
                    text += dataButonu[u].Aciklama;
                    if (u != dataButonu.Count - 1)
                        text += " | ";
                    else
                        text += "}}";
                }

                char[] focusedTextCharArray = focusedTextBoxId.ToCharArray();

                int secilenList = -1;
                int secilenListVariation = -1;
                int startIndex = 0;
                for (int i = 0; i < focusedTextCharArray.Length; i++)
                {
                    if (focusedTextCharArray[i] == '|')
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                    else if (i == focusedTextCharArray.Length - 1)
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i + 1; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                }

                if (secilenList == 0)
                {
                    sohbet.aciklama[secilenListVariation] += text;
                }
                else
                {
                    sohbet.cevaplar[secilenList - 1].cevapVaryasyonlari[secilenListVariation] += text;
                }

                dataButonu = new List<DataButonu>();
                dataButonu.Add(new DataButonu());
                GUIUtility.keyboardControl = 0;
            }

            if (GUILayout.Button("Geri"))
            {
                menuState = "veriGirisi";
                GUIUtility.keyboardControl = 0;
            }
        }
    }

    void PanelKelimeButonu()
    {
        if (menuState == "kelimeButonu")
        {
            EditorStyles.textField.wordWrap = true; // This sets the wordwrap value of the property

            for (int i = 0; i<kelimeAciklama.Count; i++)
            {
                kelimeAciklama[i] = EditorGUILayout.TextArea(kelimeAciklama[i], EditorStyles.textArea, GUILayout.Height(70));
            }
            GUILayout.Space(20);

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("-"))
            {
                if (kelimeAciklama.Count > 0)
                {
                    kelimeAciklama.RemoveAt(kelimeAciklama.Count - 1);
                }
            }
            if (GUILayout.Button("+"))
            {
                kelimeAciklama.Add("");
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.Space(10);
            if (GUILayout.Button("Ok", boldButton))
            {
                menuState = "veriGirisi";

                string text = "{{kelime, ";
                for (int u = 0; u < kelimeAciklama.Count; u++)
                {
                    text += kelimeAciklama[u];
                    if (u != kelimeAciklama.Count - 1)
                        text += " | ";
                    else
                        text += "}}";
                }

                char[] focusedTextCharArray = focusedTextBoxId.ToCharArray();

                int secilenList = -1;
                int secilenListVariation = -1;
                int startIndex = 0;
                for (int i = 0; i < focusedTextCharArray.Length; i++)
                {
                    if (focusedTextCharArray[i] == '|')
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                    else if (i == focusedTextCharArray.Length - 1)
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i + 1; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                }

                if (secilenList == 0)
                {
                    sohbet.aciklama[secilenListVariation] += text;
                }
                else
                {
                    sohbet.cevaplar[secilenList - 1].cevapVaryasyonlari[secilenListVariation] += text;
                }

                GUIUtility.keyboardControl = 0;
            }

            if (GUILayout.Button("Geri"))
            {
                menuState = "veriGirisi";
                GUIUtility.keyboardControl = 0;
            }
        }
    }

    void PanelSayiyaGoreKelimeSec()
    {
        if (menuState == "saateGoreKelimeSec")
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Sabah", GUILayout.Width(100));
            saatCumle1 = EditorGUILayout.TextArea(saatCumle1, GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Öğle", GUILayout.Width(100));
            saatCumle2 = EditorGUILayout.TextArea(saatCumle2, GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("İkindi", GUILayout.Width(100));
            saatCumle3 = EditorGUILayout.TextArea(saatCumle3, GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Akşam", GUILayout.Width(100));
            saatCumle4 = EditorGUILayout.TextArea(saatCumle4, GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Gece", GUILayout.Width(100));
            saatCumle5 = EditorGUILayout.TextArea(saatCumle5, GUILayout.ExpandHeight(true));
            EditorGUILayout.EndHorizontal();

            if (GUILayout.Button("Tamam", secenekEkleButtonStyle))
            {
                if (saatCumle1.Replace(" ", "") != "" && saatCumle2.Replace(" ", "") != "" && saatCumle3.Replace(" ", "") != "" && saatCumle4.Replace(" ", "") != "" && saatCumle5.Replace(" ", "") != "")
                {
                    char[] focusedTextCharArray = focusedTextBoxId.ToCharArray();

                    int secilenList = -1;
                    int secilenListVariation = -1;
                    int startIndex = 0;
                    for (int i = 0; i < focusedTextCharArray.Length; i++)
                    {
                        if (focusedTextCharArray[i] == '|')
                        {
                            string numberString = "";
                            for (int u = startIndex; u < i; u++)
                            {
                                numberString += focusedTextCharArray[u].ToString();
                            }
                            if (secilenList == -1)
                            {
                                int.TryParse(numberString, out secilenList);
                            }
                            else
                            {
                                int.TryParse(numberString, out secilenListVariation);
                            }
                            startIndex = i + 1;
                        }
                        else if (i == focusedTextCharArray.Length - 1)
                        {
                            string numberString = "";
                            for (int u = startIndex; u < i + 1; u++)
                            {
                                numberString += focusedTextCharArray[u].ToString();
                            }
                            if (secilenList == -1)
                            {
                                int.TryParse(numberString, out secilenList);
                            }
                            else
                            {
                                int.TryParse(numberString, out secilenListVariation);
                            }
                            startIndex = i + 1;
                        }
                    }

                    if (secilenList == 0)
                    {
                        sohbet.aciklama[secilenListVariation] += "{{saat, " + saatCumle1 + " | " + saatCumle2 + " | " + saatCumle3 + " | " + saatCumle4 + " | " + saatCumle5 + "}}";
                    }
                    else
                    {
                        sohbet.cevaplar[secilenList - 1].cevapVaryasyonlari[secilenListVariation] += "{{saat, " + saatCumle1 + " | " + saatCumle2 + " | " + saatCumle3 + " | " + saatCumle4 + " | " + saatCumle5 + "}}";
                    }

                    saatCumle1 = "";
                    saatCumle2 = "";
                    saatCumle3 = "";
                    saatCumle4 = "";
                    saatCumle5 = "";
                    menuState = "veriGirisi";
                    GUIUtility.keyboardControl = 0;
                }
            }

            if (GUILayout.Button("Geri"))
            {
                saatCumle1 = "";
                saatCumle2 = "";
                saatCumle3 = "";
                saatCumle4 = "";
                saatCumle5 = "";
                menuState = "veriGirisi";
                GUIUtility.keyboardControl = 0;
            }

            EditorGUILayout.Space(50);
        }
    }

    void PanelSayiGir()
    {
        if (menuState == "sayiGir")
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Sayı gir:", GUILayout.Width(50));
            sayiButonuSayi = EditorGUILayout.IntField(sayiButonuSayi);
            EditorGUILayout.EndHorizontal();

            if (GUILayout.Button("Tamam", secenekEkleButtonStyle))
            {
                GUIUtility.keyboardControl = 0;
                char[] focusedTextCharArray = focusedTextBoxId.ToCharArray();

                int secilenList = -1;
                int secilenListVariation = -1;
                int startIndex = 0;
                for (int i = 0; i < focusedTextCharArray.Length; i++)
                {
                    if (focusedTextCharArray[i] == '|')
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                    else if (i == focusedTextCharArray.Length - 1)
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i + 1; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                }

                if (secilenList == 0)
                {
                    sohbet.aciklama[secilenListVariation] += "{{" + sayiButonuAdi + sayiButonuSayi + "}}";
                }
                else
                {
                    sohbet.cevaplar[secilenList - 1].cevapVaryasyonlari[secilenListVariation] += "{{" + sayiButonuAdi + sayiButonuSayi + "}}";
                }

                sayiButonuSayi = 0;
                sayiButonuAdi = "";
                menuState = "veriGirisi";

                GUIUtility.keyboardControl = 0;
            }

            if (GUILayout.Button("Geri"))
            {
                sayiButonuSayi = 0;
                menuState = "veriGirisi";
                GUIUtility.keyboardControl = 0;
            }

            EditorGUILayout.Space(50);
        }
    }

    void PanelAralikliSayiGir()
    {
        if (menuState == "aralikliSayiGir")
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("İlk sayıyı gir:", GUILayout.Width(100));
            aralikliSayiButonuSayi1 = EditorGUILayout.IntField(aralikliSayiButonuSayi1);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("İkinci sayıyı gir:", GUILayout.Width(100));
            aralikliSayiButonuSayi2 = EditorGUILayout.IntField(aralikliSayiButonuSayi2);
            EditorGUILayout.EndHorizontal();

            if (GUILayout.Button("Tamam", secenekEkleButtonStyle))
            {
                char[] focusedTextCharArray = focusedTextBoxId.ToCharArray();

                int secilenList = -1;
                int secilenListVariation = -1;
                int startIndex = 0;
                for (int i = 0; i < focusedTextCharArray.Length; i++)
                {
                    if (focusedTextCharArray[i] == '|')
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                    else if (i == focusedTextCharArray.Length - 1)
                    {
                        string numberString = "";
                        for (int u = startIndex; u < i + 1; u++)
                        {
                            numberString += focusedTextCharArray[u].ToString();
                        }
                        if (secilenList == -1)
                        {
                            int.TryParse(numberString, out secilenList);
                        }
                        else
                        {
                            int.TryParse(numberString, out secilenListVariation);
                        }
                        startIndex = i + 1;
                    }
                }

                if (secilenList == 0)
                {
                    sohbet.aciklama[secilenListVariation] += "{{" + sayiButonuAdi + aralikliSayiButonuSayi1 + "," + aralikliSayiButonuSayi2 + "}}";
                }
                else
                {
                    sohbet.cevaplar[secilenList - 1].cevapVaryasyonlari[secilenListVariation] += "{{" + sayiButonuAdi + aralikliSayiButonuSayi1 + "," + aralikliSayiButonuSayi2 + "}}";
                }

                aralikliSayiButonuSayi1 = 0;
                aralikliSayiButonuSayi2 = 0;
                aralikliSayiButonuAdi = "";
                menuState = "veriGirisi";
                GUIUtility.keyboardControl = 0;
            }

            if (GUILayout.Button("Geri"))
            {
                aralikliSayiButonuSayi1 = 0;
                aralikliSayiButonuSayi2 = 0;
                aralikliSayiButonuAdi = "";
                menuState = "veriGirisi";
                GUIUtility.keyboardControl = 0;
            }

            EditorGUILayout.Space(50);
        }
    }

    void PanelKelimeButonlari(string kelime)
    {
        string text = "{{"+kelime+"}}";

        char[] focusedTextCharArray = focusedTextBoxId.ToCharArray();

        int secilenList = -1;
        int secilenListVariation = -1;
        int startIndex = 0;
        for (int i = 0; i < focusedTextCharArray.Length; i++)
        {
            if (focusedTextCharArray[i] == '|')
            {
                string numberString = "";
                for (int u = startIndex; u < i; u++)
                {
                    numberString += focusedTextCharArray[u].ToString();
                }
                if (secilenList == -1)
                {
                    int.TryParse(numberString, out secilenList);
                }
                else
                {
                    int.TryParse(numberString, out secilenListVariation);
                }
                startIndex = i + 1;
            }
            else if (i == focusedTextCharArray.Length - 1)
            {
                string numberString = "";
                for (int u = startIndex; u < i + 1; u++)
                {
                    numberString += focusedTextCharArray[u].ToString();
                }
                if (secilenList == -1)
                {
                    int.TryParse(numberString, out secilenList);
                }
                else
                {
                    int.TryParse(numberString, out secilenListVariation);
                }
                startIndex = i + 1;
            }
        }

        if (secilenList == 0)
        {
            sohbet.aciklama[secilenListVariation] += text;
        }
        else
        {
            sohbet.cevaplar[secilenList - 1].cevapVaryasyonlari[secilenListVariation] += text;
        }

        GUIUtility.keyboardControl = 0;
    }

    void PanelMetinSec()
    {
        if (menuState == "metinSec")
        {
            EditorGUILayout.LabelField("Metin Seç", labelHeadline1);
            EditorGUILayout.Space(20);
            EditorGUILayout.LabelField("Açıklama");

            for (int i = 0; i < sohbet.aciklama.Count; i++)
            {
                if (GUILayout.Button(sohbet.aciklama[i], metinSecButton))
                {
                    menuState = "butonlar";

                    secilenList = 0;
                    secilenListVariation = i;

                    //secilenArrayIndex = i;
                    EditorGUI.FocusTextInControl(null);
                }
            }

            EditorGUILayout.Space(10);

            for (int i = 0; i < sohbet.cevaplar.Count; i++)
            {
                EditorGUILayout.LabelField("Seçenek");
                for (int u = 0; u < sohbet.cevaplar[i].cevapVaryasyonlari.Count; u++)
                {
                    if (GUILayout.Button(sohbet.cevaplar[i].cevapVaryasyonlari[u], metinSecButton))
                    {
                        menuState = "butonlar";
                        secilenList = i + 1;
                        secilenListVariation = u;
                        EditorGUI.FocusTextInControl(null);
                    }
                }
                EditorGUILayout.Space(2);
            }

            EditorGUILayout.Space(20);

            if (GUILayout.Button("Geri", boldButton))
            {
                menuState = "veriGirisi";
                //secilenArrayIndex = i;
                EditorGUI.FocusTextInControl(null);
            }
        }
    }

    public List<string> StringArrayField(string name, List<string> array)
    {
        for (int i = 0; i < array.Count; i++)
        {
            EditorGUILayout.BeginHorizontal("box");
            GUI.SetNextControlName(name + i.ToString());

            array[i] = EditorGUILayout.TextArea(array[i], EditorStyles.textArea, GUILayout.ExpandHeight(false));

            if (GUILayout.Button("-", secenekSilButtonStyle, GUILayout.Width(20)))
            {
                EditorGUI.FocusTextInControl(null);
                List<string> old = new List<string>(new string[array.Count - 1]);

                int indexDif = 0;
                for (int u = 0; u < old.Count; u++)
                {
                    if (u == i)
                    {
                        indexDif = 1;
                    }
                    old[u] = array[u + indexDif];
                }
                array = old;
            }
            EditorGUILayout.EndHorizontal();
        }

        if (GUILayout.Button("+", secenekEkleButtonStyle, GUILayout.Width(50)))
        {
            List<string> old = new List<string>(new string[array.Count + 1]);
            for (int i = 0; i < old.Count; i++)
            {
                if (i != old.Count - 1)
                {
                    old[i] = array[i];
                }
                else
                {
                    old[i] = "";
                }
            }
            array = old;
        }

        return array;
    }

    public List<string> StringArrayField(string name, List<string> array, int height)
    {
        for (int i = 0; i < array.Count; i++)
        {
            int scrollIndex = -1;
            for (int u = 0; u < scrollUsed.Count; u++)
            {
                if (!scrollUsed[u])
                {
                    scrollIndex = u;
                    scrollUsed[u] = true;
                    break;
                }
            }

            if(scrollIndex == -1)
            {
                scrollUsed.Add(true);
                scroll.Add(new Vector2());
                scrollIndex = scroll.Count - 1;
            }
            
          //  scroll[scrollIndex] = EditorGUILayout.BeginScrollView(scroll[scrollIndex], GUILayout.MinHeight(height));

            EditorGUILayout.BeginHorizontal("box");
            GUI.SetNextControlName(name + i.ToString());

            //array[i] = EditorGUILayout.TextArea(array[i]);

            var areaStyle = new GUIStyle(GUI.skin.textArea);
            areaStyle.wordWrap = true;
            var width = EditorGUIUtility.currentViewWidth - 80;

            areaStyle.fixedHeight = 0; // reset height, else CalcHeight gives wrong numbers
            areaStyle.fixedHeight = areaStyle.CalcHeight(new GUIContent(array[i]), width);
            if (areaStyle.fixedHeight < 80)
            {
                areaStyle.fixedHeight = 80;
            }
            array[i] = EditorGUILayout.TextArea(array[i], areaStyle, GUILayout.Height(areaStyle.fixedHeight), GUILayout.MaxWidth(width));


            if (GUILayout.Button("-", secenekSilButtonStyle, GUILayout.Width(20)))
            {
                EditorGUI.FocusTextInControl(null);
                List<string> old = new List<string>(new string[array.Count - 1]);

                int indexDif = 0;
                for (int u = 0; u < old.Count; u++)
                {
                    if (u == i)
                    {
                        indexDif = 1;
                    }
                    old[u] = array[u + indexDif];
                }
                array = old;
            }
          
            EditorGUILayout.EndHorizontal();

         //   EditorGUILayout.EndScrollView();

            EditorGUILayout.Space(3);
        }

        if (GUILayout.Button("+", secenekEkleButtonStyle, GUILayout.Width(50)))
        {
            List<string> old = new List<string>(new string[array.Count + 1]);
            for (int i = 0; i < old.Count; i++)
            {
                if (i != old.Count - 1)
                {
                    old[i] = array[i];
                }
                else
                {
                    old[i] = "";
                }
            }
            array = old;
        }

        return array;
    }

    async void SetDeletable()
    {
        deletable = true;
        await System.Threading.Tasks.Task.Delay(200);
        deletable = false;
    }
}

public class DataButonu
{
    public string Aciklama;
    public List<Sohbet.AyarlanacakDegisken> degisken;

    public DataButonu()
    {
        Aciklama = "";
        degisken = new List<Sohbet.AyarlanacakDegisken>();
        degisken.Add(new Sohbet.AyarlanacakDegisken());
    }
}
