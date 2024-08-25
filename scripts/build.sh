#!/bin/bash

check_out_remote_module() (
    rurl="$1"
    shift
    declare -a paths
    declare -a module_names
    for var in "$@"
    do
        IFS="="
        read -ra module_name_components <<< "$var"
        components_count=${#module_name_components[@]}
        path=${module_name_components[0]}
        module_name=${module_name_components[$components_count-1]}
        paths=("${paths[@]}" "$path")
        module_names=("${module_names[@]}" "$module_name")
    done
    IFS=" "

    for module_name in "${module_names[@]}"
    do
        rm -rf ../$module_name
    done

    current_date_time=$(date)
    echo "URL: $rurl"
    git clone -n --depth=1 --filter=tree:0 $rurl
    cd ${rurl##*/}
    git sparse-checkout set --no-cone "${paths[@]}"
    git checkout

    for i in "${!paths[@]}"
    do
        module_name=${module_names[$i]}
        path=${paths[$i]}
        cp -R ./$path ../../$module_name
        echo $current_date_time > ../../$module_name/.checkoutinfo
        echo "URL: $rurl" >> ../../$module_name/.checkoutinfo
        echo "Path: $path" >> ../../$module_name/.checkoutinfo
    done
    cd ../
)

checkout_dependencies()(
    echo -e "\n[INFO] Checking out dependencies"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/gojo" "gojo"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/hue" "hue"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/mist" "mist"
    check_out_remote_module "-b nightly https://github.com/thatstoasty/weave" "weave"
)

build_dependencies() {
    echo -e "\n[INFO] Building dependencies"
    dirs_to_remove=("bufio" "net" "syscall")
    for dir in "${dirs_to_remove[@]}"; do
        rm -R "gojo/${dir}"
    done
    rm -R mog/gojo
    mv gojo mog
    rm -R mog/hue
    mv hue mog
    rm -R mog/mist
    mv mist mog
    rm -R mog/weave
    mv weave mog
}

if [ "$1" == "package" ]; then
    mkdir -p "_deps"
    cd "_deps"

    checkout_dependencies
    cd ..

    rm -rf "_deps"
    build_dependencies
    mojo package mog
elif [ "$1" == "dependencies" ]; then
    mkdir -p "_deps"
    cd "_deps"

    checkout_dependencies
    cd ..

    rm -rf "_deps"
    build_dependencies
else
    echo "Invalid argument. Use 'package' to package the project or 'dependencies' to build only the dependencies."
fi
