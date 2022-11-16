using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text;
using Newtonsoft.Json;
using System.Globalization;
using DG.Tweening;

public class FirstWelcomeScreenManager : MonoBehaviour
{
    public string aciklama;
    public string gercekAciklama = "";
    public string cursorChar;
    private string cursorText;

    public CurrentPlayerData playerDataManager;
    public ChatVariables chatVariables;

    public TMP_Text text;
    private RectTransform textRect, canvasRect;
    public RectTransform content;

    public float textUpdateTimer;

    private float cursorTimer;

    [HideInInspector] public List<TerminalSohbet> terminalSohbetleri;

    private bool sohbetSecildi;

    public TerminalSohbet sohbet;
    int ekrandakiSohbetSayisi = 0;

    float writingDelay;

    bool popUpActive;
    bool saatPopClosed;
    bool sehirBulundu = false;

    public GameObject[] popUpMenus;

    int pageNumberIlkAnlatim = 0;
    public RectTransform ilkAnlatimParent;

    public int pageNumber;
    public GameObject[] pages;
    public RectTransform pageIndicatorsParent;
    public RectTransform pageIndicatorsKnob;
    public Animator magnusLogoAnimator;
    public GameObject buttonFolder;
    public GameObject oncekiButton;
    public GameObject devamButton, devamButtonBuyuk;
    public GameObject skipSohbetButton;

    public RectTransform kurulumBar;
    public int kurulumBarProgress = 0;

    public List<string> oncekiSohbetEtiket;

    private TouchScreenKeyboard keyboard;
    public string keyboardText, saatKeyboardText;

    [HideInInspector] public string kaydedilecekDegiskenAdi;
     public string kaydedilecekDegiskenDegeri;

    public string ucNokta;
    public float ucNoktaTimer;

    public PreferencesObject magnusPreferences;

    public CountryCityDatabase countryCityDatabase;

    bool isCitySearching = false;

    public TimeSelecter timeSelecter;

    public string lokasyonIzniVerildiAciklama, lokasyonIzniVerilmediAciklama;

    float changeButtonDeactivated;

    void Start()
    {
        textRect = text.gameObject.GetComponent<RectTransform>();
        canvasRect = GameObject.Find("Canvas").GetComponent<RectTransform>();

        //content = GetComponent<RectTransform>().GetChild(0).GetComponent<RectTransform>();

        keyboard = null;

        oncekiSohbetEtiket = new List<string>();

        TerminalSohbet[] terminalSohbetleriArray = Resources.LoadAll<TerminalSohbet>("SohbetVeriTabani/TerminalVeritabani");

        List<TerminalSohbet> terminalSohbetleriList = new List<TerminalSohbet>();
        foreach (TerminalSohbet element in terminalSohbetleriArray)
        {
            terminalSohbetleriList.Add(element);
        }

        while (terminalSohbetleriList.Count > 0)
        {
            int index = Random.Range(0, terminalSohbetleriList.Count);
            terminalSohbetleri.Add(terminalSohbetleriList[index]);
            terminalSohbetleriList.RemoveAt(index);
        }

        if (buttonFolder.activeInHierarchy)
            buttonFolder.SetActive(false);

        playerDataManager.datas.dahaOnceGeldi = false;

        SohbetSonu("hosgeldin");
    }

    void Update()
    {
        if (changeButtonDeactivated > 0)
        {
            changeButtonDeactivated -= Time.deltaTime;
        }
    }

    public void ChangePage(bool next)
    {
        ChangePageAsync(next);
    }

    private async void ChangePageAsync(bool next)
    {
        if (changeButtonDeactivated <= 0)
        {
            if (FindObjectOfType<OpenWeatherApi>().checkGpsAgain)
            {
                StartCoroutine(FindObjectOfType<OpenWeatherApi>().StartLocal(true));
                FindObjectOfType<OpenWeatherApi>().checkGpsAgain = false;
            }

            if (sohbet.ozelKontrol == "astroloji api" && next)
            {
                buttonFolder.SetActive(false);

                int day;
                int month;
                int year;
                int hour;
                int minute;
                double lat;
                double lon;

                int.TryParse(playerDataManager.GetChatVariableValue("dogum saati"), out hour);
                int.TryParse(playerDataManager.GetChatVariableValue("dogum dakikasi"), out minute);
                int.TryParse(playerDataManager.GetChatVariableValue("dogum gunu"), out day);
                int.TryParse(playerDataManager.GetChatVariableValue("dogum ayi"), out month);
                int.TryParse(playerDataManager.GetChatVariableValue("dogum yili"), out year);
                double.TryParse(playerDataManager.GetChatVariableValue("dogum sehri enlem"), NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lat);
                double.TryParse(playerDataManager.GetChatVariableValue("dogum sehri boylam"), NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lon);

                await AstrologyApiRequestAscendant(day, month, year, hour, minute, (float)lat, (float)lon);
                await AstrologyApiRequestMoonSign(day, month, year, hour, minute, (float)lat, (float)lon);

                buttonFolder.SetActive(true);
            }

            if (next)
            {
                if (!string.IsNullOrEmpty(kaydedilecekDegiskenDegeri) || sohbet.ozelKontrol == "start gps")
                {
                    if (pageNumber + 1 < pageIndicatorsParent.childCount)
                    {
                        pageIndicatorsKnob.DOMove(pageIndicatorsParent.GetChild(pageNumber + 1).position, 0.6f);
                    }
                }
            }
            else
            {
                if (pageNumber - 1 >= 0)
                {
                    pageIndicatorsKnob.DOMove(pageIndicatorsParent.GetChild(pageNumber - 1).position, 0.6f);
                }
            }

            if (!string.IsNullOrEmpty(kaydedilecekDegiskenDegeri) || sohbet.ozelKontrol == "start gps" || !next)
            {
                if (sohbet.ozelKontrol == "gun kontrol")
                {
                    GunDegeriniKontrolEt();
                }

                if (sohbet.popUpIndex != 0 && next)
                {
                    oncekiSohbetEtiket.Add(sohbet.etiket);
                }

                content.DOLocalMove(new Vector2((next) ? -1000 : 1000, content.anchoredPosition.y), 0.3f).onComplete = () =>
                {
                    if (pageNumber < pages.Length)
                    {
                        if (next)
                        {
                            content.anchoredPosition = new Vector2(1000, content.anchoredPosition.y);

                            if (!string.IsNullOrEmpty(kaydedilecekDegiskenDegeri))
                            {
                                if (!string.IsNullOrEmpty(kaydedilecekDegiskenAdi))
                                    playerDataManager.AddElementToChatVariableList(kaydedilecekDegiskenAdi, kaydedilecekDegiskenDegeri);
                                kaydedilecekDegiskenDegeri = string.Empty;
                            }

                            content.DOLocalMove(new Vector2(0, content.anchoredPosition.y), 0.3f);

                            pages[pageNumber].SetActive(false);

                            if (pageNumber < pages.Length - 1)
                                pageNumber++;
                        }
                        else
                        {
                            content.anchoredPosition = new Vector2(-1000, content.anchoredPosition.y);

                            content.DOLocalMove(new Vector2(0, content.anchoredPosition.y), 0.3f);

                            pages[pageNumber].SetActive(false);
                            pageNumber--;
                            pages[pageNumber].SetActive(true);
                        }
                    }
                    else
                    {
                        content.anchoredPosition = new Vector2(1000, content.anchoredPosition.y);

                        content.DOLocalMove(new Vector2(0, content.anchoredPosition.y), 0.3f);

                        if (!string.IsNullOrEmpty(kaydedilecekDegiskenDegeri))
                        {
                            if (!string.IsNullOrEmpty(kaydedilecekDegiskenAdi))
                                playerDataManager.AddElementToChatVariableList(kaydedilecekDegiskenAdi, kaydedilecekDegiskenDegeri);
                            kaydedilecekDegiskenDegeri = string.Empty;
                        }
                        buttonFolder.SetActive(false);
                    }

                    SohbetSonu(next);

                    if (oncekiSohbetEtiket.Count <= 0)
                    {
                        oncekiButton.SetActive(false);
                        devamButton.SetActive(false);
                        devamButtonBuyuk.SetActive(true);
                    }
                    else
                    {
                        oncekiButton.SetActive(true);
                        devamButton.SetActive(true);
                        devamButtonBuyuk.SetActive(false);
                    }
                };
            }
        }
    }

 
    public void SkipSohbetButton()
    {
        if (skipSohbet != null)
        {
            StopCoroutine(skipSohbet);
            skipSohbet = null;
        }
        skipSohbet = SkipSohbet(0);
        StartCoroutine(skipSohbet);
    }

