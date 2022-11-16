using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SplashScreen : MonoBehaviour
{
    public float timer;

    public GameObject welcomeScreen;

    public IntroManager introManager;

    void Start()
    {
        InvokeRepeating("IntroControl", .1f, .1f);
    }

    void Update()
    {
   
    }

    public void IntroControl()
    {
        if (introManager.introDone)
        {
            welcomeScreen.SetActive(true);
            gameObject.SetActive(false);
            CancelInvoke("IntroControl");
        }
        else
        {
            welcomeScreen.SetActive(false);
        }
    }
}
