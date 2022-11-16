using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.SceneManagement;
using Random = UnityEngine.Random;

public class GameController_2048Bricks : BaseGameController
{
    public float speed;
    public float fallSpeed;
    public Transform nextBrickPoint;
    public Transform columnsParent;

    public Brick columnPrefab;
    public bool spawnColumns;

    public PlaySfx landingSfx;
    public PlaySfx mergingSfx;

    NumberedBrick nextBrick;
    Vector2Int currentBrick;

    float timeSinceMoveDown;

    bool isFalling;
    bool isAnimating;
    bool isMoved;

    GameState2048Bricks gameState;

    public Magnu2048Settings magnu2048Settings;
    
    class BrickPath
    {
        public NumberedBrick brick;
        public List<Vector2Int> path;
    }

    bool IsAnimating
    {
        get => isAnimating;
        set
        {
            isAnimating = value;
            if (isAnimating)
                isMoved = false;
        }
    }

    int GetRandomNumber()
    {
        return Mathf.RoundToInt(Mathf.Pow(2, Random.Range(1, 5)));
    }

    int GetColorIndex(int number)
    {
        return Mathf.RoundToInt(Mathf.Log(number, 2) - 1);
    }

    private void Awake()
    {
        RectTransform canvasRect = GameObject.Find("Canvas").GetComponent<RectTransform>();
        RectTransform rt = transform.GetChild(0).GetComponent<RectTransform>().GetChild(0).GetComponent<RectTransform>();
        RectTransform rtAnimationFolder = transform.GetChild(0).GetComponent<RectTransform>().GetChild(1).GetComponent<RectTransform>();

        float scale = ((canvasRect.sizeDelta.x / 540f));

        if (scale > 1)
            scale = 1;

        rt.localScale = new Vector3(scale, scale, scale);
        rtAnimationFolder.localScale = rt.localScale;
    }

    void Start()
    {
        if (spawnColumns)
            SpawnColumns();

        InputController.Left += OnLeft;
        InputController.Right += OnRight;
        InputController.Down += OnDown;
        InputController.Move += OnTapMove;

        SpawnNextBrick();

        field = new NumberedBrick[bricksCount.x, bricksCount.y];

        gameState = UserProgress.Current.GetGameState<GameState2048Bricks>(name);
        if (gameState == null)
        {
            gameState = new GameState2048Bricks();
            UserProgress.Current.SetGameState(name, gameState);
        }

        UserProgress.Current.CurrentGameId = name;

        if (LoadGame())
            return;

        gameState.Score = 0;
        gameState.IsGameOver = false;
        SpawnStartingBricks();
        nextBrick.Number = GetRandomNumber();
        nextBrick.ColorIndex = GetColorIndex(nextBrick.Number);
        SaveGame();
    }

    void SpawnStartingBricks()
    {
        currentBrick = new Vector2Int(bricksCount.x / 2, bricksCount.y - 1);
        Spawn(currentBrick, GetRandomNumber());

        List<int> numbers = new List<int>(bricksCount.x);
        for (int i = 1; i <= bricksCount.x; i++)
        {
            numbers.Add(Mathf.RoundToInt(Mathf.Pow(2, i)));
        }

        for (int i = 0; i < bricksCount.x; i++)
        {
            int rand = Random.Range(0, numbers.Count);
            Spawn(new Vector2Int(i, 0), numbers[rand]);
            numbers.RemoveAt(rand);
        }
    }

    void SpawnColumns()
    {
        for (int i = 0; i < bricksCount.x; i++)
        {
            Brick columnBrick = Instantiate(columnPrefab, columnsParent);
            RectTransform rect = columnBrick.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.zero;
            rect.anchoredPosition = new Vector2(GetBrickPosition(new Vector2(i, 0)).x, fieldTransform.rect.height / 2);

            rect.sizeDelta = new Vector2(fieldTransform.rect.width / bricksCount.x, fieldTransform.rect.height);
            Color color = columnBrick.sprite.color;
            color.a = i % 2 == 0 ? 0.20f : 0.3f;
            columnBrick.sprite.color = color;
        }
    }

