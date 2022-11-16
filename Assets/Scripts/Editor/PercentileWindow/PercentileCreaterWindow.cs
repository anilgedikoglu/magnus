using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class PercentileCreaterWindow : EditorWindow
{
    //Window setting
    int headerSpace = 100;
    int spaceBetweenObjects = 5;
    int spaceBetweenBarBlocks = 50;
    Vector2 scroll;

    //Variables
    string mod;
    string header;
    string sohbetAdi;
    List<BarInformation> barInformations;


    [MenuItem("Magnus/Olusturucular/Yüzdelik Sohbet Oluşturucu")]
    public static void ShowWindow()
    {
        PercentileCreaterWindow window = (PercentileCreaterWindow)EditorWindow.GetWindow(typeof(PercentileCreaterWindow));
    }

    private void OnEnable()
    {
        barInformations = new List<BarInformation>();
        barInformations.Add(new BarInformation());
    }

    private void OnGUI()
    {
        scroll = EditorGUILayout.BeginScrollView(scroll);
        if (!string.IsNullOrEmpty(mod) && !string.IsNullOrEmpty(header))
        {
            if (GUILayout.Button("Sohbeti Oluştur", GUILayout.Height(50)))
            {
                BarData barData = new BarData();
                var jsonData = "";

                barData.header = header;

                foreach (BarInformation barInformation in barInformations)
                {
                    List<Bar.Explanation> explanations = new List<Bar.Explanation>();
                    explanations.Add(new Bar.Explanation(barInformation.explanations));
                    barData.bars.Add(new Bar(barInformation.barColors.ToString(), barInformation.style, "standart", new Bar.Animation("{{sayi, " + barInformation.barMinValue.ToString() + ", " + barInformation.barMaxValue.ToString() + "}}", 100f, 0f, 0f), new Bar.Header(barInformation.barHeader), explanations));
                }

                jsonData = JsonUtility.ToJson(barData);
                Sohbet sohbet = CreateInstance(typeof(Sohbet)) as Sohbet;
                sohbet.aciklama = new List<string> { "" };
                sohbet.aciklama[0] = "{{barmenu}}" + jsonData;
                sohbet.gerekliDegiskenler = new List<Sohbet.GerekenDegisken>(new Sohbet.GerekenDegisken[1]);
                sohbet.gerekliDegiskenler[0] = new Sohbet.GerekenDegisken();
                sohbet.gerekliDegiskenler[0].degiskenAdi = "mod";
                sohbet.gerekliDegiskenler[0].degiskenDegeri = mod;

                if (string.IsNullOrEmpty(sohbetAdi))
                {
                    ProjectWindowUtil.CreateAsset(sohbet, "sohbet" + ".asset");
                }
                else
                {
                    ProjectWindowUtil.CreateAsset(sohbet, sohbetAdi + ".asset");
                }
                Debug.Log(jsonData);
            }
        }

        EditorGUILayout.Space(spaceBetweenObjects);

        GUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Mod", GUILayout.Width(headerSpace));
        mod = EditorGUILayout.TextField(mod);
        GUILayout.EndHorizontal();

        GUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Panel başlığı", GUILayout.Width(headerSpace));
        header = EditorGUILayout.TextField(header);
        GUILayout.EndHorizontal();

        GUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Sohbet Adı", GUILayout.Width(headerSpace));
        sohbetAdi = EditorGUILayout.TextField(sohbetAdi);
        GUILayout.EndHorizontal();


        List<BarInformation> kalidirilacakBarlar = new List<BarInformation>();
        foreach (BarInformation barInformation in barInformations)
        {
            EditorGUILayout.Space(spaceBetweenBarBlocks);

            GUIStyle h1;
            h1 = new GUIStyle();
            h1.fontSize = 25;
            h1.normal.textColor = Color.white;
            h1.fontStyle = FontStyle.Bold;

            GUIStyle h2;
            h2 = new GUIStyle();
            h2.fontSize = 20;
            h2.normal.textColor = Color.white;
            h2.fontStyle = FontStyle.Bold;

            string baslikText = "";
            if (!string.IsNullOrEmpty(barInformation.barHeader))
            {
                if (!string.IsNullOrEmpty(barInformation.explanations))
                {
                    if (!(barInformation.barMaxValue == 0 && barInformation.barMinValue == 0))
                    {
                        baslikText = barInformation.barHeader + "(Başlık, bar ve açıklama)";
                    }
                    else
                    {
                        baslikText = barInformation.barHeader + "(Başlık ve açıklama)";
                    }
                }
                else
                {
                    if (!(barInformation.barMaxValue == 0 && barInformation.barMinValue == 0))
                    {
                        baslikText = barInformation.barHeader + "(Başlık ve bar)";
                    }
                    else
                    {
                        baslikText = barInformation.barHeader + "(Sadece başlık)";
                    }
                }
            }
            else
            {
                if (!string.IsNullOrEmpty(barInformation.explanations))
                {
                    if (!(barInformation.barMaxValue == 0 && barInformation.barMinValue == 0))
                    {
                        baslikText = "Başlıksız" + "(Bar ve açıklama)";
                    }
                    else
                    {
                        baslikText = "Başlıksız" + "(Sadece açıklama)";
                    }
                }
                else
                {
                    if (!(barInformation.barMaxValue == 0 && barInformation.barMinValue == 0))
                    {
                        baslikText = "Başlıksız" + "(Sadece bar)";
                    }
                    else
                    {
                        baslikText = "Boş";
                    }
                }
            }

            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(baslikText, h1, GUILayout.Height(30));
            if (GUILayout.Button("-", GUILayout.Height(30), GUILayout.Height(30), GUILayout.ExpandWidth(false)))
            {
                kalidirilacakBarlar.Add(barInformation);
            }
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Bar rengi", GUILayout.Width(headerSpace));
            barInformation.barColors = (BarInformation.BarColors)EditorGUILayout.EnumPopup(barInformation.barColors);
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Bar Sitili", GUILayout.Width(headerSpace));
            barInformation.style = (PercentileBar.Bar.Style)EditorGUILayout.EnumPopup(barInformation.style);
            GUILayout.EndHorizontal();

            EditorGUILayout.Space(spaceBetweenObjects);

            /*
            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Arkaplan rengi", GUILayout.Width(headerSpace));
            barInformation.barBackgroundColors = (BarInformation.BarColors)EditorGUILayout.EnumPopup(barInformation.barBackgroundColors);
            GUILayout.EndHorizontal();

            EditorGUILayout.Space(spaceBetweenObjects);
            */


            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Başlık", GUILayout.Width(headerSpace));
            barInformation.barHeader = EditorGUILayout.TextField(barInformation.barHeader);
            GUILayout.EndHorizontal();

            EditorGUILayout.Space(spaceBetweenObjects);

            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Minimum değer", GUILayout.Width(headerSpace));
            barInformation.barMinValue = EditorGUILayout.IntField(barInformation.barMinValue);
            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("Maksimum değer", GUILayout.Width(headerSpace));
            barInformation.barMaxValue = EditorGUILayout.IntField(barInformation.barMaxValue);
            GUILayout.EndHorizontal();

            EditorGUILayout.Space(spaceBetweenObjects);

            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Açıklama", GUILayout.Width(headerSpace));
            barInformation.explanations = EditorGUILayout.TextArea(barInformation.explanations, EditorStyles.textArea, GUILayout.Height(200), GUILayout.ExpandHeight(true));
            GUILayout.EndHorizontal();
        }

        foreach(BarInformation kaldirilacakBar in kalidirilacakBarlar)
        {
            barInformations.Remove(kaldirilacakBar);
        }

        EditorGUILayout.Space(spaceBetweenObjects);

        GUILayout.BeginHorizontal();
        GUILayout.Space(300);
        if (GUILayout.Button("-", GUILayout.Height(50), GUILayout.Height(20)))
        {
            barInformations.RemoveAt(barInformations.Count - 1);
        }
        if (GUILayout.Button("+", GUILayout.Height(50), GUILayout.Height(20)))
        {
            barInformations.Add(new BarInformation());
        }
        GUILayout.EndHorizontal();


        EditorGUILayout.EndScrollView();
    }

    [System.Serializable]
    class BarInformation
    {
        public string barHeader;
        public string explanations;

        public enum BarColors { red, green, blue, yellow, orange, pink, magenta, cyan, brown }
        public BarColors barColors;
        public BarColors barBackgroundColors;

        public PercentileBar.Bar.Style style;

        public int barMinValue, barMaxValue;
    }

    [System.Serializable]
    public class Bar
    {
        [HideInInspector] public string color;
        public PercentileBar.Bar.Style style;

        [HideInInspector] public string backgroundColor;

        public Animation animation;
        public Header header;
        public List<Explanation> explanations;

        public Bar(string color, PercentileBar.Bar.Style style, string backgroundColor, Animation animation, Header header, List<Explanation> explanations)
        {
            this.color = color;
            this.style = style;
            this.backgroundColor = backgroundColor;
            this.animation = animation;
            this.header = header;
            this.explanations = explanations;
        }

        [System.Serializable]
        public class Animation
        {
            [HideInInspector] public string startValue;
            [HideInInspector] public float startTime, targetValue;
            public float duration;

            public Animation()
            {
                startValue = "";
                targetValue = 0;
                startTime = 0;
                duration = 0;
            }

            public Animation(string startValue, float targetValue, float startTime, float duration)
            {
                this.startValue = startValue;
                this.targetValue = targetValue;
                this.startTime = startTime;
                this.duration = duration;
            }
        }

        public void InitiliazeBar(GameObject gameObject, GameObject backgroundGameObject)
        {
            color = "";
            backgroundColor = "";
        }

        [System.Serializable]
        public class Header
        {
            public string content;

            public Header()
            {
                content = "Bar başlığı";
            }

            public Header(string content)
            {
                this.content = content;
            }
        }

        [System.Serializable]
        public class Explanation
        {
            public string content;

            public Explanation()
            {
                content = "Bar açıklaması";
            }

            public Explanation(string content)
            {
                this.content = content;
            }
        }
    }

    public class BarData
    {
        public string header;
        public List<Bar> bars;

        public BarData()
        {
            bars = new List<Bar>();
        }
    }
}
