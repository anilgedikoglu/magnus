using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Events;

using DG.Tweening;

public class DelayButton : MonoBehaviour, IPointerClickHandler
{
    public UnityEvent onClick;
    public RectTransform slider;

    float delayTimer;
    public float delay;

    public bool delayActive = true;

    private void Awake()
    {
        if (slider != null)
        {
            onClick.AddListener(BaseOnClick);
            slider.localScale = new Vector3(0, slider.localScale.y, slider.localScale.z);
        }
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (delayActive)
        {
            if (delayTimer > 0)
            {
                delayTimer -= Time.deltaTime;
            }
        }
        else
        {
            delayTimer = 0;
        }
    }

    void BaseOnClick()
    {
        if (delayActive)
        {
            if (slider != null)
            {
                slider.localScale = new Vector3(1, slider.localScale.y, slider.localScale.z);
                slider.DOScaleX(0, delay);
            }
        }
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if (delayTimer <= 0)
        {
            onClick.Invoke();
            delayTimer = delay;
        }
        else
        {
            Debug.Log("Bu butona " + delayTimer + " saniye sonra tekrar basilabilir");
        }
    }
}
