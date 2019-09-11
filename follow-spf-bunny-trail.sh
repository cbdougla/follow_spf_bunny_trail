#! /bin/sh
#
# follow_spf_bunny_trail
#
# Written 8/18/2016 by Collin Douglas (Collin.Douglas@adfitech.com)
#
# Quick ugly script to parse SPF record trails and generate a list of
# all IP addresses that can send for a domain
#
# This needs a reasonably recent version of dig.
# The dig in RHEL5, for example, doesn't work because it doesn't
# recognize "spf" as a valid type

DEBUG=0
VERBOSE=0
FILTER=0
PCAP=0
server=""

while getopts "Dhvfpd:s:" arg
 do
  case "$arg" in
    "h") echo ""
	     echo "Usage: follow-spf-bunny-trail -hvpfD -d <domain>"
	     echo ""
	     echo "  h: Print help summary"
	     echo "  v: Verbose mode"
	     echo "  D: Print debug info"
	     echo "  d: Specify domain"
	     echo "  s: Specify DNS server"
	     echo "  f: Output results in a tshark -Y display filter"
	     echo "     (You will need to remove the last \"or\")"
	     echo "  p: Output results in a pcap capture filter"
	     echo ""
	     echo "This tool will generate a list of all of the IP addresses / hostnames"
	     echo "from which the supplied domain can send emails."
	     echo ""
	     echo "It is good for tracking down issues with receiving emails"
	     echo "from some hosted domains (like hotmail)."
	     echo ""
	     echo "In addition, it can generate output (mostly) suitable for"
	     echo "a network sniffer (tshark or tcpdump) so it makes it easier"
	     echo "to see which server the emails are coming from"
	     echo ""
	     exit
	     ;;
    "d") domain=$OPTARG;
	     ;;
    "s") server=$OPTARG;
	     ;;
    "v") VERBOSE=1;
	     ;;
    "D") DEBUG=1;
	     ;;
    "f") FILTER=1;
	     ;;
    "p") PCAP=1;
	     ;;
    "*") echo "Invalid option";
	     exit
		 ;;
  esac
done

if [ \( $FILTER -eq 1 \) -a \( $PCAP -eq 1 \) ]; then
  echo ""
  echo "Do not enable display filter and pcap filter at the same time"
  echo ""
  exit
fi

if [ $FILTER -eq 1 ]; then
  echo ""
  echo "Don't forget to pass it to tshark with -Y option"
  echo "(and remove the last \"or\")"
fi

if [ -z "$domain" ]; then
  echo "You must specify a domain with the -d option"
  exit
fi

if [ $VERBOSE -eq 1 ]; then
  echo ""
  echo "Inspecting $domain for SPF records and IPV4 records"
  echo ""
fi

declare -a domains[1]="$domain"
dom_idx=1
dom_cnt=1


echo ""

while [ -n "$domain" ];
 do
  if [ $VERBOSE -eq 1 ]; then
    echo -n "$domain: "
  fi
  dom_idx=`expr $dom_idx + 1`

  if [ -n "$server" ]; then
    spf=`dig +short @${server} $domain txt | grep v=spf`
    spf="$spf `dig +short @${server} $domain spf | grep v=spf`"
   else
    spf=`dig +short $domain txt | grep v=spf`
    spf="$spf `dig +short $domain spf | grep v=spf`"
  fi

  if [ $DEBUG -eq 1 ]; then
	echo ""
    echo "DEBUG: domain=$domain, spf=$spf"
  fi

  if [ -z "$spf" ]; then
    echo "No SPF record for $domain"
	exit
  fi

  for item in $spf
   do
    tag=`echo $item | cut -d":" -f1`
    data=`echo $item | cut -d":" -f2`
    if [ $DEBUG -eq 1 ]; then
	  echo ""
      echo "DEBUG: i=$item, tag=$tag, data=$data"
    fi
  
    if [ "$tag" = "include" ]; then
	  # Check to see if domain is already in the array
	  current=1
	  new=1
	  while [ $current -le $dom_cnt ]
	   do
	    if [ "$data" = "${domains[current]}" ]; then
		  new=0
		  if [ $DEBUG -eq 1 ]; then
		    echo "DEBUG: found duplicate domain: $data"
		  fi
		fi
		current=`expr $current + 1`
	  done
	  if [ $new -eq 1 ]; then
	    if [ $DEBUG -eq 1 ]; then
		  echo "DEBUG: Adding domain $data"
		fi
        dom_cnt=`expr $dom_cnt + 1`;
        domains[dom_cnt]="$data"
      fi
    fi
    
    if [ \( "$tag" = "ip4" \) -o \( "$tag" = "a" \) ]; then

	  if [ $FILTER -eq 1 ]; then
		  echo -n "ip.addr == "
      fi
	  if [ $PCAP -eq 1 ]; then
	    echo $data|grep -q "/"
		rc=$?
		if [ $rc -eq 0 ]; then
		  echo -n "net "
		 else
		  echo -n "host "
		fi
      fi
      echo -n "$data "

	  if [ \( $FILTER -eq 1 \) -o \( $PCAP -eq 1 \) ]; then
	    echo -n "or "
	  fi

    fi

	if [ "$tag" = "mx" ]; then

	  if [ $DEBUG -eq 1 ]; then
	    echo "DEBUG: looking up mx record for $domain"
	  fi

	  if [ -n "$server" ]; then
	    data=`dig +short @${server} $domain mx| awk ' { print $2 } ' | tr '\n' ' '`
	   else
	    data=`dig +short $domain mx| awk ' { print $2 } ' | tr '\n' ' '`
	  fi

	  for mx in $data
	   do
	     if [ $FILTER -eq 1 ]; then
		   echo -n "ip.addr == "
		 fi
	     if [ $PCAP -eq 1 ]; then
	       echo $data|grep -q "/"
		   rc=$?
		   if [ $rc -eq 0 ]; then
		     echo -n "net "
		    else
		     echo -n "host "
		   fi
         fi
	     echo -n "$mx "
	  if [ \( $FILTER -eq 1 \) -o \( $PCAP -eq 1 \) ]; then
	    echo -n "or "
	  fi
	   done
	fi
  done
if [ $VERBOSE -eq 1 ]; then
  echo ""
  echo ""
fi

  domain=${domains[$dom_idx]}
  
done
if [ $VERBOSE -eq 0 ]; then
  echo ""
  echo ""
fi
echo "Number of domains: $dom_cnt"
echo "List of SPF domains: ${domains[@]}"
echo ""
  
