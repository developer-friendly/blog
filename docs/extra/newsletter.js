var scrollPercentage = 0;
var scrollListeners = [];

function getScrollPercentage() {
  return scrollPercentage;
}

function updateScrollPercentage() {
  var docElement = document.documentElement;
  var scrollTop = window.pageYOffset || docElement.scrollTop;
  var scrollHeight = docElement.scrollHeight - docElement.clientHeight;
  scrollPercentage = scrollHeight > 0 ? Math.round((scrollTop / scrollHeight) * 100) : 0;

  scrollListeners.forEach(function notifyListener(listener) {
    listener(scrollPercentage);
  });
}

function subscribe(listener) {
  scrollListeners.push(listener);
}

function updateFormScroll() {
  var forms = document.querySelectorAll('.newsletter-form');
  forms.forEach(function handleForm(form) {
    form.setAttribute('data-pirsch-meta-scroll', String(scrollPercentage));
  });
}

function handleScroll() {
  updateScrollPercentage();
  updateFormScroll();
}

function showSuccessMessage(formElement) {
  var container = formElement.parentElement;
  var successMessage = container.querySelector('.success-message');

  formElement.classList.add('hidden');
  successMessage.classList.remove('hidden');
}

function resetAltcha() {
  var altchaWidgets = document.querySelectorAll('altcha-widget');
  altchaWidgets.forEach(function handleWidget(widget) {
    if (widget && typeof widget.reset === 'function') {
      var formElement = widget.closest('form');
      var successMessage = formElement.parentElement.querySelector('.success-message');
      resetForm(formElement, successMessage);
      widget.reset();
    }
  });
}

function resetForm(formElement, successMessage) {
  successMessage.classList.add('hidden');
  formElement.classList.remove('hidden');
  formElement.reset();

  var submitButton = formElement.querySelector('.submit-button');
  var buttonText = submitButton.querySelector('.button-text');
  var buttonLoader = submitButton.querySelector('.button-loader');

  submitButton.disabled = false;
  buttonText.classList.remove('hidden');
  buttonLoader.classList.add('hidden');

  var existingError = formElement.querySelector('.error-message');
  if (existingError) {
    existingError.remove();
  }

  setTimeout(function focusEmail() {
    var emailInput = formElement.querySelector('.email-input');
    if (emailInput) {
      emailInput.focus();
    }
  }, 500);
}

function handleReset() {
  var resendLinks = document.querySelectorAll('.resend-link');
  resendLinks.forEach(function attachListener(resendLink) {
    resendLink.addEventListener('click', function handleResend(e) {
      e.preventDefault();
      resetAltcha();
    });
  });
}

function showErrorMessage(formElement, message) {
  var existingError = formElement.querySelector('.error-message');
  if (existingError) {
    existingError.remove();
  }

  var errorDiv = document.createElement('div');
  errorDiv.className = 'error-message';
  errorDiv.textContent = message || 'Something went wrong. Please try again.';

  var submitButton = formElement.querySelector('.submit-button');
  formElement.insertBefore(errorDiv, submitButton);

  setTimeout(function removeError() {
    errorDiv.remove();
  }, 5000);
}

function handleFormSubmit(event) {
  event.preventDefault();

  var form = event.target;
  var submitButton = form.querySelector('.submit-button');
  var buttonText = submitButton.querySelector('.button-text');
  var buttonLoader = submitButton.querySelector('.button-loader');

  submitButton.disabled = true;
  buttonText.classList.add('hidden');
  buttonLoader.classList.remove('hidden');

  updateFormScroll();

  var formData = new FormData(form);

  fetch(form.action, {
    method: 'POST',
    body: formData,
  })
    .then(function handleResponse(response) {
      if (response.ok) {
        return response;
      }
      throw new Error('Subscription failed');
    })
    .then(function onSuccess() {
      showSuccessMessage(form);
    })
    .catch(function onError(error) {
      console.error('Subscription error:', error);
      showErrorMessage(form, 'Unable to subscribe. Please try again.');
      submitButton.disabled = false;
      buttonText.classList.remove('hidden');
      buttonLoader.classList.add('hidden');
    });
}

function initialize() {
  updateScrollPercentage();
  updateFormScroll();
  handleReset();

  subscribe(function onScrollChange(percentage) {
    console.debug('Scroll percentage changed to', percentage);
  });

  window.addEventListener('scroll', handleScroll);

  var forms = document.querySelectorAll('.newsletter-form');
  forms.forEach(function attachSubmitHandler(form) {
    form.addEventListener('submit', handleFormSubmit);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initialize);
} else {
  initialize();
}
