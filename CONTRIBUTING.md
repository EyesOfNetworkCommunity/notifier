# Contribution Guidelines
## Table of Contents
- [Contribution Guidelines](#contribution-guidelines)
  - [Introduction](#introduction)
  - [Maintainers](#maintainers)
  - [Bug reports](#bug-reports)
  - [Add functionnalities or bug corrections](#add-functionnalities-or-bug-correction)
  - [Sign your work](#sign-your-work)
  - [Versionning](#versionning)

## Introduction
This document explains how to contribute changes to the [EyesOfNetwork](http://www.eyesofnetwork.com) notifier project.

## Maintainers
This part of [EyesOfNetwork](http://www.eyesofnetwork.com) solution is maintained essentialy by one person.  
All of team can review and help us on issue.

## Bug reports
Please, ensure you've already search into issue tracker than your issue not already exist or will be solved.  
If unique, [open an issue](https://github.com/EyesOfNetworkCommunity/notifier/issues/new) and answer the questions so we can understand and reproduce the problematic behavior.

Please, on issue creation, **write clear and concise**. Specify all configurations or command you've launch to could be reproduce error in all time you send.

Please be kind, remember that [EyesOfNetwork](http://www.eyesofnetwork.com) is communal development.

## Add functionnalities or bug correction
To actively contribute to this project, you could generate pull request to include your modifications if you think this is needed to merged into standard project.  
We work with pull request to integrate new functionnalities. This permit us to review proposed change, discuss on it, check it, modify it, and validate or not the change.

Somes conditions to create pull request :
  1. You'll don't break existing code.
  2. You'll don't cause ANY regression (speed or functionnalities).
  3. On released version, only security correctives could be merged. No functionnalities adds.
  4. You'll only pass by repository fork and pull request to add something.

How to contribute :
  1. Fork master branch
  2. Update project into your fork
  3. Create pull request

## Sign your work
When you add or modify code, please, just sign your commit with your real name.  
To do this, just add to end of your commit the next line  
```
Signed-off-by: John DOE <john.doe@domain.tld>
```
Or if you've GPG key, directly sign your commit with it by a simple `git commit -S`

## Versionning
To generate new releases of project, we work on not finished code into specific branch sur as `release/v2.1-1`.  
This method permit to not break master branch with new code, and to follow much easier new changes.

When new release is finished to write, we merge it onto master branch, we create new tag `2.1-1` and drop branch.