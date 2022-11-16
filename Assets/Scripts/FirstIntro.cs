using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FirstIntro : MonoBehaviour
{
    public AudioSource audioSource;

    bool ended;

    public GameObject introObject;

    public float timer;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (!ended)
        {
            if (audioSource.playOnAwake)
            {
                if (audioSource.time >= audioSource.clip.length)
                {
                    introObject.SetActive(true);
                    ended = true;
                    gameObject.SetActive(false);
                }
            }
            else
            {
                if (timer > 0) 
                {
                    timer -= Time.deltaTime;
                }
                else
                {
                    introObject.SetActive(true);
                    ended = true;
                    gameObject.SetActive(false);
                }
            }
        }   
    }
}
