using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UIHealthAlchemy;
using DG.Tweening;
using TMPro;

public class EnergyManager : MonoBehaviour
{
    public List<Square> squares;

    public CurrentPlayerData playerDataManager;

    public TMP_Text extraEnergyText;

    public Color standartColor, fullColor;

    public Animation fullAnimation;

    IEnumerator animationEnumerator;

    public int minAnimationAmount = 0;

    static readonly private int maxDailyKonsantrasyon = 5;
    static readonly private int maxDailyKonsantrasyonPlus = 10;

    static readonly private int maxDailyEnergy = 10;
    static readonly private int maxDailyEnergyPlus = 20;

    static readonly private int dailyEnergy = 1;
    static readonly private int dailyEnergyPlus = 10;

    private WelcomeScreen welcomeScreen;

    public enum BarType
    {
        energy,
        konsantrasyon
    }
    public BarType barType;

    public bool reverseAnimation;

    public Notification notification;

    void Start()
    {
        animationEnumerator = null;
        notification.rectTransform.gameObject.SetActive(false);
        welcomeScreen = FindObjectOfType<WelcomeScreen>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void PlayExtraAnimation()
    {
        if (animationEnumerator == null)
        {
            animationEnumerator = PlayBarAnimation();
            StartCoroutine(animationEnumerator);
        }
    }

    IEnumerator PlayBarAnimation()
    {
        RectTransform textRect = extraEnergyText.GetComponent<RectTransform>();
        textRect.localScale = Vector3.zero;

        //int value = (barType == BarType.energy) ? playerDataManager.datas.energy : playerDataManager.datas.konsantrasyon;

        int value = 10;

        for (int i = squares.Count - 1; i >= 0; i--)
        {
      
            if (value >= squares.Count - i)
            {
                Square square = squares[i];
                //square.tween.Complete();
                RectTransform rt = square.rectTransform.GetChild(0).GetComponent<RectTransform>();
                Image image = square.rectTransform.GetChild(0).GetComponent<Image>();

                rt.localScale = Vector3.one;
                rt.DOPunchScale(new Vector3(fullAnimation.maxScale, fullAnimation.maxScale, 1f), fullAnimation.duration * fullAnimation.impactField * 2, 3, fullAnimation.elasticity);
                image.DOColor(fullColor, fullAnimation.duration * fullAnimation.impactField).onComplete = () => { image.DOColor(standartColor, fullAnimation.duration * fullAnimation.impactField); };
                yield return new WaitForSeconds(0.12f);
            }
            else
            {
                /*
                Square square = squares[value - 1 - i];
                RectTransform rt = square.rectTransform.GetChild(0).GetComponent<RectTransform>();
                Image image = square.rectTransform.GetChild(0).GetComponent<Image>();

                rt.localScale = Vector3.zero;*/
                yield return new WaitForSeconds(0.12f);
            }
        }

        yield return new WaitForSeconds(0.5f);


        for (int i = squares.Count - 1; i >= 0; i--)
        {

            if (value >= squares.Count - i)
            {
                Square square = squares[i];
                //square.tween.Complete();
                RectTransform rt = square.rectTransform.GetChild(0).GetComponent<RectTransform>();
                Image image = square.rectTransform.GetChild(0).GetComponent<Image>();

                rt.localScale = Vector3.one;
                rt.DOScale(0f, 0.2f);
                yield return new WaitForSeconds(0.12f);
            }
            else
            {
                /*
                Square square = squares[value - 1 - i];
                RectTransform rt = square.rectTransform.GetChild(0).GetComponent<RectTransform>();
                Image image = square.rectTransform.GetChild(0).GetComponent<Image>();

                rt.localScale = Vector3.zero;*/
                yield return new WaitForSeconds(0.12f);
            }
        }

        textRect.DOScale((barType == BarType.energy) ? Vector3.one : new Vector3(-1, 1, 1), .2f);

        yield return new WaitForSeconds(4f);

        textRect.DOScale(0, .2f);

        yield return new WaitForSeconds(.2f);

        for (int i = 0; i < squares.Count; i++)
        {

            if (value >= squares.Count - i)
            {
                Square square = squares[i];
                //square.tween.Complete();
                RectTransform rt = square.rectTransform.GetChild(0).GetComponent<RectTransform>();
                Image image = square.rectTransform.GetChild(0).GetComponent<Image>();

                rt.localScale = Vector3.one;
                rt.DOPunchScale(new Vector3(fullAnimation.maxScale, fullAnimation.maxScale, 1f), fullAnimation.duration * fullAnimation.impactField * 2, 3, fullAnimation.elasticity);
                image.DOColor(fullColor, fullAnimation.duration * fullAnimation.impactField).onComplete = () => { image.DOColor(standartColor, fullAnimation.duration * fullAnimation.impactField); };
                yield return new WaitForSeconds(0.12f);
            }
            else
            {
                /*
                Square square = squares[value - 1 - i];
                RectTransform rt = square.rectTransform.GetChild(0).GetComponent<RectTransform>();
                Image image = square.rectTransform.GetChild(0).GetComponent<Image>();

                rt.localScale = Vector3.zero;*/
                yield return new WaitForSeconds(0.12f);
            }
        }

        yield return new WaitForSeconds(.45f);
        StartCoroutine(PlayBarAnimation());
    }

    private void OnEnable()
    {
        UpdateBars();
    }

    private void OnDisable()
    {
        if (animationEnumerator != null)
        {
            StopCoroutine(animationEnumerator);
            animationEnumerator = null;
        }
    }

    public void AddEnergy(int amount, int konsantrasyon)
    {
        if (barType == BarType.energy)
        {
            if (amount > 0)
                notification.text.text = $"+{amount} Altın";
            else if (amount < 0)
                notification.text.text = $"{amount} Altın";

            playerDataManager.datas.energy += amount;
            Mathf.Clamp(playerDataManager.datas.energy, 0, Mathf.Infinity);
            if (playerDataManager.datas.energy < 0)
                playerDataManager.datas.energy = 0;

            if (amount != 0 && gameObject.activeInHierarchy && !welcomeScreen.reviewAppRt.gameObject.activeInHierarchy && !welcomeScreen.updateAppRt.gameObject.activeInHierarchy)
                StartCoroutine(ShowNotification());
        }
        else if (barType == BarType.konsantrasyon)
        {
            if (konsantrasyon > 0)
                notification.text.text = $"+{konsantrasyon} Elmas";
            else if (konsantrasyon < 0)
                notification.text.text = $"{konsantrasyon} Elmas";

            playerDataManager.datas.konsantrasyon += konsantrasyon;
            if (playerDataManager.datas.konsantrasyon < 0)
                playerDataManager.datas.konsantrasyon = 0;

            if (konsantrasyon != 0 && gameObject.activeInHierarchy && !welcomeScreen.reviewAppRt.gameObject.activeInHierarchy && !welcomeScreen.updateAppRt.gameObject.activeInHierarchy)
                StartCoroutine(ShowNotification());
        }

        UpdateBars();
    }

    public void AddEnergy(int amount, int konsantrasyon, string text)
    {
        if (barType == BarType.energy)
        {
            notification.text.text = text;

            playerDataManager.datas.energy += amount;
            Mathf.Clamp(playerDataManager.datas.energy, 0, Mathf.Infinity);
            if (playerDataManager.datas.energy < 0)
                playerDataManager.datas.energy = 0;

            //if (amount > 0 && gameObject.activeInHierarchy)
            if (amount != 0 && gameObject.activeInHierarchy && !welcomeScreen.reviewAppRt.gameObject.activeInHierarchy && !welcomeScreen.updateAppRt.gameObject.activeInHierarchy)
                StartCoroutine(ShowNotification());
        }
        else if (barType == BarType.konsantrasyon)
        {
            notification.text.text = text;

            playerDataManager.datas.konsantrasyon += konsantrasyon;
            if (playerDataManager.datas.konsantrasyon < 0)
                playerDataManager.datas.konsantrasyon = 0;

            //if (konsantrasyon > 0 && gameObject.activeInHierarchy)
            if (konsantrasyon != 0 && gameObject.activeInHierarchy && !welcomeScreen.reviewAppRt.gameObject.activeInHierarchy && !welcomeScreen.updateAppRt.gameObject.activeInHierarchy)
                StartCoroutine(ShowNotification());
        }

        UpdateBars();
    }

    public void UpdateBars()
    {
        //int value = (barType == BarType.energy) ? playerDataManager.datas.energy : playerDataManager.datas.konsantrasyon;
        int value = 10;
        extraEnergyText.text = (barType == BarType.energy) ? $"ALTIN: {playerDataManager.datas.energy}" : $"ELMAS: {playerDataManager.datas.konsantrasyon}";

        for (int i = 0; i < squares.Count; i++)
        {
            Square square = squares[i];
            if (value >= squares.Count - i)
            {
                square.rectTransform.GetChild(0).gameObject.SetActive(true);
            }
            else
            {
                square.rectTransform.GetChild(0).gameObject.SetActive(false);
            }
        }

        if (value >= minAnimationAmount)
        {
            if (gameObject.activeInHierarchy)
                PlayExtraAnimation();
        }
        else
        {
            if (animationEnumerator != null)
            {
                StopCoroutine(animationEnumerator);
                animationEnumerator = null;
            }
        }
    }

    public IEnumerator ShowNotification()
    {
        notification.rectTransform.gameObject.SetActive(true);
        notification.rectTransform.anchoredPosition = GetComponent<RectTransform>().anchoredPosition;
        notification.rectTransform.DOAnchorPos(new Vector2(GetComponent<RectTransform>().anchoredPosition.x, -72), 0.4f).
            onComplete = () => {
                if (notification.notificationTweener != null)
                {
                    if (notification.notificationTweener.IsPlaying())
                        notification.notificationTweener.Complete();
                }
                notification.notificationTweener =
                notification.rectTransform.DOPunchScale(new Vector3(0.3f, 0.3f, 0), 0.5f, 6, 1.1f);
            };

        yield return new WaitForSeconds(5f);
        notification.rectTransform.DOAnchorPos(new Vector2(GetComponent<RectTransform>().anchoredPosition.x, 
            GetComponent<RectTransform>().anchoredPosition.y + 400), 0.5f);
        yield return new WaitForSeconds(0.4f);
        notification.rectTransform.gameObject.SetActive(false);
    }

    public static int GetMaxDailyEnergy()
    {
        if (FindObjectOfType<CurrentPlayerData>().GetChatVariableValue("plus") == "var")
        {
            return maxDailyEnergyPlus;
        }
        else
        {
            return maxDailyEnergy;
        }
    }

    public static int GetDailyEnergy()
    {
        if (FindObjectOfType<CurrentPlayerData>().GetChatVariableValue("plus") == "var")
        {
            return dailyEnergyPlus;
        }
        else
        {
            return dailyEnergy;
        }
    }

    [System.Serializable]
    public class Animation
    {
        public float maxScale;
        public float elasticity;
        public int impactField;
        public float duration;

        public Animation()
        {
            this.maxScale = 1.2f;
            this.duration = 0.15f;
            this.elasticity = 3;
            this.impactField = 3;
    }

        public Animation(float duration, float elasticity)
        {
            this.maxScale = 1.2f;
            this.duration = duration;
            this.elasticity = elasticity;
            this.impactField = 3;
        }
    }

    [System.Serializable]
    public class Square
    {
        public RectTransform rectTransform;
        [HideInInspector] public Tween tween;
    }

    [System.Serializable]
    public class Notification
    {
        public RectTransform rectTransform;
        public Text text;
        public Tweener notificationTweener;
    }
}
