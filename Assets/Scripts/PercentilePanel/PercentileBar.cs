using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;

using DG.Tweening;
using UIHealthAlchemy;

public class PercentileBar : MonoBehaviour
{
    //Bar
    public Bar bar;

    //Explanations
    public GameObject explanationPrefab;
    public RectTransform explanationFolder;

    public float animationDelay;

    public RectTransform customBarsParent;

    private void Start()
    {
        StartBarAnimationsWithDelay(animationDelay);
    }

    // Update is called once per frame
    void Update()
    {
        if (!string.IsNullOrEmpty(bar.header.content))
        {
            if (bar.rectTransform != null)
            {
                //float t = (Time.time - bar.animation.startTime) / bar.animation.duration;
                //bar.rectTransform.localScale = new Vector3(Mathf.SmoothStep(bar.animation.startValue, bar.animation.targetValue, t), bar.rectTransform.localScale.y, bar.rectTransform.localScale.z);
            }
        }
    }

    public void StartBarAnimationsWithDelay(float delay)
    {
        StartCoroutine(StartBarAnimationsDelay(delay));
    }

    IEnumerator StartBarAnimationsDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        if (bar.rectTransform != null)
        {
            bar.rectTransform.sizeDelta = new Vector2(bar.animation.startValue, bar.rectTransform.sizeDelta.y);
            bar.rectTransform.DOSizeDelta(new Vector2(bar.backgroundRectTransform.rect.width * bar.animation.targetValue, bar.backgroundRectTransform.rect.height), bar.animation.duration);
        }
    }

    public void InitiliazeBar(string headerContent, List<string> explanations, float targetValue, string color, Bar.Style style, string backgroundColor)
    {
        var percentileManager = FindObjectOfType<PercentileManager>();

        bar.InitiliazeBar(bar.gameObject, bar.backgroundGameObject);

        if (targetValue != 0 && !string.IsNullOrEmpty(headerContent))
        {
            bar.header.SetContent(headerContent + " %" + targetValue * 100f);
        }
        else
        {
            bar.header.SetContent(headerContent);
        }

        bar.animation.startValue = 0;
        bar.animation.targetValue = targetValue;
        bar.animation.startTime = Time.time;
        bar.backgroundImage.color = percentileManager.bakcgroundStadartColor;
        switch (color)
        {
            case "red":
                bar.image.color = percentileManager.red;
                break;
            case "green":
                bar.image.color = percentileManager.green;
                break;
            case "blue":
                bar.image.color = percentileManager.blue;
                break;
            case "yellow":
                bar.image.color = percentileManager.yellow;
                break;
            case "orange":
                bar.image.color = percentileManager.orange;
                break;
            case "pink":
                bar.image.color = percentileManager.pink;
                break;
            case "magenta":
                bar.image.color = percentileManager.magenta;
                break;
            case "cyan":
                bar.image.color = percentileManager.cyan;
                break;
            case "brown":
                bar.image.color = percentileManager.brown;
                break;
            default:
                bar.image.color = percentileManager.red;
                break;
        }

        customBarsParent.GetChild(1).GetComponent<MaterialHealhBar>().Value = targetValue;
        Material newMat = new Material(customBarsParent.GetChild(1).GetComponent<MaterialHealhBar>().mat.shader);
        newMat.CopyPropertiesFromMaterial(customBarsParent.GetChild(1).GetComponent<MaterialHealhBar>().mat);
        customBarsParent.GetChild(1).GetComponent<MaterialHealhBar>().mat = newMat;
        customBarsParent.GetChild(1).GetChild(2).GetComponent<Image>().material = newMat;

        customBarsParent.GetChild(2).GetComponent<MaterialHealhBar>().Value = targetValue;
        Material newMat2 = new Material(customBarsParent.GetChild(2).GetComponent<MaterialHealhBar>().mat.shader);
        newMat2.CopyPropertiesFromMaterial(customBarsParent.GetChild(2).GetComponent<MaterialHealhBar>().mat);
        customBarsParent.GetChild(2).GetComponent<MaterialHealhBar>().mat = newMat2;
        customBarsParent.GetChild(2).GetChild(2).GetComponent<Image>().material = newMat2;

        customBarsParent.GetChild(3).GetComponent<MaterialHealhBar>().Value = targetValue;
        Material newMat3 = new Material(customBarsParent.GetChild(3).GetComponent<MaterialHealhBar>().mat.shader);
        newMat3.CopyPropertiesFromMaterial(customBarsParent.GetChild(3).GetComponent<MaterialHealhBar>().mat);
        customBarsParent.GetChild(3).GetComponent<MaterialHealhBar>().mat = newMat3;
        customBarsParent.GetChild(3).GetChild(1).GetComponent<Image>().material = newMat3;

        //Burasi daha sonra duzenlenecek. Normal durumu icin de ekleme yapilacak vs.
        if (style == Bar.Style.ates)
        {
            customBarsParent.GetComponent<Image>().color = new Color(0, 0, 0, 0);

            customBarsParent.GetChild(0).gameObject.SetActive(false);
            customBarsParent.GetChild(1).gameObject.SetActive(true);
            customBarsParent.GetChild(2).gameObject.SetActive(false);
            customBarsParent.GetChild(3).gameObject.SetActive(false);

            GetComponent<VerticalLayoutGroup>().spacing = 15;
        }
        else if (style == Bar.Style.buz)
        {
            customBarsParent.GetComponent<Image>().color = new Color(0, 0, 0, 0);

            customBarsParent.GetChild(0).gameObject.SetActive(false);
            customBarsParent.GetChild(1).gameObject.SetActive(false);
            customBarsParent.GetChild(2).gameObject.SetActive(true);
            customBarsParent.GetChild(3).gameObject.SetActive(false);

            GetComponent<VerticalLayoutGroup>().spacing = 25;
        }
        if (style == Bar.Style.doga)
        {
            customBarsParent.GetComponent<Image>().color = new Color(0, 0, 0, 0);

            customBarsParent.GetChild(0).gameObject.SetActive(false);
            customBarsParent.GetChild(1).gameObject.SetActive(false);
            customBarsParent.GetChild(2).gameObject.SetActive(false);
            customBarsParent.GetChild(3).gameObject.SetActive(true);

            GetComponent<VerticalLayoutGroup>().spacing = 15;
        }

        SetExplanation(explanations);

        if (string.IsNullOrEmpty(bar.header.content))
        {
            Destroy(bar.header.text.gameObject);
        }
        else
        {
            if (bar.animation.targetValue == 0 && bar.explanations[0].content == "")
            {
                bar.header.text.alignment = TextAlignmentOptions.Center;
            }
        }

        if (bar.animation.targetValue == 0)
        {
            Destroy(bar.backgroundGameObject);
        }
        else
        {
            //Debug.Log(bar.animation.targetValue);
        }

        if (bar.explanations[0].content== "")
        {
            Destroy(explanationFolder.gameObject);
        }
    }

    public void SetExplanation(List<string> texts)
    {
        foreach (string text in texts)
        {
            var explanationObject = Instantiate(explanationPrefab, explanationFolder);
            bar.explanations.Add(new Bar.Explanation(explanationObject.GetComponent<TMP_Text>(), text));
        }
    }

    [System.Serializable]
    public class Bar
    {
        public GameObject gameObject;
        [HideInInspector] public RectTransform rectTransform;
        [HideInInspector] public Image image;
        [HideInInspector] public string color;

        public GameObject backgroundGameObject;
        [HideInInspector] public RectTransform backgroundRectTransform;
        [HideInInspector] public Image backgroundImage;
        [HideInInspector] public string backgroundColor;

        public Animation animation;
        public Header header;
        public List<Explanation> explanations;

        public enum Style { normal, scfi, ates, buz, doga};
        public Style style = Style.normal;

        public Bar()
        {
            this.gameObject = null;
            rectTransform = null;
            image = null;
            color = "";
            style = Style.normal;
        }

        [System.Serializable]
        public class Animation
        {
            [HideInInspector] public float startValue, targetValue;
            [HideInInspector] public float startTime;
            public float duration;

            public Animation()
            {
                startValue = 0;
                targetValue = 0;
                startTime = 0;
                duration = 0;
            }

            public Animation(float startValue, float targetValue, float startTime, float duration)
            {
                this.startValue = startValue;
                this.targetValue = targetValue;
                this.startTime = startTime;
                this.duration = duration;
            }
        }

        public void InitiliazeBar( GameObject gameObject, GameObject backgroundGameObject)
        {
            rectTransform = gameObject.GetComponent<RectTransform>().parent.GetComponent<RectTransform>();
            image = gameObject.GetComponent<Image>();
            color = "";

            backgroundRectTransform = backgroundGameObject.GetComponent<RectTransform>();
            backgroundImage = backgroundGameObject.GetComponent<Image>();
            backgroundColor = "";
        }

        [System.Serializable]
        public class Header
        {
            public TMP_Text text;
            public string content;

            public Header()
            {
                text = null;
                content = "Bar başlığı";
            }

            public void SetContent()
            {
                text.text = content;
            }

            public void SetContent(string content)
            {
                this.content = content;
                text.text = content;
            }
        }

        [System.Serializable]
        public class Explanation
        {
            public TMP_Text text;
            public string content;

            public Explanation()
            {
                text = null;
                content = "Bar açıklaması";
            }

            public Explanation(TMP_Text text, string content)
            {
                this.text = text;
                this.content = content;
                SetContent();
            }

            public void SetContent()
            {
                text.text = content;
            }
        }
    }
}
