using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;

public class InAppPopUp : MonoBehaviour
{
    public InAppPopUpData data;
    public TMP_Text debugText;
    public Image backgroundImage;
    public Image icon;
    public float duration = 5f;

    [HideInInspector] public float timer;

    public UnityEvent startEvent;
    public UnityEvent endEvent;

    // Start is called before the first frame update
    void Start()
    {

    }

    private void OnEnable()
    {
        //Kapanin acildigi zaman son kalan timerdan devam etmesin diye.
        timer = -1;
    }

    public void Initiliaze()
    {
        SetActive(false);
    }

    public void Log(string value)
    {
        startEvent.Invoke();

        SetActive(true);
        debugText.text = value;
        debugText.color = data.typeLog.color;
        icon.sprite = data.typeLog.sprite;
        icon.color = data.typeLog.color;
        backgroundImage.color = data.typeLog.backgroundColor;
        timer = duration;
    }

    public void LogWarning(string value)
    {
        startEvent.Invoke();

        SetActive(true);
        debugText.text = value;
        debugText.color = data.typeLogWarning.color;
        icon.sprite = data.typeLogWarning.sprite;
        icon.color = data.typeLogWarning.color;
        backgroundImage.color = data.typeLogWarning.backgroundColor;
        timer = duration;
    }

    public void LogError(string value)
    {
        startEvent.Invoke();

        SetActive(true);
        debugText.text = value;
        debugText.color = data.typeLogError.color;
        icon.sprite = data.typeLogError.sprite;
        icon.color = data.typeLogError.color;
        backgroundImage.color = data.typeLogError.backgroundColor;
        timer = duration;
    }

    public void LogSuccess(string value)
    {
        startEvent.Invoke();

        SetActive(true);
        debugText.text = value;
        debugText.color = data.typeLogSuccess.color;
        icon.sprite = data.typeLogSuccess.sprite;
        icon.color = data.typeLogSuccess.color;
        backgroundImage.color = data.typeLogSuccess.backgroundColor;
        timer = duration;
    }

    public void ClosePopUp()
    {
        SetActive(false);
        endEvent.Invoke();
    }

    public void SetActive(bool value)
    {
        backgroundImage.gameObject.SetActive(value);
    }

    // Update is called once per frame
    void Update()
    {
        if (timer > 0)
        {
            timer -= Time.deltaTime;

            if (timer <= 0)
            {
                timer = duration;
                ClosePopUp();
            }
        }
    }
}
