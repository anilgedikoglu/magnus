using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FolderNavigationButtonsManager : MonoBehaviour
{
    public List<NavigationButton> buttons;

    public List<GameObject> additionalDeactivatePanels;

    public Color activeColor;
    public Color deactiveColor;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetButtonActive(int index)
    {
        foreach (NavigationButton button in buttons)
        {
            button.rect.SetAsFirstSibling();
            button.image.color = deactiveColor;

            if (button.activatePanel != null)
                button.activatePanel.SetActive(false);

            if (additionalDeactivatePanels != null)
                if (additionalDeactivatePanels.Count > 0)
                    foreach (GameObject panel in additionalDeactivatePanels)
                        panel.SetActive(false);
        }

        if (index >= 0 && index < buttons.Count)
        {
            buttons[index].rect.SetAsLastSibling();
            buttons[index].image.color = activeColor;

            if (buttons[index].activatePanel != null)
                buttons[index].activatePanel.SetActive(true);
        }
    }

    [System.Serializable]
    public class NavigationButton
    {
        public RectTransform rect;
        public Image image;
        public GameObject activatePanel;
    }
}
