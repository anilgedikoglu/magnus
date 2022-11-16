using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Firebase.Auth;
using Firebase.Extensions;
using Google;
using TMPro;
using UnityEngine.UI;
using System.Threading.Tasks;
using Facebook;
using Facebook.Unity;
using AppleAuth;
using AppleAuth.Enums;
using AppleAuth.Extensions;
using AppleAuth.Interfaces;
using AppleAuth.Native;
using System;
using System.Security.Cryptography;
using System.Text;
using System.Linq;
using UnityEngine.SceneManagement;
using Michsky.UI.ModernUIPack;
using Firebase.Database;

public class AuthenticationManager : MonoBehaviour
{
    public FirebaseAuth auth;
    public FirebaseUser user;
    public Firebase.FirebaseApp app;

    #region SignInWithEmail
    public TMP_InputField signInEmailInputField, signInPasswordInputField;
    #endregion
    #region SignUpWithEmail
    public TMP_InputField signUpEmailInputField, signUpPasswordInputField, signUpPasswordAgainInputField;
    #endregion

    #region SignInWithEmail
    public TMP_InputField phoneNumberInputField, smsCodedInputField;
    #endregion

    public IntroManager introManager;

    public string webClientId = "<Android client id>";
    private GoogleSignInConfiguration configuration;

    private IAppleAuthManager _appleAuthManager;

    string appleNonce;

    [HideInInspector]
    public IAppleIDCredential appleCredential;

    string id;

    public string smsVerificationId;

    public Text debugText;

    public LoginPanelHandler loginPanelHandler;

    bool checkEmailStatusOnFocus;

    [HideInInspector] public DateTime lastVerificationEmailSentDate;

    public List<string> providers;
    public LinkProviderPanel[] linkPanels;

    public NotificationManager bilgilerEksikNotif;

    public BilgiEkraniSettings bilgiEkraniSettings;

    public DateTime signInDate;

    private bool userSignedIn;

