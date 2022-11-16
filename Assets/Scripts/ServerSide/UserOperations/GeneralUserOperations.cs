using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GeneralUserOperations : ScriptableObject
{
    public List<string> closedMods;
    public List<string> plusMods;
    public List<string> versions;
    public string lastAndroidVersion;
    public string lastIosVersion;
    public bool bakim;
    public Uyari bakimUyari;
    public Uyari surumEskiUyari;

    public List<Admin> admins;

    [System.Serializable]
    public class Uyari
    {
        [TextArea(1, 5)]
        public string title;
        [TextArea(1, 5)]
        public string subTitle;
        [TextArea(1, 5)]
        public string description;

        public Uyari()
        {
            title = string.Empty;
            subTitle = string.Empty;
            description = string.Empty;
        }

        public Uyari(string title, string subTitle, string description)
        {
            this.title = title;
            this.subTitle = subTitle;
            this.description = description;
        }
    }

    [System.Serializable]
    public class Admin
    {
        public string name;
        public string email;
        public string password;

        public Admin()
        {
            name = string.Empty;
            email = string.Empty;
            password = string.Empty;
        }

        public Admin(string name, string email, string password)
        {
            this.name = name;
            this.email = email;
            this.password = password;
        }
    }
}
