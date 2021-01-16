# FancyDiscord

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

## TODO
- [x] Create jobs in gitlab
- [x] Refresh jobs status with cron job
- [x] Limit apps creating to 1
- [x] Create user_id field in apps table
- [x] Assign dokku host for ip on deploy if there is no ip assigned
- [x] Add case for `FancyDiscord.Deploy.start_deploy/1` when app's machine is nil
- [x] Kill deploys older than 4 hours (jobs that succeeded more than 4 hours ago), remove apps from dokku machine and reset apps' machine field so it can be deployed on new machine later
- [x] Discord auth
- [ ] Detect necessary buildpacks
- [ ] Add getting stdout from bots machines with Vector.dev and NATS
- [ ] Add Discord webhook notifications about job status and deploy removal
- [ ] Encrypt bot tokens when sending over the network
- [ ] Add tests to apps creation and deploy scenarios
- [ ] Configurable cron jobs for bots for sending messages to channels via service
