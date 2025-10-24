import re
from textwrap import dedent

include = re.compile(r"blog/[1-9].*")


def on_page_markdown(markdown, page, config, files, **kwargs):
    if not include.match(page.url):
        return markdown

    page_url = page.url

    subscription_form = dedent(
        f"""
    <div class="newsletter-form-container">
      <h3>📬 Join the Newsletter</h3>
      <p class="form-description">
        Get weekly insights on DevOps, cloud infrastructure, and production-grade development.
      </p>

      <form
        class="newsletter-form listmonk-form"
        data-pirsch-event="subscribe"
        data-pirsch-meta-page_url="{page_url}"
        data-pirsch-meta-variant="footer"
        data-pirsch-non-interactive
        action="https://newsletter.meysam.io/subscription/form"
        method="post"
      >
        <input type="hidden" name="nonce" />
        <input type="hidden" name="l" value="00a2c2b8-467a-4d74-9c76-9c6472c91d06" />

        <div class="form-group">
          <input
            type="email"
            name="email"
            placeholder="your@email.com"
            required
            aria-label="Email address"
            class="email-input"
          />
        </div>

        <altcha-widget
          class="altcha-widget"
          challengeurl="https://newsletter.meysam.io/api/public/captcha/altcha"
          auto="onfocus"
        ></altcha-widget>

        <button type="submit" class="btn btn-primary submit-button">
          <span class="button-text">Join 1,500+ Engineers</span>
          <span class="button-loader hidden">
            <svg class="spinner" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
            </svg>
            Subscribing...
          </span>
        </button>

        <p class="form-note">No spam. Unsubscribe anytime. Privacy respected.</p>
      </form>

      <div class="success-message hidden">
        <div class="success-icon">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
        </div>
        <h3 class="success-title">Check Your Email!</h3>
        <p class="success-description">
          We've sent a confirmation link to your inbox. Click it to complete your subscription.
        </p>
        <p class="success-note">
          Don't see it? Check your spam folder or <a class="resend-link">click here to resend</a>.
        </p>
      </div>
    </div>
    """
    )

    return markdown + subscription_form
