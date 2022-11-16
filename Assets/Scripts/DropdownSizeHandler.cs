using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Michsky.UI.ModernUIPack;

public class DropdownSizeHandler : MonoBehaviour
{
    private CustomDropdown dropdownManager;

    private Vector3 firsPosition;
    private Vector2 firsSize;

    private Vector3 realPosition;

    void Start()
    {
        dropdownManager = gameObject.GetComponent<CustomDropdown>();

        RectTransform rt = GetComponent<RectTransform>();
        firsPosition = rt.position;
        firsSize = rt.sizeDelta;
    }

    void Update()
    {
        SetSize();
        SetPositionToRealPosition();
    }

    void SetSize() 
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        if (dropdownManager.isOn) 
        {
            rt.sizeDelta = new Vector2(canvasRt.sizeDelta.x - canvasRt.sizeDelta.x / 10f, rt.sizeDelta.y);
            realPosition = canvasRt.position;
        }
        else 
        {
            rt.sizeDelta = firsSize;
            realPosition = firsPosition;
        }
    }

    void SetPositionToRealPosition()
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        if (rt.position.y > realPosition.y + 0.5f || rt.position.y < realPosition.y - 0.5f)
        {
            rt.position = new Vector3(rt.position.x, rt.position.y + (realPosition.y - rt.position.y) * Time.deltaTime * 7f, rt.position.z);
        }
        else
        {
            rt.position = new Vector3(rt.position.x, realPosition.y, rt.position.z);
        }

        if (rt.position.x > realPosition.x + 0.5f || rt.position.x < realPosition.x - 0.5f)
        {
            rt.position = new Vector3(rt.position.x + (realPosition.x - rt.position.x) * Time.deltaTime * 20f, rt.position.y, rt.position.z);
        }
        else
        {
            rt.position = new Vector3(realPosition.x, rt.position.y, rt.position.z);
        }
    }
}
