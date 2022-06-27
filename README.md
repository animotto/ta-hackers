# Trickster Arts Hackers reverse engineering
![GitHub](https://img.shields.io/github/license/animotto/ta-hackers)
[![Tests](https://github.com/animotto/ta-hackers/actions/workflows/tests.yml/badge.svg)](https://github.com/animotto/ta-hackers/actions/workflows/tests.yml)

## Overview
This tool provides a sandbox for researching of the network API of the Hackers mobile game, originally developed by Trickster Arts

## Disclaimer
This project is for research purposes only. All source code is provided as is. I don't condone of exploiting vulnerabilities or cheating in this game, you act at your own risk.

## Sandbox
It uses my [sandbox-ruby](https://github.com/animotto/sandbox-ruby) gem

The sandbox consists of the following contexts:
- `chat` Internal chat
- `market` Purchases of various ingame items
- `mission` Managing your missions
- `net` Maintenance your network
- `prog` Managing your programs
- `query` Creating and analyzing queries to the API server
- `script` Running your own scripts to interact with the sandbox
- `top` Top players
- `world` World map

## How to run it

Clone the repository to your local machine and prepare the environment:
```console
git clone https://github.com/animotto/ta-hackers
cd ta-hackers
bundle install
export RUBYLIB=$PWD/lib
```

Create a new account and write the credentials to the config named *my*:
```console
./bin/sandbox -n my
```

Run the sandbox with the config *my*:
```console
./bin/sandbox -c my
```

## Contributing

Any suggestions are welcome, just open an issue on Github. If you want to contribute to the source code, you can fork this repository and submit a pull request.

## License
See the [LICENSE](LICENSE) file
