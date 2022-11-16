using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AimTrainer
{
    public class EnemySpawner : MonoBehaviour
    {
        [SerializeField] private GameObject prefab;
        public List<SpawnPrefab> enemies;
        public Sprite[] sprites;
        private Sprite currentEnemySprite;

        private int enemyDensity, enemyCount;

        public int maxEnemyCount;

        public bool floor;

        private bool flick;
        private int flickValue = 1;

        private int currentEnemyType;

        void Start()
        {
            currentEnemySprite = sprites[Random.Range(0, sprites.Length)];

            AimTrainer.start = true;
            AimTrainer.startTimer = -1;
            SpawnEnemies();


            maxEnemyCount = AimTrainer.maxEnemyCount;
            //enemies = AimTrainer.enemies;

            flick = AimTrainer.flick;
            flickValue = 1;

            if (!AimTrainer.floorSpawn)
            {
                if (floor)
                {
                    Destroy(gameObject);
                }
            }
            else
            {
                if (!floor)
                {
                    Destroy(gameObject);
                }
            }
        }

        void Update()
        {
            SpawnEnemies();
        }

        void SpawnEnemies()
        {
            if (AimTrainer.start && AimTrainer.startTimer <= 0f)
            {
                enemyCount = GameObject.FindGameObjectsWithTag("Enemy").Length;

                if (enemyCount < AimTrainer.maxEnemyCount)
                {
                    var firstEnemyType = currentEnemyType;
                    for (int i = enemies.Count - 1; i >= 0; i--)
                    {
                        if (enemies[i].score < AimTrainer.score)
                        {
                            if (i > currentEnemyType)
                                currentEnemyType = i;

                            if (firstEnemyType < currentEnemyType)
                            {
                                AimTrainer.timer += enemies[i].additionalTime;
                                currentEnemySprite = sprites[Random.Range(0, sprites.Length)];
                                FindObjectOfType<ChatManager>().ClickVirtualButton("magnukem sure eklendi " + enemies[i].additionalTime);
                            }
                            break;
                        }
                    }
                    var enemy = Instantiate(prefab, setEnemyPosition(), Quaternion.identity);
                    enemy.transform.parent = transform;
                    //enemy.transform.localScale = Vector3.one;
                    enemy.GetComponent<Enemy>().enemyIcon.sprite = currentEnemySprite;
                    flickValue *= -1;
                }
            }
        }

        Vector3 setEnemyPosition()
        {
            Vector3 pos = new Vector3(0, 0, 0);

            if (!flick)
            {
                if (!AimTrainer.floorSpawn)
                {
                    pos = new Vector3(transform.position.x + Random.Range(-(int)(AimTrainer.spawnXSize / 2f), (int)(AimTrainer.spawnXSize / 2f) + 1), transform.position.y + Random.Range(-(int)(AimTrainer.spawnYSize / 2f), (int)(AimTrainer.spawnYSize / 2f) + 1), transform.position.z);
                }
                else
                {
                    //Y pos will be minumum y pos that bot could have. Because bot will set its position to boundary position. So if we set -5 to y post its will be equal boundary pos.
                    pos = new Vector3(transform.position.x + Random.Range(-(int)(AimTrainer.spawnXSize / 2f), (int)(AimTrainer.spawnXSize / 2f) + 1), 1f, transform.position.z + Random.Range(-(int)(AimTrainer.spawnYSize / 2f), (int)(AimTrainer.spawnYSize / 2f) + 1));
                }
            }
            else
            {
                if (!AimTrainer.floorSpawn)
                {
                    pos = new Vector3(transform.position.x + Random.Range((int)(AimTrainer.spawnXSize / 4f), (int)(AimTrainer.spawnXSize / 2f) + 1) * flickValue, transform.position.y + Random.Range(-(int)(AimTrainer.spawnYSize / 2f), (int)(AimTrainer.spawnYSize / 2f) + 1), transform.position.z);
                }
                else
                {
                    //Y pos will be minumum y pos that bot could have. Because bot will set its position to boundary position. So if we set -5 to y post its will be equal boundary pos.
                    pos = new Vector3(transform.position.x + Random.Range((int)(AimTrainer.spawnXSize / 4f), (int)(AimTrainer.spawnXSize / 2f) + 1) * flickValue, 1f, transform.position.z + Random.Range(-(int)(AimTrainer.spawnYSize / 2f), (int)(AimTrainer.spawnYSize / 2f) + 1));
                }
            }
            return pos;
        }

        [System.Serializable]
        public class SpawnPrefab
        {
            public int score;
            public int additionalTime;
        }
    }
}