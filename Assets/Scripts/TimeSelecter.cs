using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TimeSelecter : MonoBehaviour
{
    public Text[] hourTexts;
    public Text[] minuteTexts;

    [HideInInspector] public int hour;
    [HideInInspector] public int minute;

    public float hourButtonFastDuration;
    public float hourButtonDuration;
    float hourButtonTimer;
    float hourButtonFastTimer;
    bool hourButtonIncrease;
    bool hourButtonDecrease;

    public float minuteButtonFastDuration;
    public float minuteButtonDuration;
    float minuteButtonTimer;
    float minuteButtonFastTimer;
    bool minuteButtonIncrease;
    bool minuteButtonDecrease;

    void Start()
    {
        SetTexts(hourTexts, 0, new Vector2(0, 23));
        SetTexts(minuteTexts, 0, new Vector2(0, 59));
    }

    void Update()
    {
        if (hourButtonIncrease)
        {
            if (hourButtonTimer < 0)
            {
                if (hourButtonFastTimer < 0)
                {
                    IncreaseHourButton();
                    hourButtonFastTimer = hourButtonFastDuration;
                }
                else
                {
                    hourButtonFastTimer -= Time.deltaTime;
                }
            }
            else
            {
                hourButtonTimer -= Time.deltaTime;
            }
        }

        if (hourButtonDecrease)
        {
            if (hourButtonTimer < 0)
            {
                if (hourButtonFastTimer < 0)
                {
                    DecreaseHourButton();
                    hourButtonFastTimer = hourButtonFastDuration;
                }
                else
                {
                    hourButtonFastTimer -= Time.deltaTime;
                }
            }
            else
            {
                hourButtonTimer -= Time.deltaTime;
            }
        }

        if (!hourButtonDecrease && !hourButtonIncrease)
        {
            hourButtonTimer = hourButtonDuration;
            hourButtonFastTimer = -1;
        }

        if (minuteButtonIncrease)
        {
            if (minuteButtonTimer < 0)
            {
                if (minuteButtonFastTimer < 0)
                {
                    IncreaseMinuteButton();
                    minuteButtonFastTimer = minuteButtonFastDuration;
                }
                else
                {
                    minuteButtonFastTimer -= Time.deltaTime;
                }
            }
            else
            {
                minuteButtonTimer -= Time.deltaTime;
            }
        }

        if (minuteButtonDecrease)
        {
            if (minuteButtonTimer < 0)
            {
                if (minuteButtonFastTimer < 0)
                {
                    DecreaseMinuteButton();
                    minuteButtonFastTimer = minuteButtonFastDuration;
                }
                else
                {
                    minuteButtonFastTimer -= Time.deltaTime;
                }
            }
            else
            {
                minuteButtonTimer -= Time.deltaTime;
            }
        }

        if (!minuteButtonDecrease && !minuteButtonIncrease)
        {
            minuteButtonTimer = minuteButtonDuration;
            minuteButtonFastTimer = -1;
        }
    }

    void SetTexts(Text[] texts, int value, Vector2 range)
    {
        int[] hourValues = new int[]
        {
            value - 2,
            value - 1,
            value,
            value + 1,
            value + 2
        };

        for (int i = 0; i < 5; i++)
        {
            if (hourValues[i] < range.x)
            {
                hourValues[i] = hourValues[i] + (int)range.y + 1;
            }

            if (hourValues[i] > range.y)
            {
                hourValues[i] = (hourValues[i] - (int)range.y - 1);
            }

            if (hourValues[i].ToString().ToCharArray().Length < 2)
            {
                texts[i].text = "0" + (hourValues[i]).ToString();
            }
            else
            {
                texts[i].text = (hourValues[i]).ToString();
            }
        }
    }

    public void SetIncreaseHourButtonActivity(bool value)
    {
        hourButtonIncrease = value;
    }

    public void SetDecreaseHourButtonActivity(bool value)
    {
        hourButtonDecrease = value;
    }

    public void SetIncreaseMinuteButtonActivity(bool value)
    {
        minuteButtonIncrease = value;
    }

    public void SetDecreaseMinuteButtonActivity(bool value)
    {
        minuteButtonDecrease = value;
    }

    public void IncreaseHourButton()
    {
        Vector2 range = new Vector2(0, 23);

        hour += 1;

        if (hour > range.y)
        {
            hour = (int)range.x;
        }

        SetTexts(hourTexts, hour, range);
    }

    public void DecreaseHourButton()
    {
        Vector2 range = new Vector2(0, 23);

        hour -= 1;

        if (hour < range.x)
        {
            hour = (int)range.y;
        }

        SetTexts(hourTexts, hour, range);
    }

    public void IncreaseMinuteButton()
    {
        Vector2 range = new Vector2(0, 59);

        minute += 1;

        if (minute > range.y)
        {
            minute = (int)range.x;
        }

        SetTexts(minuteTexts, minute, range);
    }

    public void DecreaseMinuteButton()
    {
        Vector2 range = new Vector2(0, 59);

        minute -= 1;

        if (minute < range.x)
        {
            minute = (int)range.y;
        }

        SetTexts(minuteTexts, minute, range);
    }
}
