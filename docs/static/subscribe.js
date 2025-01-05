document.addEventListener(
  "DOMContentLoaded",
  function subscribeButtonHandler() {
    var subscriptionForm = document.getElementById(
      "subscription-form-b8eb1947"
    );

    var subscribeButton = document.getElementById("subscribe-button-ea4577c9");
    var subscribeForm = document.getElementById("subscribe-form-9b27c56e");
    var submitInfo = document.getElementById("subscribe-submit-info-345a25b9");

    subscriptionForm.reset();

    subscribeButton.addEventListener("click", function subscribeButtonClick() {
      subscribeForm.classList.toggle("hidden");
    });

    subscriptionForm.addEventListener(
      "submit",
      function subscribeButtonSubmit(event) {
        event.preventDefault();

        var firstName = document.getElementById("name").value;
        var email = document.getElementById("email").value;

        console.debug({
          firstName,
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
    );
  }
);
