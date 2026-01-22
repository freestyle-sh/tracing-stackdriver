# NGINX Configuration Examples for Error Handling

This directory contains example NGINX configuration files that demonstrate proper error handling patterns, specifically addressing the issue where HTTP 503 was being used for both maintenance mode and other server errors.

## Problem Statement

Previously, the maintenance page was being served for many different errors because HTTP 503 (Service Unavailable) was being used to indicate maintenance mode, but 503 was also being generated for other reasons like backend failures, timeouts, and other issues.

## Solution

This configuration separates maintenance mode from other error conditions:

### Error Code Usage

- **503 (Service Unavailable)**: Reserved ONLY for scheduled maintenance mode
  - Triggered by the presence of `/var/www/maintenance.flag` file
  - Displays `maintenance.html`

- **502 (Bad Gateway)**: Backend server is down or unreachable
  - Occurs when upstream server cannot be reached
  - Displays `502.html`

- **504 (Gateway Timeout)**: Backend server timeout
  - Occurs when upstream server takes too long to respond
  - Displays `504.html`

- **500 (Internal Server Error)**: Application errors
  - Occurs when the application encounters an error
  - Displays `500.html`

- **429 (Too Many Requests)**: Rate limiting
  - Occurs when rate limits are exceeded
  - Displays `429.html`

## Files

```
examples/nginx/
├── nginx.conf                  # Main NGINX configuration
├── error-pages/
│   ├── maintenance.html        # Scheduled maintenance page (503)
│   ├── 502.html               # Bad Gateway error page
│   ├── 504.html               # Gateway Timeout error page
│   ├── 500.html               # Internal Server Error page
│   └── 429.html               # Too Many Requests page
└── README.md                   # This file
```

## Usage

### Basic Setup

1. Copy the `nginx.conf` to your NGINX configuration directory:
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/your-site
   sudo ln -s /etc/nginx/sites-available/your-site /etc/nginx/sites-enabled/
   ```

2. Copy the error pages to your web root:
   ```bash
   sudo cp -r error-pages/* /var/www/html/
   ```

3. Test and reload NGINX:
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

### Enabling Maintenance Mode

To enable maintenance mode, simply create the maintenance flag file:

```bash
sudo touch /var/www/maintenance.flag
```

To disable maintenance mode, remove the flag file:

```bash
sudo rm /var/www/maintenance.flag
```

### Customization

#### Change Maintenance Flag Location

Edit the `nginx.conf` file and update the path in the `if` statement:

```nginx
if (-f /your/custom/path/maintenance.flag) {
    return 503;
}
```

#### Customize Error Pages

All error pages are standard HTML files. You can edit them to match your branding:

```bash
sudo nano /var/www/html/maintenance.html
```

#### Add Backend Servers

Update the `upstream backend` block in `nginx.conf`:

```nginx
upstream backend {
    server backend1.example.com:8080 max_fails=3 fail_timeout=30s;
    server backend2.example.com:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}
```

## Testing

### Test Maintenance Mode

```bash
# Enable maintenance
sudo touch /var/www/maintenance.flag
curl -I http://localhost
# Should return HTTP 503 with maintenance page

# Disable maintenance
sudo rm /var/www/maintenance.flag
curl -I http://localhost
# Should return normal response
```

### Test Other Error Pages

You can test other error pages by temporarily configuring NGINX to return specific status codes:

```nginx
location /test-502 {
    return 502;
}

location /test-504 {
    return 504;
}
```

## Integration with Tracing-Stackdriver

When using this NGINX configuration with applications that use the `tracing-stackdriver` library, error responses will be properly logged with their correct HTTP status codes, making it easier to distinguish between:

- Scheduled maintenance (503)
- Infrastructure issues (502, 504)
- Application errors (500)
- Rate limiting (429)

This improves observability and helps with debugging and monitoring in Google Cloud Operations Suite.

## Best Practices

1. **Always use the maintenance flag file**: Never return 503 directly for other error conditions
2. **Monitor upstream health**: Configure proper health checks in your upstream blocks
3. **Set appropriate timeouts**: Adjust `proxy_*_timeout` values based on your application's needs
4. **Log errors appropriately**: Ensure error logs are being sent to your monitoring system
5. **Test maintenance mode regularly**: Verify that maintenance mode works as expected before you need it
6. **Keep error pages simple**: Error pages should load quickly and have minimal dependencies
7. **Provide helpful information**: Include relevant contact information or status page links

## Troubleshooting

### Maintenance page not showing
- Check that `/var/www/maintenance.flag` exists
- Verify NGINX configuration syntax: `sudo nginx -t`
- Check NGINX error logs: `sudo tail -f /var/log/nginx/error.log`

### Wrong error page displayed
- Verify error page files exist in `/var/www/html/`
- Check file permissions: `sudo chmod 644 /var/www/html/*.html`
- Ensure `error_page` directives are not being overridden in other config files

### Backend connection issues
- Verify upstream server is running
- Check firewall rules between NGINX and backend
- Test direct connection: `curl http://backend-ip:port`
