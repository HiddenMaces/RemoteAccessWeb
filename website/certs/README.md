# **Build RootCA**

# **Private Root CA and Client Authentication (mTLS) Guide**

This guide explains how to build a private Root Certificate Authority (CA), issue certificates for a web server (HTTPS), and issue certificates for clients (users) to serve as an authentication mechanism.   
This setup is often called **Mutual TLS (mTLS)** or **2-Way SSL**

## 

## **Overview of the Architecture**

**The Root CA:** The ultimate authority. It signs both the Server and Client certificates. Both the Web Server and the User's Browser must trust this CA.  
**The Server Certificate:** Installed on your web server (Nginx/Apache). Used to encrypt traffic (HTTPS).  
**The Client Certificate:** Installed in the user's system/browser. Used to identify the user to the server.

## 

## **Prerequisites**

You will need a Linux/Unix terminal with openssl installed.

Create a directory to keep your files organized:

```shell
mkdir -p ~/my-ca/{certs,private,newcerts,csr,cnf}cd ~/my-cachmod 700 private
```

## **Create the Root CA**

The Root CA is the "trust anchor."

### **1\. Generate the Root Key**

This is the most sensitive file. Protect it with a strong password (-aes256).   
Don’t loose it, or forget the password 🙂

```shell
openssl genrsa -aes256 -out private/rootCA.key 4096
```

Parameters:

* genrsa: Generate a RSA key  
* \-out: location where to place the key and its name  
* 4096: length of the key, lower number means less secure, higher means more secure) Best practice for systems/applications is 2048 bits long

### **2\. Generate the Root Certificate**

This creates a self-signed certificate valid for 10 years (3650 days). You will be asked for Country, State, Org, etc.  
Parameters:

* req: request a certificate  
* \-x509: format of the certificate  
* \-key: which key must be used  
* \-sha256: use SHA256  
* \-days: numbers of days the certificate is valid (3650 \= 10 years)  
* \-out: the created signed certificate


When the command is executed, it will ask information about the organization.  
The most important and mandatory information is the **Common Name (CN)**  
This is what you see in the certificate stores etc.  
It contents doesn’t matter in case of a RootCA, best practice is to enter some descriptive information about the RootCA.  
For example: “My Internal RootCA”

```shell
openssl req -x509 -new -nodes -key private/rootCA.key  -sha256 -days 3650 -out certs/rootCA.crt
```

