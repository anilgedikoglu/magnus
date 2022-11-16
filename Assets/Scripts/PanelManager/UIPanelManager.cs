using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Magnus.UI
{
    public class UIPanelManager : MonoBehaviour
    {
        public List<RectTransform> panels;


        private int _activePanelIndex;
        private int ActivePanelIndex
        {
            get
            {
                return _activePanelIndex;
            }

            set
            {
                _activePanelIndex = value;
                UpdateUI();
            }
        }
        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }

        public void SetActivePanelIndex(int index)
        {
            ActivePanelIndex = index;
        }

        public void UpdateUI()
        {
            CloseAllPanels();
            panels[ActivePanelIndex].gameObject.SetActive(true);
        }

        private void CloseAllPanels()
        {
            foreach(RectTransform panel in panels)
            {
                panel.gameObject.SetActive(false);
            }
        }
    }
}