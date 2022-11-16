using DG.Tweening;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using UnityEngine;
using UnityEngine.UI;
using Magnus.UI;
using TMPro;
using Firebase.Database;
using Firebase.Extensions;

public class BilgiEkraniManager : MonoBehaviour
{
    public Panel panel;

    public Image backgroundImage;

    public BilgiEkraniSettings bilgiEkraniSettings;

    private ChatVariables chatVariables;

    public Vector2 mainButtonsFirsPos;

    [HideInInspector] public bool isEditMode;

    [HideInInspector] public CurrentPlayerData playerData;

    public AdvancedGraph modalityGraph;
    public AdvancedGraph polarityGraph;
    public AdvancedGraph elementGraph;

    public GameObject kontrolPaneliButonu;
    public GameObject onlineFalMevcutIcon;

    public TMP_Text karsilamaMetni;
    private string karsilamaMesaji = string.Empty;
    private string duzenlemeMesaji = string.Empty;
    private string gelenKutusuMesaji = string.Empty;
    private string falHaklariMesaji = string.Empty;

    public GameObject inboxNotification;

    public delegate void OnEditModStart();
    public OnEditModStart onEditModStart;

    public delegate void OnEditModEnd();
    public OnEditModEnd onEditModEnd;

    public delegate void OnSaveEdits();
    public OnSaveEdits onSaveEdits;

    private BilgiEkraniAciklamaPopUp aciklamaPopUp;

    private void Awake()
    {
        kontrolPaneliButonu.SetActive(false);
        playerData = FindObjectOfType<CurrentPlayerData>();
        chatVariables = FindObjectOfType<ChatVariables>();

        aciklamaPopUp = GetComponentInChildren<BilgiEkraniAciklamaPopUp>(true);
        aciklamaPopUp.SetActive(true);
    }

    // Start is called before the first frame update
    void Start()
    {
        onEditModStart += OnEditMod;
        onEditModEnd += EndEditMod;

        BackgroundAnim();
    }

