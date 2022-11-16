using Firebase.Extensions;
using Firebase.Storage;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEngine.Networking;

public class PhotoManager : MonoBehaviour
{
    public PhotoSettings photoSettings;

    FirebaseStorage storage;

    public List<DownloadedTextures> downloadedTextures;
    [Range(5, 100)]
    public int maxDownloadedPhotoCount;

    void Start()
    {
        storage = FirebaseStorage.DefaultInstance;
    }

    void Update()
    {
        
    }

    public string GetLocalSpriteId(Sprite sprite)
    {
        foreach (PhotoSettings.LocalSprite localSprite in photoSettings.localSprites)
        {
            if (sprite == localSprite.sprite)
            {
                return localSprite.GetId();
            }
        }
        return string.Empty;
    }

    public Sprite GetSprite(string id)
    {
        foreach(PhotoSettings.LocalSprite localSprite in photoSettings.localSprites)
        {
            if (id == localSprite.GetId())
            {
                return localSprite.sprite;
            }
        }

        return null;
    }

    public Sprite GetDownloadedSprite(string name)
    {
        foreach (DownloadedTextures texture in downloadedTextures)
        {
            if (name == texture.name)
            {
                return texture.sprite;
            }
        }

        return null;
    }

    public void AddTextureToDownloadedTexture(string name, Sprite sprite)
    {
        downloadedTextures.Add(new DownloadedTextures(name, sprite));

        while (downloadedTextures.Count > maxDownloadedPhotoCount)
        {
            downloadedTextures.RemoveAt(0);
        }
    }

    [System.Serializable]
    public class DownloadedTextures
    {
        public string name;
        public Sprite sprite;

        public DownloadedTextures(string name, Sprite sprite)
        {
            this.name = name;
            this.sprite = sprite;
        }
    }
}
