using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using System.Threading.Tasks;
using NatSuite.Devices;

public class MagnusCameraManager : MonoBehaviour
{

    #region --Inspector--
    [Header("Preview")]
    public RawImage rawImage;
    public AspectRatioFitter aspectFitter;

    [Header("Buttons")]
    public GameObject captureButton;
    public GameObject toggleFlashButton;
    public GameObject switchCameraButton;
    public GameObject loadingCircle;
    public Image flashIcon;
    public Image switchIcon;
    #endregion


    #region --Setup--

    MediaDeviceQuery query;
    Texture2D previewTexture;

    public ChatManager chatManager;

    public KahveFalManager kahveFalManager;

    public CurrentPlayerData playerData;

    public RenderTexture defualtTexture;

    public Image borderEffectImage;

    public Image faceRecognationLine;

    #endregion

    private void Update()
    {
        if (borderEffectImage.color.a > 0)
        {
            borderEffectImage.color = new Color(borderEffectImage.color.r, borderEffectImage.color.g, borderEffectImage.color.b, borderEffectImage.color.a - Time.deltaTime * 2f);
        }
    }

    #region --UI Handlers--
    public void CapturePhoto()
    {
        borderEffectImage.color = new Color(borderEffectImage.color.r, borderEffectImage.color.g, borderEffectImage.color.b, 1f);

        if (chatManager.cekilecekFotografSayisi > 0)
        {
            if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
            {
                chatManager.cekilecekFotografSayisi -= 1;

                RenderTexture rTex = new RenderTexture(previewTexture.width / 2, previewTexture.height / 2, 0);
                Graphics.Blit(previewTexture, rTex);
                RenderTexture currentActiveRT = RenderTexture.active;
                RenderTexture.active = rTex;
                // Create a new Texture2D and read the RenderTexture image into it
                Texture2D tex = new Texture2D(rTex.width, rTex.height);
                tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);
                tex.Apply();

                captureButton.SetActive(false);
                switchCameraButton.SetActive(false);
                toggleFlashButton.SetActive(false);
                loadingCircle.SetActive(true);

                if (playerData.GetChatVariableValue("mod") == "kahve falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "kahve";
                }
                else if (playerData.GetChatVariableValue("mod") == "online kahve falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "online kahve";
                }
                else if (playerData.GetChatVariableValue("mod") == "yüz falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "yuz";
                }
                else if (playerData.GetChatVariableValue("mod") == "el falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "el";
        
                }

                kahveFalManager.ProcessPhoto(tex);

                RenderTexture.active = currentActiveRT;
                Sprite sprite = Sprite.Create(tex, new Rect(0, 0, rTex.width, rTex.height), Vector2.zero);

                chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().contentImage.sprite = sprite;
                Image buttonImage = chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().button.GetComponent<Image>();
                buttonImage.color = new Color(buttonImage.color.r, buttonImage.color.g, buttonImage.color.b, 1f);

                TMPro.TMP_Text buttonText = chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().text;
                buttonText.color = new Color(buttonText.color.r, buttonText.color.g, buttonText.color.b, 1f);

                Image buttonContentImage = chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().contentImage;
                buttonContentImage.color = new Color(buttonContentImage.color.r, buttonContentImage.color.g, buttonContentImage.color.b, 1f);

                chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().ReCalculateContentImageSize();
            }
            else
            {
                Texture2D tex = new Texture2D(defualtTexture.width, defualtTexture.height, TextureFormat.RGB24, false);
                RenderTexture.active = defualtTexture;

                tex.ReadPixels(new Rect(0, 0, defualtTexture.width, defualtTexture.height), 0, 0);
                tex.Apply();

                Sprite sprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), Vector2.zero);

