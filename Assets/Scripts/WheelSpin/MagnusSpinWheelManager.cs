using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MagnusSpinWheelManager : SpinWheelManager
{
    ChatManager chatManager;
    Animator animator;

    bool isDestroyed;

    public override void Start()
    {
        chatManager = FindObjectOfType<ChatManager>();
        animator = GetComponent<Animator>();
        base.Start();
        SetItems();
        AutoGenerateSpin();
    }

    void SetItems()
    {
        foreach (SpinWheelSettings.Wheel wheel in chatManager.spinWheelSettings.wheels)
        {
            if (chatManager.PlayerDataManager.GetChatVariableValue("wheel mod") == wheel.wheelName)
            {
                items = new List<SpinItem>();
                foreach (SpinItem element in wheel.items)
                {
                    items.Add(element);
                }

                spaceSize = wheel.spaceSize;
                generateItemsText = wheel.generateItemsText;
                itemsTextPosition = wheel.itemsTextPosition;
                itemsTextSize = wheel.itemsTextSize;
                itemsTextColor = wheel.itemsTextColor;
                itemsTextAlignment = wheel.itemsTextAlignment;
                itemsHasOutline = wheel.itemsHasOutline;
                itemsOutlineColor = wheel.itemsOutlineColor;
                generateItemsIcon = wheel.generateItemsIcon;
                itemsIconPosition = wheel.itemsIconPosition;
                itemsIconSize = wheel.itemsIconSize;
            }
        }
    }

    public override void OnFinishedSpin()
    {
        base.OnFinishedSpin();

        if (!reverseWheelRotation)
        {
            StartCoroutine(StartExit(1.25f, 1.25f, items[selectedItem].gidilecekMod.mod));
        }
        else
        {
            StartCoroutine(StartExit(1.25f, 1.25f, items[items.Count - 1 - selectedItem].gidilecekMod.mod));
        }
    }

    IEnumerator StartExit(float firstDelay, float secondDelay, string mod)
    {
        if (!chatManager.spinWheelSettings.IsSpinWheelMod(mod) || string.IsNullOrEmpty(mod))
        {
            isDestroyed = true;
            yield return new WaitForSeconds(firstDelay);
            animator.SetBool("exit", true);
            yield return new WaitForSeconds(secondDelay);

            if(!string.IsNullOrEmpty(mod))
            chatManager.ClickVirtualButton(mod);

            Destroy(gameObject);
            chatManager.spinWheelDragManager.gameObject.SetActive(false);
        }
        else
        {
            if (!string.IsNullOrEmpty(mod))
                chatManager.ClickVirtualButton(mod);
        }
    }

    public override void Update()
    {
        if (!chatManager.spinWheelSettings.IsSpinWheelMod(chatManager.PlayerDataManager.GetChatVariableValue("mod")) && !isDestroyed)
        {
            StartCoroutine(StartExit(0.25f, 1.25f, null));
        }

        base.Update();
    }

    public override void OnSpinButtonClick()
    {
        if (!IsWheelSpinning())
        {
            base.OnSpinButtonClick();
        }
    }

    private int GetCoins()
    {
        return PlayerPrefs.GetInt("coin", 1000);
    }

    private void AddCoin(int value)
    {
        int coins = GetCoins();
        PlayerPrefs.SetInt("coin", coins + value);
    }

    private bool UseCoin(int value)
    {
        int coins = GetCoins();
        if (coins >= value)
        {
            PlayerPrefs.SetInt("coin", GetCoins() - value);
            return true;
        }

        return false;
    }

    private int GetHearts()
    {
        return PlayerPrefs.GetInt("heart", 0);
    }

    private void AddHeart(int value)
    {
        int hearts = GetHearts();
        PlayerPrefs.SetInt("heart", hearts + value);
    }

    private IEnumerator AnimateCountText(Text text, int preValue, int nextValue)
    {
        bool increase = true;
        if (nextValue < preValue)
        {
            increase = false;
        }

        float value = nextValue - preValue;

        float t = (Mathf.Abs(value) / 5) * 0.4f;
        if (t > 2.0f) t = 2.0f;

        if (value != 0)
        {
            float step = value / (t / 0.06f);
            float pre = preValue;

            value = Mathf.Abs(value);

            while (value > 0)
            {
                value -= Mathf.Abs(step);
                pre += (step);
                if ((increase && pre > nextValue) || (!increase && pre < nextValue))
                {
                    pre = nextValue;
                }

                text.text = (int)pre + "";
                yield return new WaitForSecondsRealtime(0.02f);
            }

            text.text = nextValue + "";
        }
        else
        {
            text.text = nextValue + "";
        }

    }
}
