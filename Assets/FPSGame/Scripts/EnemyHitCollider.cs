using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AimTrainer
{
    public class EnemyHitCollider : MonoBehaviour
    {
        public Enemy enemy;
        public float damageMultiplier = 1f;

        public bool hs;

        void Start()
        {

        }

        void Update()
        {

        }

        public void ApplyDamageToEnemy(float damage)
        {
            enemy.Damage(damage * damageMultiplier);
            enemy.hs = hs;
        }
    }
}