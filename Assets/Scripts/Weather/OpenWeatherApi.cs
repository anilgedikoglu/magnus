using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using UnityEngine;
using UnityEngine.UI;
using System;

#if UNITY_ANDROID
using UnityEngine.Android;
#endif

public class OpenWeatherApi : MonoBehaviour
{
    CurrentPlayerData playerDataManager;

    public WeatherGeoApisVariables weatherGeoApisVariables;

    public float lon = 28.9603f;
    public float lat = 41.0100f;

    public Text debugText;
    public enum Mode { publish, debug}
    public Mode mode;

    [HideInInspector] public bool checkGpsAgain = false;
    bool checkOnFocus = false;

    // Start is called before the first frame update
    void Start()
    {
        playerDataManager = FindObjectOfType<CurrentPlayerData>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }


    //Ilk açışta eğer izin vermediyse izin sorulur. İzinden geri dönüşte tekrar kontrol etmek için bu fonksiyon kullanılır.
    private void OnApplicationFocus(bool focus)
    {
        //Devredisi birakildi!
        /*
        if (Input.location.isEnabledByUser && focus && checkOnFocus)
        {
            StartCoroutine(StartLocal());
            checkOnFocus = false;
        }*/
    }

    public IEnumerator StartLocal(bool foreToUseGecodeAPI)
    {
        print("Lokasyon erisimi baslatildi");
        // Check if the user has location service enabled.
        if (!Input.location.isEnabledByUser)
        {
#if UNITY_EDITOR
            print("Unity, <color=red>EDITOR</color> modunda calistigi icin ISTANBUL ili icin enlem ve boylam degerleri ayarlandi.");
            lon = 28.9603f;
            lat = 41.0100f;

            if (debugText != null && mode == Mode.debug)
            {
                debugText.text = "Location: " + lat + " " + lon + " " + "\n Istanbul icin degerler ayarlandi";
            }

            WeatherApiRequest();
            if (Vector2.Distance(new Vector2(lat, lon), new Vector2(playerDataManager.datas.kullaniciSehriEnlem, playerDataManager.datas.kullaniciSehriBoylam)) > 2 || foreToUseGecodeAPI)
            {
                GoogleReverseGeocodingApiRequest();
                playerDataManager.datas.kullaniciSehriEnlem = lat;
                playerDataManager.datas.kullaniciSehriBoylam = lon;
                Debug.Log("Kullanıcı son konumundan fazla uzaklaştığı için <color=cyan><b>Google Gecode API'sine</b></color> tekrar istek <color=red><b>gönderildi</b></color>.");
            }
            else
            {
                Debug.Log("Kullanıcı son kontrolden sonra bulunduğu bölgeden çok uzaklaşmadığı için <color=cyan><b>Google Gecode</b></color> isteği <color=green><b>gönderilmedi</b></color>.");
            }
#elif UNITY_ANDROID
            print("Izin verilmedigi icin lokasyon elde edilemedi");
            if (!Permission.HasUserAuthorizedPermission(Permission.FineLocation))
            {
                Permission.RequestUserPermission(Permission.FineLocation);
            }

            if (debugText != null && mode == Mode.debug)
            {
                debugText.text = "Location: " + Input.location.lastData.latitude + " " + Input.location.lastData.longitude + " " + Input.location.lastData.altitude + " " + Input.location.lastData.horizontalAccuracy + " " + Input.location.lastData.timestamp + "\n Izin olmadigi icin calistirilamadi";
            }
#endif

            if (Application.platform != RuntimePlatform.IPhonePlayer)
                yield break;
            else
                checkGpsAgain = true;
        }
        else
        {
            print("Izinler verildi");
        }

        // Starts the location service.
        Input.location.Start();

        // Waits until the location service initializes
        int maxWait = 20;
        while (Input.location.status == LocationServiceStatus.Initializing && maxWait > 0)
        {
            yield return new WaitForSeconds(1);
            maxWait--;
        }

        // If the service didn't initialize in 20 seconds this cancels location service use.
        if (maxWait < 1)
        {
            print("Timed out");
            yield break;
        }

        // If the connection failed this cancels location service use.
        if (Input.location.status == LocationServiceStatus.Failed)
        {
            print("Unable to determine device location");
            yield break;
        }
        else
        {
            // If the connection succeeded, this retrieves the device's current location and displays it in the Console window.
            print("Location: " + Input.location.lastData.latitude + " " + Input.location.lastData.longitude + " " + Input.location.lastData.altitude + " " + Input.location.lastData.horizontalAccuracy + " " + Input.location.lastData.timestamp);
            lon = Input.location.lastData.longitude;
            lat = Input.location.lastData.latitude;
        }

        if (debugText != null && mode == Mode.debug)
        {
            debugText.text = "Location: " + Input.location.lastData.latitude + " " + Input.location.lastData.longitude + " " + Input.location.lastData.altitude + " " + Input.location.lastData.horizontalAccuracy + " " + Input.location.lastData.timestamp;
        }

        WeatherApiRequest();

        if (Vector2.Distance(new Vector2(lat, lon), new Vector2(playerDataManager.datas.kullaniciSehriEnlem, playerDataManager.datas.kullaniciSehriBoylam)) > 2 || foreToUseGecodeAPI)
        {
            GoogleReverseGeocodingApiRequest();
            playerDataManager.datas.kullaniciSehriEnlem = lat;
            playerDataManager.datas.kullaniciSehriBoylam = lon;
            Debug.Log("Kullanıcı son konumundan fazla uzaklaştığı için <color=cyan><b>Google Gecode API'sine</b></color> tekrar istek <color=red><b>gönderildi</b></color>.");
        }
        else
        {
            Debug.Log("Kullanıcı son kontrolden sonra bulunduğu bölgeden çok uzaklaşmadığı için <color=cyan><b>Google Gecode</b></color> isteği <color=green><b>gönderilmedi</b></color>.");
        }

        // Stops the location service if there is no need to query location updates continuously.
        Input.location.Stop();
    }

