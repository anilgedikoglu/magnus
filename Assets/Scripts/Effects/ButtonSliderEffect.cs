using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;

public class ButtonSliderEffect : MonoBehaviour
{
    public RectTransform sliderRect;

    private RectTransform rt;
    public Image CheckBox;
    Color checkBoxDefualtColor;
    public Color checkBoxSelectedColor;

    [HideInInspector] public Vector3 sizeSmall, sizeLarge, animationFisrtSize;
    [HideInInspector] public float startTime;
    [HideInInspector] public int animationType;

    public float duration;
    public UnityEvent finishEvent;

    public float invalidClickAcceptTimer = 3f;

    // Start is called before the first frame update
    void Start()
    {
        checkBoxDefualtColor = CheckBox.color;
        animationType = -1;

        rt = gameObject.GetComponent<RectTransform>();

        sizeSmall = new Vector3(0, 0, 0);
        sizeLarge = new Vector3(rt.rect.width, 0, 0);
    }

    // Update is called once per frame
    void Update()
    {
        SizeUpdate();
    }

    public void SizeUpdate()
    {
        //****************************************************************************************************************************************************************************************************
        if (animationType == 1)
        {
            float t = (Time.time - startTime) / duration;
            sliderRect.sizeDelta = new Vector3(Mathf.SmoothStep(animationFisrtSize.x, sizeLarge.x, t), sliderRect.sizeDelta.y);
            
            if (t >= 1)
            {
                finishEvent.Invoke();
            }
        }
        else if(animationType == 0)
        {
            float t = (Time.time - startTime) / invalidClickAcceptTimer;
            sliderRect.sizeDelta = new Vector3(Mathf.SmoothStep(animationFisrtSize.x, sizeSmall.x, t), sliderRect.sizeDelta.y);

            if (t >= 1)
            {
                finishEvent.Invoke();
            }
        }
        else
        {
            sliderRect.sizeDelta = new Vector3(sizeSmall.x, sliderRect.sizeDelta.y);
        }

    }

    public void SetAnimationTimer(int animationType)
    {
        GameObject[] allButtons = GameObject.FindGameObjectsWithTag("terminalTimerButton");
        
        foreach(GameObject element in allButtons)
        {
            element.GetComponent<ButtonSliderEffect>().animationType = -1;
            element.GetComponent<ButtonSliderEffect>().CheckBox.color = checkBoxDefualtColor;
        }

        if (animationType == 1)
        {
            sliderRect.sizeDelta = new Vector3(0f, sliderRect.sizeDelta.y);
        }

        //Imleci ustune getirdiginde ya da kaldirdiginda her zaman checkBox yesil olmali. Yoksa secilen obje imlec kalkinca griye doner. Fakat biz secili kalmasini istiyoruz.
        CheckBox.color = checkBoxSelectedColor;
        startTime = Time.time;
        this.animationType = animationType;
        animationFisrtSize = new Vector3(sliderRect.sizeDelta.x, 0, 0);
    }
}
