# The Easiest Way — Get an Instant localhost HTTPS URL with Tunnelmole

What if you could bypass all certificate generation and configuration with a single command? This is where tunneling tools come in, and Tunnelmole is a fantastic open-source option.

Tunnelmole works by creating a secure tunnel from a public, HTTPS-enabled URL to your local web server. When a request hits the public URL, Tunnelmole forwards it through the tunnel to your localhost application.

This approach gives you a valid, browser-trusted HTTPS URL without you ever having to create, sign, or manage an SSL certificate.

## How to Use Tunnelmole

Let's see how simple it is.

### Step 1: Have a Local Server Running

First, make sure your local web application is running. For this example, we'll use a basic Node.js Express server on port 3000.

```javascript
// server.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello from my secure localhost server!');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
```

Install dependencies with `npm install express`, then run it with `node server.js`.

### Step 2: Install Tunnelmole

If you have Node.js installed, the quickest way is via npm:

```bash
sudo npm install -g tunnelmole
```

Alternatively, for Linux, Mac, or WSL, you can use the curl script:

```bash
curl -O https://install.tunnelmole.com/xD345/install && sudo bash install
```

### Step 3: Run Tunnelmole

Now, open a new terminal and run a single command, telling Tunnelmole which port your server is on:

```bash
tmole 3000
```

Within seconds, you'll see output like this:

```
$ tmole 3000
Your Tunnelmole Public URLs are below and are accessible internet wide. Always use HTTPs for the best security

https://cqcu2t-ip-49-185-26-79.tunnelmole.net ⟶ http://localhost:3000
http://cqcu2t-ip-49-185-26-79.tunnelmole.net ⟶ http://localhost:3000
```

That's it! You now have a public, secure localhost HTTPS URL (`https://cqcu2t-ip-49-185-26-79.tunnelmole.net` in this case) that securely points to your local server running on `http://localhost:3000`.

You can open this URL in any browser, on any device, and you'll see your application running with a valid SSL certificate and the reassuring padlock icon. No warnings, no configuration.

## How Does Tunnelmole Work?

The magic behind Tunnelmole is a persistent WebSocket connection established between the client on your machine and a public Tunnelmole service host.

### Connection Flow

- **Connection:** The `tmole` client on your machine connects to the public Tunnelmole server and requests a unique public URL.
- **Tunneling:** When a user makes a request to your public HTTPS URL, the Tunnelmole server receives it.
- **Forwarding:** The server sends the request down the secure tunnel to the `tmole` client on your machine.
- **Local Request:** The client then makes a standard HTTP request to your local server (e.g., `localhost:3000`).
- **Response:** The response from your local server travels back along the same path to the user.

## Why Tunnelmole is a Superior Solution

Using Tunnelmole for localhost HTTPS has several distinct advantages:

- **Ultimate Simplicity:** It's a single command. There are no certificates to manage, no server configs to edit, and no system trust stores to modify.
- **Zero Configuration:** It works out of the box with any local web server, regardless of the language or framework you're using.
- **Publicly Accessible:** This is the killer feature. You can use your HTTPS URL to test webhooks from services like Stripe, Shopify, or Slack, which is impossible with a purely local setup.
- **Easy Collaboration:** Share the URL with teammates, designers, or clients to show your work-in-progress without deploying it.
- **Real-Device Testing:** Open the URL on your phone, tablet, or another computer to test the mobile and cross-browser experience accurately.
- **Open Source and Self-Hostable:** Trust and security are paramount. Tunnelmole is fully open-source, so you can inspect the code yourself. For maximum control and privacy, you can also self-host the Tunnelmole service on your own server.

## Conclusion: Choose the Right Tool for the Job

Securing your local development environment with HTTPS is essential for modern web development. While creating self-signed certificates is a viable but clunky option, and tools like mkcert offer a great solution for purely local work, Tunnelmole provides the fastest, most flexible, and most powerful way to get a localhost HTTPS URL.

It not only solves the immediate problem of needing a secure context for browser features but also opens up a world of possibilities by making your local server securely accessible to the internet for webhook testing, collaboration, and real-device debugging.

By abstracting away the complexities of SSL certificates, Tunnelmole lets you focus on what you do best: building great applications. Give it a try for your next project and experience the simplicity of one-command localhost HTTPS.
