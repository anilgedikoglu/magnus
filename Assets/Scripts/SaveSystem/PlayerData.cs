using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class PlayerData
{
    public List<ChatDegiskeni> chatDegiskenleri;

    public Date tanismaTarihi;
    public Date lastActiveDay;

    public string kullaniciEmail = string.Empty;

    public float kullaniciSehriEnlem;
    public float kullaniciSehriBoylam;

    public int profilePhotoNum;
    public string profilePhotoLink;

    public int energy;
    public Date lastFreeEnergy;

    public int konsantrasyon;
    public Date lastFreekonsantrasyon;

    public bool ilkeEnerjiVerildi;

    public bool introGosterildi;

    public bool dahaOnceGeldi;

    public string plusExpireDate;

    //Bu degisken kullanici plus uyeligi mobile marketlerden satin aldigi zaman kullanilir.
    public Date plusExpireDateFromStore;

    //Bu degisken plus uyelik kullaniciya ozel olarak verildigi zaman kullanilir.
    public Date plusExpireDateFromSystem;

    public List<BugunGelenMod> bugunGelenMods;

    public List<CounterModData> counterModDatas = new List<CounterModData>();

    public List<string> usedEarnEnergyButtons = new List<string>();

    public List<FalModlariIstatistik> falModlariIstatistik;

    public InviteKey inviteKey = new();

    public bool isAdmin = false;
    public string adminPassword = string.Empty;

    public bool deleteKons;

    public int onlineDatabaseVersion = 0;

    public bool isUserInformationSent;

    public PlayerData()
    {
        chatDegiskenleri = new List<ChatDegiskeni>();
        bugunGelenMods = new List<BugunGelenMod>();
        counterModDatas = new List<CounterModData>();
        usedEarnEnergyButtons = new List<string>();
        isAdmin = false;
        adminPassword = string.Empty;
        kullaniciEmail = string.Empty;

        falModlariIstatistik = new();

        deleteKons = false;
        onlineDatabaseVersion = 0;

        isUserInformationSent = false;
    }

    [System.Serializable]
    public class ChatDegiskeni
    {
        public string degiskenAdi;
        public string degiskenDegeri;

        public ChatDegiskeni(string degiskenAdi, string degiskenDegeri)
        {
            this.degiskenAdi = degiskenAdi;
            this.degiskenDegeri = degiskenDegeri;
        }

        public ChatDegiskeni()
        {
            this.degiskenAdi = "";
            this.degiskenDegeri = "";
        }
    }

    [System.Serializable]
    public class BugunGelenMod
    {
        public string mod;
        public int count;

        public BugunGelenMod()
        {
            mod = string.Empty;
            count = 0;
        }

        public BugunGelenMod(string mod)
        {
            this.mod = mod;
            count = 1;
        }

        public BugunGelenMod(string mod, int count)
        {
            this.mod = mod;
            this.count = count;
        }
    }

    [System.Serializable]
    public class CounterModData
    {
        public string mod;

        public int _value;
        public int Value
        {
            set
            {
                _value = value;

                CurrentPlayerData currentPlayerData = GameObject.FindObjectOfType<CurrentPlayerData>();

                if (currentPlayerData != null)
                {
                    currentPlayerData.AddElementToChatVariableList("counter " + mod, _value.ToString());
                }
                else
                {
                    Debug.LogError("Counter mod sahnede CurrentPlayerData(PLAYER DATA) objesi olmadığı buton olarak kullanılmak üzere kaydedilemedi." +
                        " Bu counter modun çalışması ve kaçıncı seferde olduğunu bimesini engellemez ama bir değişken olarak " +
                        "sohbetlerde kullanılmasını önler veya kullanıldığı zaman yanlış değer döndürür.");
                }
            }

            get
            {

                return _value;
            }
        }

        public CounterModData()
        {
            mod = string.Empty;
            Value = 0;
        }

        public CounterModData(string mod)
        {
            this.mod = mod;
            Value = 0;
        }

        public CounterModData(string mod, int value)
        {
            this.mod = mod;
            this.Value = value;
        }
    }

    [System.Serializable]
    public struct Date
    {
        public int day;
        public int month;
        public int year;
        public int hour;
        public int minute;
        public int second;

        public Date(int year, int month, int day, int hour, int minute, int second)
        {
            this.day = day;
            this.month = month;
            this.year = year;
            this.hour = hour;
            this.minute = minute;
            this.second = second;
        }

        public Date(System.DateTime dateTime)
        {
            this.day = dateTime.Day;
            this.month = dateTime.Month;
            this.year = dateTime.Year;
            this.hour = dateTime.Hour;
            this.minute = dateTime.Minute;
            this.second = dateTime.Second;
        }


        public static bool operator ==(Date first, Date second)
        {
            if (first.year == second.year)
            {
                if (first.month == second.month)
                {
                    if (first.day == second.day)
                    {
                        if (first.hour == second.hour)
                        {
                            if (first.minute == second.minute)
                            {
                                if (first.second == second.second)
                                {
                                    return true;
                                }
                                else
                                {
                                    return false;
                                }
                            }
                            else
                            {
                                return false;
                            }
                        }
                        else
                        {
                            return false;
                        }
                    }
                    else
                    {
                        return false;
                    }
                }
                else
                {
                    return false;
                }
            }
            else
            {
                return false;
            }
        }

        public static bool operator !=(Date first, Date second)
        {
            if (first.year == second.year)
            {
                if (first.month == second.month)
                {
                    if (first.day == second.day)
                    {
                        if (first.hour == second.hour)
                        {
                            if (first.minute == second.minute)
                            {
                                if (first.second == second.second)
                                {
                                    return false;
                                }
                                else
                                {
                                    return true;
                                }
                            }
                            else
                            {
                                return true;
                            }
                        }
                        else
                        {
                            return true;
                        }
                    }
                    else
                    {
                        return true;
                    }
                }
                else
                {
                    return true;
                }
            }
            else
            {
                return true;
            }
        }
    }

    [System.Serializable]
    public class InviteKey
    {
        public string key = string.Empty;
        public bool used = false;
        public bool enteredKey = false;

        private string letters = "abcdefghijkmnprstyz" + "abcdefghjklmnprstyz".ToUpper() + "123456789";

        public InviteKey()
        {
            key = string.Empty;
            used = false;
            enteredKey = false;
        }

        public void CreateKey()
        {
            key = string.Empty;
            for (int i = 0; i < 10; i++)
                key += letters[Random.Range(0, letters.Length)];
        }
    }

    [System.Serializable]
    public class FalModlariIstatistik
    {
        public string mod;
        public List<string> sohbetIDleri;

        public FalModlariIstatistik()
        {
            mod = string.Empty;
            sohbetIDleri = new();
        }

        public FalModlariIstatistik(string mod)
        {
            this.mod = mod;
            this.sohbetIDleri = new();
        }

        public FalModlariIstatistik(string mod, List<string> sohbetIDleri)
        {
            this.mod = mod;
            this.sohbetIDleri = sohbetIDleri;
        }
    }
}
