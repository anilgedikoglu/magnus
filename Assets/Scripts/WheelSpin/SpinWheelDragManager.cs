using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpinWheelDragManager : MonoBehaviour
{
    Vector2 firsMousePos;
    Vector3 firstWheelRot;

    List<float> lastRotateAmounts;

    public Transform wheelTransform;
    public MagnusSpinWheelManager magnusSpinWheelManager;

    RectTransform mainCanvasRt;

    ChatManager chatManager;

    int direction = 1;

    // Start is called before the first frame update
    void Start()
    {
        chatManager = FindObjectOfType<ChatManager>();
        mainCanvasRt = GameObject.FindGameObjectWithTag("main canvas").GetComponent<RectTransform>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void BeginDrag()
    {
        if (!magnusSpinWheelManager.IsWheelSpinning())
        {
            firsMousePos = Input.mousePosition;
            firstWheelRot = wheelTransform.eulerAngles;

            lastRotateAmounts = new List<float>();
        }
    }

    public void OnDrag()
    {
        if (!magnusSpinWheelManager.IsWheelSpinning())
        {
            Vector2 speenDirection = new Vector2(1, 1);
            Vector3 wheelScreenPoint = Camera.main.WorldToScreenPoint(wheelTransform.position);

            if (wheelScreenPoint.y > Input.mousePosition.y)
            {
                speenDirection = new Vector2(1, speenDirection.y);
            }
            else
            {
                speenDirection = new Vector2(-1, speenDirection.y);
            }

            if (wheelScreenPoint.x < Input.mousePosition.x)
            {
                speenDirection = new Vector2(speenDirection.x, 1);
            }
            else
            {
                speenDirection = new Vector2(speenDirection.x, -1);
            }

            float rotateAmaount = ((Input.mousePosition.x - firsMousePos.x) * speenDirection.x + (Input.mousePosition.y - firsMousePos.y) * speenDirection.y) / mainCanvasRt.localScale.y;
            wheelTransform.Rotate(new Vector3(0, 0, rotateAmaount));
            firsMousePos = Input.mousePosition;

            if (rotateAmaount > 0)
            {
                direction = 1;
            }
            else
            {
                direction = -1;
            }

            if (lastRotateAmounts.Count < 5)
            {
                lastRotateAmounts.Add(Mathf.Abs(rotateAmaount));
            }
            else
            {
                lastRotateAmounts.RemoveAt(0);
                lastRotateAmounts.Add(Mathf.Abs(rotateAmaount));
            }
        }
    }

    public void EndDrag()
    {
        if (!magnusSpinWheelManager.IsWheelSpinning())
        {
            float avarageRotateAmount = 0;

            foreach (float amount in lastRotateAmounts)
            {
                avarageRotateAmount += amount;
            }
            avarageRotateAmount /= lastRotateAmounts.Count;

            if (avarageRotateAmount * (Time.deltaTime * 5f) < 0.1f)
            {
                Debug.Log("olmadi" + avarageRotateAmount * (Time.deltaTime * 5f));

                chatManager.ClickVirtualButton(chatManager.spinWheelSettings.modYavas);
            }
            else
            {
                Debug.Log("oldu" + avarageRotateAmount * (Time.deltaTime * 5f));

                if (direction == 1)
                {
                    magnusSpinWheelManager.reverseHandleRotation = true;
                    magnusSpinWheelManager.reverseWheelRotation = true;
                }
                else
                {
                    magnusSpinWheelManager.reverseHandleRotation = false;
                    magnusSpinWheelManager.reverseWheelRotation = false;
                }
                magnusSpinWheelManager.OnSpinButtonClick();
            }

            lastRotateAmounts = new List<float>();
        }
    }
}
