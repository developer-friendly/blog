document$.subscribe(function prepareSubForm() {
  var formParentDiv = document.getElementById("subscribe-form-9b27c56e");
  var subscriptionForm = document.getElementById("subscription-form-b8eb1947");
  var subscribeButton = document.getElementById("subscribe-button-ea4577c9");
  var submitInfo = document.getElementById("subscribe-submit-info-345a25b9");

  function subscribeButtonClick() {
    isHidden = formParentDiv.classList.contains("hidden");
    if (!isHidden) {
      subscriptionForm.reset();
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

    if (hcaptcha.getResponse().length == 0) {
      submitInfo.innerHTML = "Please complete the captcha!";
      submitInfo.classList.remove("hidden");
      submitInfo.classList.add("md-banner--warning");
      return;
    }

    event.target.submit();

    submitInfo.innerHTML = "Thank you for subscribing!";
    submitInfo.classList.remove("hidden");

    event.target.reset();
  }

  subscribeButton.addEventListener("click", subscribeButtonClick);
  subscriptionForm.addEventListener("submit", subscribeButtonSubmit);
});
