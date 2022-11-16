using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[SerializeField]
public class WeatherGeoApisVariables : ScriptableObject
{
    public string id;
    public string main;

    public string temp;
    public string feels_like;
    public string temp_min;
    public string temp_max;
    public string humidity;

    public string windSpeed;

    public string userCurrentCity;
}
