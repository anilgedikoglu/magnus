using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Newtonsoft.Json;
using System.IO;
using Firebase.Extensions;
using Firebase.Database;
using System.Linq;
using Firebase.Storage;

public class CurrentPlayerData : MonoBehaviour
{
    //Bu class yerele şifrelenerek kaydedilir. Aynı zamanda olduğu gibi Firebase'e atılıp
    //sonra geri alınır. Bu nedenle içindeki her bir byte data uygulamaya eksra maliyettir.
    //Boyutu oldukça küçük olmalıdır. Yeterince önemli olmayan tüm datalar localPlayerDatas
    //içinde saklanmalıdır.
    public PlayerData datas;

    //Bu değişken şifrelenmeden json formatında yerele kaydedilir. Bu nedenle içerisindeki
    //bilgiler önemsiz ve appin daha iyi çalışması için genelde geçici ve yerel cihaza
    //özgü dataları barındırmalırı.
    //!!KESİNLİKLE ÖNEMLİ VE KORUNMASI GEREKEN HİÇBİR DATAYI İÇEREMEZ!!
    //Bu değişken her zaman yerelde kalır ve hiçbir zaman online olarak eşitlenmez!
    public LocalPlayerData localPlayerDatas;

    public List<PlayerData.ChatDegiskeni> yerelChatDegiskenleri;

    public ModUsageStat modUsageStat;
    public List<SessionMod> modsThisSession;

    public ChatVariables chatVariablesManager;
    public ChatManager chatManager;

    public DefaultVariables defaultVariables;

    public bool onlineDataChecked;
    public System.DateTime lastOnlineSave;
    public readonly float focuSaveRate = 15f;

    public delegate void OnModChange(string mod);
    public OnModChange onModChange;

    private ModSohbetManager modSohbetManager;

    internal delegate void OnOnlineDatabaseLoad();
    internal OnOnlineDatabaseLoad onlineDatabaseLoadEvent;

    public bool isDatabaseLoaded;

    [SerializeField] internal GameObject onlineDatabaseYukleniyorPanel;

    internal bool IsPlus
    {
        get { return GetChatVariableValue("plus") == "var"; }
    }

    internal string Mod
    {
        get { return GetChatVariableValue("mod"); }
    }

    private void Awake()
    {
        modSohbetManager = FindObjectOfType<ModSohbetManager>();

        //Uygulama ilk açıldıktan sonraki ilk focu kaybında kesinlikle kayıt yapsın diye bu şekilde
        lastOnlineSave = System.DateTime.Now.AddSeconds(-focuSaveRate * 2f);

        modsThisSession = new();

        //DontDestroyOnLoad(gameObject);
        ResetVariables();

        isDatabaseLoaded = false;
        onlineDatabaseYukleniyorPanel.SetActive(false);
        
        onlineDatabaseLoadEvent += () =>
        {
            isDatabaseLoaded = true;
            onlineDatabaseYukleniyorPanel.SetActive(false);
        };
    }

    void Start()
    {
        onModChange += (mod) =>
        {
            chatManager.modAyarlandi = true;
            AddElementToSessionMods(mod);
            SendUsedModsStats();
        };
    }

    public void Initiliaze()
    {
#if UNITY_EDITOR
        datas = new PlayerData();
#endif
        LoadPlayerData();

        if (string.IsNullOrWhiteSpace(localPlayerDatas.lastIOSVersion))
        {
            localPlayerDatas.lastIOSVersion = Application.version;
        }

        if (string.IsNullOrWhiteSpace(localPlayerDatas.lastAndroidVersion))
        {
            localPlayerDatas.lastAndroidVersion = Application.version;
        }

        int gun = (int)System.DateTime.Now.DayOfWeek;
        if (gun == 0)
            AddElementToChatVariableList("gun", 7.ToString(), false);
        else
            AddElementToChatVariableList("gun", gun.ToString(), false);

        AddElementToChatVariableList("ay", System.DateTime.Now.Month.ToString(), false);
        AddElementToChatVariableList("mevsim", chatVariablesManager.AyiMevsimeCevir(chatVariablesManager.SayiyiAyaCevir(System.DateTime.Now.Month).ToLower(), "lower"), false);

    }

    #region GetOnlineDatas
    RealtimeDatabaseManager realtimeDatabase;
    AuthenticationManager authenticationManager;

    /// <summary>
    /// Bu fonksiyon playerData turundeki datas objesini son kayıttan alir.
    /// </summary>
    /// <returns></returns>
    public IEnumerator GetUserDataOnline()
    {
        yield return new WaitForEndOfFrame();
        realtimeDatabase = FindObjectOfType<RealtimeDatabaseManager>();
        authenticationManager = FindObjectOfType<AuthenticationManager>();

        Debug.Log("Bilgiler online veritabanından alınıyor...");

        realtimeDatabase.GetData("Users/" + authenticationManager.auth.CurrentUser.UserId, (string rawJson) =>
        {
            if (rawJson != null)
            {
                Debug.Log("<Color=green>Bilgiler online veritabanından başarıyla alındı</color> ");
                Debug.Log("Online veritabanindan gelen kullanici bilgileri uygun classa cevriliyor...");
                try
                {
                    Debug.Log("<Color=green>Bilgiler uygun classa cevrildi</color>");
                    datas = JsonConvert.DeserializeObject<PlayerData>(rawJson);
                    SavePlayerData(true);

                    datas.kullaniciEmail = authenticationManager.auth.CurrentUser.Email;

                    //Admin Kontrolu
                    GetAdminInformations();

                    //Invete key kontrolu
                    GetInviteKey();

                    if (!datas.deleteKons)
                    {
                        Debug.Log("<Color=green>Kullanici yeni kons sistemine uygun olmadigi icin yeni kons sifirlandi</color>");
                        datas.deleteKons = true;
                        datas.konsantrasyon = 0;
                    }
                }
                catch
                {
                    Debug.LogError("Veri tabanından gelen kullanıcı kayıt bilgileri güncel class ile uyumlu değil. Bu çok büyük bir problem!" + rawJson);
                }
            }
            else
            {
                DeleteAdminInfo();

                datas = new PlayerData();

                Debug.Log("Bilgiler online veritabanında bulunamadığı için uygulama terminal ekranına yönlendiriliyor...");
            }


            GetVersionInfo();

        }, (string reason) =>
        {
            DeleteAdminInfo();
            onlineDataChecked = true;
            localPlayerDatas.releaseVersions = new List<string>();
            Debug.Log(reason);
        });

        //Online inbox mesajlari kontrolu
        GetOnlineSystemMessages(() => { });

        //Online inbox mesajlari kontrolu
        GetOnlineFal(() => { });

        //Onlien database alinir.
        GetOnlineDatabaseVersion();

        //Profil fotografinin online alinmasi veya indexe ayarlanmasi
        FindObjectOfType<WelcomeScreen>().SetProfilePhotoSpriteIEnumurator(datas.profilePhotoNum);

        float maxWait = 10f;
        yield return new WaitForSeconds(maxWait);
        if (!onlineDataChecked)
        {
            onlineDataChecked = true;
            Debug.Log($"{maxWait} saniye içinde serverdan yanıt gelmediği için işlem iptal edildi ve kullanıcı yerel kayıt ile devam etmeye" +
                " yönlendirildi.");
        }
    }

