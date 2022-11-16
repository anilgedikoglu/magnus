using Michsky.UI.ModernUIPack;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class FalOyunOneriElement : MonoBehaviour
{
    private FalOyunOner falOyunOner;

    public Image image, plusBadge, frameImage;

    public TMP_Text text;

    [HideInInspector] public UIGradient TextBackground;

    public int index;
    public bool onlyPlus;

    private bool clickable;
    private BilgiEkraniSettings.HizliFalOyun.Element element;

    private void Awake()
    {
        falOyunOner = FindObjectOfType<FalOyunOner>();
        TextBackground = GetComponentInChildren<UIGradient>();

        falOyunOner.updateUI += StartUpdateUI;
    }

    // Start is called before the first frame update
    void Start()
    {
 
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void StartUpdateUI()
    {
        StartCoroutine(UpdateUIDelay());
    }

    private IEnumerator UpdateUIDelay() {
        for (int i = 0; i < index; i++)
            yield return new WaitForEndOfFrame();

        UpdateUI();
    }

    private void UpdateUI()
    {
        clickable = true;

        bool plus = falOyunOner.currentPlayerData.GetChatVariableValue("plus") == "var";

        BilgiEkraniSettings.HizliFalOyun.Element element = falOyunOner.bilgiEkraniSettings.hizliFalOyun.defaultElement;

        Color currentFrameColor;
        Gradient currentTextGradient;
        float sansFal = Random.Range(0f, 100f);
        List<BilgiEkraniSettings.HizliFalOyun.Element> elementList;
        List<BilgiEkraniSettings.HizliFalOyun.Element> elementListClean;
        if (sansFal < falOyunOner.falSecmeYuzdesi)
        {
            elementList = falOyunOner.bilgiEkraniSettings.hizliFalOyun.fallar;
            currentFrameColor = falOyunOner.falFrameActiveColor;
            currentTextGradient = falOyunOner.textFalActiveGradient;
        }
        else
        {
            elementList = falOyunOner.bilgiEkraniSettings.hizliFalOyun.oyunlar;

            currentFrameColor = falOyunOner.oyunFrameActiveColor;
            currentTextGradient = falOyunOner.textOyunActiveGradient;
        }

        elementListClean = elementList.FindAll(x =>
        {
            PreferencesObject.BugunGelenMod bugunGelenMod =
            falOyunOner.preferences.gunlukModlar.Find(y => y.uIInformation.title.Equals(x.title));

            for (int i = 0; i < index; i++)
            {
                if (falOyunOner.elements[i].element == x)
                {
                    return false;
                }
            }

            if (x.plus)
            {
                if (!onlyPlus)
                {
                    return false;
                }
            }
            else
            {
                if (onlyPlus)
                    return false;
            }

            if (plus)
            {
                if (bugunGelenMod != null)
                {
                    PlayerData.BugunGelenMod dataBugunGelenMod = falOyunOner.currentPlayerData.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));

                    if (dataBugunGelenMod != null)
                    {
                        if (dataBugunGelenMod.count >= bugunGelenMod.countPlus)
                        {
                            return false;
                        }
                    }
                }
            }
            else
            {
                if (bugunGelenMod != null)
                {
                    PlayerData.BugunGelenMod dataBugunGelenMod = falOyunOner.currentPlayerData.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));

                    if (dataBugunGelenMod != null)
                    {
                        if (dataBugunGelenMod.count >= bugunGelenMod.count)
                        {
                            return false;
                        }
                    }
                }
            }
            return true;
        });
        List<BilgiEkraniSettings.HizliFalOyun.Element> elementListWithValue = new();

        foreach (BilgiEkraniSettings.HizliFalOyun.Element cleanElement in elementListClean)
        {
            for (int i = 0; i < cleanElement.falDegeri; i++)
            {
                elementListWithValue.Add(cleanElement);
            }
        }

        elementListWithValue.Shuffle();
        element = elementListWithValue[Random.Range(0, elementListWithValue.Count)];

        this.element = element;

        text.text = (string.IsNullOrEmpty(element.sanaOzelTitle)) ? element.title : element.sanaOzelTitle;

        PreferencesObject.BugunGelenMod bugunGelenMod = falOyunOner.preferences.gunlukModlar.Find(x => x.uIInformation.title.Equals(element.title));

        if (string.IsNullOrEmpty(element.mod))
        {
            TextBackground.EffectGradient = falOyunOner.textDeactiveGradient;
            image.sprite = element.iconDeactive;
            frameImage.color = falOyunOner.frameDeactiveColor;
            clickable = false;
            if (plusBadge != null)
                plusBadge.color = frameImage.color;
            return;
        }
        else
        {
            TextBackground.EffectGradient = currentTextGradient;
            image.sprite = element.icon;
            frameImage.color = currentFrameColor;
            if (plusBadge != null)
                plusBadge.color = frameImage.color;
        }

        if (bugunGelenMod == null)
        {
            return;
        }
        if (plus)
        {
            PlayerData.BugunGelenMod dataBugunGelenMod = falOyunOner.currentPlayerData.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));
            if (dataBugunGelenMod == null)
                return;

            if (dataBugunGelenMod.count < bugunGelenMod.countPlus)
            {
                return;
            }
        }
        else
        {
            PlayerData.BugunGelenMod dataBugunGelenMod = falOyunOner.currentPlayerData.datas.bugunGelenMods.Find(x => x.mod.Equals(bugunGelenMod.mod));
            if (dataBugunGelenMod == null)
                return;

            if (dataBugunGelenMod.count < bugunGelenMod.count)
            {
                return;
            }
        }

        TextBackground.EffectGradient = falOyunOner.textDeactiveGradient;
        image.sprite = element.iconDeactive;
        frameImage.color = falOyunOner.frameDeactiveColor;
        clickable = false;
        if (plusBadge != null)
            plusBadge.color = frameImage.color;
    }

    public void ClickButton()
    {
        if (!string.IsNullOrEmpty(element.mod) && clickable)
        {
            if (falOyunOner.currentPlayerData.datas.energy >= element.energy)
            {
                if (falOyunOner.currentPlayerData.datas.konsantrasyon >= element.kons)
                {
                    bool plus = falOyunOner.currentPlayerData.GetChatVariableValue("plus") == "var";

                    if (element.plus && !plus)
                    {
                        //Magazayi acan bir fonksiyon yazilacak.
                        //Bu ne boyle!
                        GameObject.Find("PanelMagaza").GetComponent<RectTransform>().GetChild(0).gameObject.SetActive(true);
                        GameObject.Find("PanelMagaza").GetComponent<RectTransform>().GetChild(0).GetComponent<StoreMenu>().SetAnimatorState(1);
                        return;
                    }

                    var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                    welcomeScreen.ButtonSohbeteGec(element.mod);

                    falOyunOner.energyManager.AddEnergy(-element.energy, 0);
                    falOyunOner.konsManager.AddEnergy(0, -element.kons);

                    //Panel tekrar acildiginda onerilerin yenilenmesi icin
                    falOyunOner.sonOneriDate = System.DateTime.Now.AddMinutes(-10);
                }
                else
                {
                    var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                    welcomeScreen.SetActive(false, false);

                    var chatManager = FindObjectOfType<ChatManager>();

                    chatManager.chatScreenActivityManager.SetActive();
                    chatManager.introManager.SetChatWallpaperActive();

                    chatManager.chatIsActive = true;

                    chatManager.DelayedCall(.2f, () =>
                    {
                        chatManager.ClickVirtualButton("konsantrasyon bitti");
                    });

                    chatManager.reklamSonuModu = string.Empty;
                }
            }
            else
            {
                var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                welcomeScreen.SetActive(false, false);

                var chatManager = FindObjectOfType<ChatManager>();

                chatManager.chatScreenActivityManager.SetActive();
                chatManager.introManager.SetChatWallpaperActive();

                chatManager.chatIsActive = true;

                chatManager.DelayedCall(.2f, () =>
                {
                    chatManager.ClickVirtualButton("enerji bitti");
                });

                chatManager.reklamSonuModu = element.mod;
            }
        }
    }
}
