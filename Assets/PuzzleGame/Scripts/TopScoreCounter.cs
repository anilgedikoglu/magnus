public class TopScoreCounter : ScoreCounter
{
    protected override int Value
    {
        get { return currentGameState.TopScore; }
    }
}