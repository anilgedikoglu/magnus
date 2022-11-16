using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "QuizEditorObject", menuName = "Magnus/QuizEditorObject")]
public class QuizEditorDataType : ScriptableObject
{
    [TextArea(5, 20)]
    [SerializeField] public List<string> bilgiYarismasiAciklama;
    [SerializeField] public List<BilgiYarismasiCevap> cevaplar;
    public Sohbet ustMenu;
}

[System.Serializable]
public class BilgiYarismasiCevap
{
    [TextArea(5, 20)]
    public string cevap;
    public bool dogruCevap;

}