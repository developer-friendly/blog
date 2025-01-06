document$.subscribe(function prepareSubForm() {
  var formParentDiv = document.getElementById("subscribe-form-9b27c56e");
  var subscriptionForm = document.getElementById("subscription-form-b8eb1947");
  var subscribeButton = document.getElementById("subscribe-button-ea4577c9");
  var submitInfo = document.getElementById("subscribe-submit-info-345a25b9");

  function subscribeButtonClick() {
    isHidden = formParentDiv.classList.contains("hidden");
    if (!isHidden) {
      subscriptionForm.reset();
      submitInfo.innerHTML = "";
    }
    formParentDiv.classList.toggle("hidden");
  }

  function subscribeButtonSubmit(event) {
    event.preventDefault();

    var name = document.getElementById("name").value;
    var email = document.getElementById("email").value;

    console.debug({
      name,
      email,
    });

    if (hcaptcha.getRespKey().length == 0) {
      hcaptcha.render("h-captcha-0de6fb2e-eb24-454a-8dfe-4f6c9670ab7e", {
        sitekey: "0de6fb2e-eb24-454a-8dfe-4f6c9670ab7e",
      })
      hcaptcha.execute()
      return;
    }

    var formData = new FormData(subscriptionForm);

    var xhr = new XMLHttpRequest();
    xhr.open(subscriptionForm.method, subscriptionForm.action, true);
    xhr.onload = function onloadHandler() {
      if (xhr.status == 200) {
        submitInfo.classList.remove("md-banner--warning");
        submitInfo.innerHTML = "Subscription successful!";
      } else {
        submitInfo.classList.add("md-banner--warning");
        submitInfo.innerHTML = "Subscription failed. Please try again.";
      }
    };
    xhr.send(formData);

    submitInfo.classList.remove("hidden");

    subscriptionForm.reset();
  }

  subscribeButton.addEventListener("click", subscribeButtonClick);
  subscriptionForm.addEventListener("submit", subscribeButtonSubmit);
});
