using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FalOyunOner : MonoBehaviour
{
    public BilgiEkraniSettings bilgiEkraniSettings;
    public PreferencesObject preferences;
    [HideInInspector] public CurrentPlayerData currentPlayerData;

    public List<FalOyunOneriElement> elements;

    public int falSecmeYuzdesi = 70;

    public Color oyunFrameActiveColor;
    public Color falFrameActiveColor;
    public Color frameDeactiveColor;

    public Gradient textFalActiveGradient;
    public Gradient textOyunActiveGradient;
    public Gradient textDeactiveGradient;

    public delegate void UpdateUIDelegate();
    public UpdateUIDelegate updateUI;

    public DateTime sonOneriDate;

    public EnergyManager energyManager;
    public EnergyManager konsManager;

    public bool debug = false;

    private void Awake()
    {
        currentPlayerData = FindObjectOfType<CurrentPlayerData>();
        updateUI += UpdateUI;
    }

    // Start is called before the first frame update
    void Start()
    {
        updateUI();

        if (debug)
            StartCoroutine(DebugDeneme());
    }

    private void OnEnable()
    {
        if ((DateTime.Now - sonOneriDate).TotalMinutes >= 5)
        {
            updateUI();
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void UpdateUI()
    {
        sonOneriDate = DateTime.Now;
    }

    public IEnumerator DebugDeneme()
    {
        while (true)
        {
            updateUI();

            yield return new WaitForSeconds(.1f);

            for (int i = 0; i < elements.Count; i++)
            {
                for (int u = 0; u < elements.Count; u++)
                {
                    if (i != u)
                    {
                        if (elements[i].text.text == elements[u].text.text)
                        {

                            Debug.LogError("Ayni element bulundu!");
                            Debug.LogError(elements[i].text.text);
                            Debug.LogError(elements[u].text.text);
                            yield break;
                        }
                    }
                }
            }
        }


    }
}
