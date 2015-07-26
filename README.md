[![Circle CI](https://circleci.com/gh/luxola/apple-pie.svg?style=svg)](https://circleci.com/gh/luxola/apple-pie)
[![Code Climate](https://codeclimate.com/github/luxola/apple-pie/badges/gpa.svg)](https://codeclimate.com/github/luxola/apple-pie)
[![Test Coverage](https://codeclimate.com/github/luxola/apple-pie/badges/coverage.svg)](https://codeclimate.com/github/luxola/apple-pie/coverage)

# Apple Pie

A devops tool for code & feature reviews involving developers, product and UI/UX.


## Backstory

As the team grew, more people (including non developers) became involved in the development of a feature:

1. Reviewing developer: reviews the code
1. Product: reviews the feature
1. UI/UX: reviews UI/UX

These roles are not fixed. The reviewing developer can also be involved in reviewing the feature from the frontend and some developers are happy to provide UI/UX opinions. UI/UX can be involved in feature reviews too. These reviews starts when a Github Pull Request (PR) is created. 

Tools involved in the reviewing process:

1. Github's Pull Request
1. Pivotal Tracker (our project management tool)

## Process

1. Reviewing developer approves code
2. Product approves
3. UI/UX approves
4. Note: the above 3 may run in parallel
5. Reviewing developer gives the final approval to merge the Pull Request to the master branch.


## Problem

For each Pull Request, the reviewing developer needs to go the specific Pivotal Tracker story to search through comments which indicates that Product and UI/UX has approved the feature. Overtime, this becomes tedious.

## Solution

An integration to reflect the approvals from Product and UI/UX in the Pull Request.


## How it works

* Based on certain keywords in the PT story comments (eg. `ui ok`, `feature ok`) 
* The statuses will be updated in the 1st comment section (aka the body of the PR)
* This tool assumes that the Pull Request title contains the feature's Pivotal Tracker story ID.

### Example

```
~~~~~ Statuses ~~~~~
UI :+1:
Feature :hand:
Updated 2015-01-01 00:00:00 +0800
~~~~~ do not add text below ~~~~~
```

This indicates that:

* UI is approved
* Feature is still pending approval


## Deployment

This is a Sinatra app and is ready for use on Heroku

1. Deploy to Heroku
1. Add environment variables
1. At Github, configure Webhooks. 
	1. Payload URL: `https://your-apple-pie-app.com/gh_webhook`
	1. Events to trigger webhook: `Pull Request` only
	1. Tick `Active` checkbox
1. At Pivotal Tracker, Integrations:
	1. Under Activity Web Hook section, add `https://your-apple-pie-app.com/pt_activity_web_hook`, select `v5`


### Environment variables

* `GITHUB_USER`: Owner or organization this repository belongs to
* `GITHUB_REPO`: Github repository name
* `GITHUB_TOKEN`: Personal token of a user who has access to the repository. Using a [machine user](https://developer.github.com/guides/managing-deploy-keys/#machine-users) is recommended.


### Try it

1. Create a story in Pivotal Tracker
1. Create a new Pull Request, the statuses are automatically added 
1. Add a comment in the Pivotal Tracker story which contains the text `ui ok`, the status will be updated
1. Try the above with `feature ok` this time.


## FAQ

### Can I contribute?

Why not? Please submit a Pull Request. If not, feel free to submit a issue ticket to start a discussion.

### Why is this named Apple Pie?

Honestly, for no good reason. I will be happy to take in suggestions for a more meaningful name.