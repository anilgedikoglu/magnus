using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FalHakkiManager : MonoBehaviour
{
    private RectTransform rectTransform;

    public PreferencesObject preferencesObject;
    public BilgiEkraniSettings bilgiEkraniSettings;
    [HideInInspector] public CurrentPlayerData playerData;

    [SerializeField] internal EnergyManager altinManager, elmasManager;

    public RectTransform normalFlare, plusFlare;

    public delegate void UpdateUI();
    public UpdateUI updateUI;

    private void Awake()
    {
        rectTransform = GetComponent<RectTransform>();
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    private void OnEnable()
    {
        updateUI?.Invoke();
    }

    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(CreateElements());

        if (playerData.GetChatVariableValue("plus") == "var")
        {
            normalFlare.gameObject.SetActive(false);
            plusFlare.gameObject.SetActive(true);
        }
        else
        {
            normalFlare.gameObject.SetActive(true);
            plusFlare.gameObject.SetActive(false);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private IEnumerator CreateElements()
    {
        int totalElementCount = 0;
        for (int i = 0; i < preferencesObject.gunlukModlar.Count; i++)
        {
            if (preferencesObject.gunlukModlar[i].falHaklariMenusundeGoster)
            {
                FalHakkiElement falHakkiElement;
                if (rectTransform.childCount <= totalElementCount)
                {
                    falHakkiElement = Instantiate(rectTransform.GetChild(0), rectTransform)
                        .GetComponent<RectTransform>()
                        .GetChild(0).GetComponent<FalHakkiElement>();
                }
                else
                {
                    falHakkiElement = rectTransform.GetChild(totalElementCount).GetComponent<RectTransform>()
                        .GetChild(0).GetComponent<FalHakkiElement>();
                }
                falHakkiElement.gunlukMod = preferencesObject.gunlukModlar[i];
                totalElementCount++;
                yield return new WaitForSeconds(Time.deltaTime * 3f);
            }
        }
    }

    [System.Serializable]
    public class Button
    {
        public Image image;
        public Image frameImage;

        public Color activeColor;
        public Color deactiveColor;

        public Color frameActiveColor;
        public Color frameDeactiveColo;

        public void SetActive(bool active)
        {
            if (active)
            {
                image.color = activeColor;
                frameImage.color = frameActiveColor;
            }
            else
            {
                image.color = deactiveColor;
                frameImage.color = frameDeactiveColo;
            }
        }
    }
}
