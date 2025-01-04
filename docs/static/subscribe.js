document.addEventListener(
  "DOMContentLoaded",
  function subscribeButtonHandler() {
    document.getElementById("subscription-form-b8eb1947").reset();

    const subscribeButton = document.getElementById(
      "subscribe-button-ea4577c9"
    );
    const subscribeForm = document.getElementById("subscribe-form-9b27c56e");

    subscribeButton.addEventListener("click", function subscribeButtonClick() {
      subscribeForm.classList.toggle("hidden");
      document.getElementById("subscribe-submit-info-345a25b9").classList.add("hidden");
    });

    document
      .getElementById("subscription-form-b8eb1947")
      .addEventListener("submit", function subscribeButtonSubmit(event) {
        event.preventDefault();
        const firstName = document.getElementById("name").value;
        const email = document.getElementById("email").value;

        console.debug({
          firstName,
          email,
        });

        event.target.submit();

        var submitInfo = document.getElementById("subscribe-submit-info-345a25b9");
        submitInfo.innerHTML = "Thank you for subscribing!";
        submitInfo.classList.remove("hidden");

        event.target.reset();
        // subscribeForm.classList.add("hidden");
      });
  }
);
