using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Button))]
public class OpenUrlButton : MonoBehaviour
{
    [SerializeField]
    string url;

    void Start()
    {
        GetComponent<Button>().onClick.AddListener(OnClick);
    }

    void OnClick()
    {
        Application.OpenURL(url);
    }
}
