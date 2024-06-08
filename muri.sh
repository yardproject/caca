#!/bin/bash

domain=$(curl -sS --insecure https://raw.githubusercontent.com/username/repo/main/domain.txt)

acme.sh --issue -d "$domain" --dns \
 --yes-I-know-dns-manual-mode-enough-go-ahead-please
