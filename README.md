![KudoChest Logo](https://github.com/jcraigk/biz-kudochest/blob/main/app/assets/images/logos/app-144.png)
&nbsp;
&nbsp;


**KudoChest** is a team engagement tool for **Slack**. It allows users within a workspace to give each other tokens of gratitude, called kudos, that accrue over time. This boosts team morale and improves productivity. Users can view their profile, browse history, and access leaderboards on the web or within the chat client. App settings and moderation tools are provided via web UI.

This is a **Ruby on Rails** application backed by **Postgres** and **Redis**. It integrates tightly with chat platforms, keeping teams and users synced server-side. This enables web-based user profiles and other UX enhancements not possible in standard bots.
&nbsp;
&nbsp;


# Development

For local development, start by reading the [Installation Instructions](https://github.com/jcraigk/kudochest/wiki/Installation), paying special attention to the [Environment Variables](https://github.com/jcraigk/kudochest/wiki/Installation#environment-variables) section. Note that you will only need certain portions of what is described there, depending on your specific area of development.

## Setup

For Slack and OAuth callbacks, a tunneling service such as [ngrok](https://ngrok.com/) is recommended to expose your local server publicly.

You'll want to setup a dedicated workspace and App in Slack specifically for KudoChest development. Do not use your organization's production workspace or App to develop against.

If you're working on response images and running Sidekiq in Docker, you'll need to configure a local storage location in `docker-compose.yml` to map to `/storage` in the `sidekiq` container.
&nbsp;
&nbsp;


## Run the App Components

You may run all components in Docker with logging exposed using the command `make up` and then connect to the `kudochest_app` container and create the database.

Alternatively you can run services (PG and Redis) in Docker while running the Rails processes natively. This often eases debugging and development.

For running the Rails stack you'll need Ruby (use [rvm](https://rvm.io/) or [asdf](https://asdf-vm.com/)).

```bash
# Install Ruby dependencies
bundle install

# Initialize database
make services
bundle exec rails db:create
bundle exec rails db:reset

# Start web server (terminal 1)
bundle exec rails s

# Start Sidekiq (terminal 2)
bundle exec sidekiq
```
&nbsp;

## Testing

To run specs in Docker:

```
make spec
```

To run specs natively:

```
make services
bundle exec rspec
```

To generate seed data for manual testing, first install your local instance of KudoChest into a development workspace and then run

```
bundle exec rails seeds:all
```



# NEW BOX SETUP

1. Create droplet in SFO3 with `kudochest` and `web` tags

2. Setup non-root login (skip this?)
```
ssh root@<kudochest-host>
adduser <admin-user>
usermod -aG sudo <admin-user>
su - <admin-user>
mkdir ~/.ssh
chmod 700 ~/.ssh
vim ~/.ssh/authorized_keys
# => Paste result of local: `cat ~/.ssh/id_rsa.pub`
chmod 600 ~/.ssh/authorized_keys
exit
sudo vim /etc/ssh/sshd_config
# => Change PermitRootLogin to "no"
sudo systemctl reload sshd
exit
ssh <admin-user>@<kudochest-host>
```

3. Install Dokku
```
wget -NP . https://dokku.com/install/v0.32.0/bootstrap.sh
sudo DOKKU_TAG=v0.32.0 bash bootstrap.sh
```

4. Configure Dokku

```
# Add deploy key
echo 'CONTENTS_OF_ID_RSA_PUB_FILE' | dokku ssh-keys:add admin

# Create app
dokku apps:create kudochest

# Setup local storage
sudo mkdir -p /var/lib/dokku/data/storage/kudochest/response_images/tmp
sudo mkdir -p /var/lib/dokku/data/storage/kudochest/response_images/cache
sudo chmod -R 777 /var/lib/dokku/data/storage/kudochest
dokku storage:mount kudochest /var/lib/dokku/data/storage/kudochest:/storage

# Domain
dokku domains:set kudochest kudochest.com

# Port forwarding
dokku proxy:ports-set kudochest http:80:3000 https:443:3000
dokku config:set kudochest <env vars>
```

4. SSL config (skip if LB terminates SSL)
```
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
dokku letsencrypt:set kudochest email kudochest@gmail.com
dokku letsencrypt:enable kudochest
```

5. Download the cert/key? (This isn't necessary)
```
Your account credentials have been saved in your Let's Encrypt
configuration directory at "/certs/accounts".
You should make a secure backup of this folder now

# Direct access via Dokku certs
dokku certs:show kudochest crt
dokku certs:show kudochest key
```

6. Add new IP to `WEB_BOXES` env var so `bin/deploy` uses it
