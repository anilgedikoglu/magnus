using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LinkProviderPanel : MonoBehaviour
{
    public AuthenticationManager authenticationManager;

    public GameObject linkMenu, linkedMenu;

    public string provider;

    // Update is called once per frame
    void Update()
    {
        
    }

    public void StateUpdate()
    {
        if (authenticationManager.providers != null)
        {
            if (authenticationManager.providers.Contains(provider))
            {
                linkMenu.SetActive(false);
                linkedMenu.SetActive(true);
            }
            else
            {
                linkMenu.SetActive(true);
                linkedMenu.SetActive(false);
            }
        }
        else
        {
            linkMenu.SetActive(true);
            linkedMenu.SetActive(false);
        }
    }
}
