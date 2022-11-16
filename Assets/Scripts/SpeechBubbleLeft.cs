using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Michsky.UI.ModernUIPack;
using TMPro;
using Magnus;
using System.Text.RegularExpressions;
using Firebase.Storage;
using Firebase.Extensions;
using UnityEngine.Networking;

public class SpeechBubbleLeft : MonoBehaviour
{
    //*****************************Kullanim Amaci*****************************
    //targetposition degiskeni bu cevap baloncugunun gitmesi gereken noktanin koordinatlarini barindiran degiskendir.
    //Baloncugun mevcut pozisyonu bu degere her bir framede Move fonksiyonunda belirtildigi oranda yaklasir.
    [HideInInspector] public Vector3 targetPosition;

    //*****************************Kullanim Amaci*****************************
    //previousTartgetPosition degiskeni baloncuk hareket etmeye basladigi anda baloncugun bulundugu degeri icinde barindirir.
    //Bu basitce baloncugun hareket ettigi yonu anlamakta kullanilir.
    //Detaylar SetPositionToRealPotion fonksiyonuna bak.
    private Vector3 previousTartgetPosition;

    [HideInInspector] public bool isActive;
    [HideInInspector] public bool movable;
    [HideInInspector] public int bubbleType;
    [HideInInspector] public int variation;
    [HideInInspector] public Sohbet sohbet;
    [HideInInspector] public TakipSohbeti takipSohbet;
    [HideInInspector] public bool takipSohbetiAktif;
    [HideInInspector] public string sohbettenCikMetini;
    [HideInInspector] public bool forceToMultipleLines;
    [HideInInspector] public int contentIndex;
    [HideInInspector] public bool contentImageActive;
    [HideInInspector] public bool justPhoto;
    [HideInInspector] public List<SpeechBubbleLeft> realtedBubbles;
    [HideInInspector] public float startTime;
    [HideInInspector] public ChatManager chatManager;
    [HideInInspector] public bool sayacAktif;
    [HideInInspector] public string sohbetId;
    [HideInInspector] public RectTransform contentImageRt;

    private bool gifSizeSet;

    public TMP_Text textMain;
    public TMP_Text text;
    public Button button;
    public RectTransform rt;
    public ContentSizeFitter contFilter;
    public RectTransform profilePhotoRect;
    public Image contentImage;
    public float animationDuration;
    public RectTransform sayacSilderRect;
    public Color continueTextColor;
    public string continueText;
    public GameObject timerFolder;
    public RectTransform timerImageRect;

    public void Start()
    {
        /*
        if (!string.IsNullOrEmpty(sohbet.contentImage.gifId) && sohbet.contentImage.gifId!= chatManager.magnusPreferences.wheelChartConentPhotoId && sohbet.contentImage.gifId != chatManager.magnusPreferences.kullaniciPhotoId)
        {
            contentImage.GetComponent<ProGifPlayerImage>().loadPath = $"https://media.giphy.com/media/{sohbet.contentImage.gifId}/giphy.gif";
            contentImage.GetComponent<ProGifPlayerImage>().enabled = true;
        }
        else
        {
            contentImage.GetComponent<ProGifPlayerImage>().enabled = false;
        }*/
            
        contentImageRt = contentImage.GetComponent<RectTransform>();

        SetPosition();
        AddButtonListeners();

        if (chatManager.sohbetTimer > 0)
            sayacAktif = true;
    }

    void Update()
    {
        //SetPositionToTargetPosition();
        //CheckIfShouldDestroy();
        SayacUpdate();
        //SetGifPhotoSize();
    }

    void SetGifPhotoSize()
    {/*
        if (!gifSizeSet)
        {
            if (!string.IsNullOrEmpty(sohbet.contentImage.gifId))
            {
                if (contentImage.GetComponent<ProGifPlayerImage>().isActiveAndEnabled)
                {
                    if (contentImage.GetComponent<ProGifPlayerImage>().width == contentImage.sprite.rect.width)
                    {
                        contentImageRt.localScale = new Vector3((float)contentImage.GetComponent<ProGifPlayerImage>().width / (float)contentImage.GetComponent<ProGifPlayerImage>().height, contentImageRt.localScale.y, contentImageRt.localScale.z);

                        gifSizeSet = true;
                    }
                }
            }
        }*/
    }

