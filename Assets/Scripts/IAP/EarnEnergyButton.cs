using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Button))]
public class EarnEnergyButton : MonoBehaviour
{
    CurrentPlayerData currentPlayerData;
    Button button;

    public Color deactiveColor;
    Color normalColor;

    public int energyAmount;
    public int konsAmount;

    public EnergyManager energyManager;
    public EnergyManager konsManager;

    public string buttonId;

    // Start is called before the first frame update
    void Start()
    {
        currentPlayerData = FindObjectOfType<CurrentPlayerData>();
        button = GetComponent<Button>();
        button.onClick.AddListener(OnClick);

        normalColor = GetComponent<Image>().color;

        CheckState();
    }

    private void OnEnable()
    {
        if (currentPlayerData != null)
            CheckState();
    }

    void OnClick()
    {
        currentPlayerData.datas.usedEarnEnergyButtons.Add(buttonId);

        energyManager.AddEnergy(energyAmount, 0);
        konsManager.AddEnergy(0, konsAmount);

        CheckState();
    }

    void CheckState()
    {
        button.enabled = !currentPlayerData.datas.usedEarnEnergyButtons.Contains(buttonId);
        GetComponent<Image>().color = (button.enabled) ? normalColor : deactiveColor;
    }
}
