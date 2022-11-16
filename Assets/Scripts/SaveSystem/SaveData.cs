using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;

public static class SaveData
{
    public static void Save(CurrentPlayerData currentData) 
    {
        BinaryFormatter formatter = new BinaryFormatter();
        string path = Application.persistentDataPath + "/save.magnus";
        FileStream stream = new FileStream(path, FileMode.Create);

        PlayerData data = currentData.datas;

        formatter.Serialize(stream, data);
        stream.Close();
    }

    public static void SaveOnlineSohbets(OnlineSohbetData[] onlineSohbetler)
    {
        BinaryFormatter formatter = new BinaryFormatter();
        string path = Application.persistentDataPath + "/online.magnus";
        FileStream stream = new FileStream(path, FileMode.Create);

        OnlineSohbetData[] data = onlineSohbetler;

        formatter.Serialize(stream, data);
        stream.Close();
    }

    public static void SaveObject(string path, object data)
    {
        BinaryFormatter formatter = new BinaryFormatter();
        path = Application.persistentDataPath + "/" + path;
        FileStream stream = new FileStream(path, FileMode.Create);

        formatter.Serialize(stream, data);
        stream.Close();
    }

    public static PlayerData LoadPlayerData() 
    {
        string path = Application.persistentDataPath + "/save.magnus";
        if (File.Exists(path)) 
        {
            BinaryFormatter formatter = new BinaryFormatter();
            FileStream stream = new FileStream(path, FileMode.Open);

            PlayerData data = new PlayerData();
            try
            {
                 data = formatter.Deserialize(stream) as PlayerData;
            }
            catch
            {
                Debug.LogWarning("Save file does not exist!");
            }
            stream.Close();

            return data;
        }
        else 
        {
            Debug.LogWarning("Save file does not exist!");
            return new PlayerData();
        }
    }

    public static OnlineSohbetData[] LoadOnlineSohbets()
    {
        string path = Application.persistentDataPath + "/online.magnus";
        if (File.Exists(path))
        {
            BinaryFormatter formatter = new BinaryFormatter();
            FileStream stream = new FileStream(path, FileMode.Open);

            OnlineSohbetData[] data = new OnlineSohbetData[0];
            try
            {
                data = formatter.Deserialize(stream) as OnlineSohbetData[];
            }
            catch
            {
                Debug.LogWarning("file does not exist!");
            }
            stream.Close();

            return data;
        }
        else
        {
            Debug.LogWarning("file does not exist!");
            return new OnlineSohbetData[0];
        }
    }

    public static object LoadObject(string path)
    {
        path = Application.persistentDataPath + "/" + path;
        if (File.Exists(path))
        {
            BinaryFormatter formatter = new BinaryFormatter();
            FileStream stream = new FileStream(path, FileMode.Open);

            object data = null;
            try
            {
                data = formatter.Deserialize(stream);
            }
            catch
            {
                Debug.LogWarning("Save file does not exist!");
            }
            stream.Close();

            return data;
        }
        else
        {
            Debug.LogWarning("Save file does not exist!");
            return null;
        }
    }

    public static void DeleteSaveFile()
    {
        string path = Application.persistentDataPath + "/save.magnus";
        string path2 = Application.persistentDataPath + "/magnusLocalData.json";
        File.Delete(path);
        File.Delete(path2);
    }
}
