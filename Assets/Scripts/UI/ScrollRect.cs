using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace Magnus.UI
{
    public class ScrollRect : MonoBehaviour, IDragHandler, IEndDragHandler, IBeginDragHandler
    {
        RectTransform rectTransform;
        public RectTransform container;
        public RectTransform mainCanvasRect;

        public float dragSensivity = 1f;

        List<Vector2> lastDragPositions;

        bool canDrag;

        float _speed;
        float speed
        {
            get
            {
                return _speed;
            }
            set
            {
                if (value >= -maxSpeed && value <= maxSpeed)
                    _speed = value;
                else
                {
                    if (value < 0)
                        _speed = -maxSpeed;
                    else
                        _speed = maxSpeed;
                }
            }
        }

        float speedDirection;
        public float acceleration = 0.25f;
        public float deceleration = 100f;
        public float maxSpeed = 100f;

        float touchOffset;

        // Start is called before the first frame update
        void Start()
        {
            rectTransform = GetComponent<RectTransform>();
        }

        public void OnEnable()
        {
            speed = 0;
            lastDragPositions = new List<Vector2>();
        }

        // Update is called once per frame
        void Update()
        {
            if (speedDirection == 1)
            {
                if (speed > 0)
                {
                    speed -= UnityEngine.Time.deltaTime * deceleration;
                    container.position = new Vector2(container.position.x, Mathf.Clamp(container.position.y - speed, rectTransform.position.y - (Mathf.Abs(rectTransform.rect.height - container.rect.height) / 2f) * mainCanvasRect.localScale.y,
                 rectTransform.position.y + (Mathf.Abs(rectTransform.rect.height - container.rect.height) / 2f) * mainCanvasRect.localScale.y));
                }
            }
            else
            {
                if (speed < 0)
                {
                    speed += UnityEngine.Time.deltaTime * deceleration;
                    container.position = new Vector2(container.position.x, Mathf.Clamp(container.position.y - speed, rectTransform.position.y - (Mathf.Abs(rectTransform.rect.height - container.rect.height) / 2f) * mainCanvasRect.localScale.y,
                 rectTransform.position.y + (Mathf.Abs(rectTransform.rect.height - container.rect.height) / 2f) * mainCanvasRect.localScale.y));
                }
            }

            if (canDrag)
                AddElementInLastDragPosList(Input.mousePosition);
        }

        void AddElementInLastDragPosList(Vector2 value)
        {
            while (lastDragPositions.Count >= 5)
            {
                lastDragPositions.RemoveAt(0);
            }

            lastDragPositions.Add(value);
        }

        Vector2 GetAvarageLastDragPositionValue()
        {
            Vector2 totalValue = new Vector2();
            foreach (Vector2 value in lastDragPositions)
            {
                totalValue += value;
            }

            return totalValue / ((float)lastDragPositions.Count);
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            touchOffset = container.position.y - Input.mousePosition.y;
            lastDragPositions = new List<Vector2>();
            canDrag = true;
            speed = 0;
        }

        public void OnDrag(PointerEventData eventData)
        {
            container.position = new Vector2(container.position.x, Mathf.Clamp(Input.mousePosition.y + touchOffset, rectTransform.position.y - (Mathf.Abs(rectTransform.rect.height - container.rect.height) /2f) * mainCanvasRect.localScale.y, 
                rectTransform.position.y + (Mathf.Abs(rectTransform.rect.height - container.rect.height) / 2f) * mainCanvasRect.localScale.y));
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            speed = (GetAvarageLastDragPositionValue().y - Input.mousePosition.y) * (Screen.width / 1080f) * acceleration;

            canDrag = false;

            if (speed > 0)
                speedDirection = 1;
            else
                speedDirection = -1;
        }
    }
}