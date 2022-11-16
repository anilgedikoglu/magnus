using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(MagnuTrisSettings))]
public class MagnuTrisSettingsEditor : Editor
{
    MagnuTrisSettings settings;

    Texture2D[] shapeTextures;
    
    private void OnEnable()
    {
        settings = (MagnuTrisSettings)target;

        shapeTextures = Resources.LoadAll<Texture2D>("EditorShapeLogos");

        if (settings.sekiller == null || settings.sekiller.Length != shapeTextures.Length)
        {
            settings.sekiller = new string[shapeTextures.Length];
        }

        EditorUtility.SetDirty(settings);
    }

    public override void OnInspectorGUI() 
    {
        settings.genelMod = EditorGUILayout.TextField("Genel Mod", settings.genelMod);
        settings.cikisModu = EditorGUILayout.TextField("Çıkış Modu", settings.cikisModu);
        settings.enYuksekSkorGecildiModu = EditorGUILayout.TextField("Magnutris en yüksek skor geçildi", settings.enYuksekSkorGecildiModu);
        settings.enYuksekSkorGecilmediModu = EditorGUILayout.TextField("Magnutris en yüksek skor geçilmedi", settings.enYuksekSkorGecilmediModu);
        settings.yokEdilenSatir1= EditorGUILayout.TextField("1 Satır Yok Etme Modu", settings.yokEdilenSatir1);
        settings.yokEdilenSatir2 = EditorGUILayout.TextField("2 Satır Yok Etme Modu", settings.yokEdilenSatir2);
        settings.yokEdilenSatir3 = EditorGUILayout.TextField("3 Satır Yok Etme Modu", settings.yokEdilenSatir3);
        settings.yokEdilenSatir4 = EditorGUILayout.TextField("4 Satır Yok Etme Modu", settings.yokEdilenSatir4);
        settings.yokEdilenSatirFazla = EditorGUILayout.TextField("4 Satırdan Fazla Yok Etme Modu", settings.yokEdilenSatirFazla);
        settings.bombaYerlestirme = EditorGUILayout.TextField("Bomba yerleştirme modu", settings.bombaYerlestirme);

        EditorGUILayout.Space(15);
        EditorGUILayout.HelpBox("Aşağıdaki bir mod değeri değil \"değişken adı\" değeridir. Oyun bitiminde gösterilecek oyun bitiş nedeni bu değişkenin içne kaydedilir.", MessageType.Info);
        EditorGUILayout.LabelField("Değişken adı");
        settings.oyunSonuMesajiDegiskenAdi = EditorGUILayout.TextField("Oyun sonu mesajı değişken adı", settings.oyunSonuMesajiDegiskenAdi);
        EditorGUILayout.Space(5);
        EditorGUILayout.LabelField("Değişken değerleri");
        settings.oyunSonuMesajiHamleKalmadi = EditorGUILayout.TextField("Oyun sonu mesajı hamle kalmadı", settings.oyunSonuMesajiHamleKalmadi);
        settings.oyunSonuMesajiSureDoldu = EditorGUILayout.TextField("Oyun sonu mesajı süre doldu", settings.oyunSonuMesajiSureDoldu);
        settings.oyunSonuMesajiBombaPatladi = EditorGUILayout.TextField("Oyun sonu mesajı bomba patladı", settings.oyunSonuMesajiBombaPatladi);

        EditorGUILayout.Space(15);
        for (int i = 0; i < shapeTextures.Length; i++)
        {
            if (settings.sekiller.Length == shapeTextures.Length)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Label(shapeTextures[i], GUILayout.Width(50), GUILayout.Height(50));
                EditorGUILayout.LabelField("<= Şeklinin Yerleştirilme Modu", GUILayout.Width(180));
                settings.sekiller[i] = EditorGUILayout.TextField(settings.sekiller[i]);
                EditorGUILayout.EndHorizontal();
            }
            else
            {
                //Sekiller stringi ile bulunan fotoğraflar uyuşmadığında kaşılaşılacak hata. Bu durumda sekkiler stringi baştan tanımlanır.
                EditorGUILayout.HelpBox("MagnuTrisSettingsEditor classında hata meydana geldi.", MessageType.Error);
            }
        }
    }
}
