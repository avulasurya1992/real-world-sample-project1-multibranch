# Use official Apache HTTP Server image
FROM httpd:latest

# Copy all HTML files from the repo root into the Apache web server's document root
COPY *.html /usr/local/apache2/htdocs/
