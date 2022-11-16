using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class BilgiEkraniAciklamaPopUp : MonoBehaviour
{
    private BilgiEkraniManager bilgiEkraniManager;
    private ChatVariables chatVariables;

    public TMP_Text text;

    [SerializeField] internal float duration = 5f;

    Dictionary<string, BilgiEkraniSettings.AciklamaPopUpData.Aciklama[]> popUpDefaultDatas;
    Dictionary<string, BilgiEkraniSettings.AciklamaPopUpData.Aciklama[]> popUpDatas;

    private BilgiEkraniSettings.AciklamaPopUpData data;

    [SerializeField] private RectTransform buttonsParent;
    [SerializeField] private Animator animator;

    string currentKey;

    bool isActive;

    private void Awake()
    {
        bilgiEkraniManager = GetComponentInParent<BilgiEkraniManager>();
        chatVariables = FindObjectOfType<ChatVariables>();

        data = bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp;
    }

    // Start is called before the first frame update
    void Start()
    {
        data = SaveData.LoadObject("bilgiEkraniAciklamaPopUp.magnus") as BilgiEkraniSettings.AciklamaPopUpData;
        SetAciklamaPopUpDatas();
        gameObject.SetActive(true);
    }

    private void OnDisable()
    {
        SetActive(false);
    }

    private void SetAciklamaPopUpDatas()
    {
        if (data == null)
        {
            data = bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.Clone();
        }
        popUpDefaultDatas = new Dictionary<string, BilgiEkraniSettings.AciklamaPopUpData.Aciklama[]>();

        popUpDefaultDatas.Add("dogumTarihi", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.dogumTarihi);
        popUpDefaultDatas.Add("cinsiyet", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.cinsiyet);
        popUpDefaultDatas.Add("medeniDurum", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.medeniDurum);
        popUpDefaultDatas.Add("meslek", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.meslek);
        popUpDefaultDatas.Add("dogumSaati", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.dogumSaati);
        popUpDefaultDatas.Add("dogumYeri", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.dogumYeri);
        popUpDefaultDatas.Add("burc", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.burc);
        popUpDefaultDatas.Add("gezegen", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.gezegen);
        popUpDefaultDatas.Add("yukselen", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.yukselen);
        popUpDefaultDatas.Add("ayburcu", bilgiEkraniManager.bilgiEkraniSettings.aciklamaPopUp.ayburcu);

        popUpDatas = new Dictionary<string, BilgiEkraniSettings.AciklamaPopUpData.Aciklama[]>();

        popUpDatas.Add("dogumTarihi", data.dogumTarihi);
        popUpDatas.Add("cinsiyet", data.cinsiyet);
        popUpDatas.Add("medeniDurum", data.medeniDurum);
        popUpDatas.Add("meslek", data.meslek);
        popUpDatas.Add("dogumSaati", data.dogumSaati);
        popUpDatas.Add("dogumYeri", data.dogumYeri);
        popUpDatas.Add("burc", data.burc);
        popUpDatas.Add("gezegen", data.gezegen);
        popUpDatas.Add("yukselen", data.yukselen);
        popUpDatas.Add("ayburcu", data.ayburcu);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetActive(bool active)
    {
        SetDeactiveAllButtonBg();

        isActive = active;
        //gameObject.SetActive(active);

        if (deactivateDelay != null)
            StopCoroutine(deactivateDelay);

        if (active && gameObject.activeInHierarchy)
        {
            deactivateDelay = DeactivateDelay();
            StartCoroutine(deactivateDelay);
        }

        if (!active)
            currentKey = string.Empty;

        animator.SetInteger("decreption", active ? 1 : 2);
    }

    public void SetActive(bool active, string aciklamaKey)
    {
        SetDeactiveAllButtonBg();

        var currentData = popUpDatas[aciklamaKey];
        var currentAciklama = GetAciklama(currentData);

        if (currentAciklama == null)
        {
            if (popUpDefaultDatas[aciklamaKey].Length > 0)
            {
                data = null;
                SetAciklamaPopUpDatas();

                SetActive(active, aciklamaKey);
            }
            return;
        }
        else if (currentAciklama.text.Count <= 0)
        {
            currentAciklama.text = new List<string>(GetAciklama(popUpDatas[aciklamaKey]).text);
        }

        int index = Random.Range(0, currentAciklama.text.Count);
        text.text = chatVariables.OrtakButonlar(currentAciklama.text[index]);
        currentAciklama.text.RemoveAt(index);

        SaveData.SaveObject("bilgiEkraniAciklamaPopUp.magnus", data);
        
        SetActive(active);

        currentKey = aciklamaKey;
    }

    public void SetActiveWithKey(string aciklamaKey)
    {
        if (aciklamaKey != currentKey)
        {
            SetActive(true, aciklamaKey);
            return;
        }

        StartCoroutine(SetDeactiveWithDelay());
    }

    private IEnumerator deactivateDelay;
    private IEnumerator DeactivateDelay()
    {
        yield return new WaitForSeconds(duration);
        deactivateDelay = null;
        SetActive(false);
    }

    private void SetDeactiveAllButtonBg()
    {
        for (int i = 0; i < buttonsParent.childCount; i++)
        {
            var background = buttonsParent.GetChild(i).GetComponent<RectTransform>().Find("SelectedBackground");

            if (background != null)
                background.gameObject.SetActive(false);
        }
    }

    private IEnumerator SetDeactiveWithDelay()
    {
        yield return new WaitForEndOfFrame();
        SetActive(false);
        SetDeactiveAllButtonBg();
    }

    private BilgiEkraniSettings.AciklamaPopUpData.Aciklama GetAciklama(BilgiEkraniSettings.AciklamaPopUpData.Aciklama[] aciklamalar)
    {
        BilgiEkraniSettings.AciklamaPopUpData.Aciklama degiskensizAciklama = null;

        aciklamalar.Shuffle();

        foreach (BilgiEkraniSettings.AciklamaPopUpData.Aciklama aciklama in aciklamalar)
        {
            if (aciklama.text.Count > 0)
            {
                if (aciklama.degisken == null)
                {
                    degiskensizAciklama = aciklama;
                }

                if (string.IsNullOrEmpty(aciklama.degisken.degiskenAdi))
                {
                    degiskensizAciklama = aciklama;
                }
                else if (aciklama.degisken.degiskenDegeri ==
                    bilgiEkraniManager.playerData.GetChatVariableValue(aciklama.degisken.degiskenAdi))
                {
                    return aciklama;
                }
            }
        }

        return degiskensizAciklama;
    }
}


public static class BilgiEkraniAciklamaPopUpExtenstion
{
    public static BilgiEkraniSettings.AciklamaPopUpData Clone(this BilgiEkraniSettings.AciklamaPopUpData defaultData)
    {
        BilgiEkraniSettings.AciklamaPopUpData data = new BilgiEkraniSettings.AciklamaPopUpData();

        data.dogumTarihi = defaultData.dogumTarihi.CloneAciklamlar();
        data.cinsiyet = defaultData.cinsiyet.CloneAciklamlar();
        data.medeniDurum = defaultData.medeniDurum.CloneAciklamlar();
        data.meslek = defaultData.meslek.CloneAciklamlar();
        data.dogumSaati = defaultData.dogumSaati.CloneAciklamlar();
        data.dogumYeri = defaultData.dogumYeri.CloneAciklamlar();
        data.burc = defaultData.burc.CloneAciklamlar();
        data.gezegen = defaultData.gezegen.CloneAciklamlar();
        data.yukselen = defaultData.yukselen.CloneAciklamlar();
        data.ayburcu = defaultData.ayburcu.CloneAciklamlar();

        return data;
    }

    public static BilgiEkraniSettings.AciklamaPopUpData.Aciklama[] CloneAciklamlar(this BilgiEkraniSettings.AciklamaPopUpData.Aciklama[] defAciklamalar)
    {
        BilgiEkraniSettings.AciklamaPopUpData.Aciklama[] aciklamalar = new BilgiEkraniSettings.AciklamaPopUpData.Aciklama[defAciklamalar.Length];
        for (int i = 0; i < aciklamalar.Length; i++)
        {
            aciklamalar[i] = new BilgiEkraniSettings.AciklamaPopUpData.Aciklama();
            aciklamalar[i].degisken = defAciklamalar[i].degisken;
            aciklamalar[i].text = new List<string>(defAciklamalar[i].text);
        }
        return aciklamalar;
    }

    public static void Shuffle<T>(this T[] array)
    {
        System.Random rng = new System.Random();
        int n = array.Length;
        while (n > 1)
        {
            int k = rng.Next(n--);
            T temp = array[n];
            array[n] = array[k];
            array[k] = temp;
        }
    }
}