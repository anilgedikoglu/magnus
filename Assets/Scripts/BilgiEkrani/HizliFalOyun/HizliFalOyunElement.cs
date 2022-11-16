using DG.Tweening;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using Michsky.UI.ModernUIPack;

public class HizliFalOyunElement : MonoBehaviour
{
    public Image image, frameImage;
    private Color frameFirstColor;

    public TMP_Text text;
    private HizliFalOyunManager hizliFalOyunManager;

    [HideInInspector] public UIGradient TextBackground;

    [HideInInspector] public int index;

    BilgiEkraniSettings.HizliFalOyun.Element element;

    private bool clickable = true;

    public TMP_Text energyText;
    public GameObject energyIcon;

    public TMP_Text konsText;
    public GameObject konsIcon;

    private void Awake()
    {
        hizliFalOyunManager = FindObjectOfType<HizliFalOyunManager>();

        frameImage = GetComponent<RectTransform>().GetChild(0).GetComponent<Image>();
        frameFirstColor = frameImage.color;

        hizliFalOyunManager.updateUI += UpdateUI;

        GetComponent<Button>().onClick.AddListener(ClickButton);

        TextBackground = GetComponentInChildren<UIGradient>();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void UpdateUI()
    {
        clickable = true;

        BilgiEkraniSettings.HizliFalOyun.Element element = hizliFalOyunManager.bilgiEkraniSettings.hizliFalOyun.defaultElement;
        if (index < hizliFalOyunManager.elements.Count)
        {
            element = hizliFalOyunManager.elements[index];
        }

        this.element = element;

 

        text.text = element.title;

        PreferencesObject.BugunGelenMod bugunGelenMod = hizliFalOyunManager.preferences.gunlukModlar.Find(x => x.uIInformation.title.Equals(element.title));

        bool plus = hizliFalOyunManager.currentPlayerData.GetChatVariableValue("plus") == "var";

        if (string.IsNullOrEmpty(element.mod))
        {
            TextBackground.EffectGradient = hizliFalOyunManager.textDeactiveGradient;
            image.sprite = element.iconDeactive;
            frameImage.color = hizliFalOyunManager.frameDeactiveColor;
            clickable = false;

            SetEnergyKonsText(false);
            return;
        }
        else
        {
            TextBackground.EffectGradient = hizliFalOyunManager.textCurrentActiveGradient;
            image.sprite = element.icon;
            frameImage.color = hizliFalOyunManager.currentFrameColor;

            SetEnergyKonsText(true);
        }

        if (bugunGelenMod == null)
        {
            return;
        }
        if (plus)
        {
            PlayerData.BugunGelenMod dataBugunGelenMod = hizliFalOyunManager.currentPlayerData.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));
            if (dataBugunGelenMod == null)
                return;

            if (dataBugunGelenMod.count < bugunGelenMod.countPlus)
            {
                return;
            }
        }
        else
        {
            PlayerData.BugunGelenMod dataBugunGelenMod = hizliFalOyunManager.currentPlayerData.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));
            if (dataBugunGelenMod == null)
                return;

            if (dataBugunGelenMod.count < bugunGelenMod.count)
            {
                return;
            }
        }

        TextBackground.EffectGradient = hizliFalOyunManager.textDeactiveGradient;
        image.sprite = element.iconDeactive;
        frameImage.color = hizliFalOyunManager.frameDeactiveColor;
        clickable = false;

        SetEnergyKonsText(false);
    }

    private void SetEnergyKonsText(bool value)
    {
        if (!value)
        {
            energyIcon.gameObject.SetActive(false);
            energyText.gameObject.SetActive(false);

            konsIcon.gameObject.SetActive(false);
            konsText.gameObject.SetActive(false);
            return;
        }
        else
        {
            energyIcon.gameObject.SetActive(element.energy > 0);
            energyText.gameObject.SetActive(element.energy > 0);

            konsIcon.gameObject.SetActive(element.kons > 0);
            konsText.gameObject.SetActive(element.kons > 0);
        }

        energyText.text = element.energy.ToString();
        konsText.text = element.kons.ToString();
    }

    public void ClickButton()
    {
        if (!string.IsNullOrEmpty(element.mod) && clickable)
        {
            if (hizliFalOyunManager.currentPlayerData.datas.energy >= element.energy)
            {
                if (hizliFalOyunManager.currentPlayerData.datas.konsantrasyon >= element.kons)
                {
                    bool plus = hizliFalOyunManager.currentPlayerData.GetChatVariableValue("plus") == "var";

                    if (element.plus && !plus)
                    {
                        //Magazayi acan bir fonksiyon yazilacak.
                        //Bu ne boyle!
                        GameObject.Find("PanelMagaza").GetComponent<RectTransform>().GetChild(0).gameObject.SetActive(true);
                        GameObject.Find("PanelMagaza").GetComponent<RectTransform>().GetChild(0).GetComponent<StoreMenu>().SetAnimatorState(1);
                        return;
                    }

                    hizliFalOyunManager.transactionImage.DOFade(1, .25f).onComplete = () =>
                    {
                        hizliFalOyunManager.SetActive(false);
                        hizliFalOyunManager.transactionImage.DOFade(0, 0);
                        var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                        welcomeScreen.ButtonSohbeteGec(element.mod);

                        hizliFalOyunManager.energyManager.AddEnergy(-element.energy, 0);
                        hizliFalOyunManager.konsManager.AddEnergy(0, -element.kons);

                        if (element.reklamGoster && !plus)
                            hizliFalOyunManager.adManager.ShowInterstitial();
                    };

                    if (element.showAd && !plus)
                        hizliFalOyunManager.adManager.ShowInterstitial();
                }
                else
                {
                    var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                    welcomeScreen.SetActive(false, false);

                    var chatManager = FindObjectOfType<ChatManager>();

                    /*
                    chatManager.chatScreenActivityManager.SetActive();
                    chatManager.introManager.SetChatWallpaperActive();

                    chatManager.chatIsActive = true;*/

                    welcomeScreen.ButtonSohbeteGec("konsantrasyon bitti");

                    chatManager.reklamSonuModu = element.mod;
                }
            }
            else
            {
                var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                welcomeScreen.SetActive(false, false);

                var chatManager = FindObjectOfType<ChatManager>();

                /*
                chatManager.chatScreenActivityManager.SetActive();
                chatManager.introManager.SetChatWallpaperActive();

                chatManager.chatIsActive = true;

                /*
                chatManager.DelayedCall(.2f, () =>
                {
                    chatManager.ClickVirtualButton("enerji bitti");
                });*/

                welcomeScreen.ButtonSohbeteGec("enerji bitti");

                chatManager.reklamSonuModu = element.mod;
            }
        }
    }
}
