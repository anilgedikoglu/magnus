using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetActiveWithPlus : MonoBehaviour
{
    CurrentPlayerData currentPlayerData;

    public bool isActive;

    // Start is called before the first frame update
    void Start()
    {
  
    }

    public void Check()
    {
        if (currentPlayerData == null)
            currentPlayerData = FindObjectOfType<CurrentPlayerData>();

        if (currentPlayerData.GetChatVariableValue("plus") == "var")
        {
            gameObject.SetActive(isActive);
        }
        else
        {
            gameObject.SetActive(!isActive);
        }
    }
}
