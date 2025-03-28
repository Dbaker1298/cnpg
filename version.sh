# Copyright [2024] [Tietoevry Care]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

readonly CHART_PATH="." # replace with your actual path
readonly TEMP_REPO_NAME="temp" # This will be removed when the script is done

verify_commands_exist() {
  commands=("helm" "jq" "yq" "git")
  for cmd in "${commands[@]}"; do
    if ! command -v $cmd &> /dev/null; then
      echo "$cmd could not be found"
      echo "Please install $cmd before proceeding."
      case $cmd in
        "helm")
          echo "You can install helm using the following command:"
          echo "macOS: brew install helm"
          echo "Windows: choco install kubernetes-helm"
          ;;
        "jq")
          echo "You can install jq using the following command:"
          echo "macOS: brew install jq"
          echo "Windows: choco install jq"
          ;;
        "yq")
          echo "You can install yq using the following command:"
          echo "macOS: brew install yq"
          echo "Windows: choco install yq"
          ;;
        "git")
          echo "You can install git using the following command:"
          echo "macOS: brew install git"
          echo "Windows: choco install git"
          ;;
      esac
      exit 1
    fi
  done
}

remove_temp_repo() {
  helm repo remove $TEMP_REPO_NAME > /dev/null
}

fetch_repo_and_chart() {
  repo=$(yq eval '.dependencies[0].repository' $CHART_PATH/Chart.yaml)
  chart=$(yq eval '.dependencies[0].name' $CHART_PATH/Chart.yaml)
}

add_and_update_repo() {
  helm repo add $TEMP_REPO_NAME $repo > /dev/null
  helm repo update > /dev/null
}

get_current_version() {
  current_version=$(yq eval '.version' $CHART_PATH/Chart.yaml)
}

search_existing_versions() {
  echo "No new version provided. Searching the repository for existing versions..."
  printf "%-15s %-15s %s\n" "Version" "App Version" "Current"
  helm search repo $TEMP_REPO_NAME/$chart -l --output json | jq -r '.[] | "\(.version) \(.app_version)"' | awk -v cv="$current_version" '{if ($1 == cv) printf "%-15s %-15s %s\n", $1, $2, "*"; else printf "%-15s %-15s %s\n", $1, $2, ""}'
  remove_temp_repo
  exit 0
}

verify_version_exists() {
  search_results=$(helm search repo $TEMP_REPO_NAME/$chart --version "$new_version" --output json)
  if [ "$(echo $search_results | jq -r '.[0].app_version')" == "null" ]; then
    echo "Version does not exist"
    remove_temp_repo
    exit 1
  fi
  app_version=$(echo $search_results | jq -r '.[0].app_version')
  echo "Version exists, app_version is $app_version"
}

update_chart_yaml() {
  yq eval -i ".version = \"$new_version\"" $CHART_PATH/Chart.yaml
  yq eval -i '(.dependencies[0].version) |= "'$new_version'"' $CHART_PATH/Chart.yaml
  yq eval -i ".appVersion = \"$app_version\"" $CHART_PATH/Chart.yaml
  remove_temp_repo
  echo "Updated $CHART_PATH/Chart.yaml with version $new_version and appVersion $app_version"
}

update_dependencies() {
  helm dependency update $CHART_PATH > /dev/null
}

check_tag_exists() {
  if git rev-parse "$new_version" >/dev/null 2>&1; then
    echo "Tag already exists, why do you want to add it again? Exiting..."
    exit 1
  fi
}

commit_and_push_changes() {
  git add .
  git commit -m "Changed version $new_version and appVersion $app_version"
  git tag $new_version
  git push origin $new_version --tags
}

# Main script
verify_commands_exist
fetch_repo_and_chart
add_and_update_repo
get_current_version

if [ -z "$1" ]; then
  search_existing_versions
fi

new_version=$1
verify_version_exists
update_chart_yaml
update_dependencies
check_tag_exists
commit_and_push_changes
