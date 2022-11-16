using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Purchasing;
using UnityEngine.UI;

public class IAPManager : MonoBehaviour
{
    IStoreController m_Controller;
    IAppleExtensions m_AppleExtensions;

    CurrentPlayerData playerData;

    //Products Subs
    public string plus1Ay;
    public string plus3Ay;
    public string plus1Yil;
    public string plus3AyV2;
    public string plus1YilV2;

    //Products Consumable Energy
    public string energyTier1;
    public string energyTier2;
    public string energyTier3;

    //Products Consumable Kons
    public string konsTier1;
    public string konsTier2;
    public string konsTier3;

    public Text debugText;

    private void Awake()
    {
        playerData = FindObjectOfType<CurrentPlayerData>();
        Debug.text = debugText;
    }

    public void OnPurchase(Product product)
    {
        m_AppleExtensions = CodelessIAPStoreListener.Instance.GetStoreExtensions<IAppleExtensions>();

        if (product.definition.id == plus1Ay)
        {
            if (StandardPurchasingModule.Instance().appStore != AppStore.fake)
            {
                Dictionary<string, string> introductory_info_dict = m_AppleExtensions.GetIntroductoryPriceDictionary();
                string intro_json = (introductory_info_dict == null || !introductory_info_dict.ContainsKey(product.definition.storeSpecificId)) ?
                    null : introductory_info_dict[product.definition.storeSpecificId];

                SubscriptionManager p = new SubscriptionManager(product, intro_json);
                SubscriptionInfo info = p.getSubscriptionInfo();

                playerData.datas.plusExpireDateFromStore = new PlayerData.Date(info.getExpireDate());
                playerData.AddElementToChatVariableList("plus", "var");
                Debug.Log("1 aylık plus üyelik satın alındı!");
            }
            else
            {
                playerData.datas.plusExpireDateFromStore = new PlayerData.Date(System.DateTime.Now.AddMonths(1));
                playerData.AddElementToChatVariableList("plus", "var");
                Debug.Log("Fake store abonelik satın alımlarını desteklemez. Fakat yine de 1 aylık plus üyelik tanımlandı!");
            }
        }
        else if (product.definition.id == plus3Ay || product.definition.id == plus3AyV2)
        {
            if (StandardPurchasingModule.Instance().appStore != AppStore.fake)
            {
                Dictionary<string, string> introductory_info_dict = m_AppleExtensions.GetIntroductoryPriceDictionary();
                string intro_json = (introductory_info_dict == null || !introductory_info_dict.ContainsKey(product.definition.storeSpecificId)) ? 
                    null : introductory_info_dict[product.definition.storeSpecificId];

                SubscriptionManager p = new SubscriptionManager(product, intro_json);
                SubscriptionInfo info = p.getSubscriptionInfo();

                playerData.datas.plusExpireDateFromStore = new PlayerData.Date(info.getExpireDate());
                playerData.AddElementToChatVariableList("plus", "var");
                Debug.Log("3 aylık plus üyelik satın alındı!");
            }
            else
            {
                playerData.datas.plusExpireDateFromStore = new PlayerData.Date(System.DateTime.Now.AddMonths(3));
                playerData.AddElementToChatVariableList("plus", "var");
                Debug.Log("Fake store abonelik satın alımlarını desteklemez. Fakat yine de 3 aylık plus üyelik tanımlandı!");
            }
        }
        else if (product.definition.id == plus1Yil || product.definition.id == plus1YilV2)
        {
            if (StandardPurchasingModule.Instance().appStore != AppStore.fake)
            {
                Dictionary<string, string> introductory_info_dict = m_AppleExtensions.GetIntroductoryPriceDictionary();
                string intro_json = (introductory_info_dict == null || !introductory_info_dict.ContainsKey(product.definition.storeSpecificId)) ? 
                    null : introductory_info_dict[product.definition.storeSpecificId];

                SubscriptionManager p = new SubscriptionManager(product, intro_json);
                SubscriptionInfo info = p.getSubscriptionInfo();

                playerData.datas.plusExpireDateFromStore = new PlayerData.Date(info.getExpireDate());
                playerData.AddElementToChatVariableList("plus", "var");
                Debug.Log("1 yıllık plus üyelik satın alındı!");
            }
            else
            {
                playerData.datas.plusExpireDateFromStore = new PlayerData.Date(System.DateTime.Now.AddYears(1));
                playerData.AddElementToChatVariableList("plus", "var");
                Debug.Log("Fake store abonelik satın alımlarını desteklemez. Fakat yine de 1 yıllık plus üyelik tanımlandı!");
            }
        }
        else if (product.definition.id == energyTier1)
        {
            playerData.datas.energy += 1;
            Debug.Log("1 enerji satın alındı!");
        }
        else if (product.definition.id == energyTier2)
        {
            playerData.datas.energy += 3;
            Debug.Log("3 enerji satın alındı!");
        }
        else if (product.definition.id == energyTier3)
        {
            playerData.datas.energy += 10;
            Debug.Log("10 enerji satın alındı!");
        }
        else if (product.definition.id == konsTier1)
        {
            playerData.datas.konsantrasyon += 1;
            Debug.Log("1 konsantrasyon satın alındı!");
        }
        else if (product.definition.id == konsTier2)
        {
            playerData.datas.konsantrasyon += 3;
            Debug.Log("3 konsantrasyon satın alındı!");
        }
        else if (product.definition.id == konsTier3)
        {
            playerData.datas.konsantrasyon += 10;
            Debug.Log("10 konsantrasyon satın alındı!");
        }

        FindObjectOfType<IntroManager>().CheckPlus(false);

        //Online bir satın alım yapıldıktan hemen sonra datalar onlineye atılır.
        playerData.SendDataOnline();
    }

