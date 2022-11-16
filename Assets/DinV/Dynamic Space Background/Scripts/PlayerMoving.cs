using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// This scripts controls the player's moving. PlayerMoving script is created for demonstration of the package abilities. 
/// 
/// Attention!! You can use this script, and also an attached sprite of a spaceship; but for your own goals you may need to set the player behavior by yourself.
/// </summary>

public enum ControlMode { rotation, linear}

public class PlayerMoving : MonoBehaviour {

    public ControlMode controlMode;
    public float maxSpeed;
    public float acceleration;
    public float rotationSpeed;

    [Tooltip("If you flag this field, the camera will follow the player")]
    public bool attachCamera;

    [Tooltip("If you flag this field, the camera will repeat the rotation of the player")]
    public bool rotateCameraWithPlayer;    
    Transform mainCamera;

    float speed;

    private void Start()
    {
        mainCamera = Camera.main.transform;
    }

    private void Update()
    {
        if (controlMode == ControlMode.rotation)
        {
            if (Input.GetKey(KeyCode.LeftArrow))
                transform.Rotate(Vector3.forward * rotationSpeed);
            else if (Input.GetKey(KeyCode.RightArrow))
                transform.Rotate(Vector3.forward * -rotationSpeed);

            if (Input.GetKey(KeyCode.UpArrow))
            {
                if (speed < maxSpeed)
                    speed += acceleration * Time.deltaTime;
            }
            else
            {
                if (speed > 0)
                    speed -= acceleration * 2 * Time.deltaTime;
                else
                    speed = 0;
            }
            transform.Translate(Vector3.up * speed);
            if (attachCamera)
            {
                Vector3 newPos = transform.position;
                newPos.z = mainCamera.position.z;
                mainCamera.position = newPos;

                if (rotateCameraWithPlayer)
                {
                    mainCamera.rotation = transform.rotation;
                }
            }
        }
        else if(controlMode == ControlMode.linear)
        {
            transform.Translate(new Vector3(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"), 0) * maxSpeed * Time.deltaTime);
        }
    }
}