    private void OnEnable()
    {
        CheckInboxNotificationState();
        OnlineFalVarMiKontrol();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void KarsilamaMetniAyarla()
    {
        if (playerData.localPlayerDatas.karsilamaMetniData == null)
        {
            playerData.localPlayerDatas.karsilamaMetniData = new();
        }

        if (bilgiEkraniSettings.karsilamaMesaji.karsilamaMesajlari.Count > 0)
        {
            if (bilgiEkraniSettings.karsilamaMesaji.karsilamaMesajlari.Count > 0)
            {
                if (playerData.localPlayerDatas.karsilamaMetniData.karsilama.Count <= 0)
                {
                    playerData.localPlayerDatas.karsilamaMetniData.karsilama = new();
                    for (int i = 0; i < bilgiEkraniSettings.karsilamaMesaji.karsilamaMesajlari.Count; i++)
                    {
                         
                        playerData.localPlayerDatas.karsilamaMetniData.karsilama.Add(i);
                    }
                }
            }
            System.Random meesageValue = new System.Random();
            int mesajIndex = meesageValue.Next(0, playerData.localPlayerDatas.karsilamaMetniData.karsilama.Count - 1);
            karsilamaMesaji = chatVariables.OrtakButonlar(bilgiEkraniSettings.karsilamaMesaji.karsilamaMesajlari[playerData.localPlayerDatas.karsilamaMetniData.karsilama[mesajIndex]]);
            playerData.localPlayerDatas.karsilamaMetniData.karsilama.RemoveAt(mesajIndex);

            if (bilgiEkraniSettings.karsilamaMesaji.duzenlemeMesajlari.Count > 0)
            {
                if (playerData.localPlayerDatas.karsilamaMetniData.duzenleme.Count <= 0)
                {
                    playerData.localPlayerDatas.karsilamaMetniData.duzenleme = new();
                    for (int i = 0; i < bilgiEkraniSettings.karsilamaMesaji.duzenlemeMesajlari.Count; i++)
                    {
                         
                        playerData.localPlayerDatas.karsilamaMetniData.duzenleme.Add(i);
                    }
                }
            }
            meesageValue = new System.Random();
            mesajIndex = meesageValue.Next(0, playerData.localPlayerDatas.karsilamaMetniData.duzenleme.Count - 1);
            duzenlemeMesaji = chatVariables.OrtakButonlar(bilgiEkraniSettings.karsilamaMesaji.duzenlemeMesajlari[playerData.localPlayerDatas.karsilamaMetniData.duzenleme[mesajIndex]]);
            playerData.localPlayerDatas.karsilamaMetniData.duzenleme.RemoveAt(mesajIndex);

            if (bilgiEkraniSettings.karsilamaMesaji.gelenKutusuMesajlari.Count > 0)
            {
                if (playerData.localPlayerDatas.karsilamaMetniData.gelenKutusu.Count <= 0)
                {
                    playerData.localPlayerDatas.karsilamaMetniData.gelenKutusu = new();
                    for (int i = 0; i < bilgiEkraniSettings.karsilamaMesaji.gelenKutusuMesajlari.Count; i++)
                    {
                         
                        playerData.localPlayerDatas.karsilamaMetniData.gelenKutusu.Add(i);
                    }
                }
            }
            meesageValue = new System.Random();
            mesajIndex = meesageValue.Next(0, playerData.localPlayerDatas.karsilamaMetniData.gelenKutusu.Count - 1);
            gelenKutusuMesaji = chatVariables.OrtakButonlar(bilgiEkraniSettings.karsilamaMesaji.gelenKutusuMesajlari[playerData.localPlayerDatas.karsilamaMetniData.gelenKutusu[mesajIndex]]);
            playerData.localPlayerDatas.karsilamaMetniData.gelenKutusu.RemoveAt(mesajIndex);

            if (bilgiEkraniSettings.karsilamaMesaji.falHaklariMesajlari.Count > 0)
            {
                if (playerData.localPlayerDatas.karsilamaMetniData.falHaklari.Count <= 0)
                {
                    playerData.localPlayerDatas.karsilamaMetniData.falHaklari = new();
                    for (int i = 0; i < bilgiEkraniSettings.karsilamaMesaji.falHaklariMesajlari.Count; i++)
                    {
                         
                        playerData.localPlayerDatas.karsilamaMetniData.falHaklari.Add(i);
                    }
                }
            }
            meesageValue = new System.Random();
            mesajIndex = meesageValue.Next(0, playerData.localPlayerDatas.karsilamaMetniData.falHaklari.Count - 1);
            falHaklariMesaji = chatVariables.OrtakButonlar(bilgiEkraniSettings.karsilamaMesaji.falHaklariMesajlari[playerData.localPlayerDatas.karsilamaMetniData.falHaklari[mesajIndex]]);
            playerData.localPlayerDatas.karsilamaMetniData.falHaklari.RemoveAt(mesajIndex);
        }

        KarsilamaMetniAyarla("karsilama");
    }

    public void KarsilamaMetniAyarla(string type)
    {
        karsilamaMetni.text = type switch
        {
            "karsilama" => karsilamaMesaji,
            "duzenleme" => duzenlemeMesaji,
            "gelenKutusu" => gelenKutusuMesaji,
            "falHaklari" => falHaklariMesaji,
            _ => karsilamaMesaji,
        };
    }

    public bool CheckInboxNotificationState()
    {
        try
        {
            RenderedText son5MetinTexts = playerData.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");

            if (son5MetinTexts != null)
            {
                if (son5MetinTexts.renderedTexts != null)
                {
                    foreach (RenderedText.Text text in son5MetinTexts.renderedTexts)
                    {
                        if (!text.isOpened)
                        {
                            inboxNotification.SetActive(true);
                            return true;
                        }

                        if (text.uIInformation.showTimeStamp > 0 &&
                           text.uIInformation.showTimeStamp - Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now) <= 0)
                        {
                            inboxNotification.SetActive(true);
                            return true;
                        }
                    }
                }
            }
        }
        catch
        {
            Debug.LogError("Inboc Notification kontrol edilemedi.");
        }
        inboxNotification.SetActive(false);
        return false;
    }

    public void OnlineFalVarMiKontrol()
    {
        if (playerData.datas.isAdmin)
        {
            onlineFalMevcutIcon.SetActive(false);

            FirebaseDatabase.DefaultInstance
            .GetReference("OnlineFallar")
            .GetValueAsync().ContinueWithOnMainThread(task =>
            {
                if (!task.IsFaulted && !task.IsCanceled)
                {
                    if (task.Result.Value != null)
                    {
                        onlineFalMevcutIcon.SetActive(true);
                        Debug.Log("Yan?tlanmay? bekleyen premium fal mevcut.");
                        return;
                    }
                }
                else
                {
                    Debug.LogError("Bir hata meydana geldi.");
                }

                Debug.Log("Yan?tlanmay? bekleyen premium fal mevcut de?il.");
                onlineFalMevcutIcon.SetActive(false);
            });
        }
        else
        {
            onlineFalMevcutIcon.SetActive(false);
        }
    }

    public void EditModeSwitch()
    {
        isEditMode = !isEditMode;

        if (isEditMode)
            onEditModStart();
        else
            onEditModEnd();
    }

    public void OnEditMod()
    {
        isEditMode = true;
        panel.summaryPanel.gameObject.SetActive(false);
        panel.editPanel.gameObject.SetActive(true);
    }

