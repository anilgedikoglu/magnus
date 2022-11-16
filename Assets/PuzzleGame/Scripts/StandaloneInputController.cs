using UnityEngine;

public class StandaloneInputController : InputController
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.LeftArrow))
            OnLeft();

        if (Input.GetKeyDown(KeyCode.RightArrow))
            OnRight();

        if (Input.GetKeyDown(KeyCode.DownArrow))
            OnDown();
    }
}