    void SayacUpdate()
    {
        if (sayacAktif)
        {
            if (chatManager.sohbetTimer <= 0)
            {
                sayacAktif = false;
                sayacSilderRect.transform.localScale = new Vector3(0, 0, sayacSilderRect.transform.localScale.z);
                sayacSilderRect.gameObject.SetActive(false);
                timerFolder.SetActive(false);
                Destroy(this);
            }
            else
            {
                if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.bar || sohbet.sayacTipi == Sohbet.sayacTipiEnum.barVeEkrandaText)
                {
                    if (!timerFolder.activeInHierarchy)
                    {
                        if (contentIndex == realtedBubbles.Count - 1)
                        {
                            timerFolder.SetActive(true);
                        }
                    }
                    else 
                    {
                        if (contentIndex == realtedBubbles.Count - 1)
                        {
                            timerImageRect.sizeDelta = new Vector2(timerImageRect.GetComponent<RectTransform>().parent.GetComponent<RectTransform>().rect.width * (chatManager.sohbetTimer / sohbet.sayac), timerImageRect.sizeDelta.y);
                        }
                        else
                        {
                            timerFolder.SetActive(false);
                        }
                    }
                }
                else
                {
                    timerFolder.SetActive(false);
                }

                if (sohbet.sayacTipi == Sohbet.sayacTipiEnum.balonIciGolge)
                {
                    sayacSilderRect.transform.localScale = new Vector3(chatManager.sohbetTimer / sohbet.sayac, sayacSilderRect.transform.localScale.y, sayacSilderRect.transform.localScale.z);
                }
                else
                {
                    if (sayacSilderRect.gameObject.activeSelf)
                        sayacSilderRect.gameObject.SetActive(false);
                }
            }
        }
        else
        {
            sayacSilderRect.transform.localScale = new Vector3(0, 0, sayacSilderRect.transform.localScale.z);
            sayacSilderRect.gameObject.SetActive(false);
            timerFolder.SetActive(false);
        }
    }

    public void SetTextObjects()
    {
        ChatManager chatManager = GameObject.Find("ChatManager").GetComponent<ChatManager>();
        ChatVariables chatVariables = GameObject.Find("ChatVariables").GetComponent<ChatVariables>();

        if (bubbleType == 0)
        {
            if (sohbettenCikMetini == "")
            {
                if (sohbet.contentImage.image != null || !string.IsNullOrEmpty(sohbet.contentImage.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
                {
                    if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaSonda)
                    {
                        if (chatVariables.GetBubbleCount(sohbet.aciklama[0]) == contentIndex)
                        {
                            text.text = "";
                            justPhoto = true;
                        }
                        else
                        {
                            if (!string.IsNullOrWhiteSpace(sohbet.aciklama[variation]))
                                text.text = sohbet.aciklama[variation];
                            if (chatManager.aciklamasiEklenecekSohbetler.Count > 0)
                                text.text += "\n\n";

                            sohbetId += sohbet.idIndex.ToString();

                            foreach (AciklamaSohbetleri element in chatManager.aciklamasiEklenecekSohbetler)
                            {
                                text.text += element.sohbet.aciklama[Random.Range(0, element.sohbet.aciklama.Count)] + "\n\n";
                                sohbetId += "|" + element.sohbet.idIndex.ToString();
                            }
                        }
                    }
                    else if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaBasta)
                    {
                        if (contentIndex == 0)
                        {
                            text.text = "";
                            justPhoto = true;
                        }
                        else
                        {
                            if (!string.IsNullOrWhiteSpace(sohbet.aciklama[variation]))
                                text.text = sohbet.aciklama[variation];
                            if (chatManager.aciklamasiEklenecekSohbetler.Count > 0)
                                text.text += "\n\n";

                            sohbetId += sohbet.idIndex.ToString();

                            foreach (AciklamaSohbetleri element in chatManager.aciklamasiEklenecekSohbetler)
                            {
                                text.text +=  element.sohbet.aciklama[Random.Range(0, element.sohbet.aciklama.Count)] + "\n\n";
                                sohbetId += "|" + element.sohbet.idIndex.ToString();
                            }
                        }
                    }
                    else
                    {
                        if (!string.IsNullOrWhiteSpace(sohbet.aciklama[variation]))
                            text.text = sohbet.aciklama[variation];
                        if (chatManager.aciklamasiEklenecekSohbetler.Count > 0)
                            text.text += "\n\n";

                        sohbetId += sohbet.idIndex.ToString();

                        foreach (AciklamaSohbetleri element in chatManager.aciklamasiEklenecekSohbetler)
                        {
                            text.text +=  element.sohbet.aciklama[Random.Range(0, element.sohbet.aciklama.Count)] + "\n\n";
                            sohbetId += "|" + element.sohbet.idIndex.ToString();
                        }
                    }
                }
                else
                {
                    if (!string.IsNullOrWhiteSpace(sohbet.aciklama[variation]))
                        text.text = sohbet.aciklama[variation];
                    if (chatManager.aciklamasiEklenecekSohbetler.Count > 0)
                        text.text += "\n\n";

                    sohbetId += sohbet.idIndex.ToString();

                    foreach (AciklamaSohbetleri element in chatManager.aciklamasiEklenecekSohbetler)
                    {
                        text.text += element.sohbet.aciklama[Random.Range(0, element.sohbet.aciklama.Count)] + "\n\n";
                        sohbetId += "|" + element.sohbet.idIndex.ToString();
                    }
                }
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(sohbet.aciklama[variation]))
                    text.text = sohbet.aciklama[variation];
                if (chatManager.aciklamasiEklenecekSohbetler.Count > 0)
                    text.text += "\n\n";

                sohbetId += sohbet.idIndex.ToString();

                foreach (AciklamaSohbetleri element in chatManager.aciklamasiEklenecekSohbetler)
                {
                    text.text += element.sohbet.aciklama[Random.Range(0, element.sohbet.aciklama.Count)] + "\n\n";
                    sohbetId += "|" + element.sohbet.idIndex.ToString();
                }
            }
        }

        //Metinlerde yanlışlıkla kullanılan emojileri ve özel karakterleri kaldıran kodlar.
        text.text = Regex.Replace(text.text, @"\p{Cs}", "");
        text.text = text.text.Replace(" ️️", "");
        text.text = text.text.Replace("⭐", "");
        text.text = text.text.Replace("☝", "");

        text.text = ReplaceChatVariables(text.text);

        textMain.text = text.text;

        if (chatManager.PlayerDataManager.localPlayerDatas.renderedTexts != null)
        {
            //do something
        }

        StartCoroutine(MetniKaydet());
    }

    private IEnumerator MetniKaydet()
    {
        yield return new WaitForSeconds(chatManager.AiMessageDelay);

        string mod = chatManager.PlayerDataManager.GetChatVariableValue("mod");

        if (!sohbet.metniKaydet || string.IsNullOrEmpty(text.text))
        {
            yield break;
        }
        
        string sohbetText = string.Empty;
        foreach (SpeechBubbleLeft bubble in realtedBubbles)
        {
            sohbetText += bubble.text.text;
        }
        
        string imageID = sohbet.contentImage.imageId;
        if (sohbet.contentImage.image != null)
        {
            if (string.IsNullOrEmpty(imageID))
            {
                imageID = FindObjectOfType<PhotoManager>().GetLocalSpriteId(sohbet.contentImage.image);
            }
        }
        
        if (chatManager.PlayerDataManager.localPlayerDatas.renderedTexts == null)
        {
            chatManager.PlayerDataManager.localPlayerDatas.renderedTexts = new List<RenderedText>();
        }

        var welcomScreen = FindObjectOfType<WelcomeScreen>();
        BilgiEkraniSettings.Inbox.InboxElement inboxElement = welcomScreen.bilgiEkraniSettings
            .inbox.inboxElements.Find(x => x.mod.Equals(mod));
        
        if (inboxElement == null)
            inboxElement = welcomScreen.bilgiEkraniSettings
            .inbox.defaultElement;

        RenderedText son5MetinTexts = chatManager.PlayerDataManager
            .localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");

        long showTime = 0;
        if (inboxElement.delay.y > 0)
            showTime = Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now.AddMinutes(Random.Range(inboxElement.delay.x, inboxElement.delay.y)));
        string earlyText = string.Empty;

        if (this == realtedBubbles[0] || mod != "tefeul")
        {
            if (son5MetinTexts != null)
            {

                while (son5MetinTexts.renderedTexts.Count >= 10)
                {

                    son5MetinTexts.renderedTexts.RemoveAt(0);
                }

                //son5MetinTexts.renderedTexts.Add(new RenderedText.TextDeneme(textMain.text, sohbet.contentImage.imageId));
                if (chatManager.tarotSohbetleri.Count != 3)
                {

                    if (chatManager.tarotSohbetleri.Count != 1)
                    {

                        son5MetinTexts.renderedTexts.Add(new RenderedText.Text(mod, sohbetText, imageID, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                    else
                    {

                        son5MetinTexts.renderedTexts.Add(new RenderedText.Text(mod, sohbetText, chatManager.tarotSohbetleri[0].contentImage.image.name, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                }
                else
                {
                    //Tarot icin yapilan kontrol. Daha iyi bir yol bulup kaldirilacak!!!
                    son5MetinTexts.renderedTexts.Add(new RenderedText.Text(mod, sohbetText, $"{chatManager.tarotSohbetleri[0].contentImage.image.name}," +
                        $"{chatManager.tarotSohbetleri[1].contentImage.image.name},{chatManager.tarotSohbetleri[2].contentImage.image.name}", sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                }
            }
            else
            {

                if (chatManager.tarotSohbetleri.Count != 3)
                {

                    if (chatManager.tarotSohbetleri.Count != 1)
                    {

                        chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", mod, sohbetText, imageID, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                    else
                    {

                        chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", mod, sohbetText, chatManager.tarotSohbetleri[0].contentImage.image.name, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                }
                else
                {

                    //Tarot icin yapilan kontrol. Daha iyi bir yol bulup kaldirilacak!!!
                    chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", mod, sohbetText, $"{chatManager.tarotSohbetleri[0].contentImage.image.name}," +
                        $"{chatManager.tarotSohbetleri[1].contentImage.image.name},{chatManager.tarotSohbetleri[2].contentImage.image.name}", sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                }
            }


            RenderedText modTexts = chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Find(x => x.name == mod);
            if (modTexts != null)
            {

                while (modTexts.renderedTexts.Count >= 10)
                {

                    modTexts.renderedTexts.RemoveAt(0);
                }

                //son5MetinTexts.renderedTexts.Add(new RenderedText.TextDeneme(textMain.text, sohbet.contentImage.imageId));

                if (chatManager.tarotSohbetleri.Count != 3)
                {

                    if (chatManager.tarotSohbetleri.Count != 1)
                    {

                        modTexts.renderedTexts.Add(new RenderedText.Text(mod, sohbetText, imageID, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                    else
                    {

                        modTexts.renderedTexts.Add(new RenderedText.Text(mod, sohbetText, chatManager.tarotSohbetleri[0].contentImage.image.name, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                }
                else
                {
                    Debug.LogError("ddsadsa");
                    //Tarot icin yapilan kontrol. Daha iyi bir yol bulup kaldirilacak!!!
                    modTexts.renderedTexts.Add(new RenderedText.Text(mod, sohbetText, $"{chatManager.tarotSohbetleri[0].contentImage.image.name}," +
                        $"{chatManager.tarotSohbetleri[1].contentImage.image.name},{chatManager.tarotSohbetleri[2].contentImage.image.name}", sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                }
            }
            else
            {

                if (chatManager.tarotSohbetleri.Count != 3)
                {

                    if (chatManager.tarotSohbetleri.Count != 1)
                    {

                        chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText(mod, mod, sohbetText, imageID, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                    else
                    {

                        chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText(mod, mod, sohbetText, chatManager.tarotSohbetleri[0].contentImage.image.name, sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                    }
                }
                else
                {
                    //Tarot icin yapilan kontrol. Daha iyi bir yol bulup kaldirilacak!!!
                    chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText(mod, mod, sohbetText, $"{chatManager.tarotSohbetleri[0].contentImage.image.name}," +
                        $"{chatManager.tarotSohbetleri[1].contentImage.image.name},{chatManager.tarotSohbetleri[2].contentImage.image.name}", sohbet.GetSohbetId(), true, new RenderedText.Text.UIInformation(inboxElement.title, showTime)));
                }
            }
        }
    }

    public string ReplaceChatVariables(string text)
    {
        ChatVariables chatVariables = GameObject.Find("ChatVariables").GetComponent<ChatVariables>();

        if ((sohbet.contentImage.image == null && string.IsNullOrEmpty(sohbet.contentImage.gifId)) && string.IsNullOrEmpty(sohbet.contentImage.imageId) || sohbet.fotografKonum == Sohbet.contentPhotoLocation.balonIcindeBasta || sohbet.fotografKonum == Sohbet.contentPhotoLocation.balonIcindeSonda)
        {
            //Bu degisken texti belirledigi icin ilk basta kontrol edilir.
            text = chatVariables.NewBubble(text, contentIndex);
        }
        else
        {
            if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaBasta)
            {
                if (contentIndex - 1 >= 0)
                {
                    //Bu degisken texti belirledigi icin ilk basta kontrol edilir.
                    text = chatVariables.NewBubble(text, contentIndex - 1);
                }
            }
            else
            {
                text = chatVariables.NewBubble(text, contentIndex);
            }
        }
        text = chatVariables.OrtakButonlar(text);

        forceToMultipleLines = chatVariables.CheckForceMultipleLine(text);

        return text;
    }

    void AddButtonListeners() 
    {
        PanelShowWholeTextManager showPanel = FindObjectOfType<PanelShowWholeTextManager>();

        button.onClick.AddListener(() => showPanel.OpenPanel(realtedBubbles, sohbet));
    }

    void CheckIfShouldDestroy()
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();
        ChatScreenActivity chatScreenActivity = GameObject.Find("ChatScreen").GetComponent<ChatScreenActivity>();

        if (rt.position.y > canvasRt.position.y + canvasRt.sizeDelta.y * canvasRt.localScale.y || !chatScreenActivity.isChatScreenActive)
        {
            for (int i = 0; i < rt.childCount; i++)
            {
                if (rt.GetChild(i).gameObject.activeInHierarchy)
                {
                    if (gameObject.GetComponent<TMP_SubMeshUI>() == null)
                        rt.GetChild(i).gameObject.SetActive(false);
                }
            }
        }
        else
        {
            for (int i = 0; i < rt.childCount; i++)
            {
                if (!rt.GetChild(i).gameObject.activeInHierarchy)
                {
                    rt.GetChild(i).gameObject.SetActive(true);
                }
            }
        }

    }

    public void SetPosition()
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();
        ChatManager chatManager = FindObjectOfType<ChatManager>();
   

        if (!sohbet.aciklamaBalonuYok)
        {
            SetTargetPosition(rt.position);

            float firstXPos = canvasRt.sizeDelta.x / 2f + rt.sizeDelta.x / 2f * chatManager.spaceBetweenBubbles;

            rt.position = GameGeneral.MoveRecttransform(rt.position, canvasRt, new Vector2(-firstXPos, -200));

            SetTargetPosition(new Vector3(canvasRt.position.x - (canvasRt.sizeDelta.x / 2f - rt.sizeDelta.x / 2f - 30f - profilePhotoRect.sizeDelta.x) * canvasRt.localScale.x,
                targetPosition.y + (rt.sizeDelta.y / 2f + chatManager.spaceBetweenBubbles) * canvasRt.localScale.y, targetPosition.z));
        }
        else
        {
            SetTargetPosition(new Vector3(5000f, rt.position.y, rt.position.z));

            rt.position = new Vector3(5000f, rt.position.y, rt.position.z);

            //ekran disi bir bolgeye at x exseninde
            SetTargetPosition(new Vector3((5000) * canvasRt.localScale.x,
       targetPosition.y + (rt.sizeDelta.y / 2f + 25) * canvasRt.localScale.y, targetPosition.z));
        }
    }

    void SetContentImageSprite()
    {
        if (sohbet.contentImage.gifId == chatManager.magnusPreferences.wheelChartConentPhotoId)
        {
            contentImage.sprite = chatManager.wheelChartSprite;
        }
        else if (sohbet.contentImage.gifId == chatManager.magnusPreferences.kullaniciPhotoId)
        {
            contentImage.sprite = FindObjectOfType<WelcomeScreen>().profilePhotoImage.sprite;
        }
        else
        {
            if (!string.IsNullOrEmpty(sohbet.contentImage.gifId))
            {
                if (sohbet.contentImage.image == null)
                {
                    contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent;
                }
                else
                {
                    contentImage.sprite = sohbet.contentImage.image;
                }
            }
            else
            {
                if (sohbet.contentImage.image == null)
                {
                    if (!string.IsNullOrEmpty(sohbet.contentImage.imageId))
                    {
                        contentImage.sprite = chatManager.magnusPreferences.defaultLoadingContent;

                        var photoManager = FindObjectOfType<PhotoManager>();
                        Sprite localPhoto = photoManager.GetSprite(sohbet.contentImage.imageId);

                        if(localPhoto == null)
                        {
                            Debug.Log("Firebase veritabanindan fotograf alınıyor");
                            GetOnlineSprite(sohbet.contentImage.imageId);
                        }
                        else
                        {
                            contentImage.sprite = localPhoto;
                        }
                    }
                }
                else
                {
                    contentImage.sprite = sohbet.contentImage.image;
                }
            }
       
        }
        contentImageActive = true;
    }

    /// <summary>
    /// Baloncugun turune gore boyutunu ayarlayan fonksiyon. Bu fonksiyon ayni zaman  SetTextFontSize() fonksiyonunu da cagirir.
    /// </summary>
    public void SetFirstSizes()
    {
        //contentSizeFilter componentinin kod blogunun basinda none degerine esitlenmesinin nedeni, normalde obje bu kodu cagirdiginda bu sekilde bulumasi gereken compenentin defualt
        //degerlerinin unityEditor icerisinde yanliklikla baska degere ayarlanmasi sonucu olusabilecek hatalarin onune gecmektir.
        SetContentSizeFilter("none");

        ChatVariables chatVariables = GameObject.Find("ChatVariables").GetComponent<ChatVariables>();

        if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.balonIcindeBasta)
        {
            if (sohbet.contentImage.image != null  || !string.IsNullOrEmpty(sohbet.contentImage.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
            {
                if (contentIndex == 0)
                {
                    SetContentImageSprite();
                    text.alignment = TextAlignmentOptions.TopJustified;
                    textMain.alignment = text.alignment;
                }
            }
        }
        else if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.balonIcindeSonda)
        {
            if (sohbet.contentImage.image != null || !string.IsNullOrEmpty(sohbet.contentImage.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
            {
                if (contentIndex == 0)
                {
                    SetContentImageSprite();
                    text.alignment = TextAlignmentOptions.BottomJustified;
                    textMain.alignment = text.alignment;
                }
            }
        }

        if (sohbet.contentImage.image != null || !string.IsNullOrEmpty(sohbet.contentImage.gifId) || !string.IsNullOrEmpty(sohbet.contentImage.imageId))
        {
            if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaSonda)
            {
                if (chatVariables.GetBubbleCount(sohbet.aciklama[0]) == contentIndex)
                {
                    SetContentImageSprite();
                }
            }
            else if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.ayriBalondaBasta)
            {
                if (contentIndex == 0)
                {
                    SetContentImageSprite();
                }
            }
        }

        contentImage.gameObject.SetActive(contentImageActive);

        //Canvas objesinin RectTransform componentine erisilmesi.
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        //genislik ve yukseklik degerlerinin ayarlanmasi.
        //maxWidth degeri canvasin boyutuna yuzdelik olarak ayarlanir.
        float maxWidth = canvasRt.sizeDelta.x * (80f / 100f);
        float minWidth = 50f;
        float maxWidthWithPhoto = canvasRt.sizeDelta.x * (45f / 100f);

        float minHeight = 35f;
        float maxHeight = 200;

        //****************************  BALONCUGUN FOTOGRAF TIPINE GORE TURU  ****************************
        //justPhoto degiskeni ile baloncugun icindeki fotografin ana baloncugun icinde olan bir fotografli baloncuk olup olmadigi anlasilir.
        //Eger baloncuk sadece fotograf gostermek icin uretilmis TEXT barindirmayan bir baloncuk ise justPhoto degiskeni TRUE degerini alir.
        //Bu degiskenin degeri SetTextObjects() fonksiyonunun icinde ayarlanir.
        if (!justPhoto)
        {
            //****************************  contentIndex DEGISKENI NE ISE YARAR?  ****************************
            //contentIndex degiskeni text bir sohbet objesinin aciklama kismindaki yazi '||' metin degiskeni ile birden
            //fazla baloncuga bolunduyse bu baloncugun kacinci sohbet baloncugu oldugunu kontrol eder.

            //Bu kisma gecildigine gore mevcut sohbet dosyasinda baloncugun icinde bulunacak bir fotograf bulundugu anlasilir. Asagidaki if kosulu ile
            //kontrol edilen durum ise eger birden fazla baloncuk ayni anda spawn oldu ise bu baloncugun fotografin icinde oldugu ilk balon olup olmadigi anlasilir.
            if (contentIndex != 0 || !contentImageActive)
            {
                //****************************  #1 - BALONCUGUN HORIZONTAL OLARAK TEXTE GORE BOYUTLANDIRILMASI.  ****************************
                //Ilk once horizontal olarak texte gore boyut ayarliyoruz. Bunu once yapmamizin sebebi eger balon horizontal olarak max boyuta ulasmamissa vertical uzunlugu standart boyutta birakip horizontal olarak
                //boyutlandiriyoruz. 
                SetContentSizeFilter("horizontal");
                rt.sizeDelta = new Vector2(rt.sizeDelta.x, minHeight);

                //****************************  Canvas.ForceUpdateCanvases() FONKSIYONUNUN KULLANIM NEDENI  ****************************
                //ContentSize filter componenti ile her yapilan boyutlandirma isleminden sonra Canvas Update'e zorlanmalidir. Aksi taktirde size'in ayarlanmasi birkac frame sonraya atilabilir
                //bu durumda boyut mevcut frame icinde alanamadigi icin boyutlandirmada hatalar olusur.
                Canvas.ForceUpdateCanvases();

                //Yukaridaki #1 nolu kisimda sadece yatay duzlemde texte gore boyutlandirma ayarladigimiz icin simdi kontrol etmemiz gereken durum yatay duzlemde baloncugun bizim olmasini istedigimiz
                //Maksimum degerden daha buyuk bir degere esitlenip esitlenmedigi. Eger balouncugun yatay boyutu olmasini istedigimiz maksimum boyur olan maxWidth degerinden buyukse
                //artik yatay duzlemdeki boyutunu ContentSizeFitter compoenenti ile ayarlamak yerine maxWidth componentinin degerine sabitliyoruz. Dusey boyutunu ise ContentSizeFitter componenti ile ayarliyoruz.
                if (rt.sizeDelta.x > maxWidth || forceToMultipleLines)
                {
                    SetContentSizeFilter("vertical");
                    rt.sizeDelta = new Vector2(maxWidth, rt.sizeDelta.y);
                }
                else if (rt.sizeDelta.x < minWidth)                                                 //Onemli bir diger kontrol de eger yatay boyutun alabilecegi minumum deger olan minWidth'den kucuk oldugu durum. 
                {                                                                                   //Bu durumda ise ContentSizeFitter compenentinin hem yatayda hem duseyde boyut ayarlamasini kapatiyoruz ve
                    SetContentSizeFilter("none");
                    rt.sizeDelta = new Vector2(minWidth, minHeight);
                }
                Canvas.ForceUpdateCanvases();

                //Vertical uzunluk olabilecek max uzunluktan buyukse bu durumda baloncugun boyutu maxHeight degerine sabitlenir ve textin geri kalani baloncugun icindeki bir
                //scrollRect componenti ile kaydirilabilecek sekilde gosterilir.
                if (rt.sizeDelta.y > maxHeight)
                {
                    SetContentSizeFilter("none");
                    rt.sizeDelta = new Vector2(maxWidth, maxHeight);
                    Canvas.ForceUpdateCanvases();

                    char[] textMainChar = textMain.text.ToCharArray();
                    char[] ekMetinChar = continueText.ToCharArray();

                    if (textMain.textInfo.pageCount > 0)
                    {
                        textMain.text = "";
                        for (int i = textMain.textInfo.pageInfo[0].firstCharacterIndex; i < textMain.textInfo.pageInfo[0].lastCharacterIndex - (("  ...".ToCharArray().Length) + ekMetinChar.Length) - 5; i++)
                        {
                            textMain.text += textMainChar[i];
                        }
                        textMain.text += $"  <color=#{ColorUtility.ToHtmlStringRGB(continueTextColor)}><b><u>" + continueText + "...</u></b></color>";
                    }
                }
            }
            else                                                                                                //****************************  BALONCUGUN ICINDE FOTOGRAF VE TEXT VAR  ****************************
            {                                                                                                   //Bu kisim baloncugun icinde fotograf varken altinda ya da ustunde de text oldugu anlamina gelir. Bu ozellik whatshapp'taki
                                                                                                                //fotograflo mesaj baloncuklari ile bire bir ayni sekilde calisir.

                text.alignment = TextAlignmentOptions.Left;
                textMain.alignment = text.alignment;
                //Oncelikle width degeri fotografli mesaj baloncuklarin alacagi degere esitlenir.
                rt.sizeDelta = new Vector2(maxWidthWithPhoto, rt.sizeDelta.y);

                //Asagidaki kisimda ContentSizeFilter componenti ile once dusey eksende baloncugun boyutu textin boyutuna orantili olmasi icin SetContentSizeFilter("vertical") fonksiyonu cagrilir.
                SetContentSizeFilter("vertical");
                //Yukaridaki fonksiyon cagirildiktan sonra dusey duzlemde baloncuk textin boyutuna esitlenmis olur. Ama yapilmasi gereken son sey bu adimdan sonra fotorafin boyutunu da baloncuga
                //ekleyecegimiz icin ContentSizeFilter compoenentinin baloncugun boyutunu texte gore ayarlamasini bu satirdan sonra devre disi birakmaktir.
                SetContentSizeFilter("none");

                //Baloncugun mevcut yukseklik degeri bir degiskene atanir. Boylece bu deger ilerki adimlarda fotografin anchor pointlerinin ayarlanmasinda kullanilir.
                float textBoxHeight = rt.sizeDelta.y;
                if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.balonIcindeBasta)
                {
                    //Fotografin baloncugun icine yerlesiminde textin altta ya da ustte olusuna gore fotografin altta ya da ustte textin dusey boyutu kadar bosluk birakmasi gerekir. Bu deger az once textBoxHeight degiskenine atanan degerdir.
                    //Bu degiksen kullanilarak fotografin achor pointleri ayarlanir ve textin altta ya da ustte olmasi icin Text componentinde ayarlamalar gerceklesir.
                    contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMax.y);
                    contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, textBoxHeight);

                    //Son olarak baloncugun boyutu fotografin en boy oranlarina uyumlu olacak sekilde yatay duzlemdeki uzunlugunun kati bir deger alir.
                    rt.sizeDelta = new Vector2(rt.sizeDelta.x, rt.sizeDelta.y + maxWidthWithPhoto * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x));

                    textMain.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(textMain.gameObject.GetComponent<RectTransform>().offsetMax.x, -contentImage.gameObject.GetComponent<RectTransform>().rect.height - chatManager.bubbleFrameBlank / 2f);
                    textMain.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(textMain.gameObject.GetComponent<RectTransform>().offsetMin.x, textMain.gameObject.GetComponent<RectTransform>().offsetMin.y);


                }
                else if (sohbet.fotografKonum == Sohbet.contentPhotoLocation.balonIcindeSonda)
                {
                    //Fotografin baloncugun icine yerlesiminde textin altta ya da ustte olusuna gore fotografin altta ya da ustte textin dusey boyutu kadar bosluk birakmasi gerekir. Bu deger az once textBoxHeight degiskenine atanan degerdir.
                    //Bu degiksen kullanilarak fotografin achor pointleri ayarlanir ve textin altta ya da ustte olmasi icin Text componentinde ayarlamalar gerceklesir.
                    contentImage.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMax.x, -textBoxHeight);
                    contentImage.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(contentImage.gameObject.GetComponent<RectTransform>().offsetMin.x, contentImage.gameObject.GetComponent<RectTransform>().offsetMin.y);

                    //Son olarak baloncugun boyutu fotografin en boy oranlarina uyumlu olacak sekilde yatay duzlemdeki uzunlugunun kati bir deger alir.
                    rt.sizeDelta = new Vector2(rt.sizeDelta.x, rt.sizeDelta.y + maxWidthWithPhoto * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x));

                    textMain.gameObject.GetComponent<RectTransform>().offsetMax = new Vector2(textMain.gameObject.GetComponent<RectTransform>().offsetMax.x, textMain.gameObject.GetComponent<RectTransform>().offsetMax.y);
                    textMain.gameObject.GetComponent<RectTransform>().offsetMin = new Vector2(textMain.gameObject.GetComponent<RectTransform>().offsetMin.x, contentImage.gameObject.GetComponent<RectTransform>().rect.height + chatManager.bubbleFrameBlank / 2f);
                }
            }
        }
        else
        {
            //Asagidaki kisimda ContentSizeFilter componenti ile once dusey eksende baloncugun boyutu textin boyutuna orantili olmasi icin SetContentSizeFilter("vertical") fonksiyonu cagrilir.
            SetContentSizeFilter("vertical");
            //Yukaridaki fonksiyon cagirildiktan sonra dusey duzlemde baloncuk textin boyutuna esitlenmis olur. Ama yapilmasi gereken son sey bu adimdan sonra fotorafin boyutunu da baloncuga
            //ekleyecegimiz icin ContentSizeFilter compoenentinin baloncugun boyutunu texte gore ayarlamasini bu satirdan sonra devre disi birakmaktir.
            SetContentSizeFilter("none");

            //Son olarak baloncugun boyutu fotografin en boy oranlarina uyumlu olacak sekilde yatay duzlemdeki uzunlugunun kati bir deger alir.
            rt.sizeDelta = new Vector2(maxWidthWithPhoto, maxWidthWithPhoto * (contentImage.sprite.rect.size.y / contentImage.sprite.rect.size.x));
        }

        Canvas.ForceUpdateCanvases();
    }

    private void SetContentSizeFilter(string axis)
    {
        if (axis == "horizontal")
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
        }
        else if (axis == "vertical")
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        }
        else
        {
            contFilter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            contFilter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
        }
        contFilter.SetLayoutVertical();
        contFilter.SetLayoutHorizontal();
        Canvas.ForceUpdateCanvases();
    }

    /// <summary>
    /// targetPosition degiskenini mevcut pozisyona ayarlayan fonksiyon.
    /// </summary>
    public void SetMovableFalse()
    {
        //rt.position = targetPosition;
        movable = false;
    }

    /// <summary>
    /// Her bir frame'de cagrilan ve rectTransform componentinin pozisyon degerini realPosition degerine yaklastiran fonksiyon.
    /// </summary>
    public void SetPositionToTargetPosition()
    {
        //****************************  movable DEGISKENI NE ISE YARIYOR?  ****************************
        //Eger baloncuk hareket edebilir turde ise kontrolu yapilir. Bu kontrolun yapilma amaci, eger baloncuklarin gelme animasyonu tamamlanirsa baloncuklarin hareketi scrollRect componenti
        //tarafindan kontrol edilir. Bu sayede baloncuklari ekranda belirli bir noktaya sabitleyen asagidaki kodlar calismaz.

        //****************************  isActive DEGISKENI NE ISE YARIYOR?  ****************************
        //Isactive degiskeni baloncugun olustugu anda target position'a gitmesini engeller. Baloncuklarin belirli siralamalar ile hedeflerine gitmesini istedigimiz icin
        //baloncuklari olusturduktan sonra belirli sureler ile isActive degiskenini baloncuklar icin devre disi birakiriz. Bu degiksen ne zama TRUE degerini alirsa
        //o zaman baloncugun targetPosition'a dogru gitmesini saglayacak asagidaki kodlar calismaya balsar bu kontrol ile.
        float t = (Time.time - startTime) / animationDuration;
        if (movable && isActive)
        {
            //****************************************************************************************************************************************************************************************************
            rt.position = new Vector3(Mathf.SmoothStep(previousTartgetPosition.x, targetPosition.x, t), Mathf.SmoothStep(previousTartgetPosition.y, targetPosition.y, t), rt.position.z);
        }
    }

    public void OpenTefeulBook()
    {
        if (chatManager.PlayerDataManager.GetChatVariableValue("mod") == "tefeul")
        {
            if (realtedBubbles.Count > 1)
                chatManager.bookManager.OpenPanel(realtedBubbles[0].text.text, realtedBubbles[1].text.text);
            else
                chatManager.bookManager.OpenPanel(text.text, "");
        }
    }

    public void SetTargetPosition(Vector3 targetPosition)
    {
        RectTransform rt = GetComponent<RectTransform>();

        this.targetPosition = targetPosition;
        previousTartgetPosition = rt.position;
    }

    public void GetOnlineSprite(string fileName)
    {
        Sprite downloadedSprite = FindObjectOfType<PhotoManager>().GetDownloadedSprite(fileName);
        if (downloadedSprite == null)
        {
            FirebaseStorage storage = FirebaseStorage.DefaultInstance;

            // Create a storage reference from our storage service
            StorageReference storageRef =
                storage.GetReferenceFromUrl("gs://magnus-338513.appspot.com");

            // Create a reference to the file you want to upload
            StorageReference riversRef = storageRef.Child("Images/" + fileName);

            // Start downloading a file
            riversRef.GetDownloadUrlAsync().ContinueWithOnMainThread(taskGetUrl =>
            {
                Debug.Log("Image url is: " + taskGetUrl.Result.ToString());
                StartCoroutine(DownloadImage(fileName, taskGetUrl.Result.ToString()));

            });
        }
        else
        {
            Debug.Log("Fotoğraf daha önce indirildiği için tekrar indirilmedi.");
            contentImage.sprite = downloadedSprite;
        }
    }

    IEnumerator DownloadImage(string fileName, string url)
    {
        UnityWebRequest request = UnityWebRequestTexture.GetTexture(url);
        yield return request.SendWebRequest();
        if (request.isNetworkError || request.isHttpError)
            Debug.Log(request.error);
        else
        {
            Texture2D texture = ((DownloadHandlerTexture)request.downloadHandler).texture;
            Debug.Log("Wheel chart basariyla indirildi ve kaydedildi.");
            contentImage.sprite = Sprite.Create(texture, new Rect(0.0f, 0.0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100.0f);
            FindObjectOfType<PhotoManager>().AddTextureToDownloadedTexture(fileName, contentImage.sprite);
        }
    }
}
