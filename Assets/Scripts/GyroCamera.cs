using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GyroCamera : MonoBehaviour
{
    Gyroscope m_Gyro;

    private Transform pivot;
    private Transform backgroundPivot;
    public BackgroundMovingController backgroundMovingController;

    public float smoothness = 50f;

    [HideInInspector] public Vector3 firstPos;
    [HideInInspector] public Vector3 backgroundFirstPos;

    private bool isActive = false;

    public float debugMove;

    // Start is called before the first frame update
    void Start()
    {
        pivot = gameObject.transform;
        backgroundPivot = backgroundMovingController.transform;

        //Set up and enable the gyroscope (check your device has one)
        if (SystemInfo.supportsGyroscope)
        {
            m_Gyro = Input.gyro;
            m_Gyro.enabled = true;
        }

        firstPos = pivot.position;
        backgroundFirstPos = backgroundPivot.position;
    }

    // Update is called once per frame
    void Update()
    {
#if UNITY_EDITOR
        if (isActive)
        {
            if (debugMove > 0)
            {
                pivot.position = new Vector3(pivot.position.x - debugMove * smoothness,
                    pivot.position.y + debugMove * smoothness, firstPos.z);
            }
        }
#endif
    }

    private void FixedUpdate()
    {
        if (isActive)
        {
            if (SystemInfo.supportsGyroscope)
            {
                pivot.position = new Vector3(pivot.position.x - m_Gyro.rotationRateUnbiased.y * smoothness, 
                    pivot.position.y + m_Gyro.rotationRateUnbiased.x * smoothness, firstPos.z);
            }
        }
    }

    public void ResetPivotPos()
    {
        pivot.position = firstPos;
    }

    public void ResetBacgroundPivotPos()
    {
        backgroundPivot.position = backgroundFirstPos;
    }

    public void SetActiveGyro(bool value)
    {
        isActive = value;
        backgroundMovingController.enabled = value;

        /*
        if (value)
        {
        
        }
        else
        {
            backgroundPivot.position = new Vector3(backgroundFirstPos.x - 500, backgroundFirstPos.y, backgroundFirstPos.z);
        }*/

        backgroundPivot.position = backgroundFirstPos;
        ResetBacgroundPivotPos();
        ResetPivotPos();
    }

    public IEnumerator PauseBackgroundGyro(float duration)
    {
        SetActiveGyro(false);
        yield return new WaitForSeconds(duration);
        SetActiveGyro(true);
    }

    public void StartChessBoard()
    {
        FindObjectOfType<cgChessBoardScript>(true).gameObject.SetActive(true);
    }
}
