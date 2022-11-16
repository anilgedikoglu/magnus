using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WindowManager : MonoBehaviour
{
    private GameObject contents;

    public bool isActive;

    private Vector3 realPosition;

    private void Awake()
    {
        contents = transform.GetChild(0).gameObject;
        contents.SetActive(isActive);
    }

    void Start()
    {

    }

    void Update()
    {

    }


    public void WindowAcivityButton() 
    {
        RectTransform rt = GetComponent<RectTransform>();
        RectTransform canvasRt = GameObject.Find("Canvas").GetComponent<RectTransform>();

        if (isActive) 
        {
            isActive = false;
            contents.SetActive(isActive);
        }
        else 
        {
            isActive = true;
            contents.SetActive(isActive);
        }
    }

    public void WindowAcivityButton(bool state)
    {
        contents.SetActive(state);
    }
}
