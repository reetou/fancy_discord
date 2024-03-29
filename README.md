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
- [x] Handle case when there are no available machines
- [x] Attempt init app on app create
- [x] Dont update last_deploy_at when app was destroyed
- [x] Add premium apps and dont destroy em
- [x] Allow init after destroy
- [x] Add app status to show proper details and messages depending on it
- [x] Add update app settings
- [x] Add plug for checking if app exists in user
- [x] Add destroy app
- [x] Detect necessary buildpacks
- [x] Job logs
- [ ] Disable Dokku zero downtime deployments on create `checks:disable <app>` (or decide if its needed)
- [ ] Add getting stdout from bots machines with Vector.dev and NATS
- [ ] Add Discord webhook notifications about job status and deploy removal
- [ ] Encrypt bot tokens when sending over the network
- [ ] Add tests to apps creation and deploy scenarios
- [ ] Configurable cron jobs for bots for sending messages to channels via service
- [ ] Init deploy on deploy start if app was not initialized
- [ ] Add changing app type and handle it gracefully
