using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Threading.Tasks;

[CustomEditor(typeof(CountryCityDatabase)), CanEditMultipleObjects]
public class CityDatabaseEditor : Editor
{
    int page=0;
    public int lineCount = 30;

    TextAsset textAsset;

    string city;
    string cityAscii;
    string lat;
    string lng;
    string country;
    string iso2;
    string iso3;
    string adminName;
    string capital;
    string population;
    string id;

    List<CountryCityDatabase.City> cities;
    void OnEnable()
    {
        CountryCityDatabase targetObject = (CountryCityDatabase)target;
        cities = targetObject.cities;
    }

    public override void OnInspectorGUI()
    {
        CountryCityDatabase targetObject = (CountryCityDatabase)target;

        //textAsset = (TextAsset)EditorGUILayout.ObjectField(textAsset, typeof(TextAsset), true);

        page = EditorGUILayout.IntField(page);
        lineCount = EditorGUILayout.IntField(lineCount);

        if (page > cities.Count)
            page = cities.Count;
        else if (page < 0)
            page = 0;

        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("-"))
        {
            if (page > 0)
                page -= 1;
        }

        EditorGUILayout.LabelField((page * lineCount).ToString() + "/" + (cities.Count).ToString());
        if (GUILayout.Button("+"))
        {
            if (page < cities.Count)
                page += 1;
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField(targetObject.cities[0].city, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].cityAscii, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].lat, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].lng, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].country, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].iso2, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].iso3, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].adminName, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].capital, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].population, GUILayout.Width(80));
        EditorGUILayout.LabelField(targetObject.cities[0].id, GUILayout.Width(80));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        city = EditorGUILayout.TextField(city, GUILayout.Width(80));
        cityAscii = EditorGUILayout.TextField(cityAscii, GUILayout.Width(80));
        lat = EditorGUILayout.TextField(lat, GUILayout.Width(80));
        lng = EditorGUILayout.TextField(lng, GUILayout.Width(80));
        country = EditorGUILayout.TextField(country, GUILayout.Width(80));
        iso2 = EditorGUILayout.TextField(iso2, GUILayout.Width(80));
        iso3 = EditorGUILayout.TextField(iso3, GUILayout.Width(80));
        adminName = EditorGUILayout.TextField(adminName, GUILayout.Width(80));
        capital = EditorGUILayout.TextField(capital, GUILayout.Width(80));
        population = EditorGUILayout.TextField(population, GUILayout.Width(80));
        id = EditorGUILayout.TextField(id, GUILayout.Width(80));
        EditorGUILayout.EndHorizontal();

        for (int i = page * lineCount; i < (page + 1) * lineCount; i++)
        {
            if (i < cities.Count)
            {
                if (cities[i].city != "\"city\"")
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField(cities[i].city, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].cityAscii, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].lat, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].lng, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].country, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].iso2, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].iso3, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].adminName, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].capital, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].population, GUILayout.Width(80));
                    EditorGUILayout.LabelField(cities[i].id, GUILayout.Width(80));
                    EditorGUILayout.EndHorizontal();
                }
            }
        }

        if (GUILayout.Button("Bul"))
        {
            deneme();
        }
    }

    async void deneme()
    {
        cities = new List<CountryCityDatabase.City>();
        cities = await Search();
    }

    public async Task<List<CountryCityDatabase.City>> StartSearch()
    {
        List<CountryCityDatabase.City>  returnValue = new List<CountryCityDatabase.City>();
        returnValue = await Search();

        return returnValue;
    }

    public async Task<List<CountryCityDatabase.City>> Search()
    {
        CountryCityDatabase targetObject = (CountryCityDatabase)target;

        List<CountryCityDatabase.City> returnValue = new List<CountryCityDatabase.City>();

        await Task.Run(() =>
        {
            foreach (CountryCityDatabase.City element in targetObject.cities)
            {
                if (Contains(element.city.Replace("\"", ""), city) || city.Replace(" ", "") == "")
                {
                    if (Contains(element.cityAscii.Replace("\"", ""), cityAscii) || cityAscii.Replace(" ", "") == "")
                    {
                        if (Contains(element.lat.Replace("\"", ""), lat) || lat.Replace(" ", "") == "")
                        {
                            if (Contains(element.lng.Replace("\"", ""), lng) || lng.Replace(" ", "") == "")
                            {
                                if (Contains(element.country.Replace("\"", ""), country) || country.Replace(" ", "") == "")
                                {
                                    if (Contains(element.iso2.Replace("\"", ""), iso2) || iso2.Replace(" ", "") == "")
                                    {
                                        if (Contains(element.iso3.Replace("\"", ""), iso3) || iso3.Replace(" ", "") == "")
                                        {
                                            if (Contains(element.adminName.Replace("\"", ""), adminName) || adminName.Replace(" ", "") == "")
                                            {
                                                if (Contains(element.capital.Replace("\"", ""), capital) || capital.Replace(" ", "") == "")
                                                {
                                                    if (Contains(element.population.Replace("\"", ""), population) || population.Replace(" ", "") == "")
                                                    {
                                                        if (Contains(element.id.Replace("\"", ""), id) || id.Replace(" ", "") == "")
                                                        {
                                                            returnValue.Add(element);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        });

        return returnValue;
    }

    bool Contains(string mainText, string text)
    {
        bool returnValue = false;

        if (text == null)
            text = "";

        char[] mainTextChar = mainText.ToLower().ToCharArray();
        char[] textChar = text.ToLower().ToCharArray();

        for (int i = 0; i < textChar.Length; i++)
        {
            if (mainTextChar.Length > i)
            {
                if (textChar[i] == mainTextChar[i])
                {
                    if (i == textChar.Length - 1)
                    {
                        returnValue = true;
                    }
                }
                else
                {
                    returnValue = false;
                    break;
                }
            }
            else
            {
                returnValue = true;
                break;
            }
        }

        return returnValue;
    }
}
