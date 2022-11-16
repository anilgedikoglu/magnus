using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Events;

public class FWSInpıtManager : MonoBehaviour
{
    private AuthenticationManager authenticationManager;

    public FirstWelcomeScreenManager firstWelcomeScreenManager;
    public TMP_InputField TMP_InputField;
    public WheelDatePicker wheelDatePicker;
    public WheelTimePicker wheelTimePicker;
    public WheelStringListPicker wheelStringListPicker;

    [SerializeField] private UnityEvent onActivated;

    private void Awake()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
    }

    // Start is called before the first frame update
    void Start()
    {
        firstWelcomeScreenManager = FindObjectOfType<FirstWelcomeScreenManager>();
        TMP_InputField = FindObjectOfType<TMP_InputField>();
        wheelDatePicker = FindObjectOfType<WheelDatePicker>();
        wheelTimePicker = FindObjectOfType<WheelTimePicker>();
        wheelStringListPicker = FindObjectOfType<WheelStringListPicker>();


        if (TMP_InputField!=null)
        {
            TMP_InputField.onValueChanged.AddListener((string text) => { OnValueChanged(text); });
        }

        if (wheelDatePicker != null)
        {
            wheelDatePicker.ValueChange += () => { OnValueChanged(wheelDatePicker.year.CurrentValue, wheelDatePicker.month.CurrentValue, wheelDatePicker.day.CurrentValue); };
        }

        if (wheelTimePicker != null)
        {
            wheelTimePicker.ValueChange += () => { OnValueChanged(wheelTimePicker.hour.CurrentValue, wheelTimePicker.minute.CurrentValue); };
        }

        if (wheelStringListPicker != null)
        {
            wheelStringListPicker.ValueChange += () => { OnValueChanged(wheelStringListPicker.wheel.CurrentValue); };
        }

        onActivated.Invoke();
    }

    private void OnEnable()
    {
        StartCoroutine(EnableEndOfFrame());
    }

    IEnumerator EnableEndOfFrame()
    {
        yield return new WaitForEndOfFrame();
        if (TMP_InputField != null)
        {
            if (!string.IsNullOrEmpty(TMP_InputField.text))
                OnValueChanged(TMP_InputField.text);
        }

        if (wheelDatePicker != null)
        {
            OnValueChanged(wheelDatePicker.year.CurrentValue, wheelDatePicker.month.CurrentValue, wheelDatePicker.day.CurrentValue);
        }

        if (wheelTimePicker != null)
        {
            OnValueChanged(wheelTimePicker.hour.CurrentValue, wheelTimePicker.minute.CurrentValue);
        }

        if (wheelStringListPicker != null)
        {
            OnValueChanged(wheelStringListPicker.wheel.CurrentValue);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnValueChanged(string text)
    {
        firstWelcomeScreenManager.kaydedilecekDegiskenDegeri = text;
    }

    private void OnValueChanged(string yil, string ay, string gun)
    {
        firstWelcomeScreenManager.kaydedilecekDegiskenDegeri = yil;
        firstWelcomeScreenManager.playerDataManager.AddElementToChatVariableList("dogum yili", yil);
        firstWelcomeScreenManager.playerDataManager.AddElementToChatVariableList("dogum ayi", ChatVariables.AyiSayiyaCevir(ay).ToString());
        firstWelcomeScreenManager.playerDataManager.AddElementToChatVariableList("dogum gunu", gun);
    }

    private void OnValueChanged(string saat, string dakika)
    {
        firstWelcomeScreenManager.kaydedilecekDegiskenDegeri = saat;
        firstWelcomeScreenManager.playerDataManager.AddElementToChatVariableList("dogum saati", saat);
        firstWelcomeScreenManager.playerDataManager.AddElementToChatVariableList("dogum dakikasi", dakika);
    }

    public void SetUserName()
    {
        if (TMP_InputField == null)
            return;

        if (authenticationManager.appleCredential == null)
            return;

        if (authenticationManager.appleCredential.FullName == null)
            return;

        if (string.IsNullOrEmpty(authenticationManager.appleCredential.FullName.GivenName))
            return;

        TMP_InputField.text = authenticationManager.appleCredential.FullName.GivenName;
    }

    public void SetLastName()
    {
        if (TMP_InputField == null)
            return;

        if (authenticationManager.appleCredential == null)
            return;

        if (authenticationManager.appleCredential.FullName == null)
            return;

        if (string.IsNullOrEmpty(authenticationManager.appleCredential.FullName.FamilyName))
            return;

        TMP_InputField.text = authenticationManager.appleCredential.FullName.FamilyName;
    }
}