                chatManager.cekilecekFotografSayisi -= 1;
                chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().contentImage.sprite = Sprite.Create(tex, new Rect(0.0f, 0.0f, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100.0f);

                Image buttonImage = chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().button.GetComponent<Image>();
                buttonImage.color = new Color(buttonImage.color.r, buttonImage.color.g, buttonImage.color.b, 1f);

                TMPro.TMP_Text buttonText = chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().text;
                buttonText.color = new Color(buttonText.color.r, buttonText.color.g, buttonText.color.b, 1f);

                Image buttonContentImage = chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().contentImage;
                buttonContentImage.color = new Color(buttonContentImage.color.r, buttonContentImage.color.g, buttonContentImage.color.b, 1f);

                chatManager.answerBubbles[kahveFalManager.gerekenFotografSayisi - chatManager.cekilecekFotografSayisi - 1].GetComponent<AnswerBubble>().ReCalculateContentImageSize();

                captureButton.SetActive(false);
                switchCameraButton.SetActive(false);
                toggleFlashButton.SetActive(false);
                loadingCircle.SetActive(true);

                if (playerData.GetChatVariableValue("mod") == "kahve falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "kahve";
                }
                else if (playerData.GetChatVariableValue("mod") == "online kahve falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "online kahve";
                }
                else if (playerData.GetChatVariableValue("mod") == "yüz falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "yuz";
                }
                else if (playerData.GetChatVariableValue("mod") == "el falı fotoğraf yükle")
                {
                    kahveFalManager.mod = "el";
                }

                kahveFalManager.ProcessPhoto(tex);
            }
        }
    }

    public void EndOfRequest()
    {
        captureButton.SetActive(true);
        switchCameraButton.SetActive(true);
        toggleFlashButton.SetActive(true);
        loadingCircle.SetActive(false);

        if (chatManager.cekilecekFotografSayisi <= 0 && chatManager.sohbet.IsPhotographMode())
        {
            chatManager.SetCameraActivity(false);

            //chatManager.scrollOfftet = 0;

            captureButton.SetActive(false);
            switchCameraButton.SetActive(false);
            toggleFlashButton.SetActive(false);
            loadingCircle.SetActive(false);

            if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
            {
                query.current.StopRunning();
            }
        }
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
        switchCameraButton.SetActive(false);
        toggleFlashButton.SetActive(false);
        loadingCircle.SetActive(true);

        kahveFalManager.ProcessPhoto(tex);

        captureButton.SetActive(true);
        switchCameraButton.SetActive(true);
        toggleFlashButton.SetActive(true);
        loadingCircle.SetActive(false);
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
        aspectFitter.aspectRatio = (float)previewTexture.width / previewTexture.height;
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
            switchCameraButton.SetActive(false);
            toggleFlashButton.SetActive(false);
            loadingCircle.SetActive(true);
        }
        else
        {
            captureButton.SetActive(true);
            switchCameraButton.SetActive(false);
            toggleFlashButton.SetActive(false);
            loadingCircle.SetActive(false);
        }

        rawImage.texture = defualtTexture;

        if (!await MediaDeviceQuery.RequestPermissions<CameraDevice>())
        {
            CloseCameraMenu("kamera izni yok");
            return;
        }

        // Create a device query for device cameras
        query = new MediaDeviceQuery(MediaDeviceCriteria.CameraDevice);
        // Start camera preview
        var device = query.current as CameraDevice;

        if (playerData.GetChatVariableValue("mod") == "yüz falı fotoğraf yükle")
        {
            faceRecognationLine.gameObject.SetActive(true);

            if (!device.frontFacing)
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
        }
        else
        {
            faceRecognationLine.gameObject.SetActive(false);

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
        }

        device.zoomRatio = 1;
        device.photoResolution = new((int)(device.photoResolution.height / 2f), (int)(device.photoResolution.height / 2f));

        previewTexture = await device.StartRunning();

        captureButton.SetActive(true);
        switchCameraButton.SetActive(true);
        toggleFlashButton.SetActive(true);
        loadingCircle.SetActive(false);
        rawImage.texture = previewTexture;
        aspectFitter.aspectRatio = (float)previewTexture.width / previewTexture.height;

        // Display preview texture
        rawImage.texture = previewTexture;
        aspectFitter.aspectRatio = (float)previewTexture.width / previewTexture.height;
        // Set UI state
        switchIcon.color = query.count > 1 ? Color.white : Color.gray;
        flashIcon.color = device.flashSupported ? Color.white : Color.gray;
    }
    #endregion

    void CloseCameraMenu(string mod)
    {
        chatManager.SetCameraActivity(false);
        captureButton.SetActive(false);
        switchCameraButton.SetActive(false);
        toggleFlashButton.SetActive(false);
        loadingCircle.SetActive(true);
        playerData.AddElementToChatVariableList("mod", mod);
        //chatManager.scrollOfftet = 0;
        chatManager.cekilecekFotografSayisi = 0;

        chatManager.answerBubbles[chatManager.answerBubbles.Count - 1].GetComponent<AnswerBubble>().button.onClick.Invoke();
    }
}
