using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class LinkPhoneNumber : MonoBehaviour
{
    public TMP_InputField countryCode, phoneNumber, verificationCode;

    public GameObject subMenuPhoneNumber, subMenuVerificationCode;

    AuthenticationManager authenticationManager;

    // Start is called before the first frame update
    void Start()
    {
        authenticationManager = FindObjectOfType<AuthenticationManager>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void OnClickLinkButton()
    {
        authenticationManager.SendVerificationCodeWithSmsForLink(countryCode.text, phoneNumber.text, subMenuPhoneNumber, subMenuVerificationCode);
    }

    public void OnClickLinkVerificationButton()
    {
        authenticationManager.OnLinkWithSms(verificationCode.text);
    }
}
