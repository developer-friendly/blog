document$.subscribe(function popUpModal() {
  var modal = document.getElementById("modal");
  var closeButton = document.querySelector(".close-button");
  var subscribeForm = document.getElementById("subscribe-form");

  subscribeForm.addEventListener("submit", function subscribe(event) {
    event.preventDefault();

    var formData = new FormData(event.target);
    var email = formData.get("email");

    if (email) {
      LogRocket.identify(email);
    }

    localStorage.setItem("subscribed", true);

    event.target.submit();
  });

  function showModal() {
    modal.style.display = "flex";
  }

  closeButton.addEventListener("click", function closeSubscribeModal() {
    modal.style.display = "none";
    localStorage.setItem("subscribed", true);
  });

  if (localStorage.getItem("subscribed") != "true") {
    setTimeout(showModal, 5000);
  }
});
