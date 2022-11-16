using UnityEngine;

namespace AimTrainer
{
    public class CameraLook : MonoBehaviour
    {
        public float mouseSensitivity = 100f;

        public Transform playerBody;

        //public FixedJoystick joystick;

        float xRotation = 0f;

        public GameObject gun;

        public bool test;

        //private CurrentPlayerData dataObject;

        float gyroInitialOrientationX;
        float gyroInitialOrientationY;

        void Start()
        {
#if UNITY_EDITOR
            test = true;
            Cursor.lockState = CursorLockMode.Locked;
#elif UNITY_ANDROID
        test = false;
#elif UNITY_IPHONE
        test = false;
#else
         test = false;
#endif

            //dataObject = GameObject.Find("CurrentPlayerData").GetComponent<CurrentPlayerData>();
            //mouseSensitivity = dataObject.datas.mouseSensivity;
            mouseSensitivity = 100f;
        }

        void Update()
        {
            SetRotations();
        }

        private void FixedUpdate()
        {
            Input.gyro.enabled = true;
            gyroInitialOrientationX = Input.gyro.rotationRateUnbiased.x;
            gyroInitialOrientationY = Input.gyro.rotationRateUnbiased.y;
        }

        void SetRotations()
        {
            float pointer_x;
            float pointer_y;

            if (!test)
            {
                if (Input.touches.Length > 0)
                {
                    pointer_x = Input.touches[0].deltaPosition.x / 20f;
                    pointer_y = Input.touches[0].deltaPosition.y / 20f;
                }
                else
                {
                    pointer_x = 0f;
                    pointer_y = 0f;
                }
            }
            else
            {
                pointer_x = Input.GetAxis("Mouse X");
                pointer_y = Input.GetAxis("Mouse Y");
            }


            float mouseX = 0;
            float mouseY = 0;

            /*
            if (dataObject.datas.controlType == 0)
            {
                mouseX = dataObject.datas.reverseXAxis * pointer_x * mouseSensitivity * Time.deltaTime;
                mouseY = dataObject.datas.reverseYAxis * pointer_y * mouseSensitivity * Time.deltaTime;
            }
            else if (dataObject.datas.controlType == 1)
            {
                mouseX = dataObject.datas.reverseXAxis * gyroInitialOrientationY * mouseSensitivity * Time.deltaTime;
                mouseY = dataObject.datas.reverseYAxis * (-1f) * gyroInitialOrientationX * mouseSensitivity * Time.deltaTime;
            }*/

            mouseX = pointer_x * mouseSensitivity * Time.deltaTime;
            mouseY = pointer_y * mouseSensitivity * Time.deltaTime;

            xRotation -= mouseY;
            xRotation = Mathf.Clamp(xRotation, -90f, 90f);

            if (!AimTrainer.pause && !AimTrainer.endOfTheGame)
            {
                transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
                playerBody.Rotate(Vector3.up * mouseX);
            }
        }
    }
}