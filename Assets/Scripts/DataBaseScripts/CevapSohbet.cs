using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[System.Serializable]
public class CevapSohbet
{
    [TextArea(5, 20)]
    [Tooltip("Cevap varyasyonları sohbetlerin aynı görünmesini engellemek için varladır. Kaç tane varyasyon eklemek istediğinizi girin ardından her birisi aynı anlama gelen tüm varyasyonlar için metinlerinizi oluşturun.")]
    public List<string> cevapVaryasyonlari;

    public Sohbet.ContentImage contentImage;
    [HideInInspector] public Sprite contentPhoto;
    [HideInInspector] public string contentPhotoId = "";
    [HideInInspector] public string gifId;

    public enum contentPhotoLocation { basta = 0, sonda = 1};
    public contentPhotoLocation fotografKonum;

    //Ilerde silinecek
    [HideInInspector] public List<ChatDegiskeni> ayarlanacakDegiskenler;
    //Ilerde silinecek
    [HideInInspector] public List<ChatDegiskeni> secenekDegiskenleri;

    public EnerjiKonsantrasyon gerekenEnerjiKons;
    public EnerjiKonsantrasyon uIEnerjiKonsOverwrite;
    public bool reklamGoster = false;

    public List<Sohbet.AyarlanacakDegisken> ayarlananDegiskenler;
    public List<Sohbet.GerekenDegisken> gerekliDegiskenler;

    [Tooltip("Kullanıcı eğer bu cevabı seçerse sohbetin hangi sohbet havuzu ile devam edeceğini gösterir. Boş kalması algoritmanın karar vereceği anlamına gelir. Bu cevaptan sonra hangi sohbete geçmek istiyorsanız onu işaretleyin.")]
    public Sohbet sonrakiSohbetHavuzu;
    [HideInInspector] public string sonrakiSohbetID;

    [HideInInspector]
    public Sohbet CurrentSonrakiSohbetHavuzu
    {
        get
        {
            if (!string.IsNullOrEmpty(sonrakiSohbetID))
                return System.Array.Find(ModSohbetManager.Instance.onlineSohbetCache, x => x.GetSohbetId().Equals(sonrakiSohbetID));
            else return null;
        }
    }

    //KALDIRILDI
    [Tooltip("Kullanıcı eğer bu cevabı seçerse sohbetin hangi sohbet şeması ile devam edeceğini gösteren değişken. Bu cevaptan sonra hangi sohbete geçmek istiyorsanız onu işaretleyin.")]
    [HideInInspector] public TakipSohbeti takipSohbeti;

    [Tooltip("Ozel fonksiyonar seceneklerin secildiginde on tanimli bazi fonksiyonlarin cagirilmasina yararlar. Kullanici normal sohbette iken bu fonksiyonlar kullanilmaz dogar olarak bu kutucuk bos kalir. Eger bunun ne anlama geldigini bilmiyorsaniz bos" +
        "kalmasi en iyisidir.")]
    public string ozelFonksiyon;

    [System.Serializable]
    public class EnerjiKonsantrasyon
    {
        public int enerji;
        public int kons;

        public EnerjiKonsantrasyon()
        {
            enerji = 0;
            kons = 0;
        }
    }
}
