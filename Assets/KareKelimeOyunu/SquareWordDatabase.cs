using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[CreateAssetMenu(fileName =("KareKelimeOyunuDatabase"), menuName ="VeriTabani/KareKelime")]
public class SquareWordDatabase : ScriptableObject
{
    public List<Word> words;
    public string kareKelimeOyunuModu;
    public string defaultSohbetAciklama;
    public string defaultDogruSohbetAciklama;

    [System.Serializable]
    public class Word
    {
        public int Size;
        public Letter[] letters;

        public List<CorrectIndex> correctIndexs;

        public Word()
        {
            correctIndexs = new List<CorrectIndex>();
        }
    }

    [System.Serializable]
    public class Letter
    {
        public char text;

        public Letter()
        {
            text = ' ';
        }
    }

    [System.Serializable]
    public class CorrectIndex
    {
        public List<int> indexs;

        public CorrectIndex()
        {
            indexs = new();
        }
    }
}