    /// <summary>
    /// Bu fonksiyon Admin bilgilerine ulasir.
    /// Eger kullanici adminse admin paneline erisim izni tanimlar.
    /// </summary>
    private void GetAdminInformations()
    {
        //Admin kontrolu
        DeleteAdminInfo();
        realtimeDatabase.GetData("Admins/" + authenticationManager.auth.CurrentUser.Email.
            Replace("@", string.Empty).Replace(".", string.Empty),
            (data) =>
            {
                GeneralUserOperations.Admin admin = JsonConvert.DeserializeObject<GeneralUserOperations.Admin>(data);
                if (!string.IsNullOrEmpty(admin.email) && !string.IsNullOrEmpty(authenticationManager.auth.CurrentUser.Email))
                {
                    if (admin.email == authenticationManager.auth.CurrentUser.Email)
                    {
                        datas.isAdmin = true;
                        datas.adminPassword = admin.password;
                    }
                }
            }, (reason) =>
            {
                Debug.LogError(reason);
            });
    }

    /// <summary>
    /// Bu fonksiyon admin bilgilerini sifirlar ve 
    /// tekrar baslatir.
    /// </summary>
    private void DeleteAdminInfo()
    {
        datas.isAdmin = false;
        datas.adminPassword = string.Empty;
    }

    /// <summary>
    /// Bu fonksiyon invite key kontrolu yapar.
    /// Kullanicya tanimli key yoksa key olusturur.
    /// </summary>
    private void GetInviteKey()
    {
        if (!datas.inviteKey.used)
        {
            if (string.IsNullOrEmpty(datas.inviteKey.key))
            {
                datas.inviteKey.CreateKey();
                realtimeDatabase.SetData("InviteKeys/" + datas.inviteKey.key,
                    (object)authenticationManager.auth.CurrentUser.UserId,
                    () =>
                    {
                        Debug.Log("Invite key başarı ile oluşturuldu");
                    },
                    (string reason) =>
                    {
                        Debug.Log("Invite key oluşturma başarısız.: " + reason);
                    });
            }
            else
            {
                realtimeDatabase.GetData("InviteKeys/" + datas.inviteKey.key, (string value) =>
                {
                    if (value != authenticationManager.auth.CurrentUser.UserId)
                    {
                        Debug.Log("<color=green><b>Kullanıcının key değeri başka bir kullanıcı" +
                            " tarafından kullanıldığı için kullanıcıya 1 hafta plus verildi</b></color>");
                        datas.plusExpireDateFromSystem = new PlayerData.Date(System.DateTime.Now.AddDays(7));
                        datas.inviteKey.used = true;
                    }
                });
            }
        }
    }

    /// <summary>
    /// Bu fonksiyon versiyon bilgisini alir. Eger versiyon uygun degilse
    /// kullanici app'e giremez. Fakat kullaniciyi app'e almayan kontrol burada degil
    /// intro manager icinde yapilir
    /// </summary>
    private void GetVersionInfo()
    {
        //Version bilgilerini aliyoruz
        realtimeDatabase.GetData("Versions/Release", (string rawJson) =>
        {
            if (rawJson != null)
            {
                localPlayerDatas.releaseVersions = JsonConvert.DeserializeObject<List<string>>(rawJson);
                Debug.Log("Sürüm bilgisi başarıyla alındı" + JsonConvert.DeserializeObject<List<string>>(rawJson).Count);
                Debug.Log(rawJson);
            }
            else
            {
                localPlayerDatas.releaseVersions = new List<string>();
                Debug.Log("Sürüm bilgisi bulunamadı");
            }

            GetBakimInfo();

        }, (string reason) =>
        {
            Debug.Log(reason);
            onlineDataChecked = true;
            localPlayerDatas.releaseVersions = new List<string>();
        });
    }

    /// <summary>
    /// Bu fonksiyon appte bakim olup olmadigi bilgisini alir.
    /// </summary>
    private void GetBakimInfo()
    {
        //Uygulama bakimda mi degil kontrolu
        realtimeDatabase.GetData("Bakim", (string rawJson) =>
        {
            if (rawJson != null)
            {
                localPlayerDatas.bakimDurumu = JsonConvert.DeserializeObject<bool>(rawJson);

                Debug.Log("Sürüm bilgisi başarıyla alındı");

                GetPlatformLatestVersionInfo();

                GetKapaliSohbetModlariInfo();
             
                GetPlusSohbetModlari();
            }
            else
            {
                localPlayerDatas.bakimDurumu = false;
                Debug.Log("Bakım bilgisi veritabanında bulunamadı. Bu nedenle bakım yok sayılıyor.");
            }
            onlineDataChecked = true;

        }, (string reason) =>
        {
            Debug.Log(reason);
            onlineDataChecked = true;
            localPlayerDatas.releaseVersions = new List<string>();
        });
    }

