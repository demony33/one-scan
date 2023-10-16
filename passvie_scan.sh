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

printf "\x1b[32m ---> [ DNS Enumeration -Find Subdomains:]\\x1b[0m\n" ;
## DNS Enumeration -Find Subdomains
amass enum -passive -norecursive -noalts -df "$scope/domains.txt" | anew "$outpath/subs.txt"

subfinder -dL "$scope/domains.txt" -all | anew "$outpath/subs.txt"

shuffledns -l "$scope/domains.txt" -w "$wordlists/2m-subdomains.txt" -r "$wordlists/resolvers-trusted.txt" | anew "$outpath/subs.txt"

printf "\x1b[32m ---> [ DNS Resolution - Resolver Discovered Subdomains:]\\x1b[0m\n" ;
## DNS Resolution - Resolver Discovered Subdomains
puredns resolve "$outpath/subs.txt" -r "$wordlists/resolvers-trusted.txt" -w "$outpath/resolved.txt" | wc -l

dnsx -l "$outpath/resolved.txt" -json -o "$outpath/dns.json" | jq -r '.a?[]?' | anew "$outpath/ips.txt" | wc -l 

printf "\x1b[32m ---> [ Port Scanning & HTTP Server Discovery:]\\x1b[0m\n" ;
## Port Scanning & HTTP Server Discovery
naabu -l "$outpath/resolved.txt" -pf port_list.txt | anew "$outpath/port.txt"

httpx -l "$outpath/port.txt" -timeout 10 -cl -wc -fr -title -sc | anew "$outpath/httpxscan.txt"

printf "\x1b[32m ---> [ Webscanning - nuclei:]\\x1b[0m\n" ;
nuclei -l "$outpath/port.txt" -etags dns,ssl -es info -o "$outpath/report.txt"

printf "\x1b[32m ---> [ Have been sent to discord!]\\x1b[0m\n" ;
#notify
notify -data "$outpath/report.txt" -bulk
