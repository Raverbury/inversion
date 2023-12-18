# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.4]

## Fixed

- Client occasionally freezing when game is decided
- Screenshot path using editor prefix of res:// in build

### Changed

- Deactivated effects no longer expire (thus triggering deactivation twice)
- Effects are no longer removed on disconnect
- Broadcast command response only to the command invoker when execution failed
- Update some effects' un-proc text color to match with other effects
- Temporarily swap Scout's sprites due to bad clipping
- Other misc fixes