    void Awake()
    {
        signInDate = DateTime.Now.AddMinutes(-30);

        configuration = new GoogleSignInConfiguration
        {
            WebClientId = webClientId,
            RequestIdToken = true
        };

        //Initiliaze Facebook Authentication
        if (!FB.IsInitialized)
        {
            FB.Init(() =>
            {
                if (FB.IsInitialized)
                {
                    FB.ActivateApp();
                    debugText.text += "\n" + "Facebook SDK baslatildi";
                }
                else
                {
                    debugText.text += "\n" + "Facebook SDK baslatilamadi";
                    Debug.LogError("Facebook SDK baslatilamadi");
                }
            });
        }
        else
        {
            debugText.text += "\n" + "Facebook SDK baslatildi";
            FB.ActivateApp();
        }

        Debug.Log(Application.persistentDataPath);
    }

    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(InitializeFirebaseDelay());
    }

    IEnumerator InitializeFirebaseDelay()
    {
        yield return new WaitForEndOfFrame();
        InitializeFirebase();
    }

    // Update is called once per frame
    void Update()
    {
        // Updates the AppleAuthManager instance to execute
        // pending callbacks inside Unity's execution loop
        if (this._appleAuthManager != null)
        {
            this._appleAuthManager.Update();
        }
    }

    void OnDestroy()
    {
        auth.StateChanged -= AuthStateChanged;
        auth = null;
    }

    private void OnApplicationFocus(bool focus)
    {
        if (focus && checkEmailStatusOnFocus)
        {
            CheckEmailVerification();
        }
    }

    public void InitializeFirebase()
    {
        //introManager.gameObject.SetActive(false);

#if UNITY_EDITOR
        FirebaseDatabase.DefaultInstance.SetPersistenceEnabled(false);
#endif

        Debug.Log("Setting up Firebase Auth");
        auth = Firebase.Auth.FirebaseAuth.DefaultInstance;
        app = Firebase.FirebaseApp.DefaultInstance;
        auth.StateChanged += AuthStateChanged;
        AuthStateChanged(this, null);
        FindObjectOfType<RealtimeDatabaseManager>().reference = FirebaseDatabase.DefaultInstance.RootReference;
        FindObjectOfType<RealtimeDatabaseManager>().PostTimeStampToDatebase();

        //introManager.gameObject.SetActive(true);

        //StartCoroutine(introManager.Initialize());

        //Initiliaze Apple sign in
        // If the current platform is supported
        if (AppleAuthManager.IsCurrentPlatformSupported)
        {
            // Creates a default JSON deserializer, to transform JSON Native responses to C# instances
            var deserializer = new PayloadDeserializer();
            // Creates an Apple Authentication manager with the deserializer
            this._appleAuthManager = new AppleAuthManager(deserializer);
        }

        //Firebase.Auth.Credential credential =
    //Firebase.Auth.EmailAuthProvider.GetCredential(email, password);
    }

    void AuthStateChanged(object sender, System.EventArgs eventArgs)
    {
        if (auth.CurrentUser != user)
        {
            bool signedIn = user != auth.CurrentUser && auth.CurrentUser != null;
            if (!signedIn && user != null)
            {
                userSignedIn = false;
                Debug.Log("Signed out " + user.UserId);
            }
            user = auth.CurrentUser;
            if (signedIn)
            {
                userSignedIn = true;
                StartCoroutine(introManager.Initialize());
                Debug.Log("Signed in " + user.UserId);
                GetAllEmails();
            }
        }

        if(!userSignedIn)
        StartCoroutine(introManager.Initialize());
    }

    public void OnClickSignInWithEmailButton(string email, string password)
    {
        auth.SignInWithEmailAndPasswordAsync(email, password).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled)
            {
                loginPanelHandler.popUp.LogError("Girdiğin bilgilere uygun kullanıcı bulunamadı. Lütfen " +
                    "bilgilerini kontrol edip tekrar dene.");
                Debug.LogError("SignInWithEmailAndPasswordAsync was canceled.");
                loginPanelHandler.forgetPasswordButton.SetActive(true);
                return;
            }
            if (task.IsFaulted)
            {
                loginPanelHandler.popUp.LogError("Girdiğin bilgilere uygun kullanıcı bulunamadı. Lütfen " +
                    "bilgilerini kontrol edip tekrar dene.");
                Debug.LogError("SignInWithEmailAndPasswordAsync encountered an error: " + task.Exception);
                loginPanelHandler.forgetPasswordButton.SetActive(true);
                return;
            }

            Firebase.Auth.FirebaseUser newUser = task.Result;
            Debug.LogFormat("User signed in successfully: {0} ({1})",
                newUser.DisplayName, newUser.UserId);

            signInDate = DateTime.Now;
            /*
            if (auth.CurrentUser.IsEmailVerified)
                StartCoroutine(introManager.Initialize());
            else
            {
                loginPanelHandler.SetActivePanel(loginPanelHandler.verificationEmailPanel);
            }*/
        });
    }

    public void OnClickSignUpWithEmailButton(string email, string password, string passwordAgain)
    {
        if (password == passwordAgain)
        {
            auth.CreateUserWithEmailAndPasswordAsync(email, password).ContinueWithOnMainThread(task =>
            {
                if (task.IsCanceled)
                {
                    Debug.LogError("CreateUserWithEmailAndPasswordAsync was canceled.");
                    return;
                }
                if (task.IsFaulted)
                {
                    Debug.LogError("CreateUserWithEmailAndPasswordAsync encountered an error: " + task.Exception);
                    return;
                }

                // Firebase user has been created.
                Firebase.Auth.FirebaseUser newUser = task.Result;
                Debug.LogFormat("Firebase user created successfully: {0} ({1})",
                    newUser.DisplayName, newUser.UserId);

                signInDate = DateTime.Now;
                /*
                if (auth.CurrentUser.IsEmailVerified)
                    StartCoroutine(introManager.Initialize());
                else
                {
                    loginPanelHandler.SetActivePanel(loginPanelHandler.verificationEmailPanel);
                }*/
            });
        }
        else
        {
            Debug.LogError("Şifreler eşleşmedi");
        }
    }

    public void VerificateEmail()
    {
        if ((DateTime.Now - lastVerificationEmailSentDate).TotalSeconds > 30)
        {
            checkEmailStatusOnFocus = true;
            Firebase.Auth.FirebaseUser user = auth.CurrentUser;
            if (user != null)
            {
                user.SendEmailVerificationAsync().ContinueWith(task =>
                {
                    if (task.IsCanceled)
                    {
                        Debug.LogError("SendEmailVerificationAsync was canceled.");
                        return;
                    }
                    if (task.IsFaulted)
                    {
                        Debug.LogError("SendEmailVerificationAsync encountered an error: " + task.Exception);
                        OnClickSignOutButton();
                        return;
                    }

                    lastVerificationEmailSentDate = DateTime.Now;
                    Debug.Log("Email sent successfully.");
                });
            }
        }
        else
        {
            Debug.Log("Son email gonderiminin üzerinden 30 saniye geçmediği için email gönderilemedi. Birdahaki gönderime kalan süre: " + (DateTime.Now - lastVerificationEmailSentDate).TotalSeconds);
        }

    }

    public void CheckEmailVerification()
    {
        checkEmailStatusOnFocus = false;

        auth.CurrentUser.ReloadAsync().ContinueWithOnMainThread(task =>
        {
            if (auth.CurrentUser.IsEmailVerified)
            {
                StartCoroutine(introManager.Initialize());
            }
            else
            {
                Debug.Log("Email dogrulanmadi");
            }
        });
    }

    public void OnClickResetPasswordButton()
    {
        string emailAddress = loginPanelHandler.emailInputField.text;
        auth.SendPasswordResetEmailAsync(emailAddress).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled)
            {
                loginPanelHandler.popUp.LogError("E-posta gönderilirken bir hata meydana geldi");
                Debug.LogError("SendPasswordResetEmailAsync was canceled.");
                return;
            }
            if (task.IsFaulted)
            {
                loginPanelHandler.popUp.LogError("E-posta gönderilirken bir hata meydana geldi");
                Debug.LogError("SendPasswordResetEmailAsync encountered an error: " + task.Exception);
                return;
            }

            loginPanelHandler.popUp.LogSuccess("E-posta adresinize şifre sıfırlama bağlantısı gönderildi." +
                " Bu bağlantıyı kullanarak şifrenizi sıfırlayabilirsiniz.");
            Debug.Log("Password reset email sent successfully.");
        });
    }

    public void SendVerificationCodeWithSmsForLink(string countryCode, string phoneNumber, GameObject closeMenu, GameObject openMenu)
    {
        List<char> phoneNumberChar = phoneNumber.ToList();

        if (phoneNumberChar[0] == '0')
        {
            phoneNumberChar.RemoveAt(0);
        }

        countryCode = (string.IsNullOrEmpty(countryCode)) ? "+90" : countryCode;

        if (phoneNumberChar.Count == 10)
        {
            PhoneAuthProvider provider = PhoneAuthProvider.GetInstance(auth);
            provider.VerifyPhoneNumber(countryCode + phoneNumber, 15 * 1000, null,
              verificationCompleted: (credential) =>
              {
                  // Auto-sms-retrieval or instant validation has succeeded (Android only).
                  // There is no need to input the verification code.
                  // `credential` can be used instead of calling GetCredential().
                  Debug.Log("Kod başarıyla doğrulandı");
                  DebugLogMobile("Kod başarıyla doğrulandı");
                  OnLinkWithSmsAuto(credential);
              },
              verificationFailed: (error) =>
              {
                  // The verification code was not sent.
                  // `error` contains a human readable explanation of the problem.
                  Debug.Log("Sms doğrulamasında hata meydana geldi." + error);
                  DebugLogMobile("Sms doğrulamasında hata meydana geldi." + error);
              },
              codeSent: (id, token) =>
              {
                  // Verification code was successfully sent via SMS.
                  // `id` contains the verification id that will need to passed in with
                  // the code from the user when calling GetCredential().
                  // `token` can be used if the user requests the code be sent again, to
                  // tie the two requests together.
                  Debug.Log("Sms kodu başarıyla gönderildi: " + id);
                  DebugLogMobile("Sms kodu başarıyla gönderildi: " + id);

                  smsVerificationId = id;
                  openMenu.SetActive(true);
                  closeMenu.SetActive(false);
              },
              codeAutoRetrievalTimeOut: (id) =>
              {
                  // Called when the auto-sms-retrieval has timed out, based on the given
                  // timeout parameter.
                  // `id` contains the verification id of the request that timed out.
                  Debug.Log("Sms kodu zaman aşımına uğradı");
                  DebugLogMobile("Sms kodu zaman aşımına uğradı");
              });
        }
    }

    public void OnLinkWithSms(string verificationCode)
    {
        PhoneAuthProvider provider = PhoneAuthProvider.GetInstance(auth);

        Credential credential =
    provider.GetCredential(smsVerificationId, verificationCode);

        user.LinkWithCredentialAsync(credential).ContinueWithOnMainThread(task => {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                GetAllEmails();
            }
            else
            {
                bilgilerEksikNotif.title = bilgiEkraniSettings.hesapBaglamaUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.hesapBaglamaUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        });
    }

    public void OnLinkWithSmsAuto(Credential credential)
    {
        user.LinkWithCredentialAsync(credential).ContinueWithOnMainThread(task => {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                GetAllEmails();
            }
            else
            {
                bilgilerEksikNotif.title = bilgiEkraniSettings.hesapBaglamaUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.hesapBaglamaUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        });
    }

    public void SendVerificationCodeWithSms(string countryCode, string phoneNumber)
    {
        List<char> phoneNumberChar = phoneNumber.ToList();

        if (phoneNumberChar[0] == '0')
        {
            phoneNumberChar.RemoveAt(0);
        }

        countryCode = (string.IsNullOrEmpty(countryCode)) ? "+90" : countryCode;

        if (phoneNumberChar.Count == 10)
        {
            PhoneAuthProvider provider = PhoneAuthProvider.GetInstance(auth);
            provider.VerifyPhoneNumber(countryCode + phoneNumber, 15 * 1000, null,
              verificationCompleted: (credential) =>
              {
              // Auto-sms-retrieval or instant validation has succeeded (Android only).
              // There is no need to input the verification code.
              // `credential` can be used instead of calling GetCredential().
              Debug.Log("Kod başarıyla doğrulandı");
                  DebugLogMobile("Kod başarıyla doğrulandı");
                  SmsCodeVerified();
              },
              verificationFailed: (error) =>
              {
              // The verification code was not sent.
              // `error` contains a human readable explanation of the problem.
              Debug.Log("Sms doğrulamasında hata meydana geldi." + error);
                  DebugLogMobile("Sms doğrulamasında hata meydana geldi." + error);
              },
              codeSent: (id, token) =>
              {
              // Verification code was successfully sent via SMS.
              // `id` contains the verification id that will need to passed in with
              // the code from the user when calling GetCredential().
              // `token` can be used if the user requests the code be sent again, to
              // tie the two requests together.
              Debug.Log("Sms kodu başarıyla gönderildi: " + id);
                  DebugLogMobile("Sms kodu başarıyla gönderildi: " + id);

                  smsVerificationId = id;
                  loginPanelHandler.SetActivePanel(loginPanelHandler.verificationPhoneNumberPanel);
              },
              codeAutoRetrievalTimeOut: (id) =>
              {
              // Called when the auto-sms-retrieval has timed out, based on the given
              // timeout parameter.
              // `id` contains the verification id of the request that timed out.
              Debug.Log("Sms kodu zaman aşımına uğradı");
                  DebugLogMobile("Sms kodu zaman aşımına uğradı");
              });
        }
    }

    public void OnSignInWithSms(string verificationCode)
    {
        PhoneAuthProvider provider = PhoneAuthProvider.GetInstance(auth);
        
        Credential credential =
    provider.GetCredential(smsVerificationId, verificationCode);

        auth.SignInWithCredentialAsync(credential).ContinueWithOnMainThread(task => {
            if (task.IsFaulted)
            {
                Debug.LogError("SignInWithCredentialAsync encountered an error: " +
                               task.Exception);
                return;
            }

            FirebaseUser newUser = task.Result;
            Debug.Log("User signed in successfully");
            // This should display the phone number.
            Debug.Log("Phone number: " + newUser.PhoneNumber);
            // The phone number providerID is 'phone'.
            Debug.Log("Phone provider ID: " + newUser.ProviderId);

            signInDate = DateTime.Now;

            // StartCoroutine(introManager.Initialize());
        });
    }

    private void SmsCodeVerified()
    {
        StartCoroutine(introManager.Initialize());
    }

    private void SignWithFacebook(string accessToken)
    {
        debugText.text += "\n" + "Facebook firebase istegi baslatildi";
        Firebase.Auth.Credential credential =
    Firebase.Auth.FacebookAuthProvider.GetCredential(accessToken);
        auth.SignInWithCredentialAsync(credential).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled)
            {
                Debug.LogError("SignInWithCredentialAsync was canceled.");
                debugText.text += "\n" + "SignInWithCredentialAsync was canceled.";
                return;
            }
            if (task.IsFaulted)
            {
                Debug.LogError("SignInWithCredentialAsync encountered an error: " + task.Exception);
                debugText.text += "\n" + "SignInWithCredentialAsync encountered an error: " + task.Exception;
                return;
            }

            Firebase.Auth.FirebaseUser newUser = task.Result;
            Debug.LogFormat("User signed in successfully: {0} ({1})",
                newUser.DisplayName, newUser.UserId);
            debugText.text += "\n" + "User signed in successfully: {0} ({1})" + newUser.DisplayName + " " + newUser.UserId;

            signInDate = DateTime.Now;

            //StartCoroutine(introManager.Initialize());
        });
    }

    private void LinkWithFacebook(string accessToken)
    {
        debugText.text += "\n" + "Facebook firebase istegi baslatildi";
        Firebase.Auth.Credential credential =
    Firebase.Auth.FacebookAuthProvider.GetCredential(accessToken);
        user.LinkWithCredentialAsync(credential).ContinueWithOnMainThread(task => {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                GetAllEmails();
            }
            else
            {
                bilgilerEksikNotif.title = bilgiEkraniSettings.hesapBaglamaUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.hesapBaglamaUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        });
    }

    public void OnSignInWithFacebookButton()
    {
        FacebookLogin();
    }

    public void OnLinkWithFacebookButton()
    {
        FacebookLink();
    }

    void LinkGoogle(string googleIdToken, string googleAccessToken)
    {
        Firebase.Auth.Credential credential =
Firebase.Auth.GoogleAuthProvider.GetCredential(googleIdToken, googleAccessToken);
        user.LinkWithCredentialAsync(credential).ContinueWithOnMainThread(task => {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                GetAllEmails();
            }
            else
            {
                bilgilerEksikNotif.title = bilgiEkraniSettings.hesapBaglamaUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.hesapBaglamaUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        });
    }

    void SignInWithGoogle(string googleIdToken, string googleAccessToken)
    {
        Firebase.Auth.Credential credential =
Firebase.Auth.GoogleAuthProvider.GetCredential(googleIdToken, googleAccessToken);
        auth.SignInWithCredentialAsync(credential).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled)
            {
                Debug.LogError("SignInWithCredentialAsync was canceled.");
                return;
            }
            if (task.IsFaulted)
            {
                Debug.LogError("SignInWithCredentialAsync encountered an error: " + task.Exception);
                return;
            }

            Firebase.Auth.FirebaseUser newUser = task.Result;
            Debug.LogFormat("User signed in successfully: {0} ({1})",
                newUser.DisplayName, newUser.UserId);

            signInDate = DateTime.Now;

            //StartCoroutine(introManager.Initialize());
        });
    }

    public void OnSignInWithGoogleButton()
    {
        OnSignIn();
    }

    public void OnLinkWithGoogleButton()
    {
        OpenGoogleLinkPopUp();
    }

    public void OnClickSignOutButton()
    {
        auth.SignOut();

        if (GoogleSignIn.Configuration != null)
            OnSignOut();
        if (FB.IsLoggedIn)
        {
            FB.LogOut();
            Debug.Log("SignOut from Facebook is succesful");
        }

        SaveData.DeleteSaveFile();
        FindObjectOfType<CurrentPlayerData>().LoadPlayerData();
        FindObjectOfType<CurrentPlayerData>().onlineDataChecked = false;
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }

    #region FacebookSign
    private void FacebookLogin()
    {
        debugText.text += "\n" + "Facebook Login istegi gonderildi";
        var permissions = new List<string>() { "public_profile", "email" };
        FB.LogInWithReadPermissions(permissions, FacebookAuthCallback);
    }

    private void FacebookAuthCallback(ILoginResult result)
    {
        if (FB.IsLoggedIn)
        {
            // AccessToken class will have session details
            var aToken = Facebook.Unity.AccessToken.CurrentAccessToken;
            // Print current access token's User ID
            Debug.Log(aToken.UserId);
            // Print current access token's granted permissions
            foreach (string perm in aToken.Permissions)
            {
                Debug.Log(perm);
                debugText.text += "\n" + perm;
            }
            SignWithFacebook(aToken.TokenString);
            debugText.text += "\n" + "Facebook Giris basarili";
        }
        else
        {
            debugText.text += "\n" + "Facebook Giris basarisiz";
            debugText.text += "\n" + result.Error;
            Debug.Log("User cancelled login");
        }
    }

    private void FacebookLink()
    {
        debugText.text += "\n" + "Facebook Login istegi gonderildi";
        var permissions = new List<string>() { "public_profile", "email" };
        FB.LogInWithReadPermissions(permissions, FacebookLinkCallback);
    }

    private void FacebookLinkCallback(ILoginResult result)
    {
        if (FB.IsLoggedIn)
        {
            // AccessToken class will have session details
            var aToken = Facebook.Unity.AccessToken.CurrentAccessToken;
            // Print current access token's User ID
            Debug.Log(aToken.UserId);
            // Print current access token's granted permissions
            foreach (string perm in aToken.Permissions)
            {
                Debug.Log(perm);
                debugText.text += "\n" + perm;
            }
            LinkWithFacebook(aToken.TokenString);
            debugText.text += "\n" + "Facebook Giris basarili";
        }
        else
        {
            debugText.text += "\n" + "Facebook Giris basarisiz";
            debugText.text += "\n" + result.Error;
            Debug.Log("User cancelled login");
        }
    }

    public void LogOutFacebook()
    {
        debugText.text += "\n" + "Facebook cikis basarilir";
        FB.LogOut();
    }


    #endregion

    #region AppleSign
    private void GetAppleIdForLink()
    {
        var rawNonce = GenerateRandomString(32);
        var nonce = GenerateSHA256NonceFromRawNonce(rawNonce);

        var loginArgs = new AppleAuthLoginArgs(LoginOptions.IncludeEmail | LoginOptions.IncludeFullName, nonce);

        this._appleAuthManager.LoginWithAppleId(
            loginArgs,
            credential =>
            {
                // If a sign in with apple succeeds, we should have obtained the credential with the user id, name, and email, save it
                appleNonce = loginArgs.Nonce;
                appleCredential = credential as IAppleIDCredential;
                Debug.Log("Signed with apple. The id is:");
                Debug.Log(appleCredential.User);
                LinkWithAppleId(rawNonce);
            },
            error =>
            {
                var authorizationErrorCode = error.GetAuthorizationErrorCode();
                Debug.LogError("Sign in with Apple failed " + authorizationErrorCode.ToString() + " " + error.ToString());
                DebugLogMobile("Sign in with Apple failed " + authorizationErrorCode.ToString() + " " + error.ToString());
            });
    }


    private void GetAppleId()
    {
        var rawNonce = GenerateRandomString(32);
        var nonce = GenerateSHA256NonceFromRawNonce(rawNonce);

        var loginArgs = new AppleAuthLoginArgs(LoginOptions.IncludeEmail | LoginOptions.IncludeFullName, nonce);

        this._appleAuthManager.LoginWithAppleId(
            loginArgs,
            credential =>
            {
                // If a sign in with apple succeeds, we should have obtained the credential with the user id, name, and email, save it
                appleNonce = loginArgs.Nonce;
                appleCredential = credential as IAppleIDCredential;
                Debug.Log("Signed with apple. The id is:");
                Debug.Log(appleCredential.User);
                SignInWithAppleId(rawNonce);
            },
            error =>
            {
                var authorizationErrorCode = error.GetAuthorizationErrorCode();
                Debug.LogError("Sign in with Apple failed " + authorizationErrorCode.ToString() + " " + error.ToString());
                DebugLogMobile("Sign in with Apple failed " + authorizationErrorCode.ToString() + " " + error.ToString());
            });
    }

    public void LinkWithAppleId(string rawNonce)
    {
        DebugLogMobile("Firebase isteği baslatildi");
        Firebase.Auth.Credential credential =
            Firebase.Auth.OAuthProvider.GetCredential("apple.com", Encoding.UTF8.GetString(appleCredential.IdentityToken), rawNonce, null);
        user.LinkWithCredentialAsync(credential).ContinueWithOnMainThread(task => {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                GetAllEmails();
            }
            else
            {
                bilgilerEksikNotif.title = bilgiEkraniSettings.hesapBaglamaUyari.title;
                bilgilerEksikNotif.description = bilgiEkraniSettings.hesapBaglamaUyari.description;
                bilgilerEksikNotif.UpdateUI();
                bilgilerEksikNotif.OpenNotification();
            }
        });
    }

    public void UnlinkProvider(string provider)
    {
        if (providers.Count > 1)
        {
            auth.CurrentUser.ReloadAsync().ContinueWithOnMainThread(reloadTask =>
            {

                if (!reloadTask.IsCanceled && !reloadTask.IsFaulted)
                {
                    auth.CurrentUser.UnlinkAsync(provider).ContinueWithOnMainThread(task =>
                    {
                        if (!task.IsCanceled && !task.IsFaulted)
                            GetAllEmails();
                        else
                        {
                            Debug.Log(task.Exception);

                            foreach (IUserInfo userInfo in auth.CurrentUser.ProviderData)
                            {

                                string providerId = userInfo.ProviderId;
                                Debug.Log(providerId);

                            }
                        }
                    });
                }
                else
                {
                    Debug.Log(reloadTask.Exception);
                }
            });
        }
        else
        {
            Debug.LogError("Tek bir provider bulunduğu için provide kaldırılamıyor.");
        }
    }

    public void SignInWithAppleId(string rawNonce)
    {
        DebugLogMobile("Firebase isteği baslatildi");
        Firebase.Auth.Credential credential =
            Firebase.Auth.OAuthProvider.GetCredential("apple.com", Encoding.UTF8.GetString(appleCredential.IdentityToken), rawNonce, null);
        auth.SignInWithCredentialAsync(credential).ContinueWith(task =>
        {
            if (task.IsCanceled)
            {
                DebugLogMobile("Firebase basarili");
                Debug.LogError("SignInWithCredentialAsync was canceled.");
                return;
            }
            if (task.IsFaulted)
            {
                DebugLogMobile("Firebase basarisiz");
                Debug.LogError("SignInWithCredentialAsync encountered an error: " + task.Exception);
                return;
            }

            Firebase.Auth.FirebaseUser newUser = task.Result;
            Debug.LogFormat("User signed in successfully: {0} ({1})",
                newUser.DisplayName, newUser.UserId);

            signInDate = DateTime.Now;
        });
    }

    public void GetAllEmails()
    {
        providers = new List<string>();

        auth.CurrentUser.ReloadAsync().ContinueWithOnMainThread(reloadTask => {

            if (!reloadTask.IsCanceled && !reloadTask.IsFaulted)
            {
                if (!string.IsNullOrEmpty(auth.CurrentUser.Email))
                {
                    auth.FetchProvidersForEmailAsync(auth.CurrentUser.Email).ContinueWithOnMainThread((fetchTask) =>
                    {
                        if (fetchTask.IsCanceled)
                        {
                            //onCheckEmailComplete.SafeInvoke(false, false);
                        }
                        else if (fetchTask.IsFaulted)
                        {
                            //onCheckEmailComplete.SafeInvoke(false, false);
                        }
                        else if (fetchTask.IsCompleted)
                        {
                            //Crashlytics.Log("CheckUserEmailExist Task Completed");

                            bool isUserExist = false;

                            if (fetchTask.Result != null)
                            {
                                foreach (string provider in fetchTask.Result)
                                {
                                    Debug.Log(provider);
                                    providers.Add(provider);
                                    isUserExist = true;
                                }
                            }
                            //onCheckEmailComplete.SafeInvoke(true, isUserExist);
                        }

                        foreach (LinkProviderPanel linkProviderPanel in linkPanels)
                        {
                            linkProviderPanel.StateUpdate();
                        }
                    });
                }

                if (!string.IsNullOrEmpty(auth.CurrentUser.PhoneNumber))
                {
                    providers.Add("phone");
                }
            }
            else
            {
                Debug.Log(reloadTask.Exception);
            }
        });


    }

    private static string GenerateSHA256NonceFromRawNonce(string rawNonce)
    {
        var sha = new SHA256Managed();
        var utf8RawNonce = Encoding.UTF8.GetBytes(rawNonce);
        var hash = sha.ComputeHash(utf8RawNonce);

        var result = string.Empty;
        for (var i = 0; i < hash.Length; i++)
        {
            result += hash[i].ToString("x2");
        }

        return result;
    }

    private static string GenerateRandomString(int length)
    {
        if (length <= 0)
        {
            throw new Exception("Expected nonce to have positive length");
        }

        const string charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._";
        var cryptographicallySecureRandomNumberGenerator = new RNGCryptoServiceProvider();
        var result = string.Empty;
        var remainingLength = length;

        var randomNumberHolder = new byte[1];
        while (remainingLength > 0)
        {
            var randomNumbers = new List<int>(16);
            for (var randomNumberCount = 0; randomNumberCount < 16; randomNumberCount++)
            {
                cryptographicallySecureRandomNumberGenerator.GetBytes(randomNumberHolder);
                randomNumbers.Add(randomNumberHolder[0]);
            }

            for (var randomNumberIndex = 0; randomNumberIndex < randomNumbers.Count; randomNumberIndex++)
            {
                if (remainingLength == 0)
                {
                    break;
                }

                var randomNumber = randomNumbers[randomNumberIndex];
                if (randomNumber < charset.Length)
                {
                    result += charset[randomNumber];
                    remainingLength--;
                }
            }
        }

        return result;
    }

    public void OnAppleSignIn()
    {
        GetAppleId();
    }

    public void OnAppleLinkButton()
    {
        GetAppleIdForLink();
    }

    public void DeleteAccountButton()
    {
        auth.CurrentUser.DeleteAsync().ContinueWithOnMainThread(task => {
            if (task.IsCanceled || task.IsFaulted)
            {
                Debug.Log("Hesap silme sırasında hata meydana geldi");
                Debug.Log(task.Exception);
            }
            else
            {
                SceneManager.LoadScene(SceneManager.GetActiveScene().name);
                Debug.Log("Hesap başarıyla silindi");
            }
        });
    }

    #endregion

    #region GoogleSignInTokeneFunctions

    void OpenGoogleLinkPopUp()
    {
        GoogleSignIn.Configuration = configuration;
        GoogleSignIn.Configuration.UseGameSignIn = false;
        GoogleSignIn.Configuration.RequestIdToken = true;
        Debug.Log("Calling SignIn");

        GoogleSignIn.DefaultInstance.SignIn().ContinueWith(
          OnSignInForLinkFinished);
    }

    internal void OnSignInForLinkFinished(Task<GoogleSignInUser> task)
    {
        if (task.IsFaulted)
        {
            using (IEnumerator<System.Exception> enumerator =
                    task.Exception.InnerExceptions.GetEnumerator())
            {
                if (enumerator.MoveNext())
                {
                    GoogleSignIn.SignInException error =
                            (GoogleSignIn.SignInException)enumerator.Current;
                    Debug.Log("Got Error: " + error.Status + " " + error.Message);
                }
                else
                {
                    Debug.Log("Got Unexpected Exception?!?" + task.Exception);
                }
            }
        }
        else if (task.IsCanceled)
        {
            Debug.Log("Canceled");
        }
        else
        {
            id = task.Result.IdToken;
            Debug.Log("Welcome: " + task.Result.DisplayName + "!");
            LinkGoogle(task.Result.IdToken, null);
        }
    }

    public void OnSignIn()
    {
        GoogleSignIn.Configuration = configuration;
        GoogleSignIn.Configuration.UseGameSignIn = false;
        GoogleSignIn.Configuration.RequestIdToken = true;
        Debug.Log("Calling SignIn");

        GoogleSignIn.DefaultInstance.SignIn().ContinueWith(
          OnAuthenticationFinished);
    }

    public void OnSignOut()
    {
        Debug.Log("Calling SignOut");
 
        GoogleSignIn.DefaultInstance.SignOut();
    }

    public void OnDisconnect()
    {
        Debug.Log("Calling Disconnect");
        GoogleSignIn.DefaultInstance.Disconnect();
    }

    internal void OnAuthenticationFinished(Task<GoogleSignInUser> task)
    {
        if (task.IsFaulted)
        {
            using (IEnumerator<System.Exception> enumerator =
                    task.Exception.InnerExceptions.GetEnumerator())
            {
                if (enumerator.MoveNext())
                {
                    GoogleSignIn.SignInException error =
                            (GoogleSignIn.SignInException)enumerator.Current;
                    Debug.Log("Got Error: " + error.Status + " " + error.Message);
                }
                else
                {
                    Debug.Log("Got Unexpected Exception?!?" + task.Exception);
                }
            }
        }
        else if (task.IsCanceled)
        {
            Debug.Log("Canceled");
        }
        else
        {
            id = task.Result.IdToken;
            Debug.Log("Welcome: " + task.Result.DisplayName + "!");
            SignInWithGoogle(task.Result.IdToken, task.Result.Email);
        }
    }

    public void OnSignInSilently()
    {
        GoogleSignIn.Configuration = configuration;
        GoogleSignIn.Configuration.UseGameSignIn = false;
        GoogleSignIn.Configuration.RequestIdToken = true;
        Debug.Log("Calling SignIn Silently");

        GoogleSignIn.DefaultInstance.SignInSilently()
              .ContinueWith(OnAuthenticationFinished);
    }


    public void OnGamesSignIn()
    {
        GoogleSignIn.Configuration = configuration;
        GoogleSignIn.Configuration.UseGameSignIn = true;
        GoogleSignIn.Configuration.RequestIdToken = false;

        Debug.Log("Calling Games SignIn");

        GoogleSignIn.DefaultInstance.SignIn().ContinueWith(
          OnAuthenticationFinished);
    }
    #endregion

    void DebugLogMobile(string text)
    {
        debugText.text += "\n" + text;
    }
}
