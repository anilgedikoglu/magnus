using UnityEngine;

public class EnvironmentController : MonoBehaviour
{
    [SerializeField]
    private Transform player = null;

    private Vector3 _offset;

    private Vector3 _position;
    
    private void Start()
    {
        _position = transform.position;
        _offset = player.position - _position;
        
    }

    private void Update()
    {
        _position.z = (player.position - _offset).z;

        transform.position = _position;
    }
}
