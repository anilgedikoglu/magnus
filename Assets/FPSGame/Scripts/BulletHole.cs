using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AimTrainer
{
    public class BulletHole : MonoBehaviour
    {
        public float destroySpeed = 1f;
        public float haloDestroyTime = 1f;

        private float haloDestroyTimeFirst;
        private float haloFirstScale;



        private GameObject bulletHalo;

        void Start()
        {
            bulletHalo = gameObject.transform.GetChild(0).gameObject;
            haloFirstScale = bulletHalo.transform.localScale.x;
            haloDestroyTimeFirst = haloDestroyTime;
        }

        void Update()
        {
            if (bulletHalo.transform.localScale.x > 0f)
            {
                haloDestroyTime -= Time.deltaTime;
                bulletHalo.transform.localScale = new Vector3(haloFirstScale * (haloDestroyTime / haloDestroyTimeFirst), haloFirstScale * (haloDestroyTime / haloDestroyTimeFirst), haloFirstScale * (haloDestroyTime / haloDestroyTimeFirst));
            }

            Renderer objectRenderer = GetComponent<Renderer>();

            if (objectRenderer.material.color.a > 0f)
            {
                objectRenderer.material.color = new Color(objectRenderer.material.color.r, objectRenderer.material.color.g, objectRenderer.material.color.b, objectRenderer.material.color.a - Time.deltaTime * destroySpeed);
            }
            else
            {
                Destroy(gameObject);
            }
        }
    }
}
