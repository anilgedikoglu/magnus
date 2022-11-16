using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;

namespace Magnus.UI
{
    public class DoubleTapButton : MonoBehaviour, IPointerClickHandler
    {
        public float doubleTapDuration = 0.1f;
        private float doubleTapTimer;

        public UnityEvent onDoubleClick;

        private void Awake()
        {
            doubleTapTimer = -1;
        }

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            if (doubleTapTimer > 0)
            {
                doubleTapTimer -= UnityEngine.Time.deltaTime;
            }
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (doubleTapTimer > 0)
            {
                onDoubleClick.Invoke();
                doubleTapTimer = -1;

                Debug.Log("Double click tamamlandı");
            }
            else
            {
                doubleTapTimer = doubleTapDuration;

                Debug.Log("Double click başlatıldı");
            }
        }
    }
}