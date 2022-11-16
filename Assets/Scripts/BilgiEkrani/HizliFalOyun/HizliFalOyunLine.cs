using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class HizliFalOyunLine : MonoBehaviour
{
    private RectTransform rect;
    private HorizontalLayoutGroup horizontalLayoutGroup;
    private ContentSizeFitter contentSizeFitter;
    private HizliFalOyunManager hizliFalOyunManager;
    private GameObject firsChild;

    public int elementCount = 3;

    [HideInInspector] public bool isRenderCompleted = false;

    private void Awake()
    {
        rect = GetComponent<RectTransform>();
        horizontalLayoutGroup = GetComponent<HorizontalLayoutGroup>();
        contentSizeFitter = GetComponent<ContentSizeFitter>();
        hizliFalOyunManager = FindObjectOfType<HizliFalOyunManager>();

        firsChild = rect.GetChild(0).gameObject;
    }

    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(CreateElements());
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public IEnumerator CreateElements()
    {
        //-1 yapma nedenimiz zaten bir child'in olusmus olarak
        //baslamasi!
        for (int i = 0; i < elementCount - 1; i++)
        {
            yield return new WaitForSeconds(Time.deltaTime * 3f);
            Instantiate(firsChild, rect);
        }

        yield return new WaitForEndOfFrame();
        contentSizeFitter.SetLayoutVertical();

        horizontalLayoutGroup.CalculateLayoutInputHorizontal();
        horizontalLayoutGroup.CalculateLayoutInputVertical();

        VerticalLayoutGroup parentVerticalLayoutGroup =
            rect.parent.GetComponent<VerticalLayoutGroup>();
        parentVerticalLayoutGroup.CalculateLayoutInputHorizontal();
        parentVerticalLayoutGroup.CalculateLayoutInputVertical();

        Canvas.ForceUpdateCanvases();

        hizliFalOyunManager.FindElements();
        hizliFalOyunManager.updateUI();

        isRenderCompleted = true;
        
        HizliFalOyunLine[] lines = FindObjectsOfType<HizliFalOyunLine>();

        foreach(HizliFalOyunLine hizliFalOyunLine in lines)
        {
            if (!hizliFalOyunLine.isRenderCompleted)
            {
                yield break;
            }
        }

        hizliFalOyunManager.loadingMask.SetActive(false);
    }
}
