using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using GoogleMobileAds.Api;

public class AdManager : MonoBehaviour
{
    private CurrentPlayerData playerData;

    private BannerView bannerView;
    private InterstitialAd interstitial;
    private RewardedAd rewardedAd;

    public string androidAppId;
    public string IOSAppId;

    public AdId bannerId;
    public AdId interstitialId;
    public AdId rewardedId;

    public enum Version { release, test};
    public Version version;

    public EnergyManager energyBar;
    public EnergyManager konsantrasyonBar;

    public RewardItem rewardItem;

    public float backendRequestDuration = 5f;
    private float requestTimer;

    private void Awake()
    {
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    private void Start()
    {
        RequestInterstitial();
        RequestRewardedAd();
        //ShowInter();
    }

    private void Update()
    {
        RequestTimerUpdate();
    }

    private void RequestTimerUpdate()
    {
        if (requestTimer > 0)
        {
            requestTimer -= Time.deltaTime;
        }
        else
        {
            RequestAds();
            requestTimer = backendRequestDuration * 60f;
        }
    }

    private void RequestAds()
    {
        if (rewardedAd != null)
        {
            if (!rewardedAd.IsLoaded())
            {
                RequestRewardedAd();
            }
        }
        else
        {
            RequestRewardedAd();
        }

        if (interstitial != null)
        {
            if (!interstitial.IsLoaded())
            {
                RequestInterstitial();
            }
        }
        else
        {
            RequestInterstitial();
        }
    }

    public void ResetTimer()
    {
        requestTimer = 0;
    }

    public void RequestRewardedAd() 
    {
        if (rewardedAd != null)
        {
            DestroyRewarded();
            Debug.Log("Önceden kalan bir ödüllü reklam bulundu. Yeni istekten önce <color=red><b>reklam siliniyor...</b></color>");
        }
        else
        {
            //Yukarıdaki  DestroyRewarded() işlemi zaten bu fonksiyonu barındırıyor.
            playerData.AddElementToChatVariableList("odul reklami", "yok", false);
        }

        Debug.Log("Ödül reklamı için istek oluşturuluyor...");

#if UNITY_ANDROID
        string adUnitId;
        if (version == Version.test)
        {
            adUnitId = rewardedId.test;
        }
        else
        {
            adUnitId = rewardedId.android;
        }
#elif UNITY_IPHONE
        string adUnitId;
        if (version == Version.test)
        {
            adUnitId = rewardedId.test;
        }
        else
        {
            adUnitId = rewardedId.ios;
        }
#else
        string adUnitId = "unexpected_platform";
#endif
        this.rewardedAd = new RewardedAd(adUnitId);

        // Called when an ad request has successfully loaded.
        this.rewardedAd.OnAdLoaded += HandleRewardedAdLoaded;
        // Called when an ad request failed to load.
        this.rewardedAd.OnAdFailedToLoad += HandleRewardedAdFailedToLoad;
        // Called when an ad is shown.
        this.rewardedAd.OnAdOpening += HandleRewardedAdOpening;
        // Called when an ad request failed to show.
        this.rewardedAd.OnAdFailedToShow += HandleRewardedAdFailedToShow;
        // Called when the user should be rewarded for interacting with the ad.
        this.rewardedAd.OnUserEarnedReward += HandleUserEarnedReward;
        // Called when the ad is closed.
        this.rewardedAd.OnAdClosed += HandleRewardedAdClosed;

        // Create an empty ad request.
        AdRequest request = new AdRequest.Builder().Build();
        // Load the rewarded ad with the request.
        this.rewardedAd.LoadAd(request);
    }

    public void HandleRewardedAdLoaded(object sender, EventArgs args)
    {
        Debug.Log("Ödül reklamı <color=green>başarıyla</color> yüklendi");
        playerData.AddElementToChatVariableList("odul reklami", "var", false);
    }

    public void HandleRewardedAdFailedToLoad(object sender, AdFailedToLoadEventArgs args)
    {
        Debug.Log("Ödül reklamı yüklenirken <color=red>hata</color> meydana geldi. Reklam siliniyor. Bir sonraki kontrolde tekrar denenecek. Sonraki kontrole: " + (requestTimer).ToString() + " saniye var");
        DestroyRewarded();
    }

    public void HandleRewardedAdOpening(object sender, EventArgs args)
    {
        Debug.Log("Ödül reklamı açıldı.");
        Time.timeScale = 0;
    }

    public void HandleRewardedAdFailedToShow(object sender, AdErrorEventArgs args)
    {
        Debug.Log("Ödül reklamı gösterilirken hata meydana geldi");
    }

    public void HandleRewardedAdClosed(object sender, EventArgs args)
    {
        Debug.Log("Ödül reklamı kapatıldı");
        Time.timeScale = 1;
    }

    public void HandleUserEarnedReward(object sender, Reward args)
    {
        onEarnedReward?.Invoke();
    }

    public delegate void OnEarnedReward();
    private OnEarnedReward onEarnedReward;
    public void ShowRewarded(OnEarnedReward onEarnedReward)
    {
        Debug.Log("Ödül reklamı gösteriliyor...");

        this.onEarnedReward = onEarnedReward;
        this.onEarnedReward += BaseEarnedEvent;

        rewardedAd.Show();
    }

    public void DestroyRewarded()
    {
        Debug.Log("Ödül reklamı silindi");
        playerData.AddElementToChatVariableList("odul reklami", "yok", false);
        rewardedAd.Destroy();
    }

    public void LoadRewarded()
    {
        RequestRewardedAd();
    }

    public void UserEarnedEnergyKons()
    {
        Debug.Log("Kullanıcı ödül relamını baştan sonz izledi. <color=orange><b>$$$</b></color>");
        Debug.Log($"Kullanıcı {rewardItem.amount} birim {rewardItem.item} ile ödüllendirildi!");

        if (rewardItem.item == RewardItem.Item.energy)
        {
            energyBar.AddEnergy(rewardItem.amount, 0);
        }
        else if (rewardItem.item == RewardItem.Item.konsantrasyon)
        {
            //konsantrasyonBar.AddEnergy(0, rewardItem.amount);
        }

        var chatmanager = FindObjectOfType<ChatManager>();

        if (chatmanager != null)
            if (!string.IsNullOrEmpty(chatmanager.reklamSonuModu))
            {
                chatmanager.ClickVirtualButton(chatmanager.reklamSonuModu);

                var bugunGelenData = chatmanager.PlayerDataManager.datas.bugunGelenMods.Find(x => x.mod.Equals(chatmanager.reklamSonuModu));
                var bugunGelen = chatmanager.magnusPreferences.gunlukModlar.Find(x => x.mod.Equals(chatmanager.reklamSonuModu));

                if(bugunGelen != null)
                {
                    if(bugunGelenData != null)
                    {
                        bugunGelenData.count++;
                    }
                    else
                    {
                        chatmanager.PlayerDataManager.datas.bugunGelenMods.Add(new PlayerData.BugunGelenMod(chatmanager.reklamSonuModu, 1));
                    }
                }

                chatmanager.energyBarManager.AddEnergy(-chatmanager.reklamSonuAzalacakEnerji, 0);
                //chatmanager.konsantrasyonBarManager.AddEnergy(0, -chatmanager.reklamSonuAzalacakKons);
            }
    }

    public void FreeEnergyButton()
    {
        ShowRewarded(() => {
            energyBar.AddEnergy(1, 0);
        });
    }

    private void BaseEarnedEvent()
    {
        Debug.Log($"Reklam başarılı bir şekilde gösterildiği için reklam siliniyor ve yeni bir" +
            $" istek oluşturuluyor...");
        DestroyRewarded();

        RequestRewardedAd();

        //Bir sonraki framede bu ve boş olan diğer reklam isteklerinin baştan oluşturulması için
        //Timerı sıfırlıyoruz. Çakışma olmaması için direkt yeni request atmek yerine
        //böyle yapıldı.
        ResetTimer();
        Time.timeScale = 1;
    }

    private void RequestInterstitial()
    {
        if (rewardedAd != null)
        {
            DestroyInterstitial();
            Debug.Log("Önceden kalan bir geçiş reklamı bulundu. Yeni istekten önce <color=red><b>reklam siliniyor...</b></color>");
        }
        else
        {
            //Yukarıdaki  DestroyInterstitial() işlemi zaten bu fonksiyonu barındırıyor.
            playerData.AddElementToChatVariableList("gecis reklami", "yok", false);
        }

        Debug.Log("Geçiş reklamı için istek oluşturuluyor...");

#if UNITY_ANDROID
        string adUnitId;
        if (version == Version.test)
        {
            adUnitId = interstitialId.test;
        }
        else
        {
            adUnitId = interstitialId.android;
        }
#elif UNITY_IPHONE
        string adUnitId;
        if (version == Version.test)
        {
            adUnitId = interstitialId.test;
        }
        else
        {
            adUnitId = interstitialId.ios;
        }
#else
        string adUnitId = "unexpected_platform";
#endif

        // Initialize an InterstitialAd.
        this.interstitial = new InterstitialAd(adUnitId);
        // Create an empty ad request.

        // Called when an ad request has successfully loaded.
        this.interstitial.OnAdLoaded += HandleOnIntAdLoaded;
        // Called when an ad request failed to load.
        this.interstitial.OnAdFailedToLoad += HandleOnIntAdFailedToLoad;
        // Called when an ad is shown.
        this.interstitial.OnAdOpening += HandleOnIntAdOpened;
        // Called when the ad is closed.
        this.interstitial.OnAdClosed += HandleOnIntAdClosed;

        AdRequest request = new AdRequest.Builder().Build();
        // Load the interstitial with the request.
        this.interstitial.LoadAd(request);
    }

    public void HandleOnIntAdLoaded(object sender, EventArgs args)
    {
        Debug.Log("Geçiş reklamı <color=green>başarıyla</color> yüklendi");
        playerData.AddElementToChatVariableList("gecis reklami", "var", false);
    }

    public void HandleOnIntAdFailedToLoad(object sender, AdFailedToLoadEventArgs args)
    {
        Debug.Log("Geçiş reklamı yüklenirken <color=red>hata</color> meydana geldi. Reklam siliniyor. Bir sonraki kontrolde tekrar denenecek. Sonraki kontrole: " + (requestTimer).ToString() + " saniye var");
        DestroyInterstitial();
    }

    public void HandleOnIntAdOpened(object sender, EventArgs args)
    {
        Debug.Log("Geçiş reklamı açıldı.");
        Time.timeScale = 0;
    }

    public void HandleOnIntAdClosed(object sender, EventArgs args)
    {
        Debug.Log("Geçiş reklamı kapatıldı.");
        RequestInterstitial();
        Time.timeScale = 1;
        //RequestInterstitial();
    }

    public void ShowInterstitial()
    {
        Debug.Log("Geçiş reklamı gösteriliyor...");
        interstitial.Show();
    }

    public void DestroyInterstitial()
    {
        Debug.Log("Geçiş reklamı silindi");
        playerData.AddElementToChatVariableList("gecis reklami", "yok", false);
        interstitial.Destroy();
    }

    private void RequestBanner()
    {
#if UNITY_ANDROID
        string adUnitId;
        if (version == Version.test)
        {
            adUnitId = bannerId.test;
        }
        else
        {
            adUnitId = bannerId.android;
        }
#elif UNITY_IPHONE
        string adUnitId;
        if (version == Version.test)
        {
            adUnitId = bannerId.test;
        }
        else
        {
            adUnitId = bannerId.ios;
        }
#else
        string adUnitId = "unexpected_platform";
#endif

        // Create a 320x50 banner at the top of the screen.
        this.bannerView = new BannerView(adUnitId, AdSize.Banner, AdPosition.Bottom);

        // Called when an ad request has successfully loaded.
        this.bannerView.OnAdLoaded += this.HandleOnAdLoaded;
        // Called when an ad request failed to load.
        this.bannerView.OnAdFailedToLoad += this.HandleOnAdFailedToLoad;
        // Called when an ad is clicked.
        this.bannerView.OnAdOpening += this.HandleOnAdOpened;
        // Called when the user returned from the app after an ad click.
        this.bannerView.OnAdClosed += this.HandleOnAdClosed;

        // Called when the ad click caused the user to leave the application.
        //this.bannerView.o += this.HandleOnAdLeavingApplication; çalışmıyor ama salla ya

        // Create an empty ad request.
        AdRequest request = new AdRequest.Builder().Build();

        // Load the banner with the request.
        bannerView.LoadAd(request);
    }

    public void HandleOnAdLoaded(object sender, EventArgs args)
    {

    }

    public void HandleOnAdFailedToLoad(object sender, AdFailedToLoadEventArgs args)
    {

    }

    public void HandleOnAdOpened(object sender, EventArgs args)
    {
    }

    public void HandleOnAdClosed(object sender, EventArgs args)
    {
        //RequestBanner();
    }

    public void HandleOnAdLeavingApplication(object sender, EventArgs args)
    {
   
    }

    public void ShowBanner()
    {
        bannerView.Show();
    }

    public void LoadBanner()
    {
        RequestBanner();
    }

    public void DestroyBanner()
    {
        bannerView.Destroy();
    }

    [System.Serializable]
    public class AdId
    {
        public string android;
        public string ios;
        public string test;

        public AdId()
        {
            android = string.Empty;
            ios = string.Empty;
            test = string.Empty;
        }

        public AdId(string android, string ios, string test)
        {
            this.android = android;
            this.ios = ios;
            this.test = test;
        }
    }

    [System.Serializable]
    public class RewardItem
    {
        public int amount;
        public enum Item
        {
            energy,
            konsantrasyon
        }
        public Item item;

        public RewardItem(Item item, int amount)
        {
            this.item = item;
            this.amount = amount;
        }

        public RewardItem()
        {
            item = new Item();
            amount = 0;
        }
    }
}