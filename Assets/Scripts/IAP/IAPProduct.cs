using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Purchasing;
using UnityEngine.UI;

[RequireComponent(typeof(Button))]
public class IAPProduct : MonoBehaviour
{
    Button button;

    Product product;
    public string productId;
    public string productIdApple;
    public string productIdAndroid;
    
    public Text titleText;
    public Text descriptionText;
    
    public Text priceText;
    public Text subMonthlyPrice;
    public int subDuration = 0;

    public Text discountRatioText;
    public string baseProductId;
    Product baseProduct;

    // Start is called before the first frame update
    void Start()
    {
        product = CodelessIAPStoreListener.Instance.GetProduct(GetCurrentProductId());

        if (!string.IsNullOrEmpty(baseProductId))
            baseProduct = CodelessIAPStoreListener.Instance.GetProduct(baseProductId);

        button = GetComponent<Button>();
        button.onClick.AddListener(PurchaseProduct);

        SetText();
    }

    public void SetText()
    {
        decimal price = product.metadata.localizedPrice;

        if (titleText != null)
        {
            titleText.text = product.metadata.localizedTitle;
            Debug.Log(product.metadata.localizedTitle);
        }

        if (descriptionText != null)
        {
            descriptionText.text = product.metadata.localizedDescription;
        }

        if (priceText != null)
        {
            priceText.text = ChageCurrency(price + " " + product.metadata.isoCurrencyCode);

            //Gecici olarak devredisi
            //if (subDuration == 1)
                //priceText.text += "/ay";
        }

        if (subDuration != 0 && subMonthlyPrice != null)
        {
            subMonthlyPrice.text = ChageCurrency((System.MathF.Round(((float)price / subDuration), 2)).ToString() + product.metadata.isoCurrencyCode + "/ay");
        }

        if (!string.IsNullOrEmpty(baseProductId) && baseProduct != null && discountRatioText != null)
        {
            SetDiscountText(product.metadata.isoCurrencyCode, (float)price, (float)baseProduct.metadata.localizedPrice * subDuration);
        }
    }

    void SetDiscountText(string currecnyIso, float price, float basePrice)
    {
        if (currecnyIso.Contains("TRY"))
        {
            discountRatioText.text = "%" + System.MathF.Round(((basePrice - price) / basePrice) * 100f, 2).ToString();
        }
        else
        {
            discountRatioText.text = System.MathF.Round(((basePrice - price) / basePrice) * 100f, 2).ToString() + "%";
        }
    }

    void PurchaseProduct()
    {
        CodelessIAPStoreListener.Instance.InitiatePurchase(GetCurrentProductId());
    }

    string ChageCurrency(string text)
    {
        if (text.Contains("TRY"))
            text = text.Replace("TRY", "₺");

        if (text.Contains("USD"))
            text = text.Replace("USD", "$");

        return text;
    }

    public string GetCurrentProductId()
    {
        if(Application.platform == RuntimePlatform.IPhonePlayer)
        {
            return productIdApple;
        }
        else if (Application.platform == RuntimePlatform.Android)
        {
            return productIdAndroid;
        }
        else
        {
            return productId;
        }
    }
}
