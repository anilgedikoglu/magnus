using System;

[Serializable]
public class Label
{
    public LabelType labelType;
    public SpritesCollection collection;
}

public enum LabelType
{
    Text,
    Sprite
}