# FancyDiscord

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

## TODO
- [x] Create jobs in gitlab
- [ ] Refresh jobs status with cron job
- [ ] Limit apps creating to 1
- [ ] Create user_id field in apps table
- [ ] Kill deploys older than 4 hours, remove apps from dokku machine and reset apps' `dokku_host` fields so it can be deployed on new machine later
- [ ] Assign dokku host for ip on deploy
- [ ] Add case for `FancyDiscord.Deploy.start_deploy/1` when app's `dokku_host` is `nil`
- [ ] Discord auth
- [ ] Detect necessary buildpacks
- [ ] Add getting stdout from bots machines
- [ ] Encrypt bot tokens when sending over the network
- [ ] Add Discord webhook notifications about job status and deploy removal
- [ ] Add tests to apps creation and deploy scenarios
- [ ] Configurable cron jobs for bots for sending messages to channels via service
