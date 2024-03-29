#!/bin/bash

USER_NAME=$1

if [ -z "$USER_NAME" ]; then
    echo "Usage: $0 [docker hub username]"
    exit 1
fi

echo "" > docker-bake.hcl

username=$USER_NAME
base_targets=()
iac_targets=()
depend_base_targets=()

for dockerfile in $(find . -type f -name 'Dockerfile'); do
    path=$(dirname "$dockerfile")
    short_dockerfile_path=$(echo "$dockerfile" | sed 's|^\./[^/]*/[^/]*/||')
    base=$(basename "$path")
    approot=$(dirname "$path")
    parent=$(basename "$(dirname "$path")")
    appname=$(basename "$(dirname "$approot")")
    image_tag="${appname}-${parent}"
    targetname="${image_tag//./_}-${base//./_}"
    if [[ $path == "./base/"* ]]; then
        base_targets+=("\"$targetname\"")
    elif [[ $path == "./iac/"* ]]; then
        iac_targets+=("\"$targetname\"")
    else
        depend_base_targets+=("\"$targetname\"")
    fi

    echo "target \"$targetname\" {" >> docker-bake.hcl
    echo "  context = \"$approot\"" >> docker-bake.hcl
    echo "  dockerfile = \"$short_dockerfile_path\"" >> docker-bake.hcl
    echo "  tags = [\"$username/$image_tag:$base\"]" >> docker-bake.hcl
    
    if [[ $path == "./frappe/"* ]]; then
        depends=()
        if [[ $targetname == *"debian"* ]]; then
            for target in "${base_targets[@]}"; do
                [[ $target == *"debian"* ]] && depends+=("$target")
            done
        elif [[ $targetname == *"alpine"* ]]; then
            for target in "${base_targets[@]}"; do
                [[ $target == *"alpine"* ]] && depends+=("$target")
            done
        fi

        [[ ${#depends[@]} -gt 0 ]] && echo "  depends_on = [$(IFS=, ; echo "${depends[*]}")]" >> docker-bake.hcl
    fi

    echo "}" >> docker-bake.hcl
done

echo "group \"default\" {" >> docker-bake.hcl
echo "  targets = [$(IFS=, ; echo "${base_targets[*]}")]" >> docker-bake.hcl
echo "}" >> docker-bake.hcl

echo "group \"frappe\" {" >> docker-bake.hcl
echo "  targets = [$(IFS=, ; echo "${depend_base_targets[*]}")]" >> docker-bake.hcl
echo "}" >> docker-bake.hcl

echo "group \"iac\" {" >> docker-bake.hcl
echo "  targets = [$(IFS=, ; echo "${iac_targets[*]}")]" >> docker-bake.hcl
echo "}" >> docker-bake.hcl
