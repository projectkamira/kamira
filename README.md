# Kamira :: An Open Source Clinical Quality Modeling Framework

[Kamira](http://projectkamira.org) is an open source software project designed to measure Clinical Quality Measures (CQMs) based on the availability of their supporting data, their financial impact, and the complexity of their calculations.

## Installation

This project currently uses Node.js with Express as its web application framework, plus ruby 1.9.3 for setup.

This README file includes general setup instructions; some more specific instructions can be found for Ubuntu in the file ubuntu-deployment-notes.txt

### Dependencies

#### Git

Git is required to download the Kamira source code. Instructions for installing Git are available [here](http://git-scm.com/).

#### Ruby 1.9.3

Kamira uses Ruby 1.9.3 during the setup process. Instructions for installing Ruby are available [here](http://www.ruby-lang.org/en/downloads/)

#### Bundler

Bundler is used to manage setup dependencies. To install Bundler, run the following command:

    gem install bundler

#### Node.js

Node.js is used for the web application. Installers for Node.js can be found [here](http://nodejs.org/download/)

#### MongoDB

Kamira uses the MongoDB database, and requires version 2.2.0 or higher. Instructions for installing MongoDB are available [here](http://www.mongodb.org/downloads). When setting up MongoDB, make sure the Mongo 'bin' directory is in your operating system's PATH environment variable.

### Kamira Application

#### Installing Kamira

Download the Kamira application using git

    git clone git://github.com/kamira/kamira.git

#### Setting up Kamira

After downloading, some setup is required. You will need an NLM account in order to load value sets from the VSAC service and download the measure bundle. Register for an account [here](https://uts.nlm.nih.gov/home.html). Once you have an account, load the bundle and value sets:

    cd kamira/setup
    bundle
    curl -u NLM_USERNAME:NLM_PASSWORD http://demo.projectcypress.org/bundles/bundle-latest.zip -o ./bundle-latest.zip
    bundle exec rake bundle:import[./bundle-latest.zip,true,'ep']
    bundle exec rake download_valuesets[NLM_USERNAME,NLM_PASSWORD]
    bundle exec rake populate_measure_complexity[./bundle-latest.zip,'ep']

#### Running Kamira

Start the Node.process from the kamira root directory with

    npm start
