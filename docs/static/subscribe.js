document$.subscribe(function prepareSubForm() {
  var formParentDiv = document.getElementById("subscribe-form-9b27c56e");
  var subscriptionForm = document.getElementById("subscription-form-b8eb1947");
  var subscribeButton = document.getElementById("subscribe-button-ea4577c9");
  var submitInfo = document.getElementById("subscribe-submit-info-345a25b9");
  const hcaptchaDivId = "h-captcha-0de6fb2e-eb24-454a-8dfe-4f6c9670ab7e";
  const hcaptchaSiteKey = "0de6fb2e-eb24-454a-8dfe-4f6c9670ab7e";
  window.captchaWidget = window.captchaWidget || null;

  function notifyWarning() {
    submitInfo.classList.add("flash-warning-dc1f9602");

    setTimeout(() => {
      submitInfo.classList.remove("flash-warning-dc1f9602");
    }, 50);
  }

  function subscribeButtonClick() {
    isHidden = formParentDiv.classList.contains("hidden");
    if (isHidden) {
      submitInfo.innerHTML = "";
      if (captchaWidget) {
        resetCaptcha();
      }
      renderCaptcha();
    }
    formParentDiv.classList.toggle("hidden");
  }

  function resetCaptcha() {
    hcaptcha.reset(captchaWidget);
    captchaWidget = null;
  }

  function renderCaptcha() {
    document.getElementById(hcaptchaDivId).innerHTML = "";
    captchaWidget = hcaptcha.render(hcaptchaDivId, {
      sitekey: hcaptchaSiteKey,
    });
  }

  function subscribeButtonSubmit(event) {
    event.preventDefault();

    if (hcaptcha.getResponse(captchaWidget).length == 0) {
      notifyWarning();
      submitInfo.classList.add("md-banner--warning");
      submitInfo.innerHTML = "Please complete the captcha!";
      return;
    }

    var formData = new FormData(subscriptionForm);

    var xhr = new XMLHttpRequest();
    xhr.open(subscriptionForm.method, subscriptionForm.action, true);
    xhr.onload = function onloadHandler() {
      submitInfo.innerHTML = "Submitting...";
      if (xhr.status == 200) {
        submitInfo.classList.remove("md-banner--warning");
        submitInfo.innerHTML = "Subscription successful!";
        subscriptionForm.reset();
        var countdown = 3;
        var countdownInterval = setInterval(function notifySuccess() {
          submitInfo.innerHTML = "Subscription successful! " + countdown + "s";
          countdown--;
          if (countdown < 0) {
            clearInterval(countdownInterval);
            formParentDiv.classList.add("hidden");
          }
        }, 1000);
      } else {
        submitInfo.classList.add("md-banner--warning");
        submitInfo.innerHTML = "Subscription failed. Please try again.";
        resetCaptcha();
        renderCaptcha();
      }
    };
    xhr.setRequestHeader("accept", "application/json");
    xhr.send(formData);

    submitInfo.classList.remove("hidden");
  }

  subscribeButton.addEventListener("click", subscribeButtonClick);
  subscriptionForm.addEventListener("submit", subscribeButtonSubmit);
});
