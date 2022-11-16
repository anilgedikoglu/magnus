using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
//[CreateAssetMenu(fileName = "SohbetHavuzu 1", menuName = "Veri Tabani/Takip Sohbeti Olustur")]
public class TakipSohbeti : ScriptableObject
{
    [HideInInspector]
    public string id = System.Guid.NewGuid().ToString();

    public Sprite contentPhoto;
    public enum contentPhotoLocation { ayriBalonSONDA = 0, ayriBalonBASTA = 1, balonunIcindeSONDA = 2, balonunIcindeBASTA = 3 }
    public contentPhotoLocation fotografKonumu;

    [Header("Genel")]
    [Tooltip("Açıklamalar yapayzekanın yazacağı baloncuklardır. Her farkli varyasyon icin yeni bir aciklama ekleyebilirisiniz. Bunlar temelinde ayni şeyi ifade etmelidir.")]
    [TextArea(5, 20)]
    public string[] aciklama = new string[0];

    [Tooltip("Bu değişken sadece bu takip sohbet son takip sohbetse ve herhangi bir seçenek tanımlanmadıysa, yani bir sohbetten çıkış mesajı ise, takip sohbet metninin gösterilme şansını" +
        " belirtir.")]
    public int gostermeSansi = 100;

    [Tooltip("Cevaplar kullanıcının karşısına gelecek tüm cevap butonlarını temsil eder. Kaç farklı cevap oluşturursanız o kadar buton gelir. Cevaplar cevap varyasyonlarından farklıdır.")]
    public CevapSohbet[] cevaplar = new CevapSohbet[0];

    public ChatDegiskeni[] gerekenDegiskenler;

    public enum sohbetTekrarlama { surekli = 0, sonrakiAcilista = 1, sonrakiGun = 2, unutunca = 3, tekSefer = 4 }
    public sohbetTekrarlama tekrarlama;

    public bool sohbetBititmindeAnamenuyeDon = true;
    public bool anaMenuyeGitButonuOlustur = true;
}
