using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Animator))]
public class SohbeteGecButtonsAnimatorHandler : MonoBehaviour
{
    private Animator animator;

    [SerializeField] private bool largeButtons;

    int state = 0;

    private void OnEnable()
    {
        if(animator==null)
            animator = GetComponent<Animator>();

        animator.SetInteger("state", 0);
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetAnimatorState(int state)
    {
        if (this.state == state)
            return;

        if (animator == null)
            animator = GetComponent<Animator>();

        this.state = state;
        animator.SetInteger("state", state * (largeButtons ? -1 : 1));
    }
}
