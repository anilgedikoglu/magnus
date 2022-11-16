using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Newtonsoft.Json;
using System.Net.Http;
using Firebase.Database;
using System;
using Michsky.UI.ModernUIPack;
using TMPro;

public class InAppReview : MonoBehaviour
{
    private AuthenticationManager authenticationManager;
    private RealtimeDatabaseManager realtimeDatabaseManager;
    private CurrentPlayerData playerData;

    public PanelShowWholeTextManager focusPanel;
    public ZoomPanelData zoomPanelData;

    public VerticalLayoutGroup generalLayoutGroup;
    public ContentSizeFitter tepkiTextContentSize;

    public string starReaction1;
    public string starReaction2;
    public string starReaction3;
    public string starReaction4;
    public string starReaction5;

    public TMP_InputField inputField;
    public TMP_Text starReactionText;

    public Color firstStarColor, lastStarColor;

    public Sprite filledStar, emptyStar;

    public List<Image> stars;
    private int currentGivenStars = 0;

    private InAppPopUp popUp;
    [SerializeField] private GameObject degerlendirButton;

    private void Awake()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        playerData = FindObjectOfType<CurrentPlayerData>();
        popUp = GetComponentInChildren<InAppPopUp>(true);

        currentGivenStars = 0;

        var chatVariables = FindObjectOfType<ChatVariables>();

        if (zoomPanelData.yildizTepkileri.yildiz1.Count > 0)
            starReaction1 = chatVariables.OrtakButonlar(
                zoomPanelData.yildizTepkileri.yildiz1[UnityEngine.Random.Range(0,
                zoomPanelData.yildizTepkileri.yildiz1.Count)]);
        
        if (zoomPanelData.yildizTepkileri.yildiz2.Count > 0)
            starReaction2 = chatVariables.OrtakButonlar(
                zoomPanelData.yildizTepkileri.yildiz2[UnityEngine.Random.Range(0,
                zoomPanelData.yildizTepkileri.yildiz2.Count)]);

        if (zoomPanelData.yildizTepkileri.yildiz3.Count > 0)
            starReaction3 = chatVariables.OrtakButonlar(
                zoomPanelData.yildizTepkileri.yildiz3[UnityEngine.Random.Range(0, 
                zoomPanelData.yildizTepkileri.yildiz3.Count)]);

        if (zoomPanelData.yildizTepkileri.yildiz4.Count > 0)
            starReaction4 = chatVariables.OrtakButonlar(
                zoomPanelData.yildizTepkileri.yildiz4[UnityEngine.Random.Range(0,
                zoomPanelData.yildizTepkileri.yildiz4.Count)]);

