using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "CityDatabase", menuName = "Magnus/CityDatabase")]
public class CountryCityDatabase : ScriptableObject
{
    public List<City> cities;

    [System.Serializable]
    public class City
    {
        public string city;
        public string cityAscii;
        public string lat;
        public string lng;
        public string country;
        public string iso2;
        public string iso3;
        public string adminName;
        public string capital;
        public string population;
        public string id;
    }

}
