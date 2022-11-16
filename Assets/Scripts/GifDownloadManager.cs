using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GifDownloadManager : MonoBehaviour
{
    public List<DownloadedGif> downloadedGifs;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public class Color 
    {
        
    }


    public DownloadedGif FindGif(string loadPath)
    {
        DownloadedGif returnGIf = null;

        foreach (DownloadedGif gif in downloadedGifs)
        {
            if (gif.loadPath == loadPath)
            {
                returnGIf = gif;
            }
        }

        return returnGIf;
    }

    public void AddGif(string loadPath, DownloadedGif downloadedGif)
    {
        if (!downloadedGifs.Exists(x => x.loadPath.Equals(loadPath)))
        {
            downloadedGifs.Add(downloadedGif);
        }
    }
}
