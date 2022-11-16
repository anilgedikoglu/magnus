using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PositonHandler : MonoBehaviour
{
    public RectTransform bubbleRt;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 speechBubbleLeftWorldPositon = Camera.main.WorldToScreenPoint(Camera.main.ScreenToWorldPoint(bubbleRt.position));
        transform.position = bubbleRt.position;
    }
}