    /// <summary>
    /// Bu fonksiyon son android ve ios surumlarini platform turune gore alir.
    /// Bu bilgi kullaniciya yeni surum cikti indir diyebilmek icin kullanilir.
    /// </summary>
    private void GetPlatformLatestVersionInfo()
    {
        if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.WindowsEditor)
        {
            realtimeDatabase.GetData("Versions/LastAndroidVersion", (string rawJson) =>
            {
                if (rawJson != null)
                {
                    string currentVersion = JsonConvert.DeserializeObject<string>(rawJson);

                    if (currentVersion != null)
                    {
                        if (!string.IsNullOrWhiteSpace(currentVersion))
                        {
                            if (currentVersion != localPlayerDatas.lastAndroidVersion)
                            {
                                if (currentVersion != Application.version)
                                {
                                    localPlayerDatas.lastAndroidVersion = currentVersion;
                                    localPlayerDatas.showUpdateNotification = true;
                                }
                                else
                                {
                                    localPlayerDatas.lastAndroidVersion = currentVersion;
                                    localPlayerDatas.showUpdateNotification = false;
                                }
                            }
                            else
                            {
                                if (currentVersion == Application.version)
                                {
                                    localPlayerDatas.lastAndroidVersion = currentVersion;
                                    localPlayerDatas.showUpdateNotification = false;
                                }
                            }
                        }
                    }

                    Debug.Log("Son android sürümü bilgisi başarıyla alındı. " + localPlayerDatas.showUpdateNotification);
                }
                else
                {
                    Debug.LogWarning("Son android sürümü bilgisi alınırken hata meydana geldi.");
                }

            }, (string reason) =>
            {
                Debug.LogError(reason);
            });

        }
        else if (Application.platform == RuntimePlatform.IPhonePlayer || Application.platform == RuntimePlatform.OSXEditor)
        {
            realtimeDatabase.GetData("Versions/LastIOSVersion", (string rawJson) =>
            {
                if (rawJson != null)
                {
                    string currentVersion = JsonConvert.DeserializeObject<string>(rawJson);

                    if (currentVersion != null)
                    {
                        if (!string.IsNullOrWhiteSpace(currentVersion))
                        {
                            if (currentVersion != localPlayerDatas.lastIOSVersion)
                            {
                                if (currentVersion != Application.version)
                                {
                                    localPlayerDatas.lastIOSVersion = currentVersion;
                                    localPlayerDatas.showUpdateNotification = true;
                                }
                                else
                                {
                                    localPlayerDatas.lastIOSVersion = currentVersion;
                                    localPlayerDatas.showUpdateNotification = false;
                                }
                            }
                            else
                            {
                                if (currentVersion == Application.version)
                                {
                                    localPlayerDatas.lastIOSVersion = currentVersion;
                                    localPlayerDatas.showUpdateNotification = false;
                                }
                            }
                        }
                    }

                    Debug.Log("Son ios sürümü bilgisi başarıyla alındı.");
                }
                else
                {
                    Debug.LogWarning("Son ios sürümü bilgisi alınırken hata meydana geldi.");
                }

            }, (string reason) =>
            {
                Debug.LogError(reason);
            });
        }
        else
        {
            Debug.LogWarning("Platform uygun olmadığı için son sürüm bildirimi kontrolü yapılmadı!: " + Application.platform);
            localPlayerDatas.showUpdateNotification = false;
        }
    }

    /// <summary>
    /// Kapali olan modlari alir.
    /// </summary>
    private void GetKapaliSohbetModlariInfo()
    {
        realtimeDatabase.GetData("SohbetModlari/Kapali", (string rawJson) =>
        {
            if (rawJson != null)
            {
                localPlayerDatas.closedMods = JsonConvert.DeserializeObject<List<string>>(rawJson);
                Debug.Log("Kapalı modlar başarıyla alındı.");
            }
            else
            {
                localPlayerDatas.closedMods = new List<string>();
                Debug.Log("Kapalı modlar bilgisi veritabanında bulunamadı. Bu nedenle bakım yok sayılıyor.");
            }
            onlineDataChecked = true;

        }, (string reason) =>
        {
            Debug.Log(reason);
            onlineDataChecked = true;
            localPlayerDatas.releaseVersions = new List<string>();
        });
    }

    /// <summary>
    /// Sadece plusta gorunecek olan modlarin bilgisini alir.
    /// </summary>
    private void GetPlusSohbetModlari()
    {
        realtimeDatabase.GetData("SohbetModlari/Plus", (string rawJson) =>
        {
            if (rawJson != null)
            {
                localPlayerDatas.plusMods = JsonConvert.DeserializeObject<List<string>>(rawJson);
                Debug.Log("Plus modlar başarıyla alındı.");
            }
            else
            {
                localPlayerDatas.plusMods = new List<string>();
                Debug.Log("Plus modlar bilgisi veritabanında bulunamadı. Bu nedenle bakım yok sayılıyor.");
            }
            onlineDataChecked = true;

        }, (string reason) =>
        {
            Debug.Log(reason);
            onlineDataChecked = true;
            localPlayerDatas.releaseVersions = new List<string>();
        });
    }


    public delegate void OnComplete();
    /// <summary>
    /// Online sistem mesajlarini alir.
    /// </summary>
    private void GetOnlineSystemMessages(OnComplete onFinished)
    {
        realtimeDatabase = FindObjectOfType<RealtimeDatabaseManager>();

        realtimeDatabase.reference.Child("SystemMessages").GetValueAsync().ContinueWithOnMainThread((task) =>
        {
            if (!task.IsCanceled && !task.IsFaulted)
            {
                DataSnapshot snapshot = task.Result;
                List<DataSnapshot> childrenDatas = snapshot.Children.ToList();
                List<OnlineMessage> onlineMessages = new();

                foreach (DataSnapshot child in childrenDatas)
                {
                    string jsonValue = child.GetRawJsonValue();
                    OnlineMessage onlineMessage = JsonConvert.DeserializeObject<OnlineMessage>(jsonValue);
                    onlineMessages.Add(onlineMessage);
                    System.DateTime expireDate = Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(onlineMessage.destroyDate * 1000);

                    if ((expireDate - System.DateTime.Now).TotalHours > 0)
                    {
                        Debug.Log("<b>DATE:</b> " + expireDate.ToString() + "<b>TIMESTAMP:</b> " + onlineMessage.destroyDate);
                        RenderedText son5MetinTexts = chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");
                        if (son5MetinTexts == null)
                        {
                            chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", string.Empty, onlineMessage.message, string.Empty, onlineMessage.iD,
                  new RenderedText.Text.UIInformation(onlineMessage.title, onlineMessage.iD + onlineMessage.extension)));
                        }
                        else
                        {
                            bool add = true;
                            foreach (string id in localPlayerDatas.alinanOnlineMesajlar)
                            {
                                if (id == onlineMessage.iD)
                                {
                                    Debug.Log(id + " ID'sine sahip bir mesaj daha önce zaten alındığı için mesaj yoksayıldı.");
                                    add = false;
                                    break;
                                }
                            }

                            if (add)
                            {
                                son5MetinTexts.renderedTexts.Add(new RenderedText.Text(string.Empty, onlineMessage.message, string.Empty, onlineMessage.iD,
                      new RenderedText.Text.UIInformation(onlineMessage.title, onlineMessage.iD + onlineMessage.extension)));
                                localPlayerDatas.alinanOnlineMesajlar.Add(onlineMessage.iD);
                            }
                        }

                        if (son5MetinTexts.renderedTexts.Count > 10)
                        {
                            son5MetinTexts.renderedTexts.RemoveAt(0);
                        }
                    }
                    else
                    {
                        Debug.Log(onlineMessage.iD + " ID'sine sahip mesajın tarihi geçtiği için yoksayıldı. <b>DATE:</b> " + expireDate.ToString() + "<b>TIMESTAMO:</b> " + onlineMessage.destroyDate);
                    }
                }

                //Silinecek olan yerel fotograflarin kontrolu
                foreach (string file in System.IO.Directory.GetFiles(Application.persistentDataPath + "/SystemMessages"))
                {
                    CheckOnlineMessagesCacheFile(file, onlineMessages);
                }
            }
        });

        realtimeDatabase.reference.Child("SohbetIncelemeleri/Yanitlar/" + authenticationManager.auth.CurrentUser.UserId).GetValueAsync().ContinueWithOnMainThread((task) =>
        {
            DataSnapshot snapshot = task.Result;
            List<DataSnapshot> childrenDatas = snapshot.Children.ToList();

        
            if (!task.IsCanceled && !task.IsFaulted)
            {
                foreach (DataSnapshot childSnapshot in childrenDatas)
                {
                    if (childSnapshot.Value != null)
                    {
                        AdminAnswer adminAnswer = new();
                        try
                        {
                            adminAnswer = JsonConvert.DeserializeObject<AdminAnswer>(childSnapshot.GetRawJsonValue());
                        }
                        catch
                        {
                            break;
                        }

                        RenderedText son5MetinTexts = chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");
                        if (son5MetinTexts == null)
                        {
                            chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", "adminCevap", adminAnswer.answer,
                                string.Empty, string.Empty,new RenderedText.Text.UIInformation(string.Empty, string.Empty)));
                        }
                        else
                        {
                            var adminCevapText = son5MetinTexts.renderedTexts.Find(x => x.ID.Equals(adminAnswer.id));

                            if(adminCevapText == null)
                            {
                                if (son5MetinTexts.renderedTexts.Count + 1 > 10)
                                {
                                    son5MetinTexts.renderedTexts.RemoveAt(0);
                                }

                                son5MetinTexts.renderedTexts.Add(new RenderedText.Text("adminCevap", adminAnswer.answer, string.Empty,
                            string.Empty, new RenderedText.Text.UIInformation(string.Empty, string.Empty)));
                            }
                            else
                            {
                                adminCevapText.text += "\n\n<b>CEVAP</b>\n" + adminAnswer.answer;
                                adminCevapText.mod = "adminCevap";
                                adminCevapText.isOpened = false;
                            }

                        
                        }
                    }

                    realtimeDatabase.reference.Child("SohbetIncelemeleri/Yanitlar/" + authenticationManager.auth.CurrentUser.UserId).SetValueAsync(null);
                }
            }

            onFinished();

        });

        RenderedText son5MetinTexts = chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");
        if (son5MetinTexts != null)
        {
            List<int> silinecekIndexler = new List<int>();
            for(int i = 0; i<son5MetinTexts.renderedTexts.Count; i++)
            {
                var son5Metin = son5MetinTexts.renderedTexts[i];
                if (son5Metin.mod == "adminCevapHazirlaniyor")
                {
                    var date = Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(son5Metin.uIInformation.firstTimeStamp);
                    Debug.Log("<color=yellow><b>Sohbet inceleme kontrol ediliyor!!!</b></color>");
                    realtimeDatabase.reference.Child("SohbetIncelemeleri/TariheGore/" + date.Day + "-" + date.Month + "-" + date.Year + "/" + son5Metin.ID).GetValueAsync().ContinueWithOnMainThread(task =>
                    {
                        if(task.IsCanceled || task.IsFaulted)
                        {
                            Debug.LogError("Silinmis admin sohbet incelemeri kontrol edilirken hata meydana geldi");
                            return;
                        }

                        try
                        {
                            if (JsonConvert.DeserializeObject<AdminAnswer>(task.Result.GetRawJsonValue()) == null)
                            {
                                Debug.Log("Silinmis admin yaniti bulundu!: " + son5Metin.text);
                                son5MetinTexts.renderedTexts.Remove(son5Metin);
                            }
                        }
                        catch
                        {
                            Debug.Log("Silinmis admin yaniti bulundu!: " + son5Metin.text);
                            son5MetinTexts.renderedTexts.Remove(son5Metin);
                        }
                    });
                }
                /*
                else if (son5Metin.mod == "onlineFalHazirlaniyor" || son5Metin.mod == "dertlesHazirlaniyor" || son5Metin.mod == "ruyaHazirlaniyor")
                {
                    var date = Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(son5Metin.uIInformation.firstTimeStamp);
                    Debug.Log("<color=yellow><b>Sohbet inceleme kontrol ediliyor!!!</b></color>");
                    realtimeDatabase.reference.Child("OnlineFallar/" + authenticationManager.auth.CurrentUser.UserId + "/" + son5Metin.ID).GetValueAsync().ContinueWithOnMainThread(task =>
                    {
                        if (task.IsCanceled || task.IsFaulted)
                        {
                            Debug.LogError("Silinmis online fallar kontrol edilirken hata meydana geldi");
                            return;
                        }

                        try
                        {
                            if (JsonConvert.DeserializeObject<AdminAnswer>(task.Result.GetRawJsonValue()) == null)
                            {
                                Debug.Log("Silinmis online fal bulundu!: " + son5Metin.text);
                                son5MetinTexts.renderedTexts.Remove(son5Metin);
                            }
                        }
                        catch
                        {
                            Debug.Log("Silinmis online fal bulundu!: " + son5Metin.text);
                            son5MetinTexts.renderedTexts.Remove(son5Metin);
                        }
                    });
                }
            */}
        }
    }

    /// <summary>
    /// Online fallari alir.
    /// </summary>
    private void GetOnlineFal(OnComplete onComplete)
    {
        realtimeDatabase = FindObjectOfType<RealtimeDatabaseManager>();

        realtimeDatabase.reference.Child("OnlineFalYanitlari/" + authenticationManager.auth.CurrentUser.UserId).GetValueAsync().ContinueWithOnMainThread((task) =>
        {
            DataSnapshot snapshot = task.Result;
            List<DataSnapshot> childrenDatas = snapshot.Children.ToList();


            if (!task.IsCanceled && !task.IsFaulted)
            {
                foreach (DataSnapshot childSnapshot in childrenDatas)
                {
                    if (childSnapshot.Value != null)
                    {
                        AdminAnswer adminAnswer = new();
                        try
                        {
                            adminAnswer = JsonConvert.DeserializeObject<AdminAnswer>(childSnapshot.GetRawJsonValue());
                        }
                        catch
                        {
                            break;
                        }

                        string inboxMod = string.Empty;
                        if (adminAnswer.type == AdminAnswer.Type.premium)
                            inboxMod = "onlineFalYanit";
                        else if (adminAnswer.type == AdminAnswer.Type.dertles)
                            inboxMod = "dertlesYanit";
                        else if (adminAnswer.type == AdminAnswer.Type.ruya)
                            inboxMod = "ruyaYanit";

                        RenderedText son5MetinTexts = chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");

                        if (son5MetinTexts == null)
                        {
                            chatManager.PlayerDataManager.localPlayerDatas.renderedTexts.Add(new RenderedText("son5Metin", inboxMod, adminAnswer.answer,
                                string.Empty, string.Empty, new RenderedText.Text.UIInformation(string.Empty, string.Empty)));
                        }
                        else
                        {
                            var adminCevapText = son5MetinTexts.renderedTexts.Find(x => x.ID.Equals(adminAnswer.id));

                            if (adminCevapText == null)
                            {
                                if (son5MetinTexts.renderedTexts.Count + 1 > 10)
                                {
                                    son5MetinTexts.renderedTexts.RemoveAt(0);
                                }

                                son5MetinTexts.renderedTexts.Add(new RenderedText.Text(inboxMod, adminAnswer.answer, string.Empty, 
                                    string.Empty, new RenderedText.Text.UIInformation(string.Empty, string.Empty)));
                            }
                            else
                            {
                                adminCevapText.text = adminAnswer.answer;
                                adminCevapText.mod = inboxMod;
                                adminCevapText.isOpened = false;
                            }

                        }
                        realtimeDatabase.reference.Child("OnlineFalYanitlari/" + authenticationManager.auth.CurrentUser.UserId + "/" + childSnapshot.Key).SetValueAsync(null);
                    }
                }
            }

            onComplete();

        });
    }

    internal void InboxOnlineUpdate(OnComplete onFinished)
    {
        GetOnlineFal(() => {
            GetOnlineSystemMessages(onFinished);
        });
    }

    public void InboxOnlineUpdateButton()
    {
        InboxOnlineUpdate(() => {
            FindObjectOfType<BilgiEkraniManager>().CheckInboxNotificationState();
        });
    }

    private void GetOnlineDatabaseVersion()
    {
        #if UNITY_EDITOR
        if(modSohbetManager.modSohbetManagerData.useOnlineSohbetCacheOnEditor)
        {
            modSohbetManager.OnlineFallariYukle(modSohbetManager.modSohbetManagerData.tumOnlineSohbetler);
            return;
        }
#endif

        Debug.Log(Application.version.Replace(".", "-"));
        realtimeDatabase.GetData("Versions/OnlineDataVersionsByAppVersion/" + Application.version.Replace(".", "-"), (data) =>
        {
            int packageVersion = 0;

            try
            {
                packageVersion = JsonConvert.DeserializeObject<int>(data);
                Debug.Log(packageVersion);
            }
            catch
            {
                Debug.LogError("Surume ozel online database bulunamadi veya cevirilirken hata meydana geldi! " +
                    "En guncel surum kullanilacak!");

                realtimeDatabase.GetData("Versions/OnlineDataVersion", (data) =>
                {
                    int version = 0;
                    version = JsonConvert.DeserializeObject<int>(data);
                    GetOnlineDatabase(version);
                });
                return;
            }

            if (packageVersion <= 0)
            {
                Debug.LogError("Surume ozel online database bulunamadi veya cevirilirken hata meydana geldi! " +
                "En guncel surum kullanilacak!");

                realtimeDatabase.GetData("Versions/OnlineDataVersion", (data) =>
                {
                    int version = 0;
                    version = JsonConvert.DeserializeObject<int>(data);
                    GetOnlineDatabase(version);
                });
                return;
            }

            GetOnlineDatabase(packageVersion);

        });
    }

    private void GetOnlineDatabase(int packageVersion)
    {
        if (!(datas.onlineDatabaseVersion != packageVersion ||
    !File.Exists(Application.persistentDataPath + "/online.magnus")))
        {
            StartCoroutine(modSohbetManager.OnlineFallariYukle());
            Debug.Log($"<color=yellow>Online database versiyonu guncel oldugu icin bastan indirilmedi. Online Database Versiyon: {packageVersion}</color>");
            return;
        }

        if (File.Exists(Application.persistentDataPath + "/online.magnus"))
        {
            try
            {
                File.Delete(Application.persistentDataPath + "/online.magnus");
            }
            catch
            {
                Debug.LogWarning("Yerel cache silinemedi.");
            }
        }
        datas.onlineDatabaseVersion = packageVersion;
        string packageName = (packageVersion).ToString();
        FirebaseStorage storage = FirebaseStorage.DefaultInstance;
        StorageReference reference = storage.RootReference;
        StorageReference onlineDataRef = reference.Child("OnlineSohbetData").Child(packageName).Child("online.magnus");
        string destinationURL = Application.persistentDataPath + "/online.magnus";
        if (Application.platform == RuntimePlatform.IPhonePlayer)
            destinationURL = "file://" + destinationURL;
        onlineDataRef.GetFileAsync(destinationURL).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                onlineDatabaseLoadEvent.Invoke();
                Debug.LogError("online database alinirken hata meydana geldi!!!");
                return;
            }

            StartCoroutine(modSohbetManager.OnlineFallariYukle());
            Debug.Log($"<color=green>Online database basari ile alindi. Online Database Versiyon: {packageVersion}</color>");
            AddElementToChatVariableList("mod", "hosgeldin");
        });
    }

