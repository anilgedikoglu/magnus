using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WheelStringListPicker : MonoBehaviour
{


    public event Action ValueChange;
    /// <summary>
    /// Fires an event when the value of the timepicker is changed.
    /// </summary>
    private void OnValueChange()
    {
        if (!updatingPicker)
        {
            //Debug.Log("Time changed to " + _time);
            if (ValueChange != null)
            {
                ValueChange();
            }
        }
    }

    public string[] values;

    /// <summary>
    /// The hour wheel.
    /// </summary>
    public InfiniWheel wheel;

    bool updatingPicker = false;

    private void Awake()
    {
        wheel.ValueChange += WheelChanged;

        wheel.Init(values);

        UpdateTime();
    }

    private void OnEnable()
    {
        StartCoroutine(EnableEndOfFrame());
    }

    IEnumerator EnableEndOfFrame()
    {
        yield return new WaitForEndOfFrame();
        UpdateTime();
    }

    /// <summary>
    /// Calls OnValueChanged when one of the wheels' value changes.
    /// </summary>
    /// <param name="arg1">Id of the new value</param>
    /// <param name="arg2">Text object of the new item</param>
    private void WheelChanged(int arg1, UnityEngine.UI.Text arg2)
    {
        if (!updatingPicker)
            UpdateTime();
    }

    /// <summary>
    /// Updates the time.
    /// </summary>
    private void UpdateTime()
    {
        OnValueChange();
    }
}
