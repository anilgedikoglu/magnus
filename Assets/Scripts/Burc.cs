using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Burc
{
    public enum BurcDili 
    { 
        eng = 0,
        tur = 1,
    }

    public static string BurcHesapla(int gun, int ay)
    {
        string value = "kova";

        if ((ay == 1 && (gun >= 21 && gun <= 31)) || ((ay == 2 && (gun >= 1 && gun <= 18))))
        {
            value = "kova";
        }
        else if ((ay == 2 && (gun >= 19 && gun <= 31)) || ((ay == 3 && (gun >= 1 && gun <= 20))))
        {
            value = "balık";
        }
        else if ((ay == 3 && (gun >= 21 && gun <= 31)) || ((ay == 4 && (gun >= 1 && gun <= 20))))
        {
            value = "koç";
        }
        else if ((ay == 4 && (gun >= 21 && gun <= 31)) || ((ay == 5 && (gun >= 1 && gun <= 20))))
        {
            value = "boğa";
        }
        else if ((ay == 5 && (gun >= 21 && gun <= 31)) || ((ay == 6 && (gun >= 1 && gun <= 21))))
        {
            value = "ikizler";
        }
        else if ((ay == 6 && (gun >= 22 && gun <= 31)) || ((ay == 7 && (gun >= 1 && gun <= 22))))
        {
            value = "yengeç";
        }
        else if ((ay == 7 && (gun >= 23 && gun <= 31)) || ((ay == 8 && (gun >= 1 && gun <= 22))))
        {
            value = "aslan";
        }
        else if ((ay == 8 && (gun >= 23 && gun <= 31)) || ((ay == 9 && (gun >= 1 && gun <= 22))))
        {
            value = "başak";
        }
        else if ((ay == 9 && (gun >= 23 && gun <= 31)) || ((ay == 10 && (gun >= 1 && gun <= 23))))
        {
            value = "terazi";
        }
        else if ((ay == 10 && (gun >= 24 && gun <= 31)) || ((ay == 11 && (gun >= 1 && gun <= 22))))
        {
            value = "akrep";
        }
        else if ((ay == 11 && (gun >= 23 && gun <= 31)) || ((ay == 12 && (gun >= 1 && gun <= 21))))
        {
            value = "yay";
        }
        else if ((ay == 12 && (gun >= 22 && gun <= 31)) || ((ay == 1 && (gun >= 1 && gun <= 20))))
        {
            value = "oğlak";
        }

        return value;
    }

    public static string Ceviri(string eng, BurcDili burcDili)
    {
        string value = "kova";
        Debug.LogError(eng);

        if (eng == "aries")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "koç";
                    break;
            }
        }
        else if (eng == "leo")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "aslan";
                    break;
            }
        }
        else if (eng == "sagittarius")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "yay";
                    break;
            }
        }
        else if (eng == "taurus")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "boğa";
                    break;
            }
        }
        else if (eng == "virgo")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "başak";
                    break;
            }
        }
        else if (eng == "capricorn")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "oğlak";
                    break;
            }
        }
        else if (eng == "gemini")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "ikizler";
                    break;
            }
        }
        else if (eng == "libra")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "terazi";
                    break;
            }
        }
        else if (eng == "aquarius")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "kova";
                    break;
            }
        }
        else if (eng == "cancer")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "yengeç";
                    break;
            }
        }
        else if (eng == "scorpio")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "akrep";
                    break;
            }
        }
        else if (eng == "pisces")
        {
            switch (burcDili)
            {
                case BurcDili.eng:
                    value = eng;
                    break;

                case BurcDili.tur:
                    value = "balık";
                    break;
            }
        }
        return value;
    }

    public static string GezegeniAl(string burc)
    {
        string value = "Venüs";

        if (burc == "koç")
        {
            return "Mars";
        }
        else if (burc == "aslan")
        {
            return "Güneş";
        }
        else if (burc == "yay")
        {
            return "Jüpiter";
        }
        else if (burc == "boğa")
        {
            return "Venüs";
        }
        else if (burc == "başak")
        {
            return "Merkür";
        }
        else if (burc == "oğlak")
        {
            return "Satürn";
        }
        else if (burc == "ikizler")
        {
            return "Merkür";
        }
        else if (burc == "terazi")
        {
            return "Venüs";
        }
        else if (burc == "kova")
        {
            return "Uranüs";
        }
        else if (burc == "yengeç")
        {
            return "Ay";
        }
        else if (burc == "akrep")
        {
            return "Plüton";
        }
        else if (burc == "balık")
        {
            return "Neptün";
        }
        return value;
    }

    public static List<string> TumBurclarListe()
    {
        List<string> burclar = new List<string>();
        burclar.Add("kova");
        burclar.Add("balık");
        burclar.Add("koç");
        burclar.Add("boğa");
        burclar.Add("ikizler");
        burclar.Add("yengeç");
        burclar.Add("aslan");
        burclar.Add("başak");
        burclar.Add("terazi");
        burclar.Add("akrep");
        burclar.Add("yay");
        burclar.Add("oğlak");

        return burclar;
    }
}