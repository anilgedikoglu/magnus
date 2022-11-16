using UnityEngine;
using UnityEngine.Advertisements;

public class GameOverAds : MonoBehaviour
{
    
    void OnEnable()
    {
        if (UserProgress.Current.IsItemPurchased("no_ads"))
            return;

        //if (Advertisement.IsReady(PlacementId.Video))
         //   Advertisement.Show(PlacementId.Video);
    }
}
