using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;
using TMPro;

public class LoginPanelHandler : MonoBehaviour
{
    AuthenticationManager authenticationManager;

    public GameObject signInPanel, verificationPhoneNumberPanel, verificationEmailPanel, loadingPanel;

    public GameObject signUpPasswordField;

    public Text loginTypeButtonText, signInUpButtonText;

    public InAppPopUp popUp;

    public EmailVerificationMenu emailVerificationMenu;

    #region EmailSignIn
    bool signIn;
    public TMP_InputField emailInputField;
    public TMP_InputField passwordInputField;
    public TMP_InputField passwordAgainInputField;
    public GameObject forgetPasswordButton;
    #endregion

    #region smsButtonVariables
    bool smsSignActive;
    public RectTransform smsButton;
    public Text smsButtonText;
    public RectTransform smsVerificationCodeInputField;
    public TMP_InputField phoneNumberInputField;
    public TMP_InputField countryCodeInputField;
    public TMP_InputField smsVerificationInputField;
    #endregion

    public string gizlilikSozUrl, kullanimSozUrl, IysUrl, aydinlatmaMetniUrl, eulaUrl;

    // Start is called before the first frame update
    void Start()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();

        //SetActivePanel(signInPanel);

        signUpPasswordField.SetActive(true);
        loginTypeButtonText.text = "Zaten hesabım var";
        signInUpButtonText.text = "Kayıt ol";
        signIn = false;

        smsVerificationCodeInputField.gameObject.SetActive(false);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void DeactivateAllPanel()
    {
        signInPanel.SetActive(false);
        verificationPhoneNumberPanel.SetActive(false);
        verificationEmailPanel.SetActive(false);
        loadingPanel.SetActive(false);
    }

    public void DeactivateSignInMenu()
    {
        gameObject.SetActive(false);
    }

    public void SetActivePanel(GameObject panel)
    {
        if (!gameObject.activeInHierarchy)
            gameObject.SetActive(true);

        DeactivateAllPanel();
        panel.SetActive(true);

        if (panel == verificationEmailPanel)
        {
            StartCoroutine(SendVerificationMail());
        }
    }

    IEnumerator SendVerificationMail()
    {
        yield return new WaitForEndOfFrame();
        authenticationManager.VerificateEmail();
    }

    public void OnSwitchLoginTypeButton()
    {
        if (!signIn)
        {
            signUpPasswordField.SetActive(false);
            loginTypeButtonText.text = "Hesap oluştur";
            signInUpButtonText.text = "Giriş yap";
            signIn = true;
        }
        else
        {
            signUpPasswordField.SetActive(true);
            loginTypeButtonText.text = "Zaten hesabım var";
            signInUpButtonText.text = "Kayıt ol";
            signIn = false;
        }
    }

    public void OnClickSmsButton()
    {
        if (!smsSignActive)
        {
            smsSignActive = true;

            smsVerificationCodeInputField.gameObject.SetActive(true);
            smsButtonText.text = "Giriş yap";

            smsButton.DOAnchorPos(new Vector2(smsButton.anchoredPosition.x + smsButton.sizeDelta.x / 2f + 5f, smsButton.anchoredPosition.y), 0.35f);
            smsVerificationCodeInputField.DOAnchorPos(new Vector2(smsVerificationCodeInputField.anchoredPosition.x - smsVerificationCodeInputField.sizeDelta.x / 2f - 5f, smsVerificationCodeInputField.anchoredPosition.y), 0.35f);

            smsButton.GetComponent<DelayButton>().delayActive = false;
            StartCoroutine(SetActiveSmsButtonDelay(true));
        }
        else
        {
            authenticationManager.SendVerificationCodeWithSms(countryCodeInputField.text, phoneNumberInputField.text);
            smsButton.GetComponent<DelayButton>().delayActive = true;
        }
    }

    IEnumerator SetActiveSmsButtonDelay(bool value)
    {
        yield return new WaitForEndOfFrame();
        smsButton.GetComponent<DelayButton>().delayActive = value;
    }

    public void OnClickSignInButton()
    {
        if (signIn)
        {
            authenticationManager.OnClickSignInWithEmailButton(emailInputField.text, passwordInputField.text);
        }
        else
        {
            if (passwordInputField.text == passwordAgainInputField.text)
                authenticationManager.OnClickSignUpWithEmailButton(emailInputField.text, passwordInputField.text, passwordAgainInputField.text);
            else
                Debug.Log("Şifreler eşleşmedi");
        }
    }

    public void OnClickVerificatePhoneNumberButton()
    {
        authenticationManager.OnSignInWithSms(smsVerificationInputField.text);
    }

    public void ActivateHelpButtons(float delay)
    {
        StartCoroutine(emailVerificationMenu.ActivateHelpButtonsDelay(delay));
    }

    public void OpenGizlilikSoz()
    {
        Application.OpenURL(gizlilikSozUrl);
    }

    public void OpenKullanimSoz()
    {
        Application.OpenURL(kullanimSozUrl);
    }

    public void OpenAydinlatmaMetni()
    {
        Application.OpenURL(aydinlatmaMetniUrl);
    }

    public void OpenIys()
    {
        Application.OpenURL(IysUrl);
    }

    public void OpenEula()
    {
        Application.OpenURL(eulaUrl);
    }

    [System.Serializable]
    public class EmailVerificationMenu
    {
        public GameObject ButtonSendEmailAgain;
        public GameObject ButtonTryOtherTypes;

        public IEnumerator ActivateHelpButtonsDelay(float delay)
        {
            yield return new WaitForSeconds(delay);
            ButtonSendEmailAgain.SetActive(true);
            ButtonTryOtherTypes.SetActive(true);
        }
    }
}