#endregion

    private void CheckOnlineMessagesCacheFile(string file, List<OnlineMessage> onlineMessages)
    {
        string fileID = Path.GetFileNameWithoutExtension(file);

        OnlineMessage currentOnlineMessage = onlineMessages.Find(x => x.iD.Equals(fileID));

        if (currentOnlineMessage != null)
        {
            RenderedText son5MetinTexts = localPlayerDatas.renderedTexts.Find(x => x.name == "son5Metin");

            if (son5MetinTexts != null)
            {
                if (son5MetinTexts.renderedTexts.Exists(x => x.ID.Equals(fileID)))
                    return;
            }
        }

        File.Delete(file);
        Debug.Log("Suresi gecen bir mesajin fotografi bulundugu icin fotogra silindi ID: " + fileID);
    }

    private void OnApplicationFocus(bool focus)
    {
        if (focus)
        {
            if ((System.DateTime.Now - lastOnlineSave).TotalMinutes >= 5)
            {
                Debug.Log("<color=red><b>RESET (FOCUS[TRUE]): </b></color> Uygulama 60 saniyeden uzun" +
                    " süre kullanılmadığı için resetlendi.");

                UnityEngine.SceneManagement.SceneManager.LoadScene(0);
            }
        }

        if ((System.DateTime.Now - lastOnlineSave).TotalSeconds >= 15)
        {
            if (!focus)
            {
                SendDataOnline();
                Debug.Log("<color=red><b>FIREBASE YAZMA (FOCUS[FALSE]): </b></color> Kullanici verileri Firebase'e yazıldı");
            }
        }
        else
        {
            if (!focus)
            {
                Debug.Log("Son fokus kaybındaki kontrolün üzerinden yeterince zaman geçmediği için tekrar kontrol edilmedi: "+ (System.DateTime.Now - lastOnlineSave).TotalSeconds);
            }
        }
    }

    private void OnApplicationQuit()
    {
        if ((System.DateTime.Now - lastOnlineSave).TotalSeconds >= 5)
        {
            SendDataOnline();
            Debug.Log("<color=red><b>FIREBASE YAZMA (APPLICATION.QUIT): </b></color> Kullanici verileri Firebase'e yazıldı");
        }
        else
        {
            Debug.Log("<color=green><b>FIREBASE YAZMA (APPLICATION.QUIT): </b></color> Kullanici verileri Firebase'e yazılmadı. Bu genel unfocus işleminde veriler zaten yazıldığı için Application quit işlemde" +
                " tekrar çalıştırmamak için yapılır");
        }
    }

    public void SendDataOnline()
    {
        if (datas != null)
        {
            if (FindObjectOfType<AuthenticationManager>().auth != null)
            {
                if (FindObjectOfType<AuthenticationManager>().auth.CurrentUser != null)
                {
                    FindObjectOfType<RealtimeDatabaseManager>().SetData("Users/" + FindObjectOfType<AuthenticationManager>().auth.CurrentUser.UserId, JsonConvert.SerializeObject(datas),
                        onSuccess: () =>
                        {
                            Debug.Log("Veritabanındaki kullanıcı verileri başarıyla eşitlendi.");
                        },

                        onFailed: (string reason) =>
                        {
                        //Bir sonraki sefer tekrar kontrol edilsin diye...
                        lastOnlineSave = System.DateTime.Now.AddMinutes(-1);
                            Debug.Log("Veritabanındaki kullanıcı verileri sıfırlanırken hata meydana geldi: " + reason);
                        });
                    SavePlayerData();
                    lastOnlineSave = System.DateTime.Now;
                }
                else
                {
                    Debug.LogWarning("Henüz giriş yapılmadığı için databaseye veri kaydedilmedi.");
                }
            }
            else
            {
                Debug.LogWarning("Henüz giriş yapılmadığı için databaseye veri kaydedilmedi.");
            }
        }
        else
        {
            Debug.LogWarning("Data null. Bu çoğu zaman kullanıcı henüz giriş yapmadığı için olur");
        }
    }

    private void SendUsedModsStats()
    {
        if (sendUsedModsStatsDelay != null)
            StopCoroutine(sendUsedModsStatsDelay);

        sendUsedModsStatsDelay = SendUsedModsStatsDelay();
        StartCoroutine(sendUsedModsStatsDelay);
    }

    private IEnumerator sendUsedModsStatsDelay;
    private IEnumerator SendUsedModsStatsDelay()
    {
        yield return new WaitForSeconds(10);
        System.DateTime date = Magnus.Time.DateTimeOperations.serverDate;
        foreach (SessionMod sessionMod in modsThisSession)
        {
            if (sessionMod.count > 0)
            {
                FirebaseDatabase.DefaultInstance.GetReference("ModUsage/" + $"{date.Day}-{date.Month}-{date.Year}/{sessionMod.onlineKey}/").
                GetValueAsync().ContinueWith(task =>
                {
                    int valueInt;
                    if (task.Result.Value != null)
                        int.TryParse(task.Result.Value.ToString(), out valueInt);
                    else
                        valueInt = 0;

                    Debug.Log("<color=red><b>FIREBASE YAZMA (MOD USAGE TIMER): </b></color>" +
                        "Mod kullanım istatistikleri Firebase'ye gonderildi. ");

                    FirebaseDatabase.DefaultInstance.GetReference("ModUsage/" +
                        $"{date.Day}-{date.Month}-{date.Year}/{sessionMod.onlineKey}").SetValueAsync(valueInt + sessionMod.count);

                    //Eger fokus kaybinda gonderdiyse appe geri dondugunde ayni datanin uzerinden devam
                    //etmemesi icin sifirlanir.
                    sessionMod.count = 0;
                });
            }
        }
        sendUsedModsStatsDelay = null;
    }

    public void SavePlayerData() 
    {
        SaveData.Save(this);

        string jsonData = JsonConvert.SerializeObject(localPlayerDatas);
        string jsonSavePath = Application.persistentDataPath + "/magnusLocalData.json";

        try
        {
            File.WriteAllText(jsonSavePath, jsonData);
            Debug.Log("<color=green><b>YEREL KAYIT DOSYASI YAZILDI:</b></color> Yerel kayıtları başarıyla kaydedildi.");
        }
        catch
        {
            Debug.Log("<color=red><b>YEREL KAYIT YAZILAMADI:</b></color> Yerel kayıt dosyasının kaydedilmesi sırasında bir hata meydana geldi. " +
                "Bu çok ciddi bir durumdur ve uygulamanın işleyşini tamamen değiştrir!");
        }
    }

    public void SavePlayerData(bool justOnline)
    {
        if (justOnline)
            SaveData.Save(this);
        else
            SavePlayerData();
    }

    public void LoadPlayerData()
    {
        datas = SaveData.LoadPlayerData();
        IfListsNull();

        if (File.Exists(Application.persistentDataPath + "/magnusLocalData.json"))
        {
            try
            {
                localPlayerDatas = JsonConvert.DeserializeObject<LocalPlayerData>(File.ReadAllText(Application.persistentDataPath + "/magnusLocalData.json"));
                Debug.Log("<color=green><b>YEREL KAYIT OKUNDU:</b></color> Yerel bir kayıt dosyası bulundu ve başarıyla okundu.");
            }
            catch
            {
                Debug.Log("<color=red><b>YEREL KAYIT UYGUN DEĞİL:</b></color> Yerel bir kayıt dosyası bulundu fakat bu kayıt dosyası okunup kullanılabilecek formatta değil. Bu nedenle" +
                    " yok sayıldı.");
                localPlayerDatas = new LocalPlayerData();
            }
        }
        else
            Debug.Log("<color=red><b>YEREL KAYIT BULUNAMADI:</b></color> Online olarak eşitlenmeye ve yerelde saklanan kayıt dosyası bulunamadı. Eğer bu uygulamaya ilk giriş ise sorun değil. " +
                "Ama ilk girişin dışında bu çıktı alınıyorsa hata olduğu anlamında gelir!");
    }

    public void ResetVariables()
    {
        datas = new PlayerData();
    }

    public void AddElementToChatVariableList(string degiskenAdi, string degiskenDegeri)
    {
        degiskenDegeri = degiskenDegeri.ToLower();

        if (datas.chatDegiskenleri != null)
        {
            if (datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals(degiskenAdi)))
            {
                int index = datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));
                datas.chatDegiskenleri[index].degiskenDegeri = degiskenDegeri;
            }
            else
            {
                datas.chatDegiskenleri.Add(new PlayerData.ChatDegiskeni(degiskenAdi, degiskenDegeri));
            }
        }
        else
        {
            datas.chatDegiskenleri = new List<PlayerData.ChatDegiskeni>();
            datas.chatDegiskenleri.Add(new PlayerData.ChatDegiskeni(degiskenAdi, degiskenDegeri));
        }

        if (degiskenAdi == "mod" && onModChange != null)
        {
            onModChange(degiskenDegeri);
        }
    }

    public void AddElementToChatVariableList(string degiskenAdi, string degiskenDegeri, bool save)
    {
        if (save)
        {
            AddElementToChatVariableList(degiskenAdi, degiskenDegeri);
        }
        else
        {
            degiskenDegeri = degiskenDegeri.ToLower();

            if (yerelChatDegiskenleri != null)
            {
                if (yerelChatDegiskenleri.Exists(x => x.degiskenAdi.Equals(degiskenAdi)))
                {
                    int index = yerelChatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));
                    yerelChatDegiskenleri[index].degiskenDegeri = degiskenDegeri;
                }
                else
                {
                    yerelChatDegiskenleri.Add(new PlayerData.ChatDegiskeni(degiskenAdi, degiskenDegeri));
                }
            }
            else
            {
                yerelChatDegiskenleri = new List<PlayerData.ChatDegiskeni>();
                yerelChatDegiskenleri.Add(new PlayerData.ChatDegiskeni(degiskenAdi, degiskenDegeri));
            }
        }
    }

    public void AddElementToSessionMods(string mod)
    {
        ModUsageStat.ModStat modUsageData = modUsageStat.mods.Find(x => x.mod.Equals(mod));
        if (modUsageData != null)
        {
            SessionMod sessionMod = modsThisSession.Find(x => x.mod.Equals(mod));
            if (sessionMod != null)
                sessionMod.count++;
            else
                modsThisSession.Add(new SessionMod(mod, 1, modUsageData.onlineKey));
        }
    }

    /// <summary>
    /// Session mods listesine element ekler. Fakat normalde sadece mouUsage datadaki modlari
    /// eklerken bu fonksiyon onun disindaki modlari eklemeye de zorlar.
    /// </summary>
    /// <param name="mod">Eklenecek mod</param>
    /// <param name="forceSave">Mod, modUsageDatada yoksa da eklemeye zorla</param>
    public void AddElementToSessionMods(string mod, bool forceSave)
    {
        if (forceSave)
        {
            SessionMod sessionMod = modsThisSession.Find(x => x.mod.Equals(mod));
            if (sessionMod != null)
                sessionMod.count++;
            else
                modsThisSession.Add(new SessionMod(mod, 1, mod));
        }
        else
        {
            AddElementToSessionMods(mod);
        }
    }

    public string GetRenderedText(string name)
    {
        string returnValue = "";

        foreach(RenderedText element in localPlayerDatas.renderedTexts)
        {
            if (element.name == name)
            {
                returnValue = element.renderedTexts[0].text;
                break;
            }
        }

        return returnValue;
    }


    public string GetChatVariableValue(string degiskenAdi, bool ilkHarfBuyuk)
    {
        if (ilkHarfBuyuk)
        {
            int databaseIndex = datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));

            int yerelDatabaseIndex = yerelChatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));

            if (databaseIndex >= 0)
            {
                string value = datas.chatDegiskenleri[databaseIndex].degiskenDegeri;
                char[] valueChar = value.ToCharArray();

                value = "";
                for (int i = 0; i < valueChar.Length; i++)
                {
                    if (i == 0)
                    {
                        value += valueChar[i].ToString().ToUpper();
                    }
                    else if (valueChar[i - 1].ToString() == " ")
                    {
                        value += valueChar[i].ToString().ToUpper();
                    }
                    else
                    {
                        value += valueChar[i].ToString();
                    }
                }
                return value;
            }
            else if (yerelDatabaseIndex >= 0)
            {
                string value = yerelChatDegiskenleri[yerelDatabaseIndex].degiskenDegeri;
                char[] valueChar = value.ToCharArray();

                value = "";
                for (int i = 0; i < valueChar.Length; i++)
                {
                    if (i == 0)
                    {
                        value += valueChar[i].ToString().ToUpper();
                    }
                    else if (valueChar[i - 1].ToString() == " ")
                    {
                        value += valueChar[i].ToString().ToUpper();
                    }
                    else
                    {
                        value += valueChar[i].ToString();
                    }
                }
                return value;
            }

            int defaultValueIndex = defaultVariables.degiskenler.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));

            if (defaultValueIndex >= 0)
                return defaultVariables.degiskenler[defaultValueIndex].degiskenDegeri;
            else
                return string.Empty;
        }
        else
        {
           return GetChatVariableValue(degiskenAdi);
        }
    }

    public string GetChatVariableValue(string degiskenAdi)
    {
        int databaseIndex = datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));

        if (databaseIndex >= 0)
        {
            return datas.chatDegiskenleri[databaseIndex].degiskenDegeri;
        }

        int yerelDatabaseIndex = yerelChatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));

        if (yerelDatabaseIndex >= 0)
            return yerelChatDegiskenleri[yerelDatabaseIndex].degiskenDegeri;

        int defaultValueIndex = defaultVariables.degiskenler.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));

        if (defaultValueIndex >= 0)
            return defaultVariables.degiskenler[defaultValueIndex].degiskenDegeri;
        else
            return string.Empty;
    }

    public int GetChatVariableValueInt(string degiskenAdi)
    {
        string stringValue = GetChatVariableValue(degiskenAdi);
        int intValue;

        int.TryParse(stringValue, out intValue);

        return intValue;
    }

    void IfListsNull() 
    {
        if (datas.chatDegiskenleri == null) 
        {
            datas.chatDegiskenleri = new List<PlayerData.ChatDegiskeni>();
        }

        if (localPlayerDatas.dahaOnceGelenSohbetler == null)
        {
            localPlayerDatas.dahaOnceGelenSohbetler = new List<string>();
        }
    }

    public void CreateDataOrSaveOnCurrentOne(string degiskenAdi, string degiskenDegeri) 
    {
        if (datas.chatDegiskenleri.Exists(x => x.degiskenAdi.Equals(degiskenAdi)))
        {
            int index = datas.chatDegiskenleri.FindIndex(x => x.degiskenAdi.Equals(degiskenAdi));
            datas.chatDegiskenleri[index].degiskenDegeri = degiskenDegeri;
        }
        else 
        {
            datas.chatDegiskenleri.Add(new PlayerData.ChatDegiskeni(degiskenAdi, degiskenDegeri));
        }
    }

    [System.Serializable]
    public class LocalPlayerData
    {
        public List<string> dahaOnceGelenSohbetler;
        public List<string> releaseVersions;

        public string lastAndroidVersion;
        public string lastIOSVersion;

        public bool showUpdateNotification;

        public List<string> closedMods;
        public List<string> plusMods;

        public bool bakimDurumu;
        public List<RenderedText> renderedTexts = new List<RenderedText>();
        public List<string> alinanOnlineMesajlar = new();
        public KarsilamaMetniData karsilamaMetniData = new();

        public LocalPlayerData()
        {
            dahaOnceGelenSohbetler = new List<string>();
            renderedTexts = new List<RenderedText>();
            releaseVersions = new List<string>();
            bakimDurumu = false;
            showUpdateNotification = false;
            lastAndroidVersion = string.Empty;
            lastIOSVersion = string.Empty;
            alinanOnlineMesajlar = new List<string>();
            karsilamaMetniData = new KarsilamaMetniData();
        }

        [System.Serializable]
        public class SavedSohbet
        {
            public string title;
            public string text;
            public string photoId;
            public string date;

            public SavedSohbet()
            {
                title = string.Empty;
                text = string.Empty;
                photoId = string.Empty;
                date = string.Empty;
            }

            public SavedSohbet(string title, string text)
            {
                this.title = title;
                this.text = text;
                photoId = string.Empty;
                date = string.Empty;
            }

            public SavedSohbet(string title, string text, string photoId)
            {
                this.title = title;
                this.text = text;
                this.photoId = photoId;
                date = string.Empty;
            }

            public SavedSohbet(string title, string text, string photoId, string date)
            {
                this.title = title;
                this.text = text;
                this.photoId = photoId;
                this.date = date;
            }
        }

        [System.Serializable]
        public class KarsilamaMetniData
        {
            public List<int> karsilama = new();
            public List<int> duzenleme = new();
            public List<int> falHaklari = new();
            public List<int> gelenKutusu = new();

            public KarsilamaMetniData()
            {
                karsilama = new();
                duzenleme = new();
                falHaklari = new();
                gelenKutusu = new();
            }
        }
    }

    [System.Serializable]
    public class OnlineMessage
    {
        public string title;
        public string message;
        public string iD;
        public string extension;
        public long destroyDate;

        public OnlineMessage()
        {
            title = string.Empty;
            message = string.Empty;
            iD = CreateID();
            destroyDate = 0;
            extension = string.Empty;
        }

        public OnlineMessage(string title, string message, long destroyDate, string extension)
        {
            this.title = title;
            this.message = message;
            iD = CreateID();
            this.destroyDate = destroyDate;
            this.extension = extension;
        }

        string CreateID()
        {
            string characters = "acbdefhijklmnzxvwq123456789";

            string iD = string.Empty;

            for (int i = 0; i < 8; i++)
            {
                iD += characters[UnityEngine.Random.Range(0, characters.Length)];
            }
            return iD;
        }
    }

    [System.Serializable]
    public class SessionMod
    {
        public string mod;
        public string onlineKey;
        public int count;

        public SessionMod()
        {
            mod = string.Empty;
            count = 0;
        }

        public SessionMod(string mod)
        {
            this.mod = mod;
            count = 1;
        }

        public SessionMod(string mod, int count)
        {
            this.mod = mod;
            this.count = count;
        }

        public SessionMod(string mod, int count, string onlineKey)
        {
            this.mod = mod;
            this.onlineKey = onlineKey;
            this.count = count;
        }
    }

    [System.Serializable]
    public class AdminAnswer
    {
        public string answer;
        public string id;
        public Type type;

        public AdminAnswer()
        {
            answer = string.Empty;
            id = string.Empty;
            type = Type.premium;
        }

        public enum Type
        {
            premium,
            dertles,
            ruya
        }
    }
}
