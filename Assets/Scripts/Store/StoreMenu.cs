using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using NativeShareNamespace;

public class StoreMenu : MonoBehaviour
{
    public Animator animator;

    public List<RectTransform> navigationButtons;

    public Color navigationButtonActiveColor, navigationButtonDeactiveColor;

    private ChatManager chatManager;

    // Start is called before the first frame update
    void Start()
    {
        chatManager = FindObjectOfType<ChatManager>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetAnimatorState(int value)
    {
        animator.SetInteger("state", value);

        foreach(RectTransform rectTransform in navigationButtons)
        {
            rectTransform.SetSiblingIndex(0);
            rectTransform.GetComponent<Image>().color = navigationButtonDeactiveColor;
        }

        //navigationButtons[value - 1].gameObject.SetActive(true);
        navigationButtons[value - 1].SetSiblingIndex(navigationButtons[value - 1].parent.childCount - 1);
        navigationButtons[value - 1].GetComponent<Image>().color = navigationButtonActiveColor;
    }

    public void ClosePanel()
    {
        chatManager.otomatikOdak = false;
        gameObject.SetActive(false);
    }

    public void ShareOnInstagram()
    {
        new NativeShare().SetSubject("Subject goes here").SetText("Hello world!")
        .SetUrl("https://play.google.com/store/apps/details?id=com.futurastic.Magnus").AddTarget("com.instagram.android")
        .SetCallback((result, shareTarget) =>
        {
            Debug.Log("Share result: " + result + ", selected app: " + shareTarget);
        }).Share();
    }

    public void ShareOnGeneral()
    {
        new NativeShare().SetSubject("Magnus Tarot & Kahve Falı").SetText("Magnus uygulumasını indir ve geleceğinle ilgili merak ettiklerini öğren!")
        .SetUrl("https://play.google.com/store/apps/details?id=com.futurastic.Magnus")
        .SetCallback((result, shareTarget) =>
        {
            Debug.Log("Share result: " + result + ", selected app: " + shareTarget);
        }).Share();
    }

    public void OpenFollowPage(string url)
    {
        Application.OpenURL(url);
    }
}
