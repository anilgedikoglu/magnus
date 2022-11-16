using Firebase.Database;
using Firebase.Extensions;
using Newtonsoft.Json;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class KontrolPaneliManager : MonoBehaviour
{
    private RealtimeDatabaseManager realtimeDatabaseManager;

    public TMP_InputField energyInputField, konsInputField, plusInputField, passwordInputField;
    public Toggle forMyself;
    public TMP_Text userInformation;

    public GameObject signInPanel;
    public GameObject userBlockedPanel;

    public PlayerData playerData;
    public bool isUserActive;
    public string userID = string.Empty;
    public int energy = 0;
    public int kons = 0;
    public int plusDays = 0;

    public Debug debug;

    public TMP_Text reviewPage;

    public GameObject onlineFalMevcutIcon;

    public ModUsageStat modUsageStat;

    private void Awake()
    {
        realtimeDatabaseManager = FindObjectOfType<RealtimeDatabaseManager>();
        signInPanel.SetActive(true);
        userBlockedPanel.SetActive(false);
    }

    // Start is called before the first frame update
    void Start()
    {
        debug.Initiliaze();
    }

    // Update is called once per frame
    void Update()
    {
        if (debug.timer > 0)
        {
            debug.timer -= Time.deltaTime;

            if (debug.timer <= 0)
            {
                debug.ClosePanel();
            }
        }
    }

    public void OnValueChange(string text)
    {
        int.TryParse(energyInputField.text, out energy);
        int.TryParse(konsInputField.text, out kons);
        int.TryParse(plusInputField.text, out plusDays);

        UpdateUserInformations();
    }

    public void OnUserIDChange(string id)
    {
        userID = id;
        playerData = null;
        isUserActive = false;
    }

    public void GetUserData()
    {
        if (!isUserActive)
        {
            if (!forMyself.isOn)
            {
                realtimeDatabaseManager.GetData("Users/" + userID, (string data) =>
                {
                    try
                    {
                        playerData = JsonConvert.DeserializeObject<PlayerData>(data);

                        if (playerData != null)
                        {
                            debug.Log("Kullanici bilgilerine başarıyle erişildi");
                            isUserActive = true;
                        }
                        else
                            debug.LogError("Kullanici bilgileri bulunamadi. Lütfen girmiş olduğunuz bilgileri kontrol edip tekrar deneyin.");
                    }
                    catch
                    {
                        debug.LogError("Kullanici bilgileri bulunamadi veya bir hata meydana geldi");

                    }

                    UpdateUserInformations();
                }, (string reason) =>
                {
                    debug.LogError("Girilen kullanıcı ID'si hatalı veya bu hesabın yetkisi yok.");
                });
            }
            else
            {
                playerData = FindObjectOfType<CurrentPlayerData>().datas;
                isUserActive = true;
            }
        }
        else
        {
            playerData.energy += energy;
            playerData.konsantrasyon += kons;
            if (plusDays != 0)
                playerData.plusExpireDateFromSystem = new PlayerData.Date(System.DateTime.Now.AddDays(plusDays));

            if (!forMyself.isOn)
            {
                string data = JsonConvert.SerializeObject(playerData);
                realtimeDatabaseManager.SetData("Users/" + userID, data, () => { }, (string reason) =>
                {
                    debug.Log("Kullanıcıları bilgileri veritabanına aktarılırken hata meydana geldi :" + reason);
                });
            }
            else
            {
                FindObjectOfType<CurrentPlayerData>().datas = playerData;
            }
        }
        UpdateUserInformations();
    }

    public void OnMyselfToggleChange(bool value)
    {
        if (value)
        {
            GetUserData();
        }
        else
        {
            playerData = null;
            isUserActive = false;
        }
    }

    public void UpdateUserInformations()
    {
        if (playerData != null)
        {
            string isim = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("isim")))
                isim = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("isim")).degiskenDegeri;

            string soyisim = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("soyisim")))
                soyisim = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("soyisim")).degiskenDegeri;

            string dogumGunu = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum gunu")))
                dogumGunu = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("dogum gunu")).degiskenDegeri;

            string dogumAyi = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum ayi")))
                dogumAyi = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("dogum ayi")).degiskenDegeri;

            string dogumYili = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum yili")))
                dogumYili = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("dogum yili")).degiskenDegeri;

            string dogumSaati = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum saati")))
                dogumSaati= playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("dogum saati")).degiskenDegeri;

            string dogumDakikasi = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum dakikasi")))
                dogumDakikasi = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("dogum dakikasi")).degiskenDegeri;

            string dogumSehri = string.Empty;
            if (playerData.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals("dogum sehri")))
                dogumSehri = playerData.chatDegiskenleri.Find(x => x.degiskenAdi.Equals("dogum sehri")).degiskenDegeri;

            int energy = playerData.energy;
            int kons = playerData.konsantrasyon;
            DateTime expireDateFromSystem = Magnus.Time.DateTimeOperations.ToDateTime(playerData.plusExpireDateFromSystem);

            DateTime firstOpeningDate = Magnus.Time.DateTimeOperations.ToDateTime(playerData.tanismaTarihi);
            DateTime lastOpenDate = Magnus.Time.DateTimeOperations.ToDateTime(playerData.lastActiveDay);

            userInformation.text = string.Empty;
            userInformation.text += "İsim: " + isim + " | Soyisim: " + soyisim + "\n";
            userInformation.text += "Doğum Tarihi: " + dogumGunu + "." + dogumAyi + "." + dogumYili + " " + dogumSaati + "." + dogumDakikasi + "\n";
            userInformation.text += "Doğum Şehri: " + dogumSehri +"\n";
            userInformation.text += "Tanışma Tarihi: " + firstOpeningDate.Day + "." + firstOpeningDate.Month + "." + firstOpeningDate.Year +"\n";
            userInformation.text += "Son Aktif Tarih: " + lastOpenDate.Day + "." + lastOpenDate.Month + "." + lastOpenDate.Year + "\n";
            userInformation.text += "Enerji: " + energy + $" <color={((this.energy >= 0) ? "green" : "red")}><b>({((this.energy >= 0) ? ("+" + this.energy) : this.energy)})</b></color>" + "\n";
            userInformation.text += "Konsantrsayon: " + kons + $" <color={((this.kons >= 0) ? "green" : "red")}><b>({((this.kons >= 0) ? ("+" + this.kons) : this.kons)})</b></color>" + "\n";
            userInformation.text += "Plus: " + (((expireDateFromSystem - DateTime.Now).TotalDays <= 0) ? "Yok" : ((int)(expireDateFromSystem - DateTime.Now).TotalDays) + " gün kaldı ("
                + expireDateFromSystem.Day + "." + expireDateFromSystem.Month + "." + expireDateFromSystem.Year + ")" + "\n");
            userInformation.text += $" <color={((this.plusDays >= 0) ? "green" : "red")}><b>({((this.plusDays >= 0) ? ("+" + this.plusDays) : this.plusDays)})</b></color>" + "\n";
        }
    }

    public void OnClickSignInButton()
    {
        if (!string.IsNullOrEmpty(passwordInputField.text))
        {
            CurrentPlayerData currentPlayerData = FindObjectOfType<CurrentPlayerData>();
            if (currentPlayerData.datas.isAdmin)
            {
                if (passwordInputField.text == currentPlayerData.datas.adminPassword)
                {
                    signInPanel.SetActive(false);
                }
                else
                {
                    signInPanel.SetActive(false);
                    userBlockedPanel.SetActive(true);

                    FindObjectOfType<BilgiEkraniManager>().kontrolPaneliButonu.SetActive(false);
                    currentPlayerData.datas.isAdmin = false;
                }
            }
        }
    }

    public void DownloadReviewList(int days)
    {
        reviewPage.text = string.Empty;
        days = Mathf.Clamp(days, 0, 30);

        for (int i = 0; i < days; i++)
        {
            DateTime date = DateTime.Now.AddDays(-i);
            FirebaseDatabase.DefaultInstance
            .GetReference("SohbetIncelemeleri/TariheGore/" + $"{date.Day}-{date.Month}-{date.Year}/")
            .GetValueAsync().ContinueWithOnMainThread(task =>
            {
                if (task.IsFaulted || task.IsCanceled)
                {
                    UnityEngine.Debug.LogError("Veriler alınırken hata meydana geldi");
                    // Handle the error...
                }
                else if (task.IsCompleted)
                {
                    DataSnapshot snapshot = task.Result;
                    List<DataSnapshot> snapshotChilds = snapshot.Children.ToList();

                    if (snapshotChilds.Count > 0)
                    {
                        for (int i = 0; i < snapshotChilds.Count; i++)
                        {
                            var data = JsonConvert.DeserializeObject<InAppReview.SohbetInceleme>(snapshotChilds[i].GetRawJsonValue());

                            if (!string.IsNullOrEmpty(data.inceleme))
                            {
                                reviewPage.text += "<b>" + data.userName + "</b> | " + data.yildiz + "yildiz" + "\n";
                                reviewPage.text += data.inceleme + "\n\n";
                            }
                        }
                    }
                    else
                    {
                        UnityEngine.Debug.Log(snapshot.Key + " tarihi için uygun inceleme bulunamadı");
                    }
                }
            });
        }
    }

    public void DownloadStats(int days)
    {
        reviewPage.text = string.Empty;
        var downloadedModStats = new List<DownloadedModStat>();
        days = Mathf.Clamp(days, 0, 30);

        for (int i = 0; i < days; i++)
        {
            DateTime date = DateTime.Now.AddDays(-i);
            FirebaseDatabase.DefaultInstance.GetReference("ModUsage/" + $"{date.Day}-{date.Month}-{date.Year}").
                GetValueAsync().ContinueWithOnMainThread(task =>
                {
                    List<DataSnapshot> dataSnapshots = task.Result.Children.ToList();

                    if (dataSnapshots.Count > 0)
                    {
                        foreach (DataSnapshot dataSnapshot in dataSnapshots)
                        {
                            string onlineKey = dataSnapshot.Key.ToString();
                            int.TryParse(dataSnapshot.Value.ToString(), out int count);
                            string mod = dataSnapshot.Key;


                            DownloadedModStat currentStat = downloadedModStats.Find(x => x.onlineKey.Equals(onlineKey));

                            if (currentStat == null)
                                downloadedModStats.Add(new DownloadedModStat(mod, onlineKey, count));
                            else
                                currentStat.count += count;
                        }
                    }

                    foreach (ModUsageStat.ModStat modStat in modUsageStat.mods)
                    {
                        var stat = downloadedModStats.Find(x => x.onlineKey.Equals(modStat.onlineKey));
                        if (stat == null)
                        {
                            downloadedModStats.Add(new DownloadedModStat(modStat.mod, modStat.onlineKey, 0));
                        }
                    }

                    downloadedModStats = downloadedModStats.OrderByDescending(x => x.count).ToList();

                    reviewPage.text = string.Empty;
                    foreach (DownloadedModStat downloadedModStat in downloadedModStats)
                    {
                        ModUsageStat.ModStat modStat = modUsageStat.mods.Find(x => x.onlineKey.Equals(downloadedModStat.onlineKey));

                        if (modStat == null)
                            reviewPage.text += "<b>" + downloadedModStat.mod + "</b>: " + downloadedModStat.count + "\n";
                        else
                            reviewPage.text += "<b>" + modStat.UITitle + "</b>: " + downloadedModStat.count + "\n";
                    }
                });
        }
    }

    public void DeleteDailyModUsage()
    {
        FindObjectOfType<CurrentPlayerData>().datas.bugunGelenMods = new();
    }

    [System.Serializable]
    public class Debug
    {
        public TMP_Text debugText;
        public Image backgroundImage;
        public Image icon;
        public Color normalTextColor;
        public Color warningTextColor;
        public Color errorTextColor;
        public Color normalBackgroundColor;
        public Color warningBackgroundColor;
        public Color errorBackgroundColor;
        public Sprite normalSprite;
        public Sprite warninSprite;
        public Sprite errorSprite;
        public float duration = 5f;

        [HideInInspector] public float timer;

        public void Initiliaze()
        {
            backgroundImage.gameObject.SetActive(false);
        }

        public void Log(string value)
        {
            backgroundImage.gameObject.SetActive(true);
            debugText.text = value;
            debugText.color = normalTextColor;
            icon.sprite = normalSprite;
            icon.color = normalTextColor;
            backgroundImage.color = normalBackgroundColor;
            timer = duration;
        }

        public void LogWarning(string value)
        {
            backgroundImage.gameObject.SetActive(true);
            debugText.text = value;
            debugText.color = warningTextColor;
            icon.sprite = warninSprite;
            icon.color = warningTextColor;
            backgroundImage.color = warningBackgroundColor;
            timer = duration;
        }

        public void LogError(string value)
        {
            backgroundImage.gameObject.SetActive(true);
            debugText.text = value;
            debugText.color = errorTextColor;
            icon.sprite = errorSprite;
            icon.color = errorTextColor;
            backgroundImage.color = errorBackgroundColor;
            timer = duration;
        }

        public void ClosePanel()
        {
            backgroundImage.gameObject.SetActive(false);
        }
    }

    private class DownloadedModStat
    {
        public string mod;
        public string onlineKey;
        public int count;

        public DownloadedModStat()
        {
            mod = string.Empty;
            onlineKey = string.Empty;
            count = 0;
        }

        public DownloadedModStat(string mod, string onlineKey, int count)
        {
            this.mod = mod;
            this.onlineKey = onlineKey;
            this.count = count;
        }
    }
}