This is it.  
You have now a signed rootCA. Keep the 2 files safe. With these 2 files you can sign any request. This means that if somebody gets an hold of those file, he could sign a certificate for [www.google.com](http://www.google.com)  
If a system trusts your rootCA, they won’t know if they access the real [google.com](http://google.com) or a bogus one.

# **Server certificates**

## **Create the Server Certificate (For a Website)**

This certificate allows your web server to use HTTPS. Best practice is to use the fqdn throughout the whole process. It keeps it simple 👍  
This can be done on any system. It doesn’t have to be the web server itself.  
To use this certificate, the webserver only needs the certificate (.crt) and the key (.key)

### **1\. Generate the Server Private Key**

We usually do *not* password protect the server key, so the web server can restart automatically. Otherwise every time you restart the server, it will ask for the password of the private key.

```shell
openssl genrsa -out private/FQDN.key 2048
```

Parameters:

* genrsa: Generate a RSA key  
* \-out: location where to place the key and its name  
* 2048: length of the key, lower number means less secure, higher means more secure) Best practice for systems/applications is 2048 bits long

### **2\. Create a Configuration File for SANs**

Modern browsers (Chrome/Edge) require a "Subject Alternative Name" (SAN). Creating a CSR without this will result in security warnings in modern browsers.  
Create a file named cnf/**FQDN**\_ext.cnf:

```
[ server_ext ]
# 1. AUTHORITY & SUBJECT IDs
# These link the cert to the CA and itself.
authorityKeyIdentifier=keyid,issuer
subjectKeyIdentifier=hash

# 2. BASIC CONSTRAINTS
# CA:FALSE means this cert cannot sign other certs.
basicConstraints = CA:FALSE

# 3. KEY USAGE
# digitalSignature: used for authentication (SSL handshake)
# keyEncipherment: used for key exchange (RSA)
keyUsage = digitalSignature, keyEncipherment

# 4. EXTENDED KEY USAGE
# serverAuth: Allowed to be a Web Server
# clientAuth: (Optional) Allowed to identify itself to a server
extendedKeyUsage = serverAuth

# 5. SUBJECT ALTERNATIVE NAMES (SAN)
# This is the most important part for Chrome/Safari.
# List all DNS names and IP addresses this cert covers.
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = mywebsite.local
DNS.2 = www.mywebsite.local
DNS.3 = localhost

# You can also add IP addresses if you access via IP
IP.1 = 127.0.0.1
IP.2 = 192.168.1.50
```

*DNS.1 is mandatory, the rest is optional.*

### **3\. Generate the Server CSR (Signing Request)**

When the command is executed, it will ask information about the organization. The most important and mandatory information is the **Common Name (CN)**  
This is what you see in the certificate stores etc. The contents of CN must match your server fqdn (or domain)

```shell
openssl req -new -key private/mywebsite.key -out csr/mywebsite.csr
```

Parameters:

* req: request a certificate  
* \-new: create a new request  
* \-key: which key must be used (the previous created key)  
* \-out: the created certificate signing request

### **4\. Sign the Server Certificate with the Root CA**

On a system with the 2 RootCA files, you can sign the csr and create the certificate. This uses the Root CA key to sign the Server CSR.

```shell
openssl x509 -req -in csr/fqdn.csr -CA certs/rootCA.crt -CAkey private/rootCA.key -CAcreateserial -out certs/mywebsite.crt  -days 825 -sha256 -extfile cnf/fqdn_ext.cnf
```

Parameters:

* x509: the format of the certificate  
* \-req: request a certificate  
* \-in: the certificate signing request file  
* \-CA: the rootCA certificate to be used for the signing  
* \-CAkey: the private key which belongs to the rootCA certificate  
* \-CAcreateserial: creates a unique serial number. This ensures your certificates are uniquely trackable.  
* \-out: your signed Public Certificate. You will configure your web server (Nginx, Apache) to use this file  
* \-days: This sets the expiration date. This is a specific number adopted by Apple (macOS/iOS). macOS Catalina and newer require TLS server certificates to have a validity period of 825 days or fewer.Otherwise they reject the certificate as "unsafe."  
* \-sha256: This forces the signature algorithm to use SHA-256. Older algorithms (like SHA-1) are considered insecure and are blocked by modern browsers.  
* \-extfile: This applies specific X.509 extensions defined in the created configuration file.

# **Client certificates**

## **Create the Client Certificate (For User Auth)**

This certificate is for a specific user (e.g., "Alice").

### **1\. Generate the Client Key**

```shell
openssl genrsa -out private/alice.key 2048
```

Parameters:

* genrsa: Generate a RSA key  
* \-out: location where to place the key and its name  
* 2048: length of the key, lower number means less secure, higher means more secure) Best practice for systems/applications is 2048 bits long

### **2\. Generate the Client CSR**

When the command is executed, it will ask information about the organization. The most important and mandatory information is the **Common Name (CN)**  
This is what you see in the certificate stores etc. The contents of CN can match your name.

```shell
openssl req -new -key private/alice.key -out csr/alice.csr
```

Parameters:

* req: request a certificate  
* \-new: create a new request  
* \-key: which key must be used (the previous created key)  
* \-out: the created certificate signing request

### **3\. Sign the Client Certificate**

We do not need SANs for client certs, usually just the Common Name is enough.

```shell
openssl x509 -req -in csr/alice.csr -CA certs/rootCA.crt -CAkey private/rootCA.key -CAcreateserial -out certs/alice.crt -days 365 -sha256
```

Parameters:

* x509: the format of the certificate  
* \-req: request a certificate for a signing request  
* \-in: the certificate signing request file  
* \-CA: the rootCA certificate to be used for the signing  
* \-CAkey: the private key which belongs to the rootCA certificate  
* \-CAcreateserial: creates a unique serial number. This ensures your certificates are uniquely trackable.  
* \-out: your signed Public Certificate. You will configure your web server (Nginx, Apache) to use this file  
* \-days: This sets the expiration date. 365 \= 1 year. This is good practice for identity certs  
* \-sha256: This forces the signature algorithm to use SHA-256. Older algorithms (like SHA-1) are considered insecure and are blocked by modern browsers.

### **4\. Package into PKCS\#12 (.p12 or .pfx)**

This command creates a Certificate Bundle (often called a PFX or P12 file). Think of it as packing a "digital suitcase." You are taking three separate loose files (Alice's ID card, Alice's secret key, and the Authority's stamp) and locking them inside a single, password-protected file (.p12). The command will ask for a export password. You need this password when importing it in a certificate store.

 Why is this nessecary?  
You cannot easily install a raw .key and .crt file into a web browser or Windows/macOS. They expect a single file that contains everything. Some servers need also a .p12 or .pfx file. For example Windows Server IIS often require this.

```shell
openssl pkcs12 -export -out certs/alice.p12 -inkey private/alice.key -in certs/alice.crt -certfile certs/rootCA.crt
```

Parameters:

* pkcs12: The utility for the PKCS\#12 standard (Personal Information Exchange).  
* \-export: Tells OpenSSL we are creating a file (packing), not reading one."  
* \-out:  The final packed suitcase. This is the file you will send to the user.  
* \-inkey: The Secret. The private key that matches the certificate.  
* \-in: The users public certificate (the leaf certificate).  
* \-certfile: The Trust. The Root CA certificate. Including this ensures the computer that receives this file knows exactly which Authority verified the user.

# **Config systems/apps**

# **Web Server Configuration**

You now need to configure your web server to require these client certificates.

## **Option A: Nginx Configuration**

```
server {    listen 443 ssl;    server_name mywebsite.local;    # 1. Server Identity    ssl_certificate     /path/to/certs/mywebsite.crt;    ssl_certificate_key /path/to/private/mywebsite.key;    # 2. Client Authentication Config    # The CA that signed the client certs    ssl_client_certificate /path/to/certs/rootCA.crt;         # 'on' forces a certificate. 'optional' asks for it but allows access without (handled in app logic)    ssl_verify_client on;     location / {        root /var/www/html;        index index.html;                # Optional: Pass the username to the backend application        fastcgi_param REMOTE_USER $ssl_client_s_dn_cn;     }}
```

## **Option B: Apache Configuration**

```
<VirtualHost *:443>    ServerName mywebsite.local    SSLEngine on    # 1. Server Identity    SSLCertificateFile      /path/to/certs/mywebsite.crt    SSLCertificateKeyFile   /path/to/private/mywebsite.key    # 2. Client Authentication Config    SSLCACertificateFile    /path/to/certs/rootCA.crt    SSLVerifyClient         require    SSLVerifyDepth          1        DocumentRoot /var/www/html</VirtualHost>
```

# **Browser Setup (Client Side)**

If you try to visit the site now, you will get a "Connection Reset" or "400 Bad Request \- No required SSL certificate was sent" error.

## **1\. Install the Root CA**

To remove the "Not Secure" warning in the address bar:

1. Copy rootCA.crt to the client machine.

2. **Windows:** Double click \-\> Install Certificate \-\> Local Machine \-\> **Trusted Root Certification Authorities**.

3. **MacOS:** Keychains \-\> System \-\> Certificates \-\> Drag file in \-\> Double click \-\> Trust \-\> **Always Trust**.

4. **Firefox:** Settings \-\> Privacy & Security \-\> View Certificates \-\> Authorities \-\> Import.

## **2\. Install the Client Certificate**

To actually log in:

1. Copy alice.p12 to the client machine.

2. Double click the file.

3. Enter the **Export Password** you created in Step 3.4.

4. Restart the browser.

## **3\. Test**

Visit https://mywebsite.local.

1. The browser should verify the server is safe (thanks to Root CA import).

2. The browser should popup a window asking: "Select a certificate to authenticate yourself".

3. Select "alice".

4. You are in\!

# **Security Note**

If you lose the private/rootCA.key, you cannot issue new certs. If someone steals it, they can sign fake certificates for *any* website (https://www.google.com/search?q=google.com, etc.) and your browser will trust it if you installed the Root CA. Keep the root key offline or very secure.