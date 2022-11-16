using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BubbleMoverManager : MonoBehaviour
{
    public float timerDuration;
    private float timer;

    public RectTransform contentRt;
    public RectTransform canvasRt;

    RectTransform rt;

    // Start is called before the first frame update
    void Start()
    {
        rt = GetComponent<RectTransform>();
    }

    // Update is called once per frame
    void Update()
    {
        if (timer > 0)
        {
            timer -= Time.deltaTime;
        }
        else
        {
            timer = timerDuration;
            SetChildsActivity();
        }
    }

    public void SetChildsActivity()
    {
        for(int i = 0; i<rt.childCount; i++)
        {
            RectTransform child = rt.GetChild(i).GetComponent<RectTransform>();
            if (child.GetComponent<AnswerBubble>() == null)
            {
                if (child.position.y - (child.sizeDelta.y / 2f) * canvasRt.localScale.y > contentRt.position.y + (contentRt.sizeDelta.y / 2f) * canvasRt.localScale.y)
                {
                    if (child.gameObject.activeInHierarchy)
                        child.gameObject.SetActive(false);
                }
                else if (child.position.y + (child.sizeDelta.y / 2f) * canvasRt.localScale.y < contentRt.position.y - (contentRt.sizeDelta.y / 2f) * canvasRt.localScale.y)
                {
                    if (child.gameObject.activeInHierarchy)
                        child.gameObject.SetActive(false);
                }
                else
                {
                    if (!child.gameObject.activeInHierarchy)
                        child.gameObject.SetActive(true);
                }
            }
        }
    }
}
