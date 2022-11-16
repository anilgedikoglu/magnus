using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
using UnityEngine.UI;

namespace Magnus.UI
{
    public class AdvancedGraph : MonoBehaviour
    {
        public List<Element> elements;

        private float totalUsableAngle = 360f;
        public float spaceBetweenEachElement = 5f;

        public float animationDuration = 1f;

        private bool isAnimationCompleted = false;

        public bool initiliazeOnStart;

        [HideInInspector] public bool isActive;

        private void Awake()
        {
            if (initiliazeOnStart)
            {
                Initialaze(false);
                isAnimationCompleted = true;
            }
            else
            {
                foreach (Element element in elements)
                {
                    element.value = 0;
                    element.Initialaze();
                }
            }
        }

        public void Initialaze(bool update)
        {
            foreach (Element element in elements)
            {
                element.Initialaze();
            }
            totalUsableAngle = 360 - (spaceBetweenEachElement * elements.Count);
            isAnimationCompleted = !update;
        }


        //Animasyonu sifirla
        private void OnEnable()
        {
            if (isActive)
            {
                Initialaze(true);
            }
        }

        // Start is called before the first frame update
        void Start()
        {
            isActive = true;
        }

        // Update is called once per frame
        void Update()
        {
            if (!isAnimationCompleted)
            {
                foreach (Element element in elements)
                {
                    bool state = element.image.fillAmount < element.value - (spaceBetweenEachElement / 360f);
                    if (state)
                    {
                        element.image.fillAmount += UnityEngine.Time.deltaTime / animationDuration;

                        if (element.image.fillAmount > element.value - (spaceBetweenEachElement / 360f))
                        {
                            element.image.fillAmount = element.value - (spaceBetweenEachElement / 360f);
                        }
                        break;
                    }
                }

                if (elements[^1].image.fillAmount >= elements[^1].value - (spaceBetweenEachElement / 360f))
                {
                    isAnimationCompleted = true;

                    foreach (Element element in elements)
                    {
                        element.image.fillAmount = element.value - (spaceBetweenEachElement / 360f);
                    }
                }

                Draw();
            }
        }

        public void Draw()
        {
            float currentAngle = -spaceBetweenEachElement;
            for (int i = 0; i < elements.Count; i++)
            {
                var element = elements[i];

                //element.image.fillAmount = element.value - (spaceBetweenEachElement / 360f);

                element.rectTransform.eulerAngles = new Vector3(element.rectTransform.eulerAngles.x,
                    element.rectTransform.eulerAngles.y, currentAngle

                    );

                currentAngle += -element.value * 360f;
            }
        }

        [System.Serializable]
        public class Element
        {
            [SerializeField] private GameObject _object;
            [HideInInspector] public Image image;
            [HideInInspector] public RectTransform rectTransform;
            public float value;

            public void Initialaze()
            {
                rectTransform = _object.GetComponent<RectTransform>();
            
                image = _object.GetComponent<Image>();
                image.fillAmount = 0;
            }
        }
    }
}