    public void EndEditMod()
    {
        isEditMode = false;
        panel.summaryPanel.gameObject.SetActive(true);
        panel.editPanel.gameObject.SetActive(false);
    }

    public void SaveEdits()
    {
        isEditMode = false;

        panel.summaryPanel.gameObject.SetActive(true);
        panel.editPanel.gameObject.SetActive(false);

        onSaveEdits();
    }

    public void BackgroundAnim()
    {
        backgroundImage.DOFade(0.8f, 0);
        backgroundImage.DOFade(0.3f, 1.5f);
    }

    public async void AstrologyGraphsRequest(int day, int month, int year, int hour, int min, float lat, float lon)
    {
        float tzone = await FirstWelcomeScreenManager.RequestTimeZone(day, month, year, lat, lon);

        string data = JsonConvert.SerializeObject(new FirstWelcomeScreenManager.AstrologyApiRequestData(day, month, year, hour, min, (float)System.Math.Round((decimal)lat, 2), (float)System.Math.Round((decimal)lon, 2), tzone));

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                Content = new System.Net.Http.StringContent(data, Encoding.UTF8, "application/json"),
                RequestUri = new System.Uri("https://json.astrologyapi.com/v1/natal_chart_interpretation"),
            })
            {
                string contentJsonString = await request.Content.ReadAsStringAsync();

                string apiKey = "618158" + ":" + "5baea1bb862488ad92f6e614dc540f98";
                var apiKeyBytes = System.Text.Encoding.UTF8.GetBytes(apiKey);
                var apiKeyData = System.Convert.ToBase64String(apiKeyBytes);

                request.Headers.TryAddWithoutValidation("dataType", "json");
                request.Headers.TryAddWithoutValidation("authorization", "Basic " + apiKeyData);

                var multipartContent = new MultipartFormDataContent();

                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                AstrologyGraphs responseValue = JsonUtility.FromJson<AstrologyGraphs>(jsonString);

                float totalPolarity = (responseValue.polarity.positive + responseValue.polarity.negative) / 100f;

                polarityGraph.elements[0].value = responseValue.polarity.positive / 100f * (1f / totalPolarity);
                polarityGraph.elements[1].value = responseValue.polarity.negative / 100f * (1f / totalPolarity);

                playerData.AddElementToChatVariableList("polarite feminen", ((int)responseValue.polarity.positive).ToString());
                playerData.AddElementToChatVariableList("polarite maskulen", ((int)responseValue.polarity.negative).ToString());

                modalityGraph.elements[0].value = responseValue.modes.modes[0].percentage / 100f;
                modalityGraph.elements[1].value = responseValue.modes.modes[1].percentage / 100f;
                modalityGraph.elements[2].value = responseValue.modes.modes[2].percentage / 100f;

                playerData.AddElementToChatVariableList("modalite kardinal", ((int)responseValue.modes.modes[0].percentage).ToString());
                playerData.AddElementToChatVariableList("modalite degisken", ((int)responseValue.modes.modes[1].percentage).ToString());
                playerData.AddElementToChatVariableList("modalite sabit", ((int)responseValue.modes.modes[2].percentage).ToString());

                elementGraph.elements[0].value = responseValue.elements.elements[0].percentage / 100f;
                elementGraph.elements[1].value = responseValue.elements.elements[1].percentage / 100f;
                elementGraph.elements[2].value = responseValue.elements.elements[2].percentage / 100f;
                elementGraph.elements[3].value = responseValue.elements.elements[3].percentage / 100f;

                playerData.AddElementToChatVariableList("element ates", ((int)responseValue.elements.elements[0].percentage).ToString());
                playerData.AddElementToChatVariableList("element toprak", ((int)responseValue.elements.elements[1].percentage).ToString());
                playerData.AddElementToChatVariableList("element hava", ((int)responseValue.elements.elements[2].percentage).ToString());
                playerData.AddElementToChatVariableList("element su", ((int)responseValue.elements.elements[3].percentage).ToString());

                polarityGraph.Initialaze(true);
                modalityGraph.Initialaze(true);
                elementGraph.Initialaze(true);
            }
        }
    }

    [System.Serializable]
    public class Panel
    {
        public RectTransform summaryPanel;
        public RectTransform editPanel;
    }

    [System.Serializable]
    public class AstrologyGraphs
    {
        public Modes modes;

        [System.Serializable]
        public class Modes
        {
            public Mode[] modes;

            [System.Serializable]
            public class Mode
            {
                public string name;
                public float percentage;
            }
        }

        public Elements elements;

        [System.Serializable]
        public class Elements
        {
            public Element[] elements;

            [System.Serializable]
            public class Element
            {
                public string name;
                public float percentage;
            }
        }

        public Polarity polarity;

        [System.Serializable]
        public class Polarity
        {
            public float positive;
            public float negative;
            public string report;
        }
    }
}
