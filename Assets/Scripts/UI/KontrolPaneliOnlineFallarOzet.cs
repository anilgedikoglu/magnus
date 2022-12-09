using Firebase.Database;
using Firebase.Extensions;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;

public class KontrolPaneliOnlineFallarOzet : MonoBehaviour
{
    private List<KahveFalManager.OnlineFalData> onlineFalDatas;

    [SerializeField] private TMP_Text text;

    // Start is called before the first frame update
    void Start()
    {
    
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetActive(bool isActive)
    {
        if (isActive)
            DownloadReviews();

        gameObject.SetActive(isActive);
    }

    private void DownloadReviews()
    {
        FirebaseDatabase.DefaultInstance
        .GetReference("OnlineFallar")
        .GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsFaulted || task.IsCanceled)
            {
                Debug.LogError("Veriler al?n?rken hata meydana geldi");
                // Handle the error...
            }
            else if (task.IsCompleted)
            {
                onlineFalDatas = new();

                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                if (snapshotChilds.Count > 0)
                {
                    foreach (DataSnapshot userSnapshot in snapshotChilds)
                    {
                        List<DataSnapshot> fallar = userSnapshot.Children.ToList();
                        foreach (DataSnapshot fal in fallar)
                        {
                            Debug.Log(fal.GetRawJsonValue());
                            var falData = JsonConvert.DeserializeObject<KahveFalManager.OnlineFalData>(fal.GetRawJsonValue());
                            onlineFalDatas.Add(falData);
                        }
                    }
                }
                else
                {
                    Debug.Log(snapshot.Key + " Bir hata meydana geldi...");
                }

                UpdateUI();
            }
        });
    }

    public void UpdateUI()
    {
        text.text = string.Empty;

        foreach(var item in onlineFalDatas)
        {
            text.text += $"<color=white><b>{item.kullaniciAdi + " " + item.kullaniciSoyadi} | {item.type.ToString()}</b></color>" + "\n";
            text.text += item.fal + "\n\n";
        }
    }
}
