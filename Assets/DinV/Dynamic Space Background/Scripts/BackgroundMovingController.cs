using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// This script controls the background layers. Depending on the position of the camera, it shifts the texture considering the parallax scale. 
/// If the camera is static, one can apply the layers scrolling, by that creating the movement effect.
/// </summary>

public enum CameraMode { isMoving, isStatic}
    
/// Serializable class which contains information about a layer 
[System.Serializable]
public class BackgroundLayer
{
    [Tooltip("Layer name which will appear in the Inspector")]
    public string name;

    [Tooltip("prefab of the layer which will be controlled by this script")]
    public GameObject layerObject;      

    [Range(0.1f,100)]
    public float parallaxScale;         // Parallax scale ranging from 0.1 to 100. Change the range if needed
}

public class BackgroundMovingController : MonoBehaviour {

    [Tooltip("Layers upon which the parallax effect will be applied")]
    public BackgroundLayer[] backgroundLayers;          

    [Tooltip("If your camera is moving, apply 'is moving', and a background will follow the camera. If your camera is not moving, apply 'is static', and a background " +
        "will sweep over the camera")]
    public CameraMode cameraMode; 

    [Tooltip("Speed of background scrolling according to the two coordinates. Not active if camera mode 'is moving'")]
    public Vector2 scrollingSpeed;

    [Tooltip("Camera upon which the parallex effect will be applied")]
    public Transform usedCamera;

    Material[] materials; // Array of the layers' materials

    private void Start()
    {
        materials = new Material[backgroundLayers.Length];              // create a new array of the layers' materials
        for (int i =0; i<materials.Length; i++)
        {
            materials[i] = backgroundLayers[i].layerObject.GetComponent<MeshRenderer>().material;
        }
    }

    private void Update()
    {
        if (cameraMode == CameraMode.isMoving)                          //if the camera mode 'is moving' move the camera to the gameObject's position
        {
            Vector3 newPos = usedCamera.position;
            newPos.z = transform.position.z;
            transform.position = newPos;
        }
        for (int i = 0; i < materials.Length; i++)                      // for every material in the array
        {
            Vector2 materialOffset = materials[i].mainTextureOffset;    // take a materialOffset value and...
            if (cameraMode == CameraMode.isStatic)                      // if camera mode "is static" scroll the texture with scrollingSpeed considering the layer scale and parallax scale
            {
                materialOffset.x += scrollingSpeed.x * Time.deltaTime / backgroundLayers[i].layerObject.transform.localScale.x / backgroundLayers[i].parallaxScale;
                materialOffset.y += scrollingSpeed.y * Time.deltaTime / backgroundLayers[i].layerObject.transform.localScale.y / backgroundLayers[i].parallaxScale;
            }
            else                                                        // if camera mode "is moving" shift the layers's texture considering the camera offset
            {
                materialOffset.x = backgroundLayers[i].layerObject.transform.position.x / backgroundLayers[i].layerObject.transform.localScale.x / backgroundLayers[i].parallaxScale;
                materialOffset.y = backgroundLayers[i].layerObject.transform.position.y / backgroundLayers[i].layerObject.transform.localScale.y / backgroundLayers[i].parallaxScale;
            }
            materials[i].mainTextureOffset = materialOffset;            
        }
    }
}
