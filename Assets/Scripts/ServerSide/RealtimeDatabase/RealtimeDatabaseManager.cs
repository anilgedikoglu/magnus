using Firebase.Database;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Firebase.Extensions;
using Newtonsoft.Json;
using System;

public class RealtimeDatabaseManager : MonoBehaviour
{
    public DatabaseReference reference;
    AuthenticationManager authenticationManager;

    public delegate void OnSetDatasWithSuccess();
    public delegate void OnSetDatasFailed(string reason);

    public delegate void OnGetDatasWithSuccess(string rawJson);
    public delegate void OnGetDatasFailed(string reason);

    // Start is called before the first frame update
    void Start()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
    }

    // Update is called once per frame
    void Update()
    {

    }

    public void SetData(string key, string rawJson, OnSetDatasWithSuccess onSuccess, OnSetDatasFailed onFailed)
    {
        reference.Child(key).SetRawJsonValueAsync(rawJson).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                onFailed(task.Exception.ToString());
                return;
            }

            //Basarili bir sekilde veri alinmissa fonksiyonu calistiyoruz.
            onSuccess();
        });
    }

    public void SetData(string key, string rawJson)
    {
        reference.Child(key).SetRawJsonValueAsync(rawJson).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                //onFailed(task.Exception.ToString());
                return;
            }

            //Basarili bir sekilde veri alinmissa fonksiyonu calistiyoruz.
            //onSuccess();
        });
    }

    public void SetData(string key, object value, OnSetDatasWithSuccess onSuccess, OnSetDatasFailed onFailed)
    {
        reference.Child(key).SetValueAsync(value).ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                onFailed(task.Exception.ToString());
                return;
            }

            //Basarili bir sekilde veri alinmissa fonksiyonu calistiyoruz.
            onSuccess();
        });
    }

    public void GetData(string key, OnGetDatasWithSuccess onSuccess, OnGetDatasFailed onFailed)
    {
        reference.Child(key).GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                onFailed(task.Exception.ToString());
                return;
            }

            DataSnapshot snapshot = task.Result;

            //Basarili bir sekilde veri alinmissa fonksiyonu calistiyoruz.
            onSuccess(snapshot.GetRawJsonValue());
        });
    }

    public void GetData(string key, OnGetDatasWithSuccess onSuccess)
    {
        reference.Child(key).GetValueAsync().ContinueWithOnMainThread(task =>
        {
            if (task.IsCanceled || task.IsFaulted)
            {
                Debug.LogError("failed");
                return;
            }
            DataSnapshot snapshot = task.Result;

            //Basarili bir sekilde veri alinmissa fonksiyonu calistiyoruz.

            string valueText = (snapshot.Value != null) ? snapshot.Value.ToString() : "Null";

            onSuccess(valueText);
        });
    }

    public void PostTimeStampToDatebase()
    {
        SetData("Time/TimeStamp", GetCurrentTimeStampForFirebaseServer(), () =>
        {
            GetTime();
        }, (reason) =>
        {
            Debug.Log(reason);
        });

    }
    public static object GetCurrentTimeStampForFirebaseServer()
    {
        return ServerValue.Timestamp;
    }


    //Guncel online tarihe erismek icin direkt olarak bu datayi kullanma!
    private void GetTime()
    {
        GetData("Time/TimeStamp", (string data) => {
            long.TryParse(data, out long timeStamp);

            DateTime dateTime = Magnus.Time.DateTimeOperations.UnixTimeStampToDateTime(timeStamp);
            Magnus.Time.DateTimeOperations.serverDate = dateTime;
            Magnus.Time.DateTimeOperations.serverUnixTimeStamp = timeStamp;
        });
    }
}