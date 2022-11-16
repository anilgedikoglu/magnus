using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class BookManager : MonoBehaviour
{
    public BookController bookController;
    public Transform cameraTransform, cameraZoomFirstPoint, cameraZoomSecondPoint;
    Vector3 cameraDefaultPosition;

    [HideInInspector] public Vector3 cameraAnimFirstPos, cameraAnimSecondPos;
    [HideInInspector] public float cameraAnimationTimer;
    bool zoomClickIsActive;
    public float cameraAnimationDuration;

    public RectTransform bookRawImage;
    public GameObject bookPanel;

    public GameObject secondPreviousButton;

    public Animator bookAnimator;

    [HideInInspector] public Vector3 dragFirstPos, dragSecondPos;

    public TMP_Text firstPageText, secondPageText;

    [SerializeField]
    Image bookImage;
    [SerializeField]
    Sprite bookTexture;
    [SerializeField]
    Sprite notepadTexture;

    public GameObject[] pages;
    public ChatManager chatManager;

    int currentPage;
    View currentView;

    IEnumerator changeFirsPage;
    public enum View
    {
        Book,
        Notepad
    }

    void Start()
    {
        cameraDefaultPosition = cameraTransform.position;

        bookRawImage.sizeDelta = new Vector2(bookRawImage.sizeDelta.x, bookRawImage.rect.size.x * ((float)cameraTransform.gameObject.GetComponent<Camera>().targetTexture.height / cameraTransform.gameObject.GetComponent<Camera>().targetTexture.width));

        cameraAnimationTimer = Time.time - cameraAnimationDuration;
        cameraAnimFirstPos = cameraDefaultPosition;
        cameraAnimSecondPos = cameraDefaultPosition;

        zoomClickIsActive = true;

        UpdatePage();

        bookPanel.SetActive(false);
        gameObject.transform.GetChild(0).gameObject.SetActive(false);
    }

    private void Update()
    {
        float t = (Time.time - cameraAnimationTimer) / cameraAnimationDuration;
        cameraTransform.position = new Vector3(Mathf.SmoothStep(cameraAnimFirstPos.x, cameraAnimSecondPos.x, t), Mathf.SmoothStep(cameraAnimFirstPos.y, cameraAnimSecondPos.y, t), Mathf.SmoothStep(cameraAnimFirstPos.z, cameraAnimSecondPos.z, t));

    }

    public void SetBook(bool value)
    {
        SetView(value ? View.Book : View.Notepad);
    }

    void SetView(View value)
    {
        if (currentView == value) return;

        currentView = value;
        bookImage.sprite = currentView == View.Book ? bookTexture : notepadTexture;
    }

    void NextPage()
    {
        if (currentPage < pages.Length - 1)
        {
            if (changeFirsPage != null)
            {
                StopCoroutine(changeFirsPage);
            }

            bookController.NextPage();
            currentPage = Mathf.Min(++currentPage, pages.Length - 1);
            StartCoroutine(UpdatePageDelayed());
        }
    }

    void PreviousPage()
    {
        if (currentPage > 0)
        {
            bookController.PreviousPage();
            currentPage = Mathf.Max(--currentPage, 0);
            StartCoroutine(UpdatePageDelayed());
        }
    }

    IEnumerator UpdatePageDelayed()
    {
        yield return new WaitForEndOfFrame();
        UpdatePage();
    }

    void UpdatePage()
    {
        Array.ForEach(pages, c => { c.SetActive(false); });
        pages[currentPage].SetActive(true);

        //nextButton.gameObject.SetActive(currentPage < pages.Length - 1);
        //previousButton.gameObject.SetActive(currentPage > 0);
    }

    public void ZoomFirstPage()
    {
        if (zoomClickIsActive)
        {
            cameraAnimationTimer = Time.time;

            if (cameraAnimSecondPos != cameraZoomFirstPoint.position && cameraAnimSecondPos != cameraZoomSecondPoint.position)
            {
                cameraAnimSecondPos = cameraZoomFirstPoint.position;
                cameraAnimFirstPos = cameraTransform.position;
                secondPreviousButton.SetActive(true);
            }
            else if (cameraAnimSecondPos != cameraZoomSecondPoint.position)
            {
                cameraAnimSecondPos = cameraZoomSecondPoint.position;
                cameraAnimFirstPos = cameraTransform.position;
                secondPreviousButton.SetActive(true);
            }
            else
            {
                cameraAnimSecondPos = cameraDefaultPosition;
                cameraAnimFirstPos = cameraTransform.position;
                secondPreviousButton.SetActive(false);
            }
        }
        else
        {
            zoomClickIsActive = true;
        }
    }

    public void BeginDrag()
    {
        dragFirstPos = Input.mousePosition;
        zoomClickIsActive = false;
    }

    public void EndDrag()
    {
        dragSecondPos = Input.mousePosition;

        if (dragFirstPos.x > dragSecondPos.x)
        {
            NextPage();
        }
        else
        {
            PreviousPage();
        }
    }

    public void OpenPanel(string text1, string text2)
    {
        firstPageText.text = text1;
        secondPageText.text = text2;

        cameraAnimationTimer = Time.time - cameraAnimationDuration;
        cameraAnimSecondPos = cameraDefaultPosition;
        cameraAnimFirstPos = cameraTransform.position;
        secondPreviousButton.SetActive(false);

        currentPage = 0;
        UpdatePage();

        changeFirsPage = ChangeFirsPage();

        StartCoroutine(changeFirsPage);

        bookAnimator.SetBool("exit", false);
        gameObject.transform.GetChild(0).gameObject.SetActive(true);
        bookPanel.SetActive(true);
    }

    public void ClosePanel()
    {
        bookAnimator.SetBool("exit", true);
        gameObject.transform.GetChild(0).gameObject.SetActive(false);
        StartCoroutine(ClosePanelDelay());
    }

    IEnumerator ClosePanelDelay()
    {
        yield return new WaitForSeconds(0.5f);
        bookPanel.SetActive(false);
        chatManager.otomatikOdak = false;
    }

    IEnumerator ChangeFirsPage()
    {
        yield return new WaitForSeconds(0.7f);
        NextPage();
    }
}
