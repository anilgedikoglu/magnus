using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.IO;
using System.Xml;
using UnityEditor;

public class xmlDeneme : MonoBehaviour
{
    public TextAsset xmlRawFile;
    void Start()
    {
        string data = xmlRawFile.text;
    }

    void Update()
    {
        
    }
    /*
    public void parseXmlFile (string xmlData, int index) 
    {
        XmlDocument xmlDoc = new XmlDocument();
        xmlDoc.Load(new StringReader(xmlData));

        string xmlPathPattern = "//pma_xml_export/database/table";
        XmlNodeList myNodeList = xmlDoc.SelectNodes(xmlPathPattern);

        XmlDocument xmlDoc2 = new XmlDocument();
        xmlDoc2.Load(new StringReader("<table>" + myNodeList[index].InnerXml + "</table>"));

        string xmlPathPattern2 = "//table/column";
        XmlNodeList myNodeList2 = xmlDoc2.SelectNodes(xmlPathPattern2);

        char[] rakamlar = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', };

        int mod = 0;
        string modString = myNodeList2[1].InnerText;
        char[] modCharArray = modString.ToCharArray();
        List<int> modList = new List<int>();

        for (int i = 0; i < modCharArray.Length; i++)
        {
            if (modCharArray[i] == ',')
            {
                string text = "";

                foreach(char elemnt in rakamlar)
                {
                    if (modCharArray.Length > 2 && i > 1)
                    {
                        if (modCharArray[i - 2] == elemnt)
                        {
                            text += modCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += modCharArray[i - 1].ToString();

                modList.Add(1);
                int.TryParse(text, out mod);
                modList[modList.Count - 1] = mod;
            }
            else if (i == modCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (modCharArray.Length > 1)
                    {
                        if (modCharArray[i - 1] == elemnt)
                        {
                            text += modCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += modCharArray[i].ToString();

                modList.Add(1);
                int.TryParse(text, out mod);
                modList[modList.Count - 1] = mod;
            }
        }

        int fal = 0;
        string falString = myNodeList2[2].InnerText;
        char[] falCharArray = falString.ToCharArray();
        List<int> falList = new List<int>();

        for (int i = 0; i < falCharArray.Length; i++)
        {
            if (falCharArray[i] == ',')
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (falCharArray.Length > 2 && i > 1)
                    {
                        if (falCharArray[i - 2] == elemnt)
                        {
                            text += falCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += falCharArray[i - 1].ToString();

                falList.Add(1);
                int.TryParse(text, out fal);
                falList[falList.Count - 1] = fal;
            }
            else if (i == falCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (falCharArray.Length > 1)
                    {
                        if (falCharArray[i - 1] == elemnt)
                        {
                            text += falCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += falCharArray[i].ToString();

                falList.Add(1);
                int.TryParse(text, out fal);
                falList[falList.Count - 1] = fal;
            }
        }

        int medeniDurum = 0;
        string medeniDurumString = myNodeList2[3].InnerText;
        char[] medeniDurumCharArray = medeniDurumString.ToCharArray();
        List<int> medeniDurumList = new List<int>();

        for (int i = 0; i < medeniDurumCharArray.Length; i++)
        {
            if (medeniDurumCharArray[i] == ',')
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (medeniDurumCharArray.Length > 2 && i > 1)
                    {
                        if (medeniDurumCharArray[i - 2] == elemnt)
                        {
                            text += medeniDurumCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += medeniDurumCharArray[i - 1].ToString();

                medeniDurumList.Add(1);
                int.TryParse(text, out medeniDurum);
                medeniDurumList[medeniDurumList.Count - 1] = medeniDurum;
            }
            else if (i == medeniDurumCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (medeniDurumCharArray.Length > 1)
                    {
                        if (medeniDurumCharArray[i - 1] == elemnt)
                        {
                            text += medeniDurumCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += medeniDurumCharArray[i].ToString();

                medeniDurumList.Add(1);
                int.TryParse(text, out medeniDurum);
                medeniDurumList[medeniDurumList.Count - 1] = medeniDurum;
            }
        }

        int cinsiyet = 0;
        string cinsiyetString = myNodeList2[4].InnerText;
        char[] cinsiyetCharArray = cinsiyetString.ToCharArray();
        List<int> cinsiyetList = new List<int>();

        for (int i = 0; i < cinsiyetCharArray.Length; i++)
        {
            if (cinsiyetCharArray[i] == ',')
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (cinsiyetCharArray.Length > 2 && i > 1)
                    {
                        if (cinsiyetCharArray[i - 2] == elemnt)
                        {
                            text += cinsiyetCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += cinsiyetCharArray[i - 1].ToString();

                cinsiyetList.Add(1);
                int.TryParse(text, out cinsiyet);
                cinsiyetList[cinsiyetList.Count - 1] = cinsiyet;
            }
            else if (i == cinsiyetCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (cinsiyetCharArray.Length > 1)
                    {
                        if (cinsiyetCharArray[i - 1] == elemnt)
                        {
                            text += cinsiyetCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += cinsiyetCharArray[i].ToString();

                cinsiyetList.Add(1);
                int.TryParse(text, out cinsiyet);
                cinsiyetList[cinsiyetList.Count - 1] = cinsiyet;
            }
        }

        int meslek = 0;
        string meslekString = myNodeList2[6].InnerText;
        char[] meslekCharArray = meslekString.ToCharArray();
        List<int> meslekList = new List<int>();

        for (int i = 0; i < meslekCharArray.Length; i++)
        {
            if (meslekCharArray[i] == ',')
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    Debug.Log(meslekCharArray.Length);
                    Debug.Log(i);
                    if (meslekCharArray.Length > 2 && i > 1)
                    {
                        if (meslekCharArray[i - 2] == elemnt)
                        {
                            text += meslekCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += meslekCharArray[i - 1].ToString();

                meslekList.Add(1);
                int.TryParse(text, out meslek);
                meslekList[meslekList.Count - 1] = meslek;
            }
            else if (i == meslekCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (meslekCharArray.Length > 1)
                    {
                        if (meslekCharArray[i - 1] == elemnt)
                        {
                            text += meslekCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += meslekCharArray[i].ToString();

                meslekList.Add(1);
                int.TryParse(text, out meslek);
                meslekList[meslekList.Count - 1] = meslek;
            }
        }

        int burc = 0;
        string burcString = myNodeList2[7].InnerText;
        char[] burcCharArray = burcString.ToCharArray();
        List<int> burcList = new List<int>();

        for (int i = 0; i < burcCharArray.Length; i++)
        {
            if (burcCharArray[i] == ',')
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (burcCharArray.Length > 2 && i > 1)
                    {
                        if (burcCharArray[i - 2] == elemnt)
                        {
                            text += burcCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += burcCharArray[i - 1].ToString();

                burcList.Add(1);
                int.TryParse(text, out burc);
                burcList[burcList.Count - 1] = burc;
            }
            else if (i == burcCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (burcCharArray.Length > 1)
                    {
                        if (burcCharArray[i - 1] == elemnt)
                        {
                            text += burcCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }
                Debug.Log(index.ToString() + " : " + burcCharArray.Length);

                text += burcCharArray[i].ToString();

                Debug.Log(text);

                burcList.Add(1);
                int.TryParse(text, out burc);
                burcList[burcList.Count - 1] = burc;
            }
        }

        int ay = 0;
        string ayString = myNodeList2[9].InnerText;
        char[] ayCharArray = ayString.ToCharArray();
        List<int> ayList = new List<int>();

        for (int i = 0; i < ayCharArray.Length; i++)
        {
            if (ayCharArray[i] == ',')
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (ayCharArray.Length > 2 && i > 1)
                    {
                        if (ayCharArray[i - 2] == elemnt)
                        {
                            text += ayCharArray[i - 2].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                text += ayCharArray[i - 1].ToString();

                ayList.Add(1);
                int.TryParse(text, out ay);
                ayList[ayList.Count - 1] = ay;
            }
            else if (i == ayCharArray.Length - 1)
            {
                string text = "";

                foreach (char elemnt in rakamlar)
                {
                    if (ayCharArray.Length > 1)
                    {
                        if (ayCharArray[i - 1] == elemnt)
                        {
                            text += ayCharArray[i - 1].ToString();
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                }
                Debug.Log(index.ToString() + " : " + ayCharArray.Length);

                text += ayCharArray[i].ToString();

                Debug.Log(text);

                ayList.Add(1);
                int.TryParse(text, out ay);
                ayList[ayList.Count - 1] = ay;
            }
        }

        Sohbet asset = ScriptableObject.CreateInstance<Sohbet>();

        List<ChatDegiskeni> gerekenDegiskenler = new List<ChatDegiskeni>();
        List<string> birlestirilecekModlar = new List<string>();

        foreach (int element in modList)
        {
            switch (element)
            {
                case 1:
                    AssetDatabase.CreateAsset(asset, "Assets/Resources/SohbetVeriTabani/Version1/HayatimdaNelerOlacak/KahveFali/TumFallar/Giris/Giris" + index.ToString() + ".asset");
                    EditorUtility.SetDirty(asset);
                    gerekenDegiskenler.Add(new ChatDegiskeni("mod", "kahve falı giriş"));
                    break;
                case 2:
                    AssetDatabase.CreateAsset(asset, "Assets/Resources/SohbetVeriTabani/Version1/HayatimdaNelerOlacak/KahveFali/TumFallar/Gelisme/Gelisme" + index.ToString() + ".asset");
                    EditorUtility.SetDirty(asset);
                    gerekenDegiskenler.Add(new ChatDegiskeni("mod", "kahve falı gelişme"));
                    break;
                case 3:
                    AssetDatabase.CreateAsset(asset, "Assets/Resources/SohbetVeriTabani/Version1/HayatimdaNelerOlacak/KahveFali/TumFallar/Sonuc/Sonuc" + index.ToString() + ".asset");
                    EditorUtility.SetDirty(asset);
                    gerekenDegiskenler.Add(new ChatDegiskeni("mod", "kahve falı sonuç"));
                    break;
                case 4:
                    AssetDatabase.CreateAsset(asset, "Assets/Resources/SohbetVeriTabani/Version1/HayatimdaNelerOlacak/KahveFali/TumFallar/Karsilama/Karsilama" + index.ToString() + ".asset");
                    EditorUtility.SetDirty(asset);
                    gerekenDegiskenler.Add(new ChatDegiskeni("mod", "kahve falı karşılama"));

                    birlestirilecekModlar.Add("kahve falı giriş");
                    birlestirilecekModlar.Add("kahve falı bağlama");
                    birlestirilecekModlar.Add("kahve falı gelişme");
                    birlestirilecekModlar.Add("kahve falı sonuç");
                    birlestirilecekModlar.Add("kahve falı uğurlama");
                    break;
                case 5:
                    AssetDatabase.CreateAsset(asset, "Assets/Resources/SohbetVeriTabani/Version1/HayatimdaNelerOlacak/KahveFali/TumFallar/Baglama/Baglama" + index.ToString() + ".asset");
                    EditorUtility.SetDirty(asset);
                    gerekenDegiskenler.Add(new ChatDegiskeni("mod", "kahve falı bağlama"));
                    break;
                case 6:
                    AssetDatabase.CreateAsset(asset, "Assets/Resources/SohbetVeriTabani/Version1/HayatimdaNelerOlacak/KahveFali/TumFallar/Ugurlama/Ugurlama" + index.ToString() + ".asset");
                    EditorUtility.SetDirty(asset);
                    gerekenDegiskenler.Add(new ChatDegiskeni("mod", "kahve falı uğurlama"));
                    break;
            }
        }

        foreach (int element in falList)
        {
            switch (element)
            {
                case 1:
                    gerekenDegiskenler.Add(new ChatDegiskeni("fal konusu", "genel"));
                    break;
                case 2:
                    gerekenDegiskenler.Add(new ChatDegiskeni("fal konusu", "aşk"));
                    break;
                case 3:
                    gerekenDegiskenler.Add(new ChatDegiskeni("fal konusu", "kariyer"));
                    break;
                case 4:
                    gerekenDegiskenler.Add(new ChatDegiskeni("fal konusu", "sağlık"));
                    break;
                default:
                    gerekenDegiskenler.Add(new ChatDegiskeni("fal konusu", "genel"));
                    break;
            }
        }

        foreach (int element in medeniDurumList)
        {
            switch (element)
            {
                case 1:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "ilişkisi yok"));
                    break;
                case 2:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "platonik"));
                    break;
                case 3:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "karmaşık"));
                    break;
                case 4:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "flört halinde"));
                    break;
                case 5:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "ilişkisi var"));
                    break;
                case 6:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "yeni ayrılmış"));
                    break;
                case 7:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "nişanlı"));
                    break;
                case 8:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "evli"));
                    break;
                case 9:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "ayrı yaşıyor"));
                    break;
                case 10:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "boşanmış"));
                    break;
                case 11:
                    gerekenDegiskenler.Add(new ChatDegiskeni("medeni durum", "dul"));
                    break;
                default:
                    //ekleme yok
                    break;
            }
        }

        foreach (int element in cinsiyetList)
        {
            switch (element)
            {
                case 1:
                    gerekenDegiskenler.Add(new ChatDegiskeni("cinsiyet", "kadın"));
                    break;
                case 2:
                    gerekenDegiskenler.Add(new ChatDegiskeni("cinsiyet", "erkek"));
                    break;
                default:
                    //ekleme yok
                    break;
            }
        }

        foreach (int element in meslekList)
        {
            switch (element)
            {
                case 1:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "ev hanımı"));
                    break;
                case 2:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "çalışmıyor"));
                    break;
                case 3:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "iş arıyor"));
                    break;
                case 4:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "öğrenci"));
                    break;
                case 5:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "akademisyen"));
                    break;
                case 6:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "kendi işini yapıyor"));
                    break;
                case 7:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "kamu sektörü"));
                    break;
                case 8:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "özel sektör"));
                    break;
                case 9:
                    gerekenDegiskenler.Add(new ChatDegiskeni("meslek", "emekli"));
                    break;
                default:
                    //ekleme yok
                    break;
            }
        }

        foreach (int element in burcList)
        {
            switch (element)
            {
                case 1:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "koç"));
                    break;
                case 2:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "boğa"));
                    break;
                case 3:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "ikizler"));
                    break;
                case 4:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "yengeç"));
                    break;
                case 5:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "aslan"));
                    break;
                case 6:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "başak"));
                    break;
                case 7:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "terazi"));
                    break;
                case 8:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "akrep"));
                    break;
                case 9:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "yay"));
                    break;
                case 10:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "oğlak"));
                    break;
                case 11:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "kova"));
                    break;
                case 12:
                    gerekenDegiskenler.Add(new ChatDegiskeni("burc", "balık"));
                    break;
                default:
                    //ekleme yok
                    break;
            }
        }

        foreach (int element in ayList)
        {
            switch (element)
            {
                case 1:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 2:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 3:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 4:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 5:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 6:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 7:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 8:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 9:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 10:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                case 11:
                    gerekenDegiskenler.Add(new ChatDegiskeni("ay", element.ToString()));
                    break;
                default:
                    //ekleme yok
                    break;
            }
        }

        asset.gerekenDegiskenler = new ChatDegiskeni[gerekenDegiskenler.Count];
        asset.birlestirilecekModlar = new string[birlestirilecekModlar.Count];

        for (int i =0; i<gerekenDegiskenler.Count; i++)
        {
            asset.gerekenDegiskenler[i] = new ChatDegiskeni();
            asset.gerekenDegiskenler[i].degiskenAdi = gerekenDegiskenler[i].degiskenAdi;
            asset.gerekenDegiskenler[i].degiskenDegeri = gerekenDegiskenler[i].degiskenDegeri;
        }

        for (int i = 0; i < birlestirilecekModlar.Count; i++)
        {
            asset.birlestirilecekModlar[i] = "";
            asset.birlestirilecekModlar[i] = birlestirilecekModlar[i];
        }

        //AssetDatabase.SaveAssets();

        EditorUtility.FocusProjectWindow();

        asset.aciklama = new string[] { "" };
        asset.aciklama[0] = myNodeList2[11].InnerText;

        EditorUtility.SetDirty(asset);
        //AssetDatabase.SaveAssets();
        //Selection.activeObject = asset;
    }*/
}
