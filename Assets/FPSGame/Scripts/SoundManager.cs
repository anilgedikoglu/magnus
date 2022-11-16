using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AimTrainer
{
    public class SoundManager : MonoBehaviour
    {
        public AudioSource[] sources;
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        public void PlayAudioClip(AudioClip clip)
        {
            for (int i = 0; i < sources.Length; i++)
            {
                if (sources[i].isPlaying)
                {
                    if (sources[i].clip == clip)
                    {
                        sources[i].clip = clip;
                        sources[i].Play();
                        break;
                    }
                }
                else
                {
                    sources[i].clip = clip;
                    sources[i].Play();
                    break;
                }
            }
        }
    }
}
