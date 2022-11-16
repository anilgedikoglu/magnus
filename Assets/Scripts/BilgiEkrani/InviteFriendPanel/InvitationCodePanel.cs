using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Michsky.UI.ModernUIPack;
using TMPro;
using UnityEngine.UI;

public class InvitationCodePanel : MonoBehaviour
{
    AuthenticationManager authenticationManager;
    RealtimeDatabaseManager realtimeDatabaseManager;
    CurrentPlayerData currentPlayerData;

    public GameObject content;

    public Text keyText;

    public TMP_InputField keyInputField;

    public GameObject openInvitationPanelButton;

    public InAppPopUp inAppPopUp;

    // Start is called before the first frame update
    void Start()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        currentPlayerData = FindObjectOfType<CurrentPlayerData>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OpenPanel()
    {
        if (!currentPlayerData.datas.inviteKey.used)
        {
            keyText.text = currentPlayerData.datas.inviteKey.key;
            content.SetActive(true);
        }
    }

    public void CheckCode()
    {
        Debug.Log("button basildi");
        realtimeDatabaseManager.GetData("InviteKeys/" + keyInputField.text, (string value) => {

            if (value.ToLower() == "used")
            {
                Debug.LogError("Bu key daha önce kullanıldı");
                //reasonText.color = errorColor;
                //reasonText.text = "Bu kod daha önce kullanılmış gibi görünüyor. Lütfen kontrol edip tekrar dene";
                inAppPopUp.LogError("Bu kod daha önce kullanılmış gibi görünüyor. Lütfen kontrol edip tekrar dene");
            }
            else if (value.ToLower() == "null" || string.IsNullOrEmpty(value))
            {
                Debug.LogError("Key bulunamadı");
                //reasonText.color = errorColor;
                //reasonText.text = "Girdiğin kod bulunamadı. Lütfen kontrol edip tekrar dene.";
                inAppPopUp.LogError("Girdiğin kod bulunamadı. Lütfen kontrol edip tekrar dene.");
            }
            else if (value == authenticationManager.auth.CurrentUser.UserId)
            {
                Debug.LogError("Kullanıcı kendi kodunu girdi");
                //reasonText.color = errorColor;
                //reasonText.text = "Kendine ait olan kodu kullanamazsın. Eğer bu uygulamayı kullanan başka bir arkadaşın varsa onun kodunu kullanarak ikiniz için de ücretsiz plus üyelikten yararlanabilirsin.";
                inAppPopUp.LogWarning("Kendine ait olan kodu kullanamazsın. Eğer bu uygulamayı kullanan başka bir arkadaşın varsa onun kodunu kullanarak ikiniz için de ücretsiz plus üyelikten yararlanabilirsin.");
            }
            else if (currentPlayerData.datas.inviteKey.enteredKey)
            {
                Debug.LogError("Kullanıcı daha önce key girdi ve plus kazandı");
                //reasonText.color = errorColor;
                //reasonText.text = "Daha önce başka bir kullanıcının kodunu kullanarak plus kazanmış gibi görünüyorsun. Bu işlemi birden fazla yapamazsın. " +
                //"Eğer ücretsiz plus kazanmak istersen uygulamayı yeni indiren bir arkadaşından senin kodunu girmesini isteyebilrsin.";
                inAppPopUp.LogError("Daha önce başka bir kullanıcının kodunu kullanarak plus kazanmış gibi görünüyorsun. Bu işlemi birden fazla yapamazsın. " +
                "Eğer ücretsiz plus kazanmak istersen uygulamayı yeni indiren bir arkadaşından senin kodunu girmesini isteyebilrsin.");
            }
            else if (value.Length == authenticationManager.auth.CurrentUser.UserId.Length)
            {
                //SUCCESS!!!
                Debug.Log("<color=green><b>Kullanıcıya plus ataması yapıldı!</b></color>");
                //reasonText.color = successColor;
                //reasonText.text = "Tebrikler! 1 hafta ücretsiz plus üyelik hesabınıza tanımlandı. 1 haftalık süre sonunda üyeliğiniz sona erecek ve herhangi bir ücretlendirme yapılmayacak.";
                realtimeDatabaseManager.SetData("InviteKeys/" + keyInputField.text, (object)"used", () => { Debug.Log("basarili"); }, (string reason) => { Debug.Log("basarili"); });
                currentPlayerData.datas.inviteKey.enteredKey = true;

                inAppPopUp.LogSuccess("İşlem Başarılı");
            }
            else
            {
                inAppPopUp.LogError("Beklenmeye hata meydana geldi!");
                //reasonText.color = errorColor;
                //reasonText.text = "Kusura bakma şuan sistemsel bazı sorunlar yaşıyorum. Lütfen daha sonra tekrar dene.";
            }
        });
    }
}
