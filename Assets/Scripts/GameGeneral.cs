using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class GameGeneral
{
    public static Vector3 MoveRecttransform(Vector3 pos, RectTransform canvasRt, Vector2 offset) 
    {
        pos = new Vector3(pos.x + offset.x * canvasRt.localScale.x, pos.y + offset.y * canvasRt.localScale.y, pos.z);

        return pos;
    }
}
