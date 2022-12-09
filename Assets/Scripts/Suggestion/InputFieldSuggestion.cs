using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.EventSystems;

public class InputFieldSuggestion : MonoBehaviour
{
    public RectTransform canvasRt;

    public GameObject suggestion1, suggestion2;

    public CountryCityDatabase countryCityDatabase;

    public TMP_InputField text;

    public List<CountryCityDatabase.City> cities = new List<CountryCityDatabase.City>();

    public CurrentPlayerData playerDataManager;

    bool suggest = true;
    public bool isSuggestionActive = true;

    public CountryCityDatabase.City selectedCity = null;

    public enum DefaultPosition { alt, ust }
    public DefaultPosition defaultPosition;

    // Start is called before the first frame update
    void Start()
    {

    }

    private void OnEnable()
    {
        StartCoroutine(EnableEndOfFrame());
    }

    IEnumerator EnableEndOfFrame()
    {
        yield return new WaitForEndOfFrame();
        //Terminal için kontroller
        var firstWelcome = FindObjectOfType<FirstWelcomeScreenManager>();
        if (!playerDataManager.datas.dahaOnceGeldi && selectedCity != null && firstWelcome != null)
        {
            //Sayfanin atlanabilmesi icin bu degiskenin bir degere esitlenmesi gerekir. Esitleme onemsizdir...
            firstWelcome.kaydedilecekDegiskenDegeri = selectedCity.city;
        }
        else
        {
            text.text = playerDataManager.GetChatVariableValue("dogum sehri");
            ValueChanged();
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (text.text.Replace(" ", "") != "" && suggest && isSuggestionActive)
        {
            //float minScreenYPos = canvasRt.position.y + (canvasRt.sizeDelta.y / 2f - 200) * canvasRt.localScale.y;
            float minScreenYPos = canvasRt.position.y + (canvasRt.sizeDelta.y * GetKeyboardHeightRatio() + suggestion2.GetComponent<RectTransform>().sizeDelta.y * 2f + 20f - canvasRt.sizeDelta.y / 2f ) * canvasRt.localScale.y;
            float defaultScreenYPos;

            if (defaultPosition == DefaultPosition.ust)
                defaultScreenYPos = text.GetComponent<RectTransform>().position.y + text.GetComponent<RectTransform>().sizeDelta.y / 2f * canvasRt.localScale.y;
            else
                defaultScreenYPos = text.GetComponent<RectTransform>().position.y - text.GetComponent<RectTransform>().sizeDelta.y / 2f * canvasRt.localScale.y;

            if (!TouchScreenKeyboard.visible)
                minScreenYPos = 0;

            float posY;

            if(minScreenYPos < defaultScreenYPos)
            {
                posY = defaultScreenYPos;
            }
            else
            {
                posY = minScreenYPos;
            }

            if (cities.Count > 1)
            {
                suggestion1.SetActive(true);
                suggestion1.GetComponent<RectTransform>().GetChild(0).GetComponent<Text>().text = cities[0].iso2 + ", " + cities[0].city;

                if (defaultPosition == DefaultPosition.ust)
                    suggestion1.GetComponent<RectTransform>().position = new Vector3(suggestion1.GetComponent<RectTransform>().position.x, posY + suggestion1.GetComponent<RectTransform>().sizeDelta.y, suggestion1.GetComponent<RectTransform>().position.z);
                else
                    suggestion1.GetComponent<RectTransform>().position = new Vector3(suggestion1.GetComponent<RectTransform>().position.x, posY - suggestion1.GetComponent<RectTransform>().sizeDelta.y, suggestion1.GetComponent<RectTransform>().position.z);

                suggestion2.SetActive(true);
                suggestion2.GetComponent<RectTransform>().GetChild(0).GetComponent<Text>().text = cities[1].iso2 + ", " + cities[1].city;

                if (defaultPosition == DefaultPosition.ust)
                    suggestion2.GetComponent<RectTransform>().position = new Vector3(suggestion2.GetComponent<RectTransform>().position.x, posY + suggestion1.GetComponent<RectTransform>().sizeDelta.y + 60 * canvasRt.localScale.y, suggestion2.GetComponent<RectTransform>().position.z);
                else
                    suggestion2.GetComponent<RectTransform>().position = new Vector3(suggestion2.GetComponent<RectTransform>().position.x, posY - suggestion1.GetComponent<RectTransform>().sizeDelta.y - 60 * canvasRt.localScale.y, suggestion2.GetComponent<RectTransform>().position.z);

                if(text.text.ToLower() == cities[0].city.Replace("\"", "").ToLower())
                {
                    selectedCity = cities[0];
                }
                else if (text.text.ToLower() == cities[1].city.Replace("\"", "").ToLower())
                {
                    selectedCity = cities[1];
                }
            }
            else if (cities.Count > 0)
            {
                suggestion1.SetActive(true);
                suggestion1.GetComponent<RectTransform>().GetChild(0).GetComponent<Text>().text = cities[0].iso2 + ", " + cities[0].city;

                if (defaultPosition == DefaultPosition.ust)
                    suggestion1.GetComponent<RectTransform>().position = new Vector3(suggestion1.GetComponent<RectTransform>().position.x, posY + suggestion1.GetComponent<RectTransform>().sizeDelta.y, suggestion1.GetComponent<RectTransform>().position.z);
                else
                    suggestion1.GetComponent<RectTransform>().position = new Vector3(suggestion1.GetComponent<RectTransform>().position.x, posY - suggestion1.GetComponent<RectTransform>().sizeDelta.y, suggestion1.GetComponent<RectTransform>().position.z);

                suggestion2.SetActive(false);

                if (text.text.ToLower() == cities[0].city.Replace("\"", "").ToLower())
                {
                    selectedCity = cities[0];
                }
            }
            else
            {
                suggestion1.SetActive(false);
                suggestion2.SetActive(false);
            }
        }
        else
        {
            if (suggestion1.activeInHierarchy || suggestion2.activeInHierarchy)
            {
                suggestion1.SetActive(false);
                suggestion2.SetActive(false);
            }
        }
    }

    public async Task<List<CountryCityDatabase.City>> Search()
    {
        List<CountryCityDatabase.City> returnValue = new List<CountryCityDatabase.City>();

        await Task.Run(() =>
        {
            foreach (CountryCityDatabase.City element in countryCityDatabase.cities)
            {
                if (Contains(element.city.Replace(" ", "").Replace("\"", "").ToLower().Replace("ı", "i").Replace("ü", "u").Replace("ö", "o").Replace("ş", "s").Replace("ç", "c").Replace("ğ", "g"),
                    text.text.Replace(" ", "").ToLower().Replace("ı", "i").Replace("ü", "u").Replace("ö", "o").Replace("ş", "s").Replace("ç", "c").Replace("ğ", "g"))
                || text.text == "")
                {
                    if (returnValue.Count < 2)
                    {
                        if (element.city.Replace(" ", "") != "")
                            returnValue.Add(element);
                    }
                    else
                    {
                        break;
                    }
                }
            }
        });

        return returnValue;
    }

    bool Contains(string mainText, string text)
    {
        bool returnValue = false;

        if (text == null)
            text = "";

        char[] mainTextChar = mainText.ToLower().ToCharArray();
        char[] textChar = text.ToLower().ToCharArray();

        for (int i = 0; i < textChar.Length; i++)
        {
            if (mainTextChar.Length > i)
            {
                if (textChar[i] == mainTextChar[i])
                {
                    if (i == textChar.Length - 1)
                    {
                        returnValue = true;
                    }
                }
                else
                {
                    returnValue = false;
                    break;
                }
            }
            else
            {
                returnValue = false;
                break;
            }
        }

        return returnValue;
    }

    public static float GetKeyboardHeightRatio()
    {
#if UNITY_ANDROID
        /*
        using (var unityClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
        {
            var view = unityClass.GetStatic<AndroidJavaObject>("currentActivity")
                .Get<AndroidJavaObject>("mUnityPlayer")
                .Call<AndroidJavaObject>("getView");

            var dialog = unityClass.GetStatic<AndroidJavaObject>("currentActivity")
                .Get<AndroidJavaObject>("mUnityPlayer")
                .Get<AndroidJavaObject>("b");

            var decorView = dialog.Call<AndroidJavaObject>("getWindow")
                .Call<AndroidJavaObject>("getDecorView");

            var height = decorView.Call<int>("getHeight");

            using (var rect = new AndroidJavaObject("android.graphics.Rect"))
            {
                view.Call("getWindowVisibleDisplayFrame", rect);
                return (float)(Screen.height - rect.Call<int>("height") + height) / Screen.height;
            }
        }
        */

        return 0.55f;
#elif UNITY_IOS
        return (float) TouchScreenKeyboard.area.height / Screen.height;
#endif

        return 0.7f;
    }

    public async void ValueChanged()
    {
        cities = await Search();
        if (gameObject.activeInHierarchy)
        {
            for (int i = 0; i < cities.Count; i++)
            {
                string buttonText = text.text.ToLower().Replace("ı", "i");
                string cityText = cities[i].city.Replace("\"", "").ToLower().Replace("ı", "i");
                if (buttonText == cityText)
                {
                    ClickSuggestionButton(i);
                    break;
                }
            }
        }
        suggest = true;
    }

    public void ClickSuggestionButton(int index)
    {
        if (index == 0)
        {
            this.text.text = cities[0].city.Replace("\"", "");
            selectedCity = cities[0];
        }
        else
        {
            this.text.text = cities[1].city.Replace("\"", "");
            selectedCity = cities[1];
        }

        text.GraphicUpdateComplete();

        StartCoroutine(ChageSuggetsState(false));

        //Terminal için kontroller
        if (!playerDataManager.datas.dahaOnceGeldi)
        {
            //Sayfanin atlanabilmesi icin bu degiskenin bir degere esitlenmesi gerekir. Esitleme onemsizdir...
            var firstScreen = FindObjectOfType<FirstWelcomeScreenManager>();

            if (firstScreen != null)
                firstScreen.kaydedilecekDegiskenDegeri = selectedCity.city;

            SaveButton();
        }
    }

    public void SaveButton()
    {
        if (selectedCity != null)
        {
            playerDataManager.AddElementToChatVariableList("dogum sehri", selectedCity.city.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri ascii", selectedCity.cityAscii.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri enlem", selectedCity.lat.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri boylam", selectedCity.lng.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum ulkesi", selectedCity.country.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum ulkesi iso2", selectedCity.iso2.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum ulkesi iso3", selectedCity.iso3.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri admin city", selectedCity.adminName.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri capital", selectedCity.capital.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri population", selectedCity.population.Replace("\"", ""));
            playerDataManager.AddElementToChatVariableList("dogum sehri id", selectedCity.id.Replace("\"", ""));
        }
    }

    public void EditButton()
    {
        suggest = false;
        selectedCity = null;
    }

    IEnumerator ChageSuggetsState(bool value)
    {
        yield return new WaitForEndOfFrame();
        suggest = value;
    }

    private void OnApplicationFocus(bool focus)
    {
        if (focus)
        {
            if (RectTransformUtility.RectangleContainsScreenPoint(suggestion1.GetComponent<RectTransform>(), Input.mousePosition))
            {
                ClickSuggestionButton(0);
            }
            else
            {
                Debug.Log(Input.mousePosition);
            }

            if (RectTransformUtility.RectangleContainsScreenPoint(suggestion2.GetComponent<RectTransform>(), Input.mousePosition))
            {
                ClickSuggestionButton(1);
            }
            else
            {
                Debug.Log(Input.mousePosition);
            }
        }
    }
}
