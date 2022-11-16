using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;

/// <summary>
/// Uyuglama icinde sadece Chat ekraninda gosterilen bildirimleri yoneten class.
/// 
/// NOT: Uygulamayi degerlendir, yeni surum mevcut ve enerji bildirimleri suan bu classa
/// bagli degil. En kisa zamanda bu classa alinacak!!!
/// </summary>
public class InAppNotifications : MonoBehaviour
{
    /// <summary>
    /// Bildirimin UI Recttransform komponenti
    /// </summary>
    public RectTransform notifRect;

    /// <summary>
    /// Bildirimin text komponenti
    /// </summary>
    public TMPro.TMP_Text text;

    /// <summary>
    /// Eger chatScreen aktif degilse yani kullanici chatte degilse bildirim dusmemeli.
    /// bu kontrolu yapmak icin bu degisken kullanilir.
    /// </summary>
    private ChatScreenActivity chatScreenActivity;

    /// <summary>
    /// Kullanici kayitlari
    /// </summary>
    private CurrentPlayerData playerData;

    private void Awake()
    {
        chatScreenActivity = GetComponent<ChatScreenActivity>();
        playerData = FindObjectOfType<CurrentPlayerData>();
    }

    /// <summary>
    /// Firebase baslayip giris islemini sonlandirdigi
    /// anda calismasi gereken fonksiyondur.
    /// </summary>
    public void StartEvent()
    {
        FalHazirBildirimKontrol();
    }
    
    /// <summary>
    /// Son fallardaki hazir olmayan fallari kontrol eder ve gereken icin in app bildirim kurar.
    /// </summary>
    private void FalHazirBildirimKontrol()
    {
        var son5Metin = playerData.localPlayerDatas.renderedTexts.Find(x => x.name.Equals("son5Metin"));

        if (son5Metin != null)
        {
            RenderedText.Text minDelayText = null;
            foreach (RenderedText.Text text in son5Metin.renderedTexts)
            {
                if (text.uIInformation.showTimeStamp > 0 &&
                    text.uIInformation.showTimeStamp > Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now))
                {
                    if (minDelayText != null)
                    {
                        if (minDelayText.uIInformation.showTimeStamp > text.uIInformation.showTimeStamp)
                            minDelayText = text;
                    }
                    else
                    {
                        minDelayText = text;
                    }
                }
            }

            if (minDelayText != null)
            {
                int seconds = (int)(minDelayText.uIInformation.showTimeStamp - Magnus.Time.DateTimeOperations.DateTimeToUnixTimeStamp(System.DateTime.Now));

                if (seconds > 0)
                {
                    SetNotification($"{minDelayText.uIInformation.title} hazır!", seconds);
                }
            }
        }
    }

    void Update()
    {
        
    }

    /// <summary>
    /// Belirtilen text ve delay icin in app bildirim kurar
    /// </summary>
    /// <param name="text">Bildirim texti</param>
    /// <param name="delay">Saniye cinsinden delay</param>
    public void SetNotification(string text, int delay)
    {
        var chatScreen = FindObjectOfType<ChatScreenActivity>();

        this.text.text = text;

        if (notificationEnumerator != null)
        {
            StopCoroutine(notificationEnumerator);
            notificationEnumerator = null;
        }
        notificationEnumerator = NotificationEnumerator(delay);
        StartCoroutine(notificationEnumerator);
    }

    private IEnumerator notificationEnumerator;
    /// <summary>
    /// Notification'in gecikmeli olarak yurutulmesini saglar
    /// </summary>
    /// <param name="delay">Saniye cinsinden delay</param>
    private IEnumerator NotificationEnumerator(int delay)
    {
        yield return new WaitForSeconds(delay);

        if (chatScreenActivity.isChatScreenActive)
        {
            notifRect.DOAnchorPosY(-140, 0.4f);

            yield return new WaitForSeconds(5f);
            notifRect.DOAnchorPosY(140, 0.5f);

            notificationEnumerator = null;
        }

        if (chatScreenActivity.topMenuNotifAnimationEnumerator != null)
            StopCoroutine(chatScreenActivity.topMenuNotifAnimationEnumerator);

        chatScreenActivity.topMenuNotifAnimationEnumerator = chatScreenActivity.TopMenuNotifAnimationEnumerator();
        StartCoroutine(chatScreenActivity.topMenuNotifAnimationEnumerator);

        FalHazirBildirimKontrol();
    }
}