     public void Restore()
    {
        if (Application.platform == RuntimePlatform.WSAPlayerX86 ||
            Application.platform == RuntimePlatform.WSAPlayerX64 ||
            Application.platform == RuntimePlatform.WSAPlayerARM)
        {
            CodelessIAPStoreListener.Instance.GetStoreExtensions<IMicrosoftExtensions>()
                .RestoreTransactions();
        }
        else if (Application.platform == RuntimePlatform.IPhonePlayer ||
                 Application.platform == RuntimePlatform.OSXPlayer ||
                 Application.platform == RuntimePlatform.tvOS)
        {
            CodelessIAPStoreListener.Instance.GetStoreExtensions<IAppleExtensions>()
                .RestoreTransactions(OnTransactionsRestored);
        }
        else if (Application.platform == RuntimePlatform.Android &&
            StandardPurchasingModule.Instance().appStore == AppStore.GooglePlay)
        {
            CodelessIAPStoreListener.Instance.GetStoreExtensions<IGooglePlayStoreExtensions>()
                .RestoreTransactions(OnTransactionsRestored);
        }
        else
        {
            Debug.LogWarning(Application.platform.ToString() +
                             " is not a supported platform for the Codeless IAP restore button");
        }
    }

    void OnTransactionsRestored(bool success)
    {
        if (success)
        {
            Debug.Log("<color=green><b>RESTORE: </b></color>İşlem başarılı. Ürünler tekrar çağrılıyor.");

            Product product1AyPlus = CodelessIAPStoreListener.Instance.GetProduct(plus1Ay);
            RestoreProduct(product1AyPlus);

            Product product3AyPlus = CodelessIAPStoreListener.Instance.GetProduct(plus3Ay);
            RestoreProduct(product3AyPlus);

            Product product3AyPlusV2 = CodelessIAPStoreListener.Instance.GetProduct(plus3AyV2);
            RestoreProduct(product3AyPlusV2);

            Product product1YilPlus = CodelessIAPStoreListener.Instance.GetProduct(plus1Yil);
            RestoreProduct(product1YilPlus);

            Product product1YilPlusV2 = CodelessIAPStoreListener.Instance.GetProduct(plus1YilV2);
            RestoreProduct(product1YilPlusV2);

            FindObjectOfType<IntroManager>().CheckPlus(false);
        }
        else
        {
            Debug.Log("<color=red><b>RESTORE: </b></color>İşlem başarısız!");
        }
    }


    private bool RestoreProduct(Product product)
    {
        if (product != null)
        {
            if (product.hasReceipt)
            {
                if (product.definition.type == ProductType.Subscription)
                {
                    m_AppleExtensions = CodelessIAPStoreListener.Instance.GetStoreExtensions<IAppleExtensions>();

                    Dictionary<string, string> introductory_info_dict = m_AppleExtensions.GetIntroductoryPriceDictionary();
                    string intro_json = (introductory_info_dict == null || !introductory_info_dict.ContainsKey(product.definition.storeSpecificId)) ? 
                        null : introductory_info_dict[product.definition.storeSpecificId];

                    SubscriptionManager p = new SubscriptionManager(product, intro_json);
                    SubscriptionInfo info = p.getSubscriptionInfo();

                    Debug.Log("product id is: " + info.getProductId());
                    Debug.Log("purchase date is: " + info.getPurchaseDate());
                    Debug.Log("subscription next billing date is: " + info.getExpireDate());
                    Debug.Log("is subscribed? " + info.isSubscribed().ToString());
                    Debug.Log("is expired? " + info.isExpired().ToString());
                    Debug.Log("is cancelled? " + info.isCancelled());
                    Debug.Log("product is in free trial peroid? " + info.isFreeTrial());
                    Debug.Log("product is auto renewing? " + info.isAutoRenewing());
                    Debug.Log("subscription remaining valid time until next billing date is: " + info.getRemainingTime());
                    Debug.Log("is this product in introductory price period? " + info.isIntroductoryPricePeriod());
                    Debug.Log("the product introductory localized price is: " + info.getIntroductoryPrice());
                    Debug.Log("the product introductory price period is: " + info.getIntroductoryPricePeriod());
                    Debug.Log("the number of product introductory price period cycles is: " + info.getIntroductoryPricePeriodCycles());
                    playerData.datas.plusExpireDateFromStore = new PlayerData.Date(info.getExpireDate());

                    if((info.getExpireDate() - System.DateTime.Now).TotalSeconds > 0)
                    {
                        return true;
                    }
                    else
                    {
                        return false;
                    }
                }
                else
                {
                    Debug.Log("<color=red><b>RESTORE: </b></color>Bu ürün Restore edilebilecek bir ürün değil!");
                    return false;
                }
            }
            else
            {
                Debug.Log("<color=red><b>RESTORE: </b></color>Ürün restore edilemiyor!");
                return false;
            }
        }
        else
        {
            Debug.Log("<color=red><b>RESTORE: </b></color>Ürün null!");
            return false;
        }
    }


    public static class Debug
    {
        public static Text text;

        public static void Log(string value)
        {
            UnityEngine.Debug.Log(value);
            text.text = "\n" + value + text.text;
        }

        public static void LogWarning(string value)
        {
            UnityEngine.Debug.LogWarning(value);
            text.text =  "\n<color=orange><b>WARNING: " + value + "</b></color>" + text.text;
        }

        public static void LogError(string value)
        {
            UnityEngine.Debug.LogError(value);
            text.text = "\n<color=red><b>ERROR: " + value + "</b></color>" + text.text;
        }
    }
}