    void OnDestroy()
    {
        InputController.Left -= OnLeft;
        InputController.Right -= OnRight;
        InputController.Down -= OnDown;
        InputController.Move -= OnTapMove;
    }

    void OnLeft()
    {
        if (!IsAnimating && !isFalling)
            MoveHorizontally(-1);
    }

    void OnRight()
    {
        if (!IsAnimating && !isFalling)
            MoveHorizontally(1);
    }

    void OnDown()
    {
        if (IsAnimating || isFalling || !isMoved)
            return;

        isFalling = true;
        timeSinceMoveDown = 0f;
        MoveDown();
    }

    void OnTapMove(int value)
    {
        isMoved = true;
        
        if (IsAnimating || isFalling) return;

        int path = 0;
        if (value < currentBrick.x)
        {
            for (int i = currentBrick.x - 1; i >= value; i--)
            {
                if (field[i, currentBrick.y] != null)
                    break;

                path++;
            }
        }

        if (value > currentBrick.x)
        {
            for (int i = currentBrick.x + 1; i <= value; i++)
            {
                if (field[i, currentBrick.y] != null)
                    break;

                path++;
            }
        }

        int steps = Mathf.Abs(currentBrick.x - value);
        value = path < steps ? currentBrick.x : value;
        
        Move(value);
    }

    void Update()
    {
        if (IsAnimating)
            return;

        timeSinceMoveDown += Time.deltaTime;

        if (isFalling && timeSinceMoveDown >= 1f / fallSpeed)
        {
            timeSinceMoveDown -= 1f / fallSpeed;
            MoveDown();
        }

        if (!isFalling && timeSinceMoveDown >= 1 / speed)
        {
            timeSinceMoveDown -= 1f / speed;
            MoveDown();
        }
    }

    bool LoadGame()
    {
        if (gameState.IsGameOver)
            return false;

        int[] numbers = gameState.GetField();
        if (numbers == null || numbers.Length != bricksCount.x * bricksCount.y)
            return false;

        for (int x = 0; x < bricksCount.x; x++)
        {
            for (int y = 0; y < bricksCount.y; y++)
            {
                if (numbers[x * bricksCount.y + y] > 0)
                    Spawn(new Vector2Int(x, y), numbers[x * bricksCount.y + y]);
            }
        }

        currentBrick = gameState.CurrentBrick;
        nextBrick.Number = gameState.NextBrick;
        nextBrick.ColorIndex = GetColorIndex(nextBrick.Number);

        return true;
    }

    void SaveGame()
    {
        int[] numbers = new int[bricksCount.x * bricksCount.y];
        for (int x = 0; x < bricksCount.x; x++)
        {
            for (int y = 0; y < bricksCount.y; y++)
            {
                numbers[x * bricksCount.y + y] = field[x, y] != null ? field[x, y].Number : 0;
            }
        }

        gameState.SetField(numbers);
        gameState.CurrentBrick = currentBrick;
        gameState.NextBrick = nextBrick.Number;
        UserProgress.Current.SaveGameState(name);
    }

    void Spawn(Vector2Int coords, int number)
    {
        NumberedBrick brick = Instantiate(brickPrefab, fieldTransform);

        brick.transform.SetParent(fieldTransform, false);
        brick.GetComponent<RectTransform>().anchorMin = Vector2.zero;
        brick.GetComponent<RectTransform>().anchorMax = Vector2.zero;
        brick.GetComponent<RectTransform>().anchoredPosition = GetBrickPosition(new Vector2(coords.x, coords.y));

        brick.Number = number;
        brick.ColorIndex = GetColorIndex(number);

        field[coords.x, coords.y] = brick;
    }

