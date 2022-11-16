using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public static class WaveAlgorithm
{
    class PathNode
    {
        public readonly Vector2Int coords;
        public readonly PathNode previous;

        public PathNode(Vector2Int coords, PathNode previous)
        {
            this.coords = coords;
            this.previous = previous;
        }
    }

    public static List<Vector2Int> GetArea<T>(T[,] field, Vector2Int start,
        Func<Vector2Int, IEnumerable<Vector2Int>> adjacent, Predicate<T> predicate)
    {
        List<Vector2Int> area = new List<Vector2Int> {start};

        Queue<Vector2Int> queue = new Queue<Vector2Int>();
        queue.Enqueue(start);

        while (queue.Count > 0)
        {
            Vector2Int coords = queue.Dequeue();

            foreach (Vector2Int c in adjacent.Invoke(coords))
                if (!area.Contains(c) && predicate(field[c.x, c.y]))
                {
                    queue.Enqueue(c);
                    area.Add(c);
                }
        }

        return area;
    }

    public static List<Vector2Int> GetPath<T>(T[,] field, Vector2Int start, Vector2Int end,
        Func<Vector2Int, IEnumerable<Vector2Int>> adjacent, Predicate<T> predicate)
    {
        List<Vector2Int> path = new List<Vector2Int>();

        List<PathNode> linkedPath = new List<PathNode> {new PathNode(start, null)};

        Queue<PathNode> queue = new Queue<PathNode>();
        queue.Enqueue(linkedPath[0]);

        while (queue.Count > 0)
        {
            PathNode node = queue.Dequeue();

            if (node.coords == end)
            {
                while (node.previous != null)
                {
                    path.Add(node.coords);
                    node = node.previous;
                }

                path.Add(node.coords);
                path.Reverse();

                return path;
            }

            foreach (Vector2Int c in adjacent.Invoke(node.coords))
                if (linkedPath.All(n => n.coords != c) && predicate(field[c.x, c.y]))
                {
                    linkedPath.Add(new PathNode(c, node));
                    queue.Enqueue(linkedPath[linkedPath.Count - 1]);
                }
        }

        return path;
    }
}