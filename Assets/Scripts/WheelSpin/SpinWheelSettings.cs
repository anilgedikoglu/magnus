using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpinWheelSettings : ScriptableObject
{
    public string modWheel;
    public string modYavas;

    public List<Wheel> wheels;


    public bool IsSpinWheelMod(string mod)
    {
        if (mod == modWheel || mod == modYavas)
        {
            return true;
        }
        else
        {
            foreach (Wheel wheel in wheels)
            {
                foreach (SpinWheelManager.SpinItem item in wheel.items)
                {
                    if (item.gidilecekMod.mod == mod && item.gidilecekMod.wheeldaKal)
                    {
                        return true;
                    }
                }
            }

            return false;
        }
    }

    [System.Serializable]
    public class Wheel
    {
        public string wheelName = "";
        public float spaceSize = 5f;
        public bool generateItemsText = true;
        public float itemsTextPosition = 110;
        public Color itemsTextColor = Color.white;
        public int itemsTextSize = 25;
        public TextAnchor itemsTextAlignment = TextAnchor.MiddleCenter;
        public bool itemsHasOutline = true;
        public Color itemsOutlineColor = Color.black;
        public bool generateItemsIcon = true;
        public float itemsIconPosition = 210;
        public float itemsIconSize = 40;

        public List<SpinWheelManager.SpinItem> items;

        public Wheel()
        {
            wheelName = "";
            spaceSize = 5f;
            generateItemsText = true;
            itemsTextPosition = 110;
            itemsTextColor = Color.white;
            itemsTextSize = 25;
            itemsHasOutline = true;
            itemsOutlineColor = Color.black;
            generateItemsIcon = true;
            itemsIconPosition = 210;
            itemsIconSize = 40;

            items = new List<SpinWheelManager.SpinItem>();
        }
    }
}
