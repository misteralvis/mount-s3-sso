#!/bin/bash

usage() {
  echo "Usage: $0 -b <bucket> -m <mount_point> -p <profile>" >&2
  echo "       $0 <bucket> <account> <mount_point>" >&2
  echo "" >&2
  echo "This utility helps mount S3 buckets via short-lived SSO creds, using defined profiles" >&2
  echo "It uses the \"s3-mount\" command, see : https://aws.amazon.com/s3/features/mountpoint" >&2
  echo "" >&2
  exit 1
}

while getopts ":b:m:p:h" opt; do
  case ${opt} in
    b )
      bucket=$OPTARG
      ;;
    m )
      mount_point=$OPTARG
      ;;
    p )
      profile=$OPTARG
      ;;
    h )
      usage
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

# Shift to the next argument after the flags
shift $((OPTIND -1))

# Check if parameters are not set and assign values from positional arguments
if [ -z "$bucket" ]; then
  bucket=$1
  shift
fi

if [ -z "$mount_point" ]; then
  mount_point=$1
  shift
fi

if [ -z "$profile" ]; then
  profile=$1
fi

# Checking if all arguments are provided
if [ -z "$bucket" ] || [ -z "$mount_point" ] || [ -z "$profile" ]; then
  usage
  exit 1
fi

#--- Verify this profile exists
grep -e '\[profile '${profile}'\]' ~/.aws/config >/dev/null || {
  echo "No profile matching \"${profile}\" found in ~/.aws/config (exit 100)"
  exit 100
}

#--- Store the temporary access keys in this processes environment
$(aws configure export-credentials --format env --profile ${profile}) || {
  echo "Was not able to export credentials. Are you logged in? (exit 101)"
  exit 101
}

#--- Perform the mount
mount-s3 ${bucket} ${mount_point}
