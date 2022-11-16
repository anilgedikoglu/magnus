using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;

public class SliderNavigationButtonManager : MonoBehaviour
{
    public RectTransform indicator;
    public List<RectTransform> buttons;
    public float animationDuration = .25f;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void ClickButton(int index)
    {
        indicator.DOMove(buttons[index].position, animationDuration);
    }

    public void ClickButtonWithoutAnimation(int index)
    {
        indicator.position = buttons[index].position;
    }
}
