using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;
using TMPro;

public class HizliFalOyunManager : MonoBehaviour
{
    public RectTransform content;

    public BilgiEkraniSettings bilgiEkraniSettings;
    public PreferencesObject preferences;

    public delegate void UpdateUIDelegate();
    public UpdateUIDelegate updateUI;

    public RectTransform linesParent;
    private List<HizliFalOyunElement> hizliFalOyunElements;

    [HideInInspector] public CurrentPlayerData currentPlayerData;
    [HideInInspector] public AdManager adManager;

    public GameObject loadingMask;

    [SerializeField] private Color oyunFrameActiveColor;
    [SerializeField] private Color falFrameActiveColor;
    public Color frameDeactiveColor;
    [HideInInspector] public Color currentFrameColor;

    [SerializeField] private Gradient textFalActiveGradient;
    [SerializeField] private Gradient textOyunActiveGradient;
    public Gradient textDeactiveGradient;
    [HideInInspector] public Gradient textCurrentActiveGradient;

    public Image navigationBarFrame;
    public Image indicatorBackground;

    public Image transactionImage;
    [HideInInspector] public Image panelImage;

    [HideInInspector] public List<BilgiEkraniSettings.HizliFalOyun.Element> elements;

    public EnergyManager energyManager;
    public EnergyManager konsManager;

    public TMP_Text energyText;
    public TMP_Text konsText;

    private void Awake()
    {
        panelImage = GetComponent<Image>();
        currentPlayerData = FindObjectOfType<CurrentPlayerData>();
        adManager = FindObjectOfType<AdManager>();

        updateUI += UpdateUI;
        FindElements();
    }

    // Start is called before the first frame update
    void Start()
    {
        loadingMask.SetActive(true);
        updateUI();

        energyText.text = energyManager.extraEnergyText.text;
        konsText.text = konsManager.extraEnergyText.text;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void UpdateUI() 
    {

    }

    private void OnEnable()
    {
        updateUI();

        energyText.text = energyManager.extraEnergyText.text;
        konsText.text = konsManager.extraEnergyText.text;

        SetActive(true);
    }

    public void SetActive(bool active)
    {
        if (active)
        {
            gameObject.SetActive(true);
            content.gameObject.SetActive(true);

            transactionImage.color = new Color(transactionImage.color.r, transactionImage.color.g,
                transactionImage.color.b, 0);

            panelImage.color = new Color(panelImage.color.r, panelImage.color.g,
           panelImage.color.b, 1);
        }
        else
        {
            content.gameObject.SetActive(false);
            gameObject.SetActive(false);
        }
    }

    public void FindElements()
    {
        hizliFalOyunElements = new List<HizliFalOyunElement>();
        int globalIndex = 0;
        for(int i = 0; i<linesParent.childCount; i++)
        {
            for (int u = 0; u < linesParent.GetChild(i).childCount; u++)
            {
                hizliFalOyunElements.Add(linesParent.GetChild(i).GetChild(u).GetComponent<RectTransform>().GetComponent<HizliFalOyunElement>());
                hizliFalOyunElements[^1].index = globalIndex;
                globalIndex += 1;
                
            }
        }
    }

    public void SetSubMenuState(string state, bool animate)
    {
        if (!animate)
        {
            textCurrentActiveGradient = (Gradient)
    bilgiEkraniSettings.hizliFalOyun.GetType().GetField(state + "TextBack").GetValue(bilgiEkraniSettings.hizliFalOyun);
            currentFrameColor = (Color)
                bilgiEkraniSettings.hizliFalOyun.GetType().GetField(state + "Color").GetValue(bilgiEkraniSettings.hizliFalOyun);

            SetElements((List<BilgiEkraniSettings.HizliFalOyun.Element>)
                bilgiEkraniSettings.hizliFalOyun.GetType().GetField(state).GetValue(bilgiEkraniSettings.hizliFalOyun));
        }
        else
        {
            SetSubMenuState(state);
        }
    }

    public void SetSubMenuState(string state)
    {
        textCurrentActiveGradient = (Gradient)
            bilgiEkraniSettings.hizliFalOyun.GetType().GetField(state + "TextBack").GetValue(bilgiEkraniSettings.hizliFalOyun);
        currentFrameColor = (Color)
            bilgiEkraniSettings.hizliFalOyun.GetType().GetField(state + "Color").GetValue(bilgiEkraniSettings.hizliFalOyun);

        SetElements((List<BilgiEkraniSettings.HizliFalOyun.Element>)
    bilgiEkraniSettings.hizliFalOyun.GetType().GetField(state).GetValue(bilgiEkraniSettings.hizliFalOyun));
    }

    private void SetElements(List<BilgiEkraniSettings.HizliFalOyun.Element> elementsData)
    {
        indicatorBackground.DOColor(currentFrameColor, 0.5f);
        navigationBarFrame.DOColor(currentFrameColor, 0.5f);

        transactionImage.DOFade(1f, .25f).onComplete = () =>
        {
            elements = new List<BilgiEkraniSettings.HizliFalOyun.Element>();
            foreach (BilgiEkraniSettings.HizliFalOyun.Element element in elementsData)
            {
                for (int i = 0; i < element.indexOffset; i++)
                    elements.Add(bilgiEkraniSettings.hizliFalOyun.defaultElement);

                elements.Add(element);
            }

            updateUI();



            transactionImage.DOFade(0f, .25f);
        };
    }

    public void SetStateWithotAnimation(string state)
    {
        SetSubMenuState(state, false);
    }
}
