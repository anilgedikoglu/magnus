using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using System.Threading.Tasks;
using NatSuite.Devices;
using System.IO;
using Firebase.Storage;
using Firebase.Extensions;
using DG.Tweening;

public class ProfilePhotoCamera : MonoBehaviour
{

    #region --Inspector--
    [Header("Preview")]
    public RawImage rawImage;

    [Header("Buttons")]
    public GameObject captureButton;
    public Image flashIcon;
    public Image switchIcon;
    #endregion


    #region --Setup--

    MediaDeviceQuery query;
    Texture2D previewTexture;

    public CurrentPlayerData playerData;

    public WelcomeScreen welcomeScreen;

    #region effects
    public Image borderEffectImage;
    public Image focusEffectImage;
    #endregion

    void Start()
    {

    }
    #endregion

    private void Update()
    {
        //rawImage.gameObject.GetComponent<RectTransform>().sizeDelta = new Vector3(GameObject.Find("Canvas").GetComponent<RectTransform>().rect.width, GameObject.Find("Canvas").GetComponent<RectTransform>().rect.width * (16f / 9f));
    }

    #region --UI Handlers--
    public void CapturePhoto()
    {
        if (borderEffectImage != null)
        {
            borderEffectImage.color = new Color(borderEffectImage.color.r, borderEffectImage.color.g, borderEffectImage.color.b, 1f);
            borderEffectImage.DOFade(0, .25f);
        }

        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
        {
            RenderTexture rTex = new RenderTexture(previewTexture.width / 2, previewTexture.height / 2, 0);
            Graphics.Blit(previewTexture, rTex);
            RenderTexture currentActiveRT = RenderTexture.active;
            RenderTexture.active = rTex;
            // Create a new Texture2D and read the RenderTexture image into it
            Texture2D tex = new Texture2D(rTex.width, rTex.height);
            tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);
            tex.Apply();

            captureButton.SetActive(false);
            //buttons.gameObject.SetActive(true);
            RenderTexture.active = currentActiveRT;
            Sprite sprite = Sprite.Create(tex, new Rect(0, 0, rTex.width, rTex.height), Vector2.zero);
            welcomeScreen.capturedProfilePhoto = sprite;
            StartCoroutine(DisableDelay());
            query.current.StopRunning();
            tex.EncodeToPNG();
            welcomeScreen.UploadProfilePhoto(tex.EncodeToJPG(200));
        }
        else
        {
            RenderTexture defualtTexture = new RenderTexture(1, 1, 0);

            Texture2D tex = new Texture2D(defualtTexture.width, defualtTexture.height, TextureFormat.RGB24, false);
            RenderTexture.active = defualtTexture;

            tex.ReadPixels(new Rect(0, 0, defualtTexture.width, defualtTexture.height), 0, 0);
            tex.Apply();

            Sprite sprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), Vector2.zero);
            welcomeScreen.capturedProfilePhoto = sprite;

            captureButton.SetActive(false);
            StartCoroutine(DisableDelay());
            tex.EncodeToPNG();
            welcomeScreen.UploadProfilePhoto(tex.EncodeToJPG(200));
        }
    }

    IEnumerator DisableDelay()
    {
        yield return new WaitForEndOfFrame();
        gameObject.GetComponent<RectTransform>().parent.gameObject.SetActive(false);
        //welcomeScreen.SetProfilePhotoSpriteIEnumurator(0);
        welcomeScreen.ChangeProfilePhotoScreenActivity();
        welcomeScreen.SetProfilePhotoSize();
        welcomeScreen.loadingCircleEffect.SetActive(true);
    }

    public void EndOfRequest(string result)
    {
        captureButton.SetActive(true);

        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
        {
            query.current.StopRunning();
        }

        captureButton.SetActive(false);

    }

    public Sprite CreateSpriteFromCamera()
    {
        RenderTexture rTex = new RenderTexture(previewTexture.width / 2, previewTexture.height / 2, 0);
        Graphics.Blit(previewTexture, rTex);
        RenderTexture currentActiveRT = RenderTexture.active;
        RenderTexture.active = rTex;
        // Create a new Texture2D and read the RenderTexture image into it
        Texture2D tex = new Texture2D(rTex.width, rTex.height);
        tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);
        tex.Apply();
        captureButton.SetActive(false);
        captureButton.SetActive(true);
        RenderTexture.active = currentActiveRT;
        Sprite sprite = Sprite.Create(tex, new Rect(0, 0, rTex.width, rTex.height), Vector2.zero);

        return sprite;
    }

    public async void SwitchCamera()
    {
        // Check that there is another camera to switch to
        if (query.count < 2)
            return;
        // Stop current camera
        var device = query.current as CameraDevice;
        device.StopRunning();

        if (device.frontFacing)
        {
            for (int i = 0; i < query.count; i++)
            {
                CameraDevice cameraDevice = query[i] as CameraDevice;

                if (!cameraDevice.frontFacing)
                {
                    device = cameraDevice;
                    query.SetIndex(i);
                    break;
                }
            }
        }
        else
        {
            for (int i = 0; i < query.count; i++)
            {
                CameraDevice cameraDevice = query[i] as CameraDevice;

                if (cameraDevice.frontFacing)
                {
                    device = cameraDevice;
                    query.SetIndex(i);
                    break;
                }
            }
        }

        previewTexture = await device.StartRunning();
        // Display preview texture
        rawImage.texture = previewTexture;
    }

    public void FocusCamera(BaseEventData e)
    {
        // Check if focus is supported
        var device = query.current as CameraDevice;
        if (!device.focusPointSupported)
            return;
        // Get the touch position in viewport coordinates
        var eventData = e as PointerEventData;
        var transform = eventData.pointerPress.GetComponent<RectTransform>();
        if (!RectTransformUtility.ScreenPointToWorldPointInRectangle(
            transform,
            eventData.pressPosition,
            eventData.pressEventCamera,
            out var worldPoint
        ))
            return;
        var corners = new Vector3[4];
        transform.GetWorldCorners(corners);
        var point = worldPoint - corners[0];
        var size = new Vector2(corners[3].x, corners[1].y) - (Vector2)corners[0];
        // Focus camera at point
        device.focusPoint = (point.x / size.x, point.y / size.y);

        if (focusEffectImage != null)
        {
            RectTransform focusImageRect = focusEffectImage.GetComponent<RectTransform>();
            focusImageRect.localScale = new Vector3(1.5f, 1.5f, 1.5f);
            focusImageRect.DOScale(Vector3.one, .25f);

            focusEffectImage.color = new Color(focusEffectImage.color.r, focusEffectImage.color.g, focusEffectImage.color.b, 1f);
            focusEffectImage.DOFade(0, 1.25f);
        }
    }

    public void ToggleFlashMode()
    {
        // Check if flash is supported
        var device = query.current as CameraDevice;
        if (!device.flashSupported)
            return;
        // Toggle
        if (device.flashMode == FlashMode.On)
        {
            device.flashMode = FlashMode.Off;
            flashIcon.color = Color.gray;
        }
        else
        {
            device.flashMode = FlashMode.On;
            flashIcon.color = Color.white;
        }
    }
    #endregion


    #region --Operations--

    void OnDisable()
    {
        //query.current.StopRunning();
    }

    async void OnEnable()
    {
        borderEffectImage.color = new Color(borderEffectImage.color.r, borderEffectImage.color.g, borderEffectImage.color.b, 0f);

        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
        {
            captureButton.SetActive(false);
        }
        else
        {
            captureButton.SetActive(true);
            return;
        }
        //We are setting out background to black.
        rawImage.color = new Color(0, 0, 0);

        if (!await MediaDeviceQuery.RequestPermissions<CameraDevice>())
        {
            CloseCameraMenu("kamera izni yok");
            return;
        }

        // Create a device query for device cameras
        query = new MediaDeviceQuery(MediaDeviceCriteria.CameraDevice);
        var device = query.current as CameraDevice;

        if (!device.frontFacing)
        {
            for (int i =0; i<query.count; i++)
            {
                CameraDevice cameraDevice = query[i] as CameraDevice;

                if (cameraDevice.frontFacing)
                {
                    device = cameraDevice;
                    query.SetIndex(i);
                    break;
                }
            }
        }

        device.zoomRatio = device.zoomRange.min;
        device.photoResolution = new((int)(device.photoResolution.height / 2f), (int)(device.photoResolution.height / 2f));
        previewTexture = await device.StartRunning();

        captureButton.SetActive(true);

        //We are setting out background to white again.
        rawImage.color = new Color(1, 1, 1);
        rawImage.texture = previewTexture;

        // Set UI state
        switchIcon.color = query.count > 1 ? Color.white : Color.gray;
        flashIcon.color = device.flashSupported ? Color.white : Color.gray;
    }
    #endregion

    void CloseCameraMenu(string mod)
    {
        captureButton.SetActive(false);
        playerData.AddElementToChatVariableList("mod", mod);
    }

    public void FotografSec()
    {
#if UNITY_EDITOR
        string[] fileTypes = new string[] { "image/*", "video/*" };
#elif UNITY_ANDROID
        // Use MIMEs on Android
        string[] fileTypes = new string[] { "image/*", "video/*" };
#else
			// Use UTIs on iOS
			string[] fileTypes = new string[] { "public.image", "public.movie" };
#endif

        /*
        Debug.Log(NativeFilePicker.CanPickMultipleFiles());

        // Pick image(s) and/or video(s)
        NativeFilePicker.Permission permission = NativeFilePicker.PickFile((paths) =>
        {
            if (paths == null)
            {
                Debug.Log("Operation cancelled");
            }
            else
            {
                Debug.Log("Picked file: " + paths);

                welcomeScreen.filePath = paths;
                Debug.Log(welcomeScreen.filePath);
            }
        }, fileTypes);

        Debug.Log("Permission result: " + permission);*/

        NativeGallery.Permission permission = NativeGallery.GetImageFromGallery((path) =>
        {
            if (path == null)
            {
                Debug.Log("Operation cancelled");
            }
            else
            {
                Debug.Log("Picked file: " + path);

                welcomeScreen.filePath = path;
                Debug.Log(welcomeScreen.filePath);
            }
        });

        Debug.Log("Permission result: " + permission);
    }
}
