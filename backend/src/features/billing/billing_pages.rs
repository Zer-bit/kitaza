use uuid::Uuid;

/// The few plain pages a phone's browser sees during checkout. Short, in both
/// languages, readable on a small screen, and with nothing to load.
fn page(title: &str, body: &str) -> String {
    format!(
        r#"<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
  body {{ font-family: system-ui, sans-serif; margin: 0; padding: 32px 20px;
         color: #1c2b29; background: #f6faf9; line-height: 1.5; }}
  main {{ max-width: 420px; margin: 0 auto; }}
  h1 {{ color: #0f766e; font-size: 1.6rem; }}
  p.fil {{ color: #3f5552; }}
  button {{ font: inherit; font-weight: 600; width: 100%; padding: 16px;
            border: 0; border-radius: 12px; background: #0f766e; color: #fff; }}
</style></head>
<body><main>{body}</main></body></html>"#
    )
}

pub fn returned(paid: bool) -> String {
    if paid {
        page(
            "Payment received",
            "<h1>Payment received</h1>\
             <p>Thank you. Go back to Kitaza: your plan updates within a minute.</p>\
             <p class=\"fil\">Salamat. Bumalik sa Kitaza: maa-update ang plan mo sa loob ng isang minuto.</p>",
        )
    } else {
        page(
            "Payment not finished",
            "<h1>Payment not finished</h1>\
             <p>Nothing was charged. Go back to Kitaza to try again whenever you are ready.</p>\
             <p class=\"fil\">Walang nabawas. Bumalik sa Kitaza para subukan ulit kapag handa ka na.</p>",
        )
    }
}

/// The test gateway's checkout: one button, no money.
pub fn test_checkout(payment_id: Uuid, amount: &str) -> String {
    page(
        "Test checkout",
        &format!(
            "<h1>Test checkout</h1>\
             <p>This server is in test mode. Nothing is charged.</p>\
             <p><strong>{amount}</strong></p>\
             <form method=\"post\" action=\"/billing/test-checkout/{payment_id}\">\
             <button type=\"submit\">Pay {amount} (test)</button></form>"
        ),
    )
}