    void SpawnNextBrick()
    {
        nextBrick = Instantiate(brickPrefab, nextBrickPoint);
        nextBrick.GetComponent<RectTransform>().anchorMin = new Vector2(0.5f, 0.5f);
        nextBrick.GetComponent<RectTransform>().anchorMax = new Vector2(0.5f, 0.5f);
        nextBrick.GetComponent<RectTransform>().anchoredPosition = Vector2.zero;
    }

    void MoveDown()
    {
        NumberedBrick brick = field[currentBrick.x, currentBrick.y];

        if (currentBrick.y > 0 && field[currentBrick.x, currentBrick.y - 1] == null)
        {
            field[currentBrick.x, currentBrick.y] = null;
            currentBrick.y--;
            field[currentBrick.x, currentBrick.y] = brick;

            brick.GetComponent<RectTransform>().anchoredPosition =
                GetBrickPosition(new Vector2(currentBrick.x, currentBrick.y));

            SaveGame();
        }
        else
        {
            IsAnimating = true;
            landingSfx.Play();
            brick.DoLandingAnimation(
                () =>
                {
                    IsAnimating = false;
                    Merge(
                        new List<Vector2Int> {currentBrick},
                        () =>
                        {
                            isFalling = false;

                            currentBrick = new Vector2Int(bricksCount.x / 2, bricksCount.y - 1);

                            if (field[currentBrick.x, currentBrick.y] != null)
                            {
                                IsAnimating = true;

                                gameState.IsGameOver = true;
                                UserProgress.Current.SaveGameState(name);

                                OnGameOver();
                                return;
                            }

                            Spawn(currentBrick, nextBrick.Number);
                            nextBrick.Number = GetRandomNumber();
                            nextBrick.ColorIndex = GetColorIndex(nextBrick.Number);

                            SaveGame();
                        }
                    );
                }
            );
        }
    }

    void MoveHorizontally(int value)
    {
        int x = currentBrick.x + value;
        Move(x);
    }

    void Move(int value)
    {
        if (value < 0 || value >= field.GetLength(0) || field[value, currentBrick.y] != null)
            return;

        NumberedBrick brick = field[currentBrick.x, currentBrick.y];

        field[currentBrick.x, currentBrick.y] = null;
        currentBrick.x = value;
        field[currentBrick.x, currentBrick.y] = brick;

        brick.GetComponent<RectTransform>().anchoredPosition =
            GetBrickPosition(new Vector2(currentBrick.x, currentBrick.y));
    }

