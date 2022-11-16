using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KutuPatlamaOyunuCikisButonu : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void UygualamayaDon()
    {
        UnityEngine.SceneManagement.SceneManager.LoadScene("MainScene");
    }
}
