# 👁️ EyeSeeYou

<p align="center">
    <a href="https://github.com/u8slvn/eye-see-you/actions/workflows/build-and-push.yml"><img src="https://img.shields.io/github/actions/workflow/status/u8slvn/eye-see-you/build-and-push.yml?label=Build" alt="Build"></a>
    <a href="https://github.com/u8slvn/eye-see-you"><img alt="GitHub License" src="https://img.shields.io/github/license/u8slvn/eye-see-you"></a>
</p>

Simply watch URLs and get notified when they change.

**Security Notice:** This is a personal tool designed for local/private network use. Not recommended for production environments.

```bash
docker run -e URLS="https://example.com" \
           -e EMAIL_USER="your@email.com" \
           -e EMAIL_PASSWORD="password" \
           -e RECIPIENT_EMAIL="notify@email.com" \
           eye-see-you
```

```yaml
version: '3'
services:
  eye-see-you:
    image: eye-see-you:latest
    container_name: eye-see-you
    environment:
      - URLS=https://example.com,https://another-site.com
      - CHECK_INTERVAL=300
      - EMAIL_USER=your@email.com
      - EMAIL_PASSWORD=your-password
      - RECIPIENT_EMAIL=notify@email.com
    restart: unless-stopped
```

Environment Variables

* `URLS`: Comma-separated URLs to monitor
* `CHECK_INTERVAL`: Seconds between checks (default: 300)
* `EMAIL_USER`: Your email
* `EMAIL_PASSWORD`: Your email password
* `RECIPIENT_EMAIL`: Where to send alerts
* `SMTP_SERVER`: SMTP server (default: smtp.gmail.com)
* `SMTP_PORT`: SMTP port (default: 587)