    async void WeatherApiRequest()
    {
        playerDataManager.AddElementToChatVariableList("gps izin", "evet");
        using (var httpClient = new HttpClient())
        {
            string apiKey = "2fa3fd709ae3cb75d2f830464ef33c9c";

            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                RequestUri = new System.Uri($"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={apiKey}"),
            })
            {
                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                WeatherApi.Reponse reponse = JsonUtility.FromJson<WeatherApi.Reponse>(jsonString);
                
                if (debugText != null && mode == Mode.debug)
                {
                    debugText.text += "\n" + "Sicaklik:" + JsonUtility.FromJson<WeatherApi.Reponse>(jsonString).main.temp + "\n"+ "Hissedilen sicaklik:" + JsonUtility.FromJson<WeatherApi.Reponse>(jsonString).main.feels_like + "\n" + "Nem:" + JsonUtility.FromJson<WeatherApi.Reponse>(jsonString).main.humidity
                       + "\n" + "Basinc:" + JsonUtility.FromJson<WeatherApi.Reponse>(jsonString).main.pressure;
                }

                if (playerDataManager != null && weatherGeoApisVariables != null && mode == Mode.publish)
                {
                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.id, reponse.weather[0].id.ToString(), false);
                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.main, reponse.weather[0].main.ToLower(), false);

                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.temp, reponse.main.KelvinToCelsius().ToString(), false);
                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.feels_like, reponse.main.KelvinToCelsius((int)reponse.main.feels_like).ToString(), false);
                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.temp_max, reponse.main.KelvinToCelsius((int)reponse.main.temp_max).ToString(), false);
                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.temp_min, reponse.main.KelvinToCelsius((int)reponse.main.temp_min).ToString(), false);
                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.humidity, reponse.main.humidity.ToString(), false);

                    playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.windSpeed, reponse.wind.speed.ToString(), false);
                }
            }
        }
    }

    [Serializable]
    class WeatherApi
    {
        [Serializable]
        public class Reponse
        {
            public Coordinate coord;
            public Weather[] weather;
            public Main main;
            public Wind wind;
            public Clouds clouds;
            public int dt;
            public Sys sys;
            public int timezone;
            public int id;
            public string name;
            public int cod;
        }

        [Serializable]
        public class Coordinate
        {
            public float lon;
            public float lat;
        }

        [Serializable]
        public class Weather
        {
            public int id;
            public string main;
            public string description;
            public string icon;
        }

        [Serializable]
        public class Main
        {
            public float temp;
            public float feels_like;
            public float temp_min;
            public float temp_max;
            public float pressure;
            public float humidity;

            const int diffrencesKelvinCelsius = 273;

            public int KelvinToCelsius(int value)
            {
                value -= diffrencesKelvinCelsius;
                return value;
            }

            public int KelvinToCelsius()
            {
                return ((int)temp - diffrencesKelvinCelsius);
            }
        }

        [Serializable]
        public class Wind
        {
            public float speed;
            public float deg;
        }

        [Serializable]
        public class Clouds
        {
            public int all;
        }

        [Serializable]
        public class Sys
        {
            public int type;
            public int id;
            public string country;
            public int sunrise;
            public int sunset;
        }
    }

    async void GoogleReverseGeocodingApiRequest()
    {
        Debug.Log("<color=red><b>GECODE İSTEĞİ BAŞLATILYIOR!</b></color>.");
        using (var httpClient = new HttpClient())
        {
            string apiKey = "AIzaSyD1MYEREBVdLh-I9QHXPZTB5QrH14EOITk";

            using (var request = new HttpRequestMessage
            {
                Method = new HttpMethod("POST"),
                RequestUri = new System.Uri($"https://maps.googleapis.com/maps/api/geocode/json?latlng={lat},{lon}&sensor=false&key={apiKey}"),
            })
            {
                var response = await httpClient.SendAsync(request);

                string jsonString = await response.Content.ReadAsStringAsync();

                Debug.Log(jsonString);

                foreach(GoogleGecodeApi.AdresComponent element in JsonUtility.FromJson<GoogleGecodeApi.Response>(jsonString).results[0].address_components)
                {
                    if(element.types[0] == "administrative_area_level_1")
                    {
                        Debug.Log(element.long_name);

                        if (debugText != null && mode == Mode.debug)
                        {
                            debugText.text += "\n" + "Google Reverse Gecode Api Sonucu sehir adi: " + element.long_name;
                        }

                        if(playerDataManager!=null && weatherGeoApisVariables != null && mode == Mode.publish)
                        {
                            playerDataManager.AddElementToChatVariableList(weatherGeoApisVariables.userCurrentCity, element.long_name.ToLower(), true);
                        }
                    }
                }
            }
        }
    }

    [Serializable]
    class GoogleGecodeApi
    {
        [Serializable]
        public class Response
        {
            public Result[] results;
        }

        [Serializable]
        public class Result
        {
            public AdresComponent[] address_components;
        }

        [Serializable]
        public class AdresComponent
        {
            public string long_name;
            public string short_name;
            public string[] types;
        }
    }
}
