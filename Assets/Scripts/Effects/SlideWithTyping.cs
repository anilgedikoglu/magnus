using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
using UnityEngine.UI;
using TMPro;

public class SlideWithTyping : MonoBehaviour
{
    public TMP_Text text;
    public int textLength;


    public RectTransform slider;


    // Start is called before the first frame update
    void Start()
    {
        slider.localScale = new Vector3(0.025f, slider.localScale.y, slider.localScale.z);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OnValueChange()
    {
        slider.DOScaleX(Mathf.Clamp((float)text.text.Length / textLength, 0, 1), 0.5f);
    }

    public void OnEndEdit()
    {
        slider.DOScaleX(text.text.Length > 1 ? 1 : 0.025f, 0.25f);
    }
}
