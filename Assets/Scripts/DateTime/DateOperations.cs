using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Globalization;

namespace Magnus.Time
{
    static public class DateTimeOperations
    {
        public static DateTime serverDate = DateTime.Now;
        public static long serverUnixTimeStamp = 0;

        static public DateTime ToDateTime(string value)
        {
            DateTime lastActiveDate = DateTime.Now;

            string[] formats = {"M/d/yyyy h:mm:ss tt", "M/d/yyyy h:mm tt",
                   "MM/dd/yyyy hh:mm:ss", "M/d/yyyy h:mm:ss",
                   "M/d/yyyy hh:mm tt", "M/d/yyyy hh tt",
                   "M/d/yyyy h:mm", "M/d/yyyy h:mm",
                   "MM/dd/yyyy hh:mm", "M/dd/yyyy hh:mm","M.M.yyyy h:mm:ss tt", "M.d.yyyy h:mm tt",
                   "MM.dd.yyyy hh:mm:ss", "M.d.yyyy h:mm:ss",
                   "M.d.yyyy hh:mm tt", "M.d.yyyy hh tt",
                   "M.d.yyyy h:mm", "M.d.yyyy h:mm",
                   "MM.dd.yyyy hh:mm", "M.dd.yyyy hh:mm"};

            if (!string.IsNullOrEmpty(value))
            {
                if (DateTime.TryParseExact(value, formats, CultureInfo.InvariantCulture, DateTimeStyles.None, out lastActiveDate))
                {
                    Debug.Log("'string' türünden 'System.DateTime' türüne çevirme işlemi başarılı.");
                }
                else
                {
                    Debug.LogWarning("Verilen değer 'string' türünden 'System.DateTime' türüne çevrilemedi");
                }
            }
            else
            {
                Debug.LogWarning("'string' türünden 'System.DateTime' türüne çevrilebilecek bir değer verilemdi. HATA: NULL VEYA BOŞ DEĞER");
            }

            return lastActiveDate;
        }

        static public DateTime ToDateTime(PlayerData.Date value)
        {
            DateTime lastActiveDate = DateTime.Now;

            try
            {
                lastActiveDate = new DateTime(value.year, value.month, value.day, value.hour, value.minute, value.second);
            }
            catch
            {
                Debug.LogWarning("Verilen değer 'PlayerData.Date' türünden 'System.DateTime' türüne çevrilemedi. Bu nedenle Datetime.Now değerine göre hesap yapılacak!");
            }

            return lastActiveDate;
        }

        public static DateTime UnixTimeStampToDateTime(long miliseconds)
        {
            DateTime dateTime = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
            dateTime = dateTime.AddSeconds(miliseconds / 1000).ToLocalTime();
            return dateTime;
        }

        public static long DateTimeToUnixTimeStamp(DateTime date)
        {
            DateTime originDate = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
            TimeSpan diff = date.ToUniversalTime() - originDate;
            return (long)Math.Floor(diff.TotalSeconds);
        }
    }
}