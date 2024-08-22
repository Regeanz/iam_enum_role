#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' 

# Run awscli with specific profile
run_aws_cli() {
    command=$1
    profile=$2
    aws $command --profile $profile --output json
}

# Function to enumerate all IAM roles
enumerate_roles() {
    profile=$1
    echo -e "${BLUE}Enumerating all IAM roles for profile: ${YELLOW}$profile${NC}"

    roles=$(run_aws_cli "iam list-roles" $profile)
    if [ -z "$roles" ]; then
        echo -e "${RED}Error: Failed to retrieve roles.${NC}"
        exit 1
    fi

    role_names=$(echo $roles | jq -r '.Roles[].RoleName')
    echo -e "${GREEN}Found Roles:${NC}"
    echo -e "${YELLOW}$role_names${NC}"
}


# Function to enumerate policies attached to roles
enumerate_role_policies() {
    profile=$1
    echo
    echo -e "${BLUE}Enumerating policies for each role.${NC}"

    roles=$(run_aws_cli "iam list-roles" $profile)
    role_names=$(echo $roles | jq -r '.Roles[].RoleName')

    for role_name in $role_names; do
        echo -e "${GREEN}Role: ${YELLOW}$role_name${NC}"

        attached_policies=$(run_aws_cli "iam list-attached-role-policies --role-name $role_name" $profile)
        if [ -n "$attached_policies" ]; then
            echo -e "${BLUE}  Attached Policies:${NC}"
            for policy_arn in $(echo $attached_policies | jq -r '.AttachedPolicies[].PolicyArn'); do
                policy_name=$(run_aws_cli "iam get-policy --policy-arn $policy_arn" $profile | jq -r '.Policy.PolicyName')
                echo -e "${YELLOW}    - $policy_name${NC} (${BLUE}$policy_arn${NC})"
                echo
            done
        fi
    done
}

# Main script execution
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Usage: $0 <aws-profile>${NC}"
    exit 1
fi

profile=$1

enumerate_roles $profile

enumerate_role_policies $profile
