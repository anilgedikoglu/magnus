using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetActiveWithPlatform : MonoBehaviour
{
    public List<RuntimePlatform> platforms;
    public bool value;

    // Start is called before the first frame update
    void Start()
    {
        for (int i = 0; i < platforms.Count; i++)
        {
            if (Application.platform == platforms[i])
            {
                gameObject.SetActive(value);
                break;
            }
            else if (i == platforms.Count - 1)
            {
                gameObject.SetActive(!value);
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
