using UnityEngine;
using TMPro;
using System.Collections;

namespace Michsky.UI.ModernUIPack
{
    [RequireComponent(typeof(TMP_InputField))]
    [RequireComponent(typeof(Animator))]
    public class CustomInputField : MonoBehaviour
    {
        [Header("Resources")]
        public TMP_InputField inputText;
        public Animator inputFieldAnimator;

        // Hidden variables
        private string inAnim = "In";
        private string outAnim = "Out";

        IEnumerator Start()
        {
            if (inputText == null)
                inputText = gameObject.GetComponent<TMP_InputField>();

            if (inputFieldAnimator == null)
                inputFieldAnimator = gameObject.GetComponent<Animator>();

            inputText.onSelect.AddListener(delegate { AnimateIn(); });
            inputText.onEndEdit.AddListener(delegate { UpdateState(); });

            yield return new WaitForEndOfFrame();
            UpdateState();
        }

        void OnEnable()
        {
            if (inputText == null)
                return;

            inputText.ForceLabelUpdate();
            UpdateState();
        }

        public void AnimateIn() 
        {
            inputFieldAnimator.Play(inAnim);
        }

        public void AnimateOut()
        {
            if (inputText.text.Length <= 0)
                inputFieldAnimator.Play(outAnim);
        }

        public void UpdateState()
        {
            if (inputText.text.Length <= 0)
                AnimateOut();
            else
                AnimateIn();
        }
    }
}