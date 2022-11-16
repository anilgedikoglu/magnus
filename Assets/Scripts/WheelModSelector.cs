using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class WheelModSelector : MonoBehaviour, IBeginDragHandler , IEndDragHandler, IDragHandler
{
    public RectTransform mainCanvasRt;
    public RectTransform rt;

    private Vector3 firstMousePos;

    public Image wheelImage;

    public RectTransform selectedAreaRect;
    public RectTransform selectedAreaHighlightRect;

    public Animator animator;

    public InfiniteWheel.InfiniteWheelController sliderModSelectorController; 

    public WheelModSelectorData wheelModSelectorData;

    [HideInInspector] public WheelModSelectorData.WheelData currentData;

    private CurrentPlayerData playerData;

    private int _currentItemIndex;
    private int CurrentItemIndex
    {
        get
        {
            return _currentItemIndex;
        }
        set
        {
            if (value != _currentItemIndex)
            {
                int delta = _currentItemIndex - value;

                int angle = (int)System.MathF.Round(_currentItemIndex * (360f / currentData.items.Length));

                if (angle < 0)
                    angle += 360;

                //0 inci elementten son elemente gectigi ozel durumlar icin...
                if (_currentItemIndex == currentData.items.Length - 1 && value == 0)
                    delta = -1;

                if (_currentItemIndex == 0 && value == currentData.items.Length - 1)
                    delta = 1;

                selectedAreaHighlightRect.localEulerAngles = new Vector3(0, 0, (180f + angle + (delta < 0 ? 360f / currentData.items.Length : -360f / currentData.items.Length)));

                Debug.Log(angle);

                _currentItemIndex = value;
            }
        }
    }

    private void Awake()
    {
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    private void OnEnable()
    {
        rt.eulerAngles = Vector3.zero;
        int angle = (int)System.MathF.Floor(rt.eulerAngles.z);
        if (angle < 0)
            angle += 360;

        selectedAreaRect.eulerAngles = new Vector3(0, 0, 180 + (angle % (360f / currentData.items.Length)));

        CurrentItemIndex = 1;
        CurrentItemIndex = 0;
    }

    // Update is called once per frame
    void Update()
    {
        if(playerData.GetChatVariableValue("mod") != currentData.wheelModu)
        {
            gameObject.SetActive(false);
            sliderModSelectorController.gameObject.SetActive(false);
        }
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        firstMousePos = Input.mousePosition;
    }

    public void OnDrag(PointerEventData eventData)
    {
        Vector2 speenDirection = new Vector2(1, 1);
        Vector3 wheelScreenPoint = rt.position;

        if (wheelScreenPoint.y > eventData.position.y)
        {
            speenDirection = new Vector2(1, speenDirection.y);
        }
        else
        {
            speenDirection = new Vector2(-1, speenDirection.y);
        }

        if (wheelScreenPoint.x < eventData.position.x)
        {
            speenDirection = new Vector2(speenDirection.x, 1);
        }
        else
        {
            speenDirection = new Vector2(speenDirection.x, -1);
        }

        float rotateAmaount = ((eventData.position.x - firstMousePos.x) * speenDirection.x 
            + (eventData.position.y - firstMousePos.y) * speenDirection.y) / mainCanvasRt.localScale.y;

        rt.eulerAngles = new Vector3(rt.eulerAngles.x, rt.eulerAngles.y, rt.eulerAngles.z + rotateAmaount);
        firstMousePos = eventData.position;

        int angle = (int)System.MathF.Floor(rt.eulerAngles.z);
        if (angle < 0)
            angle += 360;

        selectedAreaRect.eulerAngles = new Vector3(0, 0, 180 + (angle % (360f / currentData.items.Length)));
        //selectedAreaHighlightRect.localEulerAngles = new Vector3(0, 0, -(180 + (angle)));

        CurrentItemIndex = angle / (360 / currentData.items.Length);
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        
    }

    public void OnClickOkButton()
    {
        Debug.Log(rt.eulerAngles.z);
        int angle = (int)rt.eulerAngles.z;

        if (angle < 0)
            angle += 360;

        FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList(
    currentData.items[CurrentItemIndex].ayarlananDegiskenler.degiskenAdi,
    currentData.items[CurrentItemIndex].ayarlananDegiskenler.degiskenDegeri);

        FindObjectOfType<ChatManager>().ClickVirtualButton(currentData.items[CurrentItemIndex].ayarlananMod);
        SetActive(false);
    }

    public void SetActive(bool value)
    {
        if (value)
        {
            gameObject.SetActive(true);
            gameObject.transform.GetChild(0).gameObject.SetActive(true);
            animator.SetBool("exit", false);

        }
        else
        {
            animator.SetBool("exit", true);
            StartCoroutine(ExitDelay());
        }
    }

    public void SetActive(bool value, Sprite wheelSprite)
    {
        if (value)
        {
            gameObject.SetActive(true);
            gameObject.transform.GetChild(0).gameObject.SetActive(true);
            animator.SetBool("exit", false);
            wheelImage.sprite = wheelSprite;
        }
        else
        {
            SetActive(false);
        }
    }

    public void SetActive(bool value, WheelModSelectorData.WheelData data)
    {
        if(data.type == WheelModSelectorData.WheelData.Type.wheel)
        {
            SetActive(value);
        }
        else
        {
            if (value)
            {
                //Onceden kalan childlar silinir...
                while (sliderModSelectorController.items.Count > 1)
                {
                    Destroy(sliderModSelectorController.items[^1].gameObject);
                    sliderModSelectorController.items.RemoveAt(sliderModSelectorController.items.Count - 1);
                }

                gameObject.SetActive(true);
                gameObject.transform.GetChild(0).gameObject.SetActive(false);

                var itemKomponent = sliderModSelectorController.items[0]
                    .GetComponent<InfiniteWheel.InfiniteWheelItem>();
                itemKomponent.itemText.text = currentData.items[0].baslik;
                itemKomponent.itemImage.sprite = currentData.items[0].fotograf;

                float scale = 300f / itemKomponent.itemImage.sprite.rect.width;
                sliderModSelectorController.items[0].
                    itemImage.transform.localScale = new Vector3(scale, scale, scale);

                itemKomponent.onClick.RemoveAllListeners();
                itemKomponent.onClick.AddListener(() => {
                    FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList(
                        currentData.items[0].ayarlananDegiskenler.degiskenAdi,
                        currentData.items[0].ayarlananDegiskenler.degiskenDegeri);

                    FindObjectOfType<ChatManager>().ClickVirtualButton(currentData.items[0].ayarlananMod);
                    SetActive(false, data);

                    if (data.showAd && playerData.GetChatVariableValue("plus") != "var")
                        FindObjectOfType<AdManager>().ShowInterstitial();
                });

                for (int i = 1; i<currentData.items.Length; i++)
                {
                    var item = Instantiate(sliderModSelectorController.items[0],
                        sliderModSelectorController.items[0].transform.parent);

                    sliderModSelectorController.items.Add(item);

                    itemKomponent = item.GetComponent<InfiniteWheel.InfiniteWheelItem>();
                    itemKomponent.itemText.text = currentData.items[i].baslik;
                    itemKomponent.itemImage.sprite = currentData.items[i].fotograf;

                    int index = i;
                    itemKomponent.onClick.RemoveAllListeners();
                    itemKomponent.onClick.AddListener(() => {

                        FindObjectOfType<CurrentPlayerData>().AddElementToChatVariableList(
                            currentData.items[index].ayarlananDegiskenler.degiskenAdi,
                            currentData.items[index].ayarlananDegiskenler.degiskenDegeri);

                        FindObjectOfType<ChatManager>().ClickVirtualButton(currentData.items[index].ayarlananMod);
                        SetActive(false, data);

                        if (data.showAd && playerData.GetChatVariableValue("plus") != "var")
                            FindObjectOfType<AdManager>().ShowInterstitial();
                    });

                    scale = 300f / itemKomponent.itemImage.sprite.rect.width;
                    itemKomponent.itemImage.transform.localScale = new Vector3(scale, scale, scale);
                }
            }
            else
            {

            }
            sliderModSelectorController.gameObject.SetActive(value);
        }
    }

    private IEnumerator ExitDelay()
    {
        yield return new WaitForSeconds(2f);
        gameObject.SetActive(false);
    }
}
