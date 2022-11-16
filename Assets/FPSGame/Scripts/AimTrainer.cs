using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AimTrainer
{
    public static class AimTrainer
    {

        //******  PAUSE ******
        public static bool pause = false;
        public static bool endOfTheGame = false;
        public static bool start = false;
        public static float startTimer = 1f;
        public static int timer = 40; 

        #region GameModes
        public static bool enemySpawnerNearSpawn;
        public static int maxEnemyCount = 1;
        public static int enemyHealth = 150;
        public static float lifeTime = 999;
        public static bool enemyMovable = true;
        public static bool enemyXAxis = true, enemyYAxis;
        public static bool floorSpawn;
        public static bool flick;
        public static bool enemyCanChangeRotation;
        public static bool laserFire = false;
        public static bool infinityBullets = true;
        public static float gunDamage = 100;
        public static float gunLaserDamage = 2;

        public static float enemyDestroyTimer = 999;
        public static float autoMoveSoeed = 10;

        public static float spawnXSize = 8;
        public static float spawnYSize = 4;

        public static int gameModeNum = 0;

        public static GameObject[] enemies;

        public static int[] rankScoreForRanks;

        #endregion

        #region InGameScores
        public static int score, accurancy;
        #endregion

        #region GunHitLine
        public static bool HitLines = false;
        #endregion

        #region InformationsShowingPlayer
        public static string trainingName, trainingExp;
        #endregion

        #region MenuStates
        public static int mainMenuState = 1;
        public static int subMenuSettingsState = 1;
        public static int subMenuGameModeState = 0;
        public static int subMenuStatsState = 1;
        public static int subMenuStoreState = 1;
        public static bool menuButtonEffectActive;
        public static float waitForLoadGameSceneTimer;
        public static int minScore;
        #endregion

        public static void ChangePauseState()
        {
            if (pause)
            {
                pause = false;
            }
            else
            {
                pause = true;
            }
        }

        /// <summary>
        /// It resets start and startTimer vairables and if there is other virables like that. Using before take the player game room
        /// </summary>
        public static void ResetStartVairables()
        {
            start = false;
            startTimer = 5f;
            pause = false;
            endOfTheGame = false;

            score = 0;
            accurancy = 0;
        }

        public static string GetRankName(int rank)
        {
            string rankTier = "", rankNum = "";

            if (rank != 0)
            {
                rank -= 1;

                if (rank / 4 == 0)
                {
                    rankTier = "Iron";
                }
                else if (rank / 4 == 1)
                {
                    rankTier = "Bronze";
                }
                else if (rank / 4 == 2)
                {
                    rankTier = "Silver";
                }
                else if (rank / 4 == 3)
                {
                    rankTier = "Gold";
                }
                else if (rank / 4 == 4)
                {
                    rankTier = "Platin";
                }
                else if (rank / 4 == 5)
                {
                    rankTier = "Diamond";
                }
                else if (rank / 4 == 6)
                {
                    rankTier = "Pro";
                }

                rankNum = ((rank - ((rank / 4) * 4)) + 1).ToString();
            }
            else
            {
                rankTier = "Unranked";
                rankNum = "";
            }

            return rankTier + " " + rankNum;
        }

        public static string GetGameModeName(int gameMode)
        {
            string gameModeName;

            if (gameMode == 0)
            {
                gameModeName = "ONE TAP";
            }
            else if (gameMode == 1)
            {
                gameModeName = "TRACKING";
            }
            else if (gameMode == 2)
            {
                gameModeName = "SPRAYS";
            }
            else if (gameMode == 3)
            {
                gameModeName = "BOTS";
            }
            else if (gameMode == 4)
            {
                gameModeName = "BOTS (YOU MOVE)";
            }
            else if (gameMode == 5)
            {
                gameModeName = "FLICK";
            }
            else
            {
                gameModeName = "Coudln't find the name of the mode";
            }

            return gameModeName;
        }

        public static string GetGameModeDifficulty(int gameMode)
        {
            string gameModeDifficulty;

            if (gameMode == 0)
            {
                gameModeDifficulty = "<color=#3E9339>EASY</color>";
            }
            else if (gameMode == 1)
            {
                gameModeDifficulty = "<color=#F66504>NORMAL</color>";
            }
            else
            {
                gameModeDifficulty = "<color=#C12E26>HARD</color>";
            }

            return gameModeDifficulty;
        }

        public static string TurnIntSignString(int variables)
        {
            if (variables > 0)
            {
                return "+" + variables.ToString();
            }
            else if (variables < 0)
            {
                return variables.ToString();
            }
            else
            {
                return variables.ToString();
            }
        }
    }
}