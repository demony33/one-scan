#!/bin/bash

#set vars
scope="$(pwd)/scope"
outpath="$(pwd)/output"
wordlists="$HOME/wordlist"

#check you are root or not
if [ "$EUID" -ne 0 ]
  then echo -n "Please run as root"
  exit
fi

### PERFROM SCAN ###

printf "\x1b[32m ---> [ Starting scan against roots:]\\x1b[0m\n" ;

## DNS Enumeration -Find Subdomains
amass enum -passive -norecursive -noalts -df "$scope/domains.txt" | anew "$outpath/subs.txt"

subfinder -dL "$scope/domains.txt" -all | anew "$outpath/subs.txt"

shuffledns -l "$scope/domains.txt" -w "$wordlists/2m-subdomains.txt" -r "$wordlists/resolvers-trusted.txt" | anew "$outpath/subs.txt"

## DNS Resolution - Resolver Discovered Subdomains
puredns resolve "$outpath/subs.txt" -r "$wordlists/resolvers-trusted.txt" -w "$outpath/resolved.txt" | wc -l

dnsx -l "$scan_path/resolved.txt" -json -o "$outpath/dns.json" | jq -r '.a?[]?' | anew "$outpath/ips.txt" | wc -l 

## Port Scanning & HTTP Server Discovery
naabu -l "$outpath/resolved.txt" -pf port_list.txt | anew "$output/port.txt"

httpx -l "$outpath/port.txt" -timeout 10 -cl -wc -fr -title -sc | anew "$output/httpxscan.txt"
