using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class TimerItemManager : MonoBehaviour
{
    private CurrentPlayerData playerData;

    static readonly private int maxTimerKonsantrasyon = 10;
    static readonly private int maxTimerKonsantrasyonPlus = 10;

    static public float konsantrasyonDuration = 60f * 48f;
    static public float konsantrasyonDurationPlus = 60f * 24f;

    private float konsantrasyonTimer;

    private bool isActive = false;

    public EnergyManager konsantrasyonManager;

    private void Start()
    {
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    public void Initiliaze()
    {
        isActive = true;
        //CalculateEarneTimerItems();
    }

    private void OnApplicationFocus(bool focus)
    {
        if (focus && isActive)
        {
            //CalculateEarneTimerItems();
        }
    }

    private void Update()
    {
        if (isActive)
        {
            if (konsantrasyonTimer > 0)
            {
                konsantrasyonTimer -= Time.deltaTime;
            }
            else
            {
                Debug.Log("Kullanıcıya konsantrasyon VERİLDİ!!!");
                konsantrasyonTimer = GetMaxTimerKonsantrasyonDuration() * 60f;
                konsantrasyonManager.AddEnergy(0, 1, "1 kazanıldı");
            }
        }
    }

    public void SetActive(bool value)
    {

        if (!isActive)
        {
            if (value)
            {
                isActive = value;
                konsantrasyonTimer = GetMaxTimerKonsantrasyonDuration() * 60f;
            }
        }
        else
        {
            if (!value)
            {
                isActive = value;
            }
        }
    }

    public void CalculateEarneTimerItems()
    {
        int maxKonsantrasyonWithTime = GetMaxTimerKonsantrasyon();

        PlayerData.Date lastKonsantrasyonGivenTimeString = playerData.datas.lastFreekonsantrasyon;
        if (playerData.datas.lastFreekonsantrasyon == new PlayerData.Date(0, 0, 0, 0, 0, 0))
        {
            playerData.datas.lastFreekonsantrasyon = new PlayerData.Date(DateTime.Now);
        }

        DateTime lastKonsantrasyonGivenTime = Magnus.Time.DateTimeOperations.ToDateTime(lastKonsantrasyonGivenTimeString);

        if ((System.DateTime.Now - lastKonsantrasyonGivenTime).TotalSeconds < 0)
        {
            playerData.datas.lastFreekonsantrasyon = new PlayerData.Date(DateTime.Now);
            lastKonsantrasyonGivenTime = DateTime.Now;
        }

        Debug.Log("Kullanıcıya konsantrasyon VERİLDİ!!!");
        int amount = (int)Mathf.Clamp((int)(DateTime.Now - lastKonsantrasyonGivenTime).TotalSeconds / 
            (TimerItemManager.GetMaxTimerKonsantrasyonDuration() * 60f), 0,
            Mathf.Clamp(maxKonsantrasyonWithTime - playerData.datas.konsantrasyon, 0, Mathf.Infinity));

        if (amount > 0)
        {
            konsantrasyonManager.AddEnergy(0, amount);
            playerData.datas.lastFreekonsantrasyon = new PlayerData.Date(DateTime.Now);
        }

        float initialTime = (float)((lastKonsantrasyonGivenTime.AddMinutes((amount + 1) * GetMaxTimerKonsantrasyonDuration()) - DateTime.Now).TotalSeconds);
        if (initialTime < 0)
            initialTime = (amount + 1) * GetMaxTimerKonsantrasyonDuration() * 60f;

        if (GetMaxTimerKonsantrasyon() > playerData.datas.konsantrasyon)
            konsantrasyonTimer = initialTime * 1f;
        else
            isActive = false;

        if (isActive)
            Debug.Log("Sonraki konsantrasyonun verilmesine " + initialTime / 60f + " dakika kaldı");
        else
            Debug.Log("Zamanla konsantrasyon zaten maksimum olduğu için dolmayacak");
    }

    public static float GetMaxTimerKonsantrasyonDuration()
    {
        if (FindObjectOfType<CurrentPlayerData>().GetChatVariableValue("plus") == "var")
        {
            return konsantrasyonDurationPlus;
        }
        else
        {
            return konsantrasyonDuration;
        }
    }

    public static int GetMaxTimerKonsantrasyon()
    {
        if (FindObjectOfType<CurrentPlayerData>().GetChatVariableValue("plus") == "var")
        {
            return maxTimerKonsantrasyonPlus;
        }
        else
        {
            return maxTimerKonsantrasyon;
        }
    }
}
