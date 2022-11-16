using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace AimTrainer
{
    public class Gun : MonoBehaviour
    {
        //private CurrentPlayerData dataObject;

        public Animator gunAnimator;

        public float coolDown;

        private float coolDownTimer;

        private bool coolDownCheck;

        private bool fire;

        public AudioClip[] sounds;

        public GameObject bulletHole;

        public int bullet = 30;
        public int magazine = 300;
        public int magazineCapacity = 30;

        [HideInInspector]
        public int totalUsedBullet, totalHitBullet;

        public Transform gunPivot;

        public float damage = 20;
        public float laserDamage = 2;

        public Text bulletText;

        #region laserFire
        private float laserFireTimer;
        private float laserFireTimerDef = 0.1f;
        private bool laserFireActive = false;
        #endregion

        public bool infinityBullet = true;

        private GameObject[] allGuns;

        ChatManager chatManager;

        // Start is called before the first frame update
        void Start()
        {
            chatManager = GameObject.FindObjectOfType<ChatManager>();

            //dataObject = GameObject.Find("CurrentPlayerData").GetComponent<CurrentPlayerData>();

            laserFireActive = AimTrainer.laserFire;
            damage = AimTrainer.gunDamage;
            laserDamage = AimTrainer.gunLaserDamage;
            infinityBullet = AimTrainer.infinityBullets;

            coolDown = 2f / 60f;

            SetGuns();
        }

        // Update is called once per frame
        void Update()
        {
            FireUpdate();
            OnPc();
            coolDownTimerCheck();
            IfGameHasPaused();
            LaserFire();
        }

        void SetGuns()
        {
            allGuns = new GameObject[transform.childCount];

            for (int i = 0; i < transform.childCount; i++)
            {
                allGuns[i] = transform.GetChild(i).gameObject;
            }

            for (int i = 0; i < allGuns.Length; i++)
            {
                allGuns[i].SetActive(false);
            }

            /*
            for (int i = 0; i < dataObject.datas.weapons.Length; i++)
            {
                if (dataObject.datas.weapons[i] == true)
                {
                    allGuns[i].SetActive(true);
                    break;
                }
            }*/

            //allGuns[dataObject.datas.weapons[]].SetActive(true);

            allGuns[0].SetActive(true);
        }

        void CalculateAccurancy()
        {
            AimTrainer.accurancy = (int)((totalHitBullet / (float)totalUsedBullet) * 100f);
        }

        void IfGameHasPaused()
        {
            if (AimTrainer.pause || AimTrainer.endOfTheGame)
            {
                coolDownCheck = true;
                fire = false;
                coolDownTimer = 0;
                gunAnimator.SetInteger("Fire", 0);
                gunAnimator.speed = 0f;
                gameObject.transform.parent.GetComponent<AudioSource>().Pause();
            }
            else
            {
                gunAnimator.speed = 1f;
                gameObject.transform.parent.GetComponent<AudioSource>().UnPause();
            }
        }

        void FireUpdate()
        {
            if (gunAnimator.GetCurrentAnimatorStateInfo(0).IsName("Fire"))
            {
                if (fire)
                {
                    if (coolDownTimer <= 0 && damage > 0)
                    {
                        fire = false;
                        Fire();
                    }
                }
            }
        }

        void OnPc()
        {
            if (gameObject.transform.parent.GetComponent<CameraLook>().test)
            {
                if (Input.GetMouseButtonDown(0))
                {
                    PressFireButton();
                }

                if ((Input.GetMouseButtonUp(0)) || ((!Input.GetMouseButton(0) && fire == false)))
                {
                    UnPressFireButton();
                }


                if (Input.GetKeyDown(KeyCode.R))
                {
                    Reload();
                }
            }
        }

        IEnumerator FireTrue()
        {
            yield return new WaitForSeconds(gunAnimator.GetCurrentAnimatorStateInfo(0).length);
            fire = true;
        }

        public void coolDownTimerCheck()
        {
            if (coolDownCheck)
            {
                if (gunAnimator.GetCurrentAnimatorStateInfo(0).IsName("CoolDown"))
                {
                    coolDownTimer = coolDown;
                    coolDownCheck = false;
                }
            }

            if (coolDownTimer > 0)
            {
                coolDownTimer -= Time.deltaTime;
            }
            else
            {
                coolDownTimer = 0;
            }
        }

        IEnumerator ReloadDegiskenSifirla()
        {
            yield return new WaitForSeconds(0.1f);
            gunAnimator.SetBool("Reload", false);
        }


        public void PressFireButton()
        {
            if ((bullet > 0 || infinityBullet) && damage > 0)
            {
                if (!AimTrainer.pause && !AimTrainer.endOfTheGame && AimTrainer.start && AimTrainer.startTimer <= 0)
                {
                    if (coolDownTimer <= 0)
                    {
                        fire = true;
                        gunAnimator.SetInteger("Fire", 1);
                    }
                }
            }
        }

        public void UnPressFireButton()
        {
            if (!AimTrainer.pause && !AimTrainer.endOfTheGame && AimTrainer.start && AimTrainer.startTimer <= 0)
            {
                if (!gunAnimator.GetCurrentAnimatorStateInfo(0).IsName("CoolDown"))
                {
                    coolDownCheck = true;
                    gunAnimator.SetInteger("Fire", 0);
                }
            }
        }

        public void Reload()
        {
            if (!AimTrainer.pause && !AimTrainer.endOfTheGame && AimTrainer.start && AimTrainer.startTimer <= 0)
            {
                if (magazine > 0 && !infinityBullet)
                {
                    gunAnimator.SetBool("Reload", true);
                    StartCoroutine(ReloadDegiskenSifirla());
                    gameObject.transform.parent.GetComponent<SoundManager>().PlayAudioClip(sounds[1]);
                    StartCoroutine(reloadDelay());
                }
            }
        }

        IEnumerator reloadDelay()
        {
            yield return new WaitForSeconds(35f / 60f);
            int delta = magazineCapacity - bullet;

            if (magazine - delta >= 0)
            {
                magazine -= delta;
                bullet += delta;
            }
            else
            {
                bullet += magazine;
                magazine = 0;
            }
        }

        void Fire()
        {
            gameObject.transform.parent.GetComponent<SoundManager>().PlayAudioClip(sounds[0]);
            StartCoroutine(FireTrue());

            RaycastHit hit;
            // Does the ray intersect any objects excluding the player layer
            if (Physics.Raycast(GameObject.Find("FPSCamera").transform.position, GameObject.Find("FPSCamera").transform.TransformDirection(Vector3.forward), out hit, Mathf.Infinity))
            {
                if (hit.transform.GetComponent<EnemyHitCollider>() != null)
                {
                    hit.transform.GetComponent<EnemyHitCollider>().ApplyDamageToEnemy(damage);
                    AimTrainer.HitLines = true;
                    gameObject.transform.parent.GetComponent<SoundManager>().PlayAudioClip(sounds[2]);

                    totalHitBullet += 1;

                    float x = Random.Range(0f, 100f);

                    if (x <= chatManager.magNukemSettings.konusmaSansi)
                    {
                        chatManager.PlayerDataManager.AddElementToChatVariableList("mod", chatManager.magNukemSettings.isabetModu);
                        chatManager.ClickAnswerBubble(null, 0, 0, false);
                    }
                }
                else
                {
                    if (AimTrainer.score >= 2)
                        AimTrainer.score -= 10;

                    float x = Random.Range(0f, 100f);

                    if (x <= chatManager.magNukemSettings.konusmaSansi)
                    {
                        chatManager.PlayerDataManager.AddElementToChatVariableList("mod", chatManager.magNukemSettings.iskaModu);
                        chatManager.ClickAnswerBubble(null, 0, 0, false);
                    }
                }

                Instantiate(bulletHole, hit.point, Quaternion.identity);


                bullet -= 1;
                totalUsedBullet += 1;
                CalculateAccurancy();
            }
            else
            {
                if (AimTrainer.score >= 2)
                    AimTrainer.score -= 10;
            }
        }


        //Laser fire shoots always if even player is not pressing the fire button. It is especially using for stay on enemy training.
        void LaserFire()
        {
            if (laserFireActive)
            {
                if (laserFireTimer <= 0f)
                {
                    RaycastHit hit;
                    // Does the ray intersect any objects excluding the player layer
                    if (Physics.Raycast(GameObject.Find("FPSCamera").transform.position, GameObject.Find("FPSCamera").transform.TransformDirection(Vector3.forward), out hit, Mathf.Infinity))
                    {
                        if (hit.transform.GetComponent<EnemyHitCollider>() != null)
                        {
                            hit.transform.GetComponent<EnemyHitCollider>().ApplyDamageToEnemy(laserDamage * Time.deltaTime * 30f);
                            totalHitBullet += 1;
                        }
                    }

                    totalUsedBullet += 1;
                    CalculateAccurancy();
                }
                else
                {
                    laserFireTimer = laserFireTimerDef;
                }
            }
        }
    }
}