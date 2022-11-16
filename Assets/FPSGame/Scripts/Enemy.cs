using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace AimTrainer
{
    public class Enemy : MonoBehaviour
    {
        //******  General  ******
        public float health;
        private float firstHealth;
        private bool dead;
        private float lifeTime;

        //******  Movement  ******
        private GameObject positionWall;
        private float destinyTimer;
        private float movementXSpeed, movementYSpeed;
        private float movementXDir, movementYDir;
        public bool xAxis, yAxis;
        public bool canChangeRotation;
        private bool checkBoundary;
        public bool movable;

        [HideInInspector]
        public bool hs;

        public GameObject deadPartical, hsPartical;

        public Transform hsParticalSpawnPos;

        ChatManager chatManager;

        public Image enemyIcon;

        void Start()
        {
            chatManager = GameObject.FindObjectOfType<ChatManager>();

            //******  Find private components and objects  ******
            positionWall = GameObject.Find("PositionWall");

            canChangeRotation = AimTrainer.enemyCanChangeRotation;

            int type = Random.Range(1, 3);
            movable = type == 1 || type == 2;
            //health = Random.Range(50, 170f);
            xAxis = type == 1;
            yAxis = type == 2;
            lifeTime = AimTrainer.lifeTime;

            //****** Health  ******
            firstHealth = health;

            //******  Set movement variables  ******
            if (xAxis)
            {
                movementXSpeed = Random.Range(1f, 4f);
                movementXDir = Random.Range(0, 2);
            }
            if (movementXDir == 0)
                movementXSpeed = movementXSpeed * 1f;
            else
                movementXSpeed = movementXSpeed * (-1f);

            if (yAxis)
            {
                movementYSpeed = Random.Range(1f, 4f);
                movementYDir = Random.Range(0, 2);
            }
            if (movementYDir == 0)
                movementYSpeed = movementYSpeed * 1f;
            else
                movementYSpeed = movementYSpeed * (-1f);

            //transform.localScale *= Random.Range(.8f, 1.6f);
        }

        void Update()
        {
            //******  Check when unpause  ******
            if (!AimTrainer.pause && !AimTrainer.endOfTheGame)
            {
                HealthUpdate();
                SetDestinyPoint();
                move();
                ObjectColorHandler();
                LifeTimer();
                //IfObjectOutsideOfTheBound();
            }
        }

        void LifeTimer()
        {
            if (lifeTime > 0)
            {
                lifeTime -= Time.deltaTime;
            }
            else
            {
                Destroy(gameObject);
            }
        }

        void ObjectColorHandler()
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();

            if (health >= 0)
            {
                renderer.material.color = Color.HSVToRGB((125f / 360f) * ((float)health / 100f), 0.9f, 0.9f);
            }
            else
            {
                renderer.material.color = Color.HSVToRGB((125f / 360f) * (0f / 100f), 0.9f, 0.9f);
            }
        }


        void SetDestinyPoint()
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();

            if (canChangeRotation)
            {
                if ((destinyTimer < 0f) || ((transform.position.x + renderer.bounds.size.x / 2f) >= (positionWall.transform.position.x + positionWall.GetComponent<Renderer>().bounds.size.x / 2f)) || ((transform.position.x - renderer.bounds.size.x / 2f) <= (positionWall.transform.position.x - positionWall.GetComponent<Renderer>().bounds.size.x / 2f))
                    || ((transform.position.y + renderer.bounds.size.y / 2f) >= (positionWall.transform.position.y + positionWall.GetComponent<Renderer>().bounds.size.y / 2f)) || ((transform.position.y - renderer.bounds.size.y / 2f) <= (positionWall.transform.position.y - positionWall.GetComponent<Renderer>().bounds.size.y / 2f)))
                {
                    if (checkBoundary)
                    {
                        destinyTimer = Random.Range(0.3f, 2f);
                        movementXSpeed *= -1;
                        movementYSpeed *= -1;
                        checkBoundary = false;
                    }
                }
                else
                {
                    checkBoundary = true;
                    destinyTimer -= Time.deltaTime;
                }
            }
            else
            {
                if (((transform.position.x + renderer.bounds.size.x / 2f) >= (positionWall.transform.position.x + positionWall.GetComponent<Renderer>().bounds.size.x / 2f)) || ((transform.position.x - renderer.bounds.size.x / 2f) <= (positionWall.transform.position.x - positionWall.GetComponent<Renderer>().bounds.size.x / 2f))
                    || ((transform.position.y + renderer.bounds.size.y / 2f) >= (positionWall.transform.position.y + positionWall.GetComponent<Renderer>().bounds.size.y / 2f)) || ((transform.position.y - renderer.bounds.size.y / 2f) <= (positionWall.transform.position.y - positionWall.GetComponent<Renderer>().bounds.size.y / 2f)))
                {
                    if (checkBoundary)
                    {
                        movementXSpeed *= -1;
                        movementYSpeed *= -1;
                        checkBoundary = false;
                    }
                }
                else
                {
                    checkBoundary = true;
                    destinyTimer -= Time.deltaTime;
                }
            }
        }

        void move()
        {
            if (movable)
            {
                transform.position = new Vector3(transform.position.x + movementXSpeed * Time.deltaTime, transform.position.y + movementYSpeed * Time.deltaTime, transform.position.z);
            }
        }

        void HealthUpdate()
        {
            if (health <= 0)
            {
                Dead();
            }
        }

        public void Dead()
        {
            dead = true;
            Destroy(gameObject);
            AimTrainer.score += 5;

            if (AimTrainer.score > 50)
            {
                var gun = FindObjectOfType<Gun>();
                gun.gunPivot.GetChild(0).gameObject.SetActive(false);
                gun.gunPivot.GetChild(1).gameObject.SetActive(true);
                gun.damage = 150;
            }

            if (hs)
            {
                Instantiate(hsPartical, hsParticalSpawnPos.position, Quaternion.Euler(new Vector3(-90f, 0f, 0f)));
            }
            else
            {
                Instantiate(deadPartical, transform.position, Quaternion.identity);
            }

            float x = Random.Range(0f, 100f);

            if (x <= chatManager.magNukemSettings.konusmaSansi)
            {
                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", chatManager.magNukemSettings.oldurmeModu);
                chatManager.ClickAnswerBubble(null, 0, 0, false);
            }
        }

        public void Damage(float damage)
        {
            if (!dead)
            {
                health -= damage;
            }
        }

        void IfObjectOutsideOfTheBound()
        {
            if (!movable)
            {
                Renderer renderer = gameObject.GetComponent<Renderer>();

                if (((transform.position.x + renderer.bounds.size.x / 2f) > (positionWall.transform.position.x + positionWall.GetComponent<Renderer>().bounds.size.x / 2f)))
                {
                    transform.position = new Vector3(positionWall.transform.position.x + positionWall.GetComponent<Renderer>().bounds.size.x / 2f - renderer.bounds.size.x / 2f, transform.position.y, transform.position.z);
                }

                if (((transform.position.x - renderer.bounds.size.x / 2f) < (positionWall.transform.position.x - positionWall.GetComponent<Renderer>().bounds.size.x / 2f)))
                {
                    transform.position = new Vector3(positionWall.transform.position.x - positionWall.GetComponent<Renderer>().bounds.size.x / 2f + renderer.bounds.size.x / 2f, transform.position.y, transform.position.z);
                }


                if (((transform.position.y + renderer.bounds.size.y / 2f) > (positionWall.transform.position.y + positionWall.GetComponent<Renderer>().bounds.size.y / 2f)))
                {
                    transform.position = new Vector3(transform.position.x, positionWall.transform.position.y + positionWall.GetComponent<Renderer>().bounds.size.y / 2f - renderer.bounds.size.y / 2f, transform.position.z);
                }

                if (((transform.position.y - renderer.bounds.size.y / 2f) < (positionWall.transform.position.y - positionWall.GetComponent<Renderer>().bounds.size.y / 2f)))
                {
                    transform.position = new Vector3(transform.position.x, positionWall.transform.position.y - positionWall.GetComponent<Renderer>().bounds.size.y / 2f + renderer.bounds.size.y / 2f, transform.position.z);
                }
            }
        }
    }
}