    IEnumerator skipSohbetButtonActivate;
    IEnumerator SkipSohbetButtonActivate()
    {
        yield return new WaitForSeconds(1.2f);
        skipSohbetButton.SetActive(true);
    }

    void SohbetSonu(string etiket)
    {
        bool oncekiSohbetBos = true;

        if (sohbet != null)
            if (sohbet.popUpIndex != 0)
                oncekiSohbetBos = false;

        sohbet = FindSohbet(etiket);
        aciklama = chatVariables.OrtakButonlar(sohbet.aciklama[Random.Range(0, sohbet.aciklama.Length)]);

        if (sohbet.popUpIndex == 0)
        {
            if(skipSohbetButtonActivate!=null)
            {
                StopCoroutine(skipSohbetButtonActivate);
                skipSohbetButtonActivate = null;
            }

            skipSohbetButtonActivate = SkipSohbetButtonActivate();
            StartCoroutine(skipSohbetButtonActivate);

            if (ekrandakiSohbetSayisi == 0 && sohbet.etiket != "merhaba" && sohbet.etiket != "hosgeldin" && oncekiSohbetBos)
            {
                text.text += "\n\n" + aciklama;
                ekrandakiSohbetSayisi += 1;

                if (sohbet.etiket != "hosgeldin5")
                {
                    if (skipSohbet != null)
                    {
                        StopCoroutine(skipSohbet);
                        skipSohbet = null;
                    }
                    skipSohbet = SkipSohbet(Random.Range(1.3f, 2.2f) * sohbet.metinGecikmeCarpani);
                    StartCoroutine(skipSohbet);

                    if (kurulumBarProgress != -1)
                    {
                        kurulumBarProgress += 1;
                        kurulumBar.DOScaleX(kurulumBarProgress / 5f, 0.35f);
                    }
                }
                else
                {
                    kurulumBarProgress = -1;
                    kurulumBar.parent.gameObject.SetActive(false);

                    if (skipSohbet != null)
                    {
                        StopCoroutine(skipSohbet);
                        skipSohbet = null;
                    }
                    skipSohbet = SkipSohbet(2);
                    StartCoroutine(skipSohbet);
                }
            }
            else
            {
                text.text = aciklama;
                ekrandakiSohbetSayisi = 0;

                if (sohbet.etiket != "hosgeldin5")
                {

                    if (skipSohbet != null)
                    {
                        StopCoroutine(skipSohbet);
                        skipSohbet = null;
                    }
                    skipSohbet = SkipSohbet(Random.Range(0.7f, 1f) * sohbet.metinGecikmeCarpani);
                    StartCoroutine(skipSohbet);

                    if (kurulumBarProgress != -1)
                    {
                        kurulumBarProgress += 1;
                        kurulumBar.DOScaleX(kurulumBarProgress / 5f, 0.35f);
                    }
                }
                else
                {
                    kurulumBarProgress = -1;
                    kurulumBar.parent.gameObject.SetActive(false);

                    if (skipSohbet != null)
                    {
                        StopCoroutine(skipSohbet);
                        skipSohbet = null;
                    }
                    skipSohbet = SkipSohbet(2);
                    StartCoroutine(skipSohbet);
                }
            }

            pages[pageNumber].SetActive(false);
            buttonFolder.SetActive(false);
        }
        else
        {
            if (skipSohbetButtonActivate != null)
            {
                StopCoroutine(skipSohbetButtonActivate);
                skipSohbetButtonActivate = null;
            }
            skipSohbetButton.SetActive(false);

            text.text = aciklama;
            ekrandakiSohbetSayisi = 0;

            if (!pages[pageNumber].activeInHierarchy)
                pages[pageNumber].SetActive(true);

            if (!buttonFolder.activeInHierarchy)
                buttonFolder.SetActive(true);
        }

        if (sohbet.ozelKontrol == "logoAktif")
        {
            magnusLogoAnimator.SetBool("active", true);
        }
        else if (sohbet.ozelKontrol == "soyisim kontrol")
        {
            SoyisimKontrol();
        }
        else if (sohbet.ozelKontrol == "start gps")
        {
            startLocalazation = StartLocalazation();
            StartCoroutine(startLocalazation);
        }
    }

    void SohbetSonu(bool next)
    {
        if (next)
            SohbetSonu(sohbet.aranacakEtiket);
        else
        {
            if (oncekiSohbetEtiket.Count > 0)
            {
                SohbetSonu(oncekiSohbetEtiket[oncekiSohbetEtiket.Count - 1]);
                oncekiSohbetEtiket.RemoveAt(oncekiSohbetEtiket.Count - 1);
            }
        }
    }

    IEnumerator skipSohbet;
    IEnumerator SkipSohbet(float delay)
    {
        if (sohbet.etiket == "son")
        {
            Debug.Log("çıkıyor");
            yield return new WaitForSeconds(delay);

            /*
            ilkAnlatimParent.gameObject.SetActive(true);
            */
            playerDataManager.datas.introGosterildi = true;

            IntroManager introManager = FindObjectOfType<IntroManager>();
            introManager.goToChatScreen = true;
            //introManager.SetIntroWallpaperActive();

            introManager.fotoIntroPanel.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>().sprite = (playerDataManager.GetChatVariableValue("plus") == "var") ?
                introManager.fotoIntroPlustImage : introManager.fotoIntroDefaultImage;
            introManager.fotoIntroPanel.SetActive(true);
            introManager.audioSource.clip = introManager.introSound;
            introManager.audioSource.Play();
            introManager.introDone = false;

            FindObjectOfType<WelcomeScreen>().StartEvent();

            transform.parent.gameObject.SetActive(false);
        }
        else
        {
            yield return new WaitForSeconds(delay);
            SohbetSonu(true);
        }
    }

