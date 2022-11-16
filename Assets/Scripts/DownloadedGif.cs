using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class DownloadedGif
{
    public string loadPath;
    [HideInInspector] public List<GifTexture> gifTextures = new List<GifTexture>();
     public byte[] gifBytes;
    public float interval;
    public List<Color32[]> colors;

    public DownloadedGif(byte[] gifBytes, string loadPath, float interval, List<Color32[]> colors)
    {
        this.loadPath = loadPath;
        this.gifBytes = gifBytes;
        this.interval = interval;
        this.colors = colors;
    }
}
