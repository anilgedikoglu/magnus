using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class UserProgress
{
    [Serializable]
    struct PurchaseProgress
    {
        public string item;
        public int value;

        public PurchaseProgress(string item, int value)
        {
            this.item = item;
            this.value = value;
        }
    }

    static UserProgress current;

    public event Action ProgressUpdate = delegate { };

    Dictionary<string, GameState> gameStates = new Dictionary<string, GameState>();

    [SerializeField]
    int coins;

    [SerializeField]
    List<string> purchasedItems = new List<string>();

    [SerializeField]
    List<PurchaseProgress> purchaseInProgress = new List<PurchaseProgress>();

    [SerializeField]
    string currentGameId;

    public static UserProgress Current
    {
        get
        {
            if (current != null)
                return current;

            string progressJson = PlayerPrefs.GetString("UserProgress", "{}");
            Debug.Log("UserProgress : " + progressJson);
            current = JsonUtility.FromJson<UserProgress>(progressJson);

            return current;
        }
    }

    public int Coins
    {
        get => coins;
        set
        {
            coins = value;

            Save();

            ProgressUpdate.Invoke();
        }
    }

    public string CurrentGameId
    {
        get => currentGameId;
        set
        {
            currentGameId = value;

            Save();

            ProgressUpdate.Invoke();
        }
    }

    public string CurrentThemeId
    {
        get => GetGameState<GameState>(currentGameId)?.ThemeId;
        set
        {
            GameState gameState = GetGameState<GameState>(currentGameId);
            gameState.ThemeId = value;
            SetGameState(currentGameId, gameState);
            SaveGameState(currentGameId);
            Save();

            ProgressUpdate.Invoke();
        }
    }

    public bool IsItemPurchased(string item)
    {
        return purchasedItems.Contains(item);
    }

    public void OnItemPurchased(string item)
    {
        purchasedItems.Add(item);

        Save();

        ProgressUpdate.Invoke();
    }

    public int GetItemPurchaseProgress(string item)
    {
        PurchaseProgress purchaseProgress = purchaseInProgress.Find(p => p.item == item);
        return purchaseProgress.value;
    }

    public void SetItemPurchaseProgress(string item, int value)
    {
        purchaseInProgress.RemoveAll(p => p.item == item);
        purchaseInProgress.Add(new PurchaseProgress(item, value));

        Save();

        ProgressUpdate.Invoke();
    }

    public T GetGameState<T>(string id) where T : GameState
    {
        if (string.IsNullOrEmpty(id))
            return null;

        if (gameStates.ContainsKey(id) && gameStates[id] is T)
            return (T) gameStates[id];

        if (!PlayerPrefs.HasKey(id))
            return null;

        if (gameStates.ContainsKey(id))
            gameStates.Remove(id);

        GameState gameState = JsonUtility.FromJson<T>(PlayerPrefs.GetString(id));
        gameStates.Add(id, gameState);

        return (T) gameState;
    }

    public void SetGameState<T>(string id, T state) where T : GameState
    {
        if (gameStates.ContainsKey(id))
            gameStates[id] = state;
        else
            gameStates.Add(id, state);
    }

    public void SaveGameState(string id)
    {
        if (gameStates.ContainsKey(id))
            PlayerPrefs.SetString(id, JsonUtility.ToJson(gameStates[id]));
    }

    public void Save()
    {
        string progressJson = JsonUtility.ToJson(this);
        PlayerPrefs.SetString("UserProgress", progressJson);
    }
}