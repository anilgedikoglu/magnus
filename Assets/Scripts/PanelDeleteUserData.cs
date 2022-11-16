using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class PanelDeleteUserData : MonoBehaviour
{
    public GameObject content;

    AuthenticationManager authenticationManager;

    public GameObject ButtonDeleteAccount;
    public GameObject buttonSignOutFolder;

    public RectTransform verticalLayoutGroupRect;

    // Start is called before the first frame update
    void Start()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OpenPanel()
    {
        content.SetActive(true);
        if ((System.DateTime.Now - authenticationManager.signInDate).TotalMinutes > 4.5f)
        {
            ButtonDeleteAccount.SetActive(false);
            buttonSignOutFolder.SetActive(true);
        }

        LayoutRebuilder.ForceRebuildLayoutImmediate(verticalLayoutGroupRect);
    }

    public void ClosePanel()
    {
        content.SetActive(false);
    }

    public void DeletePlayerDatas()
    {
        content.SetActive(false);
        SaveData.DeleteSaveFile();
        PlayerPrefs.DeleteAll();

        CurrentPlayerData playerData = FindObjectOfType<CurrentPlayerData>();
        playerData.LoadPlayerData();

        FindObjectOfType<RealtimeDatabaseManager>().SetData("Users/" + authenticationManager.auth.CurrentUser.UserId, JsonConvert.SerializeObject(playerData.datas),
           onSuccess: () =>
           {
               Debug.Log("Veritabanındaki kullanıcı verileri başarıyla sıfırlandı.");
           },
           
           onFailed: (string reason) =>
           {
               Debug.Log("Veritabanındaki kullanıcı verileri sıfırlanırken hata meydana geldi: " + reason);
           });
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }
}