        if (zoomPanelData.yildizTepkileri.yildiz5.Count > 0)
            starReaction5 = chatVariables.OrtakButonlar(
                zoomPanelData.yildizTepkileri.yildiz5[UnityEngine.Random.Range(0, 
                zoomPanelData.yildizTepkileri.yildiz5.Count)]);
    }

    // Start is called before the first frame update
    void Start()
    {
        SetStarsColor(0);
    }

    private void OnEnable()
    {
        popUp.SetActive(false);
        degerlendirButton.SetActive(true);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void SetStarsColor(int index)
    {
        Color.RGBToHSV(firstStarColor, out float firstH, out float firstS, out float firstV);
        Color.RGBToHSV(lastStarColor, out float lastH, out float lastS, out float lastV);

        for (int i = 0; i < stars.Count; i++)
        {
            if (i < index)
            {
                stars[i].color = Color.HSVToRGB(firstH + ((lastH - firstH) / (stars.Count) * i), firstS, firstV);
                stars[i].sprite = filledStar;
            }
            else
            {
                stars[i].color = Color.white;
                stars[i].sprite = emptyStar;
            }
        }
    }

    public void ClickStar(int index)
    {
        currentGivenStars = index;
        SetStarsColor(currentGivenStars);

        switch(index)
        {
            case 0:
                starReactionText.text = string.Empty;
                starReactionText.color = Color.white;
                break;
            case 1:
                starReactionText.text = starReaction1;
                starReactionText.color = stars[index - 1].color;
                break;
            case 2:
                starReactionText.text = starReaction2;
                starReactionText.color = stars[index - 1].color;
                break;
            case 3:
                starReactionText.text = starReaction3;
                starReactionText.color = stars[index - 1].color;
                break;
            case 4:
                starReactionText.text = starReaction4;
                starReactionText.color = stars[index - 1].color;
                break;
            case 5:
                starReactionText.text = starReaction5;
                starReactionText.color = stars[index - 1].color;
                break;
            default:
                starReactionText.text = string.Empty;
                starReactionText.color = Color.white;
                break;
        }


        tepkiTextContentSize.SetLayoutVertical();
        Canvas.ForceUpdateCanvases();
        generalLayoutGroup.SetLayoutVertical();
    }

    public void SendReview()
    {
        if (currentGivenStars > 0)
        {
            SohbetInceleme sohbetInceleme = new();
            sohbetInceleme.userID = authenticationManager.auth.CurrentUser.UserId;
            sohbetInceleme.sohbetID = focusPanel.sohbetId;
            sohbetInceleme.sohbetMetni = focusPanel.textWithPhoto.text;
            sohbetInceleme.inceleme = inputField.text;
            sohbetInceleme.yildiz = currentGivenStars;
            sohbetInceleme.unixTimeStamp = Magnus.Time.DateTimeOperations.serverUnixTimeStamp;
            sohbetInceleme.platform = Application.platform.ToString();
            sohbetInceleme.appVersion = Application.version;
            sohbetInceleme.userName = playerData.GetChatVariableValue("isim", true) + " " + playerData.GetChatVariableValue("soyisim", true);
            sohbetInceleme.incelemeID = GetNewSohbetId();

            RenderedText son5MetinTexts = playerData.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");

            var uIInfo = new RenderedText.Text.UIInformation(string.Empty, string.Empty);
            uIInfo.firstTimeStamp = Magnus.Time.DateTimeOperations.serverUnixTimeStamp;

            if (son5MetinTexts == null)
            {
                playerData.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", "adminCevapHazirlaniyor", sohbetInceleme.inceleme + "</i>",
                    string.Empty, sohbetInceleme.incelemeID, true, uIInfo));
            }
            else
            {
                son5MetinTexts.renderedTexts.Add(new RenderedText.Text("adminCevapHazirlaniyor", sohbetInceleme.inceleme + "</i>", string.Empty, 
                    sohbetInceleme.incelemeID, true, uIInfo));

                if (son5MetinTexts.renderedTexts.Count > 10)
                {
                    son5MetinTexts.renderedTexts.RemoveAt(0);
                }
            }

            string data = JsonConvert.SerializeObject(sohbetInceleme);
            DateTime date = DateTime.Now;
            realtimeDatabaseManager.SetData("SohbetIncelemeleri/TariheGore/" + $"{date.Day}-{date.Month}-{date.Year}" + "/" + sohbetInceleme.incelemeID, data);
            realtimeDatabaseManager.SetData("SohbetIncelemeleri/SohbeteGore/" + sohbetInceleme.sohbetID + "/" + sohbetInceleme.incelemeID, data);

            popUp.LogSuccess("Mesajınız iletildi.");
        }
        else
        {
            starReactionText.text = "İncelemeni göndermeden önce değerlendirmelisin!";
            starReactionText.color = Color.red;
            Debug.LogError("Kaç yıldız verdiğinizi işaretlemediniz.");
            ClosePanel();
        }
    }

    //Kullanici sayisi cok fazla olmadigi icin simdilik
    //mevcut idler ile olusturulan id'nin cakisması yok
    //sayiliyor. Bu ilerde duzeltilecek.
    private string GetNewSohbetId()
    {
        string letters = "abcdefghijlmnoprstuvyzwxq123456789";
        string returnText = string.Empty;
        for (int i = 0; i < 6; i++)
        {
            returnText += letters[UnityEngine.Random.Range(0, letters.Length)];
        }
        return (DateTime.Now.Day).ToString() + (DateTime.Now.Month).ToString() + (DateTime.Now.Year).ToString() + returnText;
    }

    public void OpenPanel()
    {
        ClearPanel();
        gameObject.SetActive(true);
    }

    public void ClosePanel()
    {
        ClearPanel();
        gameObject.SetActive(false);
    }

    public void ClearPanel()
    {
        ClickStar(0);
        inputField.text = string.Empty;
    }


    [System.Serializable]
    public class SohbetInceleme
    {
        public string incelemeID;
        public string userID;
        public string userName;
        public string appVersion;
        public string platform;
        public string sohbetID;
        public string sohbetMetni;
        public string inceleme;
        public int yildiz;
        public long unixTimeStamp;

        public SohbetInceleme()
        {
            incelemeID = string.Empty;
            userName = string.Empty;
            appVersion = string.Empty;
            platform = string.Empty;
            userID = string.Empty;
            sohbetID = string.Empty;
            sohbetMetni = string.Empty;
            inceleme = string.Empty;
            yildiz = 1;
            unixTimeStamp = 0;
        }
    }

    public class Time
    {
        public long currentFileTime;
    }
}
