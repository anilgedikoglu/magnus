using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class Brick : MonoBehaviour, IPointerClickHandler
{
    public event Action<Brick> PointerClick;

    [SerializeField]
    public Image sprite;

    public RectTransform RectTransform { get; private set; }

    void Awake()
    {
        RectTransform = GetComponent<RectTransform>();
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        PointerClick?.Invoke(this);
    }
}