using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[SerializeField]
public class PhotoSettings : ScriptableObject
{
    public List<LocalSprite> localSprites;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    [System.Serializable]
    public class LocalSprite
    {
        public Sprite sprite;

        public string GetId()
        {
            if (sprite != null)
                return sprite.name;
            else
                return "";
        }

        public LocalSprite(Sprite sprite)
        {
            this.sprite = sprite;
        }
    }
}
