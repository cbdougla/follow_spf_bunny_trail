# follow_spf_bunny_trail
A BASH script to enumerate a list of SPF servers for a domain

A while back I was tasked with trying to debug some email issues involving a hosted domain.  <br>
One of the troubleshooting steps I tried was performing a network traffic sniff of the sending email servers.

Well, for some hosted email providers, this became a crazy process since they could involve several
hosts or subnets and thus, this script was born.

```
[cbd][blueboy][/home/qc/cbd/mybin]$ ./follow-spf-bunny-trail.sh -h

Usage: follow-spf-bunny-trail -hvpfD -d <domain>

  h: Print help summary
  v: Verbose mode
  D: Print debug info
  d: Specify domain
  s: Specify DNS server
  f: Output results in a tshark -Y display filter
     (You will need to remove the last "or")
  p: Output results in a pcap capture filter

This tool will generate a list of all of the IP addresses / hostnames
from which the supplied domain can send emails.

It is good for tracking down issues with receiving emails
from some hosted domains (like hotmail).

In addition, it can generate output (mostly) suitable for
a network sniffer (tshark or tcpdump) so it makes it easier
to see which server the emails are coming from
```

This script will enumerate a list of sending mail servers for a domain by traversing a list of SPF records.

For example, here's it running against hotmail.com

```
[cbd][blueboy][/home/qc/cbd/mybin]$ ./follow-spf-bunny-trail.sh -d hotmail.com

157.55.9.128/25 207.46.100.0/24 207.46.163.0/24 65.55.169.0/24 157.56.110.0/23 157.55.234.0/24 213.199.154.0/24 
213.199.180.128/26 52.100.0.0/14 157.56.232.0/21 157.56.240.0/20 207.46.198.0/25 207.46.4.128/25 157.56.24.0/25 
157.55.157.128/25 157.55.61.0/24 157.55.49.0/25 65.55.174.0/25 65.55.126.0/25 65.55.113.64/26 65.55.94.0/25 65.55.78.128/25 
111.221.112.0/21 207.46.58.128/25 111.221.69.128/25 111.221.66.0/25 111.221.23.128/25 70.37.151.128/25 157.56.248.0/21 
213.199.177.0/26 157.55.225.0/25 157.55.11.0/25 157.55.0.192/26 157.55.1.128/26 157.55.2.0/25 65.54.190.0/24 
65.54.51.64/26 65.54.61.64/26 65.55.111.0/24 65.55.116.0/25 65.55.34.0/24 65.55.90.0/24 65.54.241.0/24 207.46.117.0/24 
207.68.169.173/30 207.68.176.0/26 207.46.132.128/27 207.68.176.96/27 65.55.238.129/26 65.55.238.129/26 207.46.116.128/29 
65.55.178.128/27 213.199.161.128/27 65.55.33.64/28 65.54.121.120/29 65.55.81.48/28 65.55.234.192/26 207.46.200.0/27 
65.55.52.224/27 94.245.112.10/31 94.245.112.0/27 111.221.26.0/27 207.46.50.192/26 207.46.50.224 157.56.112.0/24 
207.46.51.64/26 64.4.22.64/26 40.92.0.0/15 40.107.0.0/16 134.170.140.0/24 23.103.128.0/19 23.103.198.0/23 65.55.88.0/24 
104.47.0.0/17 23.103.200.0/21 23.103.208.0/21 23.103.191.0/24 216.32.180.0/23 94.245.120.64/26 

Number of domains: 9
List of SPF domains: hotmail.com spf.protection.outlook.com spf-a.outlook.com spf-b.outlook.com spf-a.hotmail.com 
_spf-ssg-b.microsoft.com _spf-ssg-c.microsoft.com spfa.protection.outlook.com spfb.protection.outlook.com
```

Since I needed to be able to do a sniff, I made it capable out outputting PCAP or tshark capture filters as well. <br>
You will need to trip the last "or" off the end though.  I am lazy.
