using UnityEngine;
using UnityEngine.UI;

public class Panel : MonoBehaviour
{
    [SerializeField]
    Toggle showToggle;
    [SerializeField]
    Button[] hideButtons;

    [SerializeField]
    protected GameObject content;

    protected virtual void Show()
    {
        content.SetActive(true);
    }

    protected virtual void Hide()
    {
        content.SetActive(false);
    }

    void OnOptionsToggleClick(bool value)
    {
        if (value)
            Show();
        else
            Hide();
    }

    protected virtual void Awake()
    {
        showToggle.onValueChanged.AddListener(OnOptionsToggleClick);
        foreach (Button hideButton in hideButtons)
        {
            hideButton.onClick.AddListener(() => showToggle.isOn = false);
        }
    }
}
