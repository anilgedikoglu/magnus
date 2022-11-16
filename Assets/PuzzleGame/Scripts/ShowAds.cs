using UnityEngine;
using UnityEngine.Advertisements;

public class ShowAds : MonoBehaviour
{
    public float interval = 30f;

    static float lastAdsTime;
    
    public void Show()
    {

        if (UserProgress.Current.IsItemPurchased("no_ads"))
            return;

        /*
        if (Time.unscaledTime - lastAdsTime < interval || !Advertisement.IsReady(PlacementId.Video))
            return;*/

        lastAdsTime = Time.unscaledTime;
        //Advertisement.Show(PlacementId.Video);
    }
}