    public void ChangePageIlkAnlatim()
    {
        pageNumberIlkAnlatim++;
        if (pageNumberIlkAnlatim < 4)
        {
            //Sonuncu child button oldugu icin onu kapatmamak icin -1 koyuldu
            for (int i = 0; i < ilkAnlatimParent.childCount - 1; i++)
            {
                ilkAnlatimParent.GetChild(i).gameObject.SetActive(false);
            }
            ilkAnlatimParent.GetChild(pageNumberIlkAnlatim).gameObject.SetActive(true);
        }
        else
        {
            playerDataManager.datas.introGosterildi = true;

            IntroManager introManager = FindObjectOfType<IntroManager>();
            introManager.goToChatScreen = true;
            introManager.SetIntroWallpaperActive();
            FindObjectOfType<WelcomeScreen>().StartEvent();

            transform.parent.gameObject.SetActive(false);
            //Destroy(gameObject);
        }
    }

    public void OnValueChange(Text text)
    {
        kaydedilecekDegiskenDegeri = text.text;
    }

    public void OnValueChange(TMP_Text text)
    {
        kaydedilecekDegiskenDegeri = text.text;
    }

    public void ButtonTimerSelecterOk()
    {
        if (!saatPopClosed)
        {
            saatPopClosed = true;

            if (sohbet.isaretKoy)
                aciklama += "\n" + "> " + timeSelecter.hour.ToString() + ":" + timeSelecter.minute.ToString();
            else
                aciklama += "\n" + timeSelecter.hour.ToString() + ":" + timeSelecter.minute.ToString();

            gercekAciklama = aciklama;
            

            RequestAstrologyApi();

            timeSelecter.gameObject.SetActive(false);
        }
    }

    public async void RequestAstrologyApi()
    {
        int day;
        int month;
        int year;
        double lat;
        double lon;

        playerDataManager.AddElementToChatVariableList("dogum saati", timeSelecter.hour.ToString());
        playerDataManager.AddElementToChatVariableList("dogum dakikasi", timeSelecter.minute.ToString());
        int.TryParse(playerDataManager.GetChatVariableValue("dogum gunu"), out day);
        int.TryParse(playerDataManager.GetChatVariableValue("dogum ayi"), out month);
        int.TryParse(playerDataManager.GetChatVariableValue("dogum yili"), out year);
        double.TryParse(playerDataManager.GetChatVariableValue("dogum sehri enlem"), NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lat);
        double.TryParse(playerDataManager.GetChatVariableValue("dogum sehri boylam"), NumberStyles.AllowDecimalPoint, CultureInfo.CreateSpecificCulture("en-EN"), out lon);

        await  AstrologyApiRequestAscendant(day, month, year, timeSelecter.hour, timeSelecter.minute, (float)lat, (float)lon);
        await AstrologyApiRequestMoonSign(day, month, year, timeSelecter.hour, timeSelecter.minute, (float)lat, (float)lon);

        popUpActive = false;
        saatPopClosed = false;
    }

    async void SehirKontrol()
    {
        await Search();
    }

    void SehirBulundu(CountryCityDatabase.City sehir)
    {
        isCitySearching = false;
        popUpActive = false;

        if (sohbet.isaretKoy)
            aciklama += "\n" + "> " + keyboardText + keyboard.text;
        else
            aciklama += "\n" + keyboardText + keyboard.text;

        gercekAciklama = aciklama;
        playerDataManager.AddElementToChatVariableList("dogum sehri", sehir.city.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri ascii", sehir.cityAscii.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri enlem", sehir.lat.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri boylam", sehir.lng.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum ulkesi", sehir.country.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum ulkesi iso2", sehir.iso2.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum ulkesi iso3", sehir.iso3.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri admin city", sehir.adminName.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri capital", sehir.capital.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri population", sehir.population.Replace("\"", "").ToLower());
        playerDataManager.AddElementToChatVariableList("dogum sehri id", sehir.id.Replace("\"", "").ToLower());

        if ((keyboard.text + keyboardText).ToLower() != sehir.city.Replace("\"", "").ToLower())
        {
            sohbet.aranacakEtiket = "sehir onayla";
        }
        else
        {
            sohbet.aranacakEtiket = "sehir cevap";
            //sohbet.aranacakEtiket = "sehir onayla";
        }
    }

    public async Task<CountryCityDatabase.City> Search()
    {
        CountryCityDatabase.City returnValue = countryCityDatabase.cities[0];
        char[] textChar = (keyboard.text + keyboardText).ToLower().ToCharArray();

        await Task.Run(() =>
        {
            foreach (CountryCityDatabase.City element in countryCityDatabase.cities)
            {
                int currentPoint = 0;
                int point = 0;

                char[] mainTextChar = element.city.ToLower().Replace("ı", "i").Replace("ü", "u").Replace("ö", "o").Replace("ş", "s").Replace("ç", "c").Replace("ğ", "g").ToCharArray();
                char[] currentCityChar = returnValue.city.ToLower().Replace("ı", "i").Replace("ü", "u").Replace("ö", "o").Replace("ş", "s").Replace("ç", "c").Replace("ğ", "g").ToCharArray();

                int index = 0;
                for (int a = 0; a < textChar.Length; a++)
                {
                    for (int u = 0; u < currentCityChar.Length; u++)
                    {
                        if (textChar[a] == currentCityChar[u])
                        {
                            if (a != 0)
                            {
                                if (textChar[a - 1] == currentCityChar[u - 1])
                                {
                                    if (a != textChar.Length - 1)
                                    {
                                        if (textChar[a + 1] == currentCityChar[u + 1])
                                        {
                                            currentPoint += 3;
                                            index = u + 1;
                                            break;
                                        }
                                        else
                                        {
                                            currentPoint += 2;
                                            index = u + 1;
                                            break;
                                        }
                                    }
                                    else
                                    {
                                        if (u == currentCityChar.Length - 1)
                                        {
                                            currentPoint += 3;
                                            index = u + 1;
                                            break;
                                        }
                                        else
                                        {
                                            currentPoint += 2;
                                            index = u + 1;
                                            break;
                                        }
                                    }
                                }
                                else
                                {
                                    currentPoint += 1;
                                    index = u + 1;
                                    break;
                                }
                            }
                            else
                            {
                                if (u == a)
                                {
                                    if (textChar[a + 1] == currentCityChar[u + 1])
                                    {
                                        currentPoint += 3;
                                        index = u + 1;
                                        break;
                                    }
                                    else
                                    {
                                        currentPoint += 2;
                                        index = u + 1;
                                        break;
                                    }
                                }
                                else
                                {
                                    currentPoint += 1;
                                    index = u + 1;
                                    break;
                                }
                            }
                        }
                    }
                }

                index = 0;
                for (int a = 0; a < textChar.Length; a++)
                {
                    for (int u = index; u < mainTextChar.Length; u++)
                    {
                        int kelimedekiHarfSayisi = 0;

                        foreach (char harf in textChar)
                        {
                            if (harf == mainTextChar[u])
                                kelimedekiHarfSayisi += 1;
                        }


                        if (textChar[a] == mainTextChar[u])
                        {
                            if (a != 0)
                            {
                                if (textChar[a - 1] == mainTextChar[u - 1])
                                {
                                    if (a != textChar.Length - 1)
                                    {
                                        if (textChar[a + 1] == mainTextChar[u])
                                        {
                                            point += 3;
                                            index = u + 1;
                                            break;
                                        }
                                        else
                                        {
                                            point += 2;
                                            index = u + 1;
                                            break;
                                        }
                                    }
                                    else
                                    {
                                        if (u == mainTextChar.Length - 1)
                                        {
                                            point += 3;
                                            index = u + 1;
                                            break;
                                        }
                                        else
                                        {
                                            point += 2;
                                            index = u + 1;
                                            break;
                                        }
                                    }
                                }
                                else
                                {
                                    point += 1;
                                    index = u + 1;
                                    break;
                                }
                            }
                            else
                            {
                                if (u == a)
                                {
                                    if (textChar[a + 1] == mainTextChar[u + 1])
                                    {
                                        point += 3;
                                        index = u + 1;
                                        break;
                                    }
                                    else
                                    {
                                        point += 2;
                                        index = u + 1;
                                        break;
                                    }
                                }
                                else
                                {
                                    point += 1;
                                    index = u + 1;
                                    break;
                                }
                            }
                        }

                    }
                }


                if (returnValue.city.ToLower().Replace("\"", "").Contains((keyboard.text + keyboardText).ToLower()))
                {
                    currentPoint += textChar.Length;
                }

                if (returnValue.city.ToLower().Replace("\"", "") == (keyboard.text + keyboardText).ToLower())
                {
                    currentPoint += 1000000;
                }

                if (currentCityChar.Length != 0)
                {
                    if (textChar.Length < currentCityChar.Length)
                    {
                        currentPoint += textChar.Length - currentCityChar.Length;
                    }
                    else
                    {
                        currentPoint -= textChar.Length - currentCityChar.Length;
                    }
                }



                if (element.city.ToLower().Replace("\"", "").Contains((keyboard.text + keyboardText).ToLower()))
                {
                    point += textChar.Length;
                }

                if (element.city.ToLower().Replace("\"", "") == (keyboard.text + keyboardText).ToLower())
                {
                    point += 1000000;
                }

                if (mainTextChar.Length != 0)
                {
                    if (textChar.Length < mainTextChar.Length)
                    {
                        point += textChar.Length - mainTextChar.Length;
                    }
                    else
                    {
                        point -= textChar.Length - mainTextChar.Length;
                    }
                }

                if (point > currentPoint)
                {
                    returnValue = element;
                }

            }

        }).ContinueWith(t => SehirBulundu(returnValue));

        return returnValue;
    }


    bool Contains(CountryCityDatabase.City currentCity, string mainText, string text)
    {
        Debug.Log(currentCity.city);

        bool returnValue = false;

        int currentPoint = 0;
        int point = 0;

        if (text == null)
            text = "";

        char[] mainTextChar = mainText.ToLower().ToCharArray();
        char[] currentCityChar = currentCity.city.ToLower().ToCharArray();
        char[] textChar = text.ToLower().ToCharArray();

        for (int a = 0; a < textChar.Length; a++)
        {
            for (int u = 0; u < currentCityChar.Length; u++)
            {
                if (textChar[a] == currentCityChar[u])
                {
                    if (a != 0)
                    {
                        if (textChar[a - 1] == currentCityChar[u - 1])
                        {
                            if (a != textChar.Length - 1)
                            {
                                if (textChar[a + 1] == currentCityChar[u + 1])
                                {
                                    currentPoint += 3;
                                }
                                else
                                {
                                    currentPoint += 2;
                                }
                            }
                            else
                            {
                                if (u == currentCityChar.Length - 1)
                                {
                                    currentPoint += 3;
                                }
                                else
                                {
                                    currentPoint += 2;
                                }
                            }
                        }
                        else
                        {
                            currentPoint += 1;
                        }
                    }
                    else
                    {
                        if (u == a)
                        {
                            if (textChar[a + 1] == currentCityChar[u + 1])
                            {
                                currentPoint += 3;
                            }
                            else
                            {
                                currentPoint += 2;
                            }
                        }
                        else
                        {
                            currentPoint += 1;
                        }
                    }
                }
            }

            for (int u = 0; u < mainTextChar.Length; u++)
            {
                if (textChar[a] == mainTextChar[u])
                {
                    if (a != 0)
                    {
                        if (textChar[a - 1] == mainTextChar[u - 1])
                        {
                            if (a != textChar.Length - 1)
                            {
                                if (textChar[a + 1] == mainTextChar[u + 1])
                                {
                                    point += 3;
                                }
                                else
                                {
                                    point += 2;
                                }
                            }
                            else
                            {
                                if (u == mainTextChar.Length - 1)
                                {
                                    point += 3;
                                }
                                else
                                {
                                    point += 2;
                                }
                            }
                        }
                        else
                        {
                            point += 1;
                        }
                    }
                    else
                    {
                        if (u == a)
                        {
                            if (textChar[a + 1] == mainTextChar[u + 1])
                            {
                                point += 3;
                            }
                            else
                            {
                                point += 2;
                            }
                        }
                        else
                        {
                            point += 1;
                        }
                    }
                }
            }
        }

        if (point > currentPoint)
        {
            returnValue = true;
        }
        else
        {
            returnValue = false;
        }

        return returnValue;
    }

    void UcNoktaTimerUpdate()
    {
        if (ucNoktaTimer <= 0)
        {
            if (ucNokta.ToCharArray().Length < 5)
            {
                ucNokta += ".";
            }
            else
            {
                ucNokta = ".";
            }

            ucNoktaTimer = 0.5f;
        }
        else
        {
            ucNoktaTimer -= Time.deltaTime;
        }
    }

    TerminalSohbet FindSohbet(string etiket)
    {
        TerminalSohbet returnValue = ScriptableObject.CreateInstance("TerminalSohbet") as TerminalSohbet;

        foreach (TerminalSohbet element in terminalSohbetleri)
        {
            if (element.etiket == etiket)
            {
                if (element.gerekenDegiskenler != null)
                {
                    if (element.gerekenDegiskenler.Length != 0)
                    {
                        //Saat ve yas degiskenlerinin diger degiskenlerden ayrilmasi ve ozel degiskenlere atanmasi
                        #region yasSaatGunFarkiDegiskenleriAyarlama
                        List<ChatDegiskeni> secilenSohbetDegiskenleri = new List<ChatDegiskeni>();

                        ChatDegiskeni yasMaxDegiskeni = new ChatDegiskeni();
                        ChatDegiskeni yasMinDegiskeni = new ChatDegiskeni();

                        ChatDegiskeni saatMaxDegiskeni = new ChatDegiskeni();
                        ChatDegiskeni saatMinDegiskeni = new ChatDegiskeni();

                        ChatDegiskeni gunFarkiMaxDegiskeni = new ChatDegiskeni();
                        ChatDegiskeni gunFarkiMinDegiskeni = new ChatDegiskeni();

                        foreach (ChatDegiskeni elementDegiskenleri in element.gerekenDegiskenler)
                        {
                            if (elementDegiskenleri.degiskenAdi != "yasmin")
                            {
                                if (elementDegiskenleri.degiskenAdi != "yasmax")
                                {
                                    if (elementDegiskenleri.degiskenAdi != "saatmin")
                                    {
                                        if (elementDegiskenleri.degiskenAdi != "saatmax")
                                        {
                                            if (elementDegiskenleri.degiskenAdi != "gunmin")
                                            {
                                                if (elementDegiskenleri.degiskenAdi != "gunmax")
                                                {
                                                    secilenSohbetDegiskenleri.Add(elementDegiskenleri);
                                                }
                                                else
                                                {
                                                    gunFarkiMaxDegiskeni = elementDegiskenleri;
                                                }
                                            }
                                            else
                                            {
                                                gunFarkiMinDegiskeni = elementDegiskenleri;
                                            }
                                        }
                                        else
                                        {
                                            saatMaxDegiskeni = elementDegiskenleri;
                                        }
                                    }
                                    else
                                    {
                                        saatMinDegiskeni = elementDegiskenleri;
                                    }
                                }
                                else
                                {
                                    yasMaxDegiskeni = elementDegiskenleri;
                                }
                            }
                            else
                            {
                                yasMinDegiskeni = elementDegiskenleri;
                            }
                        }

                        int gerekenDegiskenlerLength = secilenSohbetDegiskenleri.Count;

                        //Yas
                        int yas = 0;
                        if (playerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("yas")))
                            int.TryParse(playerDataManager.datas.chatDegiskenleri[playerDataManager.datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals("yas"))].degiskenDegeri, out yas);

                        int yasMin = 0;
                        int yasMax = 100;
                        int.TryParse(yasMinDegiskeni.degiskenDegeri, out yasMin);
                        int.TryParse(yasMaxDegiskeni.degiskenDegeri, out yasMax);

                        if (yasMax == 0)
                            yasMax = 1000;

                        bool yasAraligiCheck = false;

                        if (yas >= yasMin && yas < yasMax)
                        {
                            yasAraligiCheck = true;
                        }

                        //Gun farki
                        int gunFarki = 0;

                        if (playerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("gun farki")))
                            int.TryParse(playerDataManager.datas.chatDegiskenleri[playerDataManager.datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals("gun farki"))].degiskenDegeri, out gunFarki);//Bu degisken welcomeScreen classinda kaydedilir!

                        int gunFarkiMin = 0;
                        int gunFarkiMax = 100;
                        int.TryParse(gunFarkiMinDegiskeni.degiskenDegeri, out gunFarkiMin);
                        int.TryParse(gunFarkiMaxDegiskeni.degiskenDegeri, out gunFarkiMax);

                        if (gunFarkiMax == 0)
                            gunFarkiMax = 1000;

                        bool gunFarkiAraligiCheck = false;

                        if (gunFarki >= gunFarkiMin && gunFarki < gunFarkiMax)
                        {
                            gunFarkiAraligiCheck = true;
                        }

                        //Saat
                        int saat = System.DateTime.Now.TimeOfDay.Hours;

                        int saatMin = 0;
                        int saatMax = 100;
                        int.TryParse(saatMinDegiskeni.degiskenDegeri, out saatMin);
                        int.TryParse(saatMaxDegiskeni.degiskenDegeri, out saatMax);

                        if (saatMax == 0)
                            saatMax = 1000;

                        bool saatAraligiCheck = false;

                        if (saat >= saatMin && saat < saatMax)
                        {
                            saatAraligiCheck = true;
                        }
                        #endregion


                        if (yasAraligiCheck)
                        {
                            if (gunFarkiAraligiCheck)
                            {
                                if (saatAraligiCheck)
                                {
                                    if (secilenSohbetDegiskenleri.Count > 0)
                                    {
                                        for (int i = 0; i < secilenSohbetDegiskenleri.Count; i++)
                                        {
                                            //Databasede İ ile başlayan şehirlerin ilk harfini i ile yazdığı için sorun olmaması için i ve ı arası önemi yok saymak için yapılan işlem.
                                            string mevcutDegiskenDegeri = secilenSohbetDegiskenleri[i].degiskenDegeri.ToLower().Replace("ı", "i");
                                            string mevcutDatabaseDegeri = playerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[i].degiskenAdi).Replace("ı", "i");

                                            if (mevcutDegiskenDegeri == mevcutDatabaseDegeri)
                                            {
                                                if (i == secilenSohbetDegiskenleri.Count - 1)
                                                {
                                                    if (returnValue.gerekenDegiskenler != null)
                                                    {
                                                        if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                                                        {
                                                            returnValue = element;
                                                            i = element.gerekenDegiskenler.Length;
                                                        }
                                                        else
                                                        {
                                                            break;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        returnValue = element;
                                                        i = element.gerekenDegiskenler.Length;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                {
                                                    if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                    {
                                                        if (secilenSohbetDegiskenleri[a].degiskenDegeri == playerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[i].degiskenAdi))
                                                        {
                                                            if (i == secilenSohbetDegiskenleri.Count - 1)
                                                            {
                                                                if (returnValue.gerekenDegiskenler != null)
                                                                {
                                                                    if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                                                                    {
                                                                        returnValue = element;
                                                                        i = element.gerekenDegiskenler.Length;
                                                                    }
                                                                    else
                                                                    {
                                                                        i = element.gerekenDegiskenler.Length;
                                                                        break;
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    returnValue = element;
                                                                    i = element.gerekenDegiskenler.Length;
                                                                    break;
                                                                }
                                                            }
                                                            break;
                                                        }
                                                        else
                                                        {
                                                            if (a == gerekenDegiskenlerLength - 1)
                                                            {
                                                                i = element.gerekenDegiskenler.Length;
                                                                break;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        if (a == gerekenDegiskenlerLength - 1)
                                                        {
                                                            i = element.gerekenDegiskenler.Length;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }

                                        }
                                    }
                                    else
                                    {
                                        if (element.gerekenDegiskenler.Length > 0)
                                        {
                                            returnValue = element;
                                        }
                                    }
                                }
                            }
                        }


                    }
                    else
                    {
                        if (returnValue.gerekenDegiskenler != null)
                        {
                            if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                            {
                                returnValue = element;
                            }
                            else
                            {

                            }
                        }
                        else
                        {
                            returnValue = element;
                        }
                    }
                }
                else
                {
                    if (returnValue.gerekenDegiskenler != null)
                    {
                        if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                        {
                            returnValue = element;
                        }
                        else
                        {

                        }
                    }
                    else
                    {
                        returnValue = element;
                    }
                }
            }
        }

        TerminalSohbet chanceSohbet = FindSohbetWithChance(etiket, returnValue);

        if (chanceSohbet.aciklama != null)
        {
            if (chanceSohbet.aciklama.Length != 0)
            {
                returnValue = chanceSohbet;
            }
        }

        kaydedilecekDegiskenAdi = returnValue.ayarlanacakDegisken;
        kaydedilecekDegiskenDegeri = "";
        return returnValue;
    }

    // Bu fonksiyon find sohbette seçilen en çok değişkenli sohbeti referans kullanarak değişken sayısına ağırlık verecek şekilde bir sohbet seçer.
    // Null değer de döndürebilri. Bu durum göz önünde bulundurulmalıdır.
    TerminalSohbet FindSohbetWithChance(string etiket, TerminalSohbet sohbet)
    {
        TerminalSohbet returnValue = ScriptableObject.CreateInstance("TerminalSohbet") as TerminalSohbet;

        foreach (TerminalSohbet element in terminalSohbetleri)
        {
            if (element.etiket == etiket)
            {
                if (element.gerekenDegiskenler != null)
                {
                    if (element.gerekenDegiskenler.Length != 0)
                    {
                        //Saat ve yas degiskenlerinin diger degiskenlerden ayrilmasi ve ozel degiskenlere atanmasi
                        #region yasSaatGunFarkiDegiskenleriAyarlama
                        List<ChatDegiskeni> secilenSohbetDegiskenleri = new List<ChatDegiskeni>();

                        ChatDegiskeni yasMaxDegiskeni = new ChatDegiskeni();
                        ChatDegiskeni yasMinDegiskeni = new ChatDegiskeni();

                        ChatDegiskeni saatMaxDegiskeni = new ChatDegiskeni();
                        ChatDegiskeni saatMinDegiskeni = new ChatDegiskeni();

                        ChatDegiskeni gunFarkiMaxDegiskeni = new ChatDegiskeni();
                        ChatDegiskeni gunFarkiMinDegiskeni = new ChatDegiskeni();

                        foreach (ChatDegiskeni elementDegiskenleri in element.gerekenDegiskenler)
                        {
                            if (elementDegiskenleri.degiskenAdi != "yasmin")
                            {
                                if (elementDegiskenleri.degiskenAdi != "yasmax")
                                {
                                    if (elementDegiskenleri.degiskenAdi != "saatmin")
                                    {
                                        if (elementDegiskenleri.degiskenAdi != "saatmax")
                                        {
                                            if (elementDegiskenleri.degiskenAdi != "gunmin")
                                            {
                                                if (elementDegiskenleri.degiskenAdi != "gunmax")
                                                {
                                                    secilenSohbetDegiskenleri.Add(elementDegiskenleri);
                                                }
                                                else
                                                {
                                                    gunFarkiMaxDegiskeni = elementDegiskenleri;
                                                }
                                            }
                                            else
                                            {
                                                gunFarkiMinDegiskeni = elementDegiskenleri;
                                            }
                                        }
                                        else
                                        {
                                            saatMaxDegiskeni = elementDegiskenleri;
                                        }
                                    }
                                    else
                                    {
                                        saatMinDegiskeni = elementDegiskenleri;
                                    }
                                }
                                else
                                {
                                    yasMaxDegiskeni = elementDegiskenleri;
                                }
                            }
                            else
                            {
                                yasMinDegiskeni = elementDegiskenleri;
                            }
                        }

                        int gerekenDegiskenlerLength = secilenSohbetDegiskenleri.Count;

                        //Yas
                        int yas = 0;
                        if (playerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("yas")))
                            int.TryParse(playerDataManager.datas.chatDegiskenleri[playerDataManager.datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals("yas"))].degiskenDegeri, out yas);

                        int yasMin = 0;
                        int yasMax = 100;
                        int.TryParse(yasMinDegiskeni.degiskenDegeri, out yasMin);
                        int.TryParse(yasMaxDegiskeni.degiskenDegeri, out yasMax);

                        if (yasMax == 0)
                            yasMax = 1000;

                        bool yasAraligiCheck = false;

                        if (yas >= yasMin && yas < yasMax)
                        {
                            yasAraligiCheck = true;
                        }

                        //Gun farki
                        int gunFarki = 0;
                        if (playerDataManager.datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("gun farki")))
                            int.TryParse(playerDataManager.datas.chatDegiskenleri[playerDataManager.datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals("gun farki"))].degiskenDegeri, out gunFarki);//Bu degisken welcomeScreen classinda kaydedilir!

                        int gunFarkiMin = 0;
                        int gunFarkiMax = 100;
                        int.TryParse(gunFarkiMinDegiskeni.degiskenDegeri, out gunFarkiMin);
                        int.TryParse(gunFarkiMaxDegiskeni.degiskenDegeri, out gunFarkiMax);

                        if (gunFarkiMax == 0)
                            gunFarkiMax = 1000;

                        bool gunFarkiAraligiCheck = false;

                        if (gunFarki >= gunFarkiMin && gunFarki < gunFarkiMax)
                        {
                            gunFarkiAraligiCheck = true;
                        }

                        //Saat
                        int saat = System.DateTime.Now.TimeOfDay.Hours;

                        int saatMin = 0;
                        int saatMax = 100;
                        int.TryParse(saatMinDegiskeni.degiskenDegeri, out saatMin);
                        int.TryParse(saatMaxDegiskeni.degiskenDegeri, out saatMax);

                        if (saatMax == 0)
                            saatMax = 1000;

                        bool saatAraligiCheck = false;

                        if (saat >= saatMin && saat < saatMax)
                        {
                            saatAraligiCheck = true;
                        }
                        #endregion

                        if (yasAraligiCheck)
                        {
                            if (gunFarkiAraligiCheck)
                            {
                                if (saatAraligiCheck)
                                {
                                    if (secilenSohbetDegiskenleri.Count > 0)
                                    {
                                        for (int i = 0; i < secilenSohbetDegiskenleri.Count; i++)
                                        {
                                            if (secilenSohbetDegiskenleri[i].degiskenDegeri.ToLower() == playerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[i].degiskenAdi))
                                            {
                                                if (i == element.gerekenDegiskenler.Length - 1)
                                                {
                                                    if (returnValue.gerekenDegiskenler != null)
                                                    {
                                                        if (i == element.gerekenDegiskenler.Length - 1)
                                                        {
                                                            int chance = Random.Range(1, sohbet.gerekenDegiskenler.Length + 1);
                                                            if (chance < element.gerekenDegiskenler.Length)
                                                            {
                                                                returnValue = element;
                                                                i = element.gerekenDegiskenler.Length;
                                                            }
                                                        }
                                                        else
                                                        {
                                                            break;
                                                        }
                                                    }
                                                    else
                                                    {
                                                        returnValue = element;
                                                        i = element.gerekenDegiskenler.Length;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                for (int a = 0; a < gerekenDegiskenlerLength; a++)
                                                {
                                                    if (secilenSohbetDegiskenleri[a].degiskenAdi == secilenSohbetDegiskenleri[i].degiskenAdi)
                                                    {
                                                        if (secilenSohbetDegiskenleri[a].degiskenDegeri.ToLower() == playerDataManager.GetChatVariableValue(secilenSohbetDegiskenleri[i].degiskenAdi))
                                                        {
                                                            if (i == secilenSohbetDegiskenleri.Count - 1)
                                                            {
                                                                if (returnValue.gerekenDegiskenler != null)
                                                                {
                                                                    if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                                                                    {
                                                                        returnValue = element;
                                                                        i = element.gerekenDegiskenler.Length;
                                                                    }
                                                                    else
                                                                    {
                                                                        i = element.gerekenDegiskenler.Length;
                                                                        break;
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    returnValue = element;
                                                                    i = element.gerekenDegiskenler.Length;
                                                                    break;
                                                                }
                                                            }
                                                            break;
                                                        }
                                                        else
                                                        {
                                                            if (a == gerekenDegiskenlerLength - 1)
                                                            {
                                                                i = element.gerekenDegiskenler.Length;
                                                                break;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        if (a == gerekenDegiskenlerLength - 1)
                                                        {
                                                            i = element.gerekenDegiskenler.Length;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    else
                                    {
                                        if (element.gerekenDegiskenler.Length > 0)
                                        {
                                            int chance = Random.Range(1, sohbet.gerekenDegiskenler.Length + 1);
                                            if (chance < element.gerekenDegiskenler.Length)
                                            {
                                                returnValue = element;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        if (returnValue.gerekenDegiskenler != null)
                        {
                            if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                            {
                                returnValue = element;
                            }
                            else
                            {

                            }
                        }
                        else
                        {
                            returnValue = element;
                        }
                    }
                }
                else
                {
                    if (returnValue.gerekenDegiskenler != null)
                    {
                        if (returnValue.gerekenDegiskenler.Length < element.gerekenDegiskenler.Length)
                        {
                            returnValue = element;
                        }
                        else
                        {

                        }
                    }
                    else
                    {
                        returnValue = element;
                    }
                }
            }
        }

        return returnValue;
    }

    public void ClosePopUpMenu()
    {
        foreach (GameObject element in popUpMenus)
        {
            element.SetActive(false);
        }
        popUpActive = false;
    }

    public void ConfirmLocationPermissionOkButton()
    {
        foreach (GameObject element in popUpMenus)
        {
            element.SetActive(false);
        }
        popUpActive = false;
        //playerDataManager.AddElementToChatVariableList(kaydedilecekDegiskenAdi, kaydedilecekDegiskenDegeri);

        if (playerDataManager.GetChatVariableValue("gps izin") == "evet")
        {
            if (sohbet.isaretKoy)
                aciklama += "\n" + "> " + lokasyonIzniVerildiAciklama;
            else
                aciklama += "\n" + lokasyonIzniVerildiAciklama;
        }
        else
        {
            if (sohbet.isaretKoy)
                aciklama += "\n" + "> " + lokasyonIzniVerilmediAciklama;
            else
                aciklama += "\n" + lokasyonIzniVerilmediAciklama;
        }

        gercekAciklama = aciklama;
        
    }

    public void ConfirmPopUpButton()
    {
        if (kaydedilecekDegiskenDegeri != "")
        {
            foreach (GameObject element in popUpMenus)
            {
                element.SetActive(false);
            }
            popUpActive = false;
            playerDataManager.AddElementToChatVariableList(kaydedilecekDegiskenAdi, kaydedilecekDegiskenDegeri);

            if (sohbet.isaretKoy)
                aciklama += "\n" + "> " + kaydedilecekDegiskenDegeri;
            else
                aciklama += "\n" + kaydedilecekDegiskenDegeri;

            gercekAciklama = aciklama;
            
        }
    }

    bool IsStringPositiveNumber(string text)
    {
        bool returnValue = false;

        int value = 0;

        int.TryParse(text, out value);

        if (value != 0)
            returnValue = true;

        return returnValue;
    }

    bool IsStringPositiveNumber(string text, int minValue, int maxValue)
    {
        bool returnValue = false;

        int value = 0;

        int.TryParse(text, out value);

        if (value != 0)
        {
            if (!sohbet.maxValueIsYear)
            {
                if (value <= maxValue && value >= minValue)
                {
                    returnValue = true;
                }
            }
            else
            {
                if (sohbet.etiket != "dogumYili")
                {
                    if (value <= System.DateTime.Now.Year - sohbet.popUpIntMax && value >= minValue)
                    {
                        returnValue = true;
                    }
                }
                else
                {
                    if (value <= System.DateTime.Now.Year - (System.DateTime.Now.Year - magnusPreferences.minimumDogumYili) && value >= minValue)
                    {
                        returnValue = true;
                    }
                }
            }
        }

        return returnValue;
    }

    bool GunDegeriniKontrolEt()
    {
        bool returnValue = true;

        int girilenYil = 0;
        int.TryParse(playerDataManager.GetChatVariableValue("dogum yili"), out girilenYil);
        int girilenAy = 0;
        int.TryParse(playerDataManager.GetChatVariableValue("dogum ayi"), out girilenAy);
        int girilenGun = 0;
        int.TryParse(playerDataManager.GetChatVariableValue("dogum gunu"), out girilenGun);
        System.DateTime dogumGunu = new System.DateTime(1, 1, 1);

        try
        {
            dogumGunu = new System.DateTime(girilenYil, girilenAy, girilenGun);
        }
        catch
        {
            returnValue = false;
        }

        BurcVeYasKayit(girilenGun, girilenAy, girilenYil);

        return returnValue;
    }

    void BurcVeYasKayit(int gun, int ay, int yil)
    {
        playerDataManager.datas.tanismaTarihi = new PlayerData.Date(System.DateTime.Now);

        int.TryParse(playerDataManager.GetChatVariableValue("dogum gunu"), out gun);

        int.TryParse(playerDataManager.GetChatVariableValue("dogum ayi"), out ay);

        int.TryParse(playerDataManager.GetChatVariableValue("dogum yili"), out yil);

        System.DateTime dogumGunu = new System.DateTime(2000, 1, 1);
        // Doğum tarihi
        try
        {
            dogumGunu = new System.DateTime(yil, ay, gun);
        }
        catch
        {
            dogumGunu = new System.DateTime(2000, 1, 1);
        }

        // Bu günün tarihi
        System.DateTime buGun = System.DateTime.Today;
        // Yıl farkı
        int yas = buGun.Year - dogumGunu.Year;
        // Bu günün tarihinden yıl farkını çıkar. Doğum günü bu
        // tarihten büyük ise yılı bir azalt.

        if (dogumGunu > buGun.AddYears(-yas))
            yas--;

        playerDataManager.AddElementToChatVariableList("yas", yas.ToString().ToLower());
        playerDataManager.AddElementToChatVariableList("burc", Burc.BurcHesapla(gun, ay));
    }

    public void SoyisimKontrol()
    {
        if (playerDataManager.GetChatVariableValue("isim").Contains(" " + playerDataManager.GetChatVariableValue("soyisim")))
        {
            playerDataManager.AddElementToChatVariableList("isim", playerDataManager.GetChatVariableValue("isim").Replace(" " + playerDataManager.GetChatVariableValue("soyisim"), ""));
        }
    }


    public void ChoiceButton(Text text)
    {
        kaydedilecekDegiskenDegeri = text.text;
    }

    public void SehirBuMuButtonEvent(string sohbet)
    {
        if (kaydedilecekDegiskenDegeri != "")
        {
            popUpActive = false;
            this.sohbet.aranacakEtiket = sohbet;

            foreach (GameObject element in popUpMenus)
            {
                element.SetActive(false);
            }

            if (this.sohbet.isaretKoy)
                aciklama += "\n" + "> " + kaydedilecekDegiskenDegeri;
            else
                aciklama += "\n" + kaydedilecekDegiskenDegeri;

            gercekAciklama = aciklama;
        }
    }

    IEnumerator startLocalazation = null;
    IEnumerator StartLocalazation()
    {
        changeButtonDeactivated = 3;
        yield return new WaitForSeconds(3);
        changeButtonDeactivated = 0;
        playerDataManager.AddElementToChatVariableList("gps izin", "hayır");
        StartCoroutine(FindObjectOfType<OpenWeatherApi>().StartLocal(true));
    }

    public void ClickLocalPermissionOkButton()
    {

    }

    public static async Task<bool> AstrologyApiRequestAscendant(int day, int month, int year, int hour, int min, float lat, float lon)
    {
        float tzone = await RequestTimeZone(day, month, year, lat, lon);

        string data = JsonConvert.SerializeObject(new AstrologyApiRequestData(day, month, year, hour, min, (float)System.Math.Round((decimal)lat, 3), (float)System.Math.Round((decimal)lon, 3), tzone));

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                Content = new System.Net.Http.StringContent(data, Encoding.UTF8, "application/json"),
                RequestUri = new System.Uri("https://json.astrologyapi.com/v1/general_ascendant_report/tropical"),
            })
            {
                string contentJsonString = await request.Content.ReadAsStringAsync();

                //if(JsonUtility.FromJson<AstrologyApiResponse>(contentJsonString).ascendant)

                
                string apiKey = "618158" + ":" + "5baea1bb862488ad92f6e614dc540f98";
                var apiKeyBytes = System.Text.Encoding.UTF8.GetBytes(apiKey);
                var apiKeyData = System.Convert.ToBase64String(apiKeyBytes);

                request.Headers.TryAddWithoutValidation("dataType", "json");
                request.Headers.TryAddWithoutValidation("authorization", "Basic " + apiKeyData);

                var multipartContent = new MultipartFormDataContent();

                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                Debug.Log(jsonString);
                try
                {
                    FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList("yukselen", Burc.Ceviri(JsonUtility.FromJson<AstrologyApiResponse>(jsonString).ascendant.ToLower(), Burc.BurcDili.tur));
                }
                catch
                {
                    Debug.Log(data);
                    Debug.Log(response);
                    Debug.Log(jsonString);
                    Debug.LogError("Response not valid");
                }

                return true;
            }
        }
    }

    public static async Task<bool> AstrologyApiRequestMoonSign(int day, int month, int year, int hour, int min, float lat, float lon)
    {
        float tzone = await RequestTimeZone(day, month, year, lat, lon);

        string data = JsonConvert.SerializeObject(new AstrologyApiRequestData(day, month, year, hour, min, (float)System.Math.Round((decimal)lat, 2), (float)System.Math.Round((decimal)lon, 2), tzone));

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                Content = new System.Net.Http.StringContent(data, Encoding.UTF8, "application/json"),
                RequestUri = new System.Uri("https://json.astrologyapi.com/v1/planets/tropical"),

            })
            {
                string apiKey = "618158" + ":" + "5baea1bb862488ad92f6e614dc540f98";
                var apiKeyBytes = System.Text.Encoding.UTF8.GetBytes(apiKey);
                var apiKeyData = System.Convert.ToBase64String(apiKeyBytes);

                request.Headers.TryAddWithoutValidation("dataType", "json");
                request.Headers.TryAddWithoutValidation("authorization", "Basic " + apiKeyData);

                var multipartContent = new MultipartFormDataContent();

                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                jsonString = "{\"Items\":" + jsonString + "}";

                moonApiReport[] items;

                items = JsonHelper.FromJson<moonApiReport>(jsonString);

                Debug.Log(jsonString);
                try
                {
                    FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList("ayburcu", Burc.Ceviri(items[1].sign.ToLower(), Burc.BurcDili.tur));
                }
                catch
                {
                    Debug.LogError("Response not valid");
                }

                return true;
            }
        }
    }

    public static async Task<float> RequestTimeZone(int day, int month, int year, float lat, float lon)
    {
        string data = JsonConvert.SerializeObject(new TimeZoneAPIRequest((float)System.Math.Round((decimal)lat, 2), (float)System.Math.Round((decimal)lon, 2), day, month, year));

        using (var httpClient = new HttpClient())
        {
            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                Content = new System.Net.Http.StringContent(data, Encoding.UTF8, "application/json"),
                RequestUri = new System.Uri("https://json.astrologyapi.com/v1/timezone_with_dst"),

            })
            {
                string apiKey = "618158" + ":" + "5baea1bb862488ad92f6e614dc540f98";
                var apiKeyBytes = System.Text.Encoding.UTF8.GetBytes(apiKey);
                var apiKeyData = System.Convert.ToBase64String(apiKeyBytes);

                request.Headers.TryAddWithoutValidation("dataType", "json");
                request.Headers.TryAddWithoutValidation("authorization", "Basic " + apiKeyData);

                var multipartContent = new MultipartFormDataContent();

                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                jsonString = "{\"Items\":" + jsonString + "}";

                var items = JsonConvert.DeserializeObject<TimeZoneAPIResoponse>(jsonString);

                Debug.Log(jsonString);
     
                try
                {
                    Debug.LogError(items.items.timezone);
                    return items.items.timezone;
                }
                catch
                {
                    return (float)System.TimeZone.CurrentTimeZone.GetUtcOffset(System.DateTime.Now).TotalHours;
                }

    
            }
        }
    }

    [System.Serializable]
    public class moonApiReport
    {
        public string name;
        public string fullDegree;
        public string normDegree;
        public string speed;
        public string isRetro;
        public string sign;
        public string house;
    }


    [System.Serializable]
    public class AstrologyApiResponse
    {
        public string ascendant;
        public string report;
    }

    [System.Serializable]
    public class AstrologyApiRequestData
    {
        public int day;
        public int month;
        public int year;
        public int hour;
        public int min;
        public float lat;
        public float lon;
        public float tzone;

        public AstrologyApiRequestData(int day, int month, int year, int hour, int min, float lat, float lon, float tzone)
        {
            this.day = day;
            this.month = month;
            this.year = year;
            this.hour = hour;
            this.min = min;
            this.lat = lat;
            this.lon = lon;
            this.tzone = tzone;
        }
    }

    public class TimeZoneAPIRequest
    {
        public float latitude;
        public float longitude;
        public string date;

        public TimeZoneAPIRequest(float latitude, float longitude, int day, int month, int year)
        {
            this.latitude = latitude;
            this.longitude = longitude;
            date = $"{month}-{day}-{year}";
        }
    }

    public class TimeZoneAPIResoponse
    {
        public Value items;

        public class Value
        {
            public bool status;
            public float timezone;
            public double timezone_in_ms;
            public string date;

            public Value()
            {
                this.status = false;
                this.timezone = 0;
                this.timezone_in_ms = 0;
                this.date = string.Empty;
            }
        }
    }

    public static class JsonHelper
    {
        public static T[] FromJson<T>(string json)
        {
            Wrapper<T> wrapper = JsonUtility.FromJson<Wrapper<T>>(json);
            return wrapper.Items;
        }

        public static string ToJson<T>(T[] array)
        {
            Wrapper<T> wrapper = new Wrapper<T>();
            wrapper.Items = array;
            return JsonUtility.ToJson(wrapper);
        }

        public static string ToJson<T>(T[] array, bool prettyPrint)
        {
            Wrapper<T> wrapper = new Wrapper<T>();
            wrapper.Items = array;
            return JsonUtility.ToJson(wrapper, prettyPrint);
        }

        [System.Serializable]
        private class Wrapper<T>
        {
            public T[] Items;
        }
    }
}
