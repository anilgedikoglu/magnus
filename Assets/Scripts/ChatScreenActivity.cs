using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

public class ChatScreenActivity : MonoBehaviour
{
    public GameObject sceneContainer, bubbleContainer;

    public GameObject backButton;

    public GameObject reviewAppFolder;

    private ChatManager chatManager;

    [HideInInspector] public bool isChatScreenActive;
    private CurrentPlayerData playerData;
    private BilgiEkraniManager bilgiEkraniManager;

    public RectTransform[] topMenuLogos;

    private void Awake()
    {
        playerData = FindObjectOfType<CurrentPlayerData>();
        bilgiEkraniManager = FindObjectOfType<BilgiEkraniManager>();

        topMenuNotifAnimationEnumerator = TopMenuNotifAnimationEnumerator();
    }

    // Start is called before the first frame update
    void Start()
    {
        chatManager = GameObject.Find("ChatManager").GetComponent<ChatManager>();


        SetBackButtonActivity(true);
        SetDeactive();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetDeactive()
    {
        isChatScreenActive = false;
        sceneContainer.SetActive(false);

        if (reviewAppFolder.activeInHierarchy)
            reviewAppFolder.SetActive(false);

        if (topMenuNotifAnimationEnumerator != null)
            StopCoroutine(topMenuNotifAnimationEnumerator);
    }

    public void SetActive()
    {
        isChatScreenActive = true;
        sceneContainer.SetActive(true);

        topMenuNotifAnimationEnumerator = TopMenuNotifAnimationEnumerator();
        StartCoroutine(topMenuNotifAnimationEnumerator);
    }

    public void SetBackButtonActivity(bool buttonActivity)
    {
        if (buttonActivity)
        {
            backButton.GetComponent<Button>().enabled = true;
            backButton.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>().color = 
                new Color(backButton.GetComponent<Image>().color.r, backButton.GetComponent<Image>().color.g, backButton.GetComponent<Image>().color.b, 1);
        }
        else
        {
            backButton.GetComponent<Button>().enabled = false;
            backButton.GetComponent<RectTransform>().GetChild(0).GetComponent<Image>().color =
                new Color(backButton.GetComponent<Image>().color.r, backButton.GetComponent<Image>().color.g, backButton.GetComponent<Image>().color.b, 0);
        }
    }

    internal IEnumerator topMenuNotifAnimationEnumerator;
    /// <summary>
    /// Magnus kelebeginin plus olmasini ve bildirim varsa belirli surede bir
    /// bildirim logosu ile gecis yapmasini yurutur.
    /// </summary>
    internal IEnumerator TopMenuNotifAnimationEnumerator()
    {
        float animtionDuration = 0.2f;
        int bildirimAnimasyonuDelay = 3;

        topMenuLogos[0].localScale = Vector3.one;
        topMenuLogos[1].localScale = Vector3.one;
        topMenuLogos[2].localScale = Vector3.one;
        if (playerData.IsPlus)
        {
            topMenuLogos[0].gameObject.SetActive(false);
            topMenuLogos[1].gameObject.SetActive(true);
            topMenuLogos[2].gameObject.SetActive(false);
        }
        else
        {
            topMenuLogos[0].gameObject.SetActive(true);
            topMenuLogos[1].gameObject.SetActive(false);
            topMenuLogos[2].gameObject.SetActive(false);
        }

        if (bilgiEkraniManager.CheckInboxNotificationState())
        {
            while (true)
            {
                yield return new WaitForSeconds(bildirimAnimasyonuDelay);

                if (playerData.IsPlus)
                {
                    topMenuLogos[0].gameObject.SetActive(false);

                    topMenuLogos[1].DOScaleX(0, animtionDuration).onComplete = () =>
                    {
                        topMenuLogos[1].gameObject.SetActive(false);

                        topMenuLogos[2].localScale = new Vector3(0, 1, 1);
                        topMenuLogos[2].gameObject.SetActive(true);

                        topMenuLogos[2].DOScaleX(1, animtionDuration);
                    };
                }
                else
                {
                    topMenuLogos[1].gameObject.SetActive(false);

                    topMenuLogos[0].DOScaleX(0, animtionDuration).onComplete = () =>
                    {
                        topMenuLogos[0].gameObject.SetActive(false);

                        topMenuLogos[2].localScale = new Vector3(0, 1, 1);
                        topMenuLogos[2].gameObject.SetActive(true);

                        topMenuLogos[2].DOScaleX(1, animtionDuration);
                    };
                }
                yield return new WaitForSeconds(3);

                if (playerData.IsPlus)
                {
                    topMenuLogos[0].gameObject.SetActive(false);

                    topMenuLogos[2].DOScaleX(0, animtionDuration).onComplete = () =>
                    {
                        topMenuLogos[2].gameObject.SetActive(false);

                        topMenuLogos[1].localScale = new Vector3(0, 1, 1);
                        topMenuLogos[1].gameObject.SetActive(true);

                        topMenuLogos[1].DOScaleX(1, animtionDuration);
                    };
                }
                else
                {
                    topMenuLogos[1].gameObject.SetActive(false);

                    topMenuLogos[2].DOScaleX(0, animtionDuration).onComplete = () =>
                    {
                        topMenuLogos[2].gameObject.SetActive(false);

                        topMenuLogos[0].localScale = new Vector3(0, 1, 1);
                        topMenuLogos[0].gameObject.SetActive(true);

                        topMenuLogos[0].DOScaleX(1, animtionDuration);
                    };
                }
            }
        }
    }
}
