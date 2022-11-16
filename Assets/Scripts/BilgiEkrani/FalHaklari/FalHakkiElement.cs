using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FalHakkiElement : MonoBehaviour
{
    //Managerden alincak!!!
    bool plus;
    private int remaeningCount;

    [HideInInspector] public PreferencesObject.BugunGelenMod gunlukMod;
    [HideInInspector] public BilgiEkraniSettings.HizliFalOyun.Element hizliFalOyunElement;

    public FalHakkiManager falHakkiManager;

    public Text titleText;
    public Image icon;

    public Text normalCountText, plusCountText, remaeningCountText;

    public FalHakkiManager.Button button;

    // Start is called before the first frame update
    IEnumerator Start()
    {
        yield return new WaitForEndOfFrame();
        plus = (falHakkiManager.playerData.GetChatVariableValue("plus") == "var");
        UpdateUI();
        falHakkiManager.updateUI += UpdateUI;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void UpdateUI()
    {
        var savedInformation = falHakkiManager.playerData.datas.
            bugunGelenMods.Find(x => x.mod.Equals(gunlukMod.mod));

        titleText.text = gunlukMod.uIInformation.title;
        icon.sprite = gunlukMod.uIInformation.Icon;

        normalCountText.text = gunlukMod.count.ToString();
        plusCountText.text = gunlukMod.countPlus.ToString();

        int dailyUse = (savedInformation != null) ? savedInformation.count : 0;

        remaeningCount = (plus ? gunlukMod.countPlus : gunlukMod.count) - dailyUse;
        remaeningCountText.text = remaeningCount.ToString();

        hizliFalOyunElement = falHakkiManager.bilgiEkraniSettings.hizliFalOyun.fallar.
        Find(x => x.mod.Equals(gunlukMod.mod));

        button.SetActive(remaeningCount > 0 && hizliFalOyunElement != null);
    }

    public void FalAcButonu()
    {
        if (hizliFalOyunElement != null)
        {
            if (remaeningCount > 0)
            {
                var welcomeScreen = FindObjectOfType<WelcomeScreen>();
                falHakkiManager.altinManager.AddEnergy(-hizliFalOyunElement.energy, 0);
                falHakkiManager.elmasManager.AddEnergy(0, -hizliFalOyunElement.kons);
                welcomeScreen.ButtonSohbeteGec(hizliFalOyunElement.mod);
            }
        }
    }
}