    void Merge(List<Vector2Int> toMerge, Action onComplete)
    {
        IsAnimating = true;

        List<Vector2Int> newCoords = new List<Vector2Int>();

        int animationsLeft = 0;
        foreach (Vector2Int coords in toMerge)
        {
            if (field[coords.x, coords.y] == null)
                continue;

            NumberedBrick brick = field[coords.x, coords.y];
            List<Vector2Int> area = WaveAlgorithm.GetArea(
                field,
                coords,
                GetAdjacentCoords,
                b => b != null && b.Number == brick.Number
            );

            if (area.Count < 2)
                continue;

            newCoords.AddRange(area);

            List<BrickPath> paths = new List<BrickPath>();
            foreach (Vector2Int toMove in area)
            {
                if (toMove == coords)
                {
                    continue;
                }

                BrickPath brickPath = new BrickPath
                {
                    brick = field[toMove.x, toMove.y],
                    path = WaveAlgorithm.GetPath(
                        field,
                        toMove,
                        coords,
                        GetAdjacentCoords,
                        b => b != null && b.Number == brick.Number
                    )
                };
                brickPath.path.RemoveAt(0);
                paths.Add(brickPath);
            }

            foreach (Vector2Int toMove in area)
                if (toMove != coords)
                    field[toMove.x, toMove.y] = null;

            animationsLeft++;

            int areaSize = area.Count;
            AnimateMerge(
                paths,
                () =>
                {
                    animationsLeft--;

                    if (animationsLeft > 0)
                        return;

                    mergingSfx.Play();

                    brick.Number *= Mathf.ClosestPowerOfTwo(areaSize);
                    brick.ColorIndex = GetColorIndex(brick.Number);
                    brick.DoMergingAnimation(
                        () =>
                        {
                            if (Random.Range(0f, 1f) < coinProbability)
                            {
                                UserProgress.Current.Coins++;

                                GameObject vfx = Resources.Load<GameObject>("CoinVFX");
                                vfx = Instantiate(vfx, fieldTransform.parent);

                                vfx.transform.position = brick.transform.position;

                                Destroy(vfx, 1.5f);
                            }

                            if (newCoords.Count > 0)
                                Normalize(
                                    normalized =>
                                    {
                                        newCoords.AddRange(normalized);
                                        Merge(newCoords, onComplete);
                                    }
                                );
                        }
                    );

                    gameState.Score += brick.Number;

                    float chance = Random.Range(0, 100);

                    if (chance < magnu2048Settings.sohbetEtmeSansi)
                    {
                        ChatManager chatManager = FindObjectOfType<ChatManager>();

                        switch (brick.Number)
                        {
                            case 4:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan4Modu);
                                break;
                            case 8:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan8Modu);
                                break;
                            case 16:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan16Modu);
                                break;
                            case 32:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan32odu);
                                break;
                            case 64:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan64Modu);
                                break;
                            case 128:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan128Modu);
                                break;
                            case 256:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan256Modu);
                                break;
                            case 512:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan512Modu);
                                break;
                            case 1024:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan1024Modu);
                                break;
                            case 2048:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan2048Modu);
                                break;
                            case 5096:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.Puan5096Modu);
                                break;
                            default:
                                chatManager.PlayerDataManager.AddElementToChatVariableList("mod", magnu2048Settings.PuanCokFazlaModu);
                                break;
                        }
                        chatManager.ClickAnswerBubble(null, 0, 0, false);
                    }
                }
            );
        }

        if (newCoords.Count > 0)
            return;

        IsAnimating = false;
        onComplete.Invoke();
    }

    void AnimateMerge(List<BrickPath> brickPaths, Action onComplete)
    {
        brickPaths.Sort((p0, p1) => p1.path.Count.CompareTo(p0.path.Count));

        int pathLength = brickPaths[0].path.Count;

        if (pathLength == 0)
        {
            brickPaths.ForEach(p => Destroy(p.brick.gameObject));
            onComplete.Invoke();
            return;
        }

        int animationsLeft = 0;
        foreach (BrickPath brickPath in brickPaths)
        {
            if (brickPath.path.Count < pathLength)
                break;

            Vector2 position = GetBrickPosition(brickPath.path[0]);

            brickPath.path.RemoveAt(0);

            animationsLeft++;
            brickPath.brick.DoLocalMove(
                position,
                () =>
                {
                    animationsLeft--;
                    if (animationsLeft == 0)
                        AnimateMerge(brickPaths, onComplete);
                }
            );
        }
    }

    void Normalize(Action<List<Vector2Int>> onComplete)
    {
        List<Vector2Int> normalized = new List<Vector2Int>();
        for (int x = 0; x < field.GetLength(0); x++)
        {
            for (int y = 0; y < field.GetLength(1); y++)
            {
                NumberedBrick brick = field[x, y];

                if (brick == null)
                    continue;

                int yEmpty = y;
                while (yEmpty > 0 && field[x, yEmpty - 1] == null)
                    yEmpty--;

                if (yEmpty == y)
                    continue;

                field[x, y] = null;
                field[x, yEmpty] = brick;
                Vector2Int brickCoords = new Vector2Int(x, yEmpty);

                normalized.Add(brickCoords);

                bool isFirst = normalized.Count == 1;
                brick.DoLocalMove(
                    GetBrickPosition(brickCoords),
                    () =>
                    {
                        if (isFirst)
                        {
                            brick.DoLandingAnimation(() => onComplete.Invoke(normalized));
                            landingSfx.Play();
                        }
                        else
                            brick.DoLandingAnimation(null);
                    }
                );
            }
        }

        if (normalized.Count == 0)
            onComplete.Invoke(normalized);
